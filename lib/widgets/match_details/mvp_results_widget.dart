import 'package:flutter/material.dart';

/// Widget para mostrar los resultados de la votación de MVPs
class MVPResultsWidget extends StatelessWidget {
  final Map<String, dynamic> playerDataClaro;
  final Map<String, dynamic> playerDataOscuro;
  
  const MVPResultsWidget({
    Key? key,
    required this.playerDataClaro,
    required this.playerDataOscuro,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.shade900, Colors.blue.shade900],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildPlayerCard(playerDataClaro, 'Claro')),
              SizedBox(width: 16),
              Expanded(child: _buildPlayerCard(playerDataOscuro, 'Oscuro')),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.emoji_events, color: Colors.amber, size: 28),
        SizedBox(width: 8),
        Text(
          'MVPs DEL PARTIDO',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
  
  Widget _buildPlayerCard(Map<String, dynamic> playerData, String team) {
    final bool hasPlayer = playerData.isNotEmpty;
    final String playerName = hasPlayer ? playerData['nombre'] ?? 'Desconocido' : 'No hay MVP';
    final String? photoUrl = hasPlayer ? playerData['foto_url'] : null;
    
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: team == 'Claro' ? Colors.blue.shade800 : Colors.blue.shade900,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            'MVP Equipo $team',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 12),
          _buildPlayerAvatar(photoUrl),
          SizedBox(height: 12),
          Text(
            playerName,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (hasPlayer) ...[
            SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.star,
                  color: Colors.amber,
                  size: 16,
                ),
                SizedBox(width: 4),
                Text(
                  'Votado por la mayoría',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildPlayerAvatar(String? photoUrl) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.amber.withOpacity(0.8),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 8,
          ),
        ],
      ),
      child: ClipOval(
        child: photoUrl != null && photoUrl.isNotEmpty 
          ? Image.network(
              photoUrl,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  color: Colors.grey.shade800,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: Colors.amber,
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey.shade800,
                  child: Icon(
                    Icons.person,
                    size: 40,
                    color: Colors.white70,
                  ),
                );
              },
            )
          : Container(
              color: Colors.grey.shade800,
              child: Icon(
                Icons.person,
                size: 40,
                color: Colors.white70,
              ),
            ),
      ),
    );
  }
}
