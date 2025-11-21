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
            
            # Invertir: probability es P(NO dislexia), necesitamos P(dislexia)
            dyslexia_probability = 1.0 - prediction_result['probability']
            
            # Clasificar riesgo
            risk_level = self.classify_risk(dyslexia_probability)
            
            return {
                'success': True,
                'prediction': prediction_result['prediction'],
                'probability': dyslexia_probability,
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
            
            # Invertir: probability es P(NO dislexia), necesitamos P(dislexia)
            dyslexia_probability = 1.0 - prediction_result['probability']
            
            # Clasificar riesgo
            risk_level = self.classify_risk(dyslexia_probability)
            
            return {
                'success': True,
                'activity': activity_name,
                'prediction': prediction_result['prediction'],
                'probability': dyslexia_probability,
                'confidence': prediction_result['confidence'],
                'risk_level': risk_level,
                'has_dyslexia_indicators': risk_level in ['Medio', 'Alto']
            }
        except Exception as e:
            return {
                'success': False,
                'error': str(e)
            }
    
    def classify_risk(self, dyslexia_probability):
        """Clasificar nivel de riesgo según probabilidad de dislexia
        
        Args:
            dyslexia_probability: P(dislexia) en rango [0, 1]
            
        Returns:
            Nivel de riesgo: 'Bajo', 'Medio', 'Alto'
            
        Umbrales calibrados para sensibilidad clínica:
        - < 0.25: Bajo riesgo (< 25%)
        - 0.25-0.60: Medio riesgo (25-60%)
        - >= 0.60: Alto riesgo (>= 60%)
        """
        if dyslexia_probability < 0.25:
            return "Bajo"
        elif dyslexia_probability < 0.60:
            return "Medio"
        else:
            return "Alto"
    
    def predict(self, features):
        """Realizar predicción con análisis de riesgo"""
        result = self.model_manager.predict(features)
        # Invertir probability: P(dislexia) = 1 - P(NO dislexia)
        dyslexia_prob = 1.0 - result["probability"]
        result["probability"] = dyslexia_prob
        result["risk_level"] = self.classify_risk(dyslexia_prob)
        return result
    
    def predict_batch(self, data_list):
        """Predicciones en lote con análisis de riesgo"""
        results = self.model_manager.predict_batch(data_list)
        for result in results:
            # Invertir probability: P(dislexia) = 1 - P(NO dislexia)
            dyslexia_prob = 1.0 - result["probability"]
            result["probability"] = dyslexia_prob
            result["risk_level"] = self.classify_risk(dyslexia_prob)
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
