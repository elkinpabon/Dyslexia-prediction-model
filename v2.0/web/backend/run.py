# ==============================================
#  PUNTO DE ENTRADA - BACKEND FLASK
# ==============================================

import os
from app import create_app
from app.config import DevelopmentConfig, ProductionConfig

# Determinar configuración
env = os.getenv('FLASK_ENV', 'development')
config = DevelopmentConfig if env == 'development' else ProductionConfig

# Crear app
app = create_app(config)

if __name__ == '__main__':
    print(f"""
╔════════════════════════════════════════════════════════╗
║          DYSLEXIA DETECTION - ML BACKEND              ║
║                   Flask API Server                     ║
╚════════════════════════════════════════════════════════╝

Ambiente: {env}
Debug: {app.debug}
Puerto: 5000

Endpoints:
  GET   /api/health           - Estado del servidor
  GET   /api/model/info       - Información del modelo
  POST  /api/predict          - Predicción individual
  POST  /api/predict/batch    - Predicciones en lote

Acceder a: http://localhost:5000
    """)
    
    app.run(
        host='0.0.0.0',
        port=5000,
        debug=app.debug,
        use_reloader=env == 'development'
    )
