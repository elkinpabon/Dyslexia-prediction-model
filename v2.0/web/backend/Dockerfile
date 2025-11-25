# Usar imagen oficial de Python con Alpine Linux (ligero)
FROM python:3.11-slim

# Establecer variables de entorno
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PORT=8080 \
    FLASK_ENV=production

# Establecer directorio de trabajo
WORKDIR /app

# Copiar archivos de requisitos
COPY requirements.txt .

# Instalar dependencias del sistema y Python
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libmariadb-dev \
    curl \
    && pip install --upgrade pip setuptools wheel \
    && pip install -r requirements.txt \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Copiar el resto de la aplicación
COPY . .

# Exponer el puerto 8080 (Cloud Run requiere 8080)
EXPOSE 8080

# Comando para ejecutar la aplicación
# Cloud Run ejecutará este comando
CMD ["python", "run.py"]
