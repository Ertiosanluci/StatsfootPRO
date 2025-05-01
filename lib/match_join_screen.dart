import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fluttertoast/fluttertoast.dart';

class MatchJoinScreen extends StatefulWidget {
  final String matchId;
  
  const MatchJoinScreen({Key? key, required this.matchId}) : super(key: key);
  
  @override
  _MatchJoinScreenState createState() => _MatchJoinScreenState();
}

class _MatchJoinScreenState extends State<MatchJoinScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  bool _isLoading = true;
  Map<String, dynamic>? _matchData;
  String? _errorMessage;
  bool _alreadyJoined = false;
  bool _isJoining = false;
  String _creatorName = 'Desconocido';
  
  @override
  void initState() {
    super.initState();
    // Añadir un pequeño retraso para asegurarnos de que todo está inicializado
    Future.delayed(Duration(milliseconds: 300), () {
      _loadMatchData();
    });
  }
  
  Future<void> _loadMatchData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      
      // Debug para ver el ID recibido
      debugPrint('Intentando cargar partido con ID: "${widget.matchId}"');
      
      // Asegurarnos de que el ID no está vacío
      if (widget.matchId.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'ID de partido inválido';
        });
        return;
      }
      
      // Convertir a entero para asegurarnos que es un ID válido si es numérico
      int? matchIdInt;
      try {
        matchIdInt = int.parse(widget.matchId);
        debugPrint('ID convertido a entero: $matchIdInt');
      } catch (e) {
        // Si no se puede convertir, puede ser que el ID tenga otro formato
        debugPrint('No se pudo convertir el ID a entero: $e');
      }
      
      // Primero, obtener los datos básicos del partido
      final matchResponse = await supabase
          .from('matches')
          .select()
          .eq('id', matchIdInt ?? widget.matchId)
          .maybeSingle();
      
      debugPrint('Respuesta de la consulta matches: ${matchResponse != null ? 'Datos encontrados' : 'NULL'}');
      
      if (matchResponse == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'El partido no existe o ha sido eliminado';
        });
        return;
      }
      
      // Combinar los datos
      var completeMatchData = Map<String, dynamic>.from(matchResponse);
      
      // Luego, buscar información del creador si existe creator_id
      if (matchResponse['creator_id'] != null) {
        try {
          String creatorId = matchResponse['creator_id'].toString();
          
          // 1. Primero intentamos obtener el perfil directamente desde la tabla profiles
          final creatorProfile = await supabase
              .from('profiles')
              .select('nombre, apellido')
              .eq('id', creatorId)
              .maybeSingle();
          
          if (creatorProfile != null && creatorProfile['nombre'] != null) {
            // Si encontramos el perfil, usamos ese nombre
            String nombreCompleto = creatorProfile['nombre'];
            if (creatorProfile['apellido'] != null) {
              nombreCompleto += " " + creatorProfile['apellido'];
            }
            _creatorName = nombreCompleto;
            debugPrint('Nombre del creador obtenido de profiles: $_creatorName');
          } else {
            // 2. Si no encontramos el perfil, intentamos obtener información del usuario directamente
            try {
              // Esta consulta podría no funcionar dependiendo de los permisos de Supabase
              // pero lo intentamos como fallback
              final adminClient = supabase.rest;
              final response = await adminClient.from('profiles')
                .select('nombre, apellido, email')
                .eq('id', creatorId)
                .maybeSingle();
              
              if (response != null) {
                if (response['nombre'] != null) {
                  String nombreCompleto = response['nombre'];
                  if (response['apellido'] != null) {
                    nombreCompleto += " " + response['apellido'];
                  }
                  _creatorName = nombreCompleto;
                } else if (response['email'] != null) {
                  _creatorName = response['email'];
                }
                debugPrint('Nombre del creador obtenido por método alternativo: $_creatorName');
              }
            } catch (e) {
              debugPrint('No se pudo obtener información del usuario: $e');
              _creatorName = 'Usuario #$creatorId';
            }
          }
        } catch (e) {
          debugPrint('Error al obtener datos del creador: $e');
          _creatorName = 'Desconocido';
        }
      } else {
        debugPrint('No se encontró creator_id en los datos del partido');
        _creatorName = 'Desconocido';
      }
      
      // Check if user is already in this match
      final currentUserId = supabase.auth.currentUser?.id;
      if (currentUserId != null) {
        try {
          final participantResponse = await supabase
              .from('match_participants')
              .select()
              .eq('match_id', matchIdInt ?? widget.matchId)
              .eq('user_id', currentUserId)
              .maybeSingle();
          
          setState(() {
            _alreadyJoined = participantResponse != null;
          });
        } catch (e) {
          debugPrint('Error al verificar participación: $e');
          // Continuamos asumiendo que no está unido
        }
      }
      
      setState(() {
        _matchData = completeMatchData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error al cargar datos del partido: $e';
      });
      debugPrint('Error detallado al cargar datos: $e');
    }
  }
  
  Future<void> _joinMatch() async {
    if (_isJoining) return;
    
    final currentUser = supabase.auth.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Debes iniciar sesión para unirte al partido'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    setState(() {
      _isJoining = true;
    });
    
    try {
      // Convertir ID a entero si es posible
      var matchIdValue;
      try {
        matchIdValue = int.parse(widget.matchId);
      } catch (e) {
        matchIdValue = widget.matchId;
      }
      
      // Check if user profile exists
      final profileResponse = await supabase
          .from('profiles')
          .select()
          .eq('id', currentUser.id)
          .maybeSingle();
      
      if (profileResponse == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se encontró tu perfil. Por favor, completa tu registro.'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isJoining = false;
        });
        return;
      }
      
      // Debug para mostrar los datos que se están insertando
      debugPrint('Intentando unirse al partido con ID: $matchIdValue');
      
      // Add user to match participants
      await supabase.from('match_participants').insert({
        'match_id': matchIdValue,
        'user_id': currentUser.id,
        'equipo': null, // Team will be assigned by the organizer
        'es_organizador': false,
        'joined_at': DateTime.now().toIso8601String(),
      });
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('¡Te has unido al partido correctamente!'),
          backgroundColor: Colors.green,
        ),
      );
      
      setState(() {
        _alreadyJoined = true;
        _isJoining = false;
      });
      
      // Refresh match data to see updated participant list
      _loadMatchData();
    } catch (e) {
      debugPrint('Error al unirse: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al unirse al partido: $e'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isJoining = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Unirse al Partido'),
        centerTitle: true,
        backgroundColor: Colors.blue.shade800,
      ),
      body: _isLoading 
          ? _buildLoadingView() 
          : _errorMessage != null 
              ? _buildErrorView() 
              : _buildMatchView(),
    );
  }
  
  Widget _buildLoadingView() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade300, Colors.blue.shade800],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 3,
            ),
            SizedBox(height: 20),
            Text(
              'Cargando información del partido...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
            // Añadir el ID para depuración
            SizedBox(height: 10),
            Text(
              'ID: ${widget.matchId}',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildErrorView() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade300, Colors.blue.shade800],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                color: Colors.white,
                size: 80,
              ),
              SizedBox(height: 20),
              Text(
                'Error',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10),
              Text(
                _errorMessage ?? 'Ha ocurrido un error',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.blue.shade800,
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Text(
                  'Volver',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildMatchView() {
    if (_matchData == null) return SizedBox();
    
    // Asegurarnos de que la fecha no es nula
    DateTime matchDate;
    String formattedDate = 'No disponible';
    String formattedTime = 'No disponible';
    
    try {
      if (_matchData!['fecha'] != null) {
        matchDate = DateTime.parse(_matchData!['fecha']);
        formattedDate = '${matchDate.day}/${matchDate.month}/${matchDate.year}';
        formattedTime = '${matchDate.hour.toString().padLeft(2, '0')}:${matchDate.minute.toString().padLeft(2, '0')}';
      }
    } catch (e) {
      debugPrint('Error al formatear fecha: $e');
    }
    
    // Validar el formato
    final String formato = _matchData!['formato']?.toString() ?? 'No especificado';
    
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
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Match banner
              Container(
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                  image: DecorationImage(
                    image: AssetImage('assets/habilidades.png'),
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
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
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
                    SizedBox(height: 10),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 25, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade900.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        _matchData!['nombre']?.toString() ?? 'Partido sin nombre',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: 25),
              
              // Match details card
              Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: EdgeInsets.all(20),
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
                          SizedBox(width: 10),
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
                      
                      Divider(height: 30),
                      
                      // Info rows
                      _buildInfoRow(
                        icon: Icons.format_list_numbered,
                        title: 'Formato',
                        value: formato,
                      ),
                      
                      _buildInfoRow(
                        icon: Icons.calendar_today,
                        title: 'Fecha',
                        value: formattedDate,
                      ),
                      
                      _buildInfoRow(
                        icon: Icons.access_time,
                        title: 'Hora',
                        value: formattedTime,
                      ),
                      
                      _buildInfoRow(
                        icon: Icons.person,
                        title: 'Organizado por',
                        value: _creatorName,
                      ),
                    ],
                  ),
                ),
              ),
              
              SizedBox(height: 30),
              
              // Join button
              _buildJoinButton(),
              
              SizedBox(height: 20),
              
              // Back button
              OutlinedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.white),
                  padding: EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'Volver',
                  style: TextStyle(
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 15),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: Colors.blue.shade700,
              size: 20,
            ),
          ),
          SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildJoinButton() {
    if (_alreadyJoined) {
      return Container(
        padding: EdgeInsets.symmetric(vertical: 15),
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
            SizedBox(width: 10),
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
    } else {
      return ElevatedButton(
        onPressed: _isJoining ? null : _joinMatch,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green.shade600,
          disabledBackgroundColor: Colors.green.shade300,
          padding: EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: _isJoining
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Uniéndose...',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.sports_soccer),
                  SizedBox(width: 10),
                  Text(
                    'UNIRSE AL PARTIDO',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
      );
    }
  }
}