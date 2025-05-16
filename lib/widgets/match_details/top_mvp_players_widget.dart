import 'package:flutter/material.dart';

/// Widget para mostrar el top 3 de jugadores más votados como MVP
class TopMVPPlayersWidget extends StatelessWidget {
  final List<Map<String, dynamic>> topPlayers;
  final bool isLoading;
  
  const TopMVPPlayersWidget({
    Key? key,
    required this.topPlayers,
    this.isLoading = false,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildLoadingState();
    }
    
    if (topPlayers.isEmpty) {
      return _buildEmptyState();
    }
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      elevation: 3,
      color: Colors.blueGrey.shade900,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.amber.withOpacity(0.5), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.emoji_events, color: Colors.amber, size: 20),
                SizedBox(width: 8),
                Text(
                  'TOP 3 JUGADORES MÁS VOTADOS',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const Divider(color: Colors.amber, height: 20, thickness: 0.5),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: topPlayers.length,
              itemBuilder: (context, index) {
                final player = topPlayers[index];
                final playerName = player['player_name'] ?? 'Jugador';
                final isTeamClaro = player['team'] == 'claro';
                final teamColor = isTeamClaro ? Colors.blue.shade600 : Colors.red.shade600;
                final position = index + 1;
                final votes = player['vote_count'] ?? 0;
                final medal = _getMedalIcon(position);
                
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: _getMedalColor(position),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            position.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      medal,
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              playerName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            Text(
                              isTeamClaro ? 'Equipo Claro' : 'Equipo Oscuro',
                              style: TextStyle(
                                color: teamColor,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.amber.withOpacity(0.5), width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.how_to_vote, color: Colors.amber, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              votes.toString(),
                              style: const TextStyle(
                                color: Colors.amber,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildLoadingState() {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      elevation: 3,
      color: Colors.blueGrey.shade900,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: Column(
            children: [
              CircularProgressIndicator(color: Colors.amber),
              SizedBox(height: 8),
              Text(
                'Cargando resultados...',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      elevation: 3,
      color: Colors.blueGrey.shade900,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.emoji_events_outlined, color: Colors.amber, size: 32),
              SizedBox(height: 8),
              Text(
                'No hay resultados de votación',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text(
                'Los jugadores más votados aparecerán aquí cuando finalice la votación',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
    Icon _getMedalIcon(int position) {
    switch (position) {
      case 1:
        return const Icon(Icons.workspace_premium, color: Colors.amber, size: 20);
      case 2:
        return Icon(Icons.workspace_premium, color: Colors.grey.shade300, size: 20);
      case 3:
        return Icon(Icons.workspace_premium, color: Colors.brown.shade300, size: 20);
      default:
        return const Icon(Icons.star, color: Colors.amber, size: 20);
    }
  }
  
  Color _getMedalColor(int position) {
    switch (position) {
      case 1:
        return Colors.amber.shade700;
      case 2:
        return Colors.grey.shade600;
      case 3:
        return Colors.brown.shade600;
      default:
        return Colors.blueGrey;
    }
  }
}
