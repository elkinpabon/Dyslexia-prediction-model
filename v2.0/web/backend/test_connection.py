"""
Script para probar la conexión a Railway MySQL
"""
import pymysql
import os
from dotenv import load_dotenv

load_dotenv()

def test_connection():
    """Probar conexión a MySQL"""
    print("🔍 Probando conexión a Railway MySQL...")
    print(f"   Host: {os.getenv('MYSQLHOST')}")
    print(f"   Port: {os.getenv('MYSQLPORT')}")
    print(f"   Database: {os.getenv('MYSQLDATABASE')}")
    print(f"   User: {os.getenv('MYSQLUSER')}")
    
    try:
        connection = pymysql.connect(
            host=os.getenv('MYSQLHOST'),
            port=int(os.getenv('MYSQLPORT')),
            user=os.getenv('MYSQLUSER'),
            password=os.getenv('MYSQLPASSWORD'),
            database=os.getenv('MYSQLDATABASE'),
            charset='utf8mb4'
        )
        
        print("✅ Conexión exitosa!")
        
        # Probar una consulta simple
        with connection.cursor() as cursor:
            cursor.execute("SELECT VERSION()")
            version = cursor.fetchone()
            print(f"   MySQL Version: {version[0]}")
            
            cursor.execute("SHOW TABLES")
            tables = cursor.fetchall()
            if tables:
                print(f"   Tablas existentes: {len(tables)}")
                for table in tables:
                    print(f"     - {table[0]}")
            else:
                print("   No hay tablas creadas aún")
        
        connection.close()
        print("\n✅ Prueba de conexión completada exitosamente!")
        return True
        
    except Exception as e:
        print(f"\n❌ Error de conexión: {str(e)}")
        return False

if __name__ == '__main__':
    test_connection()
