import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:convert'; // Añadir para usar jsonDecode

// Importar los widgets y servicios creados
import 'widgets/match_details/football_field.dart';
import 'widgets/match_details/player_avatar.dart';
import 'widgets/match_details/scoreboard_widget.dart';
import 'widgets/match_details/team_formation.dart';
import 'widgets/match_details/match_finish_dialog.dart';
import 'widgets/match_details/player_stats_dialog.dart';
import 'widgets/match_details/match_services.dart';
import 'widgets/match_details/position_utils.dart';

class MatchDetailsScreen extends StatefulWidget {
  final dynamic matchId;
  
  const MatchDetailsScreen({Key? key, required this.matchId}) : super(key: key);
  
  @override
  _MatchDetailsScreenState createState() => _MatchDetailsScreenState();
}

class _MatchDetailsScreenState extends State<MatchDetailsScreen> with SingleTickerProviderStateMixin {
  final MatchServices _matchServices = MatchServices();
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
  
  // Método para cargar los detalles del partido
  Future<void> _fetchMatchDetails() async {
    try {
      setState(() => _isLoading = true);
      
      // Obtener detalles del partido usando el servicio
      _matchData = await _matchServices.getMatchDetails(widget.matchId);
      print('Datos del partido encontrados: ${_matchData['nombre']}');
      
      // Obtener datos originales de match_participants para mapear IDs correctamente
      int matchIdInt = _matchData['id'] as int;
      
      // Crear un mapa para relacionar user_id con participant_id
      Map<String, String> userIdToParticipantId = {};
      try {
        final participantsRaw = await Supabase.instance.client
            .from('match_participants')
            .select('id, user_id, equipo')
            .eq('match_id', matchIdInt);
            
        for (var participant in participantsRaw) {
          userIdToParticipantId[participant['user_id']] = participant['id'].toString();
          print('Mapeando user_id: ${participant['user_id']} -> participant_id: ${participant['id']} (equipo: ${participant['equipo']})');
        }
      } catch (e) {
        print('Error al obtener mapa de IDs: $e');
      }
      
      // Obtener participantes
      final participants = await _matchServices.getMatchParticipants(matchIdInt);
      _teamClaro = participants['teamClaro'] ?? [];
      _teamOscuro = participants['teamOscuro'] ?? [];
      
      // Añadir el participant_id a cada jugador usando el mapa creado
      for (var player in _teamClaro) {
        String userId = player['id'].toString();
        if (userIdToParticipantId.containsKey(userId)) {
          player['participant_id'] = userIdToParticipantId[userId];
          print('Asignando participant_id: ${player['participant_id']} a jugador Claro: ${player['nombre']}');
        }
      }
      
      for (var player in _teamOscuro) {
        String userId = player['id'].toString();
        if (userIdToParticipantId.containsKey(userId)) {
          player['participant_id'] = userIdToParticipantId[userId];
          print('Asignando participant_id: ${player['participant_id']} a jugador Oscuro: ${player['nombre']}');
        }
      }
      
      // Cargar posiciones de los jugadores
      _loadPlayerPositions();
      
      // Cargar MVPs
      _mvpTeamClaro = _matchData['mvp_team_claro'];
      _mvpTeamOscuro = _matchData['mvp_team_oscuro'];
      
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
  
  // Método para cargar las posiciones de los jugadores desde JSON a Offset
  void _loadPlayerPositions() {
    try {
      // Procesar las posiciones de los jugadores del equipo claro
      if (_matchData['team_claro_positions'] != null) {
        Map<String, dynamic> positions;
        
        // Manejar diferentes formatos de datos
        if (_matchData['team_claro_positions'] is String) {
          // Si está en formato String (como JSON), convertirlo a Map
          try {
            positions = Map<String, dynamic>.from(
              jsonDecode(_matchData['team_claro_positions'])
            );
            print('Team Claro positions from JSON string: $positions');
          } catch (e) {
            print('Error al decodificar team_claro_positions de formato String: $e');
            positions = {};
          }
        } else if (_matchData['team_claro_positions'] is Map) {
          // Si ya es un Map, usarlo directamente
          positions = Map<String, dynamic>.from(_matchData['team_claro_positions']);
          print('Team Claro positions from Map: $positions');
        } else {
          print('Formato no reconocido para team_claro_positions: ${_matchData['team_claro_positions'].runtimeType}');
          positions = {};
        }
        
        // Procesar las posiciones y asignarlas a los jugadores usando el participant_id
        positions.forEach((participantId, position) {
          if (position is Map) {
            double dx = (position['dx'] is num) ? (position['dx'] as num).toDouble() : 0.5;
            double dy = (position['dy'] is num) ? (position['dy'] as num).toDouble() : 0.3;
            
            // Primero intentar asignar la posición usando el participant_id directamente
            bool positionAssigned = false;
            
            // Buscar el jugador que tenga este ID como participant_id
            for (var player in _teamClaro) {
              if (player['participant_id'] == participantId) {
                String playerId = player['id'].toString();
                _teamClaroPositions[playerId] = Offset(dx, dy);
                positionAssigned = true;
                print('Posición asignada para equipo claro: user_id=${player['id']} usando participant_id=$participantId en ($dx, $dy)');
                break;
              }
            }
            
            // Si no se encontró, asignar al participantId directamente (retrocompatibilidad)
            if (!positionAssigned) {
              _teamClaroPositions[participantId] = Offset(dx, dy);
              print('Posición asignada directamente para equipo claro: participant_id=$participantId en ($dx, $dy)');
            }
          }
        });
      } else {
        print('No se encontraron posiciones para el equipo claro');
      }
      
      // Procesar las posiciones de los jugadores del equipo oscuro
      if (_matchData['team_oscuro_positions'] != null) {
        Map<String, dynamic> positions;
        
        // Manejar diferentes formatos de datos
        if (_matchData['team_oscuro_positions'] is String) {
          // Si está en formato String (como JSON), convertirlo a Map
          try {
            positions = Map<String, dynamic>.from(
              jsonDecode(_matchData['team_oscuro_positions'])
            );
            print('Team Oscuro positions from JSON string: $positions');
          } catch (e) {
            print('Error al decodificar team_oscuro_positions de formato String: $e');
            positions = {};
          }
        } else if (_matchData['team_oscuro_positions'] is Map) {
          // Si ya es un Map, usarlo directamente
          positions = Map<String, dynamic>.from(_matchData['team_oscuro_positions']);
          print('Team Oscuro positions from Map: $positions');
        } else {
          print('Formato no reconocido para team_oscuro_positions: ${_matchData['team_oscuro_positions'].runtimeType}');
          positions = {};
        }
        
        // Procesar las posiciones y asignarlas a los jugadores usando el participant_id
        positions.forEach((participantId, position) {
          if (position is Map) {
            double dx = (position['dx'] is num) ? (position['dx'] as num).toDouble() : 0.5;
            double dy = (position['dy'] is num) ? (position['dy'] as num).toDouble() : 0.7;
            
            // Primero intentar asignar la posición usando el participant_id
            bool positionAssigned = false;
            
            // Buscar el jugador que tenga este ID como participant_id
            for (var player in _teamOscuro) {
              if (player['participant_id'] == participantId) {
                String playerId = player['id'].toString();
                _teamOscuroPositions[playerId] = Offset(dx, dy);
                positionAssigned = true;
                print('Posición asignada para equipo oscuro: user_id=${player['id']} usando participant_id=$participantId en ($dx, $dy)');
                break;
              }
            }
            
            // Si no se encontró, asignar al participantId directamente (retrocompatibilidad)
            if (!positionAssigned) {
              _teamOscuroPositions[participantId] = Offset(dx, dy);
              print('Posición asignada directamente para equipo oscuro: participant_id=$participantId en ($dx, $dy)');
            }
          }
        });
      } else {
        print('No se encontraron posiciones para el equipo oscuro');
      }
      
      // Log sobre tipo de datos de las posiciones
      print('Tipo de datos posiciones equipo claro original: ${_matchData['team_claro_positions']?.runtimeType}');
      print('Tipo de datos posiciones equipo oscuro original: ${_matchData['team_oscuro_positions']?.runtimeType}');
      
      // Asignar posiciones predeterminadas a jugadores sin posición
      _assignDefaultPositions();
      
      // Log de posiciones finales
      print('Posiciones finales equipo claro: $_teamClaroPositions');
      print('Posiciones finales equipo oscuro: $_teamOscuroPositions');
    } catch (e) {
      print('Error al cargar posiciones de jugadores: $e');
    }
  }
  
  // Método para asignar posiciones predeterminadas a jugadores sin posición
  void _assignDefaultPositions() {
    // Obtener el formato del partido para determinar cuántos jugadores por equipo
    String formato = _matchData['formato'] ?? '5v5';
    List<String> partes = formato.split('v');
    int numJugadoresClaros = int.tryParse(partes[0]) ?? 5;
    int numJugadoresOscuros = int.tryParse(partes.length > 1 ? partes[1] : partes[0]) ?? 5;
    
    // Generar posiciones predeterminadas
    List<Offset> defaultPosClaro = PositionUtils.getDefaultPositions(numJugadoresClaros, true);
    List<Offset> defaultPosOscuro = PositionUtils.getDefaultPositions(numJugadoresOscuros, false);
    
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
  
  // Método para actualizar la posición de un jugador
  void _updatePlayerPosition(String playerId, Offset position, bool isTeamClaro) {
    setState(() {
      if (isTeamClaro) {
        _teamClaroPositions[playerId] = position;
      } else {
        _teamOscuroPositions[playerId] = position;
      }
    });
  }
  
  // Método para guardar posiciones de los jugadores
  Future<void> _saveAllPositionsToDatabase(bool isTeamClaro) async {
    try {
      // Mostrar indicador de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: CircularProgressIndicator(
            color: isTeamClaro ? Colors.blue.shade600 : Colors.red.shade600,
          ),
        ),
      );
      
      // Convertir matchId a int si es necesario
      int matchIdInt;
      if (_matchData['id'] is int) {
        matchIdInt = _matchData['id'];
      } else {
        matchIdInt = int.parse(_matchData['id'].toString());
      }
      
      // Preparar los datos de posición para guardar en la base de datos
      Map<String, dynamic> positionsToSave = {};
      
      final Map<String, Offset> positions = isTeamClaro ? _teamClaroPositions : _teamOscuroPositions;
      
      positions.forEach((playerId, position) {
        positionsToSave[playerId] = {
          'dx': position.dx,
          'dy': position.dy
        };
      });
      
      // Guardar posiciones usando el servicio
      await _matchServices.savePlayerPositions(matchIdInt, positionsToSave, isTeamClaro);
      
      // Cerrar el indicador de carga
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      
    } catch (e) {
      // Cerrar el indicador de carga si está abierto
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      
      print('Error al guardar posiciones: $e');
      
      // El mensaje de error se maneja en el servicio
    }
  }
  
  // Método para mostrar el diálogo de estadísticas de jugador
  void _showPlayerStatsDialog(Map<String, dynamic> player, bool isTeamClaro) {
    showDialog(
      context: context,
      builder: (context) => PlayerStatsDialog(
        player: player,
        isTeamClaro: isTeamClaro,
        onStatsUpdated: (playerId, goles, asistencias, golesPropios) async {
          int matchIdInt = _matchData['id'] as int;
          
          try {
            // Actualizar estadísticas del jugador
            await _matchServices.updatePlayerStats(
              matchIdInt,
              playerId,
              goles,
              asistencias,
              golesPropios,
              isTeamClaro
            );
            
            // Actualizar marcador del partido
            final updatedScore = await _matchServices.updateMatchScore(matchIdInt);
            
            // Actualizar datos locales
            setState(() {
              // Actualizar las estadísticas del jugador en la lista local
              if (isTeamClaro) {
                for (int i = 0; i < _teamClaro.length; i++) {
                  if (_teamClaro[i]['id'].toString() == playerId.toString()) {
                    _teamClaro[i]['goles'] = goles;
                    _teamClaro[i]['asistencias'] = asistencias;
                    _teamClaro[i]['goles_propios'] = golesPropios;
                    break;
                  }
                }
              } else {
                for (int i = 0; i < _teamOscuro.length; i++) {
                  if (_teamOscuro[i]['id'].toString() == playerId.toString()) {
                    _teamOscuro[i]['goles'] = goles;
                    _teamOscuro[i]['asistencias'] = asistencias;
                    _teamOscuro[i]['goles_propios'] = golesPropios;
                    break;
                  }
                }
              }
              
              // Actualizar el marcador
              _matchData['resultado_claro'] = updatedScore['resultado_claro'];
              _matchData['resultado_oscuro'] = updatedScore['resultado_oscuro'];
            });
            
          } catch (e) {
            print('Error al actualizar estadísticas: $e');
          }
        },
      ),
    );
  }
  
  // Método para mostrar el diálogo de finalizar partido
  void _showFinalizarPartidoDialog() {
    showDialog(
      context: context,
      builder: (context) => MatchFinishDialog(
        matchData: _matchData,
        teamClaro: _teamClaro,
        teamOscuro: _teamOscuro,
        onFinishMatch: (mvpClaroId, mvpOscuroId) async {
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
            
            int matchIdInt = _matchData['id'] as int;
            
            // Actualizar estado y MVPs
            await _matchServices.finishMatch(matchIdInt, mvpClaroId, mvpOscuroId);
            
            // Actualizar datos locales
            setState(() {
              _matchData['estado'] = 'finalizado';
              _matchData['mvp_team_claro'] = mvpClaroId;
              _matchData['mvp_team_oscuro'] = mvpOscuroId;
              _mvpTeamClaro = mvpClaroId;
              _mvpTeamOscuro = mvpOscuroId;
            });
            
            // Cerrar el indicador de carga
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
            
            // Obtener los nombres de los MVP para mostrar en el mensaje
            String mvpClaroNombre = '';
            String mvpOscuroNombre = '';
            
            if (mvpClaroId != null) {
              for (var player in _teamClaro) {
                if (player['id'].toString() == mvpClaroId) {
                  mvpClaroNombre = player['nombre'];
                  break;
                }
              }
            }
            
            if (mvpOscuroId != null) {
              for (var player in _teamOscuro) {
                if (player['id'].toString() == mvpOscuroId) {
                  mvpOscuroNombre = player['nombre'];
                  break;
                }
              }
            }
            
            // Mensaje de éxito
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
            
            Fluttertoast.showToast(
              msg: successMessage,
              toastLength: Toast.LENGTH_LONG,
              gravity: ToastGravity.BOTTOM,
              backgroundColor: Colors.green,
              textColor: Colors.white,
            );
            
          } catch (e) {
            print('Error al finalizar partido: $e');
            
            // Cerrar el indicador de carga si está abierto
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
            
            // Mostrar error
            Fluttertoast.showToast(
              msg: "Error al finalizar el partido",
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.BOTTOM,
              backgroundColor: Colors.red,
              textColor: Colors.white,
            );
          }
        },
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final int golesEquipoClaro = _matchData['resultado_claro'] ?? 0;
    final int golesEquipoOscuro = _matchData['resultado_oscuro'] ?? 0;
    final bool isPartidoFinalizado = _matchData['estado'] == 'finalizado';
    
    // Determinar si el usuario actual es el creador del partido
    final currentUser = Supabase.instance.client.auth.currentUser;
    final bool isCreator = !_isLoading && currentUser != null && 
                          _matchData['creador_id'] == currentUser.id;
                          
    // La vista solo debe ser de lectura si el usuario no es el creador
    final bool isReadOnly = !isCreator;

    // Mostrar toast informativo cuando la vista se carga en modo sólo lectura
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isLoading && isReadOnly) {
        Fluttertoast.showToast(
          msg: "Vista informativa - Solo el creador puede modificar los datos",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.blueGrey.shade700,
          textColor: Colors.white,
          fontSize: 16.0
        );
      } else if (!_isLoading && isCreator) {
        Fluttertoast.showToast(
          msg: "Toca en un jugador para editar sus estadísticas",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.green.shade700,
          textColor: Colors.white,
          fontSize: 16.0
        );
      }
    });

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
        leading: BackButton(color: Colors.white),
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
        // Mostrar opciones de edición solo al creador del partido
        actions: isReadOnly ? [] : [
          if (!isPartidoFinalizado && !_isLoading)
            IconButton(
              icon: Icon(
                Icons.sports_score,
                color: Colors.white,
                size: 26,
              ),
              tooltip: 'Editar estadísticas',
              onPressed: () {
                Fluttertoast.showToast(
                  msg: "Toca en un jugador para editar sus estadísticas",
                  toastLength: Toast.LENGTH_LONG,
                  gravity: ToastGravity.CENTER,
                  backgroundColor: Colors.blue.shade700,
                  textColor: Colors.white,
                  fontSize: 16.0
                );
              },
            ),
          if (!isPartidoFinalizado && !_isLoading)
            IconButton(
              icon: Icon(
                Icons.flag_outlined,
                color: Colors.white,
                size: 26,
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
              ScoreboardWidget(
                golesEquipoClaro: golesEquipoClaro,
                golesEquipoOscuro: golesEquipoOscuro,
                isPartidoFinalizado: isPartidoFinalizado,
              ),
              
              // Eliminar el banner informativo fijo
              
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
                      TeamFormation(
                        players: _teamClaro,
                        positions: _teamClaroPositions,
                        isTeamClaro: true,
                        matchData: _matchData,
                        // Deshabilitar la edición de posiciones en modo de solo lectura
                        onPlayerPositionChanged: isReadOnly ? null : (playerId, position) => 
                            _updatePlayerPosition(playerId, position, true),
                        // Ocultar botón de guardar en modo de solo lectura
                        onSavePositions: isReadOnly ? null : () => _saveAllPositionsToDatabase(true),
                        mvpId: _mvpTeamClaro,
                        isReadOnly: isReadOnly, // Pasar el modo de solo lectura al componente
                        onPlayerTap: isReadOnly || isPartidoFinalizado ? null : _showPlayerStatsDialog, // Permitir editar estadísticas
                      ),
                      
                      // Equipo Oscuro
                      TeamFormation(
                        players: _teamOscuro,
                        positions: _teamOscuroPositions,
                        isTeamClaro: false,
                        matchData: _matchData,
                        // Deshabilitar la edición de posiciones en modo de solo lectura
                        onPlayerPositionChanged: isReadOnly ? null : (playerId, position) => 
                            _updatePlayerPosition(playerId, position, false),
                        // Ocultar botón de guardar en modo de solo lectura
                        onSavePositions: isReadOnly ? null : () => _saveAllPositionsToDatabase(false),
                        mvpId: _mvpTeamOscuro,
                        isReadOnly: isReadOnly, // Pasar el modo de solo lectura al componente
                        onPlayerTap: isReadOnly || isPartidoFinalizado ? null : _showPlayerStatsDialog, // Permitir editar estadísticas
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
    );
  }
}