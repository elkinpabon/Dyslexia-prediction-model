#!/bin/bash

# ======================================================
#  SCRIPT AUTOMATIZADO PARA DEPLOY EN CLOUD RUN
#  Uso: ./deploy.sh username_dockerhub
# ======================================================

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Verificar argumentos
if [ -z "$1" ]; then
    echo -e "${RED}❌ Error: Usuario de Docker Hub no especificado${NC}"
    echo "Uso: ./deploy.sh username_dockerhub"
    echo "Ejemplo: ./deploy.sh elkinpabon"
    exit 1
fi

DOCKER_USERNAME=$1
IMAGE_NAME="$DOCKER_USERNAME/dyslexia-backend:latest"
PROJECT_ID="${2:-dyslexia-backend}"  # Usar segundo argumento o usar default
REGION="${3:-us-central1}"  # Usar tercer argumento o usar default

echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}  🚀 DEPLOYMENT A CLOUD RUN - BACKEND DYSLEXIA${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${GREEN}Configuración:${NC}"
echo "  Docker Image: $IMAGE_NAME"
echo "  GCP Project: $PROJECT_ID"
echo "  Region: $REGION"
echo ""

# Paso 1: Login Docker
echo -e "${YELLOW}[1/5]${NC} Verifying Docker login..."
docker ps > /dev/null 2>&1 || (
    echo -e "${YELLOW}Necesitas hacer login en Docker Hub${NC}"
    docker login
)
echo -e "${GREEN}✓ Docker authenticated${NC}"
echo ""

# Paso 2: Build imagen
echo -e "${YELLOW}[2/5]${NC} Building Docker image..."
docker build -t "$IMAGE_NAME" . || {
    echo -e "${RED}❌ Build failed${NC}"
    exit 1
}
echo -e "${GREEN}✓ Docker image built successfully${NC}"
echo ""

# Paso 3: Push a Docker Hub
echo -e "${YELLOW}[3/5]${NC} Pushing to Docker Hub..."
docker push "$IMAGE_NAME" || {
    echo -e "${RED}❌ Push to Docker Hub failed${NC}"
    exit 1
}
echo -e "${GREEN}✓ Image pushed to Docker Hub${NC}"
echo ""

# Paso 4: Login Google Cloud
echo -e "${YELLOW}[4/5]${NC} Authenticating with Google Cloud..."
gcloud auth login --quiet || true
gcloud config set project "$PROJECT_ID" || true
echo -e "${GREEN}✓ Google Cloud configured${NC}"
echo ""

# Paso 5: Deploy en Cloud Run
echo -e "${YELLOW}[5/5]${NC} Deploying to Cloud Run..."
gcloud run deploy dyslexia-backend \
  --image "docker.io/$IMAGE_NAME" \
  --platform managed \
  --region "$REGION" \
  --port 8080 \
  --memory 2Gi \
  --cpu 1 \
  --timeout 3600 \
  --allow-unauthenticated \
  --set-env-vars "FLASK_ENV=production" \
  --quiet

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Cloud Run deployment failed${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Deployment successful!${NC}"
echo ""

# Obtener URL
SERVICE_URL=$(gcloud run services describe dyslexia-backend \
  --platform managed \
  --region "$REGION" \
  --format 'value(status.url)')

echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ DEPLOYMENT COMPLETADO${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${YELLOW}URL de tu Backend:${NC}"
echo -e "${GREEN}$SERVICE_URL${NC}"
echo ""
echo -e "${YELLOW}Endpoints disponibles:${NC}"
echo "  • Health:     $SERVICE_URL/api/health"
echo "  • Model Info: $SERVICE_URL/api/model/info"
echo "  • Predict:    $SERVICE_URL/api/predict"
echo ""
echo -e "${YELLOW}Próximos pasos:${NC}"
echo "  1. Copia la URL anterior en tu Flutter APK"
echo "  2. Actualiza CORS_ORIGINS en .env.production"
echo "  3. Re-deploy si cambias variables de entorno"
echo ""
