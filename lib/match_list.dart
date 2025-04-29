import 'package:flutter/material.dart';
import 'package:statsfoota/create_match.dart';
import 'package:statsfoota/match_details_screen.dart' hide MatchDetailsScreen;
import 'package:statsfoota/match_details_screen.dart' as match_details;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

class MatchListScreen extends StatefulWidget {
  @override
  _MatchListScreenState createState() => _MatchListScreenState();
}

class _MatchListScreenState extends State<MatchListScreen> with SingleTickerProviderStateMixin {
  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _matches = [];
  bool _isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchMatches();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _getPendingMatches() {
    return _matches.where((match) =>
    match['estado'].toString().toLowerCase() == 'pendiente'
    ).toList();
  }


  List<Map<String, dynamic>> _getFinishedMatches() {
    return _matches.where((match) =>
    match['estado'].toString().toLowerCase() == 'finalizado'
    ).toList();
  }

  Future<void> _fetchMatches() async {
    try {
      setState(() => _isLoading = true);

      // Obtener el usuario actual
      final currentUser = Supabase.instance.client.auth.currentUser;

      if (currentUser == null) {
        // Si no hay usuario autenticado, mostrar mensaje y no cargar partidos
        setState(() {
          _matches = [];
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Debes iniciar sesión para ver tus partidos'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Consultar solo los partidos del usuario actual usando el filtro por user_id
      final response = await supabase
          .from('partidos')
          .select('*, team_claro, team_oscuro, resultado_claro, resultado_oscuro')
          .eq('user_id', currentUser.id) // Filtrar por el ID del usuario
          .order('fecha', ascending: false);

      setState(() {
        _matches = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      print('Error al cargar los partidos: $e');
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar los partidos: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }



// Añade esta función para compartir los detalles del partido
  void _shareMatchDetails(Map<String, dynamic> match) async {
    try {
      // Formatear fecha y hora
      final DateTime matchDateTime = DateTime.parse(match['fecha']);
      final String formattedDate = '${matchDateTime.day}/${matchDateTime.month}/${matchDateTime.year}';
      final String formattedTime = '${matchDateTime.hour.toString().padLeft(2, '0')}:${matchDateTime.minute.toString().padLeft(2, '0')}';

      // Crear el mensaje para compartir
      final bool isFinished = match['estado'].toString().toLowerCase() == 'finalizado';
      String shareMessage;

      if (isFinished) {
        // Para partidos finalizados, incluir el resultado
        final int resultadoClaro = match['resultado_claro'] ?? 0;
        final int resultadoOscuro = match['resultado_oscuro'] ?? 0;

        shareMessage = """
📊 *RESULTADO: ${match['nombre']}*
⚽ Equipo Claro $resultadoClaro - $resultadoOscuro Equipo Oscuro
🏆 ${resultadoClaro > resultadoOscuro ? 'Victoria Equipo Claro' : resultadoClaro < resultadoOscuro ? 'Victoria Equipo Oscuro' : 'Empate'}
📅 $formattedDate a las $formattedTime
🔄 Formato: ${match['formato']}

¡Registrado en StatsFootA!
      """;
      } else {
        // Para partidos pendientes, incluir información e invitación
        shareMessage = """
🔔 *PARTIDO: ${match['nombre']}*
⚽ Equipo Claro vs Equipo Oscuro
📅 $formattedDate a las $formattedTime
🔄 Formato: ${match['formato']}

¡Te invito a este partido! Añádelo a tu calendario:
${_generateCalendarUrl(match)}

Organizado con StatsFootA
      """;
      }

      // Usar el paquete share_plus para mostrar el diálogo de compartir
      await Share.share(
        shareMessage,
        subject: match['nombre'] ?? 'Partido de fútbol',
      );

    } catch (e) {
      print('Error al compartir partido: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al compartir los detalles del partido'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

// Función auxiliar para generar URL del calendario que pueda ser compartida
  String _generateCalendarUrl(Map<String, dynamic> match) {
    final DateTime matchDateTime = DateTime.parse(match['fecha']);

    // Crear URL para añadir evento a Google Calendar
    final String title = Uri.encodeComponent(match['nombre'] ?? 'Partido de fútbol');
    final String description = Uri.encodeComponent(
        '${match['formato']} - Organizado con StatsFootA\n' +
            'Equipo Claro vs Equipo Oscuro'
    );

    // Calcular fechas de inicio y fin (asumiendo duración de 90 minutos)
    final String startDate = _formatCalendarDate(matchDateTime);
    final String endDate = _formatCalendarDate(matchDateTime.add(const Duration(minutes: 90)));

    // Construir URL para Google Calendar
    return 'https://www.google.com/calendar/render?action=TEMPLATE'
        '&text=$title'
        '&dates=$startDate/$endDate'
        '&details=$description'
        '&sf=true';
  }

// Modifica tu función _buildPendingActions para incluir el botón de compartir
  Widget _buildPendingActions(Map<String, dynamic> match) {
    return Column(
      children: [
        const SizedBox(height: 16),
        Divider(height: 1, color: Colors.grey.shade300),
        const SizedBox(height: 16),

        // Botón finalizar partido
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 220,
              child: ElevatedButton.icon(
                onPressed: () => _finishMatch(match),
                icon: const Icon(
                  Icons.check_circle_outline_rounded,
                  size: 20,
                ),
                label: const Text(
                  'Finalizar Partido',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 4,
                  shadowColor: Colors.green.withOpacity(0.4),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Botones de acción
        Wrap(
          spacing: 12,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            // Botón de recordatorio
            _buildActionButton(
              onPressed: () => _addToGoogleCalendar(match),
              icon: Icons.calendar_today_outlined,
              label: '',
              backgroundColor: Colors.blue.shade50,
              textColor: Colors.blue.shade700,
              iconColor: Colors.blue.shade700,
            ),

            // Botón para compartir (nuevo)
            _buildActionButton(
              onPressed: () => _shareMatchDetails(match),
              icon: Icons.share_outlined,
              label: '',
              backgroundColor: Colors.purple.shade50,
              textColor: Colors.purple.shade700,
              iconColor: Colors.purple.shade700,
            ),
          ],
        ),

        const SizedBox(height: 8),
      ],
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Partidos'),
        centerTitle: true,
        backgroundColor: Colors.blue.shade800,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
        leading: BackButton(color: Colors.white), // Cambiando el color de la flecha a blanco
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Pendientes'),
            Tab(text: 'Finalizados'),
          ],
          indicatorColor: Colors.orange.shade600,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade300, Colors.blue.shade800],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: _isLoading
            ? Center(child: CircularProgressIndicator(color: Colors.white))
            : TabBarView(
          controller: _tabController,
          children: [
            _buildMatchList(_getPendingMatches()),
            _buildMatchList(_getFinishedMatches()),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CreateMatchScreen()),
          );
          _fetchMatches();
        },
        child: Icon(Icons.add, color: Colors.white),
        backgroundColor: Colors.orange.shade600,
      ),
    );
  }

  Widget _buildMatchList(List<Map<String, dynamic>> matches) {
    return RefreshIndicator(
      onRefresh: _fetchMatches,
      child: matches.isEmpty
          ? Center(
        child: Text(
          'No hay partidos',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
      )
          : ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: matches.length,
        itemBuilder: (context, index) => _buildMatchCard(matches[index]),
      ),
    );
  }

  Widget _buildMatchCard(Map<String, dynamic> match) {
    // Extraer y formatear datos del partido
    final DateTime matchDate = DateTime.parse(match['fecha']);
    final String formattedDate = '${matchDate.day}/${matchDate.month}/${matchDate.year}';
    final String formattedTime = '${matchDate.hour.toString().padLeft(2, '0')}:${matchDate.minute.toString().padLeft(2, '0')}';
    final bool isPending = match['estado'].toString().toLowerCase() == 'pendiente';
    final bool isFinished = match['estado'].toString().toLowerCase() == 'finalizado';

    // Colores y estilos específicos según el estado
    final Color headerGradientStart = isPending
        ? Colors.blue.shade800
        : isFinished
        ? Colors.indigo.shade900
        : Colors.grey.shade800;

    final Color headerGradientEnd = isPending
        ? Colors.blue.shade700
        : isFinished
        ? Colors.indigo.shade800
        : Colors.grey.shade700;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 6,
      shadowColor: Colors.black.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Encabezado del partido con degradado
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [headerGradientStart, headerGradientEnd],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  offset: const Offset(0, 2),
                  blurRadius: 4,
                )
              ],
            ),
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Fila superior: Título del partido y badge de estado
                Row(
                  children: [
                    // Ícono asociado al formato
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getFormatIcon(match['formato']),
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Nombre del partido
                    Expanded(
                      child: Text(
                        match['nombre'] ?? 'Partido sin nombre',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    // Badge de estado
                    _buildStatusBadge(match['estado']),
                  ],
                ),

                const SizedBox(height: 12),

                // Fila inferior: Información de fecha, hora y formato
                Row(
                  children: [
                    // Fecha
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            color: Colors.white.withOpacity(0.9),
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            formattedDate,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 10),

                    // Hora
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      child: Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            color: Colors.white.withOpacity(0.9),
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            formattedTime,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Spacer(),

                    // Formato de partido
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade600,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        match['formato'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Contenido principal del partido (equipos y marcador)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Equipos y marcador
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                  decoration: BoxDecoration(
                    color: isPending ? Colors.blue.shade50.withOpacity(0.3) : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isPending ? Colors.blue.shade100 : Colors.grey.shade200,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      // Fila de equipos y marcador
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Equipo Claro
                          _buildTeamColumn(
                            'Equipo Claro',
                            match['team_claro'],
                            isPending ? Colors.blue.shade700 : Colors.blue.shade800,
                            match,
                            isFinished,
                          ),

                          // Sección central: Marcador o editor de puntuación
                          _buildCentralSection(isPending, isFinished, match),

                          // Equipo Oscuro
                          _buildTeamColumn(
                            'Equipo Oscuro',
                            match['team_oscuro'],
                            isPending ? Colors.red.shade700 : Colors.red.shade800,
                            match,
                            isFinished,
                          ),
                        ],
                      ),
                      
                      // Único botón Ver Formación centrado debajo de ambas columnas
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: TextButton.icon(
                          onPressed: () => _viewMatchDetails(match),
                          icon: Icon(
                            Icons.sports_soccer_outlined,
                            size: 16,
                            color: Colors.green.shade700,
                          ),
                          label: Text(
                            'Ver Formación',
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.green.shade50,
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Sección de acciones para partidos pendientes
                if (isPending) _buildPendingActions(match),

                // Sección de resultados para partidos finalizados
                if (isFinished) _buildFinishedActions(match),
              ],
            ),
          ),
        ],
      ),
    );
  }

// Widget para el badge de estado
  Widget _buildStatusBadge(String status) {
    final bool isPending = status.toLowerCase() == 'pendiente';
    final bool isFinished = status.toLowerCase() == 'finalizado';

    final Color badgeColor = isPending
        ? Colors.orange.shade600
        : isFinished
        ? Colors.green.shade600
        : Colors.grey.shade600;

    final IconData badgeIcon = isPending
        ? Icons.pending_actions_rounded
        : isFinished
        ? Icons.check_circle_rounded
        : Icons.help_outline_rounded;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            badgeIcon,
            color: Colors.white,
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            isPending ? 'Pendiente' : isFinished ? 'Finalizado' : status,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

// Widget para la sección central (marcador o editor)
  Widget _buildCentralSection(bool isPending, bool isFinished, Map<String, dynamic> match) {
    if (isPending) {
      // Editor de puntuación mejorado
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: _buildScoreEditor(match),
      );
    } else if (isFinished) {
      // Marcador destacado para partidos finalizados
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.grey.shade100, Colors.grey.shade200],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${match['resultado_claro'] ?? 0}',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade700,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                '-',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w300,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
            Text(
              '${match['resultado_oscuro'] ?? 0}',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade700,
              ),
            ),
          ],
        ),
      );
    } else {
      // Para otros estados (como planificado)
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Text(
          'VS',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade700,
          ),
        ),
      );
    }
  }

// Acciones para partidos pendientes
// Acciones para partidos pendientes


// Acciones para partidos finalizados
// Añade esta función para compartir y guardar el partido como recordatorio en Google Calendar
  void _addToGoogleCalendar(Map<String, dynamic> match) async {
    try {
      // Obtener la fecha y hora del partido
      final DateTime matchDateTime = DateTime.parse(match['fecha']);

      // Crear URL para añadir evento a Google Calendar
      final String title = Uri.encodeComponent(match['nombre'] ?? 'Partido de fútbol');
      final String description = Uri.encodeComponent(
          '${match['formato']} - Organizado con StatsFootA\n' +
              'Equipo Claro vs Equipo Oscuro'
      );

      // Calcular fechas de inicio y fin (asumiendo duración de 90 minutos)
      final String startDate = _formatCalendarDate(matchDateTime);
      final String endDate = _formatCalendarDate(matchDateTime.add(const Duration(minutes: 90)));

      // Construir URL para Google Calendar
      final String googleCalendarUrl = 'https://www.google.com/calendar/render?action=TEMPLATE'
          '&text=$title'
          '&dates=$startDate/$endDate'
          '&details=$description'
          '&sf=true'
          '&output=xml';

      // Abrir URL
      if (await canLaunch(googleCalendarUrl)) {
        await launch(googleCalendarUrl);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Abriendo Google Calendar...'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        throw 'No se pudo abrir Google Calendar';
      }
    } catch (e) {
      print('Error al añadir evento a Google Calendar: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al abrir Google Calendar: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

// Función para formatear fecha en formato requerido por Google Calendar
  String _formatCalendarDate(DateTime dateTime) {
    return '${dateTime.year}${dateTime.month.toString().padLeft(2, '0')}'
        '${dateTime.day.toString().padLeft(2, '0')}T'
        '${dateTime.hour.toString().padLeft(2, '0')}'
        '${dateTime.minute.toString().padLeft(2, '0')}00';
  }

// Modifica la función _buildFinishedActions para añadir el nuevo botón
  Widget _buildFinishedActions(Map<String, dynamic> match) {
    // Determinar ganador
    final int resultadoClaro = match['resultado_claro'] ?? 0;
    final int resultadoOscuro = match['resultado_oscuro'] ?? 0;
    final bool empate = resultadoClaro == resultadoOscuro;
    final bool ganaClaro = resultadoClaro > resultadoOscuro;

    return Column(
      children: [
        const SizedBox(height: 12),

        // Mostrar resultado (ganador o empate)
        if (!empate) ...[
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            decoration: BoxDecoration(
              color: ganaClaro ? Colors.blue.shade50 : Colors.red.shade50,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: ganaClaro ? Colors.blue.shade200 : Colors.red.shade200,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.emoji_events_rounded,
                  size: 18,
                  color: ganaClaro ? Colors.blue.shade700 : Colors.red.shade700,
                ),
                const SizedBox(width: 8),
                Text(
                  ganaClaro ? 'Victoria Equipo Claro' : 'Victoria Equipo Oscuro',
                  style: TextStyle(
                    color: ganaClaro ? Colors.blue.shade800 : Colors.red.shade800,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          // Código existente para empate...
        ],

        const SizedBox(height: 16),
        Divider(height: 1, color: Colors.grey.shade200),
        const SizedBox(height: 16),

        // Botones de acción - Ahora con tres botones
      ],
    );
  }


// Botón de acción genérico
  Widget _buildActionButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required Color backgroundColor,
    required Color textColor,
    required Color iconColor,
  }) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: iconColor,
              ),
              if (label.isNotEmpty) ...[
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

// Funciones auxiliares

// Determinar el icono según el formato
  IconData _getFormatIcon(String format) {
    switch (format.toLowerCase()) {
      case '5v5':
        return Icons.people;
      case '7v7':
        return Icons.groups;
      case '11v11':
        return Icons.stadium;
      default:
        return Icons.sports_soccer;
    }
  }

// Función para editar un partido
  void _editMatch(Map<String, dynamic> match) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CreateMatchScreen()),
    ).then((_) => _fetchMatches());
  }

// Función para compartir resultado
  void _shareMatchResult(Map<String, dynamic> match) {
    // Implementación del compartir...
  }

// Función para ver estadísticas detalladas
  void _viewMatchStatistics(Map<String, dynamic> match) {
    // Implementación para ver estadísticas...
  }

  Widget _buildScoreEditor(Map<String, dynamic> match) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildScoreButton(match, 'resultado_claro', match['resultado_claro'] ?? 0, Colors.blue.shade50),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Text('-',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey
                )
            ),
          ),
          _buildScoreButton(match, 'resultado_oscuro', match['resultado_oscuro'] ?? 0, Colors.red.shade50),
        ],
      ),
    );
  }

    Widget _buildScoreButton(Map<String, dynamic> match, String field, int score, Color color) {
    return Container(
      height: 24,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: score > 0 ? () {
                // Actualizo localmente primero
                setState(() {
                  match[field] = score - 1;
                });
                // Luego actualizoo en la base de datos
                _updateScoreDatabase(match, field, score - 1);
              } : null,
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: EdgeInsets.all(2),
                child: Icon(Icons.remove, size: 12),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 2),
            child: Text(
              '$score',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                // Actualizar localmente primero
                setState(() {
                  match[field] = score + 1;
                });
                // Luego actualizar en la base de datos
                _updateScoreDatabase(match, field, score + 1);
              },
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: EdgeInsets.all(2),
                child: Icon(Icons.add, size: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Función separada para actualizar el marcador en la base de datos
  Future<void> _updateScoreDatabase(Map<String, dynamic> match, String field, int newScore) async {
    try {
      // Actualizar en la base de datos sin afectar la UI
      await supabase
          .from('partidos')
          .update({field: newScore})
          .match({'id': match['id']});

      print('Marcador actualizado en BD: ${match['id']}, campo $field = $newScore');
    } catch (e) {
      print('Error al actualizar el marcador en la base de datos: $e');
    }
  }


  Future<void> _finishMatch(Map<String, dynamic> match) async {
    try {
      // Show confirmation dialog
      final bool? confirm = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Finalizar Partido'),
            content: Text('¿Estás seguro de que deseas finalizar este partido?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.green,
                ),
                child: Text('Finalizar'),
              ),
            ],
          );
        },
      );

      if (confirm != true) return;

      // Update match status in database
      await supabase
          .from('partidos')
          .update({'estado': 'finalizado'})
          .match({'id': match['id']});

      // Update local state
      setState(() {
        match['estado'] = 'finalizado';
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Partido finalizado correctamente'),
          backgroundColor: Colors.green,
        ),
      );

      // Refresh matches list
      _fetchMatches();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al finalizar el partido'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }


// actualizar el marcador principal



  Widget _buildTeamColumn(String title, List<dynamic> players, Color color, Map<String, dynamic> match, bool isFinished) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          if (isFinished)
            Text(
              '${match[title == 'Equipo Claro' ? 'resultado_claro' : 'resultado_oscuro'] ?? 0}',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
              textAlign: TextAlign.center,
            ),
          SizedBox(height: 8),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _getPlayerDetails(players, matchId: match['id']),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: color.withOpacity(0.7),
                  ),
                );
              } else if (snapshot.hasError) {
                return Text(
                  'Error: ${snapshot.error}',
                  style: TextStyle(color: Colors.red, fontSize: 12),
                );
              } else {
                final playerDetails = snapshot.data ?? [];
                if (playerDetails.isEmpty) {
                  return Text(
                    'No hay jugadores',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                    textAlign: TextAlign.center,
                  );
                }
                return Container(
                  child: Column(
                    children: playerDetails.map((player) {
                      dynamic fotoPerfil = player['foto_perfil'];
                      String? fotoUrl = fotoPerfil is String && fotoPerfil.isNotEmpty ? fotoPerfil : null;

                      return Column(
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 10,
                                backgroundImage: fotoUrl != null ? NetworkImage(fotoUrl) : null,
                                child: fotoUrl == null ? Icon(Icons.person, size: 10) : null,
                              ),
                              SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  player['nombre'] ?? 'Jugador',
                                  style: TextStyle(fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ),
                          // Mostrar solo iconos con estadísticas sin botones de edición
                          SizedBox(height: 2),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildStatDisplay('⚽', player['goles'] ?? 0),
                              SizedBox(width: 2),
                              _buildStatDisplay('👟', player['asistencias'] ?? 0),
                              SizedBox(width: 2),
                              _buildStatDisplay('🥅', player['goles_propios'] ?? 0),
                            ],
                          ),
                          Divider(height: 8, thickness: 0.5),
                        ],
                      );
                    }).toList(),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

// Nuevo widget para mostrar estadísticas sin botones (para partidos finalizados)
  Widget _buildStatDisplay(String icon, int value) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(3),
      ),
      padding: EdgeInsets.symmetric(horizontal: 3, vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: TextStyle(fontSize: 8)),
          SizedBox(width: 2),
          Text(
            '$value',
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

   Widget _buildCompactStatCounter(String icon, int value, String statType, dynamic playerId, dynamic matchId) {
    int matchIdInt = 0;
    try {
      if (matchId is int) {
        matchIdInt = matchId;
      } else if (matchId is String) {
        matchIdInt = int.parse(matchId);
      } else if (matchId != null) {
        matchIdInt = int.parse(matchId.toString());
      }
    } catch (e) {
      print('Error convirtiendo matchId: $e');
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(3),
      ),
      padding: EdgeInsets.symmetric(horizontal: 0, vertical: 0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: TextStyle(fontSize: 8)),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: (value > 0) ? () {
                setState(() {
                  _updatePlayerStatLocal(playerId, matchIdInt, statType, value - 1);
                });
                _updatePlayerStatDatabase(playerId, matchIdInt, statType, value - 1);
              } : null,
              child: Container(
                padding: EdgeInsets.all(1),
                height: 14,
                width: 14,
                child: Center(
                  child: Icon(
                    Icons.remove,
                    size: 8,
                    color: (value > 0) ? Colors.black87 : Colors.black26
                  ),
                ),
              ),
            ),
          ),
          Container(
            width: 8,
            alignment: Alignment.center,
            child: Text(
              '$value',
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                setState(() {
                  _updatePlayerStatLocal(playerId, matchIdInt, statType, value + 1);
                });
                _updatePlayerStatDatabase(playerId, matchIdInt, statType, value + 1);
              },
              child: Container(
                padding: EdgeInsets.all(1),
                height: 14,
                width: 14,
                child: Center(
                  child: Icon(
                    Icons.add,
                    size: 8,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Nueva función para actualizar estadística localmente
  void _updatePlayerStatLocal(dynamic playerId, int matchId, String statType, int newValue) {
    // Buscar el partido en la lista local
    late Map<String, dynamic>? currentMatch;

    List<Map<String, dynamic>> matchesList;
    if (_tabController.index == 0) {
      matchesList = _getPendingMatches();
    } else {
      matchesList = _getFinishedMatches();
    }

    for (var match in matchesList) {
      if (match['id'] == matchId) {
        currentMatch = match;
        break;
      }
    }

    // Si no encontramos el partido, salir
    if (currentMatch == null) return;

    // Determinar a qué equipo pertenece el jugador
    final List<dynamic> teamClaro = List<dynamic>.from(currentMatch['team_claro'] ?? []);
    final List<dynamic> teamOscuro = List<dynamic>.from(currentMatch['team_oscuro'] ?? []);

    String equipoJugador = '';

    // Comprobar si el jugador está en alguno de los equipos
    final playerIdStr = playerId.toString();
    if (teamClaro.contains(playerId) || teamClaro.any((id) => id.toString() == playerIdStr)) {
      equipoJugador = 'team_claro';
    } else if (teamOscuro.contains(playerId) || teamOscuro.any((id) => id.toString() == playerIdStr)) {
      return; // El jugador no está en ningún equipo
    }

    // Si es una actualización de goles, actualizar el marcador del partido
    if (statType == 'goles') {
      // Calcular la diferencia con el valor anterior
      int oldValue = 0;

      // Buscar estadísticas actuales del jugador si existen
      for (var player in _matches) {
        if (player['id'] == playerId) {
          oldValue = player['goles'] ?? 0;
          break;
        }
      }

      int diff = newValue - oldValue;

      // Actualizar el marcador según el equipo
      String resultField = equipoJugador == 'team_claro' ? 'resultado_claro' : 'resultado_oscuro';
      int currentScore = currentMatch[resultField] ?? 0;
      currentMatch[resultField] = currentScore + diff;
    }
  }

  // Función separada para actualizar en la base de datos sin afectar la UI
  Future<void> _updatePlayerStatDatabase(
      dynamic playerId, int matchId, String statType, int newValue) async {

    if (playerId == null || matchId <= 0) {
      print('Error: ID inválido - playerId: $playerId, matchId: $matchId');
      return;
    }

    try {
      // Paso 1: Determinar el equipo al que pertenece el jugador
      final matchResponse = await supabase
          .from('partidos')
          .select('team_claro, team_oscuro')
          .eq('id', matchId)
          .single();

      final List<dynamic> teamClaro = List<dynamic>.from(matchResponse['team_claro'] ?? []);
      final List<dynamic> teamOscuro = List<dynamic>.from(matchResponse['team_oscuro'] ?? []);

      String equipoJugador = '';
      final playerIdStr = playerId.toString();

      // Determinar equipo del jugador
      if (teamClaro.contains(playerId) || teamClaro.any((id) => id.toString() == playerIdStr)) {
        equipoJugador = 'team_claro';
      } else if (teamOscuro.contains(playerId) || teamOscuro.any((id) => id.toString() == playerIdStr)) {
        equipoJugador = 'team_oscuro';
      } else {
        print('Jugador no encontrado en ningún equipo');
        return;
      }

      // Paso 2: Verificar si existe un registro para este jugador y partido
      final statsResponse = await supabase
          .from('estadisticas')
          .select()
          .eq('jugador_id', playerId)
          .eq('partido_id', matchId);

      // Paso 3: Crear o actualizar el registro
      if (statsResponse == null || statsResponse.isEmpty) {
        // Crear nuevo registro
        await supabase.from('estadisticas').insert({
          'jugador_id': playerId, // UUID como está, sin convertir
          'partido_id': matchId,   // int4
          'goles': statType == 'goles' ? newValue : 0,
          'asistencias': statType == 'asistencias' ? newValue : 0,
          'equipo': equipoJugador, // text
        });
        print('Nuevo registro creado para jugador $playerId');
      } else {
        // Actualizar registro existente
        await supabase
            .from('estadisticas')
            .update({statType: newValue})
            .eq('jugador_id', playerId)
            .eq('partido_id', matchId);
        print('Registro actualizado para jugador $playerId');
      }

      // Paso 4: Si son goles, actualizar el marcador del partido
      if (statType == 'goles') {
        // Calcular total de goles para el equipo
        final allTeamStats = await supabase
            .from('estadisticas')
            .select('goles')
            .eq('partido_id', matchId)
            .eq('equipo', equipoJugador);

        int totalGoles = 0;
        if (allTeamStats != null) {
          for (var stat in allTeamStats) {
            if (stat['goles'] != null) {
              totalGoles += stat['goles'] as int;
            }
          }
        }

        // Actualizar el marcador del equipo en la base de datos
        final String resultField = equipoJugador == 'team_claro' ? 'resultado_claro' : 'resultado_oscuro';

        await supabase
            .from('partidos')
            .update({resultField: totalGoles})
            .eq('id', matchId);

        print('Marcador actualizado en la base de datos: $totalGoles goles');
      }

    } catch (e) {
      print('Error actualizando estadística en la base de datos: $e');
    }
  }

  // Función mejorada para obtener estadísticas de jugadores (con manejo de UUID)
   // Función mejorada para obtener estadísticas de jugadores (con manejo de UUID)
  Future<List<Map<String, dynamic>>> _getPlayerDetails(List<dynamic> players, {required int matchId}) async {
    if (players.isEmpty) return [];

    try {
      final List<Map<String, dynamic>> playerDetails = [];

      // Obtener datos de jugadores
      for (var playerId in players) {
        try {
          final response = await supabase
              .from('jugadores')
              .select('id, nombre, foto_perfil')
              .eq('id', playerId)
              .maybeSingle();

          if (response != null) {
            playerDetails.add({
              'id': playerId, // Mantener el ID original
              'nombre': response['nombre'] ?? 'Jugador',
              'foto_perfil': response['foto_perfil'],
              'goles': 0,
              'asistencias': 0,
            });
          }
        } catch (e) {
          print('Error obteniendo jugador $playerId: $e');
        }
      }

      // Usar el matchId proporcionado - esto asegura que cada partido tenga sus propias estadísticas
      if (matchId > 0) {
        // Obtener estadísticas individuales para cada jugador en este partido específico
        for (var player in playerDetails) {
          try {
            final statsResponse = await supabase
              .from('estadisticas')
              .select('goles, asistencias')
              .eq('jugador_id', player['id'])
              .eq('partido_id', matchId)
              .maybeSingle();

            if (statsResponse != null) {
              player['goles'] = statsResponse['goles'] ?? 0;
              player['asistencias'] = statsResponse['asistencias'] ?? 0;
            }
          } catch (e) {
            print('Error obteniendo estadísticas para jugador ${player['id']} en partido $matchId: $e');
          }
        }
      }

      return playerDetails;
    } catch (e) {
      print('Error general: $e');
      return [];
    }
  }

// Función para ver los detalles y formación del partido
  void _viewMatchDetails(Map<String, dynamic> match) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => match_details.MatchDetailsScreen(matchId: match['id']),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pendiente':
        return Colors.orange;
      case 'finalizado':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}