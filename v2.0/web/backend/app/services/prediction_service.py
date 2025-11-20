from app.models.model_manager import ModelManager
from app.services.feature_extractor import FeatureExtractor
from typing import Dict, List


class PredictionService:
    """Servicio de predicciones con procesamiento de actividades"""
    
    def __init__(self):
        self.model_manager = ModelManager()
        self.feature_extractor = FeatureExtractor()
    
    def process_activities(self, activities_data: Dict) -> Dict:
        """
        Procesa actividades completadas y realiza predicción
        
        Args:
            activities_data: Dict con datos de actividades
        
        Returns:
            Dict con predicción y análisis
        """
        try:
            # Extraer características de 206 dimensiones
            features = self.feature_extractor.combine_all_features(activities_data)
            
            # Realizar predicción
            prediction_result = self.model_manager.predict(features)
            
            # Clasificar riesgo
            risk_level = self.classify_risk(prediction_result['probability'])
            
            return {
                'success': True,
                'prediction': prediction_result['prediction'],
                'probability': prediction_result['probability'],
                'confidence': prediction_result['confidence'],
                'risk_level': risk_level,
                'activities_processed': list(activities_data.keys()),
                'recommendation': self._get_recommendation(risk_level)
            }
        except Exception as e:
            return {
                'success': False,
                'error': str(e)
            }
    
    def process_single_activity(self, activity_name: str, activity_data: Dict) -> Dict:
        """
        Procesa una actividad individual
        
        Args:
            activity_name: Nombre de la actividad
            activity_data: Datos de la actividad
        
        Returns:
            Dict con resultado de la actividad
        """
        try:
            # Crear datos de actividad en formato esperado
            data = {activity_name: activity_data}
            
            # Extraer características
            features = self.feature_extractor.combine_all_features(data)
            
            # Realizar predicción
            prediction_result = self.model_manager.predict(features)
            
            # Clasificar riesgo
            risk_level = self.classify_risk(prediction_result['probability'])
            
            return {
                'success': True,
                'activity': activity_name,
                'prediction': prediction_result['prediction'],
                'probability': prediction_result['probability'],
                'confidence': prediction_result['confidence'],
                'risk_level': risk_level,
                'has_dyslexia_indicators': risk_level in ['Medio', 'Alto']
            }
        except Exception as e:
            return {
                'success': False,
                'error': str(e)
            }
    
    def classify_risk(self, probability):
        """Clasificar nivel de riesgo según probabilidad"""
        if probability < 0.3:
            return "Bajo"
        elif probability < 0.7:
            return "Medio"
        else:
            return "Alto"
    
    def predict(self, features):
        """Realizar predicción con análisis de riesgo"""
        result = self.model_manager.predict(features)
        result["risk_level"] = self.classify_risk(result["probability"])
        return result
    
    def predict_batch(self, data_list):
        """Predicciones en lote con análisis de riesgo"""
        results = self.model_manager.predict_batch(data_list)
        for result in results:
            result["risk_level"] = self.classify_risk(result["probability"])
        return results
    
    def get_model_info(self):
        """Información del modelo"""
        return self.model_manager.get_info()
    
    def is_healthy(self):
        """Verificar salud del servicio"""
        return self.model_manager.is_ready()
    
    def _get_recommendation(self, risk_level: str) -> str:
        """Retorna recomendación basada en riesgo"""
        recommendations = {
            "Bajo": "El niño no presenta indicadores significativos de dislexia.",
            "Medio": "Se recomienda evaluación más profunda por especialista.",
            "Alto": "Se recomienda evaluación neuropsicológica urgente."
        }
        return recommendations.get(risk_level, "")
