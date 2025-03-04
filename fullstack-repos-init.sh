#!/bin/bash
 
set -e  # ⛔ Detener ejecución si hay error

sudo apt update && sudo apt install gh -y
echo "? What account do you want to log into? 📌GitHub.com"
echo "? What is your preferred protocol for Git operations? 📌HTTPS"
echo "? Authenticate Git with your GitHub credentials? 📌Yes"
echo "? How would you like to authenticate GitHub CLI? 📌Login with a web browser"
gh auth login

# 📌 Datos de usuario y repos
GITHUB_USER="jupahefi"
BACKEND_REPO="tl-showroom-backend-poc"
FRONTEND_REPO="tl-showroom-frontend-poc"

# 🔑 Usa SSH en vez de HTTPS
BACKEND_REPO_URL="git@github.com:$GITHUB_USER/$BACKEND_REPO.git"
FRONTEND_REPO_URL="git@github.com:$GITHUB_USER/$FRONTEND_REPO.git"

# 🚀 Función para crear el repo en GitHub si no existe
create_github_repo() {
    local repo_name="$1"

    echo "🔍 Verificando si el repositorio $repo_name existe en GitHub..."
    if ! gh repo view "$GITHUB_USER/$repo_name" &> /dev/null; then
        echo "⚠️ El repositorio no existe. Creándolo en GitHub..."
        gh repo create "$GITHUB_USER/$repo_name" --private --confirm
    else
        echo "✅ El repositorio $repo_name ya existe en GitHub."
    fi
}

# 🚀 Función para inicializar y subir un repositorio
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
    fi

    echo "📦 Agregando archivos y haciendo commit..."
    git add .
    git commit -m "Initial commit" || echo "⚠️ No hay cambios para commitear"

    echo "🚀 Subiendo cambios a GitHub..."
    git branch -M main
    git push -u origin main
}

# 🏗️ Crear repos y subir código
init_repo "/opt/easyengine/sites/tl-showroom.equalitech.xyz/app/backend" "$BACKEND_REPO_URL" "$BACKEND_REPO"
init_repo "/opt/frontend/showroom-frontend" "$FRONTEND_REPO_URL" "$FRONTEND_REPO"

echo "🎉 Repositorios creados y sincronizados con GitHub."
