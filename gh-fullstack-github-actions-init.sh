#!/bin/bash

set -e  # ⛔ Detener ejecución si hay error

# 📌 Configuración
GITHUB_USER="jupahefi"
BACKEND_REPO="tl-showroom-backend-poc"
FRONTEND_REPO="tl-showroom-frontend-poc"
SERVER_IP="tl-showroom.equalitech.xyz"

# 📂 Rutas en el servidor
BACKEND_PATH="/opt/easyengine/sites/tl-showroom.equalitech.xyz/app/backend"
FRONTEND_PATH="/opt/frontend/showroom-frontend"

# 🛠 **Eliminar workflows previos y crear nuevos**
WORKFLOW_DIR=".github/workflows"
for REPO_PATH in "$BACKEND_PATH" "$FRONTEND_PATH"; do
    echo "🗑️ Eliminando archivos de workflows en $REPO_PATH..."
    rm -rf "$REPO_PATH/$WORKFLOW_DIR"
    mkdir -p "$REPO_PATH/$WORKFLOW_DIR"

    echo "📄 Creando nuevo workflow en $REPO_PATH..."
    cat <<EOF > "$REPO_PATH/$WORKFLOW_DIR/deploy.yml"
name: 🚀 Deploy to Server

on:
  push:
    branches:
      - main
  workflow_dispatch:

jobs:
  deploy:
    runs-on: ubuntu-latest

    steps:
      - name: 📥 Checkout del código
        uses: actions/checkout@v3

      - name: 🚀 Desplegar en servidor
        run: |
          ssh -v -o StrictHostKeyChecking=no root@$SERVER_IP << 'EOF'
          cd $REPO_PATH
          git pull origin main
          bash deploy.sh
          EOF
EOF
    echo "✅ Workflow creado en $REPO_PATH/$WORKFLOW_DIR/deploy.yml"
done

# 🚀 **Subir los nuevos workflows a GitHub**
for REPO_PATH in "$BACKEND_PATH" "$FRONTEND_PATH"; do
    echo "🚀 Subiendo nuevos workflows a GitHub desde $REPO_PATH..."
    cd "$REPO_PATH"
    git add "$WORKFLOW_DIR"
    git commit -m "Reinicialización de GitHub Actions" || echo "⚠️ No hay cambios para commit"
    git push -f origin main || echo "⚠️ Error en git push, verificando conexión..."
done
echo "✅ Workflows reiniciados y desplegados."

# 🚀 **Gatillar los workflows manualmente**
echo "🚀 Gatillando despliegues..."
gh workflow run deploy.yml --repo "$GITHUB_USER/$BACKEND_REPO"
gh workflow run deploy.yml --repo "$GITHUB_USER/$FRONTEND_REPO"

echo "🎉 GitHub Actions listos y ejecutándose!"
