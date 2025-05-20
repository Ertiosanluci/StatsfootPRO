import 'package:flutter/material.dart';
import 'dart:math' as math;

class MVPResultsRevealScreen extends StatefulWidget {
  final int matchId;
  final String matchName;
  final List<Map<String, dynamic>> topPlayers;
  final Map<String, dynamic> mvpClaroData;
  final Map<String, dynamic> mvpOscuroData;

  const MVPResultsRevealScreen({
    Key? key,
    required this.matchId,
    required this.matchName,
    required this.topPlayers,
    required this.mvpClaroData,
    required this.mvpOscuroData,
  }) : super(key: key);

  @override
  State<MVPResultsRevealScreen> createState() => _MVPResultsRevealScreenState();
}

class _MVPResultsRevealScreenState extends State<MVPResultsRevealScreen> with TickerProviderStateMixin {
  late final AnimationController _revealController;
  late final Animation<double> _revealAnimation;
  
  bool _isRevealed = false;
  List<bool> _isPlayerRevealed = [false, false, false];

  @override
  void initState() {
    super.initState();
    
    // Add debug logging for the data received
    print('MVPResultsReveal - Received topPlayers: ${widget.topPlayers}');
    for (int i = 0; i < widget.topPlayers.length; i++) {
      final player = widget.topPlayers[i];
      print('Player $i: player_name=${player["player_name"]}, vote_count=${player["vote_count"]}, foto_url=${player["foto_url"]}');
    }
    
    // Animation controller for the initial reveal animation
    _revealController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _revealAnimation = CurvedAnimation(
      parent: _revealController,
      curve: Curves.easeInOutBack,
    );
  }

  @override
  void dispose() {
    _revealController.dispose();
    super.dispose();
  }

  void _onRevealButtonPressed() {
    setState(() {
      _isRevealed = true;
    });
    _revealController.forward();
  }

  void _onPlayerCardTap(int index) {
    if (!_isPlayerRevealed[index]) {
      setState(() {
        _isPlayerRevealed[index] = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade900,
      appBar: AppBar(
        title: Text('Resultados MVP: ${widget.matchName}'),
        backgroundColor: Colors.blue.shade800,
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade900, Colors.purple.shade900],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: _isRevealed
              ? _buildRevealedContent()
              : _buildInitialContent(),
        ),
      ),
    );
  }

  Widget _buildInitialContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Trophy icon with glow effect
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.amber.withOpacity(0.2),
            boxShadow: [
              BoxShadow(
                color: Colors.amber.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Icon(
            Icons.emoji_events,
            color: Colors.amber,
            size: 70,
          ),
        ),
        const SizedBox(height: 40),
        // Circular button
        GestureDetector(
          onTap: _onRevealButtonPressed,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Colors.amber.shade600, Colors.orange.shade700],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.withOpacity(0.4),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Center(
              child: Text(
                'Revelar\nResultados',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRevealedContent() {
    return AnimatedBuilder(
      animation: _revealAnimation,
      builder: (context, child) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildHeader(),
              SizedBox(height: 30),
              ...List.generate(
                math.min(widget.topPlayers.length, 3),
                (index) => Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: Transform.translate(
                    offset: Offset(
                      0, 
                      50 * (1 - _revealAnimation.value) * (index + 1)
                    ),
                    child: Opacity(
                      opacity: _revealAnimation.value,
                      child: _buildPlayerCard(index),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Icon(
          Icons.emoji_events,
          color: Colors.amber,
          size: 40,
        ),
        SizedBox(height: 8),
        Text(
          'TOP JUGADORES MVP',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Pulsa en cada tarjeta para revelar',
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildPlayerCard(int index) {    final Map<String, dynamic> playerData = index < widget.topPlayers.length
        ? widget.topPlayers[index]
        : {"player_name": "Sin datos", "foto_url": null, "vote_count": 0};
    
    // Using player_name and vote_count instead of nombre and votes
    final String playerName = playerData["player_name"] ?? "Sin nombre";
    final String? photoUrl = playerData["foto_url"];
    final int votes = playerData["vote_count"] ?? 0;
    final String position = index == 0 ? "1er" : index == 1 ? "2do" : "3er";

    return GestureDetector(
      onTap: () => _onPlayerCardTap(index),
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: LinearGradient(
            colors: index == 0
                ? [Colors.amber.shade600, Colors.amber.shade800]
                : index == 1
                    ? [Colors.grey.shade300, Colors.grey.shade500]
                    : [Colors.brown.shade400, Colors.brown.shade600],
          ),
          boxShadow: [
            BoxShadow(
              color: (index == 0
                  ? Colors.amber
                  : index == 1
                      ? Colors.grey
                      : Colors.brown)
                  .withOpacity(0.5),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          switchInCurve: Curves.easeInOutBack,
          child: _isPlayerRevealed[index]
              ? _buildRevealedPlayerContent(playerName, photoUrl, votes, position)
              : _buildHiddenPlayerContent(position),
        ),
      ),
    );
  }

  Widget _buildHiddenPlayerContent(String position) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.lock,
          color: Colors.white,
          size: 28,
        ),
        SizedBox(width: 8),
        Text(
          '$position Lugar',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(width: 8),
        Text(
          'Pulsa para revelar',
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 14,
          ),
        ),
      ],
    );
  }
  Widget _buildRevealedPlayerContent(
      String playerName, String? photoUrl, int votes, String position) {
    // Debug log to verify data being passed to this method
    print('Rendering player card: name=$playerName, votes=$votes, position=$position, photoUrl=$photoUrl');
        
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          _buildPlayerAvatar(photoUrl),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  playerName.isNotEmpty ? playerName : "Jugador Sin Nombre",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.star,
                      color: Colors.white,
                      size: 16,
                    ),
                    SizedBox(width: 4),
                    Text(
                      votes.toString() + ' votos',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              position,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerAvatar(String? photoUrl) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withOpacity(0.8),
          width: 2,
        ),
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
                        color: Colors.white,
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey.shade800,
                    child: Icon(
                      Icons.person,
                      size: 30,
                      color: Colors.white70,
                    ),
                  );
                },
              )
            : Container(
                color: Colors.grey.shade800,
                child: Icon(
                  Icons.person,
                  size: 30,
                  color: Colors.white70,
                ),
              ),
      ),
    );
  }
}
