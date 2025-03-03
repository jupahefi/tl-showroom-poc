#!/bin/bash

echo "🚀 Iniciando configuración del entorno..."

# 1️⃣ Cargar variables desde .env
if [ -f .env ]; then
    source .env
else
    echo "❌ Error: Archivo .env no encontrado."
    exit 1
fi

# 2️⃣ Verificar si PostgreSQL está instalado
if ! command -v psql &> /dev/null; then
    echo "⚠️ PostgreSQL no está instalado. Instalando..."
    
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        sudo apt update && sudo apt install -y postgresql postgresql-contrib
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        brew install postgresql
    else
        echo "❌ Error: No se pudo detectar el sistema operativo."
        exit 1
    fi
    echo "✅ PostgreSQL instalado correctamente."
else
    echo "✅ PostgreSQL ya está instalado."
fi

# 3️⃣ Verificar si PostgreSQL está corriendo
if ! systemctl is-active --quiet postgresql; then
    echo "⚠️ PostgreSQL no está corriendo. Iniciando servicio..."
    sudo systemctl start postgresql
fi

# 4️⃣ Crear usuario de sistema si no existe
if ! id "$SO_USER" &>/dev/null; then
    echo "👤 Creando usuario de sistema: $SO_USER..."
    sudo useradd -m -s /bin/bash "$SO_USER"
    echo "✅ Usuario $SO_USER creado."
else
    echo "👤 Usuario $SO_USER ya existe, omitiendo..."
fi

# 5️⃣ Crear usuario y base de datos en PostgreSQL
sudo -i -u postgres psql <<EOF
DO \$\$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = '$DB_USER') THEN
        CREATE USER $DB_USER WITH PASSWORD '$DB_PASS';
        ALTER USER $DB_USER CREATEDB;
        RAISE NOTICE 'Usuario $DB_USER creado.';
    ELSE
        RAISE NOTICE 'Usuario $DB_USER ya existe, omitiendo...';
    END IF;
END
\$\$;

CREATE DATABASE $DB_NAME OWNER $DB_USER;
GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;
EOF

echo "✅ Configuración de PostgreSQL completada."

# 6️⃣ Instalar Python y dependencias
echo "🐍 Configurando entorno Python..."

# Verificar si Python está instalado
if ! command -v python3 &> /dev/null; then
    echo "⚠️ Python3 no está instalado. Instalando..."
    
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        sudo apt update && sudo apt install -y python3 python3-venv python3-pip
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        brew install python3
    fi

    echo "✅ Python3 instalado correctamente."
else
    echo "✅ Python3 ya está instalado."
fi

# Crear y activar entorno virtual
if [ ! -d "venv" ]; then
    echo "🐍 Creando entorno virtual..."
    python3 -m venv venv
fi

echo "🐍 Activando entorno virtual..."
source venv/bin/activate

# Instalar dependencias
echo "📦 Instalando dependencias desde requirements.txt..."
pip install --upgrade pip
pip install -r requirements.txt

echo "✅ Entorno Python configurado."
echo "🚀 Setup finalizado. ¡A programar!"
