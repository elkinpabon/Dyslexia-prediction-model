import joblib
import json
import pandas as pd
from app.config import Config

class ModelManager:
    """Gestor centralizado del modelo ML"""
    
    _instance = None
    
    def __new__(cls):
        if cls._instance is None:
            cls._instance = super(ModelManager, cls).__new__(cls)
            cls._instance._initialized = False
        return cls._instance
    
    def __init__(self):
        if self._initialized:
            return
        
        self.model = None
        self.imputer = None
        self.model_info = {}
        self._initialized = True
        self._load_models()
    
    def _load_models(self):
        """Cargar modelos desde archivos pickle"""
        try:
            self.model = joblib.load(Config.MODEL_PATH)
            self.imputer = joblib.load(Config.IMPUTER_PATH)
            
            with open(Config.INFO_PATH, 'r') as f:
                self.model_info = json.load(f)
            
            print("✓ Modelos cargados exitosamente")
        except Exception as e:
            print(f"✗ Error cargando modelos: {e}")
            raise
    
    def is_ready(self):
        """Verificar si los modelos están listos"""
        return self.model is not None and self.imputer is not None
    
    def predict(self, features):
        """Realizar predicción individual"""
        if not self.is_ready():
            raise Exception("Modelo no disponible")
        
        # Obtener nombres de características del modelo
        feature_names = self.model_info.get("features", [])
        
        print(f"🔍 Predicción - Features esperadas: {len(feature_names)}")
        print(f"🔍 Predicción - Features recibidas: {len(features)}")
        
        # Validar cantidad de características
        if len(features) != len(feature_names):
            raise ValueError(
                f"Se esperaban {len(feature_names)} características, "
                f"se recibieron {len(features)}"
            )
        
        # Convertir a array numpy 2D (sin nombres de columnas)
        import numpy as np
        X = np.array([features])
        
        print(f"🔍 Array shape: {X.shape}")
        
        # NO USAR IMPUTER - Los datos de la app ya vienen completos
        # El imputer fue entrenado con 196 features (antes del feature engineering)
        # pero el modelo usa 206 features (después del feature engineering)
        # Como la app ya genera las 206 features completas, no necesitamos imputar
        
        print(f"⚠️  Saltando imputer - datos ya completos de la app")
        
        # Predecir directamente (el modelo trabaja con arrays numpy)
        prediction = self.model.predict(X)[0]
        probability = self.model.predict_proba(X)[0][1]
        confidence = float(max(self.model.predict_proba(X)[0]))
        
        print(f"✅ Predicción exitosa: {prediction}, probabilidad: {probability:.2%}")
        
        return {
            "prediction": int(prediction),
            "probability": float(probability),
            "confidence": confidence
        }
    
    def predict_batch(self, data_list):
        """Realizar predicciones en lote"""
        if not self.is_ready():
            raise Exception("Modelo no disponible")
        
        X = pd.DataFrame(data_list)
        
        # Imputar
        X_imputed = pd.DataFrame(
            self.imputer.transform(X),
            columns=X.columns
        )
        
        # Predecir
        predictions = self.model.predict(X_imputed)
        probabilities = self.model.predict_proba(X_imputed)[:, 1]
        
        results = []
        for i, (pred, prob) in enumerate(zip(predictions, probabilities)):
            results.append({
                "index": i,
                "prediction": int(pred),
                "probability": float(prob),
                "confidence": float(max(self.model.predict_proba(X_imputed)[i]))
            })
        
        return results
    
    def get_info(self):
        """Obtener información del modelo"""
        return self.model_info
