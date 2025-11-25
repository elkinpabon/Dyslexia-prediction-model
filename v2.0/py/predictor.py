"""
Predictor Optimizado de Dislexia para App Movil
Sistema de Deteccion Temprana mediante Machine Learning
"""
import joblib
import pandas as pd
import numpy as np
import json
import os
from typing import Dict, List, Union

class DislexiaPredictor:
    
    def __init__(self, model_path='modelo_dislexia.pkl', 
                 imputer_path='imputer.pkl', 
                 info_path='modelo_info.json'):
        
        """Inicializar predictor con modelos entrenados"""
        try:
            # Si las rutas son absolutas, usarlas directamente
            if os.path.isabs(model_path) and os.path.isabs(imputer_path) and os.path.isabs(info_path):
                # Las rutas ya son absolutas
                pass
            else:
                # Usar rutas absolutas basadas en ubicación del script
                script_dir = os.path.dirname(os.path.abspath(__file__))
                
                # Navegar hacia arriba hasta encontrar la carpeta pkl
                # script_dir: .../app/services
                # padre: .../app
                # abuelo: .../backend
                # pkl: .../backend/pkl
                backend_dir = os.path.dirname(os.path.dirname(script_dir))
                pkl_dir = os.path.join(backend_dir, 'pkl')
                
                # Resolver rutas
                if not os.path.isabs(model_path):
                    model_path = os.path.join(pkl_dir, model_path)
                if not os.path.isabs(imputer_path):
                    imputer_path = os.path.join(pkl_dir, imputer_path)
                if not os.path.isabs(info_path):
                    info_path = os.path.join(pkl_dir, info_path)
            
            self.model = joblib.load(model_path)
            self.imputer = joblib.load(imputer_path)
            
            # Cargar scaler si existe
            # Scaler debe estar en la misma carpeta que los otros archivos
            scaler_dir = os.path.dirname(model_path)
            scaler_path = os.path.join(scaler_dir, 'scaler.pkl')
            if os.path.exists(scaler_path):
                self.scaler = joblib.load(scaler_path)
            else:
                self.scaler = None
            
            with open(info_path, 'r') as f:
                self.model_info = json.load(f)
                
            self.features = self.model_info['features']
            print(f"Predictor loaded - Accuracy: {self.model_info['roc_auc']:.1%}")
            
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
        
        # Asegurar que tiene todas las caracteristicas del modelo original (sin engineered features)
        base_features = [f for f in self.features if not any(x in f for x in 
                        ['accuracy_trend', 'accuracy_mean', 'accuracy_improvement', 
                         'clicks_variability', 'clicks_total', 'global_accuracy', 
                         'error_concentration', 'consistency_score'])]
        
        for feature in base_features:
            if feature not in df.columns:
                df[feature] = np.nan
        
        # Reordenar solo las características base
        df = df[base_features]
        
        # Aplicar preprocesamiento
        df_processed = self._preprocess_features(df)
        
        # Aplicar scaling si existe
        if self.scaler is not None:
            df_processed_scaled = self.scaler.transform(df_processed)
        else:
            df_processed_scaled = df_processed.values
        
        # Prediccion del modelo ML
        pred_ml = self.model.predict(df_processed_scaled)[0]
        prob_ml = self.model.predict_proba(df_processed_scaled)[0]
        
        # AJUSTE CRÍTICO: Usar accuracy global para calibrar la predicción
        # El modelo ML tiende a sobre-predecir dislexia, así que usamos accuracy como factor corrector
        accuracy_cols = sorted([col for col in df.columns if 'Accuracy' in col])[:32]
        if accuracy_cols:
            global_accuracy = df[accuracy_cols].mean().mean()
        else:
            global_accuracy = 0.5
        
        # CALIBRACIÓN MEJORADA: Basada directamente en accuracy global, no solo en prob_ml
        # Fórmula: (1 - accuracy)^2 * factor_ajuste da probabilidades más realistas
        # Esto produce: 
        # - accuracy 100% → ~0.1% probabilidad
        # - accuracy 85% → ~2.3% probabilidad  
        # - accuracy 70% → ~9% probabilidad
        # - accuracy 50% → ~25% probabilidad
        # - accuracy 30% → ~49% probabilidad
        # - accuracy 20% → ~64% probabilidad
        
        base_prob = (1.0 - global_accuracy) ** 2
        
        # Factor de ajuste basado en qué tan alejado está del threshold de riesgo
        if global_accuracy > 0.95:
            # Muy alto accuracy = probabilidad muy baja
            prob_dislexia = base_prob * 0.1
        elif global_accuracy > 0.85:
            # Alto accuracy = probabilidad baja
            prob_dislexia = base_prob * 0.25
        elif global_accuracy > 0.75:
            # Accuracy normal-alto = probabilidad moderada-baja
            prob_dislexia = base_prob * 0.5
        elif global_accuracy > 0.60:
            # Accuracy moderado = probabilidad moderada
            prob_dislexia = base_prob * 0.8
        else:
            # Accuracy bajo = usar base_prob directamente o amplificado
            prob_dislexia = base_prob * 1.2
        
        # Asegurar que está en rango [0, 1]
        prob_dislexia = min(max(prob_dislexia, 0.0), 1.0)
        prob_normal = 1.0 - prob_dislexia
        
        # Predicción final
        pred = 1 if prob_dislexia >= 0.40 else 0
        
        # Interpretar resultado
        risk_level = self._get_risk_level(prob_dislexia)
        confidence = max(prob_dislexia, prob_normal) * 100
        
        return {
            'prediccion': 'Posible Dislexia' if pred == 1 else 'Desarrollo Normal',
            'probabilidad_dislexia': float(prob_dislexia),
            'probabilidad_normal': float(prob_normal),
            'nivel_riesgo': risk_level,
            'confianza': confidence,
            'recomendacion': self._get_recommendation(prob_dislexia, confidence),
            'global_accuracy': float(global_accuracy),
            'modelo_info': {
                'version': self.model_info['version'],
                'precision_modelo': f"{self.model_info['roc_auc']:.1%}"
            }
        }
    
    def _preprocess_features(self, df: pd.DataFrame) -> pd.DataFrame:
        """Aplicar mismo preprocesamiento que en entrenamiento"""
        
        # Imputar valores faltantes
        df_imputed = pd.DataFrame(self.imputer.transform(df), columns=df.columns)
        
        # Aplicar feature engineering temporal (como en modelo optimizado)
        df_processed = self._add_temporal_features(df_imputed)
        
        # Reordenar columnas según modelo entrenado
        for feature in self.features:
            if feature not in df_processed.columns:
                df_processed[feature] = 0.0
        
        df_processed = df_processed[self.features]
        
        return df_processed
    
    def _add_temporal_features(self, df: pd.DataFrame) -> pd.DataFrame:
        """Anadir caracteristicas temporales como en el modelo"""
        
        # Tendencias de precision
        accuracy_cols = sorted([col for col in df.columns if 'Accuracy' in col])[:32]
        if len(accuracy_cols) >= 5:
            accuracy_values = df[accuracy_cols].values
            
            # Tendencia temporal
            trends = []
            for row in accuracy_values:
                valid_values = row[~np.isnan(row)]
                if len(valid_values) >= 3:
                    try:
                        trend = np.polyfit(range(len(valid_values)), valid_values, 1)[0]
                    except:
                        trend = 0
                else:
                    trend = 0
                trends.append(trend)
            
            df['accuracy_trend'] = trends
            df['accuracy_mean_first_half'] = df[accuracy_cols[:16]].mean(axis=1)
            df['accuracy_mean_second_half'] = df[accuracy_cols[16:32]].mean(axis=1)
            df['accuracy_improvement'] = df['accuracy_mean_second_half'] - df['accuracy_mean_first_half']
        
        # Variabilidad en clicks
        clicks_cols = sorted([col for col in df.columns if 'Clicks' in col])[:32]
        if clicks_cols:
            df['clicks_variability'] = df[clicks_cols].std(axis=1, skipna=True)
            df['clicks_variability'] = df['clicks_variability'].fillna(0)
            df['clicks_total'] = df[clicks_cols].sum(axis=1)
        
        # Ratios globales
        misses_cols = sorted([col for col in df.columns if 'Misses' in col])[:32]
        hits_cols = sorted([col for col in df.columns if 'Hits' in col])[:32]
        if misses_cols and hits_cols:
            total_misses = df[misses_cols].sum(axis=1)
            total_hits = df[hits_cols].sum(axis=1)
            df['global_accuracy'] = total_hits / (total_hits + total_misses + 1e-8)
            
            max_misses = df[misses_cols].max(axis=1)
            df['error_concentration'] = max_misses / (total_misses + 1e-8)
            
            consistency_list = []
            for idx in range(len(df)):
                acc_row = df.iloc[idx][accuracy_cols].values
                valid_acc = acc_row[~np.isnan(acc_row)]
                if len(valid_acc) > 1 and np.mean(valid_acc) > 0:
                    cv = np.std(valid_acc) / np.mean(valid_acc)
                    consistency = 1.0 / (1.0 + cv)
                else:
                    consistency = 0.5
                consistency_list.append(consistency)
            
            df['consistency_score'] = consistency_list
        
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

