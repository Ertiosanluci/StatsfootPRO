import 'package:flutter/material.dart';
import 'dart:async';

/// Widget flotante para mostrar el contador de votación de MVP
class FloatingVotingTimerWidget extends StatefulWidget {
  final Map<String, dynamic> votingData;
  final VoidCallback onVoteButtonPressed;
  final VoidCallback? onFinishVotingPressed; // Callback para finalizar votación
  
  const FloatingVotingTimerWidget({
    Key? key,
    required this.votingData,
    required this.onVoteButtonPressed,
    this.onFinishVotingPressed,
  }) : super(key: key);
  
  @override
  _FloatingVotingTimerWidgetState createState() => _FloatingVotingTimerWidgetState();
}

class _FloatingVotingTimerWidgetState extends State<FloatingVotingTimerWidget> {
  late DateTime _endTime;
  Duration _timeRemaining = Duration.zero;
  late Timer _timer;
  
  // Variables para gestionar la posición
  Offset _position = Offset(20, 100); // Posición inicial
  bool _isDragging = false;
  
  @override
  void initState() {
    super.initState();
    _endTime = DateTime.parse(widget.votingData['voting_ends_at']);
    _updateTimeRemaining();
    _timer = Timer.periodic(Duration(seconds: 1), (_) => _updateTimeRemaining());
  }
  
  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }
  
  void _updateTimeRemaining() {
    final now = DateTime.now();
    if (_endTime.isAfter(now)) {
      setState(() {
        _timeRemaining = _endTime.difference(now);
      });
    } else {
      setState(() {
        _timeRemaining = Duration.zero;
      });
      _timer.cancel();
    }
  }
  
  String _formatTimeRemaining() {
    if (_timeRemaining.inSeconds <= 0) {
      return "¡Finalizada!";
    }
    
    final hours = _timeRemaining.inHours;
    final minutes = _timeRemaining.inMinutes % 60;
    final seconds = _timeRemaining.inSeconds % 60;
    
    return "${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
  }
    @override
  Widget build(BuildContext context) {
    // Calcular la altura del AppBar + TabBar para evitar que el widget se oculte debajo
    final MediaQueryData mediaQuery = MediaQuery.of(context);
    final double statusBarHeight = mediaQuery.padding.top;
    final double appBarHeight = AppBar().preferredSize.height;
    final double tabBarHeight = 48.0; // Altura aproximada de la TabBar
    final double minTopPosition = statusBarHeight + appBarHeight + tabBarHeight;
    
    // Asegurar que el widget no se posicione por encima del límite superior
    double topPosition = _position.dy;
    if (topPosition < minTopPosition) {
      topPosition = minTopPosition;
    }
    
    // Widget posicionable
    return Positioned(
      left: _position.dx,
      top: topPosition,
      child: GestureDetector(
        onPanStart: (details) {
          setState(() {
            _isDragging = true;
          });
        },
        onPanUpdate: (details) {
          setState(() {
            // Actualizar posición con desplazamiento
            double newY = _position.dy + details.delta.dy;
            
            // Aplicar restricción para la parte superior
            if (newY < minTopPosition) {
              newY = minTopPosition;
            }
            
            _position = Offset(
              _position.dx + details.delta.dx,
              newY,
            );
            
            // Restricciones para los bordes laterales e inferior
            if (_position.dx < 0) _position = Offset(0, _position.dy);
            if (_position.dx > mediaQuery.size.width - 150) 
              _position = Offset(mediaQuery.size.width - 150, _position.dy);
            if (_position.dy > mediaQuery.size.height - 150) 
              _position = Offset(_position.dx, mediaQuery.size.height - 150);
          });
        },
        onPanEnd: (details) {
          setState(() {
            _isDragging = false;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.purple.shade800, Colors.indigo.shade900],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: _isDragging ? Colors.white.withOpacity(0.6) : Colors.white.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,            children: [
              const Icon(
                Icons.how_to_vote,
                color: Colors.amber,
                size: 16,
              ),
              const SizedBox(width: 6),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Votación en curso",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                  Text(
                    _formatTimeRemaining(),
                    style: TextStyle(
                      color: Colors.amber,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              // Botones de acciones
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Botón para votar
                  SizedBox(
                    height: 28,
                    width: 40,
                    child: ElevatedButton(
                      onPressed: _timeRemaining.inSeconds > 0 ? widget.onVoteButtonPressed : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                      child: const Text(
                        "Votar",
                        style: TextStyle(fontSize: 10),
                      ),
                    ),
                  ),
                  if (widget.onFinishVotingPressed != null) ...[
                    const SizedBox(width: 4),
                    // Botón para finalizar votación (solo disponible para creadores)
                    SizedBox(
                      height: 28,
                      width: 48,
                      child: ElevatedButton(
                        onPressed: _timeRemaining.inSeconds > 0 ? widget.onFinishVotingPressed : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          visualDensity: VisualDensity.compact,
                        ),
                        child: const Text(
                          "Finalizar",
                          style: TextStyle(fontSize: 9),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(width: 4),
              // Indicador de arrastrar
              Icon(
                Icons.drag_indicator,
                size: 16,
                color: Colors.white.withOpacity(0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
