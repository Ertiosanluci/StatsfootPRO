import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

/// Modelo para almacenar las estadísticas de cada partido
class MatchStatistics {
  final int goals;
  final int assists;
  final int ownGoals;
  final DateTime date;
  final String matchId;

  MatchStatistics({
    required this.goals,
    required this.assists,
    required this.ownGoals,
    required this.date,
    required this.matchId,
  });
}

/// Pantalla para mostrar gráficos de estadísticas del jugador
class PlayerStatsGraphScreen extends StatefulWidget {
  const PlayerStatsGraphScreen({Key? key}) : super(key: key);

  @override
  State<PlayerStatsGraphScreen> createState() => _PlayerStatsGraphScreenState();
}

class _PlayerStatsGraphScreenState extends State<PlayerStatsGraphScreen> {
  bool _isLoading = true;
  final List<MatchStatistics> _matchStatistics = [];
  int _totalGoals = 0;
  int _totalAssists = 0;
  int _totalOwnGoals = 0;
  int _totalMatches = 0;
  
  @override
  void initState() {
    super.initState();
    _loadPlayerStatistics();
  }

  /// Carga las estadísticas del jugador desde Supabase
  Future<void> _loadPlayerStatistics() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final userId = Supabase.instance.client.auth.currentUser!.id;
      
      // Usar RPC para ejecutar SQL personalizado
      final List<dynamic> result = await Supabase.instance.client
          .rpc('get_player_match_stats', params: {
            'player_id': userId
          });
      
      // Si no hay resultados, mostrar un mensaje
      if (result.isEmpty) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Convertir a objetos MatchStatistics
      final List<MatchStatistics> stats = [];
      final Set<String> uniqueMatchIds = {};
      
      for (final dynamic row in result) {
        final Map<String, dynamic> data = row as Map<String, dynamic>;
        
        // Obtener la fecha desde la columna fecha del partido
        final DateTime date = data['fecha'] != null 
            ? DateTime.parse(data['fecha']) 
            : DateTime.now(); // Fecha por defecto en caso de nulo
        
        stats.add(
          MatchStatistics(
            goals: (data['goles'] ?? 0) as int,
            assists: (data['asistencias'] ?? 0) as int,
            ownGoals: (data['goles_propios'] ?? 0) as int,
            date: date,
            matchId: data['partido_id'].toString(),
          ),
        );
        
        // Registrar IDs de partidos únicos
        if (data['partido_id'] != null) {
          uniqueMatchIds.add(data['partido_id'].toString());
        }
        
        // Calcular totales
        _totalGoals += (data['goles'] ?? 0) as int;
        _totalAssists += (data['asistencias'] ?? 0) as int;
        _totalOwnGoals += (data['goles_propios'] ?? 0) as int;
      }
      
      _totalMatches = uniqueMatchIds.length;
      
      setState(() {
        _matchStatistics.addAll(stats);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar estadísticas: $e')),
      );
    }
  }

  /// Crea puntos para la línea de goles
  List<FlSpot> _createGoalSpots() {
    return List.generate(_matchStatistics.length, (index) {
      return FlSpot(index.toDouble(), _matchStatistics[index].goals.toDouble());
    });
  }

  /// Crea puntos para la línea de asistencias
  List<FlSpot> _createAssistSpots() {
    return List.generate(_matchStatistics.length, (index) {
      return FlSpot(index.toDouble(), _matchStatistics[index].assists.toDouble());
    });
  }

  /// Crea puntos para la línea de goles en propia
  List<FlSpot> _createOwnGoalSpots() {
    return List.generate(_matchStatistics.length, (index) {
      return FlSpot(index.toDouble(), _matchStatistics[index].ownGoals.toDouble());
    });
  }

  /// Construye un elemento de la leyenda para el gráfico
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
  
  /// Construye una tarjeta de estadística con título, valor e ícono
  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: color,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Estadísticas'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue, Colors.indigo],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _matchStatistics.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.sports_soccer,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No hay estadísticas disponibles',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Juega partidos para ver tus estadísticas aquí',
                        style: TextStyle(
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                )
              : Container(
                  color: Colors.grey[900],
                  child: Column(
                    children: [
                      // Gráfico de líneas (ocupa mitad de la pantalla)
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.5,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: SizedBox(
                              width: (_matchStatistics.length * 40).toDouble().clamp(
                                MediaQuery.of(context).size.width - 32, 
                                double.infinity
                              ),
                              child: LineChart(
                                LineChartData(
                                  gridData: FlGridData(
                                    show: true,
                                    drawVerticalLine: true,
                                    drawHorizontalLine: true,
                                    horizontalInterval: 1,
                                    getDrawingHorizontalLine: (value) {
                                      return FlLine(
                                        color: Colors.white24,
                                        strokeWidth: 1.0,
                                      );
                                    },
                                    getDrawingVerticalLine: (value) {
                                      return FlLine(
                                        color: Colors.white24,
                                        strokeWidth: 1.0,
                                      );
                                    },
                                  ),
                                  titlesData: FlTitlesData(
                                    show: true,
                                    rightTitles: const AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                    topTitles: const AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        getTitlesWidget: (value, meta) {
                                          final index = value.toInt();
                                          if (index < 0 || index >= _matchStatistics.length) {
                                            return const SizedBox.shrink();
                                          }
                                          
                                          final date = _matchStatistics[index].date;
                                          return Padding(
                                            padding: const EdgeInsets.only(top: 8.0),
                                            child: Transform.rotate(
                                              angle: -0.4,
                                              child: Text(
                                                DateFormat('dd/MM').format(date),
                                                style: const TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: 10,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                          );
                                        },
                                        reservedSize: 36,
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
                                              color: Colors.white70,
                                              fontSize: 12,
                                            ),
                                          );
                                        },
                                        reservedSize: 30,
                                      ),
                                    ),
                                  ),
                                  borderData: FlBorderData(
                                    show: true,
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.2),
                                    ),
                                  ),
                                  minY: 0.0,
                                  lineBarsData: [
                                    // Línea para goles (azul)
                                    LineChartBarData(
                                      spots: _createGoalSpots(),
                                      isCurved: true,
                                      color: Colors.blue,
                                      barWidth: 4,
                                      isStrokeCapRound: true,
                                      dotData: FlDotData(
                                        show: true,
                                        getDotPainter: (spot, percent, barData, index) {
                                          return FlDotCirclePainter(
                                            radius: 6,
                                            color: Colors.blue,
                                            strokeWidth: 2,
                                            strokeColor: Colors.white,
                                          );
                                        },
                                      ),
                                      belowBarData: BarAreaData(
                                        show: true,
                                        color: Colors.blue.withOpacity(0.1),
                                      ),
                                    ),
                                    // Línea para asistencias (verde)
                                    LineChartBarData(
                                      spots: _createAssistSpots(),
                                      isCurved: true,
                                      color: Colors.green,
                                      barWidth: 4,
                                      isStrokeCapRound: true,
                                      dotData: FlDotData(
                                        show: true,
                                        getDotPainter: (spot, percent, barData, index) {
                                          return FlDotCirclePainter(
                                            radius: 6,
                                            color: Colors.green,
                                            strokeWidth: 2,
                                            strokeColor: Colors.white,
                                          );
                                        },
                                      ),
                                      belowBarData: BarAreaData(
                                        show: true,
                                        color: Colors.green.withOpacity(0.1),
                                      ),
                                    ),
                                    // Línea para goles en propia (rojo)
                                    LineChartBarData(
                                      spots: _createOwnGoalSpots(),
                                      isCurved: true,
                                      color: Colors.red,
                                      barWidth: 4,
                                      isStrokeCapRound: true,
                                      dotData: FlDotData(
                                        show: true,
                                        getDotPainter: (spot, percent, barData, index) {
                                          return FlDotCirclePainter(
                                            radius: 6,
                                            color: Colors.red,
                                            strokeWidth: 2,
                                            strokeColor: Colors.white,
                                          );
                                        },
                                      ),
                                      belowBarData: BarAreaData(
                                        show: true,
                                        color: Colors.red.withOpacity(0.1),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      
                      // Leyenda del gráfico
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildLegendItem(Colors.blue, 'Goles'),
                            const SizedBox(width: 20),
                            _buildLegendItem(Colors.green, 'Asistencias'),
                            const SizedBox(width: 20),
                            _buildLegendItem(Colors.red, 'Goles en propia'),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Estadísticas totales
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[850],
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(20),
                              topRight: Radius.circular(20),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Estadísticas Totales',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                
                                // Tarjetas de estadísticas
                                Expanded(
                                  child: Row(
                                    children: [
                                      _buildStatCard(
                                        'Partidos',
                                        _totalMatches.toString(),
                                        Icons.sports_soccer,
                                        const Color(0xFF3F51B5),
                                      ),
                                      const SizedBox(width: 12),
                                      _buildStatCard(
                                        'Goles',
                                        _totalGoals.toString(),
                                        Icons.star,
                                        const Color(0xFF2196F3),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Expanded(
                                  child: Row(
                                    children: [
                                      _buildStatCard(
                                        'Asistencias',
                                        _totalAssists.toString(),
                                        Icons.trending_up,
                                        const Color(0xFF4CAF50),
                                      ),
                                      const SizedBox(width: 12),
                                      _buildStatCard(
                                        'Goles en propia',
                                        _totalOwnGoals.toString(),
                                        Icons.error_outline,
                                        const Color(0xFFF44336),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
