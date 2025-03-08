#!/bin/bash

set -e  # ⛔ Detener ejecución si hay error

echo "🚀 Iniciando despliegue de Repositorios para backend y front end..."

# 📌 Instalar `gh` si no está presente
if ! command -v gh &>/dev/null; then
    echo "🔹 Instalando GitHub CLI..."
    sudo apt update && sudo apt install -y gh
fi

# 🔐 Autenticación con GitHub (HTTPS)
if ! gh auth status &>/dev/null; then
    echo "🔑 Autenticando con GitHub..."
    gh auth login
else
    echo "✅ Ya estás autenticado en GitHub."
fi

# 📌 Configurar Git para usar HTTPS en lugar de SSH
git config --global url."https://github.com/".insteadOf "git@github.com:"

# 📌 Datos de usuario y repos
GITHUB_USER="jupahefi"
BACKEND_REPO="tl-showroom-backend-poc"
FRONTEND_REPO="tl-showroom-frontend-poc"

# 🔑 URLs HTTPS en lugar de SSH
BACKEND_REPO_URL="https://github.com/$GITHUB_USER/$BACKEND_REPO.git"
FRONTEND_REPO_URL="https://github.com/$GITHUB_USER/$FRONTEND_REPO.git"

# 🚀 Función para crear el repo en GitHub si no existe
create_github_repo() {
    local repo_name="$1"
    echo "🔍 Verificando si el repositorio $repo_name existe en GitHub..."

    if ! gh repo view "$GITHUB_USER/$repo_name" &>/dev/null; then
        echo "⚠️ El repositorio no existe. Creándolo en GitHub..."
        gh repo create "$GITHUB_USER/$repo_name" --private --confirm
    else
        echo "✅ El repositorio $repo_name ya existe en GitHub."
    fi
}

# 🚀 Función para inicializar y sincronizar un repositorio
init_repo() {
    local repo_path="$1"
    local repo_url="$2"
    local repo_name="$3"

    create_github_repo "$repo_name"

    echo "📂 Navegando a $repo_path..."
    cd "$repo_path"

    if [ ! -d ".git" ]; then
        echo "🛠️ Inicializando repositorio Git..."
        git init
        git remote add origin "$repo_url"
    else
        echo "🔄 Repositorio ya inicializado. Verificando conexión con remote..."
        if ! git remote -v | grep -q "$repo_url"; then
            echo "⚠️ Remote no configurado correctamente. Ajustándolo..."
            git remote set-url origin "$repo_url"
        fi
    fi

    # 🛠️ Verifica y corrige problemas en Git antes de continuar
    echo "🔄 Verificando estado del repositorio..."

    # 1️⃣ Cancela rebase pendiente si existe
    if git status | grep -q "rebase in progress"; then
        echo "⚠️ Rebase detectado. Abortando..."
        git rebase --abort
    fi

    # 2️⃣ Asegura que estamos en la rama `main`
    if ! git rev-parse --verify main &>/dev/null; then
        echo "⚠️ Rama 'main' no encontrada. Creándola..."
        git checkout -b main
    else
        git checkout main
    fi

    # 3️⃣ Resetea si hay inconsistencias y forzar el pull ignorando `Initial commit`
    if git status | grep -q "Initial commit"; then
        echo "⚠️ Detectado conflicto de 'Initial commit'. Forzando pull..."
        git fetch origin main
        git reset --hard origin/main
    else
        echo "🔄 Sincronizando con el remoto..."
        git pull --rebase origin main || git rebase --continue
    fi
}

# 🏗️ Crear repos y subir código de manera flexible
init_repo "/opt/easyengine/sites/tl-showroom.equalitech.xyz/app/backend" "$BACKEND_REPO_URL" "$BACKEND_REPO"
init_repo "/opt/frontend/showroom-frontend" "$FRONTEND_REPO_URL" "$FRONTEND_REPO"

# 📌 Crear los scripts de despliegue en los repositorios
echo "📜 Creando scripts de despliegue..."

# 🚀 Backend Deploy Script
cat <<EOF > /opt/easyengine/sites/tl-showroom.equalitech.xyz/app/backend/deploy.sh
#!/bin/bash

set -e

echo "🚀 Iniciando despliegue del backend..."

PROJECT_PATH="/opt/easyengine/sites/tl-showroom.equalitech.xyz/app/backend"
cd "\$PROJECT_PATH"

echo "📥 Actualizando código fuente desde Git..."
git pull origin main

echo "🐳 Construyendo imagen de Docker..."
docker-compose build --no-cache

echo "🔄 Reiniciando backend..."
docker-compose down
docker-compose up -d

echo "🔍 Verificando estado del backend..."
docker ps | grep showroom-api

echo "✅ Despliegue del backend completado."
EOF

chmod +x /opt/easyengine/sites/tl-showroom.equalitech.xyz/app/backend/deploy.sh

# 🚀 Frontend Deploy Script
cat <<EOF > /opt/frontend/showroom-frontend/deploy.sh
#!/bin/bash

set -e

echo "🚀 Iniciando despliegue del frontend..."

FRONTEND_DIR="/opt/frontend/showroom-frontend"
cd "\$FRONTEND_DIR"

echo "📥 Actualizando código fuente desde Git..."
git pull origin main

echo "📦 Instalando dependencias..."
npm install

echo "🏗️ Construyendo frontend..."
npm run build

echo "📂 Moviendo archivos estáticos a /htdocs..."
rsync -av --delete dist/ /opt/easyengine/sites/tl-showroom.equalitech.xyz/app/htdocs/

echo "🔄 Recargando Nginx..."
ee site reload tl-showroom.equalitech.xyz

echo "✅ Despliegue del frontend completado."
EOF

chmod +x /opt/frontend/showroom-frontend/deploy.sh

# 📦 Agregar archivos y hacer commit
echo "📦 Agregando archivos y haciendo commit..."
cd "/opt/easyengine/sites/tl-showroom.equalitech.xyz/app/backend"
git add deploy.sh
git commit -m "Agregar script de despliegue del backend" || echo "⚠️ No hay cambios para commitear"
git push -u origin main || echo "⚠️ No se pudo hacer push, revisar conflictos."

cd "/opt/frontend/showroom-frontend"
git add deploy.sh
git commit -m "Agregar script de despliegue del frontend" || echo "⚠️ No hay cambios para commitear"
git push -u origin main || echo "⚠️ No se pudo hacer push, revisar conflictos."

echo "🎉 Repositorios actualizados con los scripts de despliegue."

# ==================================
# 🚀 EJECUTAR LOS DEPLOYS
# ==================================
echo "🚀 Ejecutando despliegue del backend..."
/opt/easyengine/sites/tl-showroom.equalitech.xyz/app/backend/deploy.sh

echo "🚀 Ejecutando despliegue del frontend..."
/opt/frontend/showroom-frontend/deploy.sh

echo "✅ Despliegue finalizado correctamente."
