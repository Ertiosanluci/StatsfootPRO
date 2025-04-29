import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:ui' as ui;
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:math' as math;

class MatchDetailsScreen extends StatefulWidget {
  final dynamic matchId;
  
  const MatchDetailsScreen({Key? key, required this.matchId}) : super(key: key);
  
  @override
  _MatchDetailsScreenState createState() => _MatchDetailsScreenState();
}

class _MatchDetailsScreenState extends State<MatchDetailsScreen> with SingleTickerProviderStateMixin {
  final SupabaseClient supabase = Supabase.instance.client;
  bool _isLoading = true;
  Map<String, dynamic> _matchData = {};
  List<Map<String, dynamic>> _teamClaro = [];
  List<Map<String, dynamic>> _teamOscuro = [];
  Map<String, Offset> _teamClaroPositions = {};
  Map<String, Offset> _teamOscuroPositions = {};
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchMatchDetails();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _fetchMatchDetails() async {
    try {
      setState(() => _isLoading = true);
      
      // Convertir matchId a int si es necesario
      int matchIdInt;
      if (widget.matchId is int) {
        matchIdInt = widget.matchId;
      } else {
        matchIdInt = int.parse(widget.matchId.toString());
      }
      
      // Obtener los datos del partido
      final response = await supabase
          .from('partidos')
          .select('*')
          .eq('id', matchIdInt)
          .single();
      
      _matchData = response;
      
      // Procesar las posiciones de los jugadores (convertir de JSON a Offset)
      if (_matchData['team_claro_positions'] != null) {
        Map<String, dynamic> positions = Map<String, dynamic>.from(_matchData['team_claro_positions']);
        positions.forEach((playerId, position) {
          if (position is Map) {
            double dx = (position['dx'] is num) ? (position['dx'] as num).toDouble() : 0.5;
            double dy = (position['dy'] is num) ? (position['dy'] as num).toDouble() : 0.3;
            _teamClaroPositions[playerId] = Offset(dx, dy);
          }
        });
      }
      
      if (_matchData['team_oscuro_positions'] != null) {
        Map<String, dynamic> positions = Map<String, dynamic>.from(_matchData['team_oscuro_positions']);
        positions.forEach((playerId, position) {
          if (position is Map) {
            double dx = (position['dx'] is num) ? (position['dx'] as num).toDouble() : 0.5;
            double dy = (position['dy'] is num) ? (position['dy'] as num).toDouble() : 0.7;
            _teamOscuroPositions[playerId] = Offset(dx, dy);
          }
        });
      }
      
      // Cargar información de los jugadores del equipo claro
      List<dynamic> teamClaroIds = _matchData['team_claro'] ?? [];
      await _fetchTeamPlayers(teamClaroIds, true);
      
      // Cargar información de los jugadores del equipo oscuro
      List<dynamic> teamOscuroIds = _matchData['team_oscuro'] ?? [];
      await _fetchTeamPlayers(teamOscuroIds, false);
      
      setState(() => _isLoading = false);
    } catch (e) {
      print('Error al cargar detalles del partido: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar los detalles: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      
      setState(() => _isLoading = false);
    }
  }
  
  Future<void> _fetchTeamPlayers(List<dynamic> playerIds, bool isTeamClaro) async {
    List<Map<String, dynamic>> players = [];
    
    for (var playerId in playerIds) {
      try {
        final playerResponse = await supabase
            .from('jugadores')
            .select('*')
            .eq('id', playerId)
            .single();
        
        // Obtener estadísticas del jugador en este partido
        final statsResponse = await supabase
            .from('estadisticas')
            .select('*')
            .eq('jugador_id', playerId)
            .eq('partido_id', widget.matchId)
            .maybeSingle();
        
        Map<String, dynamic> playerData = Map<String, dynamic>.from(playerResponse);
        
        // Añadir estadísticas si existen
        if (statsResponse != null) {
          playerData['goles'] = statsResponse['goles'] ?? 0;
          playerData['asistencias'] = statsResponse['asistencias'] ?? 0;
        } else {
          playerData['goles'] = 0;
          playerData['asistencias'] = 0;
        }
        
        players.add(playerData);
      } catch (e) {
        print('Error al cargar jugador $playerId: $e');
      }
    }
    
    setState(() {
      if (isTeamClaro) {
        _teamClaro = players;
      } else {
        _teamOscuro = players;
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    // Calcular el marcador actual
    final int golesEquipoClaro = _matchData['resultado_claro'] ?? 0;
    final int golesEquipoOscuro = _matchData['resultado_oscuro'] ?? 0;
    final bool isPartidoFinalizado = _matchData['estado'] == 'finalizado';

    return Scaffold(
      appBar: AppBar(
        title: Text(_isLoading ? 'Cargando detalles...' : _matchData['nombre'] ?? 'Detalles del Partido'),
        centerTitle: true,
        backgroundColor: Colors.blue.shade800,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        leading: BackButton(color: Colors.white), // Cambiando el color de la flecha a blanco
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Equipo Claro'),
            Tab(text: 'Equipo Oscuro'),
          ],
          indicatorColor: Colors.orange.shade600,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
        ),
        actions: [
          // Botón para finalizar partido con icono mejorado
          if (!isPartidoFinalizado && !_isLoading)
            IconButton(
              icon: Icon(
                Icons.flag_outlined, // Icono de bandera
                color: Colors.white, // Color blanco para mejor visibilidad
                size: 26, // Tamaño ligeramente mayor
              ),
              tooltip: 'Finalizar partido',
              onPressed: _showFinalizarPartidoDialog,
            ),
        ],
      ),
      body: _isLoading 
        ? Center(child: CircularProgressIndicator(color: Colors.blue))
        : Column(
            children: [
              // Marcador
              _buildMarcador(golesEquipoClaro, golesEquipoOscuro, isPartidoFinalizado),
              
              // Campo y jugadores
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade300, Colors.blue.shade800],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Vista del Equipo Claro
                      _buildFullScreenTeamFormation(true),
                      
                      // Vista del Equipo Oscuro
                      _buildFullScreenTeamFormation(false),
                    ],
                  ),
                ),
              ),
            ],
          ),
    );
  }
  
  // Widget para mostrar el marcador
  Widget _buildMarcador(int golesEquipoClaro, int golesEquipoOscuro, bool isPartidoFinalizado) {
    return Container(
      color: Colors.black87,
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Equipo Claro
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'EQUIPO CLARO',
                      style: TextStyle(
                        color: Colors.blue.shade300,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              
              // Marcador
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.grey.shade800,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$golesEquipoClaro',
                      style: TextStyle(
                        color: Colors.blue.shade300,
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        '-',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                        ),
                      ),
                    ),
                    Text(
                      '$golesEquipoOscuro',
                      style: TextStyle(
                        color: Colors.red.shade300,
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Equipo Oscuro
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'EQUIPO OSCURO',
                      style: TextStyle(
                        color: Colors.red.shade300,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          // Indicador de estado del partido
          if (isPartidoFinalizado)
            Container(
              margin: EdgeInsets.only(top: 4),
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green.shade800,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'PARTIDO FINALIZADO',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  // Mostrar diálogo para finalizar el partido
  void _showFinalizarPartidoDialog() {
    final int golesEquipoClaro = _matchData['resultado_claro'] ?? 0;
    final int golesEquipoOscuro = _matchData['resultado_oscuro'] ?? 0;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.flag_outlined, 
              color: Colors.white,
              size: 24,
            ),
            SizedBox(width: 8),
            Text(
              'Finalizar Partido',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        backgroundColor: Colors.blue.shade900,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withOpacity(0.2), width: 1),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '¿Estás seguro de que deseas finalizar el partido?',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'Marcador Final',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Column(
                        children: [
                          Text(
                            'Equipo Claro',
                            style: TextStyle(
                              color: Colors.blue.shade300,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(height: 4),
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.blue.shade700,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                '$golesEquipoClaro',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'vs',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Column(
                        children: [
                          Text(
                            'Equipo Oscuro',
                            style: TextStyle(
                              color: Colors.red.shade300,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(height: 4),
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.red.shade700,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                '$golesEquipoOscuro',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange.shade300,
                  size: 16,
                ),
                SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Esta acción no se puede deshacer.',
                    style: TextStyle(
                      color: Colors.orange.shade300,
                      fontStyle: FontStyle.italic,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            child: Text(
              'Cancelar',
              style: TextStyle(color: Colors.white70),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton.icon(
            icon: Icon(
              Icons.check_circle_outline,
              color: Colors.white,
              size: 18,
            ),
            label: Text('Finalizar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
              _finalizarPartido();
            },
          ),
        ],
      ),
    );
  }
  
  // Método para finalizar el partido en la base de datos
  Future<void> _finalizarPartido() async {
    try {
      // Mostrar indicador de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: CircularProgressIndicator(
            color: Colors.orange.shade600,
          ),
        ),
      );
      
      // Convertir matchId a int si es necesario
      int matchIdInt;
      if (widget.matchId is int) {
        matchIdInt = widget.matchId;
      } else {
        matchIdInt = int.parse(widget.matchId.toString());
      }
      
      // Actualizar el estado del partido a "finalizado"
      await supabase
          .from('partidos')
          .update({'estado': 'finalizado'})
          .eq('id', matchIdInt);
      
      // Actualizar datos locales
      setState(() {
        _matchData['estado'] = 'finalizado';
      });
      
      // Cerrar el indicador de carga
      Navigator.pop(context);
      
      // Mostrar mensaje de éxito
      Fluttertoast.showToast(
        msg: "Partido finalizado correctamente",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );
      
    } catch (e) {
      print('Error al finalizar el partido: $e');
      
      // Cerrar el indicador de carga si está abierto
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      
      // Mostrar mensaje de error
      Fluttertoast.showToast(
        msg: "Error al finalizar el partido",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }
  
  Widget _buildFullScreenTeamFormation(bool isTeamClaro) {
    final List<Map<String, dynamic>> players = isTeamClaro ? _teamClaro : _teamOscuro;
    final Map<String, Offset> positions = isTeamClaro ? _teamClaroPositions : _teamOscuroPositions;
    final Color teamColor = isTeamClaro ? Colors.blue.shade700 : Colors.red.shade700;
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxWidth = constraints.maxWidth;
        final double maxHeight = constraints.maxHeight;
        
        // Usar toda la pantalla para el campo, sin calcular la relación de aspecto
        // Esto asegura que el campo ocupe todo el espacio disponible
        double fieldWidth = maxWidth;
        double fieldHeight = maxHeight;
        
        return Container(
          width: maxWidth,
          height: maxHeight,
          child: Stack(
            fit: StackFit.expand, // Asegura que el Stack use todo el espacio disponible
            children: [
              // Campo de fútbol que ocupa toda la pantalla
              Container(
                width: fieldWidth,
                height: fieldHeight,
                decoration: BoxDecoration(
                  color: const Color(0xFF2E7D32), // Verde campo de fútbol
                  image: DecorationImage(
                    image: AssetImage('assets/grass_texture.png'),
                    fit: BoxFit.cover,
                    opacity: 0.2,
                  ),
                ),
                child: Stack(
                  children: [
                    // Elementos del campo (líneas, círculos, etc.)
                    _buildFootballFieldElements(fieldWidth, fieldHeight, isTeamClaro),
                    
                    // Añadir jugadores posicionados
                    ...players.map((player) {
                      final String playerId = player['id'].toString();
                      
                      // Obtener la posición o usar una por defecto
                      Offset position = positions[playerId] ?? 
                          Offset(0.5, isTeamClaro ? 0.3 : 0.7); // Posición por defecto
                      
                      // Calcular la posición en píxeles
                      final double posX = position.dx * fieldWidth;
                      final double posY = position.dy * fieldHeight;
                      
                      return Stack(
                        children: [
                          // Avatar del jugador
                          Positioned(
                            left: posX - 25,
                            top: posY - 25,
                            child: GestureDetector(
                              onTap: () => _showPlayerStatsDialog(player, isTeamClaro),
                              child: _buildPlayerAvatar(player, isTeamClaro, posX, posY),
                            ),
                          ),
                          
                          // Nombre del jugador
                          Positioned(
                            left: posX - 40,
                            top: posY + 30,
                            child: Container(
                              width: 80,
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isTeamClaro 
                                      ? Colors.blue.shade300.withOpacity(0.5) 
                                      : Colors.red.shade300.withOpacity(0.5),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    player['nombre'] ?? 'Jugador',
                                    style: TextStyle(
                                      color: isTeamClaro ? Colors.blue.shade200 : Colors.red.shade200,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (player['goles'] > 0 || player['asistencias'] > 0)
                                    Text(
                                      '⚽ ${player['goles']} | 👟 ${player['asistencias']}',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                    
                    // Añadir información del equipo en una tarjeta flotante
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isTeamClaro ? Colors.blue.shade400 : Colors.red.shade400,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              isTeamClaro ? 'Equipo Claro' : 'Equipo Oscuro',
                              style: TextStyle(
                                color: isTeamClaro ? Colors.blue.shade200 : Colors.red.shade200,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Goles: ${_matchData[isTeamClaro ? 'resultado_claro' : 'resultado_oscuro'] ?? 0}',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              'Jugadores: ${players.length}',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildPlayerAvatar(Map<String, dynamic> player, bool isTeamA, double posX, double posY) {
    // Calcular promedio de habilidades si están disponibles
    double average = 0;
    if (player.containsKey('tiro') && 
        player.containsKey('regate') && 
        player.containsKey('tecnica') && 
        player.containsKey('defensa') && 
        player.containsKey('velocidad') && 
        player.containsKey('aguante') && 
        player.containsKey('control')) {
      
      final stats = [
        player['tiro'] ?? 0,
        player['regate'] ?? 0,
        player['tecnica'] ?? 0,
        player['defensa'] ?? 0,
        player['velocidad'] ?? 0,
        player['aguante'] ?? 0,
        player['control'] ?? 0,
      ];
      
      average = stats.isNotEmpty 
          ? stats.reduce((a, b) => a + b) / stats.length 
          : 0;
    }
    
    return Stack(
      alignment: Alignment.center,
      children: [
        // Fondo con efecto de brillo
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: isTeamA 
                  ? [Colors.blue.shade600, Colors.blue.shade900] 
                  : [Colors.red.shade600, Colors.red.shade900],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: Colors.white,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: (isTeamA ? Colors.blue : Colors.red).withOpacity(0.3),
                blurRadius: 12,
                spreadRadius: 2,
                offset: Offset(0, 3),
              ),
              BoxShadow(
                color: Colors.black26,
                blurRadius: 5,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: player['foto_perfil'] != null
                ? ClipOval(
                    child: Image.network(
                      player['foto_perfil'],
                      width: 46,
                      height: 46,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded / 
                                  loadingProgress.expectedTotalBytes!
                              : null,
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Text(
                          player['nombre'][0].toUpperCase(),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
                  )
                : Text(
                    player['nombre'][0].toUpperCase(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        
        // Efecto de brillo
        Positioned.fill(
          child: ClipOval(
            child: CustomPaint(
              painter: AvatarGlowPainter(),
            ),
          ),
        ),
        
        // Mostrar puntuación del jugador (si está disponible)
        if (average > 0)
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _getAverageColor(average).withOpacity(0.8),
                    _getAverageColor(average),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  average.toStringAsFixed(0),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFootballFieldElements(double width, double height, bool isTeamA) {
    return Stack(
      children: [
        // Línea central
        Positioned(
          top: height / 2 - 1,
          left: 0,
          right: 0,
          child: Container(
            height: 2,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
        
        // Círculo central
        Positioned(
          top: height / 2 - width * 0.1,
          left: width / 2 - width * 0.1,
          child: Container(
            width: width * 0.2,
            height: width * 0.2,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.8), width: 2),
            ),
          ),
        ),
        
        // Punto central
        Positioned(
          top: height / 2 - 4,
          left: width / 2 - 4,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ),
        
        // Área de penalti superior
        Positioned(
          top: 0,
          left: width * 0.15,
          child: Container(
            width: width * 0.7,
            height: height * 0.2,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white.withOpacity(0.8), width: 2),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(8),
                bottomRight: Radius.circular(8),
              ),
            ),
          ),
        ),
        
        // Área de portería superior
        Positioned(
          top: 0,
          left: width * 0.35,
          child: Container(
            width: width * 0.3,
            height: height * 0.08,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white.withOpacity(0.8), width: 2),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(4),
              ),
            ),
          ),
        ),
        
        // Punto de penalti superior
        Positioned(
          top: height * 0.15,
          left: width / 2 - 4,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ),
        
        // Área de penalti inferior
        Positioned(
          bottom: 0,
          left: width * 0.15,
          child: Container(
            width: width * 0.7,
            height: height * 0.2,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white.withOpacity(0.8), width: 2),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
          ),
        ),
        
        // Área de portería inferior
        Positioned(
          bottom: 0,
          left: width * 0.35,
          child: Container(
            width: width * 0.3,
            height: height * 0.08,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white.withOpacity(0.8), width: 2),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
          ),
        ),
        
        // Punto de penalti inferior
        Positioned(
          bottom: height * 0.15,
          left: width / 2 - 4,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ),
        
        // Portería superior
        Positioned(
          top: 0,
          left: width * 0.4,
          child: Container(
            width: width * 0.2,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(0.5),
                  blurRadius: 5,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        ),
        
        // Portería inferior
        Positioned(
          bottom: 0,
          left: width * 0.4,
          child: Container(
            width: width * 0.2,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(0.5),
                  blurRadius: 5,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        ),
        
        // Añadir reflejo/brillo para dar efecto profesional
        Positioned.fill(
          child: CustomPaint(
            painter: GlassPainter(),
          ),
        ),
      ],
    );
  }
  
  Color _getAverageColor(double average) {
    if (average >= 80) return Colors.green;
    if (average >= 60) return Colors.orange;
    return Colors.red;
  }
  
  // Método para mostrar el diálogo de estadísticas del jugador
  void _showPlayerStatsDialog(Map<String, dynamic> player, bool isTeamClaro) {
    // Valores iniciales para los contadores
    int goles = player['goles'] ?? 0;
    int asistencias = player['asistencias'] ?? 0;
    int golesPropios = player['goles_propios'] ?? 0; // Contador para goles en propia puerta
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Container(
              padding: EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Título con avatar
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: isTeamClaro ? Colors.blue.shade700 : Colors.red.shade700,
                        radius: 20,
                        child: player['foto_perfil'] != null
                          ? ClipOval(
                              child: Image.network(
                                player['foto_perfil'],
                                width: 36,
                                height: 36,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Text(
                                  player['nombre'][0].toUpperCase(),
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ),
                            )
                          : Text(
                              player['nombre'][0].toUpperCase(),
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          player['nombre'] ?? 'Jugador',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 16),
                  
                  // Tarjeta de estadísticas
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        children: [
                          // Goles
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.sports_soccer, color: Colors.black87),
                                  SizedBox(width: 8),
                                  Text('Goles', style: TextStyle(fontSize: 16)),
                                ],
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 36,
                                    child: IconButton(
                                      iconSize: 20,
                                      padding: EdgeInsets.zero,
                                      icon: Icon(Icons.remove_circle_outline),
                                      color: Colors.red,
                                      onPressed: goles > 0 ? () {
                                        setState(() => goles--);
                                      } : null,
                                    ),
                                  ),
                                  Container(
                                    width: 30,
                                    alignment: Alignment.center,
                                    child: Text(
                                      '$goles',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 36,
                                    child: IconButton(
                                      iconSize: 20,
                                      padding: EdgeInsets.zero,
                                      icon: Icon(Icons.add_circle_outline),
                                      color: Colors.green,
                                      onPressed: () {
                                        setState(() => goles++);
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          
                          SizedBox(height: 8),
                          
                          // Goles en propia puerta
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Icon(Icons.sports_soccer, color: Colors.red.shade700),
                                    SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        'Goles en propia', 
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.red.shade700,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 36,
                                    child: IconButton(
                                      iconSize: 20,
                                      padding: EdgeInsets.zero,
                                      icon: Icon(Icons.remove_circle_outline),
                                      color: Colors.red,
                                      onPressed: golesPropios > 0 ? () {
                                        setState(() => golesPropios--);
                                      } : null,
                                    ),
                                  ),
                                  Container(
                                    width: 30,
                                    alignment: Alignment.center,
                                    child: Text(
                                      '$golesPropios',
                                      style: TextStyle(
                                        fontSize: 16, 
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red.shade700,
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 36,
                                    child: IconButton(
                                      iconSize: 20,
                                      padding: EdgeInsets.zero,
                                      icon: Icon(Icons.add_circle_outline),
                                      color: Colors.green,
                                      onPressed: () {
                                        setState(() => golesPropios++);
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          
                          SizedBox(height: 8),
                          
                          // Asistencias
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.sports, color: Colors.black87),
                                  SizedBox(width: 8),
                                  Text('Asistencias', style: TextStyle(fontSize: 16)),
                                ],
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 36,
                                    child: IconButton(
                                      iconSize: 20,
                                      padding: EdgeInsets.zero,
                                      icon: Icon(Icons.remove_circle_outline),
                                      color: Colors.red,
                                      onPressed: asistencias > 0 ? () {
                                        setState(() => asistencias--);
                                      } : null,
                                    ),
                                  ),
                                  Container(
                                    width: 30,
                                    alignment: Alignment.center,
                                    child: Text(
                                      '$asistencias',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 36,
                                    child: IconButton(
                                      iconSize: 20,
                                      padding: EdgeInsets.zero,
                                      icon: Icon(Icons.add_circle_outline),
                                      color: Colors.green,
                                      onPressed: () {
                                        setState(() => asistencias++);
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 16),
                  
                  // Botones de acción
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        child: Text('Cancelar'),
                        onPressed: () => Navigator.pop(context),
                      ),
                      SizedBox(width: 16),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isTeamClaro ? Colors.blue.shade700 : Colors.red.shade700,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: Text('Guardar'),
                        onPressed: () {
                          _updatePlayerStats(player['id'], goles, asistencias, golesPropios, isTeamClaro);
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
  
  // Método para actualizar las estadísticas del jugador en la base de datos
  Future<void> _updatePlayerStats(dynamic playerId, int goles, int asistencias, int golesPropios, bool isTeamClaro) async {
    try {
      // Convertir matchId a int si es necesario
      int matchIdInt;
      if (widget.matchId is int) {
        matchIdInt = widget.matchId;
      } else {
        matchIdInt = int.parse(widget.matchId.toString());
      }
      
      // Verificar si existe un registro para este jugador y partido
      final statsResponse = await supabase
          .from('estadisticas')
          .select()
          .eq('jugador_id', playerId)
          .eq('partido_id', matchIdInt)
          .maybeSingle();
      
      // Crear o actualizar el registro
      if (statsResponse == null) {
        // Crear nuevo registro
        await supabase.from('estadisticas').insert({
          'jugador_id': playerId,
          'partido_id': matchIdInt,
          'goles': goles,
          'asistencias': asistencias,
          'goles_propios': golesPropios,
          'equipo': isTeamClaro ? 'team_claro' : 'team_oscuro',
        });
      } else {
        // Actualizar registro existente
        await supabase
            .from('estadisticas')
            .update({
              'goles': goles,
              'asistencias': asistencias,
              'goles_propios': golesPropios,
            })
            .eq('jugador_id', playerId)
            .eq('partido_id', matchIdInt);
      }
      
      // Actualizar los marcadores de ambos equipos en la base de datos
      // Primero, necesitamos obtener todos los datos de estadísticas
      final allStats = await supabase
          .from('estadisticas')
          .select('goles, goles_propios, equipo')
          .eq('partido_id', matchIdInt);
      
      // Calcular los goles para cada equipo
      int golesEquipoClaro = 0;
      int golesEquipoOscuro = 0;
      
      for (var stat in allStats) {
        if (stat['equipo'] == 'team_claro') {
          // Goles directos del equipo claro
          golesEquipoClaro += (stat['goles'] as int? ?? 0);
          // Goles en propia puerta del equipo oscuro
          if (stat['equipo'] != 'team_claro') {
            golesEquipoClaro += (stat['goles_propios'] as int? ?? 0);
          }
        } else if (stat['equipo'] == 'team_oscuro') {
          // Goles directos del equipo oscuro
          golesEquipoOscuro += (stat['goles'] as int? ?? 0);
          // Goles en propia puerta del equipo claro
          if (stat['equipo'] != 'team_oscuro') {
            golesEquipoOscuro += (stat['goles_propios'] as int? ?? 0);
          }
        }
      }
      
      // Sumar goles en propia puerta del equipo contrario
      // Los goles en propia puerta del equipo claro suman para el equipo oscuro
      final golesPropiosClaro = await supabase
          .from('estadisticas')
          .select('goles_propios')
          .eq('partido_id', matchIdInt)
          .eq('equipo', 'team_claro');
          
      for (var stat in golesPropiosClaro) {
        golesEquipoOscuro += (stat['goles_propios'] as int? ?? 0);
      }
      
      // Los goles en propia puerta del equipo oscuro suman para el equipo claro
      final golesPropiosOscuro = await supabase
          .from('estadisticas')
          .select('goles_propios')
          .eq('partido_id', matchIdInt)
          .eq('equipo', 'team_oscuro');
          
      for (var stat in golesPropiosOscuro) {
        golesEquipoClaro += (stat['goles_propios'] as int? ?? 0);
      }
      
      // Actualizar el marcador en la base de datos
      await supabase
          .from('partidos')
          .update({
            'resultado_claro': golesEquipoClaro,
            'resultado_oscuro': golesEquipoOscuro
          })
          .eq('id', matchIdInt);
          
      // Actualizar los datos locales
      setState(() {
        _matchData['resultado_claro'] = golesEquipoClaro;
        _matchData['resultado_oscuro'] = golesEquipoOscuro;
        
        // Actualizar las estadísticas del jugador en la lista local
        if (isTeamClaro) {
          for (var i = 0; i < _teamClaro.length; i++) {
            if (_teamClaro[i]['id'] == playerId) {
              _teamClaro[i]['goles'] = goles;
              _teamClaro[i]['asistencias'] = asistencias;
              _teamClaro[i]['goles_propios'] = golesPropios;
              break;
            }
          }
        } else {
          for (var i = 0; i < _teamOscuro.length; i++) {
            if (_teamOscuro[i]['id'] == playerId) {
              _teamOscuro[i]['goles'] = goles;
              _teamOscuro[i]['asistencias'] = asistencias;
              _teamOscuro[i]['goles_propios'] = golesPropios;
              break;
            }
          }
        }
      });
      
      // Mostrar mensaje de éxito
      Fluttertoast.showToast(
        msg: "Estadísticas actualizadas",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );
      
    } catch (e) {
      print('Error al actualizar estadísticas: $e');
      
      // Mostrar mensaje de error
      Fluttertoast.showToast(
        msg: "Error al actualizar estadísticas",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }
}

// Painter para el efecto de reflejo del campo
class GlassPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, 0),
        Offset(size.width, size.height / 3),
        [
          Colors.white.withOpacity(0.05),
          Colors.white.withOpacity(0.01),
        ],
      );
    
    // Crear un suave reflejo en la parte superior
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height / 3),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Painter para el efecto de brillo en avatar
class AvatarGlowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, 0),
        Offset(size.width / 2, size.height / 2),
        [
          Colors.white.withOpacity(0.2),
          Colors.white.withOpacity(0.0),
        ],
      );
    
    canvas.drawCircle(
      Offset(size.width / 4, size.height / 4),
      size.width / 3,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}