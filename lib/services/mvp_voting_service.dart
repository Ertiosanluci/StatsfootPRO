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
      print('Obteniendo top $limit jugadores para el partido $matchId');
      
      final result = await supabase.rpc(
        'get_top_mvp_votes',
        params: {
          'match_id_param': matchId,
          'limit_param': limit
        }
      );
      
      print('Resultado bruto de la función SQL: $result');
        
      if (result == null) {
        print('No se encontraron resultados (null)');
        return [];
      }
        // Transformar el resultado para que coincida con el formato esperado
      final List<Map<String, dynamic>> formattedResult = [];
      for (var vote in result) {
        print('Datos crudos del jugador: $vote'); // Debug
        
        // Imprimir cada campo individualmente para diagnosticar
        print(' - voted_player_id: ${vote['voted_player_id']}');
        print(' - vote_count: ${vote['vote_count']}');
        print(' - team: ${vote['team']}');
        print(' - player_name: ${vote['player_name']}');
        print(' - foto_url: ${vote['foto_url']}');
          // Asegurarnos de que todos los campos necesarios estén presentes
        Map<String, dynamic> playerData = {
          'voted_player_id': vote['voted_player_id'],
          'vote_count': vote['vote_count'],
          'team': vote['team'],
          'player_name': vote['player_name'] ?? 'Jugador Sin Nombre', // Nombre por defecto si es nulo
          'foto_url': vote['foto_url'],
          // Add aliases for backward compatibility, but our primary fix is to use the correct field names
          'nombre': vote['player_name'] ?? 'Jugador Sin Nombre',
          'votes': vote['vote_count']
        };
        
        // Imprimir el objeto formateado para diagnosticar
        print('Objeto formateado para la UI: $playerData');
        
        formattedResult.add(playerData);
      }
      
      print('Jugadores más votados encontrados: ${formattedResult.length}');
      for (var player in formattedResult) {
        print('Jugador: ${player['player_name']}, Votos: ${player['vote_count']}, Equipo: ${player['team']}');
      }      
      return formattedResult;
    } catch (e) {
      print('Error al obtener los mejores jugadores: $e');
      return [];
    }
  }
    /// Finaliza la votación y establece los MVPs basados en los votos
  Future<Map<String, String?>> finishVotingAndSetMVPs(int matchId) async {
    try {      // Verificar que existe una votación activa
      final activeVoting = await supabase
          .from('mvp_voting_status')
          .select()
          .eq('match_id', matchId)
          .eq('status', 'active')
          .maybeSingle();
          
      if (activeVoting == null) {
        print('No hay votación activa para finalizar');
        return {'mvp_team_claro': null, 'mvp_team_oscuro': null};
      }

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
      }      // Actualizar el estado de la votación a completado
      await supabase
          .from('mvp_voting_status')
          .update({'status': 'completed'})
          .eq('id', activeVoting['id']);
      
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
      
      print('Verificando votación expirada: match_id=$matchId, expires=${activeVoting['voting_ends_at']}, isExpired=$isExpired');
      
      if (isExpired) {
        print('La votación para el partido $matchId ha expirado. Finalizando automáticamente...');
        final results = await finishVotingAndSetMVPs(matchId);
        print('Resultados de la votación finalizada: $results');
        return true;
      }
      
      return false;
    } catch (e) {
      print('Error al verificar votación expirada: $e');
      return false;
    }
  }
  
  /// Finaliza manualmente una votación de MVP antes de tiempo
  Future<bool> finishVotingManually(int matchId) async {
    try {
      // Verificar que el usuario esté autenticado
      final currentUserId = supabase.auth.currentUser?.id;
      if (currentUserId == null) {
        Fluttertoast.showToast(
          msg: "Debes iniciar sesión para finalizar la votación",
          backgroundColor: Colors.red,
        );
        return false;
      }
      
      // Verificar que la votación esté activa
      final activeVoting = await getActiveVoting(matchId);
      if (activeVoting == null) {
        Fluttertoast.showToast(
          msg: "No hay votación activa para finalizar",
          backgroundColor: Colors.red,
        );
        return false;
      }
      
      // Verificar que el usuario que intenta finalizar sea el creador de la votación
      if (activeVoting['created_by'] != currentUserId) {
        // Verificar si es el creador del partido
        final matchData = await supabase
            .from('matches')
            .select('creador_id')
            .eq('id', matchId)
            .single();
        
        if (matchData['creador_id'] != currentUserId) {
          Fluttertoast.showToast(
            msg: "Solo el creador del partido o de la votación puede finalizarla",
            backgroundColor: Colors.red,
          );
          return false;
        }
      }
      
      // Finalizar la votación y asignar MVPs
      await finishVotingAndSetMVPs(matchId);
      
      Fluttertoast.showToast(
        msg: "Votación finalizada manualmente",
        backgroundColor: Colors.green,
      );
      
      return true;
    } catch (e) {
      print('Error al finalizar votación manualmente: $e');
      Fluttertoast.showToast(
        msg: "Error al finalizar la votación: $e",
        backgroundColor: Colors.red,
      );
      return false;
    }  }
  
  /// Resetea una votación de MVP y elimina todos los datos relacionados
  /// Este método borra todos los votos existentes, el estado de la votación y los resultados de MVP
  /// Solamente el creador del partido puede ejecutar esta acción
  Future<bool> resetMVPVoting(int matchId) async {
    try {
      // Verificar que el usuario esté autenticado
      final currentUserId = supabase.auth.currentUser?.id;
      if (currentUserId == null) {
        Fluttertoast.showToast(
          msg: "Debes iniciar sesión para rehacer la votación",
          backgroundColor: Colors.red,
        );
        return false;
      }
      
      // Verificar que el usuario sea el creador del partido
      final matchData = await supabase
          .from('matches')
          .select('creador_id, nombre')
          .eq('id', matchId)
          .single();
      
      if (matchData['creador_id'] != currentUserId) {
        Fluttertoast.showToast(
          msg: "Solo el creador del partido puede rehacer la votación",
          backgroundColor: Colors.red,
        );
        return false;
      }
        // Primero eliminamos los votos actuales directamente
      await supabase
        .from('mvp_votes')
        .delete()
        .eq('match_id', matchId);
          // Eliminamos cualquier registro de votación existente para este partido
      // En lugar de intentar cambiar el estado, eliminamos el registro por completo
      await supabase
        .from('mvp_voting_status')
        .delete()
        .eq('match_id', matchId);
        
      // Eliminamos los MVPs del partido
      await supabase
        .from('matches')
        .update({
          'mvp_team_claro': null,
          'mvp_team_oscuro': null
        })
        .eq('id', matchId);
          // Finalmente ejecutamos la función RPC por compatibilidad 
      // (en caso de que haya lógica adicional en el lado del servidor)
      await supabase.rpc(
        'reset_mvp_votes',
        params: {
          'match_id_param': matchId
        }
      );

      // Notificar a los participantes
      final matchName = matchData['nombre'] ?? 'Partido';
      await _notificationService.notifyMatchParticipants(
        matchId: matchId,
        title: 'Votación de MVP reiniciada',
        message: 'La votación para MVP del partido $matchName ha sido reiniciada por el organizador.',
        actionType: 'mvp_voting_reset',
      );
      
      Fluttertoast.showToast(
        msg: "Votación reiniciada correctamente",
        backgroundColor: Colors.green,
      );
      
      return true;
    } catch (e) {
      print('Error al rehacer votación de MVP: $e');
      Fluttertoast.showToast(
        msg: "Error al rehacer la votación: $e",
        backgroundColor: Colors.red,
      );
      return false;
    }
  }
}
