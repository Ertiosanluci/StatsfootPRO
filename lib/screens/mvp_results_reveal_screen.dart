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
    
    // Log para verificar que se recibieron los datos correctamente
    print('==== MVP RESULTS SCREEN DATA ====');
    print('Top Players recibidos: ${widget.topPlayers.length}');
    for (var i = 0; i < widget.topPlayers.length; i++) {
      print('Top Player ${i+1}: ${widget.topPlayers[i]['nombre']}');
    }
    print('MVP Claro: ${widget.mvpClaroData['nombre'] ?? "No disponible"}');
    print('MVP Oscuro: ${widget.mvpOscuroData['nombre'] ?? "No disponible"}');
    print('================================');
    
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
    // Añadir animación de pulsación al botón
    Future.delayed(const Duration(milliseconds: 150), () {
      setState(() {
        _isRevealed = true;
      });
      // Reproducir la animación con efecto de rebote
      _revealController.forward();
    });
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
        title: Text(
          widget.matchName,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue.shade800,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white), // Flecha de atrás en blanco
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
          child: const Icon(
            Icons.emoji_events,
            color: Colors.amber,
            size: 70,
          ),
        ),
        const SizedBox(height: 40),
        // Circular button with press animation
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 1.0, end: 1.05),
          duration: const Duration(milliseconds: 1000),
          builder: (context, value, child) {
            return Transform.scale(
              scale: 1.0 + (value - 1.0) * 0.05 * math.sin(value * 3 * math.pi),
              child: child,
            );
          },
          child: GestureDetector(
            onTap: _onRevealButtonPressed,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
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
              child: const Center(
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
        ),
        // Instrucción sutil al usuario
        const SizedBox(height: 20),
        Text(
          'Pulsa para descubrir los MVPs',
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 14,
          ),
        ),
        // Añadir indicador de número de jugadores
        const SizedBox(height: 30),
        Card(
          color: Colors.blue.shade800.withOpacity(0.7),
          elevation: 4,
          margin: const EdgeInsets.symmetric(horizontal: 30),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.people, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Jugadores destacados: ${widget.topPlayers.length}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                ),
              ],
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

  Widget _buildPlayerCard(int index) {
    final Map<String, dynamic> playerData = index < widget.topPlayers.length
        ? widget.topPlayers[index]
        : {
            "nombre": "Sin datos",
            "foto_url": null,
            "vote_count": 0
          };
    
    final String playerName = playerData["nombre"] ?? "Sin nombre";
    final String? photoUrl = playerData["foto_url"];
    final int votes = playerData["vote_count"]?.toInt() ?? 0;
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
                  playerName,
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
                      '$votes votos',
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
