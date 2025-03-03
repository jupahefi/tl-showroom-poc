#!/bin/bash

set -e  # Detener el script en caso de error

# 📌 Cargar variables desde .env si existe
if [ -f ".env" ]; then
    export $(grep -v '^#' .env | xargs)
else
    echo "⚠️ No se encontró .env, utilizando configuración manual."
fi

# 🌎 Solicitar configuración solo si no está en .env
echo "🌎 Ingresa el dominio del sitio (ej: equalitech.xyz):"
read -r SITE_DOMAIN

echo "🔹 Ingresa el subdominio (ej: tl-showroom):"
read -r SUBDOMAIN

echo "👤 Ingresa el nombre de usuario de la base de datos:"
read -r DB_USER

echo "🔑 Ingresa la contraseña para $DB_USER:"
read -s DB_PASS

echo "🗄️ Ingresa el nombre de la base de datos:"
read -r DB_NAME

FULL_DOMAIN="$SUBDOMAIN.$SITE_DOMAIN"
PROJECT_PATH="/opt/easyengine/sites/$FULL_DOMAIN/app/backend"
NGINX_CONFIG="/opt/easyengine/sites/$FULL_DOMAIN/config/nginx/custom/user.conf"
SSL_CERT="/etc/letsencrypt/live/$SITE_DOMAIN/fullchain.pem"
SSL_KEY="/etc/letsencrypt/live/$SITE_DOMAIN/privkey.pem"

# 🔒 **Verificar si los certificados existen**
if [ ! -f "$SSL_CERT" ] || [ ! -f "$SSL_KEY" ]; then
    echo "❌ ERROR: No se encontraron los certificados SSL para $SITE_DOMAIN."
    echo "🔍 Revisa que existan en /etc/letsencrypt/live/$SITE_DOMAIN/"
    echo "🚫 Abortando script."
    exit 1
fi

# 📌 Instalar dependencias si faltan
install_if_missing() {
    if ! command -v "$1" &> /dev/null; then
        echo "🚀 Instalando $1..."
        sudo apt-get update && sudo apt-get install -y "$2"
    else
        echo "✅ $1 ya está instalado."
    fi
}

install_if_missing "docker" "docker.io"
install_if_missing "docker-compose" "docker-compose"
install_if_missing "ee" "easyengine"

# 🌐 Verificar si el sitio existe en EasyEngine
if ! ee site list | grep -q "$FULL_DOMAIN"; then
    echo "🚀 Creando sitio con EasyEngine..."
    ee site create "$FULL_DOMAIN" \
        --ssl=custom \
        --ssl-crt="$SSL_CERT" \
        --ssl-key="$SSL_KEY"
else
    echo "✅ Sitio ya existe, omitiendo creación..."
fi

# 🏗️ Creación de estructura de proyecto
echo "🔧 Creando estructura de directorios..."
mkdir -p "$PROJECT_PATH"
cd "$PROJECT_PATH" || exit

# 📦 Creación de archivos del proyecto
echo "📦 Creando .env..."
cat <<EOF > .env
DB_USER=$DB_USER
DB_PASS=$DB_PASS
DB_NAME=$DB_NAME
SITE_DOMAIN=$SITE_DOMAIN
SUBDOMAIN=$SUBDOMAIN
FULL_DOMAIN=$FULL_DOMAIN
EOF

echo "📦 Creando requirements.txt..."
cat <<EOF > requirements.txt
fastapi
uvicorn
sqlalchemy
psycopg2-binary
EOF

echo "🐍 Creando Dockerfile..."
cat <<EOF > Dockerfile
FROM python:3.11

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
EOF

echo "🚀 Creando entrypoint.sh..."
cat <<EOF > entrypoint.sh
#!/bin/bash
echo "🚀 Iniciando API..."
exec uvicorn main:app --host 0.0.0.0 --port 8000
EOF
chmod +x entrypoint.sh

echo "📜 Creando docker-compose.yml con PostgreSQL..."
cat <<EOF > docker-compose.yml
version: "3.8"

services:
  api:
    build: .
    container_name: tl-showroom-api
    restart: always
    depends_on:
      - postgres
    ports:
      - "8000:8000"
    environment:
      - DATABASE_URL=postgresql://\$DB_USER:\$DB_PASS@postgres:5432/\$DB_NAME

  postgres:
    image: postgres:16
    container_name: tl-showroom-db
    restart: always
    environment:
      POSTGRES_USER: \$DB_USER
      POSTGRES_PASSWORD: \$DB_PASS
      POSTGRES_DB: \$DB_NAME
    volumes:
      - pgdata:/var/lib/postgresql/data
    ports:
      - "5432:5432"

volumes:
  pgdata:
EOF

# 🔄 Configuración de Nginx como proxy inverso
echo "🌐 Configurando Nginx como proxy inverso..."
cat <<EOF > "$NGINX_CONFIG"
server {
    listen 80;
    listen [::]:80;
    server_name $FULL_DOMAIN;

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

# 🔄 Recargar Nginx
echo "🔄 Recargando Nginx..."
ee site reload "$FULL_DOMAIN"

# ✅ Verificación final
echo "✅ Verificando configuración..."
ls -l "$PROJECT_PATH"
nginx -t
curl -I "http://$FULL_DOMAIN"

echo "🎉 Setup completado. Ahora puedes ejecutar:"
echo "👉 docker-compose up -d"
