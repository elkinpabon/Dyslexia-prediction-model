"""
Script para limpiar completamente la base de datos MySQL
"""
import os
import sys

# Agregar el directorio app al path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'app'))

from app import create_app
from app.models.database import db, User, Child, TestResult, ActivityRound

def clear_database():
    """Elimina TODOS los datos de todas las tablas"""
    app = create_app()
    
    with app.app_context():
        try:
            print("🗑️  Eliminando todos los datos de la base de datos...")
            
            # Eliminar en orden inverso por las foreign keys
            deleted_rounds = ActivityRound.query.delete()
            print(f"   ✓ {deleted_rounds} rondas eliminadas")
            
            deleted_results = TestResult.query.delete()
            print(f"   ✓ {deleted_results} resultados eliminados")
            
            deleted_children = Child.query.delete()
            print(f"   ✓ {deleted_children} niños eliminados")
            
            deleted_users = User.query.delete()
            print(f"   ✓ {deleted_users} usuarios eliminados")
            
            db.session.commit()
            print("\n✅ Base de datos limpiada completamente")
            
        except Exception as e:
            db.session.rollback()
            print(f"\n❌ Error al limpiar la base de datos: {e}")
            raise

if __name__ == '__main__':
    clear_database()
