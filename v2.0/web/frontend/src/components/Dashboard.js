import React, { useState, useEffect } from 'react';
import {
  Box,
  Card,
  CardContent,
  Grid,
  Typography,
  CircularProgress,
  Paper,
} from '@mui/material';
import {
  People as PeopleIcon,
  Assessment as AssessmentIcon,
  TrendingUp as TrendingUpIcon,
  Warning as WarningIcon,
} from '@mui/icons-material';
import { PieChart, Pie, Cell, ResponsiveContainer, Legend, Tooltip, BarChart, Bar, XAxis, YAxis, CartesianGrid } from 'recharts';
import { apiService } from '../services/api';

const COLORS = ['#4caf50', '#f44336', '#ff9800'];

const Dashboard = () => {
  const [loading, setLoading] = useState(true);
  const [stats, setStats] = useState({
    totalUsers: 0,
    totalTests: 0,
    positiveTests: 0,
    negativeTests: 0,
    averageRisk: 0,
  });
  const [results, setResults] = useState([]);

  useEffect(() => {
    loadDashboardData();
  }, []);

  const loadDashboardData = async () => {
    try {
      setLoading(true);
      const [resultsData, usersData] = await Promise.all([
        apiService.getAllResults(),
        apiService.getUsers(),
      ]);

      const allResults = resultsData.data || [];
      const allUsers = usersData.data || [];

      const positiveCount = allResults.filter(r => r.result === 'SÍ').length;
      const negativeCount = allResults.filter(r => r.result === 'NO').length;
      const avgRisk = allResults.length > 0
        ? allResults.reduce((acc, r) => acc + r.probability, 0) / allResults.length
        : 0;

      setStats({
        totalUsers: allUsers.length,
        totalTests: allResults.length,
        positiveTests: positiveCount,
        negativeTests: negativeCount,
        averageRisk: avgRisk,
      });

      setResults(allResults);
    } catch (error) {
      console.error('Error cargando datos del dashboard:', error);
    } finally {
      setLoading(false);
    }
  };

  const StatCard = ({ title, value, icon, color }) => (
    <Card sx={{ height: '100%' }}>
      <CardContent>
        <Box display="flex" alignItems="center" justifyContent="space-between">
          <Box>
            <Typography color="textSecondary" gutterBottom variant="overline">
              {title}
            </Typography>
            <Typography variant="h4" component="div">
              {value}
            </Typography>
          </Box>
          <Box
            sx={{
              backgroundColor: color,
              borderRadius: '50%',
              width: 56,
              height: 56,
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
            }}
          >
            {icon}
          </Box>
        </Box>
      </CardContent>
    </Card>
  );

  const pieData = [
    { name: 'Sin Riesgo', value: stats.negativeTests },
    { name: 'Con Riesgo', value: stats.positiveTests },
  ];

  const riskDistribution = [
    { name: 'Bajo (<30%)', value: results.filter(r => r.probability < 30).length },
    { name: 'Medio (30-70%)', value: results.filter(r => r.probability >= 30 && r.probability < 70).length },
    { name: 'Alto (>70%)', value: results.filter(r => r.probability >= 70).length },
  ];

  if (loading) {
    return (
      <Box display="flex" justifyContent="center" alignItems="center" minHeight="400px">
        <CircularProgress />
      </Box>
    );
  }

  return (
    <Box>
      <Typography variant="h4" gutterBottom sx={{ mb: 3 }}>
        Dashboard de Administración
      </Typography>

      <Grid container spacing={3} sx={{ mb: 3 }}>
        <Grid item xs={12} sm={6} md={3}>
          <StatCard
            title="Total Usuarios"
            value={stats.totalUsers}
            icon={<PeopleIcon sx={{ color: 'white', fontSize: 32 }} />}
            color="#2196f3"
          />
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <StatCard
            title="Total Pruebas"
            value={stats.totalTests}
            icon={<AssessmentIcon sx={{ color: 'white', fontSize: 32 }} />}
            color="#9c27b0"
          />
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <StatCard
            title="Con Riesgo"
            value={stats.positiveTests}
            icon={<WarningIcon sx={{ color: 'white', fontSize: 32 }} />}
            color="#f44336"
          />
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <StatCard
            title="Riesgo Promedio"
            value={`${stats.averageRisk.toFixed(1)}%`}
            icon={<TrendingUpIcon sx={{ color: 'white', fontSize: 32 }} />}
            color="#ff9800"
          />
        </Grid>
      </Grid>

      <Grid container spacing={3}>
        <Grid item xs={12} md={6}>
          <Paper sx={{ p: 3 }}>
            <Typography variant="h6" gutterBottom>
              Distribución de Resultados
            </Typography>
            <ResponsiveContainer width="100%" height={300}>
              <PieChart>
                <Pie
                  data={pieData}
                  cx="50%"
                  cy="50%"
                  labelLine={false}
                  label={({ name, percent }) => `${name}: ${(percent * 100).toFixed(0)}%`}
                  outerRadius={80}
                  fill="#8884d8"
                  dataKey="value"
                >
                  {pieData.map((entry, index) => (
                    <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                  ))}
                </Pie>
                <Tooltip />
                <Legend />
              </PieChart>
            </ResponsiveContainer>
          </Paper>
        </Grid>

        <Grid item xs={12} md={6}>
          <Paper sx={{ p: 3 }}>
            <Typography variant="h6" gutterBottom>
              Distribución de Riesgo
            </Typography>
            <ResponsiveContainer width="100%" height={300}>
              <BarChart data={riskDistribution}>
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis dataKey="name" />
                <YAxis />
                <Tooltip />
                <Bar dataKey="value" fill="#2196f3" />
              </BarChart>
            </ResponsiveContainer>
          </Paper>
        </Grid>
      </Grid>
    </Box>
  );
};

export default Dashboard;
