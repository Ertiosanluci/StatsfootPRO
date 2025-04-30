import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'create_match.dart';
import 'match_join_screen.dart';
import 'match_details_screen.dart';

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

      // Fetch matches organized by the current user
      final organizedMatchesResponse = await supabase
          .from('matches')
          .select('*, profiles!creator_id(*)')
          .eq('creador_id', currentUser.id)
          .order('fecha', ascending: false);

      // Fetch matches where the user is a participant
      final participantMatchesResponse = await supabase
          .from('match_participants')
          .select('match:matches(*, profiles!creator_id(*))')
          .eq('user_id', currentUser.id)
          .eq('es_organizador', false)
          .order('match(fecha)', ascending: false);

      // Extract the matches from the participant response
      final List<Map<String, dynamic>> invitedMatches = [];
      for (final item in participantMatchesResponse) {
        if (item['match'] != null) {
          invitedMatches.add(item['match']);
        }
      }

      setState(() {
        _myMatches = List<Map<String, dynamic>>.from(organizedMatchesResponse);
        _invitedMatches = invitedMatches;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Error al cargar partidos: $e';
      });
    }
  }

  void _shareMatchLink(Map<String, dynamic> match) async {
    final String? link = match['enlace'];
    if (link == null || link.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Este partido no tiene un enlace para compartir'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      // Format match information for sharing
      final DateTime matchDate = DateTime.parse(match['fecha']);
      final String formattedDate = '${matchDate.day}/${matchDate.month}/${matchDate.year}';
      final String formattedTime = '${matchDate.hour.toString().padLeft(2, '0')}:${matchDate.minute.toString().padLeft(2, '0')}';

      final String message = """
🏆 ¡Únete a mi partido de fútbol! 🏆

Partido: ${match['nombre']}
Formato: ${match['formato']}
Fecha: $formattedDate
Hora: $formattedTime

Únete usando este enlace: $link

¡Te esperamos!
      """;

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
    final String? link = match['enlace'];
    if (link == null || link.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Este partido no tiene un enlace para compartir'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    Clipboard.setData(ClipboardData(text: link));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Enlace copiado al portapapeles'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _manageParticipants(Map<String, dynamic> match) async {
    // Here you would navigate to a screen to manage participants
    // For now, let's show a simple dialog with the participant count
    try {
      final participantsResponse = await supabase
          .from('match_participants')
          .select('profiles!user_id(*)')
          .eq('match_id', match['id']);

      final List<Map<String, dynamic>> participants = [];
      for (final item in participantsResponse) {
        if (item['profiles'] != null) {
          participants.add(item['profiles']);
        }
      }

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Participantes'),
          content: Container(
            width: double.maxFinite,
            height: 300,
            child: participants.isEmpty
                ? Center(
                    child: Text('No hay participantes aún'),
                  )
                : ListView.builder(
                    itemCount: participants.length,
                    itemBuilder: (context, index) {
                      final participant = participants[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: participant['avatar_url'] != null
                              ? NetworkImage(participant['avatar_url'])
                              : null,
                          child: participant['avatar_url'] == null
                              ? Icon(Icons.person)
                              : null,
                        ),
                        title: Text(participant['nombre'] ?? 'Usuario'),
                        subtitle: Text(participant['email'] ?? ''),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cerrar'),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar participantes: $e'),
          backgroundColor: Colors.red,
        ),
      );
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
            Tab(text: 'Mis Partidos'),
            Tab(text: 'Invitaciones'),
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
                    isOrganizer ? Icons.sports_soccer : Icons.sports_handball,
                    color: Colors.white.withOpacity(0.8),
                    size: 80,
                  ),
                  SizedBox(height: 20),
                  Text(
                    isOrganizer
                        ? 'Aún no has creado ningún partido'
                        : 'No tienes invitaciones a partidos',
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
                        : 'Únete a través de un enlace compartido',
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
              itemBuilder: (context, index) => _buildMatchCard(matches[index], isOrganizer: isOrganizer),
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
                                  match['profiles']['nombre'] ?? 'Desconocido',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade800,
                                  ),
                                ),
                            ],
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
                            icon: Icons.share,
                            label: 'Compartir',
                            onPressed: () => _shareMatchLink(match),
                            color: Colors.green,
                          ),
                          _buildActionButton(
                            icon: Icons.copy,
                            label: 'Copiar Enlace',
                            onPressed: () => _copyMatchLink(match),
                            color: Colors.blue,
                          ),
                        ]
                      : [
                          _buildActionButton(
                            icon: Icons.info_outline,
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
        builder: (context) => MatchJoinScreen(matchId: matchId),
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