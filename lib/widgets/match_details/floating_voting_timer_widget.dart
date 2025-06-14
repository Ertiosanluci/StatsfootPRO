import 'package:flutter/material.dart';
import 'dart:async';

/// Widget flotante para mostrar el contador de votación de MVP
class FloatingVotingTimerWidget extends StatefulWidget {  final Map<String, dynamic> votingData;
  final VoidCallback onVoteButtonPressed;
  final VoidCallback? onFinishVotingPressed; // Callback para finalizar votación
  final VoidCallback? onResetVotingPressed; // Callback para rehacer votación
  final VoidCallback? onViewResultsPressed; // Callback para ver resultados
  
  const FloatingVotingTimerWidget({
    Key? key,
    required this.votingData,
    required this.onVoteButtonPressed,
    this.onFinishVotingPressed,
    this.onResetVotingPressed,
    this.onViewResultsPressed,
  }) : super(key: key);
  
  @override
  _FloatingVotingTimerWidgetState createState() => _FloatingVotingTimerWidgetState();
}

class _FloatingVotingTimerWidgetState extends State<FloatingVotingTimerWidget> {
  DateTime? _endTime;
  Duration _timeRemaining = Duration.zero;
  Timer? _timer;
  
  // Variables para gestionar la posición
  Offset _position = Offset(20, 100); // Posición inicial
  bool _isDragging = false;
  bool _isVotingActive = false;
  
  @override
  void initState() {
    super.initState();
    _initializeVotingData();
  }
  
  void _initializeVotingData() {
    // Verificar si hay datos de votación válidos
    if (widget.votingData.containsKey('voting_ends_at')) {
      try {
        _endTime = DateTime.parse(widget.votingData['voting_ends_at']);
        final String status = widget.votingData['status'] as String? ?? 'active';
        _isVotingActive = status == 'active';
        
        _updateTimeRemaining();
        // Solo iniciar el temporizador si la votación está activa
        if (_isVotingActive) {
          _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTimeRemaining());
        }
      } catch (e) {
        print('Error al analizar datos de votación: $e');
        _endTime = DateTime.now();
        _timeRemaining = Duration.zero;
      }
    } else {
      _endTime = DateTime.now();
      _timeRemaining = Duration.zero;
    }
  }
  
  @override
  void dispose() {
    _timer?.cancel();
    _timer = null;
    super.dispose();
  }
  
  @override
  void didUpdateWidget(FloatingVotingTimerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Si los datos de votación cambian, reinicializar
    if (oldWidget.votingData != widget.votingData) {
      _timer?.cancel();
      _timer = null;
      _initializeVotingData();
    }
  }
  
  void _updateTimeRemaining() {
    if (_endTime == null) return;
    
    final now = DateTime.now();
    if (_endTime!.isAfter(now)) {
      setState(() {
        _timeRemaining = _endTime!.difference(now);
      });
    } else {
      setState(() {
        _timeRemaining = Duration.zero;
        _isVotingActive = false;
      });
      _timer?.cancel();
      _timer = null;
    }
  }
  
  String _formatTimeRemaining() {
    // Si la votación no está activa o no hay end time
    if (!_isVotingActive || _endTime == null || _timeRemaining.inSeconds <= 0) {
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
                  Text(
                    _isVotingActive ? "Votación en curso" : "Votación finalizada",
                    style: const TextStyle(
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
                  // Botón para votar (siempre activo)
                  SizedBox(
                    height: 28,
                    width: 40,
                    child: ElevatedButton(
                      onPressed: widget.onVoteButtonPressed, // Siempre activo
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
                  ),                  if (widget.onFinishVotingPressed != null) ...[
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
                  if (widget.onResetVotingPressed != null) ...[
                    const SizedBox(width: 4),
                    // Botón para rehacer votación (solo disponible para creadores)
                    SizedBox(
                      height: 28,
                      width: 48,
                      child: ElevatedButton(
                        onPressed: widget.onResetVotingPressed, // Siempre activo
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          visualDensity: VisualDensity.compact,
                        ),
                        child: const Text(
                          "Rehacer",
                          style: TextStyle(fontSize: 9),
                        ),
                      ),
                    ),
                  ],
                  // Botón de ver resultados (aparece solo cuando la votación ha terminado)
                  if (!_isVotingActive && widget.onViewResultsPressed != null) ...[  
                    const SizedBox(width: 4),
                    // Usando un enfoque simple pero estético
                    InkWell(
                      onTap: widget.onViewResultsPressed, 
                      child: Container(
                        height: 28,
                        width: 70,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFB300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: Text(
                            "Ver MVPs",
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                          ),
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
