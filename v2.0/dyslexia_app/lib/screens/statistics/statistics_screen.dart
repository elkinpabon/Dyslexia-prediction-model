import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../models/round_data.dart';

/// Pantalla de Estadísticas Profesional - Dashboard Completo
/// Gráficos: Pie Chart, Bar Chart, Line Chart
/// Historial completo de actividades con filtros

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<ActivityRoundResult> _allResults = [];
  bool _isLoading = true;

  // Filtros
  String _filterActivity = 'Todas';
  DateTimeRange? _dateRange;

  final List<String> _activityNames = [
    'Todas',
    'Precisión',
    'Secuencias',
    'Simetría',
    'Ritmo',
    'Velocidad',
    'Memoria',
    'Lenguaje',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadResults();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadResults() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((key) => key.startsWith('result_'));

    final results = <ActivityRoundResult>[];
    for (final key in keys) {
      final jsonStr = prefs.getString(key);
      if (jsonStr != null) {
        try {
          final json = jsonDecode(jsonStr);
          results.add(ActivityRoundResult.fromJson(json));
        } catch (e) {
          debugPrint('Error loading result: $e');
        }
      }
    }

    results.sort((a, b) => b.endTime.compareTo(a.endTime));

    setState(() {
      _allResults = results;
      _isLoading = false;
    });
  }

  List<ActivityRoundResult> get _filteredResults {
    var filtered = _allResults;

    // Filtro por actividad
    if (_filterActivity != 'Todas') {
      filtered = filtered
          .where((r) => r.activityName.contains(_filterActivity))
          .toList();
    }

    // Filtro por fecha
    if (_dateRange != null) {
      filtered = filtered
          .where(
            (r) =>
                r.endTime.isAfter(_dateRange!.start) &&
                r.endTime.isBefore(
                  _dateRange!.end.add(const Duration(days: 1)),
                ),
          )
          .toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Estadísticas',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.indigo.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadResults),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Dashboard'),
            Tab(icon: Icon(Icons.bar_chart), text: 'Gráficos'),
            Tab(icon: Icon(Icons.history), text: 'Historial'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildDashboard(),
                _buildChartsView(),
                _buildHistoryView(),
              ],
            ),
    );
  }

  // ============================================================
  // DASHBOARD - Vista General
  // ============================================================
  Widget _buildDashboard() {
    if (_allResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bar_chart_outlined,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No hay datos disponibles',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              'Completa actividades para ver estadísticas',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    final totalActivities = _allResults.length;
    final avgAccuracy =
        _allResults.fold<double>(0, (sum, r) => sum + r.averageAccuracy) /
        totalActivities;
    final totalTime = _allResults.fold<Duration>(
      Duration.zero,
      (sum, r) => sum + r.totalDuration,
    );

    // Conteo de predicciones ML (TODO: agregar mlResult a ActivityRoundResult)
    final mlYes =
        0; // _allResults.where((r) => r.mlResult?.result.toUpperCase() == 'SÍ').length;
    final mlNo =
        0; // _allResults.where((r) => r.mlResult?.result.toUpperCase() == 'NO').length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cards de resumen
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Actividades',
                  '$totalActivities',
                  Icons.assignment_turned_in,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  'Precisión',
                  '${(avgAccuracy * 100).toStringAsFixed(1)}%',
                  Icons.check_circle,
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Tiempo Total',
                  '${totalTime.inMinutes} min',
                  Icons.timer,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  'ML: SÍ/NO',
                  '$mlYes / $mlNo',
                  Icons.psychology,
                  Colors.purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Gráfico de distribución de actividades (Pie Chart)
          _buildSectionTitle('Distribución de Actividades'),
          const SizedBox(height: 16),
          Container(
            height: 250,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: _buildActivityPieChart(),
          ),
          const SizedBox(height: 24),

          // Últimas 5 actividades
          _buildSectionTitle('Últimas Actividades'),
          const SizedBox(height: 12),
          ..._allResults.take(5).map(_buildRecentActivityCard),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 28),
              const Spacer(),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivityCard(ActivityRoundResult result) {
    final date =
        '${result.endTime.day}/${result.endTime.month}/${result.endTime.year}';
    final time =
        '${result.endTime.hour.toString().padLeft(2, '0')}:${result.endTime.minute.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.indigo.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.assessment,
              color: Colors.indigo.shade700,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.activityName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  '$date • $time',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${(result.averageAccuracy * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
              ),
              Text(
                '${result.rounds.length} rondas',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // GRÁFICOS - Charts Detallados
  // ============================================================
  Widget _buildChartsView() {
    if (_allResults.isEmpty) {
      return const Center(child: Text('No hay datos para mostrar gráficos'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Precisión por Actividad'),
          const SizedBox(height: 16),
          Container(
            height: 300,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: _buildAccuracyBarChart(),
          ),
          const SizedBox(height: 24),

          _buildSectionTitle('Progreso en el Tiempo'),
          const SizedBox(height: 16),
          Container(
            height: 300,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: _buildProgressLineChart(),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityPieChart() {
    final activityCounts = <String, int>{};
    for (var result in _allResults) {
      final name = result.activityName.split(' ').first;
      activityCounts[name] = (activityCounts[name] ?? 0) + 1;
    }

    final colors = [
      Colors.blue,
      Colors.green,
      Colors.purple,
      Colors.orange,
      Colors.pink,
      Colors.teal,
      Colors.cyan,
    ];
    int colorIndex = 0;

    return PieChart(
      PieChartData(
        sectionsSpace: 2,
        centerSpaceRadius: 60,
        sections: activityCounts.entries.map((entry) {
          final color = colors[colorIndex++ % colors.length];
          return PieChartSectionData(
            value: entry.value.toDouble(),
            title: '${entry.key}\n${entry.value}',
            color: color,
            radius: 80,
            titleStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAccuracyBarChart() {
    final activityAccuracy = <String, List<double>>{};

    for (var result in _allResults) {
      final name = result.activityName.split(' ').first;
      activityAccuracy.putIfAbsent(name, () => []);
      activityAccuracy[name]!.add(result.averageAccuracy);
    }

    final avgByActivity = activityAccuracy.map(
      (key, values) =>
          MapEntry(key, values.reduce((a, b) => a + b) / values.length),
    );

    final sortedEntries = avgByActivity.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 1.0,
        barTouchData: BarTouchData(enabled: true),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= sortedEntries.length)
                  return const Text('');
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    sortedEntries[value.toInt()].key,
                    style: const TextStyle(fontSize: 11),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${(value * 100).toInt()}%',
                  style: const TextStyle(fontSize: 11),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: FlGridData(show: true, drawVerticalLine: false),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(sortedEntries.length, (index) {
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: sortedEntries[index].value,
                color: Colors.indigo.shade400,
                width: 24,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(6),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildProgressLineChart() {
    if (_allResults.length < 2) {
      return const Center(
        child: Text('Necesitas más actividades para ver el progreso'),
      );
    }

    final sortedResults = List<ActivityRoundResult>.from(_allResults)
      ..sort((a, b) => a.endTime.compareTo(b.endTime));

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: true, drawVerticalLine: false),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= sortedResults.length)
                  return const Text('');
                final date = sortedResults[value.toInt()].endTime;
                return Text(
                  '${date.day}/${date.month}',
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${(value * 100).toInt()}%',
                  style: const TextStyle(fontSize: 11),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        minY: 0,
        maxY: 1,
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(
              sortedResults.length,
              (index) => FlSpot(
                index.toDouble(),
                sortedResults[index].averageAccuracy,
              ),
            ),
            isCurved: true,
            color: Colors.indigo.shade400,
            barWidth: 3,
            dotData: FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.indigo.shade100.withOpacity(0.3),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // HISTORIAL - Tabla Completa con Filtros
  // ============================================================
  Widget _buildHistoryView() {
    return Column(
      children: [
        _buildFilters(),
        Expanded(
          child: _filteredResults.isEmpty
              ? const Center(child: Text('No hay resultados con estos filtros'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _filteredResults.length,
                  itemBuilder: (context, index) {
                    return _buildHistoryCard(_filteredResults[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _filterActivity,
                  decoration: const InputDecoration(
                    labelText: 'Actividad',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  items: _activityNames
                      .map(
                        (name) =>
                            DropdownMenuItem(value: name, child: Text(name)),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setState(() => _filterActivity = value!),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _selectDateRange,
                icon: const Icon(Icons.date_range, size: 18),
                label: Text(_dateRange == null ? 'Fecha' : 'Filtrado'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
          if (_dateRange != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Chip(
                label: Text(
                  '${_dateRange!.start.day}/${_dateRange!.start.month} - ${_dateRange!.end.day}/${_dateRange!.end.month}',
                ),
                onDeleted: () => setState(() => _dateRange = null),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
    );
    if (picked != null) setState(() => _dateRange = picked);
  }

  Widget _buildHistoryCard(ActivityRoundResult result) {
    final date =
        '${result.endTime.day}/${result.endTime.month}/${result.endTime.year}';
    final time =
        '${result.endTime.hour.toString().padLeft(2, '0')}:${result.endTime.minute.toString().padLeft(2, '0')}';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: Colors.indigo.shade100,
          child: Icon(Icons.assignment, color: Colors.indigo.shade700),
        ),
        title: Text(
          result.activityName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('$date • $time'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${(result.averageAccuracy * 100).toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade700,
              ),
            ),
            Text(
              '${result.rounds.length} rondas',
              style: const TextStyle(fontSize: 11),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('Clicks totales', '${result.totalClicks}'),
                _buildDetailRow('Aciertos', '${result.totalHits}'),
                _buildDetailRow('Errores', '${result.totalMisses}'),
                _buildDetailRow(
                  'Duración',
                  '${result.totalDuration.inMinutes}:${(result.totalDuration.inSeconds % 60).toString().padLeft(2, '0')}',
                ),
                // TODO: Agregar mlResult cuando se integre con RoundResultsScreen
                // if (result.mlResult != null) ...[
                //   const Divider(height: 24),
                //   _buildDetailRow('ML Predicción', result.mlResult!.result),
                //   _buildDetailRow('Probabilidad', '${(result.mlResult!.probability * 100).toStringAsFixed(1)}%'),
                // ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade700)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }
}
