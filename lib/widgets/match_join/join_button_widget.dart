import 'package:flutter/material.dart';

/// Widget que muestra un botón para unirse a un partido
/// con diferentes estados: ya unido, uniéndose o disponible para unirse
class JoinButtonWidget extends StatelessWidget {
  final bool alreadyJoined;
  final bool isJoining;
  final VoidCallback? onJoin;
  
  const JoinButtonWidget({
    Key? key,
    required this.alreadyJoined,
    required this.isJoining,
    this.onJoin,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    if (alreadyJoined) {
      return _buildAlreadyJoinedButton();
    } else {
      return _buildJoinButton();
    }
  }
  
  /// Construye un botón desactivado que muestra que el usuario ya se ha unido
  Widget _buildAlreadyJoinedButton() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: BoxDecoration(
        color: Colors.green.shade100,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.green.shade400),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle,
            color: Colors.green.shade700,
          ),
          const SizedBox(width: 10),
          Text(
            'Ya te has unido a este partido',
            style: TextStyle(
              color: Colors.green.shade700,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
  
  /// Construye un botón activo para unirse al partido o un botón con indicador de progreso
  Widget _buildJoinButton() {
    return ElevatedButton(
      onPressed: isJoining ? null : onJoin,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green.shade600,
        disabledBackgroundColor: Colors.green.shade300,
        padding: const EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      child: isJoining
          ? _buildJoiningContent()
          : _buildJoinContent(),
    );
  }
  
  /// Construye el contenido del botón cuando se está uniendo (con indicador de carga)
  Widget _buildJoiningContent() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2,
          ),
        ),
        const SizedBox(width: 10),
        const Text(
          'Uniéndose...',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
  
  /// Construye el contenido del botón normal para unirse
  Widget _buildJoinContent() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.sports_soccer),
        const SizedBox(width: 10),
        const Text(
          'UNIRSE AL PARTIDO',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}
