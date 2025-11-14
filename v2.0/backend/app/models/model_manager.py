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
        
        # Convertir a DataFrame
        feature_names = self.model_info.get("features", [])
        X = pd.DataFrame([features], columns=feature_names)
        
        # Validar cantidad de características
        if X.shape[1] != len(feature_names):
            raise ValueError(
                f"Se esperaban {len(feature_names)} características, "
                f"se recibieron {X.shape[1]}"
            )
        
        # Imputar
        X_imputed = pd.DataFrame(
            self.imputer.transform(X),
            columns=X.columns
        )
        
        # Predecir
        prediction = self.model.predict(X_imputed)[0]
        probability = self.model.predict_proba(X_imputed)[0][1]
        confidence = float(max(self.model.predict_proba(X_imputed)[0]))
        
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
