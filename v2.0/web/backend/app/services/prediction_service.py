from app.models.model_manager import ModelManager
from app.services.feature_extractor import FeatureExtractor
from app.services.predictor import DislexiaPredictor
from typing import Dict, List
import os


class PredictionService:
    """Servicio de predicciones con procesamiento de actividades"""
    
    def __init__(self):
        self.model_manager = ModelManager()
        self.feature_extractor = FeatureExtractor()
        
        # Inicializar el predictor calibrado
        try:
            # Obtener ruta del modelo desde la carpeta ../pkl/ relativa al backend
            backend_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
            pkl_dir = os.path.join(os.path.dirname(backend_dir), 'pkl')
            
            model_path = os.path.join(pkl_dir, 'modelo_dislexia.pkl')
            imputer_path = os.path.join(pkl_dir, 'imputer.pkl')
            info_path = os.path.join(pkl_dir, 'modelo_info.json')
            
            print(f"[DEBUG] Backend dir: {backend_dir}")
            print(f"[DEBUG] PKL dir: {pkl_dir}")
            print(f"[DEBUG] Model path: {model_path}")
            
            self.predictor = DislexiaPredictor(
                model_path=model_path,
                imputer_path=imputer_path,
                info_path=info_path
            )
            print("[OK] Predictor calibrado cargado")
        except Exception as e:
            print(f"[WARN] Error cargando predictor calibrado: {e}")
            self.predictor = None
    
    def process_activities(self, activities_data: Dict) -> Dict:
        """
        Procesa actividades completadas y realiza predicción calibrada
        
        Args:
            activities_data: Dict con datos de actividades
        
        Returns:
            Dict con predicción y análisis
        """
        try:
            # Si el predictor calibrado está disponible, usarlo directamente
            if self.predictor:
                # Convertir datos de actividades al formato esperado por el predictor
                features_dict = self._convert_activities_to_features(activities_data)
                
                # Usar el predictor calibrado
                result = self.predictor.predict(features_dict)
                
                return {
                    'success': True,
                    'prediction': 'Posible Dislexia' if result['prediccion'] == 'Posible Dislexia' else 'Desarrollo Normal',
                    'probability': result['probabilidad_dislexia'],
                    'confidence': result['confianza'],
                    'risk_level': result['nivel_riesgo'],
                    'global_accuracy': result.get('global_accuracy', 0),
                    'activities_processed': list(activities_data.keys()),
                    'recommendation': result['recomendacion']
                }
            else:
                # Fallback al método anterior si predictor no está disponible
                features = self.feature_extractor.combine_all_features(activities_data)
                prediction_result = self.model_manager.predict(features)
                dyslexia_probability = 1.0 - prediction_result['probability']
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
    
    def _convert_activities_to_features(self, activities_data: Dict) -> Dict:
        """
        Convierte datos de actividades al formato esperado por el predictor
        
        Args:
            activities_data: Dict con datos de actividades de la app Flutter
            
        Returns:
            Dict con formato Clicks1-32, Hits1-32, Misses1-32, Score1-32, Accuracy1-32, Missrate1-32
        """
        features_dict = {}
        
        # Si viene de screening_test, procesar sus rondas
        if 'screening_test' in activities_data:
            # screening_test puede ser una lista directamente o un dict con 'rounds'
            rounds = activities_data['screening_test']
            if isinstance(rounds, dict):
                rounds = rounds.get('rounds', [])
            
            # Procesar hasta 32 rondas (máximo del dataset)
            for i, round_data in enumerate(rounds[:32], 1):
                features_dict[f'Clicks{i}'] = round_data.get('clicks', 0)
                features_dict[f'Hits{i}'] = round_data.get('hits', 0)
                features_dict[f'Misses{i}'] = round_data.get('misses', 0)
                features_dict[f'Score{i}'] = round_data.get('score', 0)
                features_dict[f'Accuracy{i}'] = round_data.get('accuracy', 0.0)
                features_dict[f'Missrate{i}'] = round_data.get('missrate', 0.0)
            
            # Rellenar si hay menos de 32 rondas
            for i in range(len(rounds) + 1, 33):
                features_dict[f'Clicks{i}'] = 0
                features_dict[f'Hits{i}'] = 0
                features_dict[f'Misses{i}'] = 0
                features_dict[f'Score{i}'] = 0
                features_dict[f'Accuracy{i}'] = 0.0
                features_dict[f'Missrate{i}'] = 0.0
        
        return features_dict
    
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
        """Realizar predicción con análisis de riesgo basado en scoring de rendimiento"""
        # En lugar de confiar 100% en el modelo ML entrenado,
        # usamos una aproximación híbrida que considera el desempeño real
        
        # Extraer métricas clave de las características (índices específicos)
        # features[0-3]: Demográficas (Gender, Nativelang, Otherlang, Age)
        # features[4-35]: Accuracy de rondas 1-32 (en posiciones específicas)
        
        # Calcular accuracy global desde las características
        accuracy_indices = list(range(8, 192, 6))  # Accuracy1-32 están cada 6 posiciones
        accuracies = [features[idx] if idx < len(features) else 0.0 for idx in accuracy_indices]
        global_accuracy = sum(accuracies) / len(accuracies) if accuracies else 0.0
        
        # Calcular desviación estándar de accuracy (consistencia)
        import numpy as np
        if len(accuracies) > 1:
            accuracy_std = np.std(accuracies)
            accuracy_consistency = 1.0 - min(accuracy_std, 1.0)
        else:
            accuracy_consistency = 0.5
        
        # SCORING DE RIESGO DIRECTO (más lógico que el modelo)
        # Basado en: accuracy global + consistencia + patrones de error
        
        # 1. Si accuracy global > 90%, riesgo muy bajo (< 10%)
        if global_accuracy > 0.90:
            dyslexia_prob = max(0.01, 0.10 * (1.0 - global_accuracy))
        # 2. Si accuracy 80-90%, riesgo bajo (10-25%)
        elif global_accuracy > 0.80:
            dyslexia_prob = 0.10 + (0.15 * (0.90 - global_accuracy))
        # 3. Si accuracy 70-80%, riesgo medio (25-45%)
        elif global_accuracy > 0.70:
            dyslexia_prob = 0.25 + (0.20 * (0.80 - global_accuracy))
        # 4. Si accuracy 60-70%, riesgo alto (45-65%)
        elif global_accuracy > 0.60:
            dyslexia_prob = 0.45 + (0.20 * (0.70 - global_accuracy))
        # 5. Si accuracy < 60%, riesgo muy alto (65-95%)
        else:
            dyslexia_prob = min(0.95, 0.65 + (0.30 * (0.60 - global_accuracy)))
        
        # Ajustar por consistencia (si hay mucha variabilidad, aumentar riesgo)
        consistency_penalty = (1.0 - accuracy_consistency) * 0.15
        dyslexia_prob = min(0.99, dyslexia_prob + consistency_penalty)
        
        # Calcular confianza (qué tan seguro estamos de la predicción)
        # Mayor accuracy → mayor confianza
        confidence = 0.5 + (global_accuracy * 0.5)  # Rango 0.5-1.0
        
        # Usar el modelo ML pero pesarlo menos si hay inconsistencia
        ml_result = self.model_manager.predict(features)
        ml_probability = 1.0 - ml_result["probability"]
        
        # Promedio ponderado: 70% scoring directo, 30% modelo ML
        final_probability = 0.7 * dyslexia_prob + 0.3 * ml_probability
        
        return {
            "prediction": 1 if final_probability > 0.50 else 0,
            "probability": final_probability,
            "confidence": confidence,
            "risk_level": self.classify_risk(final_probability),
            "debug": {
                "global_accuracy": global_accuracy,
                "consistency": accuracy_consistency,
                "direct_score": dyslexia_prob,
                "ml_score": ml_probability
            }
        }
    
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
