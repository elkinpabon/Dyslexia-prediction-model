from flask import Blueprint, request
from app.services.prediction_service import PredictionService
from app.services.database_service import DatabaseService
from app.utils.helpers import Response, Validator

api_bp = Blueprint('api', __name__, url_prefix='/api')
prediction_service = PredictionService()
db_service = DatabaseService()

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
        
        print("[RECV] Datos recibidos en /activities/rounds/evaluate")
        print(f"   Data es None: {data is None}")
        
        if not data:
            print("[ERROR] No se recibieron datos")
            return Response.error("No se recibieron datos", 400)
        
        print(f"   Keys en data: {list(data.keys())}")
        
        # Validar formato
        if 'user' not in data:
            print("❌ ERROR: Falta campo 'user'")
            return Response.error("Campo 'user' requerido con gender, age, native_lang, other_lang", 400)
        
        if 'activities' not in data:
            print("❌ ERROR: Falta campo 'activities'")
            return Response.error("Campo 'activities' requerido con lista de actividades completadas", 400)
        
        print(f"   User: {data['user']}")
        print(f"   Activities: {len(data['activities'])} actividades")
        for i, act in enumerate(data['activities']):
            print(f"     [{i}] {act.get('name', 'SIN_NOMBRE')}: {len(act.get('rounds', []))} rondas")
        
        # Extraer características usando el FeatureExtractor correcto
        features = prediction_service.feature_extractor.combine_all_features(data)
        
        # Verificar que tenemos 205 features
        if len(features) != 205:
            return Response.error(f"Se esperaban 205 características, se recibieron {len(features)}", 400)
        
        # Realizar predicción
        result = prediction_service.predict(features)
        
        # Determinar si hay indicadores de dislexia (riesgo medio o alto)
        has_indicators = result['risk_level'] in ['Medio', 'Alto']
        
        # Preparar datos para guardar
        test_result_data = {
            'user_id': data.get('userId', 'unknown'),
            'child_id': data.get('childId'),
            'activity_id': data['activities'][0].get('name', 'screening_test'),
            'activity_name': data['activities'][0].get('displayName', 'Prueba de Cribado'),
            'result': "SÍ" if has_indicators else "NO",
            'probability': round(result['probability'] * 100, 2),
            'confidence': round(result['confidence'] * 100, 2),
            'risk_level': result['risk_level'],
            'duration_seconds': data.get('durationSeconds'),
            'details': {
                "activities_processed": len(data['activities']),
                "total_rounds": sum(len(act.get('rounds', [])) for act in data['activities']),
                "features_extracted": len(features),
                "user_age": data['user'].get('age'),
                "user_gender": data['user'].get('gender')
            },
            # Información para crear usuario si no existe
            'user_info': {
                'name': data.get('userName', 'Usuario Tablet'),
                'age': data['user'].get('age', 0),
                'gender': data['user'].get('gender', 'Male'),
                'native_lang': data['user'].get('native_lang', True),
                'other_lang': data['user'].get('other_lang', False)
            },
            # Información para crear niño si no existe
            'child_info': {
                'name': data.get('childName', 'Niño'),
                'age': data.get('childAge', data['user'].get('age', 0)),
                'gender': data['user'].get('gender', 'Male'),
                'birth_date': data.get('childBirthDate')
            } if data.get('childId') else None
        }
        
        # Agregar rondas si existen
        if data['activities'] and 'rounds' in data['activities'][0]:
            rounds_data = []
            total_clicks = 0
            total_hits = 0
            total_misses = 0
            
            for i, round_data in enumerate(data['activities'][0]['rounds']):
                clicks = round_data.get('clicks', 0)
                hits = round_data.get('hits', 0)
                misses = round_data.get('misses', 0)
                
                total_clicks += clicks
                total_hits += hits
                total_misses += misses
                
                rounds_data.append({
                    'round_number': i + 1,
                    'clicks': clicks,
                    'hits': hits,
                    'misses': misses,
                    'score': round_data.get('score', 0.0),
                    'attempts': round_data.get('attempts', 0),
                    'time_seconds': round_data.get('time', 0.0)
                })
            
            test_result_data['rounds'] = rounds_data
            test_result_data['total_clicks'] = total_clicks
            test_result_data['total_hits'] = total_hits
            test_result_data['total_misses'] = total_misses
        
        # Guardar en base de datos
        try:
            saved_result = db_service.create_test_result(test_result_data)
            print(f"✅ Resultado guardado en BD con ID: {saved_result.id}")
        except Exception as e:
            print(f"[WARN] Error guardando en BD: {str(e)}")
            # No fallar la request si falla el guardado
        
        # Resultado basado en si hay indicadores de dislexia (riesgo medio o alto)
        has_indicators = test_result_data['risk_level'] in ['Medio', 'Alto']
        return Response.success(
            data={
                "result": "SÍ" if has_indicators else "NO",
                "probability": test_result_data['probability'],
                "confidence": test_result_data['confidence'],
                "risk_level": test_result_data['risk_level'],
                "details": test_result_data['details']
            },
            message="Evaluación completada usando modelo entrenado (89.48% accuracy)"
        )
    
    except ValueError as e:
        return Response.error(str(e), 400)
    except Exception as e:
        return Response.error(f"Error en evaluación: {str(e)}", 500)

# ==== ADMIN PANEL ENDPOINTS ====

@api_bp.route('/users', methods=['GET', 'POST'])
def users():
    """Gestión de usuarios"""
    if request.method == 'GET':
        try:
            users = db_service.get_all_users()
            return Response.success(
                data=[user.to_dict() for user in users],
                message="Usuarios obtenidos exitosamente"
            )
        except Exception as e:
            return Response.error(f"Error obteniendo usuarios: {str(e)}", 500)
    
    elif request.method == 'POST':
        try:
            data = request.get_json()
            user = db_service.create_user(data)
            return Response.success(
                data=user.to_dict(),
                message="Usuario creado exitosamente"
            )
        except Exception as e:
            return Response.error(f"Error creando usuario: {str(e)}", 500)

@api_bp.route('/users/<user_id>', methods=['GET', 'PUT', 'DELETE'])
def user_by_id(user_id):
    """Operaciones sobre un usuario específico"""
    if request.method == 'GET':
        try:
            user = db_service.get_user(user_id)
            if not user:
                return Response.error("Usuario no encontrado", 404)
            return Response.success(data=user.to_dict(), message="Usuario obtenido exitosamente")
        except Exception as e:
            return Response.error(f"Error obteniendo usuario: {str(e)}", 500)
    
    elif request.method == 'PUT':
        try:
            data = request.get_json()
            user = db_service.update_user(user_id, data)
            if not user:
                return Response.error("Usuario no encontrado", 404)
            return Response.success(data=user.to_dict(), message="Usuario actualizado exitosamente")
        except Exception as e:
            return Response.error(f"Error actualizando usuario: {str(e)}", 500)
    
    elif request.method == 'DELETE':
        try:
            success = db_service.delete_user(user_id)
            if not success:
                return Response.error("Usuario no encontrado", 404)
            return Response.success(message="Usuario eliminado exitosamente")
        except Exception as e:
            return Response.error(f"Error eliminando usuario: {str(e)}", 500)

@api_bp.route('/children', methods=['GET', 'POST'])
def children():
    """Gestión de niños"""
    if request.method == 'GET':
        try:
            children = db_service.get_all_children()
            return Response.success(
                data=[child.to_dict() for child in children],
                message="Niños obtenidos exitosamente"
            )
        except Exception as e:
            return Response.error(f"Error obteniendo niños: {str(e)}", 500)
    
    elif request.method == 'POST':
        try:
            data = request.get_json()
            print(f"\n📝 Datos recibidos para crear niño: {data}\n")
            
            # Validar que el usuario (tutor) existe
            user_id = data.get('user_id')
            if not user_id:
                return Response.error("user_id es requerido", 400)
            
            user = db_service.get_user(user_id)
            if not user:
                print(f"[WARN] Usuario {user_id} no existe, creando automáticamente...")
                return Response.error(f"Usuario (tutor) con ID '{user_id}' no encontrado. Registra primero al tutor.", 404)
            
            # Crear el niño
            child = db_service.create_child(data)
            
            # Convertir a dict y retornar
            child_dict = child.to_dict()
            print(f"[OK] Retornando child_dict: {child_dict}")
            
            return Response.success(
                data=child_dict,
                message="Niño creado exitosamente",
                status_code=201
            )
        except Exception as e:
            import traceback
            error_msg = traceback.format_exc()
            print(f"[ERROR] Error creando niño:\n{error_msg}")
            return Response.error(f"Error creando niño: {str(e)}", 500)

@api_bp.route('/children/<child_id>', methods=['GET', 'PUT', 'DELETE'])
def child_by_id(child_id):
    """Operaciones sobre un niño específico"""
    if request.method == 'GET':
        try:
            child = db_service.get_child(child_id)
            if not child:
                return Response.error("Niño no encontrado", 404)
            return Response.success(data=child.to_dict(), message="Niño obtenido exitosamente")
        except Exception as e:
            return Response.error(f"Error obteniendo niño: {str(e)}", 500)
    
    elif request.method == 'PUT':
        try:
            data = request.get_json()
            child = db_service.update_child(child_id, data)
            if not child:
                return Response.error("Niño no encontrado", 404)
            return Response.success(data=child.to_dict(), message="Niño actualizado exitosamente")
        except Exception as e:
            return Response.error(f"Error actualizando niño: {str(e)}", 500)
    
    elif request.method == 'DELETE':
        try:
            success = db_service.delete_child(child_id)
            if not success:
                return Response.error("Niño no encontrado", 404)
            return Response.success(message="Niño eliminado exitosamente")
        except Exception as e:
            return Response.error(f"Error eliminando niño: {str(e)}", 500)

@api_bp.route('/results', methods=['GET'])
def get_all_results():
    """Obtener todos los resultados de pruebas"""
    try:
        results = db_service.get_all_test_results()
        data = []
        for result in results:
            result_dict = result.to_dict()
            # Agregar nombre de usuario si existe
            if result.user:
                result_dict['userName'] = result.user.name
            data.append(result_dict)
        
        return Response.success(data=data, message="Resultados obtenidos exitosamente")
    except Exception as e:
        return Response.error(f"Error obteniendo resultados: {str(e)}", 500)

@api_bp.route('/results/user/<user_id>', methods=['GET'])
def get_results_by_user(user_id):
    """Obtener resultados de un usuario específico"""
    try:
        results = db_service.get_test_results_by_user(user_id)
        return Response.success(
            data=[result.to_dict() for result in results],
            message="Resultados del usuario obtenidos exitosamente"
        )
    except Exception as e:
        return Response.error(f"Error obteniendo resultados del usuario: {str(e)}", 500)

@api_bp.route('/results/child/<child_id>', methods=['GET'])
def get_results_by_child(child_id):
    """Obtener resultados de un niño específico"""
    try:
        results = db_service.get_test_results_by_child(child_id)
        return Response.success(
            data=[result.to_dict() for result in results],
            message="Resultados del niño obtenidos exitosamente"
        )
    except Exception as e:
        return Response.error(f"Error obteniendo resultados del niño: {str(e)}", 500)

@api_bp.route('/statistics', methods=['GET'])
def get_statistics():
    """Obtener estadísticas generales del sistema"""
    try:
        stats = db_service.get_statistics()
        return Response.success(data=stats, message="Estadísticas obtenidas exitosamente")
    except Exception as e:
        return Response.error(f"Error obteniendo estadísticas: {str(e)}", 500)

# ==== ERROR HANDLERS ====
@api_bp.errorhandler(404)
def not_found(error):
    """Ruta no encontrada"""
    return Response.error("Ruta no encontrada", 404)

@api_bp.errorhandler(500)
def internal_error(error):
    """Error interno del servidor"""
    return Response.error("Error interno del servidor", 500)
