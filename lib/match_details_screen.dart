import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:convert'; // Añadir para usar jsonDecode

// Importar los widgets y servicios creados
import 'widgets/match_details/scoreboard_widget.dart';
import 'widgets/match_details/team_formation.dart';
import 'widgets/match_details/match_finish_dialog.dart';
import 'widgets/match_details/player_stats_dialog.dart';
import 'widgets/match_details/match_services.dart';
import 'widgets/match_details/position_utils.dart';
import 'widgets/match_details/mvp_voting_dialog_widget.dart';
import 'widgets/match_details/start_mvp_voting_dialog.dart';
import 'widgets/match_details/floating_voting_timer_widget.dart';
import 'widgets/match_details/top_mvp_players_widget.dart';
import 'services/mvp_voting_service.dart';
import 'services/notification_service.dart';
import 'screens/mvp_voting_history_screen.dart';
import 'package:statsfoota/screens/mvp_results_reveal_screen.dart';
import 'tests/mvp_voting_test.dart' as mvp_tester;

class MatchDetailsScreen extends StatefulWidget {
  final dynamic matchId;
  
  const MatchDetailsScreen({Key? key, required this.matchId}) : super(key: key);
  
  @override
  _MatchDetailsScreenState createState() => _MatchDetailsScreenState();
}

class _MatchDetailsScreenState extends State<MatchDetailsScreen> with SingleTickerProviderStateMixin {
  final MatchServices _matchServices = MatchServices();
  final MVPVotingService _mvpVotingService = MVPVotingService();
  final NotificationService _notificationService = NotificationService();
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
  Map<String, dynamic>? _activeVoting; // Para almacenar información de votación activa
    @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchMatchDetails();
    _checkForNotifications();
    
    // Configurar un temporizador para revisar periódicamente si la votación ha expirado
    if (mounted) {
      Future.delayed(Duration(seconds: 3), () {
        _refreshMVPsAfterVoting();
      });
    }
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
      
      // Verificar si hay una votación de MVPs activa
      _activeVoting = await _mvpVotingService.getActiveVoting(matchIdInt);
      // Verificar si hay votaciones expiradas que deban cerrarse
      if (_activeVoting != null) {
        await _mvpVotingService.checkAndFinishExpiredVoting(matchIdInt);
        // Refrescar estado de votación
        _activeVoting = await _mvpVotingService.getActiveVoting(matchIdInt);
      }
      
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
              _mvpTeamClaro = mvpClaroId;              _mvpTeamOscuro = mvpOscuroId;
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
  
  // Método para mostrar el diálogo de iniciar votación de MVPs
  void _showStartVotingDialog() {
    showDialog(
      context: context,
      builder: (context) => StartMVPVotingDialog(
        onConfirm: (hours) => _startMVPVoting(hours),
        onCancel: () => Navigator.of(context).pop(),
      ),
    );
  }
  
  // Método para iniciar la votación de MVPs
  Future<void> _startMVPVoting(int hours) async {
    try {
      Navigator.of(context).pop(); // Cerrar el diálogo actual
      
      // Mostrar indicador de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: CircularProgressIndicator(
            color: Colors.amber,
          ),
        ),
      );
      
      int matchIdInt = _matchData['id'] as int;
      
      // Iniciar la votación
      final success = await _mvpVotingService.startMVPVoting(matchIdInt, votingDurationHours: hours);
      
      // Cerrar el indicador de carga
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      
      if (success) {
        // Actualizar estado de votación
        setState(() {
          _activeVoting = {
            'match_id': matchIdInt,
            'voting_started_at': DateTime.now().toIso8601String(),
            'voting_ends_at': DateTime.now().add(Duration(hours: hours)).toIso8601String(),
            'status': 'active',
          };
        });
        
        // Mostrar mensaje de éxito
        Fluttertoast.showToast(
          msg: "Votación de MVPs iniciada correctamente. Duración: $hours horas",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );
      } else {
        // Mostrar mensaje de error
        Fluttertoast.showToast(
          msg: "Error al iniciar la votación de MVPs",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
    } catch (e) {
      print('Error al iniciar votación de MVPs: $e');
      
      // Cerrar el indicador de carga si está abierto
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      
      // Mostrar mensaje de error
      Fluttertoast.showToast(
        msg: "Error al iniciar la votación: $e",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }
    // Método para mostrar el diálogo de votación de MVPs  // Método para mostrar el diálogo de votación de MVP
  void _showMVPVotingDialog() async {
    int matchIdInt = _matchData['id'] as int;
    
    // Obtener el voto previo del usuario si existe
    final previousVote = await _mvpVotingService.getPreviousVote(matchIdInt);
    final previousVotedPlayerId = previousVote != null ? previousVote['voted_player_id'] as String? : null;
    
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => MVPVotingDialog(
        teamClaro: _teamClaro,
        teamOscuro: _teamOscuro,
        matchId: matchIdInt,
        onVoteSubmit: _submitMVPVote,
        previousVotedPlayerId: previousVotedPlayerId,
      ),
    );
  }
  // Método para enviar los votos de MVP
  Future<void> _submitMVPVote(String? selectedPlayerId, String? playerTeam) async {
    try {
      int matchIdInt = _matchData['id'] as int;
      bool hasVoted = false;
      
      // Votar por el jugador seleccionado
      if (selectedPlayerId != null && playerTeam != null) {
        final success = await _mvpVotingService.voteForMVP(
          matchId: matchIdInt,
          votedPlayerId: selectedPlayerId,
          team: playerTeam,
        );
        
        if (success) {
          hasVoted = true;
        }
      }
      
      // Mostrar mensaje según el resultado
      if (hasVoted) {
        Fluttertoast.showToast(
          msg: "¡Gracias por tu voto!",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );
      } else if (selectedPlayerId == null) {
        Fluttertoast.showToast(
          msg: "No has seleccionado ningún jugador para votar",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.orange,
          textColor: Colors.white,
        );
      }
    } catch (e) {
      print('Error al votar por MVPs: $e');
      Fluttertoast.showToast(
        msg: "Error al registrar tu voto: $e",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }
    // Método para finalizar manualmente la votación de MVP
  Future<void> _finishMVPVotingManually() async {
    try {
      // Mostrar un diálogo de confirmación
      final bool shouldFinish = await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Finalizar votación'),
          content: Text(
            '¿Estás seguro de que deseas finalizar la votación de MVP antes de tiempo?\n\n'
            'Se contabilizarán los votos actuales y se seleccionarán los ganadores del top 3.',
          ),
          actions: [
            TextButton(
              child: Text('Cancelar'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            ElevatedButton(
              child: Text('Finalizar votación'),
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ) ?? false;
      
      if (!shouldFinish) return;
      
      // Mostrar indicador de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: CircularProgressIndicator(
            color: Colors.amber,
          ),
        ),
      );
      
      int matchIdInt = _matchData['id'] as int;
      
      print('Iniciando finalización manual de votación para partido $matchIdInt');
      
      // Finalizar la votación
      final success = await _mvpVotingService.finishVotingManually(matchIdInt);
      
      // Cerrar el indicador de carga
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      
      if (success) {
        print('Votación finalizada con éxito, actualizando UI');
        
        // Obtener los detalles actualizados del partido
        final matchDetails = await _matchServices.getMatchDetails(widget.matchId);
        
        // Actualizar UI
        setState(() {
          _mvpTeamClaro = matchDetails['mvp_team_claro'];
          _mvpTeamOscuro = matchDetails['mvp_team_oscuro'];
          _activeVoting = null; // La votación ya no está activa
          _matchData['mvp_team_claro'] = matchDetails['mvp_team_claro'];
          _matchData['mvp_team_oscuro'] = matchDetails['mvp_team_oscuro'];
          
          print('MVPs actualizados: Claro=${_mvpTeamClaro}, Oscuro=${_mvpTeamOscuro}');
        });
        
        // Mostrar mensaje de éxito con botón para ver resultados
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Votación finalizada correctamente. Los resultados ya están disponibles.',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 5),
            action: SnackBarAction(
              label: 'VER RESULTADOS',
              textColor: Colors.amber,
              onPressed: _navigateToMVPResultsReveal,
            ),
          ),
        );
      } else {
        // Mostrar mensaje de error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'No se pudo finalizar la votación. Inténtalo de nuevo.',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      print('Error al finalizar votación manualmente: $e');
      
      // Cerrar el indicador de carga si está abierto
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      
      // Mostrar mensaje de error
      Fluttertoast.showToast(
        msg: "Error al finalizar la votación: $e",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }
  // Método para rehacer la votación de MVP
  // Esto permitirá al creador del partido borrar todos los votos y resultados actuales
  // y comenzar una nueva votación desde cero
  Future<void> _rehacerMVPVotacion() async {
    try {
      // Mostrar un diálogo de confirmación
      final bool shouldReset = await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Rehacer votación de MVP'),
          content: Text(
            '¿Estás seguro de que deseas rehacer la votación de MVP?\n\n'
            'Esto eliminará todos los votos actuales y permitirá iniciar una nueva votación. '
            'Esta acción no se puede deshacer.',
          ),
          actions: [
            TextButton(
              child: Text('Cancelar'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            ElevatedButton(
              child: Text('Rehacer votación'),
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade700,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ) ?? false;
      
      if (!shouldReset) return;
      
      // Mostrar indicador de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: CircularProgressIndicator(
            color: Colors.amber,
          ),
        ),
      );
      
      int matchIdInt = _matchData['id'] as int;
      
      // Resetear la votación
      final success = await _mvpVotingService.resetMVPVoting(matchIdInt);
      
      // Cerrar el indicador de carga
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      
      if (success) {        // Actualizar UI
        await _fetchMatchDetails();
        
        // Mostrar mensaje de éxito
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Votación de MVP reiniciada correctamente. Ya puedes iniciar una nueva votación.',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
            action: SnackBarAction(
              label: 'INICIAR AHORA',
              textColor: Colors.amber,
              onPressed: _showStartVotingDialog,
            ),
          ),
        );
      }
    } catch (e) {
      print('Error al rehacer votación de MVP: $e');
      
      // Cerrar el indicador de carga si está abierto
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      
      // Mostrar mensaje de error
      Fluttertoast.showToast(
        msg: "Error al rehacer la votación: $e",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  
  // Método para navegar a la pantalla de historial de votaciones
  void _navigateToVotingHistory() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MVPVotingHistoryScreen(
          matchId: _matchData['id'],
          matchName: _matchData['nombre'] ?? 'Partido',
        ),
      ),
    );
  }  // Método para navegar a la pantalla de revelación de resultados MVP
  void _navigateToMVPResultsReveal() async {
    try {
      print('DEBUG NAVIGATE: Intentando ver resultados de votación');
      print('DEBUG NAVIGATE: Estado del partido: ${_matchData['estado']}');
      print('DEBUG NAVIGATE: MVPs: Claro=$_mvpTeamClaro, Oscuro=$_mvpTeamOscuro');
      
      // Verificar si existe una votación finalizada (status = completed)
      final votingStatus = await supabase
          .from('mvp_voting_status')
          .select()
          .eq('match_id', _matchData['id'] as int)
          .eq('status', 'completed')
          .maybeSingle();
      
      print('DEBUG NAVIGATE: Estado de votación finalizada encontrado: $votingStatus');
      
      // Si no hay una votación finalizada, intentamos mostrar los resultados actuales disponibles
      // o mostramos mensajes informativos según el caso
      if (votingStatus == null) {
        // Verificar si hay votación en curso
        final activeVoting = await _mvpVotingService.getActiveVoting(_matchData['id'] as int);
        if (activeVoting != null) {
          // Hay una votación en curso
          final DateTime votingEndsAt = DateTime.parse(activeVoting['voting_ends_at']);
          final Duration remaining = votingEndsAt.difference(DateTime.now());
          final String timeLeft = remaining.inHours > 0 
              ? '${remaining.inHours} horas y ${remaining.inMinutes % 60} minutos' 
              : '${remaining.inMinutes} minutos';
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('La votación está en curso y finaliza en $timeLeft. Espera a que termine para ver los resultados oficiales.'),
              backgroundColor: Colors.blue,
              duration: Duration(seconds: 5),
              action: SnackBarAction(
                label: 'VOTAR',
                textColor: Colors.white,
                onPressed: () => _showMVPVotingDialog(),
              ),
            ),
          );
          return;
        } else if (_mvpTeamClaro != null || _mvpTeamOscuro != null) {
          // No hay votación pero hay MVPs asignados (modo antiguo o asignación directa)
          // Seguimos con la navegación para mostrar los MVPs directos
        } else {
          // No hay votación ni MVPs asignados
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('No existen resultados de votación. Se debe iniciar y finalizar una votación primero.'),
              backgroundColor: Colors.orange,
              action: SnackBarAction(
                label: 'INICIAR',
                textColor: Colors.white,
                onPressed: () => _showStartVotingDialog(),
              ),
            ),
          );
          return;
        }
      }      
      // Mostrar indicador de carga mientras obtenemos los datos
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                SizedBox(width: 12),
                Text('Cargando resultados...'),
              ],
            ),
            duration: Duration(seconds: 1),
            backgroundColor: Colors.blue.shade800,
          ),
        );      }
      
      // Obtener los jugadores mejor votados
      List<Map<String, dynamic>> topPlayers = await _mvpVotingService.getTopVotedPlayers(_matchData['id'] as int);
      print('Navegando a pantalla de resultados con ${topPlayers.length} jugadores');
      
      // Si no hay suficientes jugadores votados, intentamos obtener los MVPs asignados manualmente
      if (topPlayers.isEmpty && (_mvpTeamClaro != null || _mvpTeamOscuro != null)) {
        print('No hay suficientes jugadores votados, usando MVPs asignados');
        
        // Lista temporal para jugadores MVPs
        List<Map<String, dynamic>> manualMVPs = [];
        
        // Buscar y añadir MVP equipo claro
        if (_mvpTeamClaro != null) {
          for (var player in _teamClaro) {
            if (player['id'].toString() == _mvpTeamClaro) {
              manualMVPs.add({
                'voted_player_id': player['id'].toString(),
                'player_name': player['nombre'] ?? 'Jugador Claro',
                'team': 'claro',
                'vote_count': 1,
                'foto_url': player['foto_url'],
              });
              break;
            }
          }
        }
        
        // Buscar y añadir MVP equipo oscuro
        if (_mvpTeamOscuro != null) {
          for (var player in _teamOscuro) {
            if (player['id'].toString() == _mvpTeamOscuro) {
              manualMVPs.add({
                'voted_player_id': player['id'].toString(),
                'player_name': player['nombre'] ?? 'Jugador Oscuro',
                'team': 'oscuro',
                'vote_count': 1,
                'foto_url': player['foto_url'],
              });
              break;
            }
          }
        }
        
        // Usar los MVPs encontrados
        topPlayers = manualMVPs;
      }
      
      // Registro detallado para depuración
      for (int i = 0; i < topPlayers.length; i++) {
        final player = topPlayers[i];
        print('Jugador #$i details:');
        print('  - player_name: ${player["player_name"]}');
        print('  - vote_count: ${player["vote_count"]}');
        print('  - team: ${player["team"]}');
        print('  - foto_url: ${player["foto_url"]}');
      }
        // Navegamos a la pantalla de resultados con los jugadores más votados
        // Si no hay jugadores para mostrar después de todos nuestros intentos, mostrar un mensaje
      if (topPlayers.isEmpty) {
        // Verificar si el usuario actual es el creador del partido
        final currentUser = Supabase.instance.client.auth.currentUser;
        final bool isCurrentUserCreator = currentUser != null && _matchData['creador_id'] == currentUser.id;
          // Si el usuario actual es el creador, mostramos un botón para iniciar la votación
        // de lo contrario, solo mostramos el mensaje sin botón
        if (isCurrentUserCreator) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('No hay resultados disponibles. Es necesario iniciar una votación primero.'),
              backgroundColor: Colors.orange,
              action: SnackBarAction(
                label: 'INICIAR',
                textColor: Colors.white,
                onPressed: () => _showStartVotingDialog(),
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('No hay resultados disponibles. El creador del partido debe iniciar una votación primero.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }
      
      if (mounted) {
        // Usamos Navigator.push directamente para asegurar la transición
        await Navigator.of(context).push(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => MVPResultsRevealScreen(
              matchName: _matchData['nombre'] ?? 'Partido',
              topPlayers: topPlayers,
            ),transitionsBuilder: (context, animation, secondaryAnimation, child) {
              // Fix for red screen error - Ensuring opacity is clamped within valid range
              final fadeAnimation = animation.drive(
                Tween<double>(begin: 0.0, end: 1.0).chain(
                  CurveTween(curve: Curves.easeIn)
                )
              );
              
              return FadeTransition(
                opacity: fadeAnimation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.5),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutQuad,
                  )),
                  child: child,
                ),
              );
            },
            transitionDuration: const Duration(milliseconds: 500),
          ),
        );
      }
    } catch (e) {
      print('Error al navegar a pantalla de resultados: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar los resultados'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }  // Método para actualizar los MVPs después de que se completa una votación
  Future<void> _refreshMVPsAfterVoting() async {
    try {
      if (_activeVoting == null) {
        print('No hay votación activa para refrescar MVPs');
        return;
      }
      
      int matchIdInt = _matchData['id'] as int;
      print('Revisando si la votación del partido $matchIdInt ha finalizado...');      // Verificar el estado actual de la votación directamente desde la base de datos
      final currentVotingStatus = await supabase
          .from('mvp_voting_status')
          .select('status')
          .eq('match_id', matchIdInt)
          .maybeSingle();
      
      print('Estado actual de la votación: ${currentVotingStatus != null ? currentVotingStatus['status'] : "no encontrado"}');
      
      // La votación ya ha finalizado si el status es "completed" o si ya no existe un registro
      bool votingEnded = false;
      if (currentVotingStatus == null || currentVotingStatus['status'] == 'completed') {
        votingEnded = true;
      } else {
        // Verificar si la votación ha expirado por tiempo
        votingEnded = await _mvpVotingService.checkAndFinishExpiredVoting(matchIdInt);
      }
      
      if (votingEnded) {
        print('La votación del partido $matchIdInt ha finalizado. Actualizando datos...');
        // La votación ha terminado, obtener los detalles actualizados y los top jugadores
        final matchDetails = await _matchServices.getMatchDetails(widget.matchId);
        
        setState(() {
          _mvpTeamClaro = matchDetails['mvp_team_claro'];
          _mvpTeamOscuro = matchDetails['mvp_team_oscuro'];
          _activeVoting = null; // La votación ya no está activa
          _matchData['mvp_team_claro'] = matchDetails['mvp_team_claro'];
          _matchData['mvp_team_oscuro'] = matchDetails['mvp_team_oscuro'];
          
          print('MVPs actualizados: Claro=${_mvpTeamClaro}, Oscuro=${_mvpTeamOscuro}');
        });
        
        // Mostrar mensaje de que se ha completado la votación
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'La votación de MVPs ha finalizado. Los resultados ya están disponibles.',
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 5),
              action: SnackBarAction(
                label: 'VER RESULTADOS',
                textColor: Colors.amber,
                onPressed: _navigateToMVPResultsReveal,
              ),
            ),
          );
        }
      } else {
        print('La votación del partido $matchIdInt sigue activa.');
      }
    } catch (e) {
      print('Error al actualizar MVPs después de votación: $e');
    }
  }

  // Método para ejecutar pruebas del sistema de votación (solo para desarrollo)
  void _runVotingSystemTest() async {
    try {
      int matchIdInt = _matchData['id'] as int;
      
      // Mostrar diálogo de confirmación
      final bool shouldRun = await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Test del Sistema'),
          content: Text(
            'Esto ejecutará un test completo del sistema de votación de MVP. '
            'Se creará una votación real y se establecerán MVPs. '
            '¿Deseas continuar?'
          ),
          actions: [
            TextButton(
              child: Text('Cancelar'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            ElevatedButton(
              child: Text('Ejecutar Test'),
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
              ),
            ),
          ],
        ),
      ) ?? false;
      
      if (shouldRun) {
        // Ejecutar el tester usando el namespace importado
        final tester = mvp_tester.MVPVotingTester();
        await tester.testVotingFlow(matchIdInt, context);
        
        // Refrescar la pantalla al finalizar el test
        await _fetchMatchDetails();
      }
    } catch (e) {
      print('Error al ejecutar test: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final int golesEquipoClaro = _matchData['resultado_claro'] ?? 0;
    final int golesEquipoOscuro = _matchData['resultado_oscuro'] ?? 0;    final bool isPartidoFinalizado = _matchData['estado'] == 'finalizado';
    
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
        ),        // Mostrar opciones de edición solo al creador del partido
        actions: [          // Mostrar botón de votación para usuarios (si hay votación activa)
          if (isPartidoFinalizado && _activeVoting != null && !isReadOnly)
            IconButton(
              icon: Icon(
                Icons.how_to_vote,
                color: Colors.white,
                size: 26,
              ),
              tooltip: 'Votar por MVP',
              onPressed: _showMVPVotingDialog,
            ),
          
          // Botón para ver historial de votaciones (solo visible si partido finalizado)
          if (isPartidoFinalizado)
            IconButton(
              icon: Icon(
                Icons.history,
                color: Colors.white70,
                size: 24,
              ),
              tooltip: 'Historial de votaciones',
              onPressed: _navigateToVotingHistory,
            ),
          // Mostrar opciones para el creador del partido
          if (!isReadOnly && !_isLoading) ...[
            if (!isPartidoFinalizado)
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
            if (!isPartidoFinalizado)
              IconButton(
                icon: Icon(
                  Icons.flag_outlined,
                  color: Colors.white,
                  size: 26,
                ),
                tooltip: 'Finalizar partido',
                onPressed: _showFinalizarPartidoDialog,
              ),            if (isPartidoFinalizado && _activeVoting == null)
              IconButton(
                icon: Icon(
                  Icons.how_to_vote,
                  color: Colors.amber,
                  size: 26,
                ),
                tooltip: 'Iniciar votación MVPs',
                onPressed: _showStartVotingDialog,
              ),
                // Botón para rehacer votación (solo para el creador y si el partido está finalizado)
            if (isPartidoFinalizado && isCreator)
              IconButton(
                icon: Icon(
                  Icons.replay_circle_filled,
                  color: Colors.orange.shade600,
                  size: 26,
                ),
                tooltip: 'Rehacer votación MVP',
                onPressed: _rehacerMVPVotacion,
              ),
              
            // Botón de test eliminado
          ],        ],      ),      floatingActionButton: isPartidoFinalizado
        ? FloatingActionButton.extended(
            onPressed: _navigateToMVPResultsReveal,
            backgroundColor: Colors.amber.shade700,
            icon: Icon(Icons.emoji_events, color: Colors.white),
            label: Text(
              'Ver Resultados de Votación',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            elevation: 4,
          ) 
        : null,
      body: _isLoading 
        ? Center(child: CircularProgressIndicator(color: Colors.blue))
        : Stack(
            children: [
              // Contenido principal
              Column(
                children: [              
                  // Marcador
                  ScoreboardWidget(
                    golesEquipoClaro: golesEquipoClaro,
                    golesEquipoOscuro: golesEquipoOscuro,
                    isPartidoFinalizado: isPartidoFinalizado,
                  ),
                    // Mostrar resultados de MVP si el partido está finalizado y hay una votación completada
                  if (isPartidoFinalizado && (_mvpTeamClaro != null || _mvpTeamOscuro != null)) ...[  
                    // Título que solo muestra el nombre del partido
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: Row(
                        children: [
                          Icon(Icons.emoji_events, color: Colors.amber, size: 18),
                          SizedBox(width: 8),
                          Text(
                            _matchData['nombre'] ?? 'Partido',
                            style: TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    FutureBuilder<List<Map<String, dynamic>>>(                      future: _mvpVotingService.getTopVotedPlayers(_matchData['id'] as int),
                      builder: (context, snapshot) {
                        print('FutureBuilder estado: ${snapshot.connectionState}');
                        
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          print('TopMVPPlayersWidget: Cargando datos...');
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: TopMVPPlayersWidget(
                              topPlayers: [],
                              isLoading: true,
                            ),
                          );
                        }
                        
                        if (snapshot.hasError) {
                          print('Error al cargar top players: ${snapshot.error}');
                          return SizedBox();
                        }
                        
                        print('TopMVPPlayersWidget: Datos recibidos: ${snapshot.data?.length ?? 0} jugadores');
                        if (snapshot.data != null) {
                          for (var player in snapshot.data!) {
                            print('Player en match_details: ${player['player_name']}, Votos: ${player['vote_count']}, Equipo: ${player['team']}');
                          }
                        }
                        
                        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                          // Aseguramos que la lista de jugadores sea visible y clara
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.amber.withOpacity(0.5), width: 1),
                              ),
                              child: TopMVPPlayersWidget(
                                topPlayers: snapshot.data!,
                              ),
                            ),
                          );
                        }
                        
                        return SizedBox(); // Si no hay datos, no mostramos nada
                      },
                    ),
                  ],
              
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
                ),              ),
            ],
          ),                // Widget flotante de votación (solo si hay votación activa)
              if (_activeVoting != null)
                FloatingVotingTimerWidget(
                  votingData: _activeVoting!,
                  onVoteButtonPressed: _showMVPVotingDialog,
                  onFinishVotingPressed: isCreator ? _finishMVPVotingManually : null,
                  onResetVotingPressed: isCreator ? _rehacerMVPVotacion : null,
                ),
            ],
          ),
    );
  }
  
  // Método para revisar y mostrar notificaciones relevantes
  Future<void> _checkForNotifications() async {
    try {
      // Esperar a que los datos del partido estén cargados
      await Future.delayed(Duration(seconds: 2));
      
      // Verificar si hay notificaciones sin leer
      final notifications = await _notificationService.getUnreadNotifications();
      
      if (notifications.isNotEmpty && mounted) {
        // Filtrar notificaciones relacionadas con este partido
        final matchId = widget.matchId;
        final relevantNotifications = notifications
            .where((n) => n['match_id'] == matchId)
            .toList();
            
        // Mostrar la notificación más reciente si existe
        if (relevantNotifications.isNotEmpty && mounted) {
          final latestNotification = relevantNotifications.first;
          
          // Mostrar la notificación en la UI
          _notificationService.showNotification(
            context,
            latestNotification['title'],
            latestNotification['message'],
            backgroundColor: latestNotification['action_type'] == 'mvp_voting' 
                ? Colors.purple.shade800
                : Colors.blue.shade800,
            onTap: () {
              // Marcar como leída
              _notificationService.markNotificationAsRead(latestNotification['id']);
              
              // Si es una notificación de votación, mostrar el diálogo
              if (latestNotification['action_type'] == 'mvp_voting' && _activeVoting != null) {
                _showMVPVotingDialog();
              }
            },
          );
          
          // Marcar como leída
          for (var notification in relevantNotifications) {
            _notificationService.markNotificationAsRead(notification['id']);
          }
        }
      }
    } catch (e) {
      print('Error al revisar notificaciones: $e');
    }
  }
}