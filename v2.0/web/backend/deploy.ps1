# ======================================================
#  SCRIPT AUTOMATIZADO PARA DEPLOY EN CLOUD RUN
#  Uso (PowerShell): .\deploy.ps1 -DockerUsername "username_dockerhub" -ProjectId "dyslexia-backend" -Region "us-central1"
# ======================================================

param(
    [Parameter(Mandatory=$true)]
    [string]$DockerUsername,
    
    [Parameter(Mandatory=$false)]
    [string]$ProjectId = "dyslexia-backend",
    
    [Parameter(Mandatory=$false)]
    [string]$Region = "us-central1"
)

# Verificar argumentos
if ([string]::IsNullOrEmpty($DockerUsername)) {
    Write-Host "❌ Error: Usuario de Docker Hub no especificado" -ForegroundColor Red
    Write-Host "Uso: .\deploy.ps1 -DockerUsername 'username_dockerhub' [-ProjectId 'project-id'] [-Region 'region']"
    Write-Host "Ejemplo: .\deploy.ps1 -DockerUsername 'elkinpabon'"
    exit 1
}

$ImageName = "$DockerUsername/dyslexia-backend:latest"

Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Yellow
Write-Host "  🚀 DEPLOYMENT A CLOUD RUN - BACKEND DYSLEXIA" -ForegroundColor Yellow
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Yellow
Write-Host ""
Write-Host "Configuración:" -ForegroundColor Green
Write-Host "  Docker Image: $ImageName"
Write-Host "  GCP Project: $ProjectId"
Write-Host "  Region: $Region"
Write-Host ""

# Paso 1: Verificar Docker
Write-Host "[1/5] Verificando Docker..." -ForegroundColor Yellow
try {
    docker ps > $null 2>&1
} catch {
    Write-Host "⚠️  Necesitas hacer login en Docker Hub" -ForegroundColor Yellow
    docker login
}
Write-Host "✓ Docker authenticated" -ForegroundColor Green
Write-Host ""

# Paso 2: Build imagen
Write-Host "[2/5] Construyendo imagen Docker..." -ForegroundColor Yellow
docker build -t $ImageName .
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Build falló" -ForegroundColor Red
    exit 1
}
Write-Host "✓ Docker image built successfully" -ForegroundColor Green
Write-Host ""

# Paso 3: Push a Docker Hub
Write-Host "[3/5] Subiendo a Docker Hub..." -ForegroundColor Yellow
docker push $ImageName
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Push a Docker Hub falló" -ForegroundColor Red
    exit 1
}
Write-Host "✓ Image pushed to Docker Hub" -ForegroundColor Green
Write-Host ""

# Paso 4: Login Google Cloud
Write-Host "[4/5] Autenticando con Google Cloud..." -ForegroundColor Yellow
gcloud auth login
gcloud config set project $ProjectId
Write-Host "✓ Google Cloud configured" -ForegroundColor Green
Write-Host ""

# Paso 5: Deploy en Cloud Run
Write-Host "[5/5] Desplegando en Cloud Run..." -ForegroundColor Yellow
gcloud run deploy dyslexia-backend `
  --image "docker.io/$ImageName" `
  --platform managed `
  --region $Region `
  --port 8080 `
  --memory 2Gi `
  --cpu 1 `
  --timeout 3600 `
  --allow-unauthenticated `
  --set-env-vars "FLASK_ENV=production"

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Cloud Run deployment falló" -ForegroundColor Red
    exit 1
}

Write-Host "✓ Deployment successful!" -ForegroundColor Green
Write-Host ""

# Obtener URL
Write-Host "Obteniendo URL del servicio..." -ForegroundColor Yellow
$ServiceUrl = gcloud run services describe dyslexia-backend `
  --platform managed `
  --region $Region `
  --format 'value(status.url)'

Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host "✅ DEPLOYMENT COMPLETADO" -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host ""
Write-Host "URL de tu Backend:" -ForegroundColor Yellow
Write-Host $ServiceUrl -ForegroundColor Green
Write-Host ""
Write-Host "Endpoints disponibles:" -ForegroundColor Yellow
Write-Host "  • Health:     $ServiceUrl/api/health"
Write-Host "  • Model Info: $ServiceUrl/api/model/info"
Write-Host "  • Predict:    $ServiceUrl/api/predict"
Write-Host ""
Write-Host "Próximos pasos:" -ForegroundColor Yellow
Write-Host "  1. Copia la URL anterior en tu Flutter APK"
Write-Host "  2. Actualiza CORS_ORIGINS en .env.production"
Write-Host "  3. Re-deploy si cambias variables de entorno"
Write-Host ""
