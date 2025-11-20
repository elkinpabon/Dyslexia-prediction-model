"""
Script para inicializar la base de datos con las tablas correctas
"""
import os
import sys

# Agregar el directorio app al path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'app'))

from app import create_app
from app.models.database import db

def init_database():
    """Crea todas las tablas en la base de datos"""
    app = create_app()
    
    with app.app_context():
        try:
            print("🔨 Creando tablas en la base de datos...")
            
            # Crear todas las tablas
            db.create_all()
            
            print("\n✅ Tablas creadas exitosamente:")
            print("   - users")
            print("   - children")
            print("   - test_results")
            print("   - activity_rounds")
            
        except Exception as e:
            print(f"\n❌ Error al crear las tablas: {e}")
            raise

if __name__ == '__main__':
    init_database()
