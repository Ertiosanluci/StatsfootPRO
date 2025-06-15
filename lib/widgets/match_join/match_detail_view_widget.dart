import 'package:flutter/material.dart';
import 'info_row_widget.dart';
import 'join_button_widget.dart';

/// Widget que muestra los detalles de un partido para unirse
class MatchDetailViewWidget extends StatelessWidget {
  final Map<String, dynamic> matchData;
  final String creatorName;
  final String? creatorEmail;
  final bool alreadyJoined;
  final bool isJoining;
  final VoidCallback onJoin;
  
  const MatchDetailViewWidget({
    Key? key,
    required this.matchData,
    required this.creatorName,
    this.creatorEmail,
    required this.alreadyJoined,
    required this.isJoining,
    required this.onJoin,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    // Procesamos la fecha del partido
    DateTime? matchDate;
    String formattedDate = 'No disponible';
    String formattedTime = 'No disponible';
    
    try {
      if (matchData['fecha'] != null) {
        matchDate = DateTime.parse(matchData['fecha']);
        formattedDate = '${matchDate.day}/${matchDate.month}/${matchDate.year}';
        formattedTime = '${matchDate.hour.toString().padLeft(2, '0')}:${matchDate.minute.toString().padLeft(2, '0')}';
      }
    } catch (e) {
      debugPrint('Error al formatear fecha: $e');
    }
    
    // Validar el formato
    final String formato = matchData['formato']?.toString() ?? 'No especificado';
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade300, Colors.blue.shade800],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildMatchBanner(),
              
              const SizedBox(height: 25),
              
              // Tarjeta de detalles del partido
              Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.sports_soccer,
                            color: Colors.blue.shade800,
                            size: 28,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Detalles del Partido',
                            style: TextStyle(
                              color: Colors.blue.shade800,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                      
                      const Divider(height: 30),
                      
                      // Filas de información
                      InfoRowWidget(
                        icon: Icons.format_list_numbered,
                        title: 'Formato',
                        value: formato,
                      ),
                      
                      InfoRowWidget(
                        icon: Icons.calendar_today,
                        title: 'Fecha',
                        value: formattedDate,
                      ),
                      
                      InfoRowWidget(
                        icon: Icons.access_time,
                        title: 'Hora',
                        value: formattedTime,
                      ),
                      
                      InfoRowWidget(
                        icon: Icons.location_on,
                        title: 'Ubicación',
                        value: matchData['ubicacion']?.toString() ?? 'No especificada',
                      ),
                      
                      InfoRowWidget(
                        icon: Icons.person,
                        title: 'Organizador',
                        value: creatorName,
                      ),
                      
                      if (matchData['descripcion'] != null && matchData['descripcion'].toString().isNotEmpty)
                        InfoRowWidget(
                          icon: Icons.description,
                          title: 'Descripción',
                          value: matchData['descripcion'],
                        ),
                      
                      const SizedBox(height: 20),
                      
                      // Botón para unirse
                      JoinButtonWidget(
                        alreadyJoined: alreadyJoined,
                        isJoining: isJoining,
                        onJoin: onJoin,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  /// Construye el banner superior del partido
  Widget _buildMatchBanner() {
    return Container(
      height: 150,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        image: DecorationImage(
          image: const AssetImage('assets/ic_launcher.png'),
          fit: BoxFit.contain,
          colorFilter: ColorFilter.mode(
            Colors.black.withOpacity(0.3),
            BlendMode.dstATop,
          ),
        ),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'INVITACIÓN AL PARTIDO',
              style: TextStyle(
                color: Colors.blue.shade800,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.blue.shade900.withOpacity(0.9),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              matchData['nombre']?.toString() ?? 'Partido sin nombre',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
