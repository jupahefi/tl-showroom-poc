# 📌 Configuración de SSH para Despliegue en el Servidor

Antes de poder desplegar correctamente en el servidor, es necesario configurar las claves SSH en la máquina local y en el servidor. Sigue estos pasos para asegurarte de que la autenticación funcione correctamente.

## **1️⃣ Verificar si ya tienes una clave SSH**
Ejecuta el siguiente comando para ver si tienes claves SSH existentes:
```bash
ls -la ~/.ssh/
```
Si ves archivos como `id_rsa` y `id_rsa.pub`, entonces ya tienes una clave SSH generada.

Para visualizar tu clave pública, usa:
```bash
cat ~/.ssh/id_rsa.pub
```

## **2️⃣ Generar una nueva clave SSH (si no tienes una)**
Si no tienes una clave, genera una nueva:
```bash
ssh-keygen -t rsa -b 4096 -C "juan@macbook"
```
📍 **Nota**: No sobrescribas una clave existente a menos que estés seguro. Si ya tienes `id_rsa`, usa un nombre como `id_rsa_nueva`.

Luego, agrega la clave al **agente SSH**:
```bash
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_rsa
```

## **3️⃣ Agregar la clave pública en el servidor**
Una vez que tengas la clave pública (`id_rsa.pub`), necesitas copiarla al servidor:

Si `ssh-copy-id` está disponible:
```bash
ssh-copy-id -i ~/.ssh/id_rsa.pub root@equalitech.xyz
```

Si no, agrégala manualmente:
```bash
cat ~/.ssh/id_rsa.pub | ssh root@equalitech.xyz "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"
```

## **4️⃣ Liberar el servidor de claves antiguas (opcional, si hay problemas)**
Si cambiaste de clave, libera el servidor de registros antiguos:
```bash
ssh-keygen -R equalitech.xyz
ssh-keygen -R 64.176.8.31  # Si lo tienes guardado por IP
```

## **5️⃣ Probar conexión SSH**
Intenta conectarte para verificar que todo esté funcionando:
```bash
ssh root@equalitech.xyz
```
Si la conexión es exitosa, ya puedes proceder con el despliegue.

---
✅ **Con esta configuración, el servidor está listo para recibir despliegues desde GitHub Actions y desde tu máquina local!** 🚀

