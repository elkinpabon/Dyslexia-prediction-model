# Sistema Web de Predicción de Dislexia

Sistema completo con backend Flask + MySQL y frontend React para predicción de dislexia.

## 📁 Estructura del Proyecto

```
web/
├── backend/               # API Flask con MySQL
│   ├── app/
│   │   ├── models/       # Modelos de base de datos
│   │   ├── routes/       # Endpoints API
│   │   ├── services/     # Lógica de negocio
│   │   └── utils/        # Utilidades
│   ├── requirements.txt  # Dependencias Python
│   ├── run.py           # Punto de entrada
│   ├── init_db.py       # Inicializar BD
│   └── generate_test_data.py  # Datos de prueba
│
└── frontend/             # Panel de administración React
    ├── public/
    ├── src/
    │   ├── components/   # Componentes React
    │   └── services/     # API service
    ├── package.json
    └── README.md
```

## 🚀 Inicio Rápido (Desarrollo Local)

### 1. Backend

```bash
cd backend

# Instalar dependencias
pip install -r requirements.txt

# Configurar .env (copiar de .env.example)
cp .env.example .env
# Editar .env con tus credenciales de MySQL

# Inicializar base de datos
python init_db.py

# (Opcional) Generar datos de prueba
python generate_test_data.py

# Iniciar servidor
python run.py
```

Backend corriendo en: `http://localhost:5000`

### 2. Frontend

```bash
cd frontend

# Instalar dependencias
npm install

# Configurar .env
cp .env.example .env
# REACT_APP_API_URL=http://localhost:5000

# Iniciar servidor de desarrollo
npm start
```

Frontend corriendo en: `http://localhost:3000`

## 🎯 Deploy en Railway

### Paso 1: Crear Proyecto en Railway

1. Ve a [railway.app](https://railway.app)
2. Inicia sesión con GitHub
3. Crea un nuevo proyecto
4. Conecta tu repositorio de GitHub

### Paso 2: Desplegar Backend

1. **Agregar Servicio MySQL:**
   - En tu proyecto de Railway, haz clic en "+ New"
   - Selecciona "Database" → "MySQL"
   - Railway creará automáticamente la base de datos y las variables de entorno

2. **Desplegar Backend:**
   - Agrega un nuevo servicio desde tu repositorio GitHub
   - Railway detectará automáticamente que es Python
   - Asegúrate de que el directorio raíz apunte a `/web/backend`

3. **Configurar Variables de Entorno (Opcional):**
   ```
   SECRET_KEY=tu-clave-secreta-aleatoria
   FLASK_ENV=production
   DEBUG=False
   CORS_ORIGINS=https://tu-frontend.railway.app
   ```

4. **Inicializar Base de Datos:**
   Una vez desplegado, conecta por SSH o usa Railway CLI:
   ```bash
   railway run python init_db.py
   ```

### Paso 3: Desplegar Frontend

1. **Agregar Servicio Frontend:**
   - En el mismo proyecto, agrega otro servicio desde GitHub
   - Apunta al directorio `/web/frontend`

2. **Configurar Variable de Entorno:**
   ```
   REACT_APP_API_URL=https://tu-backend.railway.app
   ```

3. **Configurar Build:**
   - Build Command: `npm run build`
   - Start Command: `npx serve -s build -l $PORT`
   
   **IMPORTANTE:** Agrega `serve` a package.json:
   ```bash
   cd frontend
   npm install --save serve
   ```

### Paso 4: Conectar Servicios

Railway automáticamente:
- ✅ Generará URLs HTTPS para backend y frontend
- ✅ Configurará variables de entorno de MySQL en el backend
- ✅ Manejará el networking entre servicios

## 📊 Base de Datos MySQL

### Tablas Principales

1. **users** - Usuarios del sistema
2. **children** - Niños asociados a usuarios
3. **test_results** - Resultados de evaluaciones
4. **activity_rounds** - Rondas individuales de actividades

Ver `backend/README.md` para detalles completos del esquema.

## 🔌 API Endpoints

### Principales Endpoints

```
GET  /api/health                    # Estado del servidor
GET  /api/model/info                # Info del modelo ML
GET  /api/users                     # Listar usuarios
POST /api/users                     # Crear usuario
GET  /api/results                   # Listar resultados
GET  /api/statistics                # Estadísticas generales
POST /api/activities/rounds/evaluate # Evaluar y predecir
```

Ver documentación completa en `backend/README.md`

## 🛠️ Tecnologías

### Backend
- Flask 3.0
- SQLAlchemy + PyMySQL
- Flask-CORS
- scikit-learn (ML)
- pandas, numpy

### Frontend
- React 18
- Material-UI
- React Router
- Recharts
- Axios

## 📝 Variables de Entorno

### Backend (.env)

```env
# Railway proporciona automáticamente:
# MYSQLHOST, MYSQLPORT, MYSQLDATABASE, MYSQLUSER, MYSQLPASSWORD

# Configurables:
SECRET_KEY=tu-clave-secreta
FLASK_ENV=production
DEBUG=False
CORS_ORIGINS=https://tu-frontend.railway.app
```

### Frontend (.env)

```env
REACT_APP_API_URL=https://tu-backend.railway.app
```

## 🔒 Seguridad

### Checklist para Producción:

- [ ] Cambiar `SECRET_KEY` a valor aleatorio
- [ ] Establecer `DEBUG=False` en backend
- [ ] Configurar CORS solo para dominios específicos
- [ ] Usar HTTPS (Railway lo proporciona automáticamente)
- [ ] Revisar permisos de base de datos
- [ ] Implementar rate limiting
- [ ] Agregar autenticación para endpoints de admin

## 🧪 Testing

### Backend
```bash
cd backend
python -m pytest
```

### Frontend
```bash
cd frontend
npm test
```

## 📚 Documentación Adicional

- [Backend README](./backend/README.md) - Detalles del API
- [Frontend README](./frontend/README.md) - Detalles del panel
- [Railway Docs](https://docs.railway.app/) - Deploy y configuración

## 🐛 Troubleshooting

### Backend no conecta con MySQL

1. Verifica que el servicio MySQL esté activo en Railway
2. Comprueba que las variables de entorno estén configuradas
3. Revisa los logs del backend en Railway

### Frontend no puede conectar con Backend

1. Verifica que `REACT_APP_API_URL` esté correctamente configurada
2. Asegúrate de que CORS esté habilitado en el backend
3. Comprueba que ambos servicios estén corriendo

### Error "Table doesn't exist"

Ejecuta el script de inicialización:
```bash
railway run python init_db.py
```

## 📈 Monitoreo

Railway proporciona:
- ✅ Logs en tiempo real
- ✅ Métricas de uso (CPU, RAM, Network)
- ✅ Health checks automáticos
- ✅ Alertas por email

## 🤝 Contribuir

1. Fork el repositorio
2. Crea una rama (`git checkout -b feature/nueva-funcionalidad`)
3. Commit tus cambios (`git commit -am 'Agregar nueva funcionalidad'`)
4. Push a la rama (`git push origin feature/nueva-funcionalidad`)
5. Crea un Pull Request

## 📧 Soporte

Para problemas o preguntas:
- Abre un issue en GitHub
- Contacta al equipo de desarrollo

## 📄 Licencia

Este proyecto es privado y confidencial.

---

**Nota:** Este README asume que estás usando Railway para el deploy. Si usas otro proveedor (AWS, Heroku, etc.), ajusta las instrucciones según corresponda.
