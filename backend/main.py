from fastapi import FastAPI, HTTPException
import psycopg2
import os

app = FastAPI()

# 📌 Configuración de PostgreSQL usando variables de entorno
DB_HOST = os.getenv("DB_HOST", "postgres")
DB_NAME = os.getenv("DB_NAME", "showroom_db")
DB_USER = os.getenv("DB_USER", "showroom_user")
DB_PASS = os.getenv("DB_PASS", "SuperSecurePass123")

def get_db_connection():
    return psycopg2.connect(
        host=DB_HOST, database=DB_NAME, user=DB_USER, password=DB_PASS
    )

@app.get("/users/{user_id}")
def get_user(user_id: int):
    conn = get_db_connection()
    cur = conn.cursor()
    cur.execute("SELECT id, name, role FROM users WHERE id = %s;", (user_id,))
    user = cur.fetchone()
    cur.close()
    conn.close()
    
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    return {"id": user[0], "name": user[1], "role": user[2]}
