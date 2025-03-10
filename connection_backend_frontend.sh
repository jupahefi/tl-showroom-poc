#!/bin/bash

set -e  # ⛔ Detener ejecución si hay error

# 📌 Cargar variables desde `.env`
ENV_FILE=".env"
if [[ -f "$ENV_FILE" ]]; then
    export $(grep -v '^#' "$ENV_FILE" | xargs -d '\n')  # 🛠️ Evita errores con espacios en valores
else
    echo "❌ ERROR: No se encontró el archivo .env. Ejecuta 'init.sh' primero."
    exit 1
fi

echo "✅ Variables de entorno cargadas correctamente."

# 📌 Función para limpiar el dominio (quitar puntos `.`)
clean_domain() {
    echo "$1" | tr -d '.'
}

# 📌 Generar el nombre correcto de la red de EasyEngine
NETWORK_NAME="$(clean_domain "$FULL_DOMAIN")_$FULL_DOMAIN"

echo "🔗 Conectando backend a la red de EasyEngine..."
if docker network connect $NETWORK_NAME showroom-api; then
    echo "✅ Conexión de red exitosa."
else
    echo "⚠️ Advertencia: No se pudo conectar showroom-api a la red de EasyEngine. Verifica manualmente."
fi
