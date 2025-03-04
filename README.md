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

🚧 Frontend aún no se comunica correctamente con el backend (error menor por resolver).
🚧 GitHub Actions en proceso de optimización para despliegue automático.

Con esta infraestructura, crear, desplegar y administrar una aplicación web completa se reduce a ejecutar un par de scripts. 🏗️⚡
