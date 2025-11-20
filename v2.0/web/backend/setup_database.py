"""
Script completo para resetear y preparar la base de datos
"""
import subprocess
import sys
import os

def run_script(script_name, description):
    """Ejecutar un script de Python"""
    print(f"\n{'='*60}")
    print(f"  {description}")
    print(f"{'='*60}\n")
    
    result = subprocess.run([sys.executable, script_name], cwd=os.path.dirname(__file__))
    
    if result.returncode != 0:
        print(f"\n❌ Error ejecutando {script_name}")
        return False
    
    return True

def main():
    """Ejecutar secuencia completa de configuración"""
    print("\n" + "="*60)
    print("  CONFIGURACIÓN COMPLETA DE BASE DE DATOS")
    print("="*60)
    
    # Paso 1: Limpiar base de datos
    if not run_script('clear_database.py', '1️⃣  LIMPIANDO BASE DE DATOS'):
        return
    
    # Paso 2: Inicializar tablas
    if not run_script('init_database.py', '2️⃣  CREANDO TABLAS'):
        return
    
    print("\n" + "="*60)
    print("  ✅ CONFIGURACIÓN COMPLETADA")
    print("="*60)
    print("\n📋 Estado:")
    print("   • Base de datos limpia")
    print("   • Tablas creadas correctamente")
    print("   • Lista para recibir datos de la tablet")
    print("\n🚀 Próximos pasos:")
    print("   1. Ejecutar backend: python run.py")
    print("   2. Ejecutar frontend: cd ../frontend && npm start")
    print("   3. Probar desde tablet Flutter")
    print()

if __name__ == '__main__':
    main()
