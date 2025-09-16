import os
import psycopg2

SECRET_KEY = os.getenv("SECRET_KEY", "6ce255c00e63d46c5af17afd44fdccb3")

def get_db_connection():
    try:
        conn = psycopg2.connect(
            dbname=os.getenv("DB_NAME", "sustainability_app"),
            user=os.getenv("DB_USER", "postgres"),
            password=os.getenv("DB_PASSWORD", "Musa"),
            host=os.getenv("DB_HOST", "localhost"),
            port=os.getenv("DB_PORT", "5432")
        )
        print("✅ Connected to PostgreSQL")
        return conn
    except Exception as e:
        print("❌ Failed to connect to PostgreSQL:", e)
        return None

ADMIN_EMAIL = "admin@example.com"
ADMIN_PASSWORD = "securepassword123"  # In production, use environment variables
