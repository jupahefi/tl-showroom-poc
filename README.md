🚀 Infraestructura Fullstack Ágil con EasyEngine, Docker y GitHub Actions

🔍 La Solución: Despliegue Automático de Aplicaciones Web

Este framework permite desplegar y administrar aplicaciones web automáticamente, eliminando la fricción técnica y reduciendo el tiempo de configuración de días a minutos.

✔️ Ideal para desarrolladores y equipos que quieren enfocarse en código, no en infraestructura.
✔️ Manejo automatizado de servidores, dominios, SSL, backend y frontend.
✔️ Integrado con GitHub para versionado y despliegue continuo.

🛠️ ¿Qué incluye esta infraestructura?

📌 Administración de Infraestructura

✅ EasyEngine: Administra sitios con Nginx + Docker + Let’s Encrypt (SSL)
✅ Firewall (UFW): Protege el backend, permitiendo solo acceso interno desde Docker
✅ GitHub CLI: Creación automática de repositorios y subida de código
✅ GitHub Actions (en progreso): Automatización del despliegue

📌 Backend (FastAPI + Docker)

✅ API en FastAPI
✅ Aislado con Docker y solo accesible desde la red interna
✅ Configurado para PostgreSQL con Docker Compose

📌 Frontend (Vue + Vite)

✅ Construcción y despliegue automático con Nginx
✅ Optimizado para producción

📜 Scripts de Infraestructura

🔹 environment-init.sh

Configura el entorno y solicita al usuario solo los datos mínimos necesarios:
📌 Dominio raíz y subdominio
📌 Credenciales de base de datos
📌 Puerto del backend

🔹 backend-init.sh

📌 Crea la API en FastAPI dentro de un contenedor Docker
📌 Configura la base de datos PostgreSQL con Docker Compose
📌 Asegura que solo el frontend puede acceder al backend mediante UFW

🔹 frontend-init.sh

📌 Configura Vue + Vite y lo despliega automáticamente en el servidor
📌 Mueve los archivos estáticos al servidor de EasyEngine
📌 Se asegura de que Nginx sirva el frontend correctamente

🔹 fullstack-repos-init.sh

📌 Crea y configura repositorios en GitHub automáticamente
📌 Sube el código de backend y frontend a GitHub
📌 Se prepara para integración con GitHub Actions

⚠️ Estado actual

# 🚀 Configuración manual de claves SSH y despliegue

## 1️⃣ **Generar clave SSH manualmente**
En tu máquina local, genera una clave SSH:
```bash
ssh-keygen -t rsa -b 4096 -m PEM -C "deploy@github-actions" -f ~/.ssh/github_actions_key -N ""
```
Esto generará dos archivos:
- `~/.ssh/github_actions_key` (clave privada)
- `~/.ssh/github_actions_key.pub` (clave pública)

## 2️⃣ **Agregar la clave pública al servidor**

Copia manualmente la clave pública al servidor:
```bash
cat ~/.ssh/github_actions_key.pub | ssh root@tl-showroom.equalitech.xyz "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"
```
Si tienes acceso físico al servidor, también puedes agregar la clave en `~/.ssh/authorized_keys` manualmente.

## 3️⃣ **Agregar la clave privada a GitHub Secrets**
Para cada repositorio, agrega la clave privada como secreto:
```bash
gh secret set SSH_PRIVATE_KEY --body "$(cat ~/.ssh/github_actions_key)" --repo jupahefi/tl-showroom-backend-poc
gh secret set SSH_PRIVATE_KEY --body "$(cat ~/.ssh/github_actions_key)" --repo jupahefi/tl-showroom-frontend-poc
```

## 4️⃣ **Configurar el despliegue manualmente**
Dentro del servidor, asegúrate de que los permisos son correctos:
```bash
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
```
Luego, prueba la conexión:
```bash
ssh -i ~/.ssh/github_actions_key root@tl-showroom.equalitech.xyz
```
Si todo está correcto, deberías poder conectarte sin problemas.

## 5️⃣ **Desplegar manualmente**
Para desplegar en el servidor, ejecuta:
```bash
ssh -i ~/.ssh/github_actions_key root@tl-showroom.equalitech.xyz << 'EOF'
cd /opt/easyengine/sites/tl-showroom.equalitech.xyz/app/backend
git pull origin main
bash deploy.sh
EOF
```



🚧 Frontend aún no se comunica correctamente con el backend (error menor por resolver).
🚧 GitHub Actions en proceso de optimización para despliegue automático.

Con esta infraestructura, crear, desplegar y administrar una aplicación web completa se reduce a ejecutar un par de scripts. 🏗️⚡
