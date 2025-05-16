import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/mvp_voting_service.dart';

/// Clase para testear el sistema de votación de MVP
/// Esta clase contiene métodos que puedes llamar desde la UI para probar las diferentes funcionalidades
class MVPVotingTester {
  final MVPVotingService _mvpService = MVPVotingService();
  
  /// Test que comprueba el flujo completo de votación
  Future<void> testVotingFlow(int matchId, BuildContext context) async {
    try {
      // 1. Crear una instancia de Scaffold Messenger para mostrar mensajes
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      
      // 2. Iniciar una votación de prueba (2 minutos)
      final votingStarted = await _mvpService.startMVPVoting(matchId, votingDurationHours: 0); // 0 para que sea muy rápido
      
      if (votingStarted) {
        scaffoldMessenger.showSnackBar(SnackBar(
          content: Text('Test: Votación iniciada correctamente'),
          backgroundColor: Colors.green,
        ));
        
        // 3. Verificar que la votación está activa
        final activeVoting = await _mvpService.getActiveVoting(matchId);
        
        if (activeVoting == null) {
          scaffoldMessenger.showSnackBar(SnackBar(
            content: Text('Test fallido: No se encontró la votación activa'),
            backgroundColor: Colors.red,
          ));
          return;
        }
        
        scaffoldMessenger.showSnackBar(SnackBar(
          content: Text('Test: Votación activa encontrada'),
          backgroundColor: Colors.green,
        ));
        
        // 4. Simular algunos votos (si tenemos más de un usuario disponible)
        // Esto normalmente ocurriría por la interacción del usuario
        final currentUser = Supabase.instance.client.auth.currentUser;
        if (currentUser != null) {
          // Auto-voto de prueba
          final votedClaro = await _mvpService.voteForMVP(
            matchId: matchId,
            votedPlayerId: currentUser.id,
            team: 'claro',
          );
          
          if (votedClaro) {
            scaffoldMessenger.showSnackBar(SnackBar(
              content: Text('Test: Voto registrado para equipo claro'),
              backgroundColor: Colors.green,
            ));
          }
        }
        
        // 5. Finalizar la votación manualmente (sin esperar)
        final results = await _mvpService.finishVotingAndSetMVPs(matchId);
        
        if (results['mvp_team_claro'] != null || results['mvp_team_oscuro'] != null) {
          scaffoldMessenger.showSnackBar(SnackBar(
            content: Text('Test: MVPs establecidos correctamente'),
            backgroundColor: Colors.green,
          ));
        } else {
          scaffoldMessenger.showSnackBar(SnackBar(
            content: Text('Test: No se pudieron establecer los MVPs'),
            backgroundColor: Colors.amber,
          ));
        }
        
        // 6. Verificar que la votación ya no está activa
        final noActiveVoting = await _mvpService.getActiveVoting(matchId);
        
        if (noActiveVoting == null) {
          scaffoldMessenger.showSnackBar(SnackBar(
            content: Text('Test completo: Sistema de votación funciona correctamente'),
            backgroundColor: Colors.green,
          ));
        } else {
          scaffoldMessenger.showSnackBar(SnackBar(
            content: Text('Test fallido: La votación sigue activa después de finalizar'),
            backgroundColor: Colors.red,
          ));
        }
      } else {
        scaffoldMessenger.showSnackBar(SnackBar(
          content: Text('Test fallido: No se pudo iniciar la votación'),
          backgroundColor: Colors.red,
        ));
      }
    } catch (e) {
      print('Error al realizar test de votación: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error en test: $e'),
        backgroundColor: Colors.red,
      ));
    }
  }
}
