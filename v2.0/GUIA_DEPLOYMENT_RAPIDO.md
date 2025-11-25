## 🎯 PASOS RÁPIDOS PARA DEPLOYMENT EN CLOUD RUN

### **OPCIÓN 1: Usando Windows PowerShell (TU CASO)**

```powershell
# 1. Navega a la carpeta del backend
cd "C:\Users\elkin\Desktop\elkinpabon\Dyslexia-prediction-model\v2.0\web\backend"

# 2. Ejecuta el script de deployment (reemplaza "tu_usuario" por tu usuario de Docker Hub)
.\deploy.ps1 -DockerUsername "tu_usuario" -ProjectId "dyslexia-backend" -Region "us-central1"

# Ejemplo completo:
.\deploy.ps1 -DockerUsername "elkinpabon"
```

El script hace TODO automáticamente:
- ✓ Build de imagen Docker
- ✓ Push a Docker Hub
- ✓ Deploy en Google Cloud Run
- ✓ Configura puerto 8080
- ✓ Muestra la URL final

---

### **OPCIÓN 2: Pasos Manuales (Si el script no funciona)**

#### 1️⃣ **Crear cuenta Docker Hub** (si no tienes)
- Ir a https://hub.docker.com
- Registrarse
- Crear repositorio público llamado `dyslexia-backend`

#### 2️⃣ **Build imagen Docker**
```powershell
cd "C:\Users\elkin\Desktop\elkinpabon\Dyslexia-prediction-model\v2.0\web\backend"

# Login a Docker
docker login

# Build
docker build -t tu_usuario/dyslexia-backend:latest .

# Ejemplo:
docker build -t elkinpabon/dyslexia-backend:latest .
```

#### 3️⃣ **Push a Docker Hub**
```powershell
docker push tu_usuario/dyslexia-backend:latest

# Ejemplo:
docker push elkinpabon/dyslexia-backend:latest
```

Verifica en: https://hub.docker.com/r/tu_usuario/dyslexia-backend

#### 4️⃣ **Instalar Google Cloud CLI**
- Descargar de: https://cloud.google.com/sdk/docs/install
- Instalar y reiniciar terminal

#### 5️⃣ **Deploy en Cloud Run**
```powershell
# Login a Google Cloud
gcloud auth login

# Set project
gcloud config set project dyslexia-backend

# Deploy
gcloud run deploy dyslexia-backend `
  --image docker.io/tu_usuario/dyslexia-backend:latest `
  --platform managed `
  --region us-central1 `
  --port 8080 `
  --memory 2Gi `
  --cpu 1 `
  --allow-unauthenticated `
  --set-env-vars "FLASK_ENV=production"
```

#### 6️⃣ **Obtener la URL**
```powershell
gcloud run services describe dyslexia-backend --region us-central1 --format 'value(status.url)'

# Output será algo como:
# https://dyslexia-backend-abc123xyz.run.app
```

---

### **PASOS FINALES: Configurar Flutter APK**

#### 1️⃣ **Editar archivo de configuración**

Abre: `dyslexia_app/lib/services/api_service.dart`

Busca y reemplaza:
```dart
// Antes:
static const String API_URL = 'http://localhost:8080/api';

// Después (con tu URL real de Cloud Run):
static const String API_URL = 'https://dyslexia-backend-abc123xyz.run.app/api';
```

#### 2️⃣ **Rebuild de la APK**

```bash
# En la carpeta dyslexia_app
flutter clean
flutter pub get
flutter build apk --release
```

La APK quedará en: `build/app/outputs/flutter-apk/app-release.apk`

#### 3️⃣ **Probar endpoints**

```powershell
# Reemplaza URL por tu URL real
$URL = "https://dyslexia-backend-abc123xyz.run.app"

# Health check
curl "$URL/api/health"

# Model info
curl "$URL/api/model/info"

# Test predict (ejemplo)
$body = @{
    activities = @(0.95, 0.90, 0.88)
} | ConvertTo-Json

curl -Method POST `
  -Uri "$URL/api/predict" `
  -Headers @{"Content-Type"="application/json"} `
  -Body $body
```

---

## 🔐 Variables de Entorno importantes

Si necesitas cambiar variables después del deploy:

```powershell
# En Google Cloud Console:
# 1. Ir a Cloud Run
# 2. Click en "dyslexia-backend"
# 3. Click en "Edit & Deploy New Revision"
# 4. En "Runtime environment variables" añadir/cambiar:

# IMPORTANTE: No olvides cambiar estos valores REALES:
FLASK_ENV=production
MYSQLHOST=tu-basedatos-host-real
MYSQLDATABASE=dyslexia_db
MYSQLUSER=root
MYSQLPASSWORD=tu-password-real
CORS_ORIGINS=https://tu-backend-url.run.app
```

---

## ✅ Checklist Final

- [ ] ¿Tienes cuenta de Docker Hub?
- [ ] ¿Instalaste Google Cloud SDK?
- [ ] ¿Creaste proyecto en Google Cloud Console?
- [ ] ¿Habilitaste Cloud Run API?
- [ ] ¿Ejecutaste deploy.ps1 o hiciste build manualmente?
- [ ] ¿Copiaste la URL de Cloud Run en api_service.dart?
- [ ] ¿Buildaste nueva APK de Flutter?
- [ ] ¿Probaste los endpoints con curl?

---

## 📊 Resultado Final

```
┌─────────────────────────────────────┐
│     Backend en Cloud Run            │
│  https://dyslexia-backend-xxx.run.app
└─────────────────────────────────────┘
         ↑
         │ (HTTP/HTTPS)
         │
    ┌────┴─────────┐
    │              │
 [APK]        [Web]
```

**Tu backend será accesible desde:**
- ✓ APK en el dispositivo
- ✓ Navegador web
- ✓ Cualquier cliente HTTP

**Ventajas:**
- 🆓 Gratis (hasta 2M requests/mes)
- ⚡ Auto-escalado automático
- 🌍 CDN global
- 📊 Logs y métricas integrados
- 🔒 HTTPS automático
- ♻️ Versioning y rollback automático

---

## 🆘 Problemas Comunes

### "docker: command not found"
→ Instala Docker Desktop desde https://www.docker.com/products/docker-desktop

### "gcloud: command not found"
→ Instala Google Cloud SDK desde https://cloud.google.com/sdk/docs/install

### "El servicio dice 'Image pull error'"
→ Asegúrate que tu imagen en Docker Hub es PÚBLICA

### "Timeout en la base de datos"
→ Verifica que el host, usuario y password son correctos en variables de entorno

### "CORS error en la APK"
→ Añade tu backend URL a CORS_ORIGINS en .env.production y re-deploy

---

**¿Necesitas ayuda?** Consulta: `DEPLOYMENT_GUIDE.md` en la carpeta backend
