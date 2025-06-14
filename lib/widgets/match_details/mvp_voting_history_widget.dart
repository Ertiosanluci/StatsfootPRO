import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

/// Widget para mostrar el historial de votaciones de MVP
class MVPVotingHistoryWidget extends StatefulWidget {
  final int matchId;
  
  const MVPVotingHistoryWidget({
    Key? key,
    required this.matchId,
  }) : super(key: key);
  
  @override
  _MVPVotingHistoryWidgetState createState() => _MVPVotingHistoryWidgetState();
}

class _MVPVotingHistoryWidgetState extends State<MVPVotingHistoryWidget> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _votingHistory = [];
  final SupabaseClient _supabase = Supabase.instance.client;
  
  @override
  void initState() {
    super.initState();
    _loadVotingHistory();
  }
  
  /// Cargar el historial de votaciones para este partido
  Future<void> _loadVotingHistory() async {
    try {
      setState(() => _isLoading = true);
      
      // Consultar la tabla de estado de votaciones
      final votingStatus = await _supabase
          .from('mvp_voting_status')
          .select()
          .eq('match_id', widget.matchId)
          .order('voting_started_at', ascending: false);
      
      if (votingStatus.isNotEmpty) {
        // Limpiar historial previo
        _votingHistory = [];
        
        // Para cada votación, obtener información adicional
        for (var voting in votingStatus) {
          // Obtener información del creador
          String creatorName = "Desconocido";
          if (voting['created_by'] != null) {
            final creator = await _supabase
                .from('users_profiles')
                .select('nombre')
                .eq('user_id', voting['created_by'])
                .maybeSingle();
                
            if (creator != null) {
              creatorName = creator['nombre'] ?? "Desconocido";
            }
          }
          
          // Obtener los votos de esta votación específica
          final votingEndDate = DateTime.parse(voting['voting_ends_at']);
          final votingStartDate = DateTime.parse(voting['voting_started_at']);
          
          // Consultar todos los votos para esta sesión de votación específica
          final votesBySession = await _supabase
              .from('mvp_votes')
              .select('''
                id, 
                voter_id, 
                voted_player_id, 
                team, 
                created_at
              ''')
              .eq('match_id', widget.matchId)
              .gte('created_at', votingStartDate.toIso8601String())
              .lte('created_at', votingEndDate.toIso8601String());
          
          // Procesamiento de votos para mostrar información completa
          List<Map<String, dynamic>> processedVotes = [];
          if (votesBySession != null && votesBySession.isNotEmpty) {
            for (var vote in votesBySession) {
              // Obtener nombre del votante
              final voterProfile = await _supabase
                  .from('users_profiles')
                  .select('nombre')
                  .eq('user_id', vote['voter_id'])
                  .maybeSingle();
                  
              String voterName = voterProfile != null 
                  ? voterProfile['nombre'] ?? "Anónimo" 
                  : "Anónimo";
              
              // Obtener nombre del jugador votado
              final playerName = await _getPlayerName(vote['voted_player_id']);
              
              processedVotes.add({
                ...vote,
                'voter_name': voterName,
                'player_name': playerName,
              });
            }
          }
          
          // Añadir la información completa al historial
          _votingHistory.add({
            ...voting,
            'creator_name': creatorName,
            'total_votes': processedVotes.length,
            'votes': processedVotes,
          });
        }
      }
      
      setState(() => _isLoading = false);
    } catch (e) {
      print('Error al cargar historial de votaciones: $e');
      setState(() => _isLoading = false);
    }
  }
  
  /// Obtener el nombre del jugador a partir de su ID
  Future<String> _getPlayerName(String playerId) async {
    try {
      final player = await _supabase
          .from('players')
          .select('nombre')
          .eq('id', playerId)
          .maybeSingle();
          
      return player != null ? player['nombre'] ?? "Jugador desconocido" : "Jugador desconocido";
    } catch (e) {
      print('Error al obtener nombre del jugador: $e');
      return "Jugador desconocido";
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    
    if (_votingHistory.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'No hay historial de votaciones para este partido',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    
    return ListView.builder(
      itemCount: _votingHistory.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final voting = _votingHistory[index];
        final startDate = DateTime.parse(voting['voting_started_at']);
        final endDate = DateTime.parse(voting['voting_ends_at']);
        final isCompleted = voting['status'] == 'completed';
        final List<dynamic> votes = voting['votes'] ?? [];
        
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          color: Colors.blueGrey.shade800,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ExpansionTile(
            collapsedIconColor: Colors.white,
            iconColor: Colors.amber,
            backgroundColor: Colors.transparent,
            collapsedBackgroundColor: Colors.transparent,
            tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            title: Row(
              children: [
                Icon(
                  isCompleted ? Icons.check_circle : Icons.access_time,
                  color: isCompleted ? Colors.green : Colors.amber,
                ),
                const SizedBox(width: 8),
                Text(
                  isCompleted ? 'Votación Completada' : 'Votación Activa',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text(
                  'Iniciada por: ${voting['creator_name']}',
                  style: const TextStyle(
                    color: Colors.white70,
                  ),
                ),
                Text(
                  'Comenzó: ${_formatDate(startDate)}',
                  style: const TextStyle(
                    color: Colors.white70,
                  ),
                ),
                Text(
                  'Finalizó: ${isCompleted ? _formatDate(endDate) : "En curso"}',
                  style: const TextStyle(
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade900,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Votos totales: ${votes.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            children: [
              const Divider(color: Colors.white24),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Detalle de Votos',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
              votes.isEmpty 
              ? const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    'No hay votos registrados en esta sesión',
                    style: TextStyle(color: Colors.white70, fontStyle: FontStyle.italic),
                    textAlign: TextAlign.center,
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: votes.length,
                  itemBuilder: (context, voteIndex) {
                    final vote = votes[voteIndex];
                    return ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      leading: CircleAvatar(
                        backgroundColor: vote['team'] == 'claro' ? Colors.white.withOpacity(0.8) : Colors.black.withOpacity(0.8),
                        child: Text(
                          (voteIndex + 1).toString(),
                          style: TextStyle(
                            color: vote['team'] == 'claro' ? Colors.black : Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        '${vote['player_name']}',
                        style: const TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        'Votado por: ${vote['voter_name']}',
                        style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
                      ),
                      trailing: Text(
                        DateFormat('dd/MM HH:mm').format(DateTime.parse(vote['created_at'])),
                        style: TextStyle(color: Colors.amber.withOpacity(0.8), fontSize: 12),
                      ),
                    );
                  },
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
  
  /// Formato de fecha legible
  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }
}
