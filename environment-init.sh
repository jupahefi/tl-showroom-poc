#!/bin/bash

set -e  # ⛔ Detener ejecución si ocurre un error

# 📌 Función para verificar si una variable está definida
check_env_var() {
    local var_name="$1"
    if [[ -z "${!var_name}" ]]; then
        echo "❌ ERROR: La variable $var_name no está definida en el .env"
        exit 1
    fi
}

# 🚀 Cargar configuración desde .env si existe
if [[ -f .env ]]; then
    echo "📂 Cargando configuración desde .env..."
    export $(grep -v '^#' .env | xargs)
fi

# 🏗️ Verificar variables obligatorias
check_env_var "DB_USER"
check_env_var "DB_PASS"
check_env_var "DB_NAME"
check_env_var "SITE_DOMAIN"
check_env_var "FASTAPI_PORT"

PROJECT_PATH="/opt/easyengine/sites/$SITE_DOMAIN/app/backend"
NGINX_CONFIG="/opt/easyengine/sites/$SITE_DOMAIN/config/nginx/custom/user.conf"
SSL_CERT="/etc/letsencrypt/live/$SITE_DOMAIN/fullchain.pem"
SSL_KEY="/etc/letsencrypt/live/$SITE_DOMAIN/privkey.pem"

# 🔐 Verificar si los certificados existen antes de continuar
if [[ ! -f "$SSL_CERT" || ! -f "$SSL_KEY" ]]; then
    echo "❌ ERROR: No se encontraron los certificados SSL en $SSL_CERT y $SSL_KEY"
    exit 1
fi

# 🌐 Verificar si el sitio existe en EasyEngine
if ! ee site list | grep -q "$SITE_DOMAIN"; then
    echo "🚀 Creando sitio con EasyEngine..."
    ee site create "$SITE_DOMAIN" --ssl=custom --ssl-crt="$SSL_CERT" --ssl-key="$SSL_KEY"
else
    echo "✅ Sitio ya existe, omitiendo creación..."
fi

# 🏗️ Creación de estructura de proyecto
echo "🔧 Creando estructura de directorios..."
mkdir -p "$PROJECT_PATH"
cd "$PROJECT_PATH" || exit

# 📦 Creación de archivos del proyecto (si no existen)
create_file_if_not_exists() {
    local file_path="$1"
    local content="$2"

    if [[ -f "$file_path" ]]; then
        echo "⚠️ Archivo $file_path ya existe, omitiendo..."
    else
        echo "📄 Creando $file_path..."
        echo "$content" > "$file_path"
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
    container_name: tl-showroom-api
    restart: always
    depends_on:
      - postgres
    ports:
      - \"$FASTAPI_PORT:$FASTAPI_PORT\"
    environment:
      - DATABASE_URL=postgresql://$DB_USER:$DB_PASS@postgres:5432/$DB_NAME
  postgres:
    image: postgres:16
    container_name: tl-showroom-db
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

# 🔄 Configuración de Nginx como proxy inverso (solo si no existe)
if [[ ! -f "$NGINX_CONFIG" ]]; then
    echo "🌐 Configurando Nginx como proxy inverso..."
    cat <<EOF > "$NGINX_CONFIG"
server {
    listen 80;
    listen [::]:80;
    server_name $SITE_DOMAIN;
    location / {
        proxy_pass http://127.0.0.1:$FASTAPI_PORT;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF
else
    echo "⚠️ Configuración de Nginx ya existe, omitiendo..."
fi

# 🔄 Recargar Nginx
echo "🔄 Recargando Nginx..."
ee site reload "$SITE_DOMAIN"

# ✅ Verificación final
echo "✅ Verificando configuración..."
ls -l "$PROJECT_PATH"
nginx -t
curl -I "http://$SITE_DOMAIN"

echo "🎉 Setup completado. Ahora puedes ejecutar:"
echo "👉 docker-compose up -d"
