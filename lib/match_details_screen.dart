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
  String? _mvpTeamClaro;
  String? _mvpTeamOscuro;
  
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
      
      print('Buscando partido con ID: $matchIdInt');
      
      // Obtener los datos del partido usando la tabla 'matches' (no 'partidos')
      final response = await supabase
          .from('matches')
          .select('*')
          .eq('id', matchIdInt)
          .maybeSingle(); // Usar maybeSingle en lugar de single para evitar errores
      
      // Verificar si se encontró el partido
      if (response == null) {
        throw Exception('No se encontró ningún partido con el ID $matchIdInt');
      }
      
      _matchData = response;
      print('Datos del partido encontrados: ${_matchData['nombre']}');
      
      // Recuperar los participantes del partido con la información de profiles
      await _fetchMatchParticipants(matchIdInt);
      
      // Cargar posiciones de los jugadores
      _loadPlayerPositions();
      
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
  
  // Nuevo método para obtener los participantes del partido usando un JOIN entre match_participants y profiles
  Future<void> _fetchMatchParticipants(int matchId) async {
    try {
      // Obtener todos los participantes del partido con sus usernames desde profiles
      final response = await supabase
          .rpc('get_match_participants_with_profiles', params: {'match_id_param': matchId});
      
      if (response == null) {
        print('No se encontraron participantes para el partido $matchId');
        return;
      }
      
      List<dynamic> participants = response;
      List<Map<String, dynamic>> teamClaro = [];
      List<Map<String, dynamic>> teamOscuro = [];
      
      // Procesar los resultados y dividir en equipos
      for (var participant in participants) {
        Map<String, dynamic> playerData = {
          'id': participant['user_id'],
          'nombre': participant['username'] ?? 'Usuario sin nombre',
          'foto_perfil': participant['avatar_url'],
          'es_organizador': participant['es_organizador'] ?? false,
        };
        
        // Obtener estadísticas del jugador en este partido
        final statsResponse = await supabase
            .from('estadisticas')
            .select('*')
            .eq('jugador_id', playerData['id'])
            .eq('partido_id', matchId)
            .maybeSingle();
        
        // Añadir estadísticas si existen
        if (statsResponse != null) {
          playerData['goles'] = statsResponse['goles'] ?? 0;
          playerData['asistencias'] = statsResponse['asistencias'] ?? 0;
          playerData['goles_propios'] = statsResponse['goles_propios'] ?? 0;
        } else {
          playerData['goles'] = 0;
          playerData['asistencias'] = 0;
          playerData['goles_propios'] = 0;
        }
        
        // Agregar al equipo correspondiente según el valor de 'equipo'
        if (participant['equipo'] == 'team_claro') {
          teamClaro.add(playerData);
        } else if (participant['equipo'] == 'team_oscuro') {
          teamOscuro.add(playerData);
        } else {
          // Si no tiene equipo asignado, simplemente se ignora por ahora
          print('Jugador sin equipo asignado: ${playerData['nombre']}');
        }
      }
      
      // Actualizar estado con los equipos
      setState(() {
        _teamClaro = teamClaro;
        _teamOscuro = teamOscuro;
      });
      
    } catch (e) {
      print('Error al cargar participantes del partido: $e');
      
      // Intentar método de respaldo si falla la función RPC
      await _fetchParticipantsFallback(matchId);
    }
  }
  
  // Método de respaldo por si falla la función RPC
  Future<void> _fetchParticipantsFallback(int matchId) async {
    try {
      final response = await supabase
          .from('match_participants')
          .select('''
            match_id, 
            user_id, 
            equipo, 
            es_organizador, 
            joined_at,
            profiles!inner(id, username, avatar_url)
          ''')
          .eq('match_id', matchId);
      
      List<Map<String, dynamic>> teamClaro = [];
      List<Map<String, dynamic>> teamOscuro = [];
      
      for (var item in response) {
        // Extraer los datos de profiles que están anidados
        final profile = item['profiles'];
        
        Map<String, dynamic> playerData = {
          'id': item['user_id'],
          'nombre': profile['username'] ?? 'Usuario sin nombre',
          'foto_perfil': profile['avatar_url'],
          'es_organizador': item['es_organizador'] ?? false,
        };
        
        // Obtener estadísticas
        final statsResponse = await supabase
            .from('estadisticas')
            .select('*')
            .eq('jugador_id', playerData['id'])
            .eq('partido_id', matchId)
            .maybeSingle();
        
        if (statsResponse != null) {
          playerData['goles'] = statsResponse['goles'] ?? 0;
          playerData['asistencias'] = statsResponse['asistencias'] ?? 0;
          playerData['goles_propios'] = statsResponse['goles_propios'] ?? 0;
        } else {
          playerData['goles'] = 0;
          playerData['asistencias'] = 0;
          playerData['goles_propios'] = 0;
        }
        
        if (item['equipo'] == 'team_claro') {
          teamClaro.add(playerData);
        } else if (item['equipo'] == 'team_oscuro') {
          teamOscuro.add(playerData);
        }
      }
      
      setState(() {
        _teamClaro = teamClaro;
        _teamOscuro = teamOscuro;
      });
      
    } catch (e) {
      print('Error en método de respaldo para cargar participantes: $e');
      
      // Si todo falla, intentar con el método original
      List<dynamic> teamClaroIds = _matchData['team_claro'] ?? [];
      await _fetchTeamPlayers(teamClaroIds, true);
      
      List<dynamic> teamOscuroIds = _matchData['team_oscuro'] ?? [];
      await _fetchTeamPlayers(teamOscuroIds, false);
    }
  }
  
  Future<void> _fetchTeamPlayers(List<dynamic> playerIds, bool isTeamClaro) async {
    List<Map<String, dynamic>> players = [];
    
    for (var playerId in playerIds) {
      try {
        // Primero, obtener información de la tabla profiles usando el user_id
        final profileResponse = await supabase
            .from('profiles')
            .select('id, username, avatar_url')
            .eq('id', playerId)
            .single();
            
        Map<String, dynamic> playerData = {
          'id': profileResponse['id'],
          'nombre': profileResponse['username'],  // Usar username de profiles
          'foto_perfil': profileResponse['avatar_url'],  // Usar avatar_url de profiles
        };
        
        // Verificar si existe en la tabla jugadores para información adicional
        try {
          final playerInfoResponse = await supabase
              .from('jugadores')
              .select('*')
              .eq('id', playerId)
              .maybeSingle();
          
          // Combinar con información adicional si existe
          if (playerInfoResponse != null) {
            playerInfoResponse.forEach((key, value) {
              if (!playerData.containsKey(key) || playerData[key] == null) {
                playerData[key] = value;
              }
            });
          }
        } catch (e) {
          print('Info adicional no disponible para el jugador $playerId: $e');
        }
        
        // Obtener estadísticas del jugador en este partido
        final statsResponse = await supabase
            .from('estadisticas')
            .select('*')
            .eq('jugador_id', playerId)
            .eq('partido_id', widget.matchId)
            .maybeSingle();
        
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
        
        // En caso de error al obtener de profiles, intentar obtener datos de la tabla jugadores
        try {
          final fallbackResponse = await supabase
              .from('jugadores')
              .select('*')
              .eq('id', playerId)
              .single();
          
          Map<String, dynamic> playerData = Map<String, dynamic>.from(fallbackResponse);
          
          // Establecer valores predeterminados para estadísticas
          playerData['goles'] = 0;
          playerData['asistencias'] = 0;
          
          players.add(playerData);
        } catch (fallbackError) {
          print('Error también al cargar fallback para jugador $playerId: $fallbackError');
        }
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
                      colors: [Colors.blue.shade100, Colors.blue.shade300],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: TabBarView(
                    controller: _tabController,
                    physics: BouncingScrollPhysics(),
                    children: [
                      // Equipo Claro
                      _buildFullScreenTeamFormation(true),
                      
                      // Equipo Oscuro
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
    // Obtener la información actual del partido
    final int golesEquipoClaro = _matchData['resultado_claro'] ?? 0;
    final int golesEquipoOscuro = _matchData['resultado_oscuro'] ?? 0;
    
    // Variables locales para controlar el estado dentro del diálogo
    String? mvpClaroLocal = _mvpTeamClaro;
    String? mvpOscuroLocal = _mvpTeamOscuro;

    // Usar el contexto fuera del builder para evitar problemas con showDialog
    BuildContext outerContext = context;
    
    // Mostrar el diálogo con builder para manejar el estado de manera adecuada
    showDialog(
      context: outerContext,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return Dialog(
              backgroundColor: Colors.blue.shade900,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.white.withOpacity(0.2), width: 1),
              ),
              child: Container(
                padding: EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Título
                    Row(
                      children: [
                        Icon(
                          Icons.flag_outlined, 
                          color: Colors.white,
                          size: 24,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Finalizar Partido',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    
                    // Mensaje de confirmación
                    Text(
                      '¿Estás seguro de que deseas finalizar el partido?',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 16),
                    
                    // Marcador
                    Container(
                      width: double.infinity,
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
                              // Equipo Claro
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
                              
                              // VS
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
                              
                              // Equipo Oscuro
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
                    
                    SizedBox(height: 16),
                    
                    // MVP Equipo Claro - Título
                    Row(
                      children: [
                        Icon(
                          Icons.emoji_events,
                          color: Colors.amber,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'MVP Equipo Claro:',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    
                    // MVP Equipo Claro - Selector
                    Container(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _teamClaro.length,
                        itemBuilder: (context, index) {
                          final player = _teamClaro[index];
                          final playerId = player['id'].toString();
                          final isSelected = mvpClaroLocal == playerId;
                          
                          return GestureDetector(
                            onTap: () {
                              setDialogState(() {
                                mvpClaroLocal = playerId;
                              });
                            },
                            child: Container(
                              width: 80,
                              margin: EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: isSelected ? Colors.blue.shade700 : Colors.black45,
                                border: Border.all(
                                  color: isSelected ? Colors.amber : Colors.transparent,
                                  width: 2,
                                ),
                                boxShadow: isSelected ? [
                                  BoxShadow(
                                    color: Colors.amber.withOpacity(0.5),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  )
                                ] : [],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Avatar
                                  Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isSelected ? Colors.amber : Colors.blue.shade300,
                                        width: 2,
                                      ),
                                    ),
                                    child: ClipOval(
                                      child: player['foto_perfil'] != null
                                          ? Image.network(
                                              player['foto_perfil'],
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) => Center(
                                                child: Text(
                                                  player['nombre'][0].toUpperCase(),
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            )
                                          : Center(
                                              child: Text(
                                                player['nombre'][0].toUpperCase(),
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  // Nombre
                                  Text(
                                    player['nombre'],
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      fontSize: 12,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  // Icono MVP
                                  if (isSelected)
                                    Icon(
                                      Icons.emoji_events,
                                      color: Colors.amber,
                                      size: 14,
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    
                    SizedBox(height: 16),
                    
                    // MVP Equipo Oscuro - Título
                    Row(
                      children: [
                        Icon(
                          Icons.emoji_events,
                          color: Colors.amber,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'MVP Equipo Oscuro:',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    
                    // MVP Equipo Oscuro - Selector
                    Container(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _teamOscuro.length,
                        itemBuilder: (context, index) {
                          final player = _teamOscuro[index];
                          final playerId = player['id'].toString();
                          final isSelected = mvpOscuroLocal == playerId;
                          
                          return GestureDetector(
                            onTap: () {
                              setDialogState(() {
                                mvpOscuroLocal = playerId;
                              });
                            },
                            child: Container(
                              width: 80,
                              margin: EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: isSelected ? Colors.red.shade700 : Colors.black45,
                                border: Border.all(
                                  color: isSelected ? Colors.amber : Colors.transparent,
                                  width: 2,
                                ),
                                boxShadow: isSelected ? [
                                  BoxShadow(
                                    color: Colors.amber.withOpacity(0.5),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  )
                                ] : [],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Avatar
                                  Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isSelected ? Colors.amber : Colors.red.shade300,
                                        width: 2,
                                      ),
                                    ),
                                    child: ClipOval(
                                      child: player['foto_perfil'] != null
                                          ? Image.network(
                                              player['foto_perfil'],
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) => Center(
                                                child: Text(
                                                  player['nombre'][0].toUpperCase(),
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            )
                                          : Center(
                                              child: Text(
                                                player['nombre'][0].toUpperCase(),
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  // Nombre
                                  Text(
                                    player['nombre'],
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      fontSize: 12,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  // Icono MVP
                                  if (isSelected)
                                    Icon(
                                      Icons.emoji_events,
                                      color: Colors.amber,
                                      size: 14,
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    
                    SizedBox(height: 12),
                    
                    // Advertencia
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
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    SizedBox(height: 16),
                    
                    // Botones
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          child: Text(
                            'Cancelar',
                            style: TextStyle(color: Colors.white70),
                          ),
                          onPressed: () => Navigator.pop(dialogContext),
                        ),
                        SizedBox(width: 8),
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
                            // Guardar las selecciones locales a las variables de la clase
                            setState(() {
                              _mvpTeamClaro = mvpClaroLocal;
                              _mvpTeamOscuro = mvpOscuroLocal;
                            });
                            Navigator.pop(dialogContext);
                            _finalizarPartido();
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
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
      
      // Actualizar el estado del partido a "finalizado" y guardar los MVPs
      // Usar la tabla 'matches' en lugar de 'partidos'
      await supabase
          .from('matches')
          .update({
            'estado': 'finalizado',
            'mvp_team_claro': _mvpTeamClaro,
            'mvp_team_oscuro': _mvpTeamOscuro
          })
          .eq('id', matchIdInt);
      
      // Actualizar datos locales
      setState(() {
        _matchData['estado'] = 'finalizado';
        _matchData['mvp_team_claro'] = _mvpTeamClaro;
        _matchData['mvp_team_oscuro'] = _mvpTeamOscuro;
      });
      
      // Cerrar el indicador de carga
      Navigator.pop(context);
      
      // Obtener los nombres de los MVP para mostrar en el mensaje (si se seleccionaron)
      String mvpClaroNombre = '';
      String mvpOscuroNombre = '';
      
      if (_mvpTeamClaro != null) {
        for (var player in _teamClaro) {
          if (player['id'].toString() == _mvpTeamClaro) {
            mvpClaroNombre = player['nombre'];
            break;
          }
        }
      }
      
      if (_mvpTeamOscuro != null) {
        for (var player in _teamOscuro) {
          if (player['id'].toString() == _mvpTeamOscuro) {
            mvpOscuroNombre = player['nombre'];
            break;
          }
        }
      }
      
      // Construir mensaje de éxito con información de MVPs
      String successMessage = "Partido finalizado correctamente";
      if (mvpClaroNombre.isNotEmpty || mvpOscuroNombre.isNotEmpty) {
        successMessage += "\nMVPs: ";
        if (mvpClaroNombre.isNotEmpty) {
          successMessage += "$mvpClaroNombre (Claro)";
        }
        if (mvpClaroNombre.isNotEmpty && mvpOscuroNombre.isNotEmpty) {
          successMessage += " y ";
        }
        if (mvpOscuroNombre.isNotEmpty) {
          successMessage += "$mvpOscuroNombre (Oscuro)";
        }
      }
      
      // Mostrar mensaje de éxito
      Fluttertoast.showToast(
        msg: successMessage,
        toastLength: Toast.LENGTH_LONG,
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
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxWidth = constraints.maxWidth;
        final double maxHeight = constraints.maxHeight;
        
        // Campo que ocupa todo el espacio disponible
        double fieldWidth = maxWidth;
        double fieldHeight = maxHeight;
        
        return Container(
          width: maxWidth,
          height: maxHeight,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Campo de fútbol con textura
              Container(
                width: fieldWidth,
                height: fieldHeight,
                decoration: BoxDecoration(
                  color: const Color(0xFF2E7D32), // Verde campo de fútbol
                  image: DecorationImage(
                    image: AssetImage('assets/habilidades.png'),
                    fit: BoxFit.cover,
                    opacity: 0.1,
                  ),
                ),
                child: Stack(
                  children: [
                    // Elementos del campo (líneas, áreas, etc.)
                    _buildFootballFieldElements(fieldWidth, fieldHeight),
                    
                    // Jugadores posicionados en el campo
                    ...players.map((player) {
                      final String playerId = player['id'].toString();
                      
                      // Obtener posición o usar una predeterminada
                      Offset position = positions[playerId] ?? 
                          Offset(0.5, isTeamClaro ? 0.3 : 0.7);
                      
                      // Convertir posición relativa a píxeles
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
                              child: _buildPlayerAvatar(player, isTeamClaro),
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
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
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
                                  if (player['goles'] != null && player['goles'] > 0 || 
                                      player['asistencias'] != null && player['asistencias'] > 0)
                                    Text(
                                      '⚽ ${player['goles'] ?? 0} | 👟 ${player['asistencias'] ?? 0}',
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
                    
                    // Información del equipo (tarjeta flotante)
                    Positioned(
                      top: 16,
                      right: 16,
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

                    // Marcador en la parte superior central
                    Positioned(
                      top: 16,
                      left: fieldWidth / 2 - 50,
                      child: Container(
                        width: 100,
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${_matchData['resultado_claro'] ?? 0}',
                              style: TextStyle(
                                color: Colors.blue.shade300,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            Container(
                              margin: EdgeInsets.symmetric(horizontal: 6),
                              child: Text(
                                '-',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                            Text(
                              '${_matchData['resultado_oscuro'] ?? 0}',
                              style: TextStyle(
                                color: Colors.red.shade300,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
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
  
  Widget _buildPlayerAvatar(Map<String, dynamic> player, bool isTeamA) {
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
    
    // Verificar si el jugador es MVP
    final String playerId = player['id'].toString();
    final bool isMVP = (isTeamA && _matchData['mvp_team_claro'] == playerId) || 
                      (!isTeamA && _matchData['mvp_team_oscuro'] == playerId);
    final bool isFinished = _matchData['estado'] == 'finalizado';
    
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
              color: (isMVP && isFinished) ? Colors.amber : Colors.white,
              width: (isMVP && isFinished) ? 3 : 2,
            ),
            boxShadow: [
              if (isMVP && isFinished)
                BoxShadow(
                  color: Colors.amber.withOpacity(0.6),
                  blurRadius: 15,
                  spreadRadius: 2,
                  offset: Offset(0, 0),
                ),
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
            top: -5,
            right: -5,
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
          
        // Estrella MVP (ahora en la parte inferior derecha y evitando solapamiento)
        if (isMVP && isFinished)
          Positioned(
            bottom: -5,
            right: -5,
            child: Container(
              padding: EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: Colors.amber,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black38,
                    blurRadius: 3,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: Icon(
                Icons.star,
                color: Colors.white,
                size: 12,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFootballFieldElements(double width, double height) {
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
          .from('matches')
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

  // Método para cargar las posiciones de los jugadores desde JSON a Offset
  void _loadPlayerPositions() {
    try {
      // Procesar las posiciones de los jugadores del equipo claro
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
      
      // Procesar las posiciones de los jugadores del equipo oscuro
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
      
      // Asignar posiciones predeterminadas a jugadores sin posición
      _assignDefaultPositions();
    } catch (e) {
      print('Error al cargar posiciones de jugadores: $e');
    }
  }
  
  // Método para asignar posiciones predeterminadas a jugadores que no tienen una posición asignada
  void _assignDefaultPositions() {
    // Obtener el formato del partido para determinar cuántos jugadores por equipo
    String formato = _matchData['formato'] ?? '5v5';
    List<String> partes = formato.split('v');
    int numJugadoresClaros = int.tryParse(partes[0]) ?? 5;
    int numJugadoresOscuros = int.tryParse(partes.length > 1 ? partes[1] : partes[0]) ?? 5;
    
    // Generar posiciones predeterminadas
    List<Offset> defaultPosClaro = _getDefaultPositions(numJugadoresClaros, true);
    List<Offset> defaultPosOscuro = _getDefaultPositions(numJugadoresOscuros, false);
    
    // Asignar posiciones al equipo claro
    for (int i = 0; i < _teamClaro.length; i++) {
      String playerId = _teamClaro[i]['id'].toString();
      if (!_teamClaroPositions.containsKey(playerId)) {
        // Asignar posición predeterminada o una posición central si no hay suficientes predeterminadas
        _teamClaroPositions[playerId] = i < defaultPosClaro.length
            ? defaultPosClaro[i]
            : Offset(0.5, 0.3); // Posición por defecto
      }
    }
    
    // Asignar posiciones al equipo oscuro
    for (int i = 0; i < _teamOscuro.length; i++) {
      String playerId = _teamOscuro[i]['id'].toString();
      if (!_teamOscuroPositions.containsKey(playerId)) {
        // Asignar posición predeterminada o una posición central si no hay suficientes predeterminadas
        _teamOscuroPositions[playerId] = i < defaultPosOscuro.length
            ? defaultPosOscuro[i]
            : Offset(0.5, 0.7); // Posición por defecto
      }
    }
  }
  
  // Método para obtener posiciones predeterminadas según la formación
  List<Offset> _getDefaultPositions(int totalPlayers, bool isTeamA) {
    List<List<double>> positions;
    
    // Posiciones relativas (x, y) donde x e y están entre 0 y 1
    switch (totalPlayers) {
      case 5:
        positions = [
          [0.5, 0.15],   // Delantero
          [0.2, 0.3],    // Mediocampista izquierdo
          [0.5, 0.4],    // Mediocampista central
          [0.8, 0.3],    // Mediocampista derecho
          [0.5, 0.7],    // Defensa / Portero
        ];
        break;
      case 6:
        positions = [
          [0.5, 0.15],   // Delantero
          [0.2, 0.3],    // Mediocampista izquierdo
          [0.5, 0.3],    // Mediocampista central
          [0.8, 0.3],    // Mediocampista derecho
          [0.3, 0.6],    // Defensa izquierdo
          [0.7, 0.6],    // Defensa derecho
        ];
        break;
      case 7:
        positions = [
          [0.5, 0.15],   // Delantero
          [0.2, 0.25],   // Extremo izquierdo
          [0.5, 0.3],    // Mediocampista central
          [0.8, 0.25],   // Extremo derecho
          [0.3, 0.5],    // Mediocampista defensivo izquierdo
          [0.7, 0.5],    // Mediocampista defensivo derecho
          [0.5, 0.7],    // Defensa central / Portero
        ];
        break;
      case 8:
        positions = [
          [0.3, 0.15],   // Delantero izquierdo
          [0.7, 0.15],   // Delantero derecho
          [0.2, 0.3],    // Extremo izquierdo
          [0.5, 0.3],    // Mediocampista central
          [0.8, 0.3],    // Extremo derecho
          [0.3, 0.5],    // Mediocampista defensivo
          [0.7, 0.5],    // Defensa central
          [0.5, 0.7],    // Portero
        ];
        break;
      default:
        // Para otros formatos que no estén definidos, distribuir uniformemente
        positions = List.generate(totalPlayers, (index) {
          double y = 0.15 + (0.6 * index / (totalPlayers - 1 > 0 ? totalPlayers - 1 : 1));
          double x = 0.5;
          if (index % 2 == 1) {
            x = 0.3 + (0.4 * (index / totalPlayers));
          } else if (index % 2 == 0 && index > 0) {
            x = 0.7 - (0.4 * (index / totalPlayers));
          }
          return [x, y];
        });
    }
    
    // Convertir a lista de Offset
    List<Offset> offsets = positions.map((pos) {
      // Si es el equipo oscuro, invertir la posición vertical
      double dy = isTeamA ? pos[1] : 1.0 - pos[1];
      return Offset(pos[0], dy);
    }).toList();
    
    return offsets;
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