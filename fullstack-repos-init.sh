#!/bin/bash

set -e  # ⛔ Detener ejecución si hay error

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

    # 3️⃣ Resolver conflictos en deploy.yml si existen (IGNORANDO Initial commit)
    if git status | grep -q ".github/workflows/deploy.yml"; then
        echo "⚠️ Conflicto detectado en deploy.yml, resolviendo automáticamente..."
        git checkout --theirs .github/workflows/deploy.yml
        git add .github/workflows/deploy.yml
        git rebase --continue || git rebase --abort
    fi

    # 4️⃣ Resetea si hay inconsistencias y forzar el pull ignorando `Initial commit`
    if git status | grep -q "Initial commit"; then
        echo "⚠️ Detectado conflicto de 'Initial commit'. Forzando pull..."
        git fetch origin main
        git reset --hard origin/main
    else
        echo "🔄 Sincronizando con el remoto..."
        #git pull --rebase origin main || echo "⚠️ No se pudo hacer pull, continuando..."
	git rebase --continue
    fi

    echo "📦 Agregando archivos y haciendo commit..."
    git add .
    git commit -m "Sync repo" || echo "⚠️ No hay cambios para commitear"

    echo "🚀 Subiendo cambios a GitHub..."
    git push -u origin main || echo "⚠️ No se pudo hacer push, revisar conflictos."
}

# 🏗️ Crear repos y subir código de manera flexible
init_repo "/opt/easyengine/sites/tl-showroom.equalitech.xyz/app/backend" "$BACKEND_REPO_URL" "$BACKEND_REPO"
init_repo "/opt/frontend/showroom-frontend" "$FRONTEND_REPO_URL" "$FRONTEND_REPO"

echo "🎉 Repositorios creados y sincronizados con GitHub."
