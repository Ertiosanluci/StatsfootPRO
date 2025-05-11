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

/// Modelo para estadísticas agregadas del jugador
class AggregatedStats {
  final int totalMatches;
  final int totalGoals;
  final int totalAssists;
  final int totalOwnGoals;
  final double goalAverage;
  final double assistAverage;
  final double ownGoalAverage;
  final double goalAssistAverage;

  AggregatedStats({
    required this.totalMatches,
    required this.totalGoals,
    required this.totalAssists,
    required this.totalOwnGoals,
    required this.goalAverage,
    required this.assistAverage,
    required this.ownGoalAverage,
    required this.goalAssistAverage,
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
  late AggregatedStats _aggregatedStats;
  
  @override
  void initState() {
    super.initState();
    // Inicializar con valores por defecto
    _aggregatedStats = AggregatedStats(
      totalMatches: 0,
      totalGoals: 0,
      totalAssists: 0,
      totalOwnGoals: 0,
      goalAverage: 0,
      assistAverage: 0,
      ownGoalAverage: 0,
      goalAssistAverage: 0,
    );
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
      int totalGoals = 0;
      int totalAssists = 0;
      int totalOwnGoals = 0;
      
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
        totalGoals += (data['goles'] ?? 0) as int;
        totalAssists += (data['asistencias'] ?? 0) as int;
        totalOwnGoals += (data['goles_propios'] ?? 0) as int;
      }
      
      final int totalMatches = uniqueMatchIds.length;
      final double goalAverage = totalMatches > 0 ? totalGoals / totalMatches : 0;
      final double assistAverage = totalMatches > 0 ? totalAssists / totalMatches : 0;
      final double ownGoalAverage = totalMatches > 0 ? totalOwnGoals / totalMatches : 0;
      final double goalAssistAverage = totalMatches > 0 ? (totalGoals + totalAssists) / totalMatches : 0;
      
      setState(() {
        _matchStatistics.addAll(stats);
        _aggregatedStats = AggregatedStats(
          totalMatches: totalMatches,
          totalGoals: totalGoals,
          totalAssists: totalAssists,
          totalOwnGoals: totalOwnGoals,
          goalAverage: goalAverage,
          assistAverage: assistAverage,
          ownGoalAverage: ownGoalAverage,
          goalAssistAverage: goalAssistAverage,
        );
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
                      
                      // Estadísticas básicas visibles en la pantalla principal
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[850],
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(20),
                              topRight: Radius.circular(20),
                            ),
                          ),
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Estadísticas Totales',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    // Botón para mostrar todas las estadísticas
                                    ElevatedButton(
                                      onPressed: () => _showFullStatistics(context),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue.shade700,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16.0, 
                                          vertical: 8.0,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: const [
                                          Text('Ver todo'),
                                          SizedBox(width: 4),
                                          Icon(Icons.keyboard_arrow_up_rounded, size: 18),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              // Grid de 2x2 para las estadísticas principales
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    children: [
                                      Expanded(
                                        child: Row(
                                          children: [
                                            _buildStatCard(
                                              'Partidos',
                                              _aggregatedStats.totalMatches.toString(),
                                              Icons.sports_soccer,
                                              const Color(0xFF3F51B5),
                                            ),
                                            const SizedBox(width: 12),
                                            _buildStatCard(
                                              'Goles',
                                              _aggregatedStats.totalGoals.toString(),
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
                                              _aggregatedStats.totalAssists.toString(),
                                              Icons.trending_up,
                                              const Color(0xFF4CAF50),
                                            ),
                                            const SizedBox(width: 12),
                                            _buildStatCard(
                                              'Goles en propia',
                                              _aggregatedStats.totalOwnGoals.toString(),
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
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
  
  /// Muestra el panel completo de estadísticas
  void _showFullStatistics(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.8,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (BuildContext context, ScrollController scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.grey[850],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  // Indicador de arrastre
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white38,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  
                  // Encabezado con título y botón cerrar
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Estadísticas Detalladas',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close_rounded, color: Colors.white70),
                          splashRadius: 24,
                        ),
                      ],
                    ),
                  ),
                  
                  // Lista desplazable de estadísticas
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(20),
                      physics: const BouncingScrollPhysics(),
                      children: [
                        // Sección: Totales
                        const Text(
                          'TOTALES',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white70,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        // Grid de estadísticas totales
                        GridView.count(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          crossAxisCount: 2,
                          childAspectRatio: 1.5,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          children: [
                            _buildDetailedStatCard(
                              'Partidos jugados',
                              _aggregatedStats.totalMatches.toString(),
                              Icons.sports_soccer,
                              const Color(0xFF3F51B5),
                            ),
                            _buildDetailedStatCard(
                              'Goles marcados',
                              _aggregatedStats.totalGoals.toString(),
                              Icons.star,
                              const Color(0xFF2196F3),
                            ),
                            _buildDetailedStatCard(
                              'Asistencias',
                              _aggregatedStats.totalAssists.toString(),
                              Icons.trending_up,
                              const Color(0xFF4CAF50),
                            ),
                            _buildDetailedStatCard(
                              'Goles en propia',
                              _aggregatedStats.totalOwnGoals.toString(),
                              Icons.error_outline,
                              const Color(0xFFF44336),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 30),
                        
                        // Sección: Promedios
                        const Text(
                          'PROMEDIOS POR PARTIDO',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white70,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        // Grid de estadísticas promedio
                        GridView.count(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          crossAxisCount: 2,
                          childAspectRatio: 1.5,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          children: [
                            _buildDetailedStatCard(
                              'Media de goles',
                              _aggregatedStats.goalAverage.toStringAsFixed(2),
                              Icons.bar_chart,
                              const Color(0xFF2196F3),
                            ),
                            _buildDetailedStatCard(
                              'Media de asistencias',
                              _aggregatedStats.assistAverage.toStringAsFixed(2),
                              Icons.show_chart,
                              const Color(0xFF4CAF50),
                            ),
                            _buildDetailedStatCard(
                              'Media de goles en propia',
                              _aggregatedStats.ownGoalAverage.toStringAsFixed(2),
                              Icons.pie_chart,
                              const Color(0xFFF44336),
                            ),
                            _buildDetailedStatCard(
                              'Media de contribuciones',
                              _aggregatedStats.goalAssistAverage.toStringAsFixed(2),
                              Icons.stacked_line_chart,
                              const Color(0xFF9C27B0),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 30),
                        
                        // Estadísticas adicionales o análisis
                        _buildRatioCard(
                          'Ratio de goles',
                          _getRatioDescription(_aggregatedStats.goalAverage),
                          _aggregatedStats.goalAverage,
                          _getRatioColor(_aggregatedStats.goalAverage),
                        ),
                        const SizedBox(height: 16),
                        _buildRatioCard(
                          'Ratio de contribución',
                          _getRatioDescription(_aggregatedStats.goalAssistAverage),
                          _aggregatedStats.goalAssistAverage,
                          _getRatioColor(_aggregatedStats.goalAssistAverage),
                        ),
                        
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
  
  /// Construye una tarjeta de estadística detallada para el panel completo
  Widget _buildDetailedStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Padding(
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
                fontSize: 24,
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
      ),
    );
  }
  
  /// Construye una tarjeta de ratio con barra de progreso
  Widget _buildRatioCard(String title, String description, double value, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(15),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _normalizeRatioValue(value),
              minHeight: 8,
              backgroundColor: Colors.white10,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '0.0',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[400],
                ),
              ),
              Text(
                value.toStringAsFixed(2),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                '3.0',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[400],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  /// Normaliza el valor del ratio para la barra de progreso (entre 0 y 1)
  double _normalizeRatioValue(double value) {
    // Consideramos 3.0 como valor máximo (escala de 0 a 3)
    return (value / 3.0).clamp(0.0, 1.0);
  }
  
  /// Devuelve la descripción del ratio según el valor
  String _getRatioDescription(double value) {
    if (value >= 2.5) {
      return 'Excelente rendimiento, contribución de élite';
    } else if (value >= 2.0) {
      return 'Muy buen rendimiento, contribución destacada';
    } else if (value >= 1.5) {
      return 'Buen rendimiento, por encima de la media';
    } else if (value >= 1.0) {
      return 'Rendimiento notable, buena contribución';
    } else if (value >= 0.5) {
      return 'Rendimiento promedio, contribuyente regular';
    } else {
      return 'Área de mejora, contribución moderada';
    }
  }
  
  /// Devuelve el color según el valor del ratio
  Color _getRatioColor(double value) {
    if (value >= 2.5) {
      return Colors.purple;
    } else if (value >= 2.0) {
      return Colors.indigo;
    } else if (value >= 1.5) {
      return Colors.blue;
    } else if (value >= 1.0) {
      return Colors.teal;
    } else if (value >= 0.5) {
      return Colors.amber;
    } else {
      return Colors.orange;
    }
  }
}
