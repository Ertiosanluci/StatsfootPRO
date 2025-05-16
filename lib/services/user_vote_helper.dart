import 'package:supabase_flutter/supabase_flutter.dart';

/// Clase helper para manejar y verificar votos de usuarios
class UserVoteHelper {
  final SupabaseClient supabase = Supabase.instance.client;
  
  /// Verifica si el usuario actual ya ha votado en un partido específico
  Future<Map<String, String?>> getUserCurrentVotes(int matchId) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        return {
          'claro': null,
          'oscuro': null,
        };
      }
      
      // Buscar votos del equipo claro
      final votesClaro = await supabase
        .from('mvp_votes')
        .select('voted_player_id')
        .eq('match_id', matchId)
        .eq('voter_id', userId)
        .eq('team', 'claro')
        .maybeSingle();
        
      // Buscar votos del equipo oscuro
      final votesOscuro = await supabase
        .from('mvp_votes')
        .select('voted_player_id')
        .eq('match_id', matchId)
        .eq('voter_id', userId)
        .eq('team', 'oscuro')
        .maybeSingle();
      
      return {
        'claro': votesClaro != null ? votesClaro['voted_player_id'] : null,
        'oscuro': votesOscuro != null ? votesOscuro['voted_player_id'] : null,
      };
    } catch (e) {
      print('Error al verificar votos del usuario: $e');
      return {
        'claro': null,
        'oscuro': null,
      };
    }
  }
  
  /// Obtiene las estadísticas de votación para un partido
  Future<Map<String, dynamic>> getVotingStats(int matchId) async {
    try {
      // Total de votos en el equipo claro
      final totalClaroVotes = await supabase
        .from('mvp_votes')
        .select('id')
        .eq('match_id', matchId)
        .eq('team', 'claro')
        .count();
      
      // Total de votos en el equipo oscuro
      final totalOscuroVotes = await supabase
        .from('mvp_votes')
        .select('id')
        .eq('match_id', matchId)
        .eq('team', 'oscuro')
        .count();
      
      // Total de participantes que han votado (usuarios únicos)
      final uniqueVoters = await supabase.rpc(
        'get_unique_voters_count',
        params: {
          'match_id_param': matchId
        }
      );
      
      return {
        'total_claro_votes': totalClaroVotes.count ?? 0,
        'total_oscuro_votes': totalOscuroVotes.count ?? 0,
        'unique_voters': uniqueVoters[0]['count'] ?? 0,
      };
    } catch (e) {
      print('Error al obtener estadísticas de votación: $e');
      return {
        'total_claro_votes': 0,
        'total_oscuro_votes': 0,
        'unique_voters': 0,
      };
    }
  }
}
