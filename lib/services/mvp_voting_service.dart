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
        title: '¡Votación de MVPs iniciada!',
        message: 'La votación para MVP del partido $matchName está abierta por $votingDurationHours horas. ¡Vota ahora!',
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
      
      // Verificar si el usuario ya ha votado para este equipo
      final existingVote = await supabase
          .from('mvp_votes')
          .select()
          .eq('match_id', matchId)
          .eq('voter_id', currentUserId)
          .eq('team', team)
          .maybeSingle();
          
      if (existingVote != null) {
        // Actualizar voto existente
        await supabase
            .from('mvp_votes')
            .update({'voted_player_id': votedPlayerId})
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
    /// Finaliza la votación y establece los MVPs basados en los votos
  Future<Map<String, String?>> finishVotingAndSetMVPs(int matchId) async {
    try {
      // Obtener el recuento de votos para el equipo claro
      final votesClaroResult = await supabase.rpc(
        'count_mvp_votes',
        params: {
          'match_id_param': matchId,
          'team_param': 'claro'
        }
      );
      
      // Obtener el recuento de votos para el equipo oscuro
      final votesOscuroResult = await supabase.rpc(
        'count_mvp_votes',
        params: {
          'match_id_param': matchId,
          'team_param': 'oscuro'
        }
      );
      
      String? mvpClaroId;
      String? mvpOscuroId;
      
      // Determinar MVP del equipo claro
      if (votesClaroResult != null && votesClaroResult.isNotEmpty) {
        mvpClaroId = votesClaroResult[0]['voted_player_id'];
      }
      
      // Determinar MVP del equipo oscuro
      if (votesOscuroResult != null && votesOscuroResult.isNotEmpty) {
        mvpOscuroId = votesOscuroResult[0]['voted_player_id'];
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
      
      // Obtener información del partido y de los MVP para la notificación
      final matchData = await supabase
          .from('matches')
          .select('nombre')
          .eq('id', matchId)
          .single();
      
      final matchName = matchData['nombre'] ?? 'Partido';
      
      // Obtener nombres de los MVP
      String mvpClaroNombre = "Sin MVP";
      String mvpOscuroNombre = "Sin MVP";
      
      if (mvpClaroId != null) {
        final userClaroData = await supabase
            .from('users_profiles')
            .select('nombre')
            .eq('user_id', mvpClaroId)
            .maybeSingle();
            
        if (userClaroData != null) {
          mvpClaroNombre = userClaroData['nombre'] ?? "Jugador Claro";
        }
      }
      
      if (mvpOscuroId != null) {
        final userOscuroData = await supabase
            .from('users_profiles')
            .select('nombre')
            .eq('user_id', mvpOscuroId)
            .maybeSingle();
            
        if (userOscuroData != null) {
          mvpOscuroNombre = userOscuroData['nombre'] ?? "Jugador Oscuro";
        }
      }
      
      // Enviar notificaciones con los resultados
      await _notificationService.notifyMatchParticipants(
        matchId: matchId,
        title: '¡Votación de MVPs finalizada!',
        message: 'Los MVPs del partido $matchName son: $mvpClaroNombre (Equipo Claro) y $mvpOscuroNombre (Equipo Oscuro)',
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
