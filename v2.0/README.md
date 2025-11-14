# Dyslexia Prediction Model

Sistema integral para la predicción de dislexia que incluye un modelo de machine learning, backend API y aplicación móvil Flutter.

## 📁 Estructura del Proyecto

### `/backend`
Backend de la aplicación desarrollado en Flask/Python que proporciona una API REST para realizar predicciones de dislexia.

**Características:**
- API RESTful para predicciones
- Gestión del modelo de machine learning
- Extracción de características
- Servicios de predicción

**Archivos principales:**
- `run.py`: Punto de entrada de la aplicación
- `requirements.txt`: Dependencias de Python
- `app/`: Código fuente de la aplicación
  - `routes/`: Endpoints de la API
  - `services/`: Lógica de negocio
  - `models/`: Gestión del modelo ML
  - `utils/`: Utilidades y helpers

### `/dataset`
Conjuntos de datos utilizados para entrenar y evaluar el modelo de predicción de dislexia.

**Archivos:**
- `Dyt-desktop.csv`: Dataset recopilado en dispositivos de escritorio
- `Dyt-tablet.csv`: Dataset recopilado en tablets

### `/dyslexia_app`
Aplicación móvil desarrollada en Flutter para realizar pruebas de screening de dislexia.

**Características:**
- Interfaz de usuario intuitiva
- Juegos y actividades interactivas
- Test de screening
- Estadísticas y seguimiento
- Integración con el backend para predicciones

**Estructura:**
- `lib/`: Código fuente de la aplicación
  - `screens/`: Pantallas de la app
  - `services/`: Servicios (API, audio, almacenamiento)
  - `models/`: Modelos de datos
  - `widgets/`: Componentes reutilizables
- `assets/`: Recursos multimedia (animaciones, imágenes, sonidos)
- `android/`: Configuración específica de Android

### `/pkl`
Archivos del modelo de machine learning entrenado.

**Contenido:**
- Modelo serializado en formato pickle
- `modelo_info.json`: Información y metadatos del modelo

### `/py`
Scripts de Python para el entrenamiento y uso del modelo.

**Archivos:**
- `modelo_dislexia.py`: Script de entrenamiento del modelo
- `predictor.py`: Script para realizar predicciones
- `log_info.py`: Utilidades de logging

## 🚀 Instalación

### Backend

```bash
cd backend
python -m venv venv
# Windows
venv\Scripts\activate
# Linux/Mac
source venv/bin/activate

pip install -r requirements.txt
python run.py
```

### Aplicación Móvil

```bash
cd dyslexia_app
flutter pub get
flutter run
```

## 📋 Requisitos

### Backend
- Python 3.8+
- Ver `backend/requirements.txt` para dependencias específicas

### Aplicación Móvil
- Flutter SDK 3.0+
- Android Studio / Xcode (para desarrollo móvil)
- Dart SDK

## 🔧 Configuración

1. Configurar las variables de entorno necesarias en el backend
2. Asegurar que los archivos del modelo en `/pkl` estén disponibles
3. Configurar la URL del backend en `dyslexia_app/lib/services/api_service.dart`

## 📱 Uso

1. Iniciar el servidor backend
2. Ejecutar la aplicación móvil
3. Realizar las actividades y tests de screening
4. Obtener predicciones y estadísticas

## 🤝 Contribuciones

Este proyecto es parte de un sistema de investigación para la detección temprana de dislexia.
