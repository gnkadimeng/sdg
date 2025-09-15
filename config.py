import os
import psycopg2

SECRET_KEY = os.getenv("SECRET_KEY", "6ce255c00e63d46c5af17afd44fdccb3")

    
    # Online database
def get_db_connection():
    try:
        conn = psycopg2.connect(
            dbname=os.getenv("DB_NAME", "randrefinerydb_hdcz"),  
            user=os.getenv("DB_USER", "randrefinerydb_hdcz_user"),    
            password=os.getenv("DB_PASSWORD", "NJY9sBdbbw3Sipd0gFGhHFjlLoiWnaaD"),  
            host=os.getenv("DB_HOST", "dpg-cudl8flumphs73cpbcj0-a"),  
            port=os.getenv("DB_PORT", "5432")  
        )
        print("✅ Database Connection Successful!")
        return conn
    except Exception as e:
        print(f"❌ Database Connection Error: {e}")
        return None


#offline database
# def get_db_connection():
#     try:
#         conn = psycopg2.connect(
#             dbname=os.getenv("DB_NAME", "sustain_app"),
#             user=os.getenv("DB_USER", "postgres"),
#             password=os.getenv("DB_PASSWORD", "V@lidation@uj2025"),
#             host=os.getenv("DB_HOST", "localhost"),
#             port=os.getenv("DB_PORT", "5432")
#         )
#         return conn
#     except Exception as e:
#         print("Error connecting to PostgreSQL database:", e)
#         return None
    
# def get_db_connection():
#     try:
#         conn = psycopg2.connect(
#             dbname=os.getenv("DB_NAME", "sustainability_app"),
#             user=os.getenv("DB_USER", "postgres"),
#             password=os.getenv("DB_PASSWORD", "Musa"),
#             host=os.getenv("DB_HOST", "localhost"),
#             port=os.getenv("DB_PORT", "5432")
#         )
#         return conn
#     except Exception as e:
#         print("Error connecting to PostgreSQL database:", e)
#         return None


ADMIN_EMAIL = "admin@example.com"
ADMIN_PASSWORD = "securepassword123"  # In production, use environment variables