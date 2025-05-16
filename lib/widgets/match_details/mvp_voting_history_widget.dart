import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
      final votingStatus = await Supabase.instance.client
          .from('mvp_voting_status')
          .select()
          .eq('match_id', widget.matchId)
          .order('voting_started_at', ascending: false);
      
      if (votingStatus != null) {
        // Para cada votación, obtener información adicional
        for (var voting in votingStatus) {
          // Obtener información del creador
          String creatorName = "Desconocido";
          if (voting['created_by'] != null) {
            final creator = await Supabase.instance.client
                .from('users_profiles')
                .select('nombre')
                .eq('user_id', voting['created_by'])
                .maybeSingle();
                
            if (creator != null) {
              creatorName = creator['nombre'] ?? "Desconocido";
            }
          }
          
          // Contar los votos totales para esta votación
          final votesCount = await Supabase.instance.client
              .from('mvp_votes')
              .select('id')
              .eq('match_id', widget.matchId)
              .count();
          
          int totalVotes = votesCount.count ?? 0;
          
          // Añadir la información completa al historial
          _votingHistory.add({
            ...voting,
            'creator_name': creatorName,
            'total_votes': totalVotes,
          });
        }
      }
      
      setState(() => _isLoading = false);
    } catch (e) {
      print('Error al cargar historial de votaciones: $e');
      setState(() => _isLoading = false);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(
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
      physics: NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final voting = _votingHistory[index];
        final startDate = DateTime.parse(voting['voting_started_at']);
        final endDate = DateTime.parse(voting['voting_ends_at']);
        final isCompleted = voting['status'] == 'completed';
        
        return Card(
          margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          color: Colors.blueGrey.shade800,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: EdgeInsets.all(16),
            title: Row(
              children: [
                Icon(
                  isCompleted ? Icons.check_circle : Icons.access_time,
                  color: isCompleted ? Colors.green : Colors.amber,
                ),
                SizedBox(width: 8),
                Text(
                  isCompleted ? 'Votación Completada' : 'Votación Activa',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 8),
                Text(
                  'Iniciada por: ${voting['creator_name']}',
                  style: TextStyle(
                    color: Colors.white70,
                  ),
                ),
                Text(
                  'Comenzó: ${_formatDate(startDate)}',
                  style: TextStyle(
                    color: Colors.white70,
                  ),
                ),
                Text(
                  'Finalizó: ${isCompleted ? _formatDate(endDate) : "En curso"}',
                  style: TextStyle(
                    color: Colors.white70,
                  ),
                ),
                SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade900,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Votos totales: ${voting['total_votes']}',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  /// Formato de fecha legible
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
