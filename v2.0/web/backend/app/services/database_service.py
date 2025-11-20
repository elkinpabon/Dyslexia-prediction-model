"""
Servicio de base de datos para operaciones CRUD
"""
from datetime import datetime
from app.models.database import db, User, Child, TestResult, ActivityRound
from sqlalchemy.exc import SQLAlchemyError


class DatabaseService:
    """Servicio para operaciones de base de datos"""
    
    # ============ USERS ============
    
    @staticmethod
    def create_user(user_data):
        """Crear un nuevo usuario"""
        try:
            user = User(
                id=user_data['id'],
                name=user_data['name'],
                age=user_data['age'],
                gender=user_data['gender'],
                native_lang=user_data.get('native_lang', True),
                other_lang=user_data.get('other_lang', False)
            )
            db.session.add(user)
            db.session.commit()
            return user
        except SQLAlchemyError as e:
            db.session.rollback()
            raise e
    
    @staticmethod
    def get_user(user_id):
        """Obtener usuario por ID"""
        return User.query.get(user_id)
    
    @staticmethod
    def get_all_users():
        """Obtener todos los usuarios"""
        return User.query.order_by(User.created_at.desc()).all()
    
    @staticmethod
    def update_user(user_id, user_data):
        """Actualizar usuario"""
        try:
            user = User.query.get(user_id)
            if not user:
                return None
            
            for key, value in user_data.items():
                if hasattr(user, key):
                    setattr(user, key, value)
            
            user.updated_at = datetime.utcnow()
            db.session.commit()
            return user
        except SQLAlchemyError as e:
            db.session.rollback()
            raise e
    
    @staticmethod
    def delete_user(user_id):
        """Eliminar usuario"""
        try:
            user = User.query.get(user_id)
            if not user:
                return False
            
            db.session.delete(user)
            db.session.commit()
            return True
        except SQLAlchemyError as e:
            db.session.rollback()
            raise e
    
    # ============ CHILDREN ============
    
    @staticmethod
    def create_child(child_data):
        """Crear un nuevo niño"""
        try:
            child = Child(
                id=child_data['id'],
                user_id=child_data['user_id'],
                name=child_data['name'],
                age=child_data['age'],
                gender=child_data['gender'],
                birth_date=child_data.get('birth_date')
            )
            db.session.add(child)
            db.session.commit()
            return child
        except SQLAlchemyError as e:
            db.session.rollback()
            raise e
    
    @staticmethod
    def get_child(child_id):
        """Obtener niño por ID"""
        return Child.query.get(child_id)
    
    @staticmethod
    def get_children_by_user(user_id):
        """Obtener todos los niños de un usuario"""
        return Child.query.filter_by(user_id=user_id).order_by(Child.created_at.desc()).all()
    
    # ============ GET OR CREATE HELPERS ============
    
    @staticmethod
    def get_or_create_user(user_id, user_data=None):
        """Obtener o crear usuario si no existe"""
        user = User.query.get(user_id)
        if not user and user_data:
            user = User(
                id=user_id,
                name=user_data.get('name', f'Usuario {user_id}'),
                age=user_data.get('age', 0),
                gender=user_data.get('gender', 'Unknown'),
                native_lang=user_data.get('native_lang', True),
                other_lang=user_data.get('other_lang', False)
            )
            db.session.add(user)
            db.session.flush()
            print(f"✅ Usuario creado automáticamente: {user_id}")
        return user
    
    @staticmethod
    def get_or_create_child(child_id, child_data=None):
        """Obtener o crear niño si no existe"""
        child = Child.query.get(child_id)
        if not child and child_data:
            child = Child(
                id=child_id,
                user_id=child_data.get('user_id', 'unknown'),
                name=child_data.get('name', f'Niño {child_id}'),
                age=child_data.get('age', 0),
                gender=child_data.get('gender', 'Unknown'),
                birth_date=child_data.get('birth_date')
            )
            db.session.add(child)
            db.session.flush()
            print(f"✅ Niño creado automáticamente: {child_id}")
        return child
    
    # ============ TEST RESULTS ============
    
    @staticmethod
    def create_test_result(result_data):
        """Crear un nuevo resultado de prueba"""
        try:
            # Asegurar que el usuario existe
            user_id = result_data['user_id']
            user_info = result_data.get('user_info', {})
            DatabaseService.get_or_create_user(user_id, user_info)
            
            # Asegurar que el niño existe (si se proporciona)
            child_id = result_data.get('child_id')
            if child_id:
                child_info = result_data.get('child_info', {})
                child_info['user_id'] = user_id  # Vincular al padre
                DatabaseService.get_or_create_child(child_id, child_info)
            
            test_result = TestResult(
                user_id=user_id,
                child_id=child_id,
                activity_id=result_data['activity_id'],
                activity_name=result_data['activity_name'],
                result=result_data['result'],
                probability=result_data['probability'],
                confidence=result_data['confidence'],
                risk_level=result_data['risk_level'],
                duration_seconds=result_data.get('duration_seconds'),
                total_clicks=result_data.get('total_clicks'),
                total_hits=result_data.get('total_hits'),
                total_misses=result_data.get('total_misses'),
                details=result_data.get('details')
            )
            db.session.add(test_result)
            db.session.flush()  # Para obtener el ID
            
            # Crear rondas si existen
            if 'rounds' in result_data and result_data['rounds']:
                for round_data in result_data['rounds']:
                    activity_round = ActivityRound(
                        test_result_id=test_result.id,
                        round_number=round_data['round_number'],
                        clicks=round_data.get('clicks', 0),
                        hits=round_data.get('hits', 0),
                        misses=round_data.get('misses', 0),
                        score=round_data.get('score', 0.0),
                        attempts=round_data.get('attempts', 0),
                        time_seconds=round_data.get('time_seconds', 0.0)
                    )
                    db.session.add(activity_round)
            
            db.session.commit()
            return test_result
        except SQLAlchemyError as e:
            db.session.rollback()
            raise e
    
    @staticmethod
    def get_test_result(result_id):
        """Obtener resultado por ID"""
        return TestResult.query.get(result_id)
    
    @staticmethod
    def get_all_test_results():
        """Obtener todos los resultados"""
        return TestResult.query.order_by(TestResult.timestamp.desc()).all()
    
    @staticmethod
    def get_test_results_by_user(user_id):
        """Obtener resultados de un usuario"""
        return TestResult.query.filter_by(user_id=user_id).order_by(TestResult.timestamp.desc()).all()
    
    @staticmethod
    def get_test_results_by_child(child_id):
        """Obtener resultados de un niño"""
        return TestResult.query.filter_by(child_id=child_id).order_by(TestResult.timestamp.desc()).all()
    
    @staticmethod
    def get_recent_test_results(limit=10):
        """Obtener resultados recientes"""
        return TestResult.query.order_by(TestResult.timestamp.desc()).limit(limit).all()
    
    # ============ STATISTICS ============
    
    @staticmethod
    def get_statistics():
        """Obtener estadísticas generales"""
        try:
            total_users = User.query.count()
            total_children = Child.query.count()
            total_tests = TestResult.query.count()
            positive_tests = TestResult.query.filter_by(result='SÍ').count()
            negative_tests = TestResult.query.filter_by(result='NO').count()
            
            # Calcular riesgo promedio
            avg_risk = db.session.query(db.func.avg(TestResult.probability)).scalar()
            
            return {
                'total_users': total_users,
                'total_children': total_children,
                'total_tests': total_tests,
                'positive_tests': positive_tests,
                'negative_tests': negative_tests,
                'average_risk': float(avg_risk) if avg_risk else 0.0
            }
        except SQLAlchemyError as e:
            raise e
    
    # ============ ACTIVITY ROUNDS ============
    
    @staticmethod
    def get_rounds_by_test(test_result_id):
        """Obtener rondas de un resultado de prueba"""
        return ActivityRound.query.filter_by(test_result_id=test_result_id).order_by(ActivityRound.round_number).all()
