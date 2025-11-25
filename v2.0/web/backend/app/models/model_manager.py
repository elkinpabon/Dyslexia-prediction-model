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
        self.scaler = None
        self.model_info = {}
        self._initialized = True
        self._load_models()
    
    def _load_models(self):
        """Cargar modelos desde archivos pickle"""
        try:
            self.model = joblib.load(Config.MODEL_PATH)
            self.imputer = joblib.load(Config.IMPUTER_PATH)
            # NUEVO en v2.1: Cargar scaler
            self.scaler = joblib.load(Config.SCALER_PATH)
            
            with open(Config.INFO_PATH, 'r') as f:
                self.model_info = json.load(f)
            
            print("[OK] Modelos cargados exitosamente (incluyendo scaler v2.1)")
        except Exception as e:
            print(f"[ERROR] Error cargando modelos: {e}")
            raise
    
    def is_ready(self):
        """Verificar si los modelos están listos"""
        return self.model is not None and self.imputer is not None and self.scaler is not None
    
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
        
        # Convertir a array numpy 2D
        import numpy as np
        X = np.array([features])
        
        print(f"🔍 Array shape antes de scaler: {X.shape}")
        
        # NUEVO en v2.1: Aplicar scaler a las features
        X_scaled = self.scaler.transform(X)
        print(f"🔍 Array shape después de scaler: {X_scaled.shape}")
        
        # Predecir con features escaladas
        prediction = self.model.predict(X_scaled)[0]
        probability = self.model.predict_proba(X_scaled)[0][1]
        confidence = float(max(self.model.predict_proba(X_scaled)[0]))
        
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
        
        import numpy as np
        
        # Convertir a array numpy
        X = np.array(data_list)
        
        # NUEVO en v2.1: Aplicar scaler a las features
        X_scaled = self.scaler.transform(X)
        
        print(f"🔍 Batch - Shape antes: {X.shape}, después: {X_scaled.shape}")
        
        # Predecir con features escaladas
        predictions = self.model.predict(X_scaled)
        probabilities = self.model.predict_proba(X_scaled)[:, 1]
        
        results = []
        for i, (pred, prob) in enumerate(zip(predictions, probabilities)):
            results.append({
                "index": i,
                "prediction": int(pred),
                "probability": float(prob),
                "confidence": float(max(self.model.predict_proba(X_scaled)[i]))
            })
        
        return results
    
    def get_info(self):
        """Obtener información del modelo"""
        return self.model_info
