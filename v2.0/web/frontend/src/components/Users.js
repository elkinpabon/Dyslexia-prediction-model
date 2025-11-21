import React, { useState, useEffect } from "react";
import { Box, Paper, Table, TableBody, TableCell, TableContainer, TableHead, TableRow, Typography, Chip, CircularProgress, IconButton, Dialog, DialogTitle, DialogContent, DialogActions, Button, Grid, Drawer, List, ListItem, ListItemText, Divider, useMediaQuery } from "@mui/material";
import { Visibility as VisibilityIcon, Menu as MenuIcon, Close as CloseIcon } from "@mui/icons-material";
import { apiService } from "../services/api";
import { useTheme } from "@mui/material/styles";

const Users = () => {
  const [rows, setRows] = useState([]);
  const [loading, setLoading] = useState(true);
  const [selectedRow, setSelectedRow] = useState(null);
  const [resultsData, setResultsData] = useState([]);
  const [dialogOpen, setDialogOpen] = useState(false);
  const [drawerOpen, setDrawerOpen] = useState(false);
  const theme = useTheme();
  const isMobile = useMediaQuery(theme.breakpoints.down("sm"));

  useEffect(() => { loadData(); }, []);

  const loadData = async () => {
    try {
      setLoading(true);
      const usersResponse = await apiService.getUsers();
      const users = usersResponse.data || [];
      const allRows = [];
      for (const user of users) {
        try {
          const childrenResponse = await apiService.getChildren();
          const allChildren = childrenResponse.data || [];
          const userChildren = allChildren.filter(child => child.user_id === user.id);
          if (userChildren.length > 0) {
            for (const child of userChildren) {
              allRows.push({ id: child.id, tutorId: user.id, tutorName: user.name, childId: child.id, childName: child.name, childAge: child.age, isChild: true });
            }
          } else {
            allRows.push({ id: user.id, tutorId: user.id, tutorName: user.name, childId: null, childName: "N/A", childAge: "N/A", isChild: false });
          }
        } catch (error) {
          console.error(`Error: ${error}`);
          allRows.push({ id: user.id, tutorId: user.id, tutorName: user.name, childId: null, childName: "N/A", childAge: "N/A", isChild: false });
        }
      }
      setRows(allRows);
    } catch (error) {
      console.error("Error:", error);
    } finally {
      setLoading(false);
    }
  };

  const handleViewUser = async (row) => {
    try {
      setSelectedRow(row);
      let response;
      if (row.isChild && row.childId) {
        response = await apiService.getAllResults();
        const allResults = response.data || [];
        const filteredResults = allResults.filter(result => result.child_id === row.childId);
        setResultsData(filteredResults);
      } else {
        response = await apiService.getResultsByUser(row.tutorId);
        setResultsData(response.data || []);
      }
      setDialogOpen(true);
    } catch (error) {
      console.error("Error:", error);
      setResultsData([]);
      setDialogOpen(true);
    }
  };

  const handleCloseDialog = () => {
    setDialogOpen(false);
    setSelectedRow(null);
    setResultsData([]);
  };

  const getRiskColor = (probability) => {
    if (probability < 30) return "success";
    if (probability < 70) return "warning";
    return "error";
  };

  if (loading) {
    return <Box display="flex" justifyContent="center" alignItems="center" minHeight="400px"><CircularProgress /></Box>;
  }

  return (
    <Box sx={{ p: { xs: 1, sm: 2, md: 3 }, minHeight: "100vh", backgroundColor: "#fafafa" }}>
      <Box sx={{ display: "flex", justifyContent: "space-between", alignItems: "center", mb: 3 }}>
        <Typography variant="h4" sx={{ mb: 0, fontSize: { xs: "1.5rem", sm: "2rem" }, fontWeight: "bold", color: "#1976d2" }}>
          Gestión de Usuarios
        </Typography>
        {isMobile && <IconButton color="primary" onClick={() => setDrawerOpen(true)} size="large"><MenuIcon /></IconButton>}
      </Box>

      <Drawer anchor="right" open={drawerOpen} onClose={() => setDrawerOpen(false)} PaperProps={{ sx: { width: "100%", maxWidth: 280 } }}>
        <Box sx={{ p: 2 }}>
          <Box sx={{ display: "flex", justifyContent: "space-between", alignItems: "center", mb: 2 }}>
            <Typography variant="h6" sx={{ fontWeight: "bold" }}>Menú</Typography>
            <IconButton onClick={() => setDrawerOpen(false)} size="small"><CloseIcon /></IconButton>
          </Box>
          <Divider sx={{ mb: 2 }} />
          <List sx={{ py: 0 }}>
            <ListItem><ListItemText primary="Total de Tutores" secondary={rows.filter(r => !r.isChild).length} /></ListItem>
            <ListItem><ListItemText primary="Total de Niños" secondary={rows.filter(r => r.isChild).length} /></ListItem>
            <ListItem><ListItemText primary="Total de Pruebas" secondary={resultsData.length} /></ListItem>
          </List>
        </Box>
      </Drawer>

      <TableContainer component={Paper} sx={{ overflowX: "auto", mb: 3 }}>
        <Table size="small" stickyHeader>
          <TableHead>
            <TableRow sx={{ backgroundColor: "#f5f5f5" }}>
              <TableCell sx={{ display: { xs: "none", sm: "table-cell" }, fontWeight: "bold", color: "#1976d2" }}>ID</TableCell>
              <TableCell sx={{ fontWeight: "bold", color: "#1976d2" }}>Tutor</TableCell>
              <TableCell sx={{ fontWeight: "bold", color: "#1976d2" }}>Niño</TableCell>
              <TableCell sx={{ display: { xs: "none", sm: "table-cell" }, fontWeight: "bold", color: "#1976d2" }}>Edad</TableCell>
              <TableCell align="center" sx={{ fontWeight: "bold", color: "#1976d2" }}>Ver</TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {rows.length === 0 ? (
              <TableRow><TableCell colSpan={5} align="center" sx={{ py: 4 }}><Typography color="textSecondary">No hay usuarios</Typography></TableCell></TableRow>
            ) : (
              rows.map((row) => (
                <TableRow key={`${row.tutorId}-${row.childId}`} hover sx={{ backgroundColor: row.isChild ? "#f9f9f9" : "white" }}>
                  <TableCell sx={{ display: { xs: "none", sm: "table-cell" }, fontSize: "0.875rem" }}>{row.childId || row.tutorId}</TableCell>
                  <TableCell sx={{ fontSize: "0.875rem" }}>{row.tutorName}</TableCell>
                  <TableCell sx={{ fontSize: "0.875rem", fontWeight: "bold", color: "#1976d2" }}>{row.childName}</TableCell>
                  <TableCell sx={{ display: { xs: "none", sm: "table-cell" }, fontSize: "0.875rem" }}>{row.childAge !== "N/A" ? `${row.childAge} años` : "N/A"}</TableCell>
                  <TableCell align="center"><IconButton color="primary" onClick={() => handleViewUser(row)} size="small"><VisibilityIcon /></IconButton></TableCell>
                </TableRow>
              ))
            )}
          </TableBody>
        </Table>
      </TableContainer>

      <Dialog open={dialogOpen} onClose={handleCloseDialog} maxWidth="sm" fullWidth>
        <DialogTitle sx={{ fontWeight: "bold", color: "#1976d2" }}>{selectedRow?.tutorName} {selectedRow?.isChild ? `/ ${selectedRow?.childName}` : ""}</DialogTitle>
        <DialogContent sx={{ p: 2 }}>
          <Grid container spacing={2} sx={{ mb: 3 }}>
            <Grid item xs={12} sm={6}><Typography variant="caption" sx={{ fontWeight: "bold" }}>ID TUTOR</Typography><Typography variant="body2">{selectedRow?.tutorId}</Typography></Grid>
            <Grid item xs={12} sm={6}><Typography variant="caption" sx={{ fontWeight: "bold" }}>TUTOR</Typography><Typography variant="body2">{selectedRow?.tutorName}</Typography></Grid>
            {selectedRow?.isChild && (<><Grid item xs={12} sm={6}><Typography variant="caption" sx={{ fontWeight: "bold" }}>ID NIÑO</Typography><Typography variant="body2">{selectedRow?.childId}</Typography></Grid><Grid item xs={12} sm={6}><Typography variant="caption" sx={{ fontWeight: "bold" }}>NIÑO</Typography><Typography variant="body2">{selectedRow?.childName}</Typography></Grid><Grid item xs={12} sm={6}><Typography variant="caption" sx={{ fontWeight: "bold" }}>EDAD</Typography><Typography variant="body2">{selectedRow?.childAge} años</Typography></Grid></>)}
          </Grid>
          <Divider sx={{ my: 2 }} />
          <Typography variant="h6" sx={{ fontWeight: "bold", color: "#1976d2", mb: 2 }}>Resultados ({resultsData.length})</Typography>
          {resultsData.length === 0 ? (<Typography color="textSecondary" sx={{ textAlign: "center", py: 3 }}>Sin resultados</Typography>) : (
            <TableContainer sx={{ overflowX: "auto" }}>
              <Table size="small">
                <TableHead><TableRow sx={{ backgroundColor: "#f5f5f5" }}><TableCell sx={{ fontWeight: "bold" }}>Actividad</TableCell><TableCell sx={{ fontWeight: "bold" }}>Fecha</TableCell><TableCell sx={{ fontWeight: "bold" }}>Res.</TableCell><TableCell sx={{ fontWeight: "bold" }}>%</TableCell><TableCell sx={{ fontWeight: "bold" }}>Riesgo</TableCell></TableRow></TableHead>
                <TableBody>{resultsData.map((r, i) => (<TableRow key={i} hover><TableCell sx={{ fontSize: "0.8rem" }}>{r.activityName?.substring(0, 12)}</TableCell><TableCell sx={{ fontSize: "0.8rem" }}>{new Date(r.timestamp).toLocaleDateString("es-ES", { month: "short", day: "numeric" })}</TableCell><TableCell><Chip label={r.result} size="small" color={r.result === "SÍ" ? "error" : "success"} variant="outlined" /></TableCell><TableCell sx={{ fontSize: "0.8rem" }}>{r.probability?.toFixed(0)}%</TableCell><TableCell><Chip label={r.riskLevel?.substring(0, 3)} size="small" color={getRiskColor(r.probability)} variant="outlined" /></TableCell></TableRow>))}</TableBody>
              </Table>
            </TableContainer>
          )}
        </DialogContent>
        <DialogActions><Button onClick={handleCloseDialog} size="small" variant="outlined">Cerrar</Button></DialogActions>
      </Dialog>
    </Box>
  );
};

export default Users;
