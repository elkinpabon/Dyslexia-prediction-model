from flask import Blueprint, request
from app.services.prediction_service import PredictionService
from app.utils.helpers import Response, Validator

api_bp = Blueprint('api', __name__, url_prefix='/api')
prediction_service = PredictionService()

# ==== HEALTH CHECK ====
@api_bp.route('/health', methods=['GET'])
def health():
    """Verificar estado del servidor"""
    return Response.success(
        data={
            "status": "healthy" if prediction_service.is_healthy() else "unhealthy",
            "model_loaded": prediction_service.is_healthy()
        },
        message="Servidor operativo"
    )

# ==== MODEL INFO ====
@api_bp.route('/model/info', methods=['GET'])
def model_info():
    """Obtener información del modelo"""
    try:
        info = prediction_service.get_model_info()
        return Response.success(
            data=info,
            message="Información del modelo obtenida"
        )
    except Exception as e:
        return Response.error(str(e), 500)

# ==== PROCESAMIENTO DE ACTIVIDADES ====
@api_bp.route('/activities/process', methods=['POST'])
def process_activities():
    """Procesa todas las actividades completadas"""
    try:
        data = request.get_json()
        
        if not data or 'activities' not in data:
            return Response.error("Campo 'activities' requerido", 400)
        
        activities = data['activities']
        
        # Procesar actividades
        result = prediction_service.process_activities(activities)
        
        if not result.get('success'):
            return Response.error(result.get('error', 'Error procesando actividades'), 400)
        
        return Response.success(
            data=result,
            message="Actividades procesadas exitosamente"
        )
    
    except Exception as e:
        return Response.error(f"Error: {str(e)}", 500)

# ==== ACTIVIDAD INDIVIDUAL ====
@api_bp.route('/activities/<activity_name>', methods=['POST'])
def process_single_activity(activity_name):
    """Procesa una actividad individual"""
    try:
        data = request.get_json()
        
        if not data:
            return Response.error("Datos de actividad requeridos", 400)
        
        # Procesar actividad
        result = prediction_service.process_single_activity(activity_name, data)
        
        if not result.get('success'):
            return Response.error(result.get('error', 'Error procesando actividad'), 400)
        
        return Response.success(
            data=result,
            message=f"Actividad '{activity_name}' procesada"
        )
    
    except Exception as e:
        return Response.error(f"Error: {str(e)}", 500)

# ==== ACTIVIDAD: SECUENCIAS ====
@api_bp.route('/activities/sequence/evaluate', methods=['POST'])
def evaluate_sequence():
    """Evalúa secuencia y retorna SÍ/NO"""
    try:
        data = request.get_json()
        
        if not data or 'user_sequence' not in data or 'correct_sequence' not in data:
            return Response.error("Se requieren user_sequence y correct_sequence", 400)
        
        user_seq = data.get('user_sequence', [])
        correct_seq = data.get('correct_sequence', [])
        response_time = data.get('time', 0)
        
        activity_data = {
            'user': user_seq,
            'correct': correct_seq,
            'time': response_time
        }
        
        result = prediction_service.process_single_activity('sequence', activity_data)
        
        return Response.success(
            data={
                'activity': 'sequence',
                'result': 'SÍ' if result['has_dyslexia_indicators'] else 'NO',
                'probability': result['probability'],
                'confidence': result['confidence'],
                'details': result
            },
            message="Evaluación de secuencia completada"
        )
    
    except Exception as e:
        return Response.error(f"Error: {str(e)}", 500)

# ==== ACTIVIDAD: ESPEJO ====
@api_bp.route('/activities/mirror/evaluate', methods=['POST'])
def evaluate_mirror():
    """Evalúa simetría y retorna SÍ/NO"""
    try:
        data = request.get_json()
        
        if not data or 'is_symmetric' not in data or 'user_answer' not in data:
            return Response.error("Se requieren is_symmetric y user_answer", 400)
        
        is_sym = data.get('is_symmetric', False)
        user_ans = data.get('user_answer', False)
        response_time = data.get('time', 0)
        
        activity_data = {
            'is_symmetric': is_sym,
            'user_answer': user_ans,
            'time': response_time
        }
        
        result = prediction_service.process_single_activity('mirror', activity_data)
        
        return Response.success(
            data={
                'activity': 'mirror',
                'result': 'SÍ' if result['has_dyslexia_indicators'] else 'NO',
                'probability': result['probability'],
                'confidence': result['confidence'],
                'details': result
            },
            message="Evaluación de simetría completada"
        )
    
    except Exception as e:
        return Response.error(f"Error: {str(e)}", 500)

# ==== ACTIVIDAD: RITMO ====
@api_bp.route('/activities/rhythm/evaluate', methods=['POST'])
def evaluate_rhythm():
    """Evalúa ritmo y retorna SÍ/NO"""
    try:
        data = request.get_json()
        
        if not data or 'user_pattern' not in data or 'correct_pattern' not in data:
            return Response.error("Se requieren user_pattern y correct_pattern", 400)
        
        user_pat = data.get('user_pattern', [])
        correct_pat = data.get('correct_pattern', [])
        response_time = data.get('time', 0)
        
        activity_data = {
            'user': user_pat,
            'correct': correct_pat,
            'time': response_time
        }
        
        result = prediction_service.process_single_activity('rhythm', activity_data)
        
        return Response.success(
            data={
                'activity': 'rhythm',
                'result': 'SÍ' if result['has_dyslexia_indicators'] else 'NO',
                'probability': result['probability'],
                'confidence': result['confidence'],
                'details': result
            },
            message="Evaluación de ritmo completada"
        )
    
    except Exception as e:
        return Response.error(f"Error: {str(e)}", 500)

# ==== ACTIVIDAD: VELOCIDAD ====
@api_bp.route('/activities/speed/evaluate', methods=['POST'])
def evaluate_speed():
    """Evalúa velocidad de lectura y retorna SÍ/NO"""
    try:
        data = request.get_json()
        
        if not data or 'words_read' not in data or 'time' not in data:
            return Response.error("Se requieren words_read y time", 400)
        
        words_read = data.get('words_read', 0)
        time_sec = data.get('time', 1)
        comprehension = data.get('comprehension', 0.5)
        
        activity_data = {
            'words_read': words_read,
            'time': time_sec,
            'comprehension': comprehension
        }
        
        result = prediction_service.process_single_activity('speed', activity_data)
        
        return Response.success(
            data={
                'activity': 'speed',
                'result': 'SÍ' if result['has_dyslexia_indicators'] else 'NO',
                'probability': result['probability'],
                'confidence': result['confidence'],
                'details': result
            },
            message="Evaluación de velocidad completada"
        )
    
    except Exception as e:
        return Response.error(f"Error: {str(e)}", 500)

# ==== ACTIVIDAD: MEMORIA ====
@api_bp.route('/activities/memory/evaluate', methods=['POST'])
def evaluate_memory():
    """Evalúa memoria y retorna SÍ/NO"""
    try:
        data = request.get_json()
        
        if not data or 'user_sequence' not in data or 'correct_sequence' not in data:
            return Response.error("Se requieren user_sequence y correct_sequence", 400)
        
        user_seq = data.get('user_sequence', [])
        correct_seq = data.get('correct_sequence', [])
        attempts = data.get('attempts', 1)
        
        activity_data = {
            'user': user_seq,
            'correct': correct_seq,
            'attempts': attempts
        }
        
        result = prediction_service.process_single_activity('memory', activity_data)
        
        return Response.success(
            data={
                'activity': 'memory',
                'result': 'SÍ' if result['has_dyslexia_indicators'] else 'NO',
                'probability': result['probability'],
                'confidence': result['confidence'],
                'details': result
            },
            message="Evaluación de memoria completada"
        )
    
    except Exception as e:
        return Response.error(f"Error: {str(e)}", 500)

# ==== ACTIVIDAD: PLN (Procesamiento de Lenguaje Natural) ====
@api_bp.route('/activities/text/evaluate', methods=['POST'])
def evaluate_text():
    """Evalúa PLN (texto hablado vs correcto) y retorna SÍ/NO"""
    try:
        data = request.get_json()
        
        if not data or 'spoken_text' not in data or 'correct_text' not in data:
            return Response.error("Se requieren spoken_text y correct_text", 400)
        
        spoken = data.get('spoken_text', '')
        correct = data.get('correct_text', '')
        
        activity_data = {
            'spoken': spoken,
            'correct': correct
        }
        
        result = prediction_service.process_single_activity('text', activity_data)
        
        return Response.success(
            data={
                'activity': 'text',
                'result': 'SÍ' if result['has_dyslexia_indicators'] else 'NO',
                'probability': result['probability'],
                'confidence': result['confidence'],
                'details': result
            },
            message="Evaluación de PLN completada"
        )
    
    except Exception as e:
        return Response.error(f"Error: {str(e)}", 500)

# ==== SINGLE PREDICTION ====
@api_bp.route('/predict', methods=['POST'])
def predict():
    """Realizar una predicción individual"""
    try:
        data = request.get_json()
        
        if not data or 'features' not in data:
            return Response.error("Campo 'features' requerido", 400)
        
        features = data['features']
        
        # Validar características
        validation_errors = Validator.validate_features(features)
        if validation_errors:
            return Response.validation_error(validation_errors)
        
        # Predicción
        result = prediction_service.predict(features)
        
        return Response.success(
            data=result,
            message="Predicción completada"
        )
    
    except ValueError as e:
        return Response.error(str(e), 400)
    except Exception as e:
        return Response.error(f"Error en predicción: {str(e)}", 500)

# ==== BATCH PREDICTION ====
@api_bp.route('/predict/batch', methods=['POST'])
def predict_batch():
    """Realizar predicciones en lote"""
    try:
        data = request.get_json()
        
        if not data or 'data' not in data:
            return Response.error("Campo 'data' requerido", 400)
        
        data_list = data['data']
        
        if not isinstance(data_list, list) or len(data_list) == 0:
            return Response.error("'data' debe ser una lista no vacía", 400)
        
        # Predicciones
        results = prediction_service.predict_batch(data_list)
        
        return Response.success(
            data={
                "predictions": results,
                "total": len(results)
            },
            message=f"Predicciones completadas para {len(results)} muestras"
        )
    
    except ValueError as e:
        return Response.error(str(e), 400)
    except Exception as e:
        return Response.error(f"Error en predicciones: {str(e)}", 500)

# ==== ROUNDS EVALUATION (FORMATO CORRECTO DATASET DYT-DESKTOP.CSV) ====
@api_bp.route('/activities/rounds/evaluate', methods=['POST'])
def evaluate_rounds():
    """
    Evaluar actividad con sistema de rondas usando el formato EXACTO del modelo.
    
    Formato esperado:
    {
        "user": {
            "gender": "Male" o "Female",
            "age": 8,
            "native_lang": true,
            "other_lang": false
        },
        "activities": [
            {
                "name": "visual_discrimination",
                "rounds": [
                    {"clicks": 10, "hits": 8, "misses": 2, "score": 8, "accuracy": 0.8, "missrate": 0.2},
                    ...
                ]
            },
            ...
        ]
    }
    """
    try:
        data = request.get_json()
        
        if not data:
            return Response.error("No se recibieron datos", 400)
        
        # Validar formato
        if 'user' not in data:
            return Response.error("Campo 'user' requerido con gender, age, native_lang, other_lang", 400)
        
        if 'activities' not in data:
            return Response.error("Campo 'activities' requerido con lista de actividades completadas", 400)
        
        # Extraer características usando el FeatureExtractor correcto
        features = prediction_service.feature_extractor.combine_all_features(data)
        
        # Verificar que tenemos 206 features
        if len(features) != 206:
            return Response.error(f"Error: se generaron {len(features)} features en lugar de 206", 500)
        
        # Realizar predicción
        result = prediction_service.predict(features)
        
        return Response.success(
            data={
                "result": "SÍ" if result['prediction'] == 'Yes' else "NO",
                "probability": round(result['probability'] * 100, 2),
                "confidence": round(result['confidence'] * 100, 2),
                "risk_level": result['risk_level'],
                "details": {
                    "activities_processed": len(data['activities']),
                    "total_rounds": sum(len(act.get('rounds', [])) for act in data['activities']),
                    "features_extracted": len(features),
                    "user_age": data['user'].get('age'),
                    "user_gender": data['user'].get('gender')
                }
            },
            message="Evaluación completada usando modelo entrenado (89.48% accuracy)"
        )
    
    except ValueError as e:
        return Response.error(str(e), 400)
    except Exception as e:
        return Response.error(f"Error en evaluación: {str(e)}", 500)

# ==== ERROR HANDLERS ====
@api_bp.errorhandler(404)
def not_found(error):
    """Ruta no encontrada"""
    return Response.error("Ruta no encontrada", 404)

@api_bp.errorhandler(500)
def internal_error(error):
    """Error interno del servidor"""
    return Response.error("Error interno del servidor", 500)
