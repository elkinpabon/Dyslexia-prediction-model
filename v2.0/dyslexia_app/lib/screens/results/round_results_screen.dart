import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/round_data.dart';
import '../../services/api_service.dart';
import '../../services/audio/audio_service.dart';
import '../../services/db/database_service.dart';
import '../../constants/app_constants.dart';
import '../../models/activity_result.dart';
import '../../widgets/loading_overlay.dart';

/// Pantalla de resultados finales de las 10 rondas
class RoundResultsScreen extends StatefulWidget {
  final ActivityRoundResult result;
  final String userId;
  final String childId;

  const RoundResultsScreen({
    super.key,
    required this.result,
    required this.userId,
    required this.childId,
  });

  @override
  State<RoundResultsScreen> createState() => _RoundResultsScreenState();
}

class _RoundResultsScreenState extends State<RoundResultsScreen>
    with SingleTickerProviderStateMixin {
  bool _isEvaluating = false;
  ActivityResult? _mlResult;
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeIn));
    _animController.forward();
    _evaluateWithML();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _evaluateWithML() async {
    setState(() => _isEvaluating = true);

    try {
      final apiService = context.read<ApiService>();

      // TODO: Obtener datos del usuario (edad, género, etc.)
      // Por ahora usamos valores por defecto
      // Obtener información del niño desde la base de datos
      final dbService = DatabaseService();

      if (widget.result.childId == null) {
        throw Exception('El resultado no tiene un ID de niño asociado');
      }

      final child = await dbService.getChildById(widget.result.childId!);

      if (child == null) {
        throw Exception('No se encontró el perfil del niño');
      }

      // Obtener información del padre/tutor
      final tutor = await dbService.getUserById(child.tutorId);
      final tutorName = tutor?.name ?? 'Usuario Desconocido';

      // Preparar datos del niño para enviar al backend
      final userData = {
        'gender':
            'Male', // Puedes agregar género al perfil del niño si lo necesitas
        'age': child.age,
        'native_lang': true,
        'other_lang': false,
      };

      // Enviar datos al modelo ML usando IDs reales de la base de datos local
      final response = await apiService.evaluateAllActivities(
        userData: userData,
        completedActivities: [widget.result],
        userId: child.tutorId, // ID del padre/tutor
        childId: child.id, // ID del niño
        userName: tutorName, // Nombre del padre
        childName: child.name, // Nombre del niño
      );

      if (response != null && mounted) {
        // Crear resultado con datos de ML
        final mlResult = ActivityResult(
          activityId: widget.result.activityId,
          activityName: widget.result.activityName,
          timestamp: DateTime.now(),
          result: response['result'],
          probability: (response['probability'] as num)
              .toDouble(), // Backend ya envía en porcentaje (0-100)
          confidence: (response['confidence'] as num)
              .toDouble(), // Backend ya envía en porcentaje (0-100)
          details: {
            'risk_level': response['risk_level'],
            'activities_processed': response['details']['activities_processed'],
            'total_rounds': response['details']['total_rounds'],
            'features_extracted': response['details']['features_extracted'],
            'rounds': widget.result.rounds
                .map(
                  (round) => {
                    'roundNumber': round.roundNumber,
                    'clicks': round.clicks,
                    'hits': round.hits,
                    'misses': round.misses,
                    'score': round.score,
                    'accuracy': round.accuracy,
                    'missrate': round.missrate,
                  },
                )
                .toList(),
            'totalClicks': widget.result.totalClicks,
            'totalHits': widget.result.totalHits,
            'totalMisses': widget.result.totalMisses,
            'averageAccuracy': widget.result.averageAccuracy,
          },
          duration: widget.result.totalDuration,
        );

        setState(() => _mlResult = mlResult);

        // Guardar resultado CON evaluación ML
        try {
          final db = DatabaseService();
          final saved = await db.saveActivityResult(
            userId: widget.userId,
            childId: widget.childId,
            result: mlResult,
          );

          if (saved) {
            print(
              '✅ Resultado guardado exitosamente con ML - userId: ${widget.userId}, childId: ${widget.childId}',
            );
          } else {
            print('❌ Error: No se pudo guardar el resultado');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('⚠️ Error al guardar el resultado'),
                  backgroundColor: Colors.orange,
                ),
              );
            }
          }
        } catch (saveError) {
          print('❌ Error al guardar: $saveError');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error al guardar: $saveError'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }

        final probability = response['probability'];
        final riskLevel = response['risk_level'];

        // Mensaje más expresivo y claro según el resultado
        String message;
        if (mlResult.result == 'SÍ') {
          message =
              '¡Atención! El análisis indica que SÍ existe riesgo de dislexia. '
              'La probabilidad detectada es del $probability por ciento, con nivel de riesgo $riskLevel. '
              'Te recomendamos realizar una evaluación profesional más completa con un especialista. '
              'Recuerda que este es solo un análisis preliminar.';
        } else {
          message =
              '¡Buenas noticias! El análisis indica que NO se detecta riesgo de dislexia. '
              'La probabilidad de dislexia es muy baja, del $probability por ciento. '
              'No se encontraron indicadores significativos en tus patrones de respuesta. '
              'Continúa practicando con las actividades educativas si lo deseas.';
        }

        await context.read<AudioService>().speak(message);
      } else {
        // Backend no disponible - mostrar error
        print('❌ Backend no disponible - no se puede completar la evaluación');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                '❌ Error: El servidor de evaluación no está disponible. '
                'Por favor, asegúrate de que el backend esté ejecutándose.',
              ),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Error en evaluación ML: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isEvaluating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppConstants.primaryColor, Colors.white],
              ),
            ),
          ),
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          _buildSummaryCard(),
                          const SizedBox(height: 20),
                          _buildAccuracyChart(),
                          const SizedBox(height: 20),
                          _buildRoundsDetails(),
                          const SizedBox(height: 20),
                          if (_mlResult != null) _buildMLResultCard(),
                        ],
                      ),
                    ),
                  ),
                  _buildBottomButtons(),
                ],
              ),
            ),
          ),
          if (_isEvaluating)
            LoadingOverlay(
              isLoading: true,
              message: 'Evaluando con IA...',
              child: const SizedBox(),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.1)),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Column(
              children: [
                const Text(
                  '🏆 Resultados Finales',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '${widget.result.rounds.length} Tareas Completadas',
                  style: const TextStyle(fontSize: 14, color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    final result = widget.result;
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  'Tiempo Total',
                  _formatDuration(result.totalDuration),
                  Icons.timer,
                  Colors.blue,
                ),
                _buildStatItem(
                  'Total Clicks',
                  '${result.totalClicks}',
                  Icons.touch_app,
                  Colors.purple,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  'Aciertos',
                  '${result.totalHits}',
                  Icons.check_circle,
                  Colors.green,
                ),
                _buildStatItem(
                  'Fallos',
                  '${result.totalMisses}',
                  Icons.cancel,
                  Colors.red,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppConstants.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.analytics, size: 32, color: Colors.blue),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Precisión Promedio',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${(result.averageAccuracy * 100).toStringAsFixed(1)}%',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, size: 32, color: color),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildAccuracyChart() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Precisión por Ronda',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) => Text(
                          '${(value * 100).toInt()}%',
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) => Text(
                          'R${value.toInt() + 1}',
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: true),
                  minX: 0,
                  maxX: 9,
                  minY: 0,
                  maxY: 1,
                  lineBarsData: [
                    LineChartBarData(
                      spots: widget.result.rounds
                          .asMap()
                          .entries
                          .map(
                            (e) => FlSpot(e.key.toDouble(), e.value.accuracy),
                          )
                          .toList(),
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.blue.withOpacity(0.2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoundsDetails() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Detalle de Rondas',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...widget.result.rounds.map((round) => _buildRoundRow(round)),
          ],
        ),
      ),
    );
  }

  Widget _buildRoundRow(RoundData round) {
    final accuracyPercent = (round.accuracy * 100).toStringAsFixed(0);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppConstants.primaryColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${round.roundNumber}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Clicks: ${round.clicks}  |  Aciertos: ${round.hits}  |  Fallos: ${round.misses}',
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: round.accuracy,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    round.accuracy >= 0.7 ? Colors.green : Colors.orange,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '$accuracyPercent%',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: round.accuracy >= 0.7 ? Colors.green : Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMLResultCard() {
    final result = _mlResult!;
    final riskLevel = result.details['risk_level'] ?? 'Bajo';
    final color = result.result == 'SÍ' ? Colors.red : Colors.green;

    // Color según nivel de riesgo
    Color riskColor;
    IconData riskIcon;
    if (riskLevel == 'Alto') {
      riskColor = Colors.red;
      riskIcon = Icons.error;
    } else if (riskLevel == 'Medio') {
      riskColor = Colors.orange;
      riskIcon = Icons.warning;
    } else {
      riskColor = Colors.green;
      riskIcon = Icons.check_circle;
    }

    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.1), Colors.white],
          ),
        ),
        child: Column(
          children: [
            Icon(
              result.result == 'SÍ' ? Icons.warning_amber : Icons.check_circle,
              size: 64,
              color: color,
            ),
            const SizedBox(height: 16),
            Text(
              'Evaluación del Modelo IA',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                result.result,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              result.result == 'SÍ'
                  ? 'Se detectaron indicadores de dislexia'
                  : 'No se detectaron indicadores significativos',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            // Porcentaje de riesgo prominente
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: color, width: 3),
              ),
              child: Column(
                children: [
                  Text(
                    'PROBABILIDAD DE DISLEXIA',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: color,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${result.probability.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 56,
                      fontWeight: FontWeight.bold,
                      color: color,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: result.result == 'SÍ' ? Colors.red : Colors.green,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      result.result == 'SÍ' ? 'EN RIESGO' : 'SIN RIESGO',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Barra de riesgo visual
            _buildRiskBar(result.probability),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMLStat(
                  'Probabilidad',
                  '${result.probability.toStringAsFixed(1)}%',
                  Icons.analytics,
                ),
                _buildMLStat(
                  'Confianza',
                  '${result.confidence.toStringAsFixed(1)}%',
                  Icons.verified,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: riskColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: riskColor, width: 2),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(riskIcon, color: riskColor, size: 32),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Nivel de Riesgo',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      Text(
                        riskLevel.toUpperCase(),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: riskColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Modelo entrenado: RandomForest (89.48% accuracy)',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
            if (result.details['features_extracted'] != null)
              Text(
                'Features extraídas: ${result.details['features_extracted']}',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMLStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 28, color: Colors.blue),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildBottomButtons() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.home),
              label: const Text('Inicio'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[300],
                foregroundColor: Colors.black87,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                // Regresar al menú principal - usar popUntil para volver a home
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              icon: const Icon(Icons.home),
              label: const Text('Menú'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final mins = duration.inMinutes;
    final secs = duration.inSeconds % 60;
    return '${mins}m ${secs}s';
  }

  // Widget de barra de riesgo visual
  Widget _buildRiskBar(double probability) {
    // Calcular posición del indicador (0 = izquierda CON RIESGO, 100 = derecha SIN RIESGO)
    // Invertir para que 0% esté a la derecha (SIN RIESGO) y 100% a la izquierda (CON RIESGO)
    final indicatorPosition = 1.0 - probability;

    return Column(
      children: [
        Text(
          'INDICADOR DE RIESGO',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          height: 60,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Barra de gradiente (rojo a verde)
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFD84315), // Rojo oscuro (CON RIESGO)
                      Color(0xFFFF6F00), // Naranja
                      Color(0xFFFDD835), // Amarillo
                      Color(0xFF9CCC65), // Verde claro
                      Color(0xFF66BB6A), // Verde (SIN RIESGO)
                    ],
                    stops: [0.0, 0.25, 0.5, 0.75, 1.0],
                  ),
                ),
              ),
              // Línea divisoria central (punto de referencia 50%)
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Container(
                    width: 2,
                    color: Colors.black.withOpacity(0.3),
                  ),
                ),
              ),
              // Indicador de posición
              Positioned(
                left:
                    MediaQuery.of(context).size.width *
                    0.85 *
                    indicatorPosition,
                top: 0,
                bottom: 0,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.location_pin,
                      size: 36,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Etiquetas
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'CON RIESGO',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.red[800],
              ),
            ),
            Text(
              'SIN RIESGO',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.green[800],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
