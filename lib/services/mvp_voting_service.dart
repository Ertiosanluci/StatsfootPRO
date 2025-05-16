import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'notification_service.dart';

/// Clase de servicios para manejar la lógica de votaciones de MVP
class MVPVotingService {
  final SupabaseClient supabase = Supabase.instance.client;
  final NotificationService _notificationService = NotificationService();
    /// Inicia una votación para MVP en un partido
  Future<bool> startMVPVoting(int matchId, {int votingDurationHours = 24}) async {
    try {
      // Calcular cuándo termina la votación (24 horas por defecto)
      final DateTime votingEndsAt = DateTime.now().add(Duration(hours: votingDurationHours));
      
      // Insertar registro de votación
      await supabase.from('mvp_voting_status').insert({
        'match_id': matchId,
        'voting_ends_at': votingEndsAt.toIso8601String(),
        'created_by': supabase.auth.currentUser?.id,
      });
      
      // Obtener nombre del partido para la notificación
      final matchData = await supabase
          .from('matches')
          .select('nombre')
          .eq('id', matchId)
          .single();
      
      final matchName = matchData['nombre'] ?? 'Partido';
      
      // Enviar notificaciones a todos los participantes
      await _notificationService.notifyMatchParticipants(
        matchId: matchId,
        title: '¡Votación de MVP iniciada!',
        message: 'La votación para MVP del partido $matchName está abierta por $votingDurationHours horas. ¡Vota ahora! Se reconocerán los 3 más votados.',
        actionType: 'mvp_voting',
      );
      
      return true;
    } catch (e) {
      print('Error al iniciar votación de MVP: $e');
      return false;
    }
  }
  
  /// Verifica si hay una votación activa para un partido
  Future<Map<String, dynamic>?> getActiveVoting(int matchId) async {
    try {
      final response = await supabase
          .from('mvp_voting_status')
          .select()
          .eq('match_id', matchId)
          .eq('status', 'active')
          .maybeSingle();
          
      return response;
    } catch (e) {
      print('Error al verificar votación activa: $e');
      return null;
    }
  }
    /// Votar por un jugador como MVP
  Future<bool> voteForMVP({
    required int matchId,
    required String votedPlayerId,
    required String team,
  }) async {
    try {
      // Verificar que el usuario esté autenticado
      final currentUserId = supabase.auth.currentUser?.id;
      if (currentUserId == null) {
        Fluttertoast.showToast(
          msg: "Debes iniciar sesión para votar",
          backgroundColor: Colors.red,
        );
        return false;
      }
      
      // Verificar que la votación esté activa
      final activeVoting = await getActiveVoting(matchId);
      if (activeVoting == null) {
        Fluttertoast.showToast(
          msg: "La votación no está activa",
          backgroundColor: Colors.red,
        );
        return false;
      }
      
      // Verificar si el usuario ya ha votado por algún jugador
      final existingVote = await supabase
          .from('mvp_votes')
          .select()
          .eq('match_id', matchId)
          .eq('voter_id', currentUserId)
          .maybeSingle();
          
      if (existingVote != null) {
        // Actualizar voto existente
        await supabase
            .from('mvp_votes')
            .update({
              'voted_player_id': votedPlayerId,
              'team': team // Actualizar el equipo según sea necesario
            })
            .eq('id', existingVote['id']);
            
        Fluttertoast.showToast(
          msg: "Voto actualizado correctamente",
          backgroundColor: Colors.green,
        );
      } else {
        // Crear nuevo voto
        await supabase.from('mvp_votes').insert({
          'match_id': matchId,
          'voter_id': currentUserId,
          'voted_player_id': votedPlayerId,
          'team': team,
        });
        
        Fluttertoast.showToast(
          msg: "Voto registrado correctamente",
          backgroundColor: Colors.green,
        );
      }      
      return true;
    } catch (e) {
      print('Error al votar por MVP: $e');
      Fluttertoast.showToast(
        msg: "Error al registrar voto: $e",
        backgroundColor: Colors.red,
      );
      return false;
    }
  }
  
  /// Obtener el voto previo del usuario en un partido específico
  Future<Map<String, dynamic>?> getPreviousVote(int matchId) async {
    try {
      final currentUserId = supabase.auth.currentUser?.id;
      if (currentUserId == null) {
        return null;
      }
      
      final vote = await supabase
          .from('mvp_votes')
          .select('*')
          .eq('match_id', matchId)
          .eq('voter_id', currentUserId)
          .maybeSingle();
          
      return vote;
    } catch (e) {
      print('Error al obtener voto previo: $e');
      return null;
    }
  }
  
  /// Obtener los 3 mejores jugadores según los votos
  Future<List<Map<String, dynamic>>> getTopVotedPlayers(int matchId, {int limit = 3}) async {
    try {
      final result = await supabase.rpc(
        'get_top_mvp_votes',
        params: {
          'match_id_param': matchId,
          'limit_param': limit
        }
      );
      
      return List<Map<String, dynamic>>.from(result);
    } catch (e) {
      print('Error al obtener los mejores jugadores: $e');
      return [];
    }
  }
  
  /// Finaliza la votación y establece los MVPs basados en los votos
  Future<Map<String, String?>> finishVotingAndSetMVPs(int matchId) async {
    try {
      // Obtener los 3 mejores jugadores votados
      final topPlayers = await getTopVotedPlayers(matchId, limit: 3);
      
      String? mvpClaroId;
      String? mvpOscuroId;
      List<Map<String, dynamic>> top3Players = [];
      
      if (topPlayers.isNotEmpty) {
        // Guardar los 3 mejores jugadores en una tabla especial
        for (var player in topPlayers) {
          await supabase.from('mvp_top_players').upsert({
            'match_id': matchId,
            'player_id': player['voted_player_id'],
            'votes': player['vote_count'],
            'rank': topPlayers.indexOf(player) + 1,
            'team': player['team']
          });
          
          // Para mantener compatibilidad con el sistema actual
          // Establecemos los MVPs de cada equipo basados en los jugadores con más votos de cada equipo
          if (player['team'] == 'claro' && mvpClaroId == null) {
            mvpClaroId = player['voted_player_id'];
          } else if (player['team'] == 'oscuro' && mvpOscuroId == null) {
            mvpOscuroId = player['voted_player_id'];
          }
        }
        
        top3Players = topPlayers;
      }
      
      // Actualizar el estado de la votación a completado
      await supabase
          .from('mvp_voting_status')
          .update({'status': 'completed'})
          .eq('match_id', matchId);
      
      // Actualizar los MVPs en la tabla de partidos
      await supabase
          .from('matches')
          .update({
            'mvp_team_claro': mvpClaroId,
            'mvp_team_oscuro': mvpOscuroId
          })
          .eq('id', matchId);
        // Obtener información del partido para la notificación
      final matchData = await supabase
          .from('matches')
          .select('nombre')
          .eq('id', matchId)
          .single();
      
      final matchName = matchData['nombre'] ?? 'Partido';
      
      // Construir mensaje con los 3 mejores jugadores
      String topPlayersMessage = "";
      if (top3Players.isNotEmpty) {
        for (int i = 0; i < top3Players.length; i++) {
          final player = top3Players[i];
          final playerName = player['player_name'] ?? 'Jugador';
          final playerTeam = player['team'] == 'claro' ? 'Equipo Claro' : 'Equipo Oscuro';
          final position = i + 1;
          
          if (i > 0) topPlayersMessage += ", ";
          topPlayersMessage += "$position° $playerName ($playerTeam)";
        }
      } else {
        topPlayersMessage = "No se registraron suficientes votos";
      }
      
      // Enviar notificaciones con los resultados
      await _notificationService.notifyMatchParticipants(
        matchId: matchId,
        title: '¡Votación de MVP finalizada!',
        message: 'Top 3 jugadores del partido $matchName: $topPlayersMessage',
        actionType: 'mvp_results',
      );
      
      return {
        'mvp_team_claro': mvpClaroId,
        'mvp_team_oscuro': mvpOscuroId
      };
    } catch (e) {
      print('Error al finalizar votación de MVP: $e');
      return {
        'mvp_team_claro': null,
        'mvp_team_oscuro': null
      };
    }
  }
  
  /// Verifica si una votación ha expirado y la finaliza si es necesario
  Future<bool> checkAndFinishExpiredVoting(int matchId) async {
    try {
      final activeVoting = await getActiveVoting(matchId);
      if (activeVoting == null) return false;
      
      final DateTime votingEndsAt = DateTime.parse(activeVoting['voting_ends_at']);
      final bool isExpired = DateTime.now().isAfter(votingEndsAt);
      
      if (isExpired) {
        await finishVotingAndSetMVPs(matchId);
        return true;
      }
      
      return false;
    } catch (e) {
      print('Error al verificar votación expirada: $e');
      return false;
    }
  }
}
