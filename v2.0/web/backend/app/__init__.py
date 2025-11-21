from flask import Flask
from flask_cors import CORS
from flask_migrate import Migrate
from app.config import Config, DevelopmentConfig
from app.models.database import db
import os

migrate = Migrate()

def create_app(config_class=None):
    """Factory para crear la aplicación Flask"""
    app = Flask(__name__)
    
    # Cargar configuración
    if config_class is None:
        env = os.getenv('FLASK_ENV', 'development')
        config_class = DevelopmentConfig if env == 'development' else Config
    
    app.config.from_object(config_class)
    
    # Inicializar extensiones
    db.init_app(app)
    migrate.init_app(app, db)
    
    # Configurar CORS
    CORS(app, resources={
        r"/api/*": {
            "origins": app.config['CORS_ORIGINS'],
            "methods": ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
            "allow_headers": ["Content-Type", "Authorization"]
        }
    })
    
    # Registrar blueprints
    from app.routes import api_bp
    app.register_blueprint(api_bp)
    
    # Manejador para cerrar transacciones después de cada request
    @app.teardown_appcontext
    def shutdown_session(exception=None):
        """Cierra la sesión de BD después de cada request"""
        if exception is not None:
            print(f"❌ Excepción en request: {exception}")
            db.session.rollback()
        db.session.remove()
    
    # Crear tablas si no existen (solo en desarrollo)
    with app.app_context():
        if app.config['DEBUG']:
            db.create_all()
    
    return app
