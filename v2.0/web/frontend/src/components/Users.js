import React, { useState, useEffect } from 'react';
import {
  Box,
  Paper,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Typography,
  Chip,
  CircularProgress,
  IconButton,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Button,
  Grid,
} from '@mui/material';
import { Visibility as VisibilityIcon } from '@mui/icons-material';
import { apiService } from '../services/api';

const Users = () => {
  const [users, setUsers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [selectedUser, setSelectedUser] = useState(null);
  const [userResults, setUserResults] = useState([]);
  const [dialogOpen, setDialogOpen] = useState(false);

  useEffect(() => {
    loadUsers();
  }, []);

  const loadUsers = async () => {
    try {
      setLoading(true);
      const response = await apiService.getUsers();
      setUsers(response.data || []);
    } catch (error) {
      console.error('Error cargando usuarios:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleViewUser = async (user) => {
    try {
      setSelectedUser(user);
      const response = await apiService.getResultsByUser(user.id);
      setUserResults(response.data || []);
      setDialogOpen(true);
    } catch (error) {
      console.error('Error cargando resultados del usuario:', error);
    }
  };

  const handleCloseDialog = () => {
    setDialogOpen(false);
    setSelectedUser(null);
    setUserResults([]);
  };

  const getRiskColor = (probability) => {
    if (probability < 30) return 'success';
    if (probability < 70) return 'warning';
    return 'error';
  };

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
        Gestión de Usuarios
      </Typography>

      <TableContainer component={Paper}>
        <Table>
          <TableHead>
            <TableRow sx={{ backgroundColor: '#f5f5f5' }}>
              <TableCell><strong>ID</strong></TableCell>
              <TableCell><strong>Nombre</strong></TableCell>
              <TableCell><strong>Edad</strong></TableCell>
              <TableCell><strong>Género</strong></TableCell>
              <TableCell><strong>Fecha Registro</strong></TableCell>
              <TableCell align="center"><strong>Acciones</strong></TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {users.map((user) => (
              <TableRow key={user.id} hover>
                <TableCell>{user.id}</TableCell>
                <TableCell>{user.name}</TableCell>
                <TableCell>{user.age} años</TableCell>
                <TableCell>
                  <Chip
                    label={user.gender === 'M' ? 'Masculino' : 'Femenino'}
                    size="small"
                    color={user.gender === 'M' ? 'primary' : 'secondary'}
                  />
                </TableCell>
                <TableCell>
                  {user.createdAt ? new Date(user.createdAt).toLocaleDateString('es-ES') : 'N/A'}
                </TableCell>
                <TableCell align="center">
                  <IconButton
                    color="primary"
                    onClick={() => handleViewUser(user)}
                    title="Ver detalles"
                  >
                    <VisibilityIcon />
                  </IconButton>
                </TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
      </TableContainer>

      {/* Dialog para ver detalles del usuario */}
      <Dialog open={dialogOpen} onClose={handleCloseDialog} maxWidth="md" fullWidth>
        <DialogTitle>
          Detalles del Usuario: {selectedUser?.name}
        </DialogTitle>
        <DialogContent>
          <Grid container spacing={2} sx={{ mb: 3 }}>
            <Grid item xs={6}>
              <Typography variant="body2" color="textSecondary">ID:</Typography>
              <Typography variant="body1">{selectedUser?.id}</Typography>
            </Grid>
            <Grid item xs={6}>
              <Typography variant="body2" color="textSecondary">Edad:</Typography>
              <Typography variant="body1">{selectedUser?.age} años</Typography>
            </Grid>
            <Grid item xs={6}>
              <Typography variant="body2" color="textSecondary">Género:</Typography>
              <Typography variant="body1">
                {selectedUser?.gender === 'M' ? 'Masculino' : 'Femenino'}
              </Typography>
            </Grid>
          </Grid>

          <Typography variant="h6" gutterBottom sx={{ mt: 2 }}>
            Resultados de Pruebas ({userResults.length})
          </Typography>

          {userResults.length === 0 ? (
            <Typography color="textSecondary" sx={{ textAlign: 'center', py: 3 }}>
              No hay pruebas registradas para este usuario
            </Typography>
          ) : (
            <TableContainer>
              <Table size="small">
                <TableHead>
                  <TableRow>
                    <TableCell>Actividad</TableCell>
                    <TableCell>Fecha</TableCell>
                    <TableCell>Resultado</TableCell>
                    <TableCell>Probabilidad</TableCell>
                    <TableCell>Nivel de Riesgo</TableCell>
                  </TableRow>
                </TableHead>
                <TableBody>
                  {userResults.map((result, index) => (
                    <TableRow key={index}>
                      <TableCell>{result.activityName}</TableCell>
                      <TableCell>
                        {new Date(result.timestamp).toLocaleDateString('es-ES')}
                      </TableCell>
                      <TableCell>
                        <Chip
                          label={result.result}
                          size="small"
                          color={result.result === 'SÍ' ? 'error' : 'success'}
                        />
                      </TableCell>
                      <TableCell>{result.probability.toFixed(1)}%</TableCell>
                      <TableCell>
                        <Chip
                          label={result.riskLevel}
                          size="small"
                          color={getRiskColor(result.probability)}
                        />
                      </TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            </TableContainer>
          )}
        </DialogContent>
        <DialogActions>
          <Button onClick={handleCloseDialog}>Cerrar</Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
};

export default Users;
