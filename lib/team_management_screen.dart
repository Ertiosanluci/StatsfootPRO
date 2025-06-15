import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:ui' as ui;
import 'dart:developer' as dev;
import 'dart:math' show Random;
import 'dart:async';
import 'dart:convert';

class TeamManagementScreen extends StatefulWidget {
  final Map<String, dynamic> match;
  
  const TeamManagementScreen({Key? key, required this.match}) : super(key: key);
  
  @override
  _TeamManagementScreenState createState() => _TeamManagementScreenState();
}

class _TeamManagementScreenState extends State<TeamManagementScreen> with SingleTickerProviderStateMixin {
  // Método para obtener las posiciones de formación según el número de jugadores
  List<List<double>> _getFormationPositions(int totalPlayers) {
    // Posiciones relativas para diferentes formaciones (x, y) donde x e y están entre 0 y 1
    switch (totalPlayers) {
      case 1:
        return [[0.5, 0.5]]; // Un solo jugador en el centro
      case 2:
        return [
          [0.3, 0.5], // Dos jugadores en línea horizontal
          [0.7, 0.5],
        ];
      case 3:
        return [
          [0.5, 0.3], // Formación triangular
          [0.3, 0.7],
          [0.7, 0.7],
        ];
      case 4:
        return [
          [0.3, 0.3], // Formación en diamante
          [0.7, 0.3],
          [0.3, 0.7],
          [0.7, 0.7],
        ];
      case 5:
        return [
          [0.5, 0.2], // Formación 2-1-2
          [0.2, 0.4],
          [0.8, 0.4],
          [0.3, 0.7],
          [0.7, 0.7],
        ];
      case 6:
        return [
          [0.3, 0.2], // Formación 2-2-2
          [0.7, 0.2],
          [0.2, 0.5],
          [0.8, 0.5],
          [0.3, 0.8],
          [0.7, 0.8],
        ];
      case 7:
        return [
          [0.5, 0.15], // Formación 2-3-2
          [0.2, 0.3],
          [0.8, 0.3],
          [0.2, 0.6],
          [0.5, 0.6],
          [0.8, 0.6],
          [0.5, 0.85],
        ];
      default:
        // Para 8 o más jugadores, crear una distribución uniforme
        List<List<double>> positions = [];
        int rows = (totalPlayers / 3).ceil(); // Aproximadamente 3 jugadores por fila
        int remaining = totalPlayers;
        
        for (int row = 0; row < rows; row++) {
          int playersInRow = (remaining / (rows - row)).ceil();
          remaining -= playersInRow;
          
          for (int i = 0; i < playersInRow; i++) {
            double x = (i + 1) / (playersInRow + 1);
            double y = (row + 1) / (rows + 1);
            positions.add([x, y]);
          }
        }
        
        return positions;
    }
  }
  
  // Método para verificar si una posición está ocupada por un jugador
  // Implementación movida a la línea 1391
  final SupabaseClient supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<Map<String, dynamic>> _participants = [];
  List<Map<String, dynamic>> _teamClaro = [];
  List<Map<String, dynamic>> _teamOscuro = [];
  List<Map<String, dynamic>> _unassignedParticipants = [];
  
  // Controlador de pestañas para alternar entre equipos
  late TabController _tabController;
  
  // Variables para gestionar posiciones de jugadores en el campo
  Map<String, Offset> _teamClaroPositions = {};
  Map<String, Offset> _teamOscuroPositions = {};
  String? _draggingPlayerId;
  GlobalKey _fieldKey = GlobalKey();
  Map<String, bool> _elevatedPlayers = {};
  
  // Mapas para rastrear qué posición ocupa cada jugador
  Map<int, String> _teamClaroPositionIndices = {};
  Map<int, String> _teamOscuroPositionIndices = {};
  // Variable para almacenar la última posición de toque
  Offset? _lastTapPosition;
  // Variables para el marcador
  int _resultadoClaro = 0;
  int _resultadoOscuro = 0;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadParticipants();
    
    // Cargar el marcador del partido si existe
    _loadMatchScore();
    
    // Actualizamos la pestaña cuando cambia
    _tabController.addListener(() {
      setState(() {}); // Para actualizar colores de pestañas
    });
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _loadParticipants() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Primero, cargar las posiciones guardadas del partido
      await _loadSavedPositions();
      
      // Obtener el ID del usuario actual
      final currentUserId = supabase.auth.currentUser?.id;
      
      // Cargar participantes del partido
      final participantsResponse = await supabase
          .from('match_participants')
          .select('*')
          .eq('match_id', widget.match['id']);
      
      // Lista completa de participantes
      final List<Map<String, dynamic>> allParticipants = [];
      
      // Equipos
      final List<Map<String, dynamic>> teamClaro = [];
      final List<Map<String, dynamic>> teamOscuro = [];
      final List<Map<String, dynamic>> unassigned = [];
      
      for (final item in participantsResponse) {
        try {
          // Obtener información básica del usuario desde auth
          final String userId = item['user_id'];
          
          // Intentar obtener datos del usuario directamente de la sesión actual
          String userName = 'Usuario';
          String userEmail = '';
          String? avatarUrl;
          
          try {
            // Si es el usuario actual, podemos obtener su email directamente
            if (userId == currentUserId && supabase.auth.currentUser?.email != null) {
              userEmail = supabase.auth.currentUser!.email!;
              userName = userEmail.split('@')[0]; // Usar parte del email como nombre
              
              // Intentar obtener el avatar del perfil del usuario actual
              try {
                final currentUserProfile = await supabase
                    .from('profiles')
                    .select('username, avatar_url')
                    .eq('id', userId)
                    .maybeSingle();
                
                if (currentUserProfile != null) {
                  userName = currentUserProfile['username'] ?? userName;
                  avatarUrl = currentUserProfile['avatar_url'];
                }
              } catch (e) {
                print('Error al obtener avatar del usuario actual: $e');
              }
            } else {
              // Para otros usuarios, intentar consultar datos básicos
              try {
                // Intentar obtener el perfil desde la tabla profiles
                final profileData = await supabase
                    .from('profiles')
                    .select('username, avatar_url')
                    .eq('id', userId)
                    .maybeSingle();
                
                if (profileData != null) {
                  userName = profileData['username'] ?? 'Usuario';
                  avatarUrl = profileData['avatar_url'];
                }
              } catch (e) {
                print('No se pudo obtener metadata para usuario $userId: $e');
                // Continuar con valores predeterminados
              }
            }
          } catch (e) {
            print('No se pudo obtener metadata para usuario $userId: $e');
            // Continuar con valores predeterminados
          }
          
          final participant = {
            'id': item['id'],
            'user_id': userId,
            'equipo': item['equipo'],
            'es_organizador': item['es_organizador'],
            'nombre': userName,
            'avatar_url': avatarUrl,
            'email': userEmail,
          };
          
          allParticipants.add(participant);
          
          // Asignar al equipo correspondiente
          if (item['equipo'] == 'claro') {
            teamClaro.add(participant);
          } else if (item['equipo'] == 'oscuro') {
            teamOscuro.add(participant);
          } else {
            unassigned.add(participant);
          }
        } catch (userError) {
          print('Error al procesar usuario para participante ${item['id']}: $userError');
        }
      }
      
      // Actualizar los datos de los equipos
      setState(() {
        _participants = allParticipants;
        _teamClaro = teamClaro;
        _teamOscuro = teamOscuro;
        _unassignedParticipants = unassigned;
      });
      
      // Calcular los índices de posición para ambos equipos
      _calculatePositionIndices();
      // Imprimir información de los equipos y sus jugadores
      print('\n=== INFORMACIÓN DE EQUIPOS Y JUGADORES ===');
      print('Total de participantes: ${_participants.length}');
      print('EQUIPO CLARO (${_teamClaro.length} jugadores):');
      for (var player in _teamClaro) {
        print('  • ${player['nombre']} (ID: ${player['id']}) - Equipo: ${player['equipo']}');
      }
      
      print('EQUIPO OSCURO (${_teamOscuro.length} jugadores):');
      for (var player in _teamOscuro) {
        print('  • ${player['nombre']} (ID: ${player['id']}) - Equipo: ${player['equipo']}');
      }
      
      print('SIN ASIGNAR (${_unassignedParticipants.length} jugadores):');
      for (var player in _unassignedParticipants) {
        print('  • ${player['nombre']} (ID: ${player['id']}) - Equipo: ${player['equipo'] ?? "null"}');
      }
      print('==========================================\n');
      
      // Asignar automáticamente jugadores sin posición a posiciones disponibles en el campo
      _autoAssignPlayersToPositions();
      
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error al cargar participantes: $e');
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar participantes: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  // Obtener una posición predeterminada para un jugador según su índice
  Offset _getDefaultPosition(int index, bool isTeamA) {
    final String format = widget.match['formato'] ?? '5v5';
    final int totalPlayers = int.tryParse(format.split('v')[0]) ?? 5;
    
    List<List<double>> positions = _getFormationPositions(totalPlayers);
    if (index < positions.length) {
      return Offset(positions[index][0], isTeamA ? positions[index][1] : 1.0 - positions[index][1]);
    }
    return Offset(0.5, isTeamA ? 0.3 : 0.7); // Posición por defecto
  }
  
  Future<void> _assignToTeam(Map<String, dynamic> participant, String? team) async {
    try {
      final String participantId = participant['id'].toString();
      final String oldTeam = participant['equipo'];  // Guardamos el equipo anterior
      
      // Verificar si el jugador ya está en el equipo de destino
      if (oldTeam == team) {
        print('El jugador ya está en el equipo destino');
        return;
      }
      
      // Primero actualizar en la base de datos para evitar inconsistencias
      await supabase
          .from('match_participants')
          .update({'equipo': team})
          .eq('id', participantId);
      
      // Ahora actualizamos localmente los datos
      setState(() {
        // Eliminar completamente al jugador de todas las estructuras
        
        // 1. Eliminar al jugador de su lista de equipo actual
        if (oldTeam == 'claro') {
          _teamClaro.removeWhere((p) => p['id'].toString() == participantId);
        } else if (oldTeam == 'oscuro') {
          _teamOscuro.removeWhere((p) => p['id'].toString() == participantId);
        } else {
          _unassignedParticipants.removeWhere((p) => p['id'].toString() == participantId);
        }
        
        // 2. Eliminar todas las referencias de posiciones del jugador (independientemente del equipo)
        _teamClaroPositionIndices.removeWhere((_, id) => id == participantId);
        _teamOscuroPositionIndices.removeWhere((_, id) => id == participantId);
        _teamClaroPositions.remove(participantId);
        _teamOscuroPositions.remove(participantId);
        _elevatedPlayers.remove(participantId);
        
        // 3. Actualizar el equipo en el objeto del participante
        participant['equipo'] = team;
        
        // 4. Añadir al jugador a su nuevo equipo/lista
        if (team == 'claro') {
          _teamClaro.add(participant);
          // Asignar posición predeterminada si no tiene una
          if (!_teamClaroPositions.containsKey(participantId)) {
            _teamClaroPositions[participantId] = 
                _getDefaultPosition(_teamClaro.length - 1, true);
          }
        } else if (team == 'oscuro') {
          _teamOscuro.add(participant);
          // Asignar posición predeterminada si no tiene una
          if (!_teamOscuroPositions.containsKey(participantId)) {
            _teamOscuroPositions[participantId] = 
                _getDefaultPosition(_teamOscuro.length - 1, false);
          }
        } else if (team == null) {
          // Si el equipo es null, significa que el jugador va a "sin asignar"
          _unassignedParticipants.add(participant);
        }
        
        // Forzar actualización para refrescar posiciones en el campo
        _redrawPositionSlots();
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Participante asignado al ${team == 'claro' ? 'Equipo Claro' : team == 'oscuro' ? 'Equipo Oscuro' : 'grupo sin asignar'}'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 1),
        ),
      );
    } catch (e) {
      print('Error al asignar equipo: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al asignar equipo: $e'),
          backgroundColor: Colors.red,
        ),
      );
      
      // Recargar participantes para recuperar el estado real
      _loadParticipants();
    }
  }
  
  // Método para forzar la actualización visual de todas las posiciones en el campo
  void _redrawPositionSlots() {
    // Este método no hace nada directamente, pero al llamarlo dentro de setState
    // fuerza a Flutter a redibujar el widget, lo que actualiza las posiciones vacías
    if (mounted) {
      // Solo un truco para forzar actualización visual
      _fieldKey = GlobalKey();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gestión de Equipos'),
        centerTitle: true,
        backgroundColor: Colors.blue.shade800,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
        // Cambiar el color de la flecha de navegación a blanco
        iconTheme: IconThemeData(
          color: Colors.white, // Flecha de navegación blanca
        ),
        actions: [
          // Botón de actualizar
          IconButton(
            onPressed: _loadParticipants,
            icon: Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Actualizar',
          ),
          // Botón de guardar movido a la barra superior
          IconButton(
            onPressed: _saveAndExit,
            icon: Icon(Icons.save, color: Colors.white),
            tooltip: 'Guardar',
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade200, Colors.blue.shade700],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                children: [
                  // Información del partido
                  _buildMatchInfo(),
                  
                  // Pestañas para seleccionar equipos
                  _buildTabsSelector(),
                  
                  // Contenido de las pestañas (campo de fútbol o lista)
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      physics: NeverScrollableScrollPhysics(),
                      children: [
                        // Campo del Equipo Claro
                        _buildFootballField(true),
                        
                        // Campo del Equipo Oscuro
                        _buildFootballField(false),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
  
  Widget _buildTabsSelector() {
    final int teamClaroSize = int.tryParse(widget.match['formato']?.split('v')[0] ?? '5') ?? 5;
    final int teamOscuroSize = int.tryParse(widget.match['formato']?.split('v')[1] ?? '5') ?? 5;
  
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      height: 48, // Aumentar altura para dar más espacio
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: TabBar(
        controller: _tabController,
        padding: EdgeInsets.zero,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
          color: _tabController.index == 0 
              ? Colors.blue.shade800
              : Colors.red.shade800,
        ),
        indicatorColor: Colors.transparent,
        indicatorWeight: 0,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white.withOpacity(0.7),
        labelStyle: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
          letterSpacing: 0.5,
        ),
        tabs: [
          // Tab Equipo Claro
          Tab(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.group, size: 18),
                  SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      "Equipo Claro",
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: 4),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _teamClaro.length == teamClaroSize
                          ? Colors.green.withOpacity(0.7)
                          : Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      "${_teamClaro.length}/${teamClaroSize}",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Tab Equipo Oscuro
          Tab(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.group, size: 18),
                  SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      "Equipo Oscuro",
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: 4),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _teamOscuro.length == teamOscuroSize
                          ? Colors.green.withOpacity(0.7)
                          : Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      "${_teamOscuro.length}/${teamOscuroSize}",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFootballField(bool isTeamA) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Usar casi todo el espacio disponible, con un margen más visible
        final double maxWidth = constraints.maxWidth;
        final double maxHeight = constraints.maxHeight;
        
        // Aumentar el margen a 5px para dar más espacio alrededor del campo
        final double margin = 5.0;
        
        // Usar la proporción de campo pero priorizando la altura máxima
        final double aspectRatio = 105 / 68;
        
        // Forzar la altura a ser máxima menos el margen
        double fieldHeight = maxHeight - (margin * 2);
        // Calcular el ancho basado en la altura pero asegurando que no exceda el ancho disponible
        double fieldWidth = fieldHeight * aspectRatio;
        if (fieldWidth > maxWidth - (margin * 2)) {
          fieldWidth = maxWidth - (margin * 2);
          // No recalculamos la altura para mantenerla al máximo
        }
        
        return Container(
          width: maxWidth,
          height: maxHeight,
          // Padding un poco más visible
          padding: EdgeInsets.all(margin),
          child: Stack(
            children: [
              // Campo de fútbol centrado horizontalmente, ocupando casi toda la altura
              Positioned(
                left: (maxWidth - fieldWidth) / 2,
                top: margin,
                child: Container(
                  key: _fieldKey,
                  width: fieldWidth,
                  height: fieldHeight,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32), // Verde campo de fútbol más realista
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 15,
                        offset: Offset(0, 5),
                      ),
                    ],
                    // Efecto de textura de césped
                    image: DecorationImage(
                      image: AssetImage('assets/ic_launcher.png'), // Usamos una imagen existente como textura
                      fit: BoxFit.cover,
                      opacity: 0.05, // Muy sutil para no distraer
                    ),
                  ),
                  clipBehavior: Clip.antiAlias, // Para que el hijo no sobresalga del borde redondeado
                  child: Stack(
                    children: [
                      // Campo de fútbol mejorado
                      _buildFootballFieldElements(fieldWidth, fieldHeight),
                      
                      // Añadir reflejo/brillo para dar efecto profesional
                      Positioned.fill(
                        child: CustomPaint(
                          painter: GlassPainter(),
                        ),
                      ),
                      
                      // Marcador de goles eliminado
                      
                      // Detector de toques para campo completo
                      Positioned.fill(
                        child: GestureDetector(
                          onTapDown: (details) {
                            setState(() {
                              // Capturar la posición para poder usar posiciones vacías
                              final RenderBox renderBox = _fieldKey.currentContext!.findRenderObject() as RenderBox;
                              final Offset localPosition = renderBox.globalToLocal(details.globalPosition);
                              _lastTapPosition = Offset(
                                localPosition.dx / renderBox.size.width,
                                localPosition.dy / renderBox.size.height
                              );
                            });
                          },
                        ),
                      ),
                      
                      // Posiciones vacías para el equipo seleccionado
                      ..._buildEmptyPositions(
                        int.parse(widget.match['formato']?.split('v')[isTeamA ? 0 : 1] ?? '5'),
                        isTeamA,
                        fieldWidth,
                        fieldHeight,
                      ),
                      
                      // Jugadores del equipo seleccionado
                      if (isTeamA && _teamClaro.isNotEmpty)
                        ..._buildTeamPlayers(_teamClaro, _teamClaroPositions, true, fieldWidth, fieldHeight),
                      
                      if (!isTeamA && _teamOscuro.isNotEmpty)
                        ..._buildTeamPlayers(_teamOscuro, _teamOscuroPositions, false, fieldWidth, fieldHeight),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildFootballFieldElements(double width, double height) {
    return Stack(
      children: [
        // Línea central
        Positioned(
          top: height / 2 - 1,
          left: 0,
          right: 0,
          child: Container(
            height: 2,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
        
        // Círculo central
        Positioned(
          top: height / 2 - width * 0.1,
          left: width / 2 - width * 0.1,
          child: Container(
            width: width * 0.2,
            height: width * 0.2,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.8), width: 2),
            ),
          ),
        ),
        
        // Punto central
        Positioned(
          top: height / 2 - 4,
          left: width / 2 - 4,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ),
        
        // Área de penalti superior
        Positioned(
          top: 0,
          left: width * 0.15,
          child: Container(
            width: width * 0.7,
            height: height * 0.2,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white.withOpacity(0.8), width: 2),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(8),
                bottomRight: Radius.circular(8),
              ),
            ),
          ),
        ),
        
        // Área de portería superior
        Positioned(
          top: 0,
          left: width * 0.35,
          child: Container(
            width: width * 0.3,
            height: height * 0.08,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white.withOpacity(0.8), width: 2),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(4),
              ),
            ),
          ),
        ),
        
        // Punto de penalti superior
        Positioned(
          top: height * 0.15,
          left: width / 2 - 4,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ),
        
        // Área de penalti inferior
        Positioned(
          bottom: 0,
          left: width * 0.15,
          child: Container(
            width: width * 0.7,
            height: height * 0.2,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white.withOpacity(0.8), width: 2),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
          ),
        ),
        
        // Área de portería inferior
        Positioned(
          bottom: 0,
          left: width * 0.35,
          child: Container(
            width: width * 0.3,
            height: height * 0.08,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white.withOpacity(0.8), width: 2),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
          ),
        ),
        
        // Punto de penalti inferior
        Positioned(
          bottom: height * 0.15,
          left: width / 2 - 4,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ),
        
        // Portería superior
        Positioned(
          top: 0,
          left: width * 0.4,
          child: Container(
            width: width * 0.2,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(0.5),
                  blurRadius: 5,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        ),
        
        // Portería inferior
        Positioned(
          bottom: 0,
          left: width * 0.4,
          child: Container(
            width: width * 0.2,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(0.5),
                  blurRadius: 5,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  List<Widget> _buildTeamPlayers(
      List<Map<String, dynamic>> team, 
      Map<String, Offset> positions, 
      bool isTeamA, 
      double fieldWidth, 
      double fieldHeight) {
    List<Widget> playerWidgets = [];
    
    for (int i = 0; i < team.length; i++) {
      final player = team[i];
      final playerId = player['id'].toString();
      
      // Obtener la posición actual o usar una posición predeterminada
      final Offset position = positions[playerId] ?? 
          _getDefaultPosition(i, isTeamA);
      
      // Convertir la posición relativa (0-1) a coordenadas reales en el campo
      final double posX = position.dx * fieldWidth;
      final double posY = position.dy * fieldHeight;
      
      // Crear widget para el avatar del jugador
      playerWidgets.add(
        Positioned(
          left: posX - 30,
          top: posY - 30,
          child: GestureDetector(
            onLongPress: () {
              setState(() {
                _draggingPlayerId = playerId;
                _elevatedPlayers[playerId] = true;
              });
            },
            onLongPressMoveUpdate: (details) {
              if (_draggingPlayerId == playerId) {
                setState(() {
                  _elevatedPlayers[playerId] = true;
                  
                  // Calcular la nueva posición relativa
                  final RenderBox renderBox = _fieldKey.currentContext!.findRenderObject() as RenderBox;
                  final Offset localPosition = renderBox.globalToLocal(details.globalPosition);

                  double dx = localPosition.dx / renderBox.size.width;
                  double dy = localPosition.dy / renderBox.size.height;

                  // Limitar posiciones para que no salgan del campo
                  dx = dx.clamp(0.05, 0.95);
                  dy = dy.clamp(0.05, 0.95);
                  
                  if (isTeamA) {
                    _teamClaroPositions[playerId] = Offset(dx, dy);
                  } else {
                    _teamOscuroPositions[playerId] = Offset(dx, dy);
                  }
                });
              }
            },            onLongPressEnd: (_) {
              setState(() {
                _elevatedPlayers[playerId] = false;
                _draggingPlayerId = null;
              });
            },
            onTap: () => _updatePlayerTeam(player['id'], player['equipo']),
            child: _buildPlayerAvatar(player, isTeamA),
          ),
        ),
      );
      
      // Añadir el nombre del jugador debajo
      playerWidgets.add(
        Positioned(
          left: posX - 40,
          top: posY + 32,
          child: Container(
            width: 80,
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isTeamA 
                    ? Colors.blue.shade300.withOpacity(0.5) 
                    : Colors.red.shade300.withOpacity(0.5),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              player['nombre'] ?? 'Usuario',
              style: TextStyle(
                color: isTeamA ? Colors.blue.shade200 : Colors.red.shade200,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      );
    }
    
    return playerWidgets;
  }
  
  Widget _buildPlayerAvatar(Map<String, dynamic> player, bool isTeamA) {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        // Fondo con efecto de brillo
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: isTeamA 
                  ? [Colors.blue.withOpacity(0.2), Colors.blue.withOpacity(0.4)] 
                  : [Colors.red.withOpacity(0.2), Colors.red.withOpacity(0.4)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: Colors.white,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: (isTeamA ? Colors.blue : Colors.red).withOpacity(0.3),
                blurRadius: 12,
                spreadRadius: 2,
                offset: Offset(0, 3),
              ),
              BoxShadow(
                color: Colors.black26,
                blurRadius: 5,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: player['avatar_url'] != null
                ? ClipOval(
                    child: Image.network(
                      player['avatar_url'],
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Text(
                          player['nombre'][0].toUpperCase(),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
                  )
                : Text(
                    player['nombre'][0].toUpperCase(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        
        // Efecto de brillo
        Positioned.fill(
          child: ClipOval(
            child: CustomPaint(
              painter: AvatarGlowPainter(),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildMatchInfo() {
    // Formatear fecha y hora
    final DateTime matchDate = DateTime.parse(widget.match['fecha']);
    final String formattedDate = '${matchDate.day}/${matchDate.month}/${matchDate.year}';
    final String formattedTime = '${matchDate.hour.toString().padLeft(2, '0')}:${matchDate.minute.toString().padLeft(2, '0')}';
    
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.sports_soccer, color: Colors.blue.shade800, size: 24),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.match['nombre'] ?? 'Partido sin nombre',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Añadir icono de participantes con contador
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.people, color: Colors.blue.shade800, size: 18),
                    SizedBox(width: 4),
                    Text(
                      "${_participants.length}",
                      style: TextStyle(
                        color: Colors.blue.shade800,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Divider(height: 24),
          Row(
            children: [
              _buildInfoItem(Icons.calendar_today, formattedDate),
              SizedBox(width: 24),
              _buildInfoItem(Icons.access_time, formattedTime),
              SizedBox(width: 24),
              _buildInfoItem(Icons.people, widget.match['formato'] ?? '5v5'),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.blue.shade100,
                        radius: 14,
                        child: Text(
                          '${_teamClaro.length}',
                          style: TextStyle(
                            color: Colors.blue.shade800,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Equipo Claro',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.red.shade100,
                        radius: 14,
                        child: Text(
                          '${_teamOscuro.length}',
                          style: TextStyle(
                            color: Colors.red.shade800,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Equipo Oscuro',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildInfoItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade700),
        SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }
  
  void _saveAndExit() async {
    // Mostrar indicador de carga
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: CircularProgressIndicator(
          color: Colors.blue,
        ),
      ),
    );

    try {
      // Guardar las posiciones de los jugadores
      await _saveTeamPositions();

      // Cerrar el indicador de carga
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      // Mostrar mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Equipos y posiciones guardados correctamente'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Actualizar los datos en lugar de volver a la pantalla anterior
      await _loadParticipants(); // Recargar los datos para mostrar los cambios
    } catch (e) {
      // Cerrar el indicador de carga
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      // Mostrar mensaje de error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
      
      print('Error al guardar equipos: $e');
    }
  }
  
  // Método para cargar el marcador del partido desde la base de datos
  Future<void> _loadMatchScore() async {
    try {
      final matchData = await supabase
          .from('matches')
          .select('resultado_claro, resultado_oscuro')
          .eq('id', widget.match['id'])
          .single();
      
      if (matchData != null) {
        setState(() {
          _resultadoClaro = matchData['resultado_claro'] ?? 0;
          _resultadoOscuro = matchData['resultado_oscuro'] ?? 0;
        });
      }
    } catch (e) {
      print('Error al cargar el marcador desde matches: $e');
      // Mantener los valores por defecto (0-0)
    }
  }
  
  // Método para actualizar el marcador eliminado

  // Construir el marcador de goles en la parte superior del campo
  // Método eliminado: ya no se muestra el marcador en el campo

  // Función para construir posiciones vacías en el campo
  // Función para construir posiciones vacías en el campo
  
  List<Widget> _buildEmptyPositions(int count, bool isTeamA, double fieldWidth, double fieldHeight) {
    List<Widget> positions = [];
    List<List<double>> formationPositions = _getFormationPositions(count);
    
    for (int i = 0; i < count; i++) {
      if (_isPositionOccupied(i, isTeamA)) continue;
      
      double posX = formationPositions[i][0] * fieldWidth;
      double posY = isTeamA 
          ? formationPositions[i][1] * fieldHeight
          : (1.0 - formationPositions[i][1]) * fieldHeight;
      
      positions.add(
        Positioned(
          left: posX - 25,
          top: posY - 25,
          child: GestureDetector(
            onTap: () => _selectPlayerForPosition(isTeamA, i),
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isTeamA 
                      ? [Colors.blue.withOpacity(0.2), Colors.blue.withOpacity(0.4)] 
                      : [Colors.red.withOpacity(0.2), Colors.red.withOpacity(0.4)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isTeamA ? Colors.blue.shade300 : Colors.red.shade300,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                Icons.add,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
        ),
      );
    }
    
    return positions;
  }

  // Comprobar si una posición está ocupada por un jugador
  bool _isPositionOccupied(int index, bool isTeamA) {
    if (isTeamA) {
      return _teamClaroPositionIndices.containsKey(index);
    } else {
      return _teamOscuroPositionIndices.containsKey(index);
    }
  }

  // Función para mostrar el selector de jugador para una posición específica
  void _selectPlayerForPosition(bool isTeamA, int positionIndex) {
    // Lista de jugadores disponibles (no asignados a ningún equipo y el usuario actual)
    List<Map<String, dynamic>> availablePlayers = [..._unassignedParticipants];
    
    // Verificar si ya estás en el partido pero no en ningún equipo
    final currentUserId = supabase.auth.currentUser?.id;
    if (currentUserId != null) {
      // Añadir también jugadores del equipo actual para poder reposicionarlos
      final teamToCheck = isTeamA ? _teamClaro : _teamOscuro;
      for (var player in teamToCheck) {
        if (!availablePlayers.any((p) => p['id'] == player['id'])) {
          availablePlayers.add(player);
        }
      }

      // Primero verificamos si el usuario ya está en alguna lista
      bool isUserInAvailablePlayers = availablePlayers.any((p) => p['user_id'] == currentUserId);
      bool isUserInClaro = _teamClaro.any((p) => p['user_id'] == currentUserId);
      bool isUserInOscuro = _teamOscuro.any((p) => p['user_id'] == currentUserId);
      
      // Si el usuario no está en ninguna lista, intentamos obtener su perfil
      if (!isUserInAvailablePlayers && !isUserInClaro && !isUserInOscuro) {
        // Verificar si el usuario ya está en los participantes
        final userParticipant = _participants.where((p) => p['user_id'] == currentUserId).toList();
        
        if (userParticipant.isNotEmpty) {
          // Si el usuario ya es un participante, añadirlo a la lista de disponibles
          availablePlayers.add(userParticipant.first);
        } else {
          // Si no lo encontramos, intentar crear un participante "temporal" para el usuario actual
          // para que al menos pueda seleccionarse a sí mismo
          try {
            final currentUserInfo = {
              'id': 'temp_${DateTime.now().millisecondsSinceEpoch}', // ID temporal
              'user_id': currentUserId,
              'equipo': null,
              'es_organizador': false,
              'nombre': 'Tú (Usuario actual)',
              'avatar_url': null,
              'email': supabase.auth.currentUser?.email ?? '',
              'isCurrentUser': true, // Marcador especial
            };
            
            availablePlayers.add(currentUserInfo);
          } catch (e) {
            print('Error al crear participante temporal: $e');
          }
        }
      }
    }
    
    // Verificar si la posición ya está ocupada por un jugador
    String? currentPlayerId;
    if (isTeamA && _teamClaroPositionIndices.containsKey(positionIndex)) {
      currentPlayerId = _teamClaroPositionIndices[positionIndex];
    } else if (!isTeamA && _teamOscuroPositionIndices.containsKey(positionIndex)) {
      currentPlayerId = _teamOscuroPositionIndices[positionIndex];
    }
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) => DraggableScrollableSheet(
            initialChildSize: 0.7,
            minChildSize: 0.5,
            maxChildSize: 0.9,
            builder: (_, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Seleccionar jugador para ${isTeamA ? "Equipo Claro" : "Equipo Oscuro"}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isTeamA ? Colors.blue.shade800 : Colors.red.shade800,
                      ),
                    ),
                    SizedBox(height: 12),
                    
                    Expanded(
                      child: availablePlayers.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.people_alt_outlined,
                                    size: 48,
                                    color: Colors.grey.shade400,
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'No hay jugadores disponibles',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 16,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  ElevatedButton.icon(
                                    onPressed: () => Navigator.pop(context),
                                    icon: Icon(Icons.arrow_back),
                                    label: Text('Volver'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.grey.shade200,
                                      foregroundColor: Colors.grey.shade800,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              controller: scrollController,
                              itemCount: availablePlayers.length,
                              itemBuilder: (context, index) {
                                final player = availablePlayers[index];
                                // Destacar si es el usuario actual
                                final isCurrentUser = player['user_id'] == currentUserId || player['isCurrentUser'] == true;
                                
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundImage: player['avatar_url'] != null
                                        ? NetworkImage(player['avatar_url'])
                                        : null,
                                    backgroundColor: isCurrentUser 
                                        ? Colors.purple.shade100 
                                        : Colors.grey.shade200,
                                    child: player['avatar_url'] == null
                                        ? Text(
                                            isCurrentUser ? "TÚ" : (player['nombre']?[0] ?? "?").toUpperCase(),
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: isCurrentUser
                                                  ? Colors.purple.shade700
                                                  : Colors.grey.shade700,
                                            ),
                                          )
                                        : null,
                                  ),
                                  title: Text(
                                    player['nombre'] ?? 'Usuario',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isCurrentUser 
                                          ? Colors.purple.shade700 
                                          : Colors.black,
                                    ),
                                  ),
                                  subtitle: Text(
                                    isCurrentUser 
                                        ? 'Tú (toca para seleccionarte)' 
                                        : '',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontStyle: isCurrentUser 
                                          ? FontStyle.italic 
                                          : FontStyle.normal,
                                      color: isCurrentUser 
                                          ? Colors.purple.shade400 
                                          : Colors.grey.shade600,
                                    ),
                                  ),
                                  trailing: ElevatedButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      if (player['isCurrentUser'] == true) {
                                        // Si es un usuario temporal, primero unirlo al partido
                                        _joinMatchAndAssignToPosition(isTeamA, positionIndex);
                                      } else {
                                        _assignPlayerToPosition(player, isTeamA, positionIndex);
                                      }
                                    },
                                    child: Text('Seleccionar'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isCurrentUser
                                          ? Colors.purple.shade600
                                          : (isTeamA ? Colors.blue.shade600 : Colors.red.shade600),
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                  onTap: () {
                                    Navigator.pop(context);
                                    if (player['isCurrentUser'] == true) {
                                      // Si es un usuario temporal, primero unirlo al partido
                                      _joinMatchAndAssignToPosition(isTeamA, positionIndex);
                                    } else {
                                      _assignPlayerToPosition(player, isTeamA, positionIndex);
                                    }
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
  
  // Nueva función para unirse al partido y asignarse a una posición
  Future<void> _joinMatchAndAssignToPosition(bool isTeamA, int positionIndex) async {
    // Primero unirse al partido
    try {
      setState(() {
        _isLoading = true;
      });
      
      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Debes iniciar sesión para unirte al partido'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      // Obtener datos del usuario actual desde auth.users en lugar de profiles
      final userData = await supabase
          .from('users')
          .select('email, id')
          .eq('id', currentUser.id)
          .maybeSingle();
          
      // Si no encuentra los datos del usuario, intenta obtenerlos directamente de auth
      final String userEmail = userData != null 
          ? userData['email'] 
          : currentUser.email ?? '';
      final String userName = userEmail.split('@')[0]; // Usar parte del email como nombre provisional

      // Determinar el equipo
      final String? team = isTeamA ? 'claro' : 'oscuro';
      
      // Añadir directamente al equipo correspondiente
      final response = await supabase.from('match_participants').insert({
        'match_id': widget.match['id'],
        'user_id': currentUser.id,
        'equipo': team,
        'es_organizador': false,
        'joined_at': DateTime.now().toIso8601String(),
      }).select();
      
      if (response.isNotEmpty) {
        // Crear objeto de participante
        final newParticipant = {
          'id': response[0]['id'],
          'user_id': currentUser.id,
          'equipo': team,
          'es_organizador': false,
          'nombre': userName,
          'avatar_url': null,
          'email': userEmail,
        };
        
        // Actualizar listas localmente
        setState(() {
          _participants.add(newParticipant);
          
          if (isTeamA) {
            _teamClaro.add(newParticipant);
            
            // Calcular posición
            List<List<double>> positions = _getFormationPositions(
              int.parse(widget.match['formato']?.split('v')[0] ?? '5')
            );
            
            // Asignar posición
            final String playerId = newParticipant['id'].toString();
            _teamClaroPositionIndices[positionIndex] = playerId;
            _teamClaroPositions[playerId] = Offset(
              positions[positionIndex][0],
              positions[positionIndex][1]
            );
          } else {
            _teamOscuro.add(newParticipant);
            
            // Calcular posición
            List<List<double>> positions = _getFormationPositions(
              int.parse(widget.match['formato']?.split('v')[1] ?? '5')
            );
            
            // Asignar posición
            final String playerId = newParticipant['id'].toString();
            _teamOscuroPositionIndices[positionIndex] = playerId;
            _teamOscuroPositions[playerId] = Offset(
              positions[positionIndex][0],
              (1.0 - positions[positionIndex][1])
            );
          }
          
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('¡Te has unido al equipo ${isTeamA ? "Claro" : "Oscuro"}!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error al unirse y asignarse: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Función para asignar un jugador a una posición específica
  void _assignPlayerToPosition(Map<String, dynamic> player, bool isTeamA, int positionIndex) async {
    try {
      final String playerId = player['id'].toString();
      
      setState(() {
        // 1. Primero verificar si el jugador ya está en algún equipo y eliminar su referencia anterior
        bool wasInTeamA = _teamClaro.any((p) => p['id'].toString() == playerId);
        bool wasInTeamB = _teamOscuro.any((p) => p['id'].toString() == playerId);
        
        // 2. Liberar la posición anterior que ocupaba el jugador, si estaba en algún equipo
        if (wasInTeamA) {
          // Encontrar y guardar la posición anterior para liberarla
          int? previousPositionIndex;
          _teamClaroPositionIndices.forEach((index, id) {
            if (id == playerId) {
              previousPositionIndex = index;
            }
          });
          
          // Liberar la posición anterior
          if (previousPositionIndex != null) {
            _teamClaroPositionIndices.remove(previousPositionIndex);
          }
        } else if (wasInTeamB) {
          // Encontrar y guardar la posición anterior para liberarla
          int? previousPositionIndex;
          _teamOscuroPositionIndices.forEach((index, id) {
            if (id == playerId) {
              previousPositionIndex = index;
            }
          });
          
          // Liberar la posición anterior
          if (previousPositionIndex != null) {
            _teamOscuroPositionIndices.remove(previousPositionIndex);
          }
        }
      });
      
      // 3. Verificar si el jugador ya está en el equipo destino o necesita ser cambiado
      String currentTeam = player['equipo'] ?? '';
      String targetTeam = isTeamA ? 'claro' : 'oscuro';
      
      if (currentTeam != targetTeam) {
        try {
          // Actualizar directamente en la base de datos antes de actualizar localmente
          await supabase
            .from('match_participants')
            .update({'equipo': targetTeam})
            .eq('id', playerId);
        } catch (e) {
          dev.log('Error al actualizar el equipo del jugador en la base de datos: $e');
          // Continuamos con la actualización local aunque falle la actualización en la base de datos
          // para evitar mostrar mensajes de error al usuario
        }
      }
      
      // 4. Actualizar los mapas de posiciones
      setState(() {
        // Si el jugador estaba en el equipo contrario, eliminarlo de allí
        if (isTeamA) {
          _teamOscuro.removeWhere((p) => p['id'].toString() == playerId);
        } else {
          _teamClaro.removeWhere((p) => p['id'].toString() == playerId);
        }
        
        // Actualizar el equipo en el objeto del jugador
        player['equipo'] = targetTeam;
        
        // Si el jugador está en la lista de no asignados, eliminarlo de allí
        _unassignedParticipants.removeWhere((p) => p['id'].toString() == playerId);
        
        // Verificar si la posición ya está ocupada
        if (isTeamA && _teamClaroPositionIndices.containsKey(positionIndex)) {
          String existingPlayerId = _teamClaroPositionIndices[positionIndex]!;
          // Si la posición está ocupada por otro jugador, quitar ese jugador
          if (existingPlayerId != playerId) {
            // Buscar al jugador que ocupa esta posición
            var existingPlayer = _teamClaro.firstWhere(
              (p) => p['id'].toString() == existingPlayerId,
              orElse: () => {}
            );
            
            if (existingPlayer.isNotEmpty) {
              // Moverlo a no asignados
              existingPlayer['equipo'] = null;
              _unassignedParticipants.add(existingPlayer);
              _teamClaro.removeWhere((p) => p['id'].toString() == existingPlayerId);
            }
          }
        } else if (!isTeamA && _teamOscuroPositionIndices.containsKey(positionIndex)) {
          String existingPlayerId = _teamOscuroPositionIndices[positionIndex]!;
          // Si la posición está ocupada por otro jugador, quitar ese jugador
          if (existingPlayerId != playerId) {
            // Buscar al jugador que ocupa esta posición
            var existingPlayer = _teamOscuro.firstWhere(
              (p) => p['id'].toString() == existingPlayerId,
              orElse: () => {}
            );
            
            if (existingPlayer.isNotEmpty) {
              // Moverlo a no asignados
              existingPlayer['equipo'] = null;
              _unassignedParticipants.add(existingPlayer);
              _teamOscuro.removeWhere((p) => p['id'].toString() == existingPlayerId);
            }
          }
        }
        
        // Asignar la nueva posición al jugador
        if (isTeamA) {
          // Añadir jugador al equipo si no está ya
          if (!_teamClaro.any((p) => p['id'].toString() == playerId)) {
            _teamClaro.add(player);
          }
          
          _teamClaroPositionIndices[positionIndex] = playerId;
          
          // Obtener las posiciones predeterminadas según la formación
          List<List<double>> positions = _getFormationPositions(
            int.parse(widget.match['formato']?.split('v')[0] ?? '5')
          );
          
          _teamClaroPositions[playerId] = Offset(
            positions[positionIndex][0],
            positions[positionIndex][1]
          );
        } else {
          // Añadir jugador al equipo si no está ya
          if (!_teamOscuro.any((p) => p['id'].toString() == playerId)) {
            _teamOscuro.add(player);
          }
          
          _teamOscuroPositionIndices[positionIndex] = playerId;
          
          // Obtener las posiciones predeterminadas según la formación
          List<List<double>> positions = _getFormationPositions(
            int.parse(widget.match['formato']?.split('v')[1] ?? '5')
          );
          
          _teamOscuroPositions[playerId] = Offset(
            positions[positionIndex][0],
            (1.0 - positions[positionIndex][1]) // Invertir en el eje Y para el equipo oscuro
          );
        }
        
        // Forzar actualización visual
        _redrawPositionSlots();
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Jugador asignado a la posición'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 1),
        ),
      );
    } catch (e) {
      dev.log('Error al asignar jugador a posición: $e');
    }
  }

  // Función para que el usuario actual se una al partido
  Future<void> _joinMatch() async {
    try {
      // Verificar si el usuario está autenticado
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

      // Mostrar indicador de carga
      setState(() {
        _isLoading = true;
      });

      // Comprobar si el usuario ya está en el partido
      final participantCheck = await supabase
          .from('match_participants')
          .select()
          .eq('match_id', widget.match['id'])
          .eq('user_id', currentUser.id)
          .maybeSingle();

      if (participantCheck != null) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ya formas parte de este partido'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Obtener información básica del usuario desde auth.users
      final String userEmail = currentUser.email ?? '';
      final String userName = userEmail.split('@')[0]; // Usar parte del email como nombre provisional

      // Añadir el usuario al partido como participante
      final response = await supabase.from('match_participants').insert({
        'match_id': widget.match['id'],
        'user_id': currentUser.id,
        'equipo': null, // Sin equipo asignado inicialmente
        'es_organizador': false,
        'joined_at': DateTime.now().toIso8601String(),
      }).select();

      if (response.isNotEmpty) {
        // Crear objeto de participante para añadir a la interfaz
        final newParticipant = {
          'id': response[0]['id'],
          'user_id': currentUser.id,
          'equipo': null,
          'es_organizador': false,
          'nombre': userName,
          'avatar_url': null,
          'email': userEmail,
        };

        // Actualizar la interfaz
        setState(() {
          _unassignedParticipants.add(newParticipant);
          _participants.add(newParticipant);
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('¡Te has unido al partido!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error al unirse al partido: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al unirse al partido: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Método para guardar las posiciones de los jugadores en la base de datos
  Future<void> _saveTeamPositions() async {
    try {
      print('\n=== GUARDANDO EQUIPOS Y POSICIONES ===');
      
      // PASO 1: Guardar las posiciones en la tabla matches
      print('\n--- Procesando posiciones para guardar ---');
      
      // Convertir las posiciones a formato JSON para guardar en la BD
      Map<String, dynamic> teamClaroPositionsJson = {};
      Map<String, dynamic> teamOscuroPositionsJson = {};
      
      // Procesar posiciones del equipo claro
      for (String playerId in _teamClaroPositions.keys) {
        final position = _teamClaroPositions[playerId]!;
        teamClaroPositionsJson[playerId] = {
          'dx': position.dx,
          'dy': position.dy
        };
        print('Preparada posición equipo claro: Jugador $playerId en (${position.dx}, ${position.dy})');
      }
      
      // Procesar posiciones del equipo oscuro
      for (String playerId in _teamOscuroPositions.keys) {
        final position = _teamOscuroPositions[playerId]!;
        teamOscuroPositionsJson[playerId] = {
          'dx': position.dx,
          'dy': position.dy
        };
        print('Preparada posición equipo oscuro: Jugador $playerId en (${position.dx}, ${position.dy})');
      }
      
      // Crear listas de IDs de usuarios por equipo
      final teamClaroIds = _teamClaro.map((p) => p['user_id'].toString()).toList();
      final teamOscuroIds = _teamOscuro.map((p) => p['user_id'].toString()).toList();
      
      print('\n--- Actualizando posiciones en la tabla matches ---');
      print('Total posiciones: ${teamClaroPositionsJson.length} (claro), ${teamOscuroPositionsJson.length} (oscuro)');
      
      // Actualizar todo en la tabla matches
      await supabase
          .from('matches')
          .update({
            'team_claro_positions': teamClaroPositionsJson,
            'team_oscuro_positions': teamOscuroPositionsJson,
            'resultado_claro': _resultadoClaro,
            'resultado_oscuro': _resultadoOscuro,
            'team_claro': teamClaroIds,
            'team_oscuro': teamOscuroIds
          })
          .eq('id', widget.match['id']);
      
      print('✓ Posiciones guardadas en la tabla matches');
      
      // PASO 2: Actualizar equipos en match_participants
      print('\n--- Actualizando asignación de equipos ---');
      
      // Crear una lista de todas las actualizaciones que necesitamos hacer
      List<Future<void>> updateOperations = [];
      
      // Preparar actualizaciones para el equipo CLARO
      for (var player in _teamClaro) {
        final participantId = player['id'];
        final nombre = player['nombre'];
        print('Preparando actualización: Jugador $nombre a equipo CLARO');
        
        updateOperations.add(
          supabase
            .from('match_participants')
            .update({'equipo': 'claro'})
            .eq('id', participantId)
            .catchError((e) {
              print('✗ Error al actualizar jugador $nombre: $e');
              // No propagar el error, para que la operación se considere "completada" aunque falle
              return null;
            })
        );
      }
      
      // Preparar actualizaciones para el equipo OSCURO
      for (var player in _teamOscuro) {
        final participantId = player['id'];
        final nombre = player['nombre'];
        print('Preparando actualización: Jugador $nombre a equipo OSCURO');
        
        updateOperations.add(
          supabase
            .from('match_participants')
            .update({'equipo': 'oscuro'})
            .eq('id', participantId)
            .catchError((e) {
              print('✗ Error al actualizar jugador $nombre: $e');
              // No propagar el error, para que la operación se considere "completada" aunque falle
              return null;
            })
        );
      }
      
      // Preparar actualizaciones para jugadores SIN ASIGNAR
      for (var player in _unassignedParticipants) {
        final participantId = player['id'];
        final nombre = player['nombre'];
        print('Preparando actualización: Jugador $nombre a SIN EQUIPO');
        
        updateOperations.add(
          supabase
            .from('match_participants')
            .update({'equipo': null})
            .eq('id', participantId)
            .catchError((e) {
              print('✗ Error al quitar equipo a jugador $nombre: $e');
              // No propagar el error, para que la operación se considere "completada" aunque falle
              return null;
            })
        );
      }
      
      // Ejecutar todas las actualizaciones en paralelo
      print('Ejecutando ${updateOperations.length} actualizaciones de equipos en match_participants...');
      await Future.wait(updateOperations);
      
      print('✓ Actualizaciones de equipo completadas');
      
      // Verificación alternativa para asegurar que todas las asignaciones se hayan guardado
      print('\n--- Verificando estado final en match_participants ---');
      try {
        final matchParticipants = await supabase
          .from('match_participants')
          .select('id, user_id, equipo')
          .eq('match_id', widget.match['id']);
        
        int countClaro = 0;
        int countOscuro = 0;
        int countUnassigned = 0;
        
        for (var participant in matchParticipants) {
          if (participant['equipo'] == 'claro') countClaro++;
          else if (participant['equipo'] == 'oscuro') countOscuro++;
          else countUnassigned++;
        }
        
        print('Verificación en base de datos: ${countClaro} en Claro, ${countOscuro} en Oscuro, ${countUnassigned} sin asignar (Total: ${matchParticipants.length})');
        print('Estado local: ${_teamClaro.length} en Claro, ${_teamOscuro.length} en Oscuro, ${_unassignedParticipants.length} sin asignar (Total: ${_participants.length})');
        
        // Comprobar si hay discrepancias
        if (countClaro != _teamClaro.length || countOscuro != _teamOscuro.length) {
          print('⚠ ADVERTENCIA: Discrepancia entre estado local y base de datos');
          // Intentar corrección para casos donde la asignación de equipo falló
          await _forceSyncTeamAssignments();
        }
      } catch (e) {
        print('Error en verificación final: $e');
      }
      
      print('\n=== GUARDADO COMPLETADO ===');
      
    } catch (e) {
      print('Error general: $e');
      if (e.toString().contains('column "team_claro_positions" does not exist')) {
        print('\n⚠ IMPORTANTE: La tabla matches no tiene las columnas necesarias para guardar posiciones.');
        print('Ejecuta estas sentencias SQL en tu base de datos:');
        print('''
ALTER TABLE matches ADD COLUMN team_claro_positions JSONB;
ALTER TABLE matches ADD COLUMN team_oscuro_positions JSONB;
ALTER TABLE matches ADD COLUMN team_claro UUID[];
ALTER TABLE matches ADD COLUMN team_oscuro UUID[];
ALTER TABLE matches ADD COLUMN resultado_claro INTEGER DEFAULT 0;
ALTER TABLE matches ADD COLUMN resultado_oscuro INTEGER DEFAULT 0;
ALTER TABLE matches ADD COLUMN mvp_team_claro UUID;
ALTER TABLE matches ADD COLUMN mvp_team_oscuro UUID;
        ''');
      }
      throw e;
    }
  }
  
  // Método para forzar la sincronización de asignaciones de equipo cuando hay errores
  Future<void> _forceSyncTeamAssignments() async {
    print('Intentando sincronización forzada de equipos...');
    
    try {
      // 1. Obtener todos los participantes actuales
      final participants = await supabase
          .from('match_participants')
          .select('*')
          .eq('match_id', widget.match['id']);
      
      // 2. Crear un mapa para búsqueda rápida
      Map<String, Map<String, dynamic>> participantsMap = {};
      for (var p in participants) {
        participantsMap[p['id'].toString()] = p;
      }
      
      // 3. Comprobar y corregir asignaciones para equipo Claro
      print('Sincronizando equipo CLARO...');
      int fixedClaro = 0;
      for (var player in _teamClaro) {
        final participantId = player['id'].toString();
        if (participantsMap.containsKey(participantId)) {
          final currentEquipo = participantsMap[participantId]!['equipo'];
          if (currentEquipo != 'claro') {
            // Intentar actualizacion directa SQL via RPC si está disponible
            try {
              await supabase.rpc(
                'execute_sql',
                params: {
                  'sql_query': "UPDATE match_participants SET equipo = 'claro' WHERE id = '$participantId'"
                }
              );
              fixedClaro++;
            } catch (e) {
              print('Error en sincronización forzada para jugador $participantId: $e');
            }
          }
        }
      }
      
      // 4. Comprobar y corregir asignaciones para equipo Oscuro
      print('Sincronizando equipo OSCURO...');
      int fixedOscuro = 0;
      for (var player in _teamOscuro) {
        final participantId = player['id'].toString();
        if (participantsMap.containsKey(participantId)) {
          final currentEquipo = participantsMap[participantId]!['equipo'];
          if (currentEquipo != 'oscuro') {
            // Intentar actualizacion directa SQL via RPC si está disponible
            try {
              await supabase.rpc(
                'execute_sql',
                params: {
                  'sql_query': "UPDATE match_participants SET equipo = 'oscuro' WHERE id = '$participantId'"
                }
              );
              fixedOscuro++;
            } catch (e) {
              print('Error en sincronización forzada para jugador $participantId: $e');
            }
          }
        }
      }
      
      print('Sincronización forzada completada. Corregidos: $fixedClaro en Claro, $fixedOscuro en Oscuro');
      
    } catch (e) {
      print('Error en sincronización forzada: $e');
    }
  }

  // Método para cargar las posiciones guardadas del partido
  Future<void> _loadSavedPositions() async {
    try {
      // Cargar datos del partido, incluyendo las posiciones de los jugadores
      final matchData = await supabase
          .from('matches')
          .select('team_claro_positions, team_oscuro_positions')
          .eq('id', widget.match['id'])
          .single();
      
      // Limpiar los mapas de posiciones
      _teamClaroPositions.clear();
      _teamOscuroPositions.clear();
      
      // Procesar las posiciones del equipo claro
      if (matchData['team_claro_positions'] != null) {
        Map<String, dynamic> positions = Map<String, dynamic>.from(matchData['team_claro_positions']);
        
        positions.forEach((playerId, position) {
          // Formato 1: { playerId: { dx: 0.5, dy: 0.3 } }
          if (position is Map && position.containsKey('dx') && position.containsKey('dy')) {
            double dx = (position['dx'] is num) ? (position['dx'] as num).toDouble() : 0.5;
            double dy = (position['dy'] is num) ? (position['dy'] as num).toDouble() : 0.3;
            _teamClaroPositions[playerId] = Offset(dx, dy);
            print('Cargada posición del equipo claro: $playerId en ($dx, $dy)');
          }
          // Formato 2: { playerId: { x: 0.5, y: 0.3 } }
          else if (position is Map && position.containsKey('x') && position.containsKey('y')) {
            double dx = (position['x'] is num) ? (position['x'] as num).toDouble() : 0.5;
            double dy = (position['y'] is num) ? (position['y'] as num).toDouble() : 0.3;
            _teamClaroPositions[playerId] = Offset(dx, dy);
            print('Cargada posición alternativa del equipo claro: $playerId en ($dx, $dy)');
          }
        });
      }
      
      // Procesar las posiciones del equipo oscuro
      if (matchData['team_oscuro_positions'] != null) {
        Map<String, dynamic> positions = Map<String, dynamic>.from(matchData['team_oscuro_positions']);
        
        positions.forEach((playerId, position) {
          // Formato 1: { playerId: { dx: 0.5, dy: 0.7 } }
          if (position is Map && position.containsKey('dx') && position.containsKey('dy')) {
            double dx = (position['dx'] is num) ? (position['dx'] as num).toDouble() : 0.5;
            double dy = (position['dy'] is num) ? (position['dy'] as num).toDouble() : 0.7;
            _teamOscuroPositions[playerId] = Offset(dx, dy);
            print('Cargada posición del equipo oscuro: $playerId en ($dx, $dy)');
          }
          // Formato 2: { playerId: { x: 0.5, y: 0.7 } }
          else if (position is Map && position.containsKey('x') && position.containsKey('y')) {
            double dx = (position['x'] is num) ? (position['x'] as num).toDouble() : 0.5;
            double dy = (position['y'] is num) ? (position['y'] as num).toDouble() : 0.7;
            _teamOscuroPositions[playerId] = Offset(dx, dy);
            print('Cargada posición alternativa del equipo oscuro: $playerId en ($dx, $dy)');
          }
        });
      }
      
      print('Posiciones cargadas: ${_teamClaroPositions.length} para equipo claro, ${_teamOscuroPositions.length} para equipo oscuro');
    } catch (e) {
      print('Error al cargar las posiciones guardadas: $e');
    }
  }

  // Calcular los índices de posición basado en las posiciones guardadas
  void _calculatePositionIndices() {
    // Limpiar los mapas de índices actuales
    _teamClaroPositionIndices.clear();
    _teamOscuroPositionIndices.clear();
    
    // Obtener el formato del partido para determinar las posiciones predefinidas
    final String format = widget.match['formato'] ?? '5v5';
    final int teamClaroSize = int.tryParse(format.split('v')[0]) ?? 5;
    final int teamOscuroSize = int.tryParse(format.split('v')[1] ?? format.split('v')[0]) ?? 5;
    
    // Obtener las posiciones predefinidas para ambos equipos
    List<List<double>> teamClaroFormationPositions = _getFormationPositions(teamClaroSize);
    List<List<double>> teamOscuroFormationPositions = _getFormationPositions(teamOscuroSize);
    
    print('Calculando índices de posición para ${_teamClaro.length} jugadores del equipo claro y ${_teamOscuro.length} del equipo oscuro');
    
    // Para cada jugador en el equipo claro, encontrar su posición más cercana en la formación
    for (var player in _teamClaro) {
      final String playerId = player['id'].toString();
      
      // Si el jugador tiene una posición guardada, encontrar el índice más cercano
      if (_teamClaroPositions.containsKey(playerId)) {
        Offset position = _teamClaroPositions[playerId]!;
        int closestIndex = _findClosestFormationPosition(position, teamClaroFormationPositions, true);
        
        // Si esa posición ya está ocupada, buscar la siguiente disponible
        if (_teamClaroPositionIndices.containsValue(playerId)) {
          // Ya está asignado, podemos dejarlo como está
          continue;
        } else if (_teamClaroPositionIndices.containsKey(closestIndex)) {
          // La posición más cercana ya está ocupada, buscar una libre
          closestIndex = _findFirstAvailableIndex(_teamClaroPositionIndices, teamClaroSize);
        }
        
        // Asignar la posición
        _teamClaroPositionIndices[closestIndex] = playerId;
        print('Asignado jugador $playerId a posición $closestIndex en equipo claro');
      }
      // Si no tiene posición, asignar a una posición disponible
      else {
        final int availableIndex = _findFirstAvailableIndex(_teamClaroPositionIndices, teamClaroSize);
        _teamClaroPositionIndices[availableIndex] = playerId;
        
        // Asignar posición predeterminada
        _teamClaroPositions[playerId] = _getDefaultPosition(availableIndex, true);
        print('Asignada posición predeterminada $availableIndex a jugador $playerId en equipo claro');
      }
    }
    
    // Para cada jugador en el equipo oscuro, encontrar su posición más cercana en la formación
    for (var player in _teamOscuro) {
      final String playerId = player['id'].toString();
      
      // Si el jugador tiene una posición guardada, encontrar el índice más cercano
      if (_teamOscuroPositions.containsKey(playerId)) {
        Offset position = _teamOscuroPositions[playerId]!;
        int closestIndex = _findClosestFormationPosition(position, teamOscuroFormationPositions, false);
        
        // Si esa posición ya está ocupada, buscar la siguiente disponible
        if (_teamOscuroPositionIndices.containsValue(playerId)) {
          // Ya está asignado, podemos dejarlo como está
          continue;
        } else if (_teamOscuroPositionIndices.containsKey(closestIndex)) {
          // La posición más cercana ya está ocupada, buscar una libre
          closestIndex = _findFirstAvailableIndex(_teamOscuroPositionIndices, teamOscuroSize);
        }
        
        // Asignar la posición
        _teamOscuroPositionIndices[closestIndex] = playerId;
        print('Asignado jugador $playerId a posición $closestIndex en equipo oscuro');
      }
      // Si no tiene posición, asignar a una posición disponible
      else {
        final int availableIndex = _findFirstAvailableIndex(_teamOscuroPositionIndices, teamOscuroSize);
        _teamOscuroPositionIndices[availableIndex] = playerId;
        
        // Asignar posición predeterminada
        _teamOscuroPositions[playerId] = _getDefaultPosition(availableIndex, false);
        print('Asignada posición predeterminada $availableIndex a jugador $playerId en equipo oscuro');
      }
    }
    
    print('Índices calculados: ${_teamClaroPositionIndices.length} para equipo claro, ${_teamOscuroPositionIndices.length} para equipo oscuro');
  }

  // Encuentra el índice de posición más cercano a una posición dada
  int _findClosestFormationPosition(Offset position, List<List<double>> formationPositions, bool isTeamA) {
    double minDistance = double.infinity;
    int closestIndex = 0;
    
    for (int i = 0; i < formationPositions.length; i++) {
      // Para el equipo oscuro, debemos comparar con la posición invertida en Y
      double posY = isTeamA 
          ? formationPositions[i][1]
          : 1.0 - formationPositions[i][1];
      
      Offset formationPos = Offset(formationPositions[i][0], posY);
      double distance = (position - formationPos).distance;
      
      if (distance < minDistance) {
        minDistance = distance;
        closestIndex = i;
      }
    }
    
    return closestIndex;
  }
  
  // Encuentra el primer índice disponible en un mapa de índices
  int _findFirstAvailableIndex(Map<int, String> positionIndices, int maxSize) {
    for (int i = 0; i < maxSize; i++) {
      if (!positionIndices.containsKey(i)) {
        return i;
      }
    }
    return 0;  // Por defecto, posición 0 si todas están ocupadas
  }
  
  // Asignar automáticamente jugadores sin posición a posiciones disponibles en el campo
  void _autoAssignPlayersToPositions() {
    print('Iniciando asignación automática de jugadores a posiciones en el campo');
    final String format = widget.match['formato'] ?? '5v5';
    final int teamClaroSize = int.tryParse(format.split('v')[0]) ?? 5;
    final int teamOscuroSize = int.tryParse(format.split('v')[1] ?? format.split('v')[0]) ?? 5;
    
    // Obtener las posiciones predefinidas para ambos equipos
    List<List<double>> teamClaroFormationPositions = _getFormationPositions(teamClaroSize);
    List<List<double>> teamOscuroFormationPositions = _getFormationPositions(teamOscuroSize);
    
    // Asignar jugadores del equipo claro sin posición
    List<String> assignedClaroIds = []; // Para rastrear IDs ya asignados
    
    for (var player in _teamClaro) {
      final String playerId = player['id'].toString();
      
      // Verificar si ya está asignado a algún índice
      bool isAssigned = false;
      _teamClaroPositionIndices.forEach((index, id) {
        if (id == playerId) isAssigned = true;
      });
      
      if (!isAssigned) {
        // Buscar el primer índice disponible
        final int availableIndex = _findFirstAvailableIndex(_teamClaroPositionIndices, teamClaroSize);
        _teamClaroPositionIndices[availableIndex] = playerId;
        
        // Asignar posición predeterminada si no tiene una
        if (!_teamClaroPositions.containsKey(playerId)) {
          _teamClaroPositions[playerId] = Offset(
            teamClaroFormationPositions[availableIndex][0],
            teamClaroFormationPositions[availableIndex][1]
          );
        }
        
        assignedClaroIds.add(playerId);
        print('Jugador $playerId asignado automáticamente a posición $availableIndex en equipo claro');
      }
    }
    
    // Asignar jugadores del equipo oscuro sin posición
    List<String> assignedOscuroIds = []; // Para rastrear IDs ya asignados
    
    for (var player in _teamOscuro) {
      final String playerId = player['id'].toString();
      
      // Verificar si ya está asignado a algún índice
      bool isAssigned = false;
      _teamOscuroPositionIndices.forEach((index, id) {
        if (id == playerId) isAssigned = true;
      });
      
      if (!isAssigned) {
        // Buscar el primer índice disponible
        final int availableIndex = _findFirstAvailableIndex(_teamOscuroPositionIndices, teamOscuroSize);
        _teamOscuroPositionIndices[availableIndex] = playerId;
        
        // Asignar posición predeterminada si no tiene una
        if (!_teamOscuroPositions.containsKey(playerId)) {
          _teamOscuroPositions[playerId] = Offset(
            teamOscuroFormationPositions[availableIndex][0],
            1.0 - teamOscuroFormationPositions[availableIndex][1] // Invertir en Y para equipo oscuro
          );
        }
        
        assignedOscuroIds.add(playerId);
        print('Jugador $playerId asignado automáticamente a posición $availableIndex en equipo oscuro');
      }
    }
    
    // Mover automáticamente jugadores sin asignar al equipo con menos jugadores si es necesario
    if (_unassignedParticipants.isNotEmpty) {
      print('Hay ${_unassignedParticipants.length} jugadores sin asignar que se intentarán distribuir');
      
      for (var player in List.from(_unassignedParticipants)) {
        // Determinar a qué equipo se debería mover el jugador
        bool moveToClaro = _teamClaro.length < teamClaroSize && _teamClaro.length <= _teamOscuro.length;
        
        if (moveToClaro && _teamClaro.length < teamClaroSize) {
          final String playerId = player['id'].toString();
          // Mover al equipo claro
          player['equipo'] = 'claro';
          _teamClaro.add(player);
          _unassignedParticipants.remove(player);
          
          // Asignar a una posición disponible
          final int availableIndex = _findFirstAvailableIndex(_teamClaroPositionIndices, teamClaroSize);
          _teamClaroPositionIndices[availableIndex] = playerId;
          _teamClaroPositions[playerId] = Offset(
            teamClaroFormationPositions[availableIndex][0],
            teamClaroFormationPositions[availableIndex][1]
          );
          
          // Actualizar en la base de datos
          _updatePlayerTeam(playerId, 'claro');
          
          print('Jugador sin asignar $playerId movido automáticamente al equipo claro en posición $availableIndex');
        } else if (_teamOscuro.length < teamOscuroSize) {
          final String playerId = player['id'].toString();
          // Mover al equipo oscuro
          player['equipo'] = 'oscuro';
          _teamOscuro.add(player);
          _unassignedParticipants.remove(player);
          
          // Asignar a una posición disponible
          final int availableIndex = _findFirstAvailableIndex(_teamOscuroPositionIndices, teamOscuroSize);
          _teamOscuroPositionIndices[availableIndex] = playerId;
          _teamOscuroPositions[playerId] = Offset(
            teamOscuroFormationPositions[availableIndex][0],
            1.0 - teamOscuroFormationPositions[availableIndex][1]
          );
          
          // Actualizar en la base de datos
          _updatePlayerTeam(playerId, 'oscuro');
          
          print('Jugador sin asignar $playerId movido automáticamente al equipo oscuro en posición $availableIndex');
        }
      }
    }
    
    print('Asignación automática completada - Equipo Claro: ${_teamClaro.length}/${teamClaroSize}, Equipo Oscuro: ${_teamOscuro.length}/${teamOscuroSize}');
    
    // Forzar actualización visual
    _redrawPositionSlots();
  }

  // Método auxiliar para actualizar el equipo de un jugador en la base de datos
  Future<void> _updatePlayerTeam(String participantId, String team) async {
    try {
      // Verificar si el participantId es válido antes de continuar
      if (participantId.isEmpty) {
        print('ID de participante no válido');
        return;
      }
      
      // Actualizar el equipo del jugador
      await supabase
        .from('match_participants')
        .update({'equipo': team})
        .eq('id', participantId);
      
      // Buscar el jugador actualizado para mostrar opciones
      final response = await supabase
        .from('match_participants')
        .select('*, profiles:user_id(nombre, avatar_url)')
        .eq('id', participantId)
        .single();
      
      // Verificar si la respuesta es válida
      if (response == null) {
        print('No se pudo obtener información del jugador');
        return;
      }
      
      Map<String, dynamic> player = response;
      if (player['profiles'] != null) {
        player['nombre'] = player['profiles']['nombre'];
        player['avatar_url'] = player['profiles']['avatar_url'];
      }
      
      // Determinar el equipo y colores
      String teamText = player['equipo'] == 'claro' ? 'Equipo Claro' : 'Equipo Oscuro';
      Color teamColor = player['equipo'] == 'claro' ? Colors.blue.shade700 : Colors.red.shade700;
      
      // Determinar el equipo contrario
      String oppositeTeam = player['equipo'] == 'claro' ? 'oscuro' : 'claro';
      String oppositeTeamText = oppositeTeam == 'claro' ? 'Equipo Claro' : 'Equipo Oscuro';
      Color oppositeTeamColor = oppositeTeam == 'claro' ? Colors.blue.shade700 : Colors.red.shade700;
      
      // Verificar si el equipo contrario está lleno
      bool isOppositeTeamFull = false;
      int oppositeTeamSize = 0;
      int oppositeTeamLimit = 0;
      
      if (oppositeTeam == 'claro') {
        oppositeTeamSize = _teamClaro.length;
        oppositeTeamLimit = int.tryParse(widget.match['formato']?.split('v')[0] ?? '5') ?? 5;
      } else {
        oppositeTeamSize = _teamOscuro.length;
        oppositeTeamLimit = int.tryParse(widget.match['formato']?.split('v')[1] ?? '5') ?? 5;
      }
      
      isOppositeTeamFull = oppositeTeamSize >= oppositeTeamLimit;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: player['avatar_url'] != null ? NetworkImage(player['avatar_url']) : null,
                child: player['avatar_url'] == null 
                  ? Text(
                      (player['nombre'] ?? 'U')[0].toUpperCase(),
                      style: TextStyle(fontWeight: FontWeight.bold)
                    ) 
                  : null,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Opciones para ${player['nombre']}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Información del jugador
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.person, color: teamColor),
                        SizedBox(width: 10),
                        Text(
                          player['nombre'],
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          player['equipo'] == 'claro'
                              ? Icons.brightness_5_outlined
                              : player['equipo'] == 'oscuro'
                                  ? Icons.brightness_2_outlined
                                  : Icons.person_outline,
                          color: teamColor,
                          size: 20,
                        ),
                        SizedBox(width: 10),
                        Text(
                          teamText,
                          style: TextStyle(
                            color: teamColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    if (player['es_organizador'] == true) ...[
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber, size: 20),
                      SizedBox(width: 10),
                      Text(
                        'Organizador',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.amber.shade700,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          SizedBox(height: 20),
          // Nuevas opciones según los requisitos
          if (player['equipo'] == 'claro' || player['equipo'] == 'oscuro') ...[
            // Opción: Quitar del equipo
            Container(
              margin: EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: ListTile(
                leading: Icon(Icons.person_remove, color: Colors.grey.shade700),
                title: Text('Quitar del equipo'),
                subtitle: Text('El jugador quedará sin equipo'),
                tileColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  _assignToTeam(player, null);
                },
              ),
            ),
            
            // Opción: Cambiar al equipo contrario (solo si el otro equipo no está lleno)
            if (!isOppositeTeamFull)
              Container(
                margin: EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: oppositeTeamColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ListTile(
                  leading: Icon(Icons.swap_horiz, color: oppositeTeamColor),
                  title: Text('Cambiar al $oppositeTeamText'),
                  subtitle: Text('Mover al jugador al equipo contrario'),
                  tileColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    _assignToTeam(player, oppositeTeam);
                  },
                ),
              ),
            
            // Opción: Expulsar del partido (solo si no es organizador)
            if (player['es_organizador'] != true)
              Container(
                margin: EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ListTile(
                  leading: Icon(Icons.person_off, color: Colors.red),
                  title: Text('Expulsar del partido'),
                  subtitle: Text('El jugador será eliminado completamente'),
                  tileColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    _showExpelConfirmation(player);
                  },
                ),
              ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cerrar'),
        ),
      ],
    ),
  );
    } catch (e) {
      print('Error al actualizar equipo del jugador: $e');
      // Solo mostrar el error si la vista está montada y visible
      if (context.mounted) {
        // Usar un Future.delayed para evitar que el error aparezca inmediatamente al entrar
        // Solo mostrar errores que no sean de inicialización
        if (!e.toString().contains('NoSuchMethodError')) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al actualizar el equipo del jugador'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
  
  // Método para mostrar confirmación de expulsión
  void _showExpelConfirmation(Map<String, dynamic> player) {
    // Verificar si es organizador
    if (player['es_organizador'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No puedes expulsar al organizador del partido'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 10),
            Text('Expulsar jugador')
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿Seguro que deseas expulsar a ${player['nombre']} del partido?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Text('Esta acción no se puede deshacer y el jugador será eliminado completamente del partido.'),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundImage: player['avatar_url'] != null ? NetworkImage(player['avatar_url']) : null,
                    child: player['avatar_url'] == null 
                      ? Text((player['nombre'] ?? 'U')[0].toUpperCase()) 
                      : null,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${player['nombre']}',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _removePlayerFromMatch(player);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.red,
            ),
            child: Text('Expulsar'),
          ),
        ],
      ),
    );
  }
  // Expulsar al jugador del partido
  Future<void> _removePlayerFromMatch(Map<String, dynamic> player) async {
    try {
      // Mostrar indicador de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: CircularProgressIndicator(),
        ),
      );
      
      final int participantId = player['id'];
      final String userId = player['user_id'];
      final String playerName = player['nombre'];
      final String? currentTeam = player['equipo'];
      
      // Guardar información sobre el equipo para el mensaje de confirmación
      String teamName = currentTeam == 'claro' 
          ? 'Equipo Claro' 
          : currentTeam == 'oscuro' 
              ? 'Equipo Oscuro' 
              : 'sin equipo asignado';
      
      print('Expulsando a jugador: $playerName (ID: $participantId) del $teamName');
      
      // Eliminar al jugador de la base de datos
      await supabase
          .from('match_participants')
          .delete()
          .eq('id', participantId);
      
      // Cerrar el diálogo de carga
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      
      // Actualizar las listas locales
      setState(() {
        // Eliminar de la lista principal de participantes
        _participants.removeWhere((p) => p['id'] == participantId);
        
        // Eliminar del equipo correspondiente
        if (currentTeam == 'claro') {
          _teamClaro.removeWhere((p) => p['id'] == participantId);
          // Limpiar cualquier posición asignada
          _teamClaroPositions.remove(participantId.toString());
          _teamClaroPositionIndices.removeWhere((key, value) => value == participantId.toString());
          print('Jugador eliminado del Equipo Claro y posiciones limpiadas');
        } else if (currentTeam == 'oscuro') {
          _teamOscuro.removeWhere((p) => p['id'] == participantId);
          // Limpiar cualquier posición asignada
          _teamOscuroPositions.remove(participantId.toString());
          _teamOscuroPositionIndices.removeWhere((key, value) => value == participantId.toString());
          print('Jugador eliminado del Equipo Oscuro y posiciones limpiadas');
        } else {
          _unassignedParticipants.removeWhere((p) => p['id'] == participantId);
          print('Jugador eliminado del grupo sin asignar');
        }
      });
      
      // Forzar actualización visual para refrescar el campo de juego
      _redrawPositionSlots();
      
      // Mostrar mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 10),
              Expanded(child: Text('${player['nombre']} ha sido expulsado del partido')),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      // Cerrar el diálogo de carga si está abierto
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      
      print('Error al expulsar al jugador: $e');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 10),
              Expanded(child: Text('Error al expulsar al jugador: $e')),
            ],
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

// Painters para efectos visuales
class GlassPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, 0),
        Offset(size.width, size.height / 3),
        [
          Colors.white.withOpacity(0.05),
          Colors.white.withOpacity(0.01),
        ],
      );
    
    // Crear un suave reflejo en la parte superior
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height / 3),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Painter para el efecto de brillo en avatar
class AvatarGlowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, 0),
        Offset(size.width / 2, size.height / 2),
        [
          Colors.white.withOpacity(0.2),
          Colors.white.withOpacity(0.0),
        ],
      );
    
    canvas.drawCircle(
      Offset(size.width / 4, size.height / 4),
      size.width / 3,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}