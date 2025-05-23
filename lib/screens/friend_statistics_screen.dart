import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

/// Pantalla para mostrar las estadísticas de un amigo
class FriendStatisticsScreen extends StatefulWidget {
  final String friendId;
  final String friendName;
  
  const FriendStatisticsScreen({
    Key? key,
    required this.friendId,
    required this.friendName,
  }) : super(key: key);

  @override
  State<FriendStatisticsScreen> createState() => _FriendStatisticsScreenState();
}

class _FriendStatisticsScreenState extends State<FriendStatisticsScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  bool _isLoading = true;
  String? _error;
  
  // Datos de estadísticas
  List<Map<String, dynamic>> _statistics = [];
  List<Map<String, dynamic>> _filteredStatistics = [];
  
  // Filtros de fecha
  DateTime? _startDate;
  DateTime? _endDate;
  
  // Estadísticas agregadas
  int _totalMatches = 0;
  int _totalGoals = 0;
  int _totalAssists = 0;
  int _totalOwnGoals = 0;
  double _goalAverage = 0;
  double _assistAverage = 0;
  double _ownGoalAverage = 0;
  double _goalAssistRatio = 0;
  
  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }
  
  /// Carga las estadísticas del jugador desde Supabase
  Future<void> _loadStatistics() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      
      // Obtener las estadísticas del amigo
      final result = await _supabase.rpc(
        'get_player_match_stats',
        params: {'player_id': widget.friendId}
      );
      
      if (result == null) {
        setState(() {
          _isLoading = false;
          _statistics = [];
          _filteredStatistics = [];
          _calculateAggregatedStats();
        });
        return;
      }
      
      // Convertir el resultado a una lista de mapas
      final List<Map<String, dynamic>> stats = List<Map<String, dynamic>>.from(result);
      
      setState(() {
        _isLoading = false;
        _statistics = stats;
        _filteredStatistics = stats;
        _calculateAggregatedStats();
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Error al cargar estadísticas: $e';
      });
    }
  }
  
  /// Aplica filtros de fecha a las estadísticas
  void _applyDateFilter() {
    if (_startDate == null && _endDate == null) {
      setState(() {
        _filteredStatistics = _statistics;
        _calculateAggregatedStats();
      });
      return;
    }
    
    final filtered = _statistics.where((stat) {
      final matchDate = DateTime.parse(stat['fecha'] ?? '');
      
      bool matchesFilter = true;
      
      // Aplicar filtro de fecha de inicio
      if (_startDate != null) {
        final startDateOnly = DateTime(_startDate!.year, _startDate!.month, _startDate!.day);
        final matchDateOnly = DateTime(matchDate.year, matchDate.month, matchDate.day);
        matchesFilter = matchesFilter && matchDateOnly.isAtSameMomentAs(startDateOnly) || matchDateOnly.isAfter(startDateOnly);
      }
      
      // Aplicar filtro de fecha de fin
      if (_endDate != null) {
        final endDateOnly = DateTime(_endDate!.year, _endDate!.month, _endDate!.day);
        final matchDateOnly = DateTime(matchDate.year, matchDate.month, matchDate.day);
        matchesFilter = matchesFilter && matchDateOnly.isAtSameMomentAs(endDateOnly) || matchDateOnly.isBefore(endDateOnly);
      }
      
      return matchesFilter;
    }).toList();
    
    setState(() {
      _filteredStatistics = filtered;
      _calculateAggregatedStats();
    });
  }
  
  /// Calcula estadísticas agregadas basadas en las estadísticas filtradas
  void _calculateAggregatedStats() {
    if (_filteredStatistics.isEmpty) {
      setState(() {
        _totalMatches = 0;
        _totalGoals = 0;
        _totalAssists = 0;
        _totalOwnGoals = 0;
        _goalAverage = 0;
        _assistAverage = 0;
        _ownGoalAverage = 0;
        _goalAssistRatio = 0;
      });
      return;
    }
    
    // Calcular totales
    final totalMatches = _filteredStatistics.length;
    
    // Sumar goles, asistencias y goles en propia
    int totalGoals = 0;
    int totalAssists = 0;
    int totalOwnGoals = 0;
    
    for (final stat in _filteredStatistics) {
      totalGoals += (stat['goles'] as int?) ?? 0;
      totalAssists += (stat['asistencias'] as int?) ?? 0;
      totalOwnGoals += (stat['goles_propia'] as int?) ?? 0;
    }
    
    // Calcular promedios
    final goalAverage = totalMatches > 0 ? totalGoals / totalMatches : 0.0;
    final assistAverage = totalMatches > 0 ? totalAssists / totalMatches : 0.0;
    final ownGoalAverage = totalMatches > 0 ? totalOwnGoals / totalMatches : 0.0;
    final goalAssistRatio = totalMatches > 0 ? (totalGoals + totalAssists) / totalMatches : 0.0;
    
    setState(() {
      _totalMatches = totalMatches;
      _totalGoals = totalGoals;
      _totalAssists = totalAssists;
      _totalOwnGoals = totalOwnGoals;
      _goalAverage = goalAverage;
      _assistAverage = assistAverage;
      _ownGoalAverage = ownGoalAverage;
      _goalAssistRatio = goalAssistRatio;
    });
  }
  
  /// Muestra el selector de fecha
  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? (_startDate ?? DateTime.now()) : (_endDate ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime(2025),
      locale: const Locale('es', 'ES'),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue.shade800,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.blue.shade800,
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          
          // Si la fecha de inicio es posterior a la fecha de fin, ajustar la fecha de fin
          if (_endDate != null && _startDate!.isAfter(_endDate!)) {
            _endDate = _startDate;
          }
        } else {
          _endDate = picked;
          
          // Si la fecha de fin es anterior a la fecha de inicio, ajustar la fecha de inicio
          if (_startDate != null && _endDate!.isBefore(_startDate!)) {
            _startDate = _endDate;
          }
        }
        
        _applyDateFilter();
      });
    }
  }
  
  /// Construye una tarjeta de estadística
  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: Colors.white.withOpacity(0.15),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: color,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Construye el gráfico de estadísticas
  Widget _buildStatsChart() {
    // Si no hay estadísticas, mostrar mensaje
    if (_filteredStatistics.isEmpty) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        child: const Text(
          'No hay datos disponibles para mostrar',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 16,
          ),
        ),
      );
    }
    
    // Ordenar las estadísticas por fecha
    final sortedStats = List<Map<String, dynamic>>.from(_filteredStatistics)
      ..sort((a, b) => DateTime.parse(a['fecha']).compareTo(DateTime.parse(b['fecha'])));
    
    // Crear puntos para el gráfico
    final List<FlSpot> goalSpots = [];
    final List<FlSpot> assistSpots = [];
    final List<FlSpot> ownGoalSpots = [];
    final List<String> xLabels = [];
    
    for (int i = 0; i < sortedStats.length; i++) {
      final stat = sortedStats[i];
      final goals = (stat['goles'] as int?) ?? 0;
      final assists = (stat['asistencias'] as int?) ?? 0;
      final ownGoals = (stat['goles_propia'] as int?) ?? 0;
      
      goalSpots.add(FlSpot(i.toDouble(), goals.toDouble()));
      assistSpots.add(FlSpot(i.toDouble(), assists.toDouble()));
      ownGoalSpots.add(FlSpot(i.toDouble(), ownGoals.toDouble()));
      
      // Formato corto de fecha para las etiquetas
      final date = DateTime.parse(stat['fecha']);
      xLabels.add(DateFormat('dd/MM').format(date));
    }
    
    return Container(
      height: 250,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
            horizontalInterval: 1,
            verticalInterval: 1,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.white24,
                strokeWidth: 1,
              );
            },
            getDrawingVerticalLine: (value) {
              return FlLine(
                color: Colors.white24,
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= 0 && value.toInt() < xLabels.length) {
                    return SideTitleWidget(
                      axisSide: meta.axisSide,
                      child: Text(
                        xLabels[value.toInt()],
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                        ),
                      ),
                    );
                  }
                  return const SizedBox();
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value == value.toInt() && value >= 0) {
                    return SideTitleWidget(
                      axisSide: meta.axisSide,
                      child: Text(
                        value.toInt().toString(),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                        ),
                      ),
                    );
                  }
                  return const SizedBox();
                },
                reservedSize: 40,
              ),
            ),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: Colors.white38),
          ),
          minX: 0,
          maxX: (sortedStats.length - 1).toDouble(),
          minY: 0,
          maxY: _filteredStatistics.fold<double>(0, (previousValue, element) {
            final goals = (element['goles'] as int?) ?? 0;
            final assists = (element['asistencias'] as int?) ?? 0;
            final ownGoals = (element['goles_propia'] as int?) ?? 0;
            return [previousValue, goals.toDouble(), assists.toDouble(), ownGoals.toDouble()].reduce((a, b) => a > b ? a : b) + 1;
          }),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              tooltipBgColor: Colors.blueGrey.shade700.withOpacity(0.8),
              getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                return touchedBarSpots.map((barSpot) {
                  final index = barSpot.x.toInt();
                  if (index >= 0 && index < sortedStats.length) {
                    final stat = sortedStats[index];
                    final date = DateTime.parse(stat['fecha']);
                    final formattedDate = DateFormat('dd/MM/yyyy').format(date);
                    
                    String title;
                    if (barSpot.barIndex == 0) {
                      title = 'Goles: ${barSpot.y.toInt()}';
                    } else if (barSpot.barIndex == 1) {
                      title = 'Asistencias: ${barSpot.y.toInt()}';
                    } else {
                      title = 'Goles en propia: ${barSpot.y.toInt()}';
                    }
                    
                    return LineTooltipItem(
                      '$formattedDate\n$title',
                      TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  }
                  return null;
                }).toList();
              },
            ),
          ),
          lineBarsData: [
            // Línea de goles
            LineChartBarData(
              spots: goalSpots,
              isCurved: true,
              color: Colors.orange,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.orange.withOpacity(0.2),
              ),
            ),
            // Línea de asistencias
            LineChartBarData(
              spots: assistSpots,
              isCurved: true,
              color: Colors.blue,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.blue.withOpacity(0.2),
              ),
            ),
            // Línea de goles en propia
            LineChartBarData(
              spots: ownGoalSpots,
              isCurved: true,
              color: Colors.red,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.red.withOpacity(0.2),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Construye la leyenda del gráfico
  Widget _buildChartLegend() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildLegendItem(Colors.orange, 'Goles'),
          const SizedBox(width: 20),
          _buildLegendItem(Colors.blue, 'Asistencias'),
          const SizedBox(width: 20),
          _buildLegendItem(Colors.red, 'Goles en propia'),
        ],
      ),
    );
  }
  
  /// Construye un elemento de la leyenda
  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
  
  /// Construye el filtro de fechas
  Widget _buildDateFilter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filtrar por fecha',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _selectDate(context, true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          color: Colors.white70,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _startDate != null
                                ? DateFormat('dd/MM/yyyy').format(_startDate!)
                                : 'Fecha inicial',
                            style: TextStyle(
                              color: _startDate != null ? Colors.white : Colors.white70,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: () => _selectDate(context, false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          color: Colors.white70,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _endDate != null
                                ? DateFormat('dd/MM/yyyy').format(_endDate!)
                                : 'Fecha final',
                            style: TextStyle(
                              color: _endDate != null ? Colors.white : Colors.white70,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  setState(() {
                    _startDate = null;
                    _endDate = null;
                    _applyDateFilter();
                  });
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white70,
                ),
                child: const Text('Limpiar'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _applyDateFilter,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade600,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Aplicar'),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Estadísticas de ${widget.friendName}'),
        centerTitle: true,
        backgroundColor: Colors.blue.shade800,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.blue.shade900,
              Colors.blue.shade800,
              Colors.blue.shade700,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
                          const SizedBox(height: 16),
                          Text(
                            _error!,
                            style: const TextStyle(color: Colors.white),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: _loadStatistics,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange.shade600,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Reintentar'),
                          ),
                        ],
                      ),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadStatistics,
                    color: Colors.orange.shade600,
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        // Filtro de fechas
                        _buildDateFilter(),
                        const SizedBox(height: 20),
                        
                        // Gráfico de estadísticas (movido arriba)
                        const Padding(
                          padding: EdgeInsets.only(left: 16, bottom: 8),
                          child: Text(
                            'Evolución de estadísticas',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        _buildStatsChart(),
                        _buildChartLegend(),
                        
                        const SizedBox(height: 20),
                        
                        // Tarjetas de estadísticas
                        GridView.count(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            _buildStatCard(
                              'Partidos',
                              _totalMatches.toString(),
                              Icons.sports_soccer,
                              Colors.white,
                            ),
                            _buildStatCard(
                              'Goles',
                              _totalGoals.toString(),
                              Icons.sports_score,
                              Colors.orange,
                            ),
                            _buildStatCard(
                              'Asistencias',
                              _totalAssists.toString(),
                              Icons.assistant,
                              Colors.blue,
                            ),
                            _buildStatCard(
                              'Goles en propia',
                              _totalOwnGoals.toString(),
                              Icons.sports_soccer_outlined,
                              Colors.red,
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Tarjetas de promedios
                        GridView.count(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            _buildStatCard(
                              'Goles por partido',
                              _goalAverage.toStringAsFixed(2),
                              Icons.trending_up,
                              Colors.orange,
                            ),
                            _buildStatCard(
                              'Asistencias por partido',
                              _assistAverage.toStringAsFixed(2),
                              Icons.trending_up,
                              Colors.blue,
                            ),
                            _buildStatCard(
                              'Goles en propia por partido',
                              _ownGoalAverage.toStringAsFixed(2),
                              Icons.trending_up,
                              Colors.red,
                            ),
                            _buildStatCard(
                              'Goles+Asist. por partido',
                              _goalAssistRatio.toStringAsFixed(2),
                              Icons.trending_up,
                              Colors.purple,
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
      ),
    );
  }
}
