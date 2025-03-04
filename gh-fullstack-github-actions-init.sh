#!/bin/bash

set -e  # ⛔ Detener ejecución si hay error

# 📌 Configuración del repositorio y servidor
GITHUB_USER="jupahefi"
BACKEND_REPO="tl-showroom-backend-poc"
FRONTEND_REPO="tl-showroom-frontend-poc"
SERVER_USER="usuario"   # Cambia esto por tu usuario SSH
SERVER_IP="tu-servidor" # IP o dominio del servidor

# 📂 Rutas en el servidor
BACKEND_PATH="/opt/easyengine/sites/tl-showroom.equalitech.xyz/app/backend"
FRONTEND_PATH="/opt/frontend/showroom-frontend"

# 🔐 Configurar SSH para GitHub Actions
echo "🔑 Generando clave SSH para GitHub Actions..."
ssh-keygen -t rsa -b 4096 -C "deploy@github-actions" -f github_actions_key -N ""
echo "✅ Clave SSH generada: github_actions_key"

echo "📋 Copia esta clave pública y agrégala en GitHub → Settings → Deploy Keys en ambos repos:"
cat github_actions_key.pub
echo "⚠️ Presiona ENTER cuando hayas agregado la clave en ambos repos"
read

# 🛠️ Agregar la clave privada como GitHub Secret en ambos repos
echo "🔐 Agregando clave privada a GitHub Secrets..."
gh secret set SSH_PRIVATE_KEY --body "$(cat github_actions_key)" --repo "$GITHUB_USER/$BACKEND_REPO"
gh secret set SSH_PRIVATE_KEY --body "$(cat github_actions_key)" --repo "$GITHUB_USER/$FRONTEND_REPO"
echo "✅ Clave agregada a los secrets de GitHub."

# 🚀 Función para crear el workflow
create_workflow() {
    local repo_path="$1"
    local repo_name="$2"
    local workflow_file="$repo_path/.github/workflows/deploy.yml"

    echo "📄 Creando workflow en $repo_name..."
    mkdir -p "$repo_path/.github/workflows"

    cat <<EOF > "$workflow_file"
name: Deploy $repo_name

on:
  push:
    branches:
      - main

jobs:
  deploy:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout código
        uses: actions/checkout@v4

      - name: Desplegar en el servidor
        env:
          SSH_PRIVATE_KEY: \${{ secrets.SSH_PRIVATE_KEY }}
        run: |
          echo "\$SSH_PRIVATE_KEY" > private_key && chmod 600 private_key
          ssh -o StrictHostKeyChecking=no -i private_key $SERVER_USER@$SERVER_IP "cd $repo_path && git pull origin main && ./deploy.sh"
EOF
    echo "✅ Workflow creado en $repo_name"
}

# 📦 Crear workflows en backend y frontend
create_workflow "$BACKEND_PATH" "$BACKEND_REPO"
create_workflow "$FRONTEND_PATH" "$FRONTEND_REPO"

# 🚀 Hacer commit y push de los workflows
commit_and_push() {
    local repo_path="$1"
    local repo_name="$2"

    echo "📤 Subiendo workflow a $repo_name..."
    cd "$repo_path"
    git add .github/workflows/deploy.yml
    git commit -m "Add GitHub Actions workflow for deployment"
    git push origin main
    echo "✅ Workflow subido a $repo_name"
}

commit_and_push "$BACKEND_PATH" "$BACKEND_REPO"
commit_and_push "$FRONTEND_PATH" "$FRONTEND_REPO"

echo "🎉 ¡Workflows de GitHub Actions creados y subidos! 🚀"
echo "👉 Ahora cada push a 'main' hará deploy automático en el servidor."
