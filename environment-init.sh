#!/bin/bash

set -e  # ⛔ Detener ejecución si hay error

# 📌 Variables requeridas
ENV_FILE=".env"
REQUIRED_VARS=("DB_USER" "DB_PASS" "DB_NAME" "SITE_DOMAIN" "SUBDOMAIN" "FASTAPI_PORT")

# 🛠️ Función para pedir input con valor por defecto
ask_var() {
    local var_name="$1"
    local default_value="$2"
    local user_input

    read -p "🔹 Ingresa $var_name [$default_value]: " user_input
    echo "${user_input:-$default_value}"
}

# 🛠️ Función para pedir contraseña sin mostrar en pantalla y sanitizar caracteres peligrosos
ask_sensitive_var() {
    local var_name="$1"
    local default_value="$2"
    local user_input

    echo "🔑 Ingresa $var_name (oculto, presiona Enter para usar el valor por defecto)"
    read -s -p "🔹 Contraseña [$default_value]: " user_input
    echo ""  

    sanitized_pass=$(echo "${user_input:-$default_value}" | tr '"' "'" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

    if [[ "$sanitized_pass" != "${user_input:-$default_value}" ]]; then
        echo "⚠️ Nota: Se han ajustado espacios en blanco y cambiado comillas dobles (\") por comillas simples (')."
    fi

    echo "Password: asegurate de guardar la contraseña - $sanitized_pass"
}

# 📂 Verificación del archivo .env
if [[ -f "$ENV_FILE" ]]; then
    echo "⚠️ Archivo .env encontrado en $(pwd)."
    read -p "🔄 ¿Quieres regenerarlo? (s/n): " REGENERATE_ENV
    if [[ "$REGENERATE_ENV" == "s" ]]; then
        rm "$ENV_FILE"
        echo "🗑️ Archivo .env eliminado. Creando uno nuevo..."
    else
        echo "✅ Usando configuración existente en .env."
    fi
fi

# 📂 Si el .env no existe, lo creamos y pedimos valores
if [[ ! -f "$ENV_FILE" ]]; then
    echo "⚠️ No se encontró .env. Creando uno nuevo..."
    
    DB_USER=$(ask_var "usuario de la base de datos" "showroom_user")
    DB_PASS=$(ask_sensitive_var "contraseña de la base de datos" "SuperSecurePass123")
    DB_NAME=$(ask_var "nombre de la base de datos" "showroom_db")
    SITE_DOMAIN=$(ask_var "dominio raíz (ej: equalitech.xyz)" "equalitech.xyz")
    SUBDOMAIN=$(ask_var "subdominio del sitio (ej: tl-showroom)" "tl-showroom")
    FASTAPI_PORT=$(ask_var "puerto para FastAPI" "8000")

    FULL_DOMAIN="$SUBDOMAIN.$SITE_DOMAIN"

    cat <<EOF > "$ENV_FILE"
DB_USER="$DB_USER"
DB_PASS="$DB_PASS"
DB_NAME="$DB_NAME"
SITE_DOMAIN="$SITE_DOMAIN"
SUBDOMAIN="$SUBDOMAIN"
FULL_DOMAIN="$FULL_DOMAIN"
FASTAPI_PORT="$FASTAPI_PORT"
EOF

    echo "✅ Archivo .env creado en $(pwd). 📂 Revísalo antes de continuar."
fi

# 🚀 Cargar configuración desde .env (método seguro)
echo "📂 Cargando configuración desde $(pwd)/.env..."
set -o allexport
source "$ENV_FILE"
set +o allexport

# 🔍 Validar que todas las variables están definidas
for var in "${REQUIRED_VARS[@]}"; do
    if [[ -z "${!var}" ]]; then
        echo "❌ ERROR: La variable $var no está definida en el .env"
        exit 1
    fi
done

PROJECT_PATH="/opt/easyengine/sites/$FULL_DOMAIN/app/backend"
NGINX_CONFIG="/opt/easyengine/sites/$FULL_DOMAIN/config/nginx/custom/user.conf"
SSL_CERT="/etc/letsencrypt/live/$SITE_DOMAIN/fullchain.pem"
SSL_KEY="/etc/letsencrypt/live/$SITE_DOMAIN/privkey.pem"

# 🔐 Verificar certificados SSL
if [[ ! -f "$SSL_CERT" || ! -f "$SSL_KEY" ]]; then
    echo "❌ ERROR: No se encontraron los certificados SSL en:"
    echo "🔹 Certificado: $SSL_CERT"
    echo "🔹 Llave privada: $SSL_KEY"
    exit 1
fi

# 🌐 Verificar si el sitio existe en EasyEngine
if ! ee site list | grep -q "$FULL_DOMAIN"; then
    echo "🚀 Creando sitio con EasyEngine..."
    ee site create "$FULL_DOMAIN" --ssl=custom --ssl-crt="$SSL_CERT" --ssl-key="$SSL_KEY"
else
    echo "✅ Sitio ya existe, omitiendo creación..."
fi

# 🏗️ Creación de estructura de proyecto
mkdir -p "$PROJECT_PATH"
cd "$PROJECT_PATH" || exit
echo "📂 Ubicación del proyecto: $(pwd)"

# 📦 Función para crear archivos si no existen
create_file_if_not_exists() {
    local file_path="$1"
    local content="$2"

    if [[ -f "$file_path" ]]; then
        echo "⚠️ Archivo $file_path ya existe en $(pwd), omitiendo..."
    else
        echo "📄 Creando $file_path en $(pwd)..."
        echo "$content" > "$file_path"
        echo "🔍 Puedes revisar el archivo en: $(pwd)/$file_path"
    fi
}

# 📜 Crear archivos con contenido seguro
create_file_if_not_exists "requirements.txt" "fastapi
uvicorn
sqlalchemy
psycopg2-binary"

create_file_if_not_exists "Dockerfile" "FROM python:3.11
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
CMD [\"uvicorn\", \"main:app\", \"--host\", \"0.0.0.0\", \"--port\", \"$FASTAPI_PORT\"]"

create_file_if_not_exists "entrypoint.sh" "#!/bin/bash
echo \"🚀 Iniciando API...\"
exec uvicorn main:app --host 0.0.0.0 --port $FASTAPI_PORT"
chmod +x entrypoint.sh  # ✅ Hacer ejecutable

create_file_if_not_exists "docker-compose.yml" "version: \"3.8\"
services:
  api:
    build: .
    container_name: showroom-api
    restart: always
    depends_on:
      - postgres
    ports:
      - \"$FASTAPI_PORT:$FASTAPI_PORT\"
    environment:
      - DATABASE_URL=postgresql://$DB_USER:$DB_PASS@postgres:5432/$DB_NAME
  postgres:
    image: postgres:16
    container_name: showroom-db
    restart: always
    environment:
      POSTGRES_USER: $DB_USER
      POSTGRES_PASSWORD: $DB_PASS
      POSTGRES_DB: $DB_NAME
    volumes:
      - pgdata:/var/lib/postgresql/data
    ports:
      - \"5432:5432\"
volumes:
  pgdata:"

# 🔄 Configuración de Nginx (si no existe)
if [[ ! -f "$NGINX_CONFIG" ]]; then
    echo "🌐 Configurando Nginx como proxy inverso..."
    cat <<EOF > "$NGINX_CONFIG"
server {
    listen 80;
    listen [::]:80;
    server_name $FULL_DOMAIN;
    location / {
        proxy_pass http://127.0.0.1:$FASTAPI_PORT;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF
    echo "🔍 Puedes revisar la configuración en: $NGINX_CONFIG"
else
    echo "⚠️ Configuración de
