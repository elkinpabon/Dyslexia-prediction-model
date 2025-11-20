"""
Script para generar datos de prueba en la base de datos
"""
import sys
import os
from datetime import datetime, timedelta
import random

# Add parent directory to path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from app import create_app
from app.config import DevelopmentConfig
from app.services.database_service import DatabaseService

def generate_test_data():
    """Genera datos de prueba en la base de datos"""
    
    print("\n🔄 Generando datos de prueba...\n")
    
    app = create_app(DevelopmentConfig)
    
    with app.app_context():
        db_service = DatabaseService()
        
        # Crear usuarios
        users = [
            {
                'id': 'user_001',
                'name': 'María García',
                'age': 35,
                'gender': 'Female',
                'native_lang': True,
                'other_lang': True
            },
            {
                'id': 'user_002',
                'name': 'Juan Pérez',
                'age': 40,
                'gender': 'Male',
                'native_lang': True,
                'other_lang': False
            },
            {
                'id': 'user_003',
                'name': 'Ana Martínez',
                'age': 32,
                'gender': 'Female',
                'native_lang': True,
                'other_lang': True
            }
        ]
        
        for user_data in users:
            user = db_service.create_user(user_data)
            print(f"✓ Usuario creado: {user.name}")
        
        # Crear hijos
        children = [
            {
                'id': 'child_001',
                'user_id': 'user_001',
                'name': 'Carlos García',
                'age': 8,
                'gender': 'Male',
                'birth_date': (datetime.now() - timedelta(days=8*365)).date()
            },
            {
                'id': 'child_002',
                'user_id': 'user_001',
                'name': 'Laura García',
                'age': 10,
                'gender': 'Female',
                'birth_date': (datetime.now() - timedelta(days=10*365)).date()
            },
            {
                'id': 'child_003',
                'user_id': 'user_002',
                'name': 'Pedro Pérez',
                'age': 7,
                'gender': 'Male',
                'birth_date': (datetime.now() - timedelta(days=7*365)).date()
            },
            {
                'id': 'child_004',
                'user_id': 'user_003',
                'name': 'Sofía Martínez',
                'age': 9,
                'gender': 'Female',
                'birth_date': (datetime.now() - timedelta(days=9*365)).date()
            }
        ]
        
        for child_data in children:
            child = db_service.create_child(child_data)
            print(f"✓ Hijo creado: {child.name}")
        
        # Crear resultados de tests
        risk_levels = ['Bajo', 'Medio', 'Alto']
        results_data = ['SÍ', 'NO']
        
        print("\n🔄 Generando resultados de tests...\n")
        
        for i in range(20):
            # Seleccionar un hijo aleatorio
            child = random.choice(children)
            
            # Generar probabilidad aleatoria
            probability = round(random.uniform(5, 95), 2)
            
            # Determinar resultado basado en probabilidad
            result = 'SÍ' if probability > 50 else 'NO'
            
            # Determinar nivel de riesgo
            if probability < 30:
                risk_level = 'Bajo'
            elif probability < 70:
                risk_level = 'Medio'
            else:
                risk_level = 'Alto'
            
            # Generar rounds aleatorios
            num_rounds = random.randint(10, 20)
            rounds = []
            for r in range(1, num_rounds + 1):
                clicks = random.randint(5, 15)
                hits = random.randint(int(clicks * 0.5), clicks)
                misses = clicks - hits
                
                rounds.append({
                    'round_number': r,
                    'clicks': clicks,
                    'hits': hits,
                    'misses': misses,
                    'score': round(hits / clicks * 100, 2),
                    'attempts': random.randint(1, 3),
                    'time_seconds': round(random.uniform(5, 20), 2)
                })
            
            # Calcular totales
            total_clicks = sum(r['clicks'] for r in rounds)
            total_hits = sum(r['hits'] for r in rounds)
            total_misses = sum(r['misses'] for r in rounds)
            
            test_result_data = {
                'user_id': child['user_id'],
                'child_id': child['id'],
                'activity_id': 'screening_test',
                'activity_name': 'Test de Cribado',
                'result': result,
                'probability': probability,
                'confidence': round(random.uniform(70, 95), 2),
                'risk_level': risk_level,
                'duration_seconds': sum(r['time_seconds'] for r in rounds),
                'total_clicks': total_clicks,
                'total_hits': total_hits,
                'total_misses': total_misses,
                'details': {},
                'timestamp': datetime.now() - timedelta(days=random.randint(0, 30)),
                'rounds': rounds
            }
            
            saved_result = db_service.create_test_result(test_result_data)
            print(f"✓ Test {i+1}/20 creado - Resultado: {result}, Probabilidad: {probability}%, Riesgo: {risk_level}")
        
        print("\n✅ Datos de prueba generados exitosamente!")
        print("\n📊 Resumen:")
        print(f"  - {len(users)} usuarios")
        print(f"  - {len(children)} hijos")
        print(f"  - 20 resultados de tests")
        print(f"  - ~{sum(len(test_result_data['rounds']) for _ in range(20)) // 20 * 20} rondas de actividades\n")

if __name__ == '__main__':
    generate_test_data()
