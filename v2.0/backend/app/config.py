import os

class Config:
    """Configuración base"""
    DEBUG = False
    TESTING = False
    
    # Paths - Subir dos niveles: backend/app/config.py -> backend -> . (raíz)
    BASE_DIR = os.path.abspath(os.path.dirname(__file__))
    PROJECT_ROOT = os.path.dirname(os.path.dirname(BASE_DIR))  # Sube a C:\Users\elkin\Desktop\Dyslexia\python
    
    MODEL_PATH = os.path.join(PROJECT_ROOT, "pkl", "modelo_dislexia_optimizado.pkl")
    IMPUTER_PATH = os.path.join(PROJECT_ROOT, "pkl", "imputer_optimizado.pkl")
    INFO_PATH = os.path.join(PROJECT_ROOT, "pkl", "modelo_info.json")
    
    # API
    JSON_SORT_KEYS = False

class DevelopmentConfig(Config):
    """Configuración desarrollo"""
    DEBUG = True
    TESTING = False

class ProductionConfig(Config):
    """Configuración producción"""
    DEBUG = False
    TESTING = False

class TestingConfig(Config):
    """Configuración testing"""
    DEBUG = True
    TESTING = True
