import os
from dotenv import load_dotenv

load_dotenv()

class Config:
    """Configuración base"""
    DEBUG = False
    TESTING = False
    
    # Flask
    SECRET_KEY = os.getenv('SECRET_KEY', 'dev-secret-key-change-in-production')
    
    # Paths - Los pkl están en backend/pkl/
    BASE_DIR = os.path.abspath(os.path.dirname(__file__))
    BACKEND_ROOT = os.path.dirname(BASE_DIR)  # Sube a backend/
    
    MODEL_PATH = os.path.join(BACKEND_ROOT, "pkl", "modelo_dislexia_optimizado.pkl")
    IMPUTER_PATH = os.path.join(BACKEND_ROOT, "pkl", "imputer_optimizado.pkl")
    INFO_PATH = os.path.join(BACKEND_ROOT, "pkl", "modelo_info.json")
    
    # Database Configuration
    # Railway provides these env variables automatically
    DB_HOST = os.getenv('MYSQLHOST', os.getenv('DB_HOST', 'localhost'))
    DB_PORT = int(os.getenv('MYSQLPORT', os.getenv('DB_PORT', 3306)))
    DB_NAME = os.getenv('MYSQLDATABASE', os.getenv('DB_NAME', 'dyslexia_db'))
    DB_USER = os.getenv('MYSQLUSER', os.getenv('DB_USER', 'root'))
    DB_PASSWORD = os.getenv('MYSQLPASSWORD', os.getenv('DB_PASSWORD', ''))
    
    # SQLAlchemy
    SQLALCHEMY_DATABASE_URI = (
        f"mysql+pymysql://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}"
        "?charset=utf8mb4"
    )
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    SQLALCHEMY_ECHO = False
    
    # API
    JSON_SORT_KEYS = False
    API_HOST = os.getenv('API_HOST', '0.0.0.0')
    API_PORT = int(os.getenv('API_PORT', 5000))
    
    # CORS
    CORS_ORIGINS = os.getenv('CORS_ORIGINS', 'http://localhost:3000').split(',')

class DevelopmentConfig(Config):
    """Configuración desarrollo"""
    DEBUG = True
    TESTING = False
    SQLALCHEMY_ECHO = True

class ProductionConfig(Config):
    """Configuración producción"""
    DEBUG = False
    TESTING = False

class TestingConfig(Config):
    """Configuración testing"""
    DEBUG = True
    TESTING = True
