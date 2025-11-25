# Dyslexia Prediction Model

Sistema integral para la predicción de dislexia que incluye un modelo de machine learning, backend API dockerizado, aplicación móvil Flutter y despliegue en Google Cloud Run.

## 🏗️ Arquitectura General

```
┌─────────────────────────────────────────────────────────────────┐
│                    ARQUITECTURA DEL SISTEMA                     │
└─────────────────────────────────────────────────────────────────┘

   ┌──────────────────────┐
   │   Flutter APK        │
   │  (Dispositivo)       │
   │                      │
   │ • Test screening     │
   │ • Audio capture      │
   │ • Envía datos JSON   │
   └──────────────┬───────┘
                  │ HTTP/HTTPS
                  │
                  ▼
   ┌──────────────────────────────────────┐
   │   Google Cloud Run                   │
   │ ☁️ https://dyslexia-backend-xxx.run.app
   │                                      │
   │  ┌────────────────────────────────┐ │
   │  │  Flask Backend (Docker)        │ │
   │  │  • API REST                    │ │
   │  │  • Predicción ML               │ │
   │  │  • XGBoost Modelo              │ │
   │  └────────────────────────────────┘ │
   │                                      │
   │  ┌────────────────────────────────┐ │
   │  │  Modelos Serializado           │ │
   │  │  • modelo_dislexia.pkl         │ │
   │  │  • scaler.pkl                  │ │
   │  │  • imputer.pkl                 │ │
   │  └────────────────────────────────┘ │
   │                                      │
   │  ┌────────────────────────────────┐ │
   │  │  Base de Datos (Cloud SQL)     │ │
   │  │  MySQL - Resultados & Usuarios │ │
   │  └────────────────────────────────┘ │
   └──────────────────────────────────────┘
                  ▲
                  │ Predicción + Resultados
                  │
            ┌─────┴─────┐
            │           │
       [APK]       [Dashboard Web]
```

## ✨ Características Principales

### 🔬 Backend ML
- Modelo XGBoost entrenado con 85.1% de precisión
- API RESTful con Flask
- **NUEVO**: Dockerizado y desplegado en Google Cloud Run
- Predicción en tiempo real
- Extracción automática de características

### 📱 Aplicación Móvil
- Tests interactivos de screening
- Captura de audio (Speech-to-Text con OpenAI)
- Cálculo de métricas en tiempo real
- Sincronización con backend

### ☁️ Infraestructura Cloud
- **Docker**: Containerización del backend
- **Google Cloud Run**: Despliegue serverless
- **Cloud SQL**: Base de datos MySQL
- **Escalado automático**: Maneja múltiples usuarios
- **HTTPS**: Conexión segura

## 📋 Estructura del Proyecto

### `/web/backend` - API Flask en Docker
Backend de la aplicación desarrollado en Flask/Python, **ahora completamente containerizado**.

**Características:**
- ✓ API RESTful para predicciones
- ✓ Modelo ML con calibración
- ✓ Dockerfile listo para Cloud Run
- ✓ Scripts de deployment automático

**Archivos principales:**
- `run.py`: Punto de entrada (soporte para puerto 8080)
- `requirements.txt`: Dependencias de Python
- `Dockerfile`: Configuración para Docker
- `deploy.ps1`: Script de deployment automático (Windows)
- `deploy.sh`: Script de deployment automático (Linux/Mac)
- `DEPLOYMENT_GUIDE.md`: Guía completa de despliegue
- `app/`: Código fuente de la aplicación
  - `routes/`: Endpoints de la API
  - `services/`: Lógica de negocio (predictor, extractor)
  - `models/`: Gestión del modelo ML
  - `utils/`: Utilidades y helpers
- `pkl/`: Modelos serializados
  - `modelo_dislexia.pkl`: Modelo XGBoost
  - `scaler.pkl`: Normalizador
  - `imputer.pkl`: Imputador de valores

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

## ☁️ Despliegue en Producción (Google Cloud Run)

### 🚀 Inicio Rápido (Windows PowerShell)

```powershell
# 1. Navega al backend
cd "web/backend"

# 2. Ejecuta el script de deployment
.\deploy.ps1 -DockerUsername "tu_usuario_dockerhub"

# El script hará todo automáticamente:
# ✓ Build Docker image
# ✓ Push a Docker Hub
# ✓ Deploy en Cloud Run
# ✓ Muestra URL final
```

### 📚 Guías Completas

- **Guía Rápida**: Lee `GUIA_DEPLOYMENT_RAPIDO.md`
- **Guía Detallada**: Lee `web/backend/DEPLOYMENT_GUIDE.md`

### 📋 Requisitos para Despliegue

1. **Docker Hub**: Cuenta gratuita en https://hub.docker.com
2. **Google Cloud**: Cuenta gratuita en https://cloud.google.com
3. **Docker Desktop**: Instalado localmente
4. **Google Cloud SDK**: `gcloud` CLI instalado

### 🔄 Pasos de Deployment

1. **Build & Push a Docker Hub**
   ```bash
   docker build -t usuario/dyslexia-backend:latest .
   docker push usuario/dyslexia-backend:latest
   ```

2. **Deploy en Cloud Run**
   ```bash
   gcloud run deploy dyslexia-backend \
     --image docker.io/usuario/dyslexia-backend:latest \
     --platform managed \
     --region us-central1 \
     --port 8080 \
     --allow-unauthenticated
   ```

3. **Obtener URL**
   ```bash
   gcloud run services describe dyslexia-backend --region us-central1 --format 'value(status.url)'
   ```

4. **Usar en Flutter APK**
   - Editar `dyslexia_app/lib/services/api_service.dart`
   - Reemplazar `API_URL` con la URL de Cloud Run
   - Rebuild APK: `flutter build apk --release`

### 💰 Costos

- **Cloud Run**: Gratis hasta 2M requests/mes
- **Cloud Storage**: 5GB gratuitos (modelos PKL)
- **Cloud SQL**: ~$15-30/mes según configuración

## 📱 Uso

1. **Desplegar backend** en Cloud Run (ver sección anterior)
2. **Build APK** de Flutter con URL correcta
3. **Ejecutar en dispositivo** y realizar tests
4. **Ver predicciones** en tiempo real desde backend
5. **Consultar logs** en Cloud Console

## 🧪 Testing

### Backend - Endpoints Disponibles

```bash
# Health check
curl https://your-backend.run.app/api/health

# Información del modelo
curl https://your-backend.run.app/api/model/info

# Predicción
curl -X POST https://your-backend.run.app/api/predict \
  -H "Content-Type: application/json" \
  -d '{"activities": [0.88, 0.85, 0.80]}'
```

### Niveles de Riesgo

| Probabilidad | Nivel | Acción |
|-------------|-------|--------|
| < 5% | 🟢 Bajo | Sin riesgo aparente |
| 5-30% | 🟡 Moderado | Seguimiento recomendado |
| 30-70% | 🟠 Alto | Evaluación clínica recomendada |
| ≥ 70% | 🔴 Crítico | Atención inmediata recomendada |

## 🤝 Contribuciones

Este proyecto es parte de un sistema de investigación para la detección temprana de dislexia.

