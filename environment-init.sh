#!/bin/bash

set -e  # ⛔ Detener ejecución si hay error

# 📌 Variables requeridas
ENV_FILE=".env"
REQUIRED_VARS=("DB_USER" "DB_PASS" "DB_NAME" "SITE_DOMAIN" "BACKEND_SUBDOMAIN" "FRONTEND_SUBDOMAIN" "BACKEND_PORT" "FRONTEND_PORT")

# 🛠️ Función para verificar e instalar paquetes
install_if_missing() {
    local package=$1
    local install_cmd=$2
    if ! command -v "$package" &>/dev/null; then
        echo "⚠️ $package no encontrado. Instalando..."
        eval "$install_cmd"
    else
        echo "✅ $package ya está instalado."
    fi
}

# 🛠️ Instalar dependencias necesarias
echo "🛠️ Verificando dependencias..."
install_if_missing "node" "curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && apt install -y nodejs"
install_if_missing "npm" "apt install -y npm"
install_if_missing "npx" "npm install -g npx"
install_if_missing "docker" "apt install -y docker.io"
install_if_missing "docker-compose" "apt install -y docker-compose"
install_if_missing "ee" "wget -qO ee https://rt.cx/ee4 && chmod +x ee && mv ee /usr/local/bin/"

echo "✅ Todas las dependencias están instaladas."

# 📂 Verificación del archivo .env
if [[ -f "$ENV_FILE" ]]; then
    echo "⚠️ Archivo .env encontrado."
    read -p "🔄 ¿Quieres regenerarlo? (s/n): " REGENERATE_ENV
    if [[ "$REGENERATE_ENV" == "s" ]]; then
        rm "$ENV_FILE"
        echo "🗑️ Archivo .env eliminado. Creando uno nuevo..."
    else
        echo "✅ Usando configuración existente."
    fi
fi

# 📂 Si el .env no existe, lo creamos
if [[ ! -f "$ENV_FILE" ]]; then
    echo "⚠️ No se encontró .env. Creando uno nuevo..."
    
    DB_USER="showroom_user"
    DB_PASS="SuperSecurePass123"
    DB_NAME="showroom_db"
    SITE_DOMAIN="equalitech.xyz"
    BACKEND_SUBDOMAIN="backend-tl-showroom"
    FRONTEND_SUBDOMAIN="tl-showroom"
    BACKEND_PORT="8080"
    FRONTEND_PORT="5173"

    BACKEND_DOMAIN="$BACKEND_SUBDOMAIN.$SITE_DOMAIN"
    FRONTEND_DOMAIN="$FRONTEND_SUBDOMAIN.$SITE_DOMAIN"

    cat <<EOF > "$ENV_FILE"
DB_USER='$DB_USER'
DB_PASS='$DB_PASS'
DB_NAME='$DB_NAME'
SITE_DOMAIN='$SITE_DOMAIN'
BACKEND_SUBDOMAIN='$BACKEND_SUBDOMAIN'
FRONTEND_SUBDOMAIN='$FRONTEND_SUBDOMAIN'
BACKEND_DOMAIN='$BACKEND_DOMAIN'
FRONTEND_DOMAIN='$FRONTEND_DOMAIN'
BACKEND_PORT='$BACKEND_PORT'
FRONTEND_PORT='$FRONTEND_PORT'
EOF

    echo "✅ Archivo .env creado. 📂 Revísalo antes de continuar."
fi

# 🚀 Cargar configuración desde .env
echo "📂 Cargando configuración desde .env..."
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

echo "✅ Variables del .env cargadas correctamente."

BACKEND_PATH="/opt/easyengine/sites/$BACKEND_DOMAIN/app/backend"
FRONTEND_PATH="/opt/easyengine/sites/$FRONTEND_DOMAIN/app/frontend"
SSL_CERT="/etc/letsencrypt/live/$SITE_DOMAIN/fullchain.pem"
SSL_KEY="/etc/letsencrypt/live/$SITE_DOMAIN/privkey.pem"
NGINX_CONFIG_BACKEND="/opt/easyengine/sites/$BACKEND_DOMAIN/config/nginx/custom/user.conf"
NGINX_CONFIG_FRONTEND="/opt/easyengine/sites/$FRONTEND_DOMAIN/config/nginx/custom/user.conf"

# 🔐 Verificar certificados SSL
if [[ ! -f "$SSL_CERT" || ! -f "$SSL_KEY" ]]; then
    echo "❌ ERROR: No se encontraron los certificados SSL en:"
    echo "🔹 Certificado: $SSL_CERT"
    echo "🔹 Llave privada: $SSL_KEY"
    exit 1
fi

# 🔐 Configurar firewall (ufw)
echo "🛡️ Configurando firewall..."
ufw allow "443/tcp"
echo "✅ Firewall configurado."

# 🌐 Crear sitios en EasyEngine con SSL
create_site() {
    local domain=$1
    if ee site list | grep -q "$domain"; then
        echo "⚠️ El sitio $domain ya existe en EasyEngine."
    else
        echo "🚀 Creando sitio $domain con EasyEngine..."
        ee site create "$domain" --ssl=custom --ssl-crt="$SSL_CERT" --ssl-key="$SSL_KEY"
    fi
}

create_site "$BACKEND_DOMAIN"
create_site "$FRONTEND_DOMAIN"

# 🏗️ Creación de estructura del backend y frontend
mkdir -p "$BACKEND_PATH"
mkdir -p "$FRONTEND_PATH"

# 📜 Configurar Proxy Inverso para Backend en Nginx
cat <<EOF > "$NGINX_CONFIG_BACKEND"
location / {
    proxy_pass http://127.0.0.1:$BACKEND_PORT;
    proxy_set_header Host \$host;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto \$scheme;
}
EOF

# 📜 Configurar Proxy Inverso para Frontend en Nginx
cat <<EOF > "$NGINX_CONFIG_FRONTEND"
location / {
    proxy_pass http://127.0.0.1:$FRONTEND_PORT;
    proxy_set_header Host \$host;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto \$scheme;
}
EOF

# 🔄 Recargar Nginx con EasyEngine
echo "🔄 Recargando Nginx..."
ee site reload "$BACKEND_DOMAIN"
ee site reload "$FRONTEND_DOMAIN"

# 🚀 Levantar backend y frontend
cd "$BACKEND_PATH" && docker-compose up -d
cd "$FRONTEND_PATH" && docker-compose up -d

echo "🎉 Infraestructura lista. Accede a:"
echo "👉 Backend (FastAPI): https://$BACKEND_DOMAIN/"
echo "👉 Frontend (Vue 3 con Vite): https://$FRONTEND_DOMAIN/"
