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

# 🛠️ Función para pedir contraseña sin mostrar en pantalla
ask_sensitive_var() {
    local var_name="$1"
    local default_value="$2"
    local user_input

    echo "🔑 Ingresa $var_name (oculto, presiona Enter para usar el valor por defecto)"
    read -s -p "🔹 Contraseña [$default_value]: " user_input
    echo ""  # Salto de línea

    # 🔥 Eliminar dobles comillas para evitar errores en el .env
    echo "${user_input//\"/}"  
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
DB_USER='$DB_USER'
DB_PASS='$DB_PASS'
DB_NAME='$DB_NAME'
SITE_DOMAIN='$SITE_DOMAIN'
SUBDOMAIN='$SUBDOMAIN'
FULL_DOMAIN='$FULL_DOMAIN'
FASTAPI_PORT='$FASTAPI_PORT'
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

echo "✅ Todas las variables del .env fueron cargadas correctamente."
