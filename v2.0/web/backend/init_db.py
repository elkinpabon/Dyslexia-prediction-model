"""
Script de inicialización de base de datos
Ejecutar con: python init_db.py
"""
from app import create_app
from app.models.database import db
from app.config import DevelopmentConfig

def init_database():
    """Inicializar la base de datos"""
    app = create_app(DevelopmentConfig)
    
    with app.app_context():
        print("🔄 Creando tablas en la base de datos...")
        
        # Eliminar todas las tablas existentes (¡CUIDADO en producción!)
        db.drop_all()
        print("✓ Tablas antiguas eliminadas")
        
        # Crear todas las tablas
        db.create_all()
        print("✓ Tablas creadas exitosamente")
        
        print("\n📊 Tablas creadas:")
        print("  - users")
        print("  - children")
        print("  - test_results")
        print("  - activity_rounds")
        
        print("\n✅ Base de datos inicializada correctamente!")

if __name__ == '__main__':
    init_database()
