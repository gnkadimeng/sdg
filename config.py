import os
import psycopg2

SECRET_KEY = os.getenv("SECRET_KEY", "6ce255c00e63d46c5af17afd44fdccb3")

def get_db_connection():
    try:
        conn = psycopg2.connect(
            dbname=os.getenv("DB_NAME"),
            user=os.getenv("DB_USER"),
            password=os.getenv("DB_PASSWORD"),
            host=os.getenv("DB_HOST"),
            port=os.getenv("DB_PORT", 5432)
        )
        print("✅ Connected to PostgreSQL")
        return conn
    except Exception as e:
        print("❌ Failed to connect to PostgreSQL:", e)
        return None

