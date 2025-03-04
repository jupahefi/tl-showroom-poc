#!/bin/bash

set -e  # ⛔ Detener ejecución si hay error

# 📌 Variables de entorno
FRONTEND_DIR="/opt/frontend"
PROJECT_NAME="showroom-frontend"
DOMAIN="tl-showroom.equalitech.xyz"
SITE_DOMAIN="equalitech.xyz"
NGINX_CONFIG="/opt/easyengine/sites/$DOMAIN/config/nginx/custom/frontend.conf"
SSL_CERT="/etc/letsencrypt/live/$SITE_DOMAIN/fullchain.pem"
SSL_KEY="/etc/letsencrypt/live/$SITE_DOMAIN/privkey.pem"

# 📜 Función para crear o reemplazar archivos
create_or_replace_file() {
    local file_path="$1"
    local content="$2"

    if [[ -f "$file_path" ]]; then
        echo "🗑️ Eliminando archivo existente: $file_path"
        rm "$file_path"
    fi

    echo "📄 Creando archivo: $file_path"
    echo "$content" > "$file_path"
}

# 🛠️ Verificar si Node.js y npm están instalados
if ! command -v node &> /dev/null; then
    echo "🔹 Node.js no encontrado. Instalando..."
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
    apt-get install -y nodejs
fi

# 🛠️ Instalar Vite y Vue globalmente
echo "📦 Instalando Vite y Vue..."
npm install -g create-vite

# 📂 Crear la carpeta del frontend si no existe
mkdir -p "$FRONTEND_DIR"
cd "$FRONTEND_DIR"

# 🗑️ Eliminar el proyecto existente si ya está creado
if [[ -d "$PROJECT_NAME" ]]; then
    echo "🗑️ Eliminando proyecto existente: $PROJECT_NAME"
    rm -rf "$PROJECT_NAME"
fi

# 🚀 Crear un nuevo proyecto con Vite y Vue 3 (TypeScript)
echo "🚀 Creando nuevo proyecto Vite + Vue 3 (TypeScript)..."
npm create vite@latest "$PROJECT_NAME" --template vue-ts --yes

# 📂 Entrar al proyecto y configurar dependencias
cd "$PROJECT_NAME"
echo "📦 Instalando dependencias..."
npm install
npm install axios vue-tsc

# 📜 Configurar TypeScript para Vue
create_or_replace_file "src/env.d.ts" \
'/// <reference types="vite/client" />
declare module "*.vue" {
    import { DefineComponent } from "vue";
    const component: DefineComponent<{}, {}, any>;
    export default component;
}'

# 📜 Configurar `vite.config.ts` para soportar Vue
create_or_replace_file "vite.config.ts" \
'import { defineConfig } from "vite";
import vue from "@vitejs/plugin-vue";

export default defineConfig({
    plugins: [vue()],
    server: {
        host: true,
        port: 5173,
        strictPort: true
    },
    build: {
        outDir: "dist"
    }
});'

# 📜 Crear un componente Vue que consume el backend
create_or_replace_file "src/components/BackendData.vue" \
'<script setup lang="ts">
import { ref, onMounted } from "vue";
import axios from "axios";

interface ApiResponse {
    message?: string;
    error?: string;
}

const backendData = ref<ApiResponse | null>(null);

onMounted(async () => {
    try {
        const response = await axios.get<ApiResponse>("/api/");
        backendData.value = response.data;
    } catch (error) {
        backendData.value = { error: "No se pudo conectar al backend" };
    }
});
</script>

<template>
    <div>
        <h2>🚀 FastAPI Response:</h2>
        <pre>{{ backendData }}</pre>
    </div>
</template>'

# 📜 Modificar App.vue para mostrar el mensaje y la respuesta del backend
create_or_replace_file "src/App.vue" \
'<script setup lang="ts">
import BackendData from "./components/BackendData.vue";
</script>

<template>
    <h1>🚀 Vue + Vite con HTTPS y FastAPI</h1>
    <BackendData />
</template>'

# 📦 Construir la aplicación
echo "🏗️ Construyendo frontend..."
npm run build

# 📂 Mover archivos estáticos correctamente
echo "📂 Moviendo archivos estáticos a /htdocs..."
rsync -av --delete /opt/frontend/showroom-frontend/dist/ /opt/easyengine/sites/$DOMAIN/app/htdocs/

# 🔄 Recargar Nginx con EasyEngine
echo "🔄 Recargando Nginx con EasyEngine..."
ee site reload "$DOMAIN"

echo "🎉 Frontend desplegado con éxito."
echo "👉 Accede en: https://$DOMAIN"
