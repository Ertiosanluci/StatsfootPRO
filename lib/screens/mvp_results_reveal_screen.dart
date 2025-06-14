import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;

/// Enum para las posiciones de los triángulos en la pantalla
enum TrianglePosition {
  top,
  bottomLeft,
  bottomRight,
  revealButton, // Nueva posición para el botón de revelar
}

/// Clipper personalizado para recortar widgets en forma de triángulo
class TriangleClipper extends CustomClipper<Path> {
  final TrianglePosition position;
  final double size;
  
  const TriangleClipper({
    required this.position,
    required this.size,
  });
  
  @override
  Path getClip(Size size) {
    final Path path = Path();
    
    switch (position) {
      case TrianglePosition.top:
        // Triángulo superior (apunta hacia abajo) - según el tercer croquis
        path.moveTo(size.width / 2, size.height);
        path.lineTo(0, 0);
        path.lineTo(size.width, 0);
        path.close();
        break;
      case TrianglePosition.bottomLeft:
        // Triángulo inferior izquierdo según el tercer croquis
        // Forma rectangular con diagonal
        path.moveTo(0, 0); // Esquina superior izquierda
        path.lineTo(size.width, size.height); // Esquina inferior derecha
        path.lineTo(0, size.height); // Esquina inferior izquierda
        path.close();
        break;
      case TrianglePosition.bottomRight:
        // Triángulo inferior derecho según el tercer croquis
        // Forma rectangular con diagonal
        path.moveTo(size.width, 0); // Esquina superior derecha
        path.lineTo(size.width, size.height); // Esquina inferior derecha
        path.lineTo(0, size.height); // Esquina inferior izquierda
        path.close();
        break;
      case TrianglePosition.revealButton:
        // Triángulo equilátero con base mirando hacia la derecha (invertido)
        path.moveTo(size.width, size.height / 2); // Punto medio derecho (nueva base)
        path.lineTo(0, 0); // Esquina superior izquierda
        path.lineTo(0, size.height); // Esquina inferior izquierda
        path.close();
        break;
    }
    
    return path;
  }
  
  @override
  bool shouldReclip(TriangleClipper oldClipper) {
    return oldClipper.position != position || oldClipper.size != size;
  }
}

/// Widget principal para la pantalla de revelación de resultados MVP
class MVPResultsRevealScreen extends StatefulWidget {
  final String matchName;
  final List<Map<String, dynamic>> topPlayers;
  
  const MVPResultsRevealScreen({
    Key? key,
    required this.matchName,
    required this.topPlayers,
  }) : super(key: key);
  
  @override
  _MVPResultsRevealScreenState createState() => _MVPResultsRevealScreenState();
}

class _MVPResultsRevealScreenState extends State<MVPResultsRevealScreen> with TickerProviderStateMixin {
  bool _resultsRevealed = false;
  bool _playerInfoVisible = false;
  late AnimationController _revealController;
  late Animation<double> _revealAnimation;
  late List<AnimationController> _playerControllers;
  final Duration _staggerDelay = const Duration(milliseconds: 300);
  
  // Colores utilizados en la pantalla
  final Color _primaryColor = const Color(0xFF1E2761);
  final Color _secondaryColor = const Color(0xFF7A89C2);
  final Color _accentColor = const Color(0xFFFF3A5E);
  final Color _backgroundColor = const Color(0xFF408EC6);
  
  @override
  void initState() {
    super.initState();
    
    // Inicializar controlador de animación principal
    _revealController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _revealAnimation = CurvedAnimation(
      parent: _revealController,
      curve: Curves.easeInOut,
    );
    
    // Inicializar controladores para cada jugador (hasta 3)
    _playerControllers = List.generate(
      math.min(widget.topPlayers.length, 3), 
      (index) => AnimationController(
        duration: const Duration(milliseconds: 500),
        vsync: this,
      ),
    );
  }
  
  @override
  void dispose() {
    _revealController.dispose();
    for (var controller in _playerControllers) {
      controller.dispose();
    }
    super.dispose();
  }
  
  /// Revela los resultados con animaciones escalonadas
  void _revealResults() {
    setState(() {
      _resultsRevealed = true;
    });
    
    _revealController.forward().then((_) {
      setState(() {
        _playerInfoVisible = true;
      });
      
      // Animar cada triángulo de jugador con un retraso escalonado
      for (var i = 0; i < _playerControllers.length; i++) {
        Future.delayed(
          _staggerDelay * i,
          () => _playerControllers[i].forward(),
        );
      }
    });
  }
  
  /// Construye un triángulo para un jugador específico
  Widget _buildPlayerTriangle(int index, TrianglePosition position) {
    final Map<String, dynamic> playerData = widget.topPlayers[index];
    final Color triangleColor = _getPlayerColor(index);
    
    // Ajustar dimensiones según la posición
    double width, height;
    
    switch (position) {
      case TrianglePosition.top:
        // Triángulo del MVP - más grande
        width = MediaQuery.of(context).size.width * 0.9;
        height = MediaQuery.of(context).size.height * 0.4;
        break;
      case TrianglePosition.bottomLeft:
      case TrianglePosition.bottomRight:
        // Triángulos del 2° y 3° lugar - tamaño medio
        width = MediaQuery.of(context).size.width * 0.5;
        height = MediaQuery.of(context).size.height * 0.5;
        break;
      default:
        width = 200;
        height = 200;
    }
    
    return AnimatedBuilder(
      animation: _playerControllers[index],
      builder: (context, child) {
        // Usamos la animación para hacer una entrada escalonada
        final double scale = 0.7 + (_playerControllers[index].value * 0.3);
        final double opacity = _playerInfoVisible ? _playerControllers[index].value : 0.0;
        
        return Opacity(
          opacity: opacity,
          child: Transform.scale(
            scale: scale,
            child: SizedBox(
              width: width,
              height: height,
              child: ClipPath(
                clipper: TriangleClipper(
                  position: position,
                  size: width, // Usamos el ancho como referencia para el clipper
                ),
                child: Container(
                  color: triangleColor,
                  child: _buildPlayerContent(playerData, position),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
  
  /// Devuelve el color correspondiente según la posición del jugador y el croquis
  Color _getPlayerColor(int index) {
    switch (index) {
      case 0: return const Color(0xFF1E3171);  // Primer lugar (MVP) - Azul oscuro
      case 1: return const Color(0xFF6C77C4);  // Segundo lugar - Azul claro/morado
      case 2: return const Color(0xFFF05366);  // Tercer lugar - Rojo/rosa
      default: return Colors.grey;  // Caso no esperado
    }
  }
  
  /// Construye el contenido dentro de cada triángulo
  Widget _buildPlayerContent(Map<String, dynamic> playerData, TrianglePosition position) {
    final String playerName = playerData["player_name"] as String;
    final int voteCount = playerData["vote_count"] as int;
    final String? imageUrl = playerData["foto_url"] as String?;
    
    // Diferentes layouts según la posición del triángulo
    switch (position) {
      case TrianglePosition.top:
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              _buildAvatar(imageUrl, 60),
              const SizedBox(height: 8),
              Text(
                playerName,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                "$voteCount votos",
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 5),
              const Icon(
                Icons.emoji_events,
                color: Colors.amber,
                size: 30,
              ),
              const Text(
                "MVP",
                style: TextStyle(
                  color: Colors.amber,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ],
          ),
        );
      
      case TrianglePosition.bottomLeft:
        // Segundo lugar - rediseñado según el tercer croquis (rectángulo con diagonal)
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 20.0, bottom: 30.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAvatar(imageUrl, 45),
                  const SizedBox(height: 8),
                  Text(
                    playerName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    "$voteCount votos",
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.emoji_events, color: Colors.grey, size: 20),
                      SizedBox(width: 4),
                      Text(
                        "2° Lugar",
                        style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      
      case TrianglePosition.bottomRight:
        // Tercer lugar - rediseñado según el tercer croquis (rectángulo con diagonal)
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 20.0, bottom: 30.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildAvatar(imageUrl, 45),
                  const SizedBox(height: 8),
                  Text(
                    playerName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.right,
                  ),
                  Text(
                    "$voteCount votos",
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.right,
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text(
                        "3° Lugar",
                        style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.emoji_events, color: Colors.grey, size: 20),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      case TrianglePosition.revealButton:
        return const Center(
          child: Padding(
            padding: EdgeInsets.only(right: 16.0), // Ajustado el padding hacia la derecha debido a la nueva orientación
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.emoji_events,
                  color: Colors.white,
                  size: 40,
                ),
                SizedBox(height: 8),
                Text(
                  "REVELAR\nRESULTADOS",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
    }
  }
  
  /// Construye un avatar de jugador circular
  Widget _buildAvatar(String? imageUrl, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 5,
            spreadRadius: 1,
          ),
        ],
        image: imageUrl != null ? DecorationImage(
          fit: BoxFit.cover,
          image: NetworkImage(imageUrl),
        ) : null,
      ),
      child: imageUrl == null ? const Icon(Icons.person, size: 30, color: Colors.grey) : null,
    );
  }
  
  /// Construye el botón rectangular redondeado para revelar los resultados
  Widget _buildRevealButton() {
    // Dimensiones para un botón rectangular redondeado según el croquis
    final double buttonWidth = 200.0;
    final double buttonHeight = 120.0;
    
    return AnimatedBuilder(
      animation: _revealAnimation,
      builder: (context, child) {
        final double scale = 1.0 - (_revealAnimation.value * 0.3);
        final double opacity = 1.0 - _revealAnimation.value;
        
        return Opacity(
          opacity: opacity,
          child: Transform.scale(
            scale: scale,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.95, end: 1.0),
              duration: const Duration(seconds: 1),
              curve: Curves.easeInOut,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: child,
                );
              },
              child: GestureDetector(
                onTap: _resultsRevealed ? null : _revealResults,
                child: Container(
                  width: buttonWidth,
                  height: buttonHeight,
                  decoration: BoxDecoration(
                    color: Colors.amber,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(
                      color: Colors.amber.shade700,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.emoji_events,
                          color: Colors.white,
                          size: 40,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "revelar\nresultados",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            letterSpacing: 1.2,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
  
  @override
  Widget build(BuildContext context) {
    // Obtener el tamaño de la pantalla
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top - kToolbarHeight;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.matchName,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: _primaryColor,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white), // Iconos de la appbar en blanco
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: _backgroundColor,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Fondo y elementos decorativos
            ..._buildBackgroundElements(),
            
            // Contenido principal: triángulos o botón revelar
            if (_resultsRevealed) ...[  // Si ya se revelaron los resultados
              // Triángulo superior (MVP - 1er lugar) - Ajustado según el tercer croquis
              if (widget.topPlayers.isNotEmpty)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: screenHeight * 0.45, // Ligeramente más grande
                  child: _buildPlayerTriangle(0, TrianglePosition.top),
                ),
              
              // Rectángulo inferior con diagonal - según el tercer croquis
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: screenHeight * 0.45, // Mitad inferior de la pantalla
                child: Container(
                  child: Stack(
                    children: [
                      // Triángulo inferior izquierdo (2do lugar)
                      if (widget.topPlayers.length > 1)
                        Positioned(
                          left: 0,
                          top: 0,
                          width: screenWidth * 0.5,
                          height: screenHeight * 0.45,
                          child: _buildPlayerTriangle(1, TrianglePosition.bottomLeft),
                        ),
                      
                      // Triángulo inferior derecho (3er lugar)
                      if (widget.topPlayers.length > 2)
                        Positioned(
                          right: 0,
                          top: 0,
                          width: screenWidth * 0.5,
                          height: screenHeight * 0.45,
                          child: _buildPlayerTriangle(2, TrianglePosition.bottomRight),
                        ),
                    ],
                  ),
                ),
              ),
            ] else ...[  // Corregido para usar el spread operator correctamente
              // Botón triangular para revelar resultados centrado
              Center(
                child: _buildRevealButton(),
              )
            ],
          ],
        ),
      ),
    );
  }
  
  /// Elementos decorativos de fondo
  List<Widget> _buildBackgroundElements() {
    return [
      // Círculos decorativos
      Positioned(
        top: -50,
        right: -50,
        child: Container(
          width: 150,
          height: 150,
          decoration: BoxDecoration(
            color: _secondaryColor.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
        ),
      ),
      Positioned(
        bottom: -60,
        left: -60,
        child: Container(
          width: 180,
          height: 180,
          decoration: BoxDecoration(
            color: _accentColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
        ),
      ),
    ];
  }
}
