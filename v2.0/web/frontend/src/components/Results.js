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
  TextField,
  MenuItem,
  Grid,
  IconButton,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Button,
} from '@mui/material';
import { Visibility as VisibilityIcon } from '@mui/icons-material';
import { apiService } from '../services/api';

const Results = () => {
  const [results, setResults] = useState([]);
  const [filteredResults, setFilteredResults] = useState([]);
  const [loading, setLoading] = useState(true);
  const [filterResult, setFilterResult] = useState('all');
  const [filterRisk, setFilterRisk] = useState('all');
  const [selectedResult, setSelectedResult] = useState(null);
  const [dialogOpen, setDialogOpen] = useState(false);

  useEffect(() => {
    loadResults();
  }, []);

  useEffect(() => {
    applyFilters();
  }, [results, filterResult, filterRisk]);

  const loadResults = async () => {
    try {
      setLoading(true);
      const response = await apiService.getAllResults();
      setResults(response.data || []);
    } catch (error) {
      console.error('Error cargando resultados:', error);
    } finally {
      setLoading(false);
    }
  };

  const applyFilters = () => {
    let filtered = [...results];

    if (filterResult !== 'all') {
      filtered = filtered.filter(r => r.result === filterResult);
    }

    if (filterRisk !== 'all') {
      filtered = filtered.filter(r => {
        if (filterRisk === 'low') return r.probability < 30;
        if (filterRisk === 'medium') return r.probability >= 30 && r.probability < 70;
        if (filterRisk === 'high') return r.probability >= 70;
        return true;
      });
    }

    setFilteredResults(filtered);
  };

  const getRiskColor = (probability) => {
    if (probability < 30) return 'success';
    if (probability < 70) return 'warning';
    return 'error';
  };

  const getRiskLabel = (probability) => {
    if (probability < 30) return 'Bajo';
    if (probability < 70) return 'Medio';
    return 'Alto';
  };

  const handleViewDetails = (result) => {
    setSelectedResult(result);
    setDialogOpen(true);
  };

  const handleCloseDialog = () => {
    setDialogOpen(false);
    setSelectedResult(null);
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
        Resultados de Pruebas de Cribado
      </Typography>

      {/* Filtros */}
      <Paper sx={{ p: 2, mb: 3 }}>
        <Grid container spacing={2}>
          <Grid item xs={12} sm={6} md={3}>
            <TextField
              select
              fullWidth
              label="Filtrar por Resultado"
              value={filterResult}
              onChange={(e) => setFilterResult(e.target.value)}
            >
              <MenuItem value="all">Todos</MenuItem>
              <MenuItem value="SÍ">Con Riesgo (SÍ)</MenuItem>
              <MenuItem value="NO">Sin Riesgo (NO)</MenuItem>
            </TextField>
          </Grid>
          <Grid item xs={12} sm={6} md={3}>
            <TextField
              select
              fullWidth
              label="Filtrar por Nivel de Riesgo"
              value={filterRisk}
              onChange={(e) => setFilterRisk(e.target.value)}
            >
              <MenuItem value="all">Todos</MenuItem>
              <MenuItem value="low">Bajo (&lt;30%)</MenuItem>
              <MenuItem value="medium">Medio (30-70%)</MenuItem>
              <MenuItem value="high">Alto (&gt;70%)</MenuItem>
            </TextField>
          </Grid>
          <Grid item xs={12} sm={6} md={3}>
            <Box display="flex" alignItems="center" height="100%">
              <Typography variant="body2" color="textSecondary">
                Total: {filteredResults.length} pruebas
              </Typography>
            </Box>
          </Grid>
        </Grid>
      </Paper>

      {/* Tabla de resultados */}
      <TableContainer component={Paper}>
        <Table>
          <TableHead>
            <TableRow sx={{ backgroundColor: '#f5f5f5' }}>
              <TableCell><strong>Usuario</strong></TableCell>
              <TableCell><strong>Actividad</strong></TableCell>
              <TableCell><strong>Fecha</strong></TableCell>
              <TableCell><strong>Resultado</strong></TableCell>
              <TableCell><strong>Probabilidad</strong></TableCell>
              <TableCell><strong>Nivel Riesgo</strong></TableCell>
              <TableCell><strong>Duración</strong></TableCell>
              <TableCell align="center"><strong>Acciones</strong></TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {filteredResults.map((result, index) => (
              <TableRow key={index} hover>
                <TableCell>{result.userName || result.userId}</TableCell>
                <TableCell>{result.activityName}</TableCell>
                <TableCell>
                  {new Date(result.timestamp).toLocaleDateString('es-ES', {
                    year: 'numeric',
                    month: 'short',
                    day: 'numeric',
                    hour: '2-digit',
                    minute: '2-digit'
                  })}
                </TableCell>
                <TableCell>
                  <Chip
                    label={result.result}
                    size="small"
                    color={result.result === 'SÍ' ? 'error' : 'success'}
                  />
                </TableCell>
                <TableCell>
                  <strong>{result.probability.toFixed(1)}%</strong>
                </TableCell>
                <TableCell>
                  <Chip
                    label={getRiskLabel(result.probability)}
                    size="small"
                    color={getRiskColor(result.probability)}
                  />
                </TableCell>
                <TableCell>
                  {result.durationSeconds ? `${Math.floor(result.durationSeconds / 60)}m` : 'N/A'}
                </TableCell>
                <TableCell align="center">
                  <IconButton
                    color="primary"
                    onClick={() => handleViewDetails(result)}
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

      {/* Dialog de detalles */}
      <Dialog open={dialogOpen} onClose={handleCloseDialog} maxWidth="md" fullWidth>
        <DialogTitle>
          Detalles de la Prueba
        </DialogTitle>
        <DialogContent>
          {selectedResult && (
            <Box>
              <Grid container spacing={2}>
                <Grid item xs={6}>
                  <Typography variant="body2" color="textSecondary">Usuario:</Typography>
                  <Typography variant="body1">{selectedResult.userName || selectedResult.userId}</Typography>
                </Grid>
                <Grid item xs={6}>
                  <Typography variant="body2" color="textSecondary">Actividad:</Typography>
                  <Typography variant="body1">{selectedResult.activityName}</Typography>
                </Grid>
                <Grid item xs={6}>
                  <Typography variant="body2" color="textSecondary">Fecha:</Typography>
                  <Typography variant="body1">
                    {new Date(selectedResult.timestamp).toLocaleString('es-ES')}
                  </Typography>
                </Grid>
                <Grid item xs={6}>
                  <Typography variant="body2" color="textSecondary">Resultado:</Typography>
                  <Chip
                    label={selectedResult.result}
                    color={selectedResult.result === 'SÍ' ? 'error' : 'success'}
                  />
                </Grid>
                <Grid item xs={6}>
                  <Typography variant="body2" color="textSecondary">Probabilidad:</Typography>
                  <Typography variant="h6">{selectedResult.probability.toFixed(1)}%</Typography>
                </Grid>
                <Grid item xs={6}>
                  <Typography variant="body2" color="textSecondary">Nivel de Riesgo:</Typography>
                  <Chip
                    label={getRiskLabel(selectedResult.probability)}
                    color={getRiskColor(selectedResult.probability)}
                  />
                </Grid>
                <Grid item xs={6}>
                  <Typography variant="body2" color="textSecondary">Confianza:</Typography>
                  <Typography variant="body1">{selectedResult.confidence?.toFixed(1)}%</Typography>
                </Grid>
                <Grid item xs={6}>
                  <Typography variant="body2" color="textSecondary">Duración:</Typography>
                  <Typography variant="body1">
                    {selectedResult.durationSeconds ? `${Math.floor(selectedResult.durationSeconds / 60)} minutos` : 'N/A'}
                  </Typography>
                </Grid>
              </Grid>

              {selectedResult.details && (
                <Box sx={{ mt: 3 }}>
                  <Typography variant="h6" gutterBottom>Detalles Adicionales:</Typography>
                  <Paper sx={{ p: 2, backgroundColor: '#f5f5f5' }}>
                    <pre style={{ margin: 0, whiteSpace: 'pre-wrap', wordWrap: 'break-word' }}>
                      {JSON.stringify(selectedResult.details, null, 2)}
                    </pre>
                  </Paper>
                </Box>
              )}
            </Box>
          )}
        </DialogContent>
        <DialogActions>
          <Button onClick={handleCloseDialog}>Cerrar</Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
};

export default Results;
