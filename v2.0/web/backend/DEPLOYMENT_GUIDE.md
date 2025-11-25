# 🚀 Guía Completa: Deploy Backend en Google Cloud Run con Docker

## 📋 Pre-requisitos

- [ ] Cuenta de Google Cloud Console
- [ ] Docker Desktop instalado (Windows/Mac) o Docker CLI (Linux)
- [ ] Cuenta de Docker Hub
- [ ] `gcloud` CLI instalado y configurado
- [ ] Proyecto creado en Google Cloud Console

## 🔐 Paso 1: Preparar Credenciales

### 1.1 Crear archivo `.env.production` local (NO subir a Git)

```bash
# Copia .env.example a .env.production
cp .env.example .env.production
```

### 1.2 Editar `.env.production` con tus valores reales

```env
FLASK_ENV=production
FLASK_DEBUG=False
SECRET_KEY=tu-clave-super-secreta-aqui-minimo-32-caracteres
MYSQLHOST=tu-basedatos-host.c.tidbcloud.com  # o Cloud SQL
MYSQLPORT=3306
MYSQLDATABASE=dyslexia_db
MYSQLUSER=root
MYSQLPASSWORD=tu-contraseña-segura
CORS_ORIGINS=https://tu-backend-url.run.app
```

⚠️ **NUNCA subas este archivo a GitHub**

## 🐳 Paso 2: Build y Push a Docker Hub

### 2.1 Hacer login en Docker

```bash
docker login
# Ingresa tu usuario y contraseña de Docker Hub
```

### 2.2 Build de la imagen Docker

Desde la carpeta `web/backend/`:

```bash
# Reemplaza USERNAME_DOCKERHUB por tu usuario real
docker build -t username_dockerhub/dyslexia-backend:latest .

# Ejemplo si tu usuario es "elkinpabon":
docker build -t elkinpabon/dyslexia-backend:latest .
```

### 2.3 Hacer push a Docker Hub

```bash
docker push username_dockerhub/dyslexia-backend:latest

# Ejemplo:
docker push elkinpabon/dyslexia-backend:latest
```

✅ Ahora tu imagen está en Docker Hub y visible en: https://hub.docker.com/r/username_dockerhub/dyslexia-backend

## ☁️ Paso 3: Configurar Google Cloud Console

### 3.1 Crear Proyecto en Google Cloud

1. Ir a https://console.cloud.google.com
2. Crear nuevo proyecto: "Dyslexia-Backend"
3. Habilitar Cloud Run API:
   - Ir a "APIs y Servicios"
   - Buscar "Cloud Run"
   - Click en "Habilitar"

### 3.2 Habilitar Cloud SQL (opcional, para base de datos)

Si usarás Cloud SQL:

1. Ir a "SQL" en el menú izquierdo
2. Click en "Crear instancia"
3. Elegir MySQL 8.0
4. Configurar:
   - ID de instancia: `dyslexia-db`
   - Contraseña root: (genera una segura)
   - Ubicación: cerca de tus usuarios
5. Click en "Crear instancia"

## 🚀 Paso 4: Deploy en Cloud Run

### 4.1 Opción A: Deploy desde Docker Hub (Recomendado)

```bash
# Login en Google Cloud
gcloud auth login

# Configurar proyecto
gcloud config set project YOUR_PROJECT_ID
# Reemplaza YOUR_PROJECT_ID con tu ID real

# Deploy
gcloud run deploy dyslexia-backend \
  --image docker.io/username_dockerhub/dyslexia-backend:latest \
  --platform managed \
  --region us-central1 \
  --port 8080 \
  --memory 2Gi \
  --cpu 1 \
  --timeout 3600 \
  --set-env-vars "FLASK_ENV=production,MYSQLHOST=tu-host,MYSQLDATABASE=dyslexia_db,MYSQLUSER=root,MYSQLPASSWORD=tu-password" \
  --allow-unauthenticated
```

### 4.2 Opción B: Deploy desde Google Cloud Build

```bash
# Crear un archivo cloudbuild.yaml en la raíz del proyecto

# Luego ejecutar:
gcloud builds submit --config=cloudbuild.yaml
```

## 📝 Archivo `cloudbuild.yaml` (opcional)

Crea este archivo en la raíz de `web/backend/`:

```yaml
steps:
  # Paso 1: Build imagen Docker
  - name: 'gcr.io/cloud-builders/docker'
    args: ['build', '-t', 'gcr.io/$PROJECT_ID/dyslexia-backend:$COMMIT_SHA', '.']
  
  # Paso 2: Push a Google Container Registry
  - name: 'gcr.io/cloud-builders/docker'
    args: ['push', 'gcr.io/$PROJECT_ID/dyslexia-backend:$COMMIT_SHA']
  
  # Paso 3: Deploy en Cloud Run
  - name: 'gcr.io/cloud-builders/gke-deploy'
    args:
      - run
      - --filename=.
      - --image=gcr.io/$PROJECT_ID/dyslexia-backend:$COMMIT_SHA
      - --location=us-central1
      - --config=cloudbuild.yaml
      - --replace

images:
  - 'gcr.io/$PROJECT_ID/dyslexia-backend:$COMMIT_SHA'

serviceAccount: 'projects/$PROJECT_ID/serviceAccounts/cloud-build@$PROJECT_ID.iam.gserviceaccount.com'
```

## ✅ Paso 5: Verificar Deploy

Una vez que el deploy se complete:

```bash
# Obtener la URL del servicio
gcloud run services list

# Output:
# SERVICE              REGION       URL                                    ACTIVE
# dyslexia-backend     us-central1   https://dyslexia-backend-xxx.run.app   ✓
```

### 5.1 Probar la API

```bash
# Health check
curl https://dyslexia-backend-xxx.run.app/api/health

# Información del modelo
curl https://dyslexia-backend-xxx.run.app/api/model/info
```

## 📱 Paso 6: Usar URL en Flutter APK

En tu código Dart (`api_service.dart`), configura:

```dart
class ApiService {
  static const String API_URL = 'https://dyslexia-backend-xxx.run.app/api';
  // Reemplaza xxx con tu ID real de Cloud Run
  
  // Resto del código...
}
```

Luego en la configuración de CORS en el backend, añade tu dominio Flutter:

```env
CORS_ORIGINS=https://dyslexia-backend-xxx.run.app,http://localhost:8080
```

## 🔄 Paso 7: Actualizar después de cambios

Cuando hagas cambios en el backend:

```bash
# 1. Build nueva imagen
docker build -t username_dockerhub/dyslexia-backend:latest .

# 2. Push
docker push username_dockerhub/dyslexia-backend:latest

# 3. Re-deploy en Cloud Run
gcloud run deploy dyslexia-backend \
  --image docker.io/username_dockerhub/dyslexia-backend:latest \
  --platform managed \
  --region us-central1 \
  --port 8080 \
  --allow-unauthenticated
```

## 🆘 Troubleshooting

### Error: "Build failed" o "Image pull error"

- Verifica que la imagen está en Docker Hub público
- Usa `docker push username/dyslexia-backend:latest` para estar seguro

### Error: "Connection timeout en base de datos"

- Asegúrate que MYSQLHOST es correcto
- Verifica Cloud SQL está corriendo
- Crea un Cloud SQL Proxy si está en red privada

### Error: "Port already in use"

Cloud Run requiere puerto 8080. Verifica:
- `EXPOSE 8080` en Dockerfile ✓
- `port=8080` en `run.py` ✓
- Variable `PORT=8080` en env

### Error: CORS issues desde Flutter

Añade tu APK origin a CORS_ORIGINS o usa `*` en desarrollo:

```env
CORS_ORIGINS=*
```

## 💡 Variables de Entorno en Cloud Run UI

1. Ir a Cloud Run Console
2. Click en tu servicio `dyslexia-backend`
3. Click en "Edit & Deploy New Revision"
4. En "Runtime settings" → "Runtime environment variables"
5. Añadir variables:
   - `FLASK_ENV`: `production`
   - `MYSQLHOST`: tu host
   - `MYSQLDATABASE`: `dyslexia_db`
   - `MYSQLUSER`: `root`
   - `MYSQLPASSWORD`: tu password
6. Click en "Deploy"

## 📊 Monitoreo

```bash
# Ver logs en tiempo real
gcloud run logs read dyslexia-backend --follow

# Ver métricas
gcloud run describe dyslexia-backend
```

## 🎯 Resultado Final

✅ Backend corriendo en: `https://dyslexia-backend-xxx.run.app/api`

✅ APK conectado a la URL de producción

✅ Base de datos en Cloud SQL

✅ Logs y monitoreo en Cloud Console

---

**Notas:**
- El primer deploy tarda ~2-3 minutos
- Cloud Run escala automáticamente según demanda
- Precio: gratis hasta 2M requests/mes (siempre)
- Tienes 5 despliegues gratis al mes
