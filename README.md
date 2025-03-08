# 📌 TL Showroom Infra PoC

Este repositorio contiene scripts automatizados para la instalación y despliegue de una aplicación web fullstack utilizando **EasyEngine**, **Docker Compose**, **FastAPI**, **PostgreSQL**, **Vue 3 + Vite** y **GitHub Actions**.

## 🚀 Tecnologías Utilizadas

- **EasyEngine**: Administra el frontend con **Nginx autoadministrado**.
- **Docker Compose**: Orquesta el backend con **FastAPI** y **PostgreSQL**.
- **Vue 3 + Vite**: Framework frontend desplegado mediante EasyEngine.
- **GitHub CLI + GitHub Actions**: Automatización de repositorios y despliegues.

---

## 🛠️ Instalación Paso a Paso

### 1️⃣ Configuración del Entorno
```bash
bash environment-ini.sh
```
Instala **EasyEngine**, configura el sistema y prepara los certificados SSL.

### 2️⃣ Instalación del Frontend
```bash
bash frontend-init.sh
```
Configura **Vue 3 + Vite**, instala dependencias y prepara el entorno de EasyEngine.

### 3️⃣ Creación de Repositorios en GitHub
```bash
bash fullstack-repos.sh
```
Automatiza la creación de repositorios para el frontend y backend en **GitHub**.

### 4️⃣ Configuración de GitHub Actions
```bash
bash gh-fullstack.sh
```
Configura **GitHub Actions** para CI/CD en ambos repositorios.

### 5️⃣ Conexión Backend - Frontend
```bash
bash connection_backend_frontend.sh
```
Conecta el backend (Docker) con el frontend (EasyEngine) permitiendo que Nginx acceda correctamente a FastAPI.

---

## 🔗 Arquitectura del Proyecto

1. **Backend:**
   - FastAPI + PostgreSQL en Docker Compose.
   - Base de datos segura (solo accesible internamente).
   - Conexión con Nginx mediante **proxy_pass**.

2. **Frontend:**
   - Vue 3 + Vite.
   - Servido con EasyEngine (integrado con Nginx).
   - Conexión HTTPS al backend a través de EasyEngine.

3. **DevOps:**
   - GitHub Actions para despliegue automático.
   - CI/CD para mantener el sistema actualizado.

---

## 🎯 Notas Importantes
- **Este script está diseñado exclusivamente para entornos con EasyEngine**.
- **Requiere acceso a GitHub CLI para la creación de repositorios**.
- **Los contenedores de Docker deben estar en la misma red que EasyEngine para funcionar correctamente**.

🔹 Con esta infraestructura, logras un **despliegue automatizado, seguro y escalable** de tu aplicación web. 🚀

