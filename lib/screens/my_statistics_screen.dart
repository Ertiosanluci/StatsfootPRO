import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

/// Pantalla para mostrar las estadísticas personales del jugador
class MyStatisticsScreen extends StatefulWidget {
  const MyStatisticsScreen({Key? key}) : super(key: key);

  @override
  State<MyStatisticsScreen> createState() => _MyStatisticsScreenState();
}

class _MyStatisticsScreenState extends State<MyStatisticsScreen> {
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
      
      final userId = _supabase.auth.currentUser!.id;
      
      // Obtener las estadísticas del jugador
      final result = await _supabase.rpc(
        'get_player_match_stats',
        params: {'player_id': userId}
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
        // Comparar solo la fecha (sin la hora)
        final startDateOnly = DateTime(_startDate!.year, _startDate!.month, _startDate!.day);
        final matchDateOnly = DateTime(matchDate.year, matchDate.month, matchDate.day);
        matchesFilter = matchesFilter && matchDateOnly.isAtSameMomentAs(startDateOnly) || matchDateOnly.isAfter(startDateOnly);
      }
      
      // Aplicar filtro de fecha de fin
      if (_endDate != null) {
        // Comparar solo la fecha (sin la hora)
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
      });
      return;
    }
    
    // Conjunto para almacenar IDs de partidos únicos
    final Set<String> uniqueMatchIds = {};
    int totalGoals = 0;
    int totalAssists = 0;
    int totalOwnGoals = 0;
    
    for (final stat in _filteredStatistics) {
      if (stat['partido_id'] != null) {
        uniqueMatchIds.add(stat['partido_id'].toString());
      }
      
      totalGoals += (stat['goles'] ?? 0) as int;
      totalAssists += (stat['asistencias'] ?? 0) as int;
      totalOwnGoals += (stat['goles_propios'] ?? 0) as int;
    }
    
    final int totalMatches = uniqueMatchIds.length;
    
    setState(() {
      _totalMatches = totalMatches;
      _totalGoals = totalGoals;
      _totalAssists = totalAssists;
      _totalOwnGoals = totalOwnGoals;
      _goalAverage = totalMatches > 0 ? totalGoals / totalMatches : 0;
      _assistAverage = totalMatches > 0 ? totalAssists / totalMatches : 0;
    });
  }
  
  /// Muestra el selector de fecha
  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime initialDate = isStartDate 
        ? _startDate ?? DateTime.now().subtract(const Duration(days: 30))
        : _endDate ?? DateTime.now();
    
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.blue,
              onPrimary: Colors.white,
              onSurface: Colors.black,
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
          // Si la fecha de fin es anterior a la de inicio, actualizar la fecha de fin
          if (_endDate != null && _endDate!.isBefore(_startDate!)) {
            _endDate = _startDate;
          }
        } else {
          _endDate = picked;
          // Si la fecha de inicio es posterior a la de fin, actualizar la fecha de inicio
          if (_startDate != null && _startDate!.isAfter(_endDate!)) {
            _startDate = _endDate;
          }
        }
      });
      _applyDateFilter();
    }
  }
  
  /// Construye una tarjeta de estadística
  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: color,
            size: 30,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  /// Construye el gráfico de estadísticas
  Widget _buildStatsChart() {
    // Ordenar las estadísticas por fecha
    final sortedStats = List<Map<String, dynamic>>.from(_filteredStatistics);
    sortedStats.sort((a, b) {
      final dateA = DateTime.parse(a['fecha'] ?? '');
      final dateB = DateTime.parse(b['fecha'] ?? '');
      return dateA.compareTo(dateB);
    });
    
    // Crear puntos para el gráfico
    final List<FlSpot> goalSpots = [];
    final List<FlSpot> assistSpots = [];
    
    for (int i = 0; i < sortedStats.length; i++) {
      final stat = sortedStats[i];
      goalSpots.add(FlSpot(i.toDouble(), (stat['goles'] ?? 0).toDouble()));
      assistSpots.add(FlSpot(i.toDouble(), (stat['asistencias'] ?? 0).toDouble()));
    }
    
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      child: sortedStats.isEmpty
          ? const Center(
              child: Text(
                'No hay datos para mostrar',
                style: TextStyle(color: Colors.white70),
              ),
            )
          : LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  horizontalInterval: 1,
                  verticalInterval: 1,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.white10,
                      strokeWidth: 1,
                    );
                  },
                  getDrawingVerticalLine: (value) {
                    return FlLine(
                      color: Colors.white10,
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: sortedStats.length > 5 ? (sortedStats.length / 5).ceil().toDouble() : 1,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 && value.toInt() < sortedStats.length) {
                          final date = DateTime.parse(sortedStats[value.toInt()]['fecha'] ?? '');
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              DateFormat('dd/MM').format(date),
                              style: const TextStyle(
                                color: Colors.white60,
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
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 10,
                          ),
                        );
                      },
                      reservedSize: 30,
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: Colors.white10),
                ),
                minX: 0,
                maxX: (sortedStats.length - 1).toDouble(),
                minY: 0,
                maxY: 5, // Ajustar según los valores máximos
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
                ],
              ),
            ),
    );
  }
  
  /// Construye la leyenda del gráfico
  Widget _buildChartLegend() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildLegendItem(Colors.orange, 'Goles'),
          const SizedBox(width: 20),
          _buildLegendItem(Colors.blue, 'Asistencias'),
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
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
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
    final dateFormat = DateFormat('dd/MM/yyyy');
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filtrar por fechas',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _selectDate(context, true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, color: Colors.white, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _startDate != null ? dateFormat.format(_startDate!) : 'Fecha inicio',
                            style: TextStyle(
                              color: _startDate != null ? Colors.white : Colors.white60,
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => _selectDate(context, false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, color: Colors.white, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _endDate != null ? dateFormat.format(_endDate!) : 'Fecha fin',
                            style: TextStyle(
                              color: _endDate != null ? Colors.white : Colors.white60,
                              fontSize: 14,
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
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  setState(() {
                    _startDate = null;
                    _endDate = null;
                  });
                  _applyDateFilter();
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white70,
                ),
                child: const Text('Limpiar'),
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
        title: const Text(
          'Mis estadísticas',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.blue.shade800,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade700, Colors.blue.shade900],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.white,
                            size: 70,
                          ),
                          const SizedBox(height: 20),
                          Text(
                            _error!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: _loadStatistics,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.blue.shade800,
                              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: const Text('Reintentar'),
                          ),
                        ],
                      ),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadStatistics,
                    color: Colors.blue.shade800,
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        // Filtro de fechas
                        _buildDateFilter(),
                        const SizedBox(height: 20),
                        
                        // Tarjetas de estadísticas principales
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
                          ],
                        ),
                        const SizedBox(height: 20),
                        
                        // Título del gráfico
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
                        
                        // Gráfico de estadísticas
                        _buildStatsChart(),
                        
                        // Leyenda del gráfico
                        _buildChartLegend(),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
      ),
    );
  }
}
