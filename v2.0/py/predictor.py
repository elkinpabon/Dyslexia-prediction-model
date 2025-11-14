"""
Predictor Optimizado de Dislexia para App Movil
Sistema de Deteccion Temprana mediante Machine Learning
"""
import joblib
import pandas as pd
import numpy as np
import json
from typing import Dict, List, Union

class DislexiaPredictor:
    
    def __init__(self, model_path='modelo_dislexia_optimizado.pkl', 
                 imputer_path='imputer_optimizado.pkl', 
                 info_path='modelo_info.json'):
        
        """Inicializar predictor con modelos entrenados"""
        try:
            self.model = joblib.load(model_path)
            self.imputer = joblib.load(imputer_path)
            
            with open(info_path, 'r') as f:
                self.model_info = json.load(f)
                
            self.features = self.model_info['features']
            print(f"Predictor cargado - Precision: {self.model_info['roc_auc']:.1%}")
            
        except Exception as e:
            raise Exception(f"Error cargando modelo: {e}")
    
    def predict_from_games(self, juegos_data: List[Dict]) -> Dict:
        """
        Predecir dislexia desde datos de juegos tipo Dytective
        
        Args:
            juegos_data: Lista de diccionarios con metricas de cada juego
                        [{'clicks': 10, 'hits': 8, 'misses': 2, 'tiempo': 150}, ...]
        
        Returns:
            Dict con prediccion, probabilidad y confianza
        """
        
        if len(juegos_data) < 5:
            raise ValueError("Se necesitan al menos 5 juegos para hacer prediccion confiable")
        
        # Convertir datos de juegos a formato del modelo
        features_dict = self._extract_features_from_games(juegos_data)
        
        return self.predict(features_dict)
    
    def _extract_features_from_games(self, juegos_data: List[Dict]) -> Dict:
        """Extraer caracteristicas del formato de juegos movil al formato del modelo"""
        
        features = {}
        
        # Simular características básicas del dataset original
        for i, juego in enumerate(juegos_data[:32], 1):  # Máximo 32 juegos como en dataset
            
            clicks = juego.get('clicks', juego.get('toques', 0))
            hits = juego.get('hits', juego.get('aciertos', 0))
            misses = juego.get('misses', juego.get('errores', 0))
            
            # Calcular metricas derivadas
            total_attempts = hits + misses if (hits + misses) > 0 else clicks
            accuracy = hits / total_attempts if total_attempts > 0 else 0
            missrate = misses / total_attempts if total_attempts > 0 else 0
            score = hits              # Puntuacion simple
            
            # Formato del dataset original
            features[f'Clicks{i}'] = clicks
            features[f'Hits{i}'] = hits
            features[f'Misses{i}'] = misses
            features[f'Score{i}'] = score
            features[f'Accuracy{i}'] = accuracy
            features[f'Missrate{i}'] = missrate
        
        return features
    
    def predict(self, data_dict: Dict) -> Dict:
        """
        Hacer prediccion desde diccionario de caracteristicas
        
        Args:
            data_dict: Diccionario con caracteristicas del usuario
        
        Returns:
            Dict con prediccion detallada
        """
        
        # Crear DataFrame con todas las caracteristicas esperadas
        df = pd.DataFrame([data_dict])
        
        # Asegurar que tiene todas las caracteristicas del modelo original
        for feature in self.features:
            if feature not in df.columns:
                df[feature] = np.nan
        
        # Reordenar columnas según modelo entrenado
        df = df.reindex(columns=self.features, fill_value=np.nan)
        
        # Aplicar preprocesamiento
        df_processed = self._preprocess_features(df)
        
        # Prediccion
        pred = self.model.predict(df_processed)[0]
        prob = self.model.predict_proba(df_processed)[0]
        
        # Interpretar resultado
        risk_level = self._get_risk_level(prob[1])
        confidence = float(max(prob)) * 100
        
        return {
            'prediccion': 'Posible Dislexia' if pred == 1 else 'Desarrollo Normal',
            'probabilidad_dislexia': float(prob[1]),
            'probabilidad_normal': float(prob[0]),
            'nivel_riesgo': risk_level,
            'confianza': confidence,
            'recomendacion': self._get_recommendation(prob[1], confidence),
            'modelo_info': {
                'version': self.model_info['version'],
                'precision_modelo': f"{self.model_info['roc_auc']:.1%}",
                'apto_tesis': self.model_info['tesis_ready']
            }
        }
    
    def _preprocess_features(self, df: pd.DataFrame) -> pd.DataFrame:
        """Aplicar mismo preprocesamiento que en entrenamiento"""
        
        # Imputar valores faltantes
        df_imputed = pd.DataFrame(self.imputer.transform(df), columns=df.columns)
        
        # Aplicar feature engineering temporal (como en modelo optimizado)
        df_processed = self._add_temporal_features(df_imputed)
        
        return df_processed
    
    def _add_temporal_features(self, df: pd.DataFrame) -> pd.DataFrame:
        """Anadir caracteristicas temporales como en el modelo"""
        
        # Tendencias de precision
        accuracy_cols = [col for col in df.columns if 'Accuracy' in col][:10]
        if len(accuracy_cols) >= 5:
            accuracy_values = df[accuracy_cols].values
            
            # Tendencia temporal
            trends = []
            for row in accuracy_values:
                valid_values = row[~np.isnan(row)]
                if len(valid_values) >= 3:
                    trend = np.polyfit(range(len(valid_values)), valid_values, 1)[0]
                else:
                    trend = 0
                trends.append(trend)
            
            df['accuracy_trend'] = trends
            df['accuracy_mean_first_half'] = df[accuracy_cols[:5]].mean(axis=1)
            df['accuracy_mean_second_half'] = df[accuracy_cols[5:]].mean(axis=1)
            df['accuracy_improvement'] = df['accuracy_mean_second_half'] - df['accuracy_mean_first_half']
        
        # Variabilidad en clicks
        clicks_cols = [col for col in df.columns if 'Clicks' in col][:10]
        if clicks_cols:
            df['clicks_variability'] = df[clicks_cols].std(axis=1)
            df['clicks_total'] = df[clicks_cols].sum(axis=1)
        
        # Ratios globales
        misses_cols = [col for col in df.columns if 'Misses' in col][:10]
        hits_cols = [col for col in df.columns if 'Hits' in col][:10]
        if misses_cols and hits_cols:
            total_misses = df[misses_cols].sum(axis=1)
            total_hits = df[hits_cols].sum(axis=1)
            df['global_accuracy'] = total_hits / (total_hits + total_misses + 1e-8)
            df['error_concentration'] = df[misses_cols].max(axis=1) / (total_misses + 1e-8)
        
        return df
    
    def _get_risk_level(self, prob_dislexia: float) -> str:
        """Determinar nivel de riesgo basado en probabilidad"""
        if prob_dislexia < 0.2:
            return "Riesgo Bajo"
        elif prob_dislexia < 0.5:
            return "Riesgo Moderado"
        elif prob_dislexia < 0.8:
            return "Riesgo Alto"
        else:
            return "Riesgo Muy Alto"
    
    def _get_recommendation(self, prob_dislexia: float, confidence: float) -> str:
        """Generar recomendacion basada en prediccion"""
        
        if prob_dislexia > 0.7 and confidence > 80:
            return "Se recomienda evaluacion profesional especializada en dislexia."
        elif prob_dislexia > 0.5:
            return "Se sugiere monitoring continuo y ejercicios de apoyo."
        elif prob_dislexia > 0.3:
            return "Desarrollo dentro de rangos normales con seguimiento ocasional."
        else:
            return "Desarrollo normal, continuar con actividades regulares."

# Predictor listo para importar en app movil
# Uso: from predictor import DislexiaPredictor

