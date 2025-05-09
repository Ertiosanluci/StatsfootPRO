import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'create_match.dart';
import 'match_join_screen.dart';
import 'match_details_screen.dart';
import 'team_management_screen.dart';

class MatchListScreen extends StatefulWidget {
  @override
  _MatchListScreenState createState() => _MatchListScreenState();
}

class _MatchListScreenState extends State<MatchListScreen> with SingleTickerProviderStateMixin {
  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _myMatches = [];
  List<Map<String, dynamic>> _invitedMatches = [];
  bool _isLoading = true;
  late TabController _tabController;
  String? _error;

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

  Future<void> _fetchMatches() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) {
        setState(() {
          _isLoading = false;
          _error = 'Debes iniciar sesión para ver tus partidos';
        });
        return;
      }

      // Primero, mostrar un log para depuración
      print('Cargando partidos para usuario: ${currentUser.id}');

      // Lista para almacenar todos los partidos del usuario (organizados + participante)
      final List<Map<String, dynamic>> allMyMatches = [];

      try {
        // 1. Cargar partidos organizados por el usuario actual
        final organizedMatchesResponse = await supabase
            .from('matches')
            .select('*')
            .eq('creador_id', currentUser.id)
            .order('fecha', ascending: false);
        
        print('Partidos organizados cargados: ${organizedMatchesResponse.length}');
        
        // Cargar los datos de perfil para los partidos organizados
        for (final match in organizedMatchesResponse) {
          final Map<String, dynamic> matchWithProfile = Map.from(match);
          
          // Para partidos creados por el usuario actual, usar su propio perfil
          try {
            final profileData = await supabase
                .from('profiles')
                .select('*')
                .eq('id', currentUser.id)
                .maybeSingle();
                
            if (profileData != null) {
              matchWithProfile['profiles'] = profileData;
            }
          } catch (e) {
            print('Error al cargar perfil del usuario actual: $e');
          }
          
          // Marcar como organizador para distinguirlos
          matchWithProfile['isOrganizer'] = true;
          
          allMyMatches.add(matchWithProfile);
        }
        
        // 2. Cargar partidos donde el usuario es participante
        final participantMatchesResponse = await supabase
            .from('match_participants')
            .select('match_id')
            .eq('user_id', currentUser.id)
            .eq('es_organizador', false);
        
        // Si hay partidos donde el usuario es participante, cargarlos individualmente
        if (participantMatchesResponse.isNotEmpty) {
          for (final item in participantMatchesResponse) {
            final int matchId = item['match_id'];
            final matchData = await supabase
                .from('matches')
                .select('*')
                .eq('id', matchId)
                .maybeSingle();
                
            if (matchData != null) {
              // Obtener datos del creador
              try {
                final creatorData = await supabase
                    .from('profiles')
                    .select('*')
                    .eq('id', matchData['creador_id'])
                    .maybeSingle();
                    
                if (creatorData != null) {
                  matchData['profiles'] = creatorData;
                }
              } catch (e) {
                print('Error al cargar perfil del creador: $e');
              }
              
              // Marcar como no organizador
              matchData['isOrganizer'] = false;
              
              // Añadir a la lista de todos los partidos
              allMyMatches.add(matchData);
            }
          }
        }
        
        print('Total de partidos cargados: ${allMyMatches.length}');

        // Ordenar todos los partidos por fecha (más reciente primero)
        allMyMatches.sort((a, b) {
          DateTime dateA = DateTime.parse(a['fecha']);
          DateTime dateB = DateTime.parse(b['fecha']);
          return dateB.compareTo(dateA);
        });

        setState(() {
          _myMatches = allMyMatches;
          _invitedMatches = []; // Dejar vacío para implementación futura
          _isLoading = false;
        });
      } catch (e) {
        print('Error en consulta específica: $e');
        setState(() {
          _isLoading = false;
          _error = 'Error al cargar datos: $e';
        });
      }
    } catch (e) {
      print('Error general: $e');
      setState(() {
        _isLoading = false;
        _error = 'Error al cargar partidos: $e';
      });
    }
  }

  void _shareMatchLink(Map<String, dynamic> match) async {
    try {
      // Obtener información del partido
      final int matchId = match['id'];
      final DateTime matchDate = DateTime.parse(match['fecha']);
      final String formattedDate = '${matchDate.day}/${matchDate.month}/${matchDate.year}';
      final String formattedTime = '${matchDate.hour.toString().padLeft(2, '0')}:${matchDate.minute.toString().padLeft(2, '0')}';

      // Usar el dominio real de Netlify para el enlace
      final String shareableLink = "https://statsfootpro.netlify.app/match/$matchId";
      
      final String message = """
🏆 ¡Únete a mi partido de fútbol! 🏆

Partido: ${match['nombre']}
Formato: ${match['formato']}
Fecha: $formattedDate
Hora: $formattedTime

Únete usando este enlace: $shareableLink

¡Te esperamos!
      """;

      // Actualiza el enlace en la base de datos para mantenerlo actualizado
      await supabase
          .from('matches')
          .update({'enlace': shareableLink})
          .eq('id', matchId);

      await Share.share(
        message,
        subject: 'Invitación a partido de fútbol',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al compartir: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _copyMatchLink(Map<String, dynamic> match) {
    try {
      // Obtener el ID del partido
      final int matchId = match['id'];
      
      // Usar el dominio real de Netlify para el enlace
      final String shareableLink = "https://statsfootpro.netlify.app/match/$matchId";
      
      // Copiar el enlace al portapapeles
      Clipboard.setData(ClipboardData(text: shareableLink));
      
      // Actualizar también el enlace en la base de datos para mantener consistencia
      supabase
          .from('matches')
          .update({'enlace': shareableLink})
          .eq('id', matchId)
          .then((_) {
            // Mostrar mensaje de éxito
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Enlace copiado al portapapeles'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al copiar el enlace: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _manageParticipants(Map<String, dynamic> match) async {
    // Navegar a la pantalla de gestión de equipos
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TeamManagementScreen(match: match),
      ),
    );
    
    // Si se realizaron cambios, actualizamos la lista de partidos
    if (result == true) {
      _fetchMatches();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mis Partidos'),
        centerTitle: true,
        backgroundColor: Colors.blue.shade800,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Todos Mis Partidos'), // Updated label
            Tab(text: 'Invitaciones Pendientes'), // Updated label
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
            : _error != null
                ? _buildErrorMessage()
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildMatchListView(_myMatches, isOrganizer: true),
                      _buildMatchListView(_invitedMatches, isOrganizer: false),
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

  Widget _buildErrorMessage() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.white,
              size: 70,
            ),
            SizedBox(height: 20),
            Text(
              _error ?? 'Ocurrió un error',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _fetchMatches,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.blue.shade800,
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchListView(List<Map<String, dynamic>> matches, {required bool isOrganizer}) {
    return RefreshIndicator(
      onRefresh: _fetchMatches,
      child: matches.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isOrganizer ? Icons.sports_soccer : Icons.mail_outline,
                    color: Colors.white.withOpacity(0.8),
                    size: 80,
                  ),
                  SizedBox(height: 20),
                  Text(
                    isOrganizer
                        ? 'Aún no tienes partidos'
                        : 'No hay invitaciones disponibles',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 10),
                  Text(
                    isOrganizer
                        ? 'Toca el botón + para crear uno nuevo'
                        : 'Esta función estará disponible próximamente',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: matches.length,
              itemBuilder: (context, index) {
                final match = matches[index];
                
                // Determinar si el usuario actual es organizador de este partido específico
                // Usar el campo isOrganizer que añadimos al cargar los datos
                final bool isUserOrganizerOfMatch = match['isOrganizer'] == true;
                
                return _buildMatchCard(match, isOrganizer: isUserOrganizerOfMatch);
              },
            ),
    );
  }

  Widget _buildMatchCard(Map<String, dynamic> match, {required bool isOrganizer}) {
    final DateTime matchDate = DateTime.parse(match['fecha']);
    final String formattedDate = '${matchDate.day}/${matchDate.month}/${matchDate.year}';
    final String formattedTime = '${matchDate.hour.toString().padLeft(2, '0')}:${matchDate.minute.toString().padLeft(2, '0')}';
    
    // Determine if the match is upcoming or past
    final bool isPast = matchDate.isBefore(DateTime.now());

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Header
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isPast
                    ? [Colors.grey.shade700, Colors.grey.shade600]
                    : [Colors.blue.shade800, Colors.blue.shade700],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.sports_soccer,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        match['nombre'] ?? 'Partido sin nombre',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    _buildStatusBadge(isPast),
                  ],
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    _buildInfoBadge(Icons.calendar_today, formattedDate),
                    SizedBox(width: 8),
                    _buildInfoBadge(Icons.access_time, formattedTime),
                    Spacer(),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade600,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        match['formato'],
                        style: TextStyle(
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
          
          // Content
          Container(
            color: Colors.white,
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                // Organizer info
                if (match['profiles'] != null)
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.blue.shade100),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundImage: match['profiles']['avatar_url'] != null
                              ? NetworkImage(match['profiles']['avatar_url'])
                              : null,
                          child: match['profiles']['avatar_url'] == null
                              ? Icon(Icons.person, size: 16)
                              : null,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isOrganizer ? 'Organizado por ti' : 'Organizado por',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue.shade800,
                                ),
                              ),
                              if (!isOrganizer)
                                Text(
                                  match['profiles']['username'] ?? 'Desconocido',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade800,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        // Mostrar insignia si el usuario participa pero no organiza
                        if (!isOrganizer)
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.green.shade300, width: 1),
                            ),
                            child: Text(
                              'Participas',
                              style: TextStyle(
                                color: Colors.green.shade800,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                
                SizedBox(height: 16),
                
                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: isOrganizer
                      ? [
                          _buildActionButton(
                            icon: Icons.people,
                            label: 'Participantes',
                            onPressed: () => _manageParticipants(match),
                            color: Colors.purple,
                          ),
                          _buildActionButton(
                            icon: Icons.article,
                            label: 'Ver Detalles',
                            onPressed: () => _navigateToMatchJoinScreen(match['id'].toString()),
                            color: Colors.blue,
                          ),
                          _buildActionButton(
                            icon: Icons.share,
                            label: 'Compartir',
                            onPressed: () => _shareMatchLink(match),
                            color: Colors.green,
                          ),
                        ]
                      : [
                          _buildActionButton(
                            icon: Icons.article,
                            label: 'Ver Detalles',
                            onPressed: () => _navigateToMatchJoinScreen(match['id'].toString()),
                            color: Colors.blue,
                          ),
                        ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  void _navigateToMatchJoinScreen(String matchId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MatchDetailsScreen(matchId: matchId),
      ),
    );
  }

  Widget _buildInfoBadge(IconData icon, String text) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.white.withOpacity(0.9),
            size: 14,
          ),
          SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(bool isPast) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isPast ? Colors.grey.shade600 : Colors.orange.shade600,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPast ? Icons.event_busy : Icons.event_available,
            color: Colors.white,
            size: 14,
          ),
          SizedBox(width: 4),
          Text(
            isPast ? 'Pasado' : 'Próximo',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required MaterialColor color,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color.shade700,
                size: 20,
              ),
            ),
            SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color.shade700,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}