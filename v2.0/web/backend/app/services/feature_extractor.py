"""
Extractor de características basado en el dataset Dyt-desktop.csv
Genera las 205 features exactas que el modelo ML espera
Formato: Gender, Nativelang, Otherlang, Age, Clicks1-32, Hits1-32, Misses1-32, 
         Score1-32, Accuracy1-32, Missrate1-32 + 9 features derivadas
"""
import numpy as np
from typing import Dict, List, Tuple
import json
from datetime import datetime


class FeatureExtractor:
    """Extrae las 205 características exactas del dataset Dyt-desktop.csv
    
    Estructura:
    - 4 demográficas: Gender, Nativelang, Otherlang, Age
    - 192 métricas: 32 rondas × 6 métricas (Clicks, Hits, Misses, Score, Accuracy, Missrate)
    - 9 derivadas: accuracy_trend, accuracy_mean_first_half, accuracy_mean_second_half,
                   accuracy_improvement, clicks_variability, clicks_total, global_accuracy,
                   error_concentration, consistency_score
    Total: 4 + 192 + 9 = 205 features
    """
    
    def __init__(self):
        self.feature_names = self._initialize_feature_names()
    
    def _initialize_feature_names(self) -> List[str]:
        """
        Inicializar las 206 características exactas del modelo:
        - 4 demográficas: Gender, Nativelang, Otherlang, Age
        - 192 métricas de 32 rondas: Clicks, Hits, Misses, Score, Accuracy, Missrate × 32
        - 10 features derivadas: accuracy_trend, accuracy_mean_first_half, etc.
        """
        features = []
        
        # 1. Características demográficas (4 features)
        features.extend(['Gender', 'Nativelang', 'Otherlang', 'Age'])
        
        # 2. Métricas de 32 rondas (192 features = 32 rondas × 6 métricas)
        for i in range(1, 33):  # Rondas 1-32
            features.extend([
                f'Clicks{i}',
                f'Hits{i}',
                f'Misses{i}',
                f'Score{i}',
                f'Accuracy{i}',
                f'Missrate{i}'
            ])
        
        # 3. Features derivadas (9 features)
        features.extend([
            'accuracy_trend',           # Tendencia de accuracy a lo largo de las rondas
            'accuracy_mean_first_half', # Promedio de accuracy en primeras 16 rondas
            'accuracy_mean_second_half',# Promedio de accuracy en últimas 16 rondas
            'accuracy_improvement',     # Mejora entre primera y segunda mitad
            'clicks_variability',       # Variabilidad en número de clicks
            'clicks_total',            # Total de clicks en todas las rondas
            'global_accuracy',         # Accuracy global de todas las rondas
            'error_concentration',     # Concentración de errores en ciertas rondas
            'consistency_score'        # Consistencia en el desempeño
        ])
        
        return features
    
    def _extract_rounds_from_activity(self, rounds: List[Dict]) -> Dict[str, List]:
        """
        Extrae métricas de rondas de una actividad.
        Cada ronda debe tener: clicks, hits, misses, score, accuracy, missrate
        
        Args:
            rounds: Lista de diccionarios con datos de cada ronda
            
        Returns:
            Dict con listas de clicks, hits, misses, score, accuracy, missrate
        """
        metrics = {
            'clicks': [],
            'hits': [],
            'misses': [],
            'score': [],
            'accuracy': [],
            'missrate': []
        }
        
        for round_data in rounds:
            clicks = round_data.get('clicks', 0)
            hits = round_data.get('hits', 0)
            misses = round_data.get('misses', 0)
            score = round_data.get('score', 0)
            accuracy = round_data.get('accuracy', 0.0)
            missrate = round_data.get('missrate', 0.0)
            
            # NORMALIZACIÓN CRÍTICA: Asegurar que Accuracy está en [0, 1]
            # Si accuracy > 1, asumir que es un Score y convertir a proporción
            if accuracy > 1 and clicks > 0:
                accuracy = hits / clicks
            elif accuracy < 0:
                accuracy = 0.0
            elif accuracy > 1:
                accuracy = 1.0  # Clamp a 1.0 si no se puede calcular
            
            # NORMALIZACIÓN: Asegurar que Missrate está en [0, 1]
            if missrate > 1 and clicks > 0:
                missrate = misses / clicks
            elif missrate < 0:
                missrate = 0.0
            elif missrate > 1:
                missrate = 1.0
            
            metrics['clicks'].append(clicks)
            metrics['hits'].append(hits)
            metrics['misses'].append(misses)
            metrics['score'].append(score)
            metrics['accuracy'].append(accuracy)
            metrics['missrate'].append(missrate)
        
        return metrics
    
    def _calculate_derived_features(self, all_metrics: Dict[str, List]) -> Dict:
        """
        Calcula las 10 features derivadas a partir de las métricas de las 32 rondas
        
        Args:
            all_metrics: Dict con listas de clicks, hits, misses, score, accuracy, missrate
            
        Returns:
            Dict con las 10 features derivadas
        """
        accuracies = all_metrics['accuracy']
        clicks = all_metrics['clicks']
        
        # 1. Tendencia de accuracy (regresión lineal simple)
        if len(accuracies) > 1:
            x = np.arange(len(accuracies))
            z = np.polyfit(x, accuracies, 1)
            accuracy_trend = z[0]  # Pendiente
        else:
            accuracy_trend = 0.0
        
        # 2. Promedio de accuracy en primera mitad (rondas 1-16)
        first_half = accuracies[:16] if len(accuracies) >= 16 else accuracies[:len(accuracies)//2]
        accuracy_mean_first_half = np.mean(first_half) if first_half else 0.0
        
        # 3. Promedio de accuracy en segunda mitad (rondas 17-32)
        second_half = accuracies[16:] if len(accuracies) > 16 else accuracies[len(accuracies)//2:]
        accuracy_mean_second_half = np.mean(second_half) if second_half else 0.0
        
        # 4. Mejora entre mitades
        accuracy_improvement = accuracy_mean_second_half - accuracy_mean_first_half
        
        # 5. Variabilidad en clicks (desviación estándar normalizada)
        clicks_variability = np.std(clicks) / (np.mean(clicks) + 1e-6) if clicks else 0.0
        
        # 6. Total de clicks
        clicks_total = sum(clicks)
        
        # 7. Accuracy global
        total_hits = sum(all_metrics['hits'])
        global_accuracy = total_hits / clicks_total if clicks_total > 0 else 0.0
        
        # 8. Concentración de errores (entropía de distribución de errores)
        misses = all_metrics['misses']
        total_misses = sum(misses)
        if total_misses > 0:
            miss_probs = [m / total_misses for m in misses if m > 0]
            error_concentration = -sum(p * np.log(p + 1e-10) for p in miss_probs)
        else:
            error_concentration = 0.0
        
        # 9. Score de consistencia (inverso del coeficiente de variación)
        if len(accuracies) > 1 and np.mean(accuracies) > 0:
            cv = np.std(accuracies) / np.mean(accuracies)
            consistency_score = 1.0 / (1.0 + cv)  # Entre 0 y 1
        else:
            consistency_score = 0.5
        
        return {
            'accuracy_trend': accuracy_trend,
            'accuracy_mean_first_half': accuracy_mean_first_half,
            'accuracy_mean_second_half': accuracy_mean_second_half,
            'accuracy_improvement': accuracy_improvement,
            'clicks_variability': clicks_variability,
            'clicks_total': clicks_total,
            'global_accuracy': global_accuracy,
            'error_concentration': error_concentration,
            'consistency_score': consistency_score
        }
    
    def combine_all_features(self, activities_data: Dict) -> List[float]:
        """
        Combina características de todas las actividades en el formato del modelo (205 features).
        
        Mapeo de actividades a rondas del modelo:
        - Actividad 1 (Visual Discrimination): 10 rondas → Rondas 1-10
        - Actividad 2 (Sound-Letter): 10 rondas → Rondas 11-20  
        - Actividad 3 (Sequential Memory): 10 rondas → Rondas 21-30
        - Actividad 4 (Audio Dictation): 2 rondas → Rondas 31-32
        - Si hay menos de 32 rondas, se rellenan con valores promedio
        
        Args:
            activities_data: Dict con datos de usuario y actividades completadas
            Formato esperado:
            {
                'user': {'gender': 'Male/Female', 'age': 8, 'native_lang': True, 'other_lang': True},
                'activities': [
                    {'name': 'visual_discrimination', 'rounds': [...]},
                    {'name': 'sound_letter', 'rounds': [...]},
                    ...
                ]
            }
            
        Returns:
            Lista de 206 floats en el orden exacto que el modelo espera
        """
        features_dict = {}
        
        # 1. DATOS DEMOGRÁFICOS (4 features)
        user_data = activities_data.get('user', {})
        
        # Gender: Male=1, Female=0
        gender = user_data.get('gender', 'Male')
        features_dict['Gender'] = 1 if gender.lower() == 'male' else 0
        
        # Nativelang: Yes=1, No=0
        native_lang = user_data.get('native_lang', True)
        features_dict['Nativelang'] = 1 if native_lang else 0
        
        # Otherlang: Yes=1, No=0
        other_lang = user_data.get('other_lang', False)
        features_dict['Otherlang'] = 1 if other_lang else 0
        
        # Age: número entero
        features_dict['Age'] = user_data.get('age', 8)
        
        # 2. RECOLECTAR TODAS LAS RONDAS DE ACTIVIDADES
        all_rounds_metrics = {
            'clicks': [],
            'hits': [],
            'misses': [],
            'score': [],
            'accuracy': [],
            'missrate': []
        }
        
        activities = activities_data.get('activities', [])
        
        # Procesar cada actividad en orden
        for activity in activities:
            rounds = activity.get('rounds', [])
            metrics = self._extract_rounds_from_activity(rounds)
            
            # Agregar métricas de esta actividad
            for key in all_rounds_metrics.keys():
                all_rounds_metrics[key].extend(metrics[key])
        
        # 3. PROMEDIAR RONDAS PARA AJUSTAR A 32 (si hay más de 32)
        # El modelo espera exactamente 32 features de rondas (32 rondas × 6 métricas = 192 features)
        # Si hay 48 rondas (screening test), promediamos en grupos:
        # - Rondas 1-3 → Ronda 1 promediada
        # - Rondas 4-6 → Ronda 2 promediada
        # - ... hasta Rondas 46-48 → Ronda 16 promediada
        # Luego duplicamos para obtener 32 rondas equivalentes
        target_rounds = 32
        current_rounds = len(all_rounds_metrics['clicks'])
        
        if current_rounds > target_rounds:
            # Promediar rondas: agrupar cada 3 rondas (48 → 16) y duplicar (16 → 32)
            group_size = max(1, current_rounds // 16)  # Tamaño de grupo para obtener ~16 grupos
            
            # Agrupar y promediar
            grouped_metrics = {key: [] for key in all_rounds_metrics.keys()}
            
            for group_idx in range(0, current_rounds, group_size):
                group_end = min(group_idx + group_size, current_rounds)
                
                for key in all_rounds_metrics.keys():
                    group_values = all_rounds_metrics[key][group_idx:group_end]
                    grouped_metrics[key].append(np.mean(group_values) if group_values else 0.0)
            
            # Duplicar para obtener 32 rondas (16 grupos × 2)
            expanded_metrics = {key: [] for key in all_rounds_metrics.keys()}
            for key in all_rounds_metrics.keys():
                for value in grouped_metrics[key]:
                    expanded_metrics[key].extend([value, value])
            
            # Ajustar exactamente a 32 rondas si es necesario
            for key in all_rounds_metrics.keys():
                expanded_metrics[key] = expanded_metrics[key][:32]
                
                # Si hay menos de 32, rellenar con el último valor
                if len(expanded_metrics[key]) < 32:
                    last_value = expanded_metrics[key][-1] if expanded_metrics[key] else 0.0
                    expanded_metrics[key].extend([last_value] * (32 - len(expanded_metrics[key])))
            
            all_rounds_metrics = expanded_metrics
        
        elif current_rounds < target_rounds:
            # Rellenar con valores promedio de las rondas existentes
            for key in all_rounds_metrics.keys():
                if all_rounds_metrics[key]:
                    avg_value = np.mean(all_rounds_metrics[key])
                else:
                    avg_value = 0.0
                
                missing_count = target_rounds - current_rounds
                all_rounds_metrics[key].extend([avg_value] * missing_count)
        
        # 4. ASIGNAR MÉTRICAS DE LAS 32 RONDAS EQUIVALENTES (192 features)
        # Nota: Si el screening tiene 48 rondas, estas son 32 rondas promediadas
        # que representan toda la información disponible
        for i in range(1, 33):
            idx = i - 1
            features_dict[f'Clicks{i}'] = all_rounds_metrics['clicks'][idx]
            features_dict[f'Hits{i}'] = all_rounds_metrics['hits'][idx]
            features_dict[f'Misses{i}'] = all_rounds_metrics['misses'][idx]
            features_dict[f'Score{i}'] = all_rounds_metrics['score'][idx]
            features_dict[f'Accuracy{i}'] = all_rounds_metrics['accuracy'][idx]
            features_dict[f'Missrate{i}'] = all_rounds_metrics['missrate'][idx]
        
        # 5. CALCULAR FEATURES DERIVADAS (9 features)
        # Estos se calculan usando todas las rondas disponibles
        derived = self._calculate_derived_features(all_rounds_metrics)
        features_dict.update(derived)
        
        # 6. RETORNAR EN ORDEN EXACTO (205 features)
        # 4 demográficas + 192 de rondas (32×6) + 9 derivadas = 205 total
        return [features_dict[name] for name in self.feature_names]
