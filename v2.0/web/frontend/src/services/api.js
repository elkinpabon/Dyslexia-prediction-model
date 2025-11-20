import axios from 'axios';

const API_BASE_URL = process.env.REACT_APP_API_URL || 'http://localhost:5000';

const api = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Interceptor para manejar errores
api.interceptors.response.use(
  (response) => response,
  (error) => {
    console.error('API Error:', error);
    return Promise.reject(error);
  }
);

export const apiService = {
  // Obtener todos los usuarios
  getUsers: async () => {
    const response = await api.get('/api/users');
    return response.data;
  },

  // Obtener usuario por ID
  getUserById: async (userId) => {
    const response = await api.get(`/api/users/${userId}`);
    return response.data;
  },

  // Obtener todos los resultados
  getAllResults: async () => {
    const response = await api.get('/api/results');
    return response.data;
  },

  // Obtener resultados por usuario
  getResultsByUser: async (userId) => {
    const response = await api.get(`/api/results/user/${userId}`);
    return response.data;
  },

  // Obtener estadísticas generales
  getStatistics: async () => {
    const response = await api.get('/api/statistics');
    return response.data;
  },

  // Obtener información del modelo
  getModelInfo: async () => {
    const response = await api.get('/api/model/info');
    return response.data;
  },
};

export default api;
