import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;

class TeamManagementScreen extends StatefulWidget {
  final Map<String, dynamic> match;
  
  const TeamManagementScreen({Key? key, required this.match}) : super(key: key);
  
  @override
  _TeamManagementScreenState createState() => _TeamManagementScreenState();
}

class _TeamManagementScreenState extends State<TeamManagementScreen> with SingleTickerProviderStateMixin {
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
            } else {
              // Para otros usuarios, intentar consultar datos básicos
              try {
                // Intentar obtener el perfil desde la tabla profiles sin incluir 'email' que no existe
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
            // Asignar posición predeterminada si no tiene una
            if (!_teamClaroPositions.containsKey(participant['id'].toString())) {
              _teamClaroPositions[participant['id'].toString()] = 
                  _getDefaultPosition(teamClaro.length - 1, true);
            }
          } else if (item['equipo'] == 'oscuro') {
            teamOscuro.add(participant);
            // Asignar posición predeterminada si no tiene una
            if (!_teamOscuroPositions.containsKey(participant['id'].toString())) {
              _teamOscuroPositions[participant['id'].toString()] = 
                  _getDefaultPosition(teamOscuro.length - 1, false);
            }
          } else {
            unassigned.add(participant);
          }
        } catch (userError) {
          print('Error al procesar usuario para participante ${item['id']}: $userError');
        }
      }
      
      setState(() {
        _participants = allParticipants;
        _teamClaro = teamClaro;
        _teamOscuro = teamOscuro;
        _unassignedParticipants = unassigned;
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
  
  // Obtener posiciones predeterminadas basadas en la formación
  List<List<double>> _getFormationPositions(int totalPlayers) {
    // Posiciones relativas (x, y) donde x e y están entre 0 y 1
    switch (totalPlayers) {
      case 5:
        return [
          [0.5, 0.15],   // Delantero
          [0.2, 0.3],    // Mediocampista izquierdo
          [0.5, 0.4],    // Mediocampista central
          [0.8, 0.3],    // Mediocampista derecho
          [0.5, 0.7],    // Defensa / Portero
        ];
      case 6:
        return [
          [0.5, 0.15],   // Delantero
          [0.2, 0.3],    // Mediocampista izquierdo
          [0.5, 0.3],    // Mediocampista central
          [0.8, 0.3],    // Mediocampista derecho
          [0.3, 0.6],    // Defensa izquierdo
          [0.7, 0.6],    // Defensa derecho
        ];
      case 7:
        return [
          [0.5, 0.15],   // Delantero
          [0.2, 0.25],   // Extremo izquierdo
          [0.5, 0.3],    // Mediocampista central
          [0.8, 0.25],   // Extremo derecho
          [0.3, 0.5],    // Mediocampista defensivo izquierdo
          [0.7, 0.5],    // Mediocampista defensivo derecho
          [0.5, 0.7],    // Defensa central / Portero
        ];
      case 8:
        return [
          [0.3, 0.15],   // Delantero izquierdo
          [0.7, 0.15],   // Delantero derecho
          [0.2, 0.3],    // Extremo izquierdo
          [0.5, 0.3],    // Mediocampista central
          [0.8, 0.3],    // Extremo derecho
          [0.3, 0.5],    // Mediocampista defensivo
          [0.7, 0.5],    // Defensa central
          [0.5, 0.7],    // Portero
        ];
      case 9:
        return [
          [0.3, 0.15],   // Delantero izquierdo
          [0.5, 0.15],   // Delantero central
          [0.7, 0.15],   // Delantero derecho
          [0.2, 0.35],   // Mediocampista izquierdo
          [0.5, 0.35],   // Mediocampista central
          [0.8, 0.35],   // Mediocampista derecho
          [0.2, 0.55],   // Defensa izquierdo
          [0.8, 0.55],   // Defensa derecho
          [0.5, 0.7],    // Portero
        ];
      case 10:
        return [
          [0.3, 0.15],   // Delantero izquierdo
          [0.7, 0.15],   // Delantero derecho
          [0.15, 0.3],   // Extremo izquierdo
          [0.38, 0.25],  // Mediocampista izquierdo
          [0.62, 0.25],  // Mediocampista derecho
          [0.85, 0.3],   // Extremo derecho
          [0.3, 0.5],    // Mediocampista defensivo izquierdo
          [0.7, 0.5],    // Mediocampista defensivo derecho
          [0.5, 0.6],    // Defensa central
          [0.5, 0.75],   // Portero
        ];
      case 11:
        return [
          [0.5, 0.15],   // Delantero centro
          [0.25, 0.2],   // Delantero izquierdo
          [0.75, 0.2],   // Delantero derecho
          [0.15, 0.35],  // Extremo izquierdo
          [0.5, 0.35],   // Mediocampista central
          [0.85, 0.35],  // Extremo derecho
          [0.25, 0.5],   // Mediocampista defensivo izquierdo
          [0.75, 0.5],   // Mediocampista defensivo derecho
          [0.25, 0.65],  // Defensa izquierdo
          [0.75, 0.65],  // Defensa derecho
          [0.5, 0.75],   // Portero
        ];
      default:
        // Para otros formatos que no estén definidos explícitamente
        return List.generate(totalPlayers, (index) {
          double y = 0.15 + (0.6 * index / (totalPlayers - 1));
          double x = 0.5;
          if (index % 2 == 1) {
            x = 0.3 + (0.4 * (index / totalPlayers));
          } else if (index % 2 == 0 && index > 0) {
            x = 0.7 - (0.4 * (index / totalPlayers));
          }
          return [x, y];
        });
    }
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
        actions: [
          IconButton(
            onPressed: _loadParticipants,
            icon: Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Actualizar',
          )
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
                  
                  // Lista de participantes sin asignar
                  _buildUnassignedParticipants(),
                ],
              ),
            ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Botón para unirse al partido
          FloatingActionButton.extended(
            onPressed: _joinMatch,
            icon: Icon(Icons.person_add),
            label: Text('Unirme al partido'),
            backgroundColor: Colors.purple.shade600,
            heroTag: 'join',
          ),
          SizedBox(height: 16),
          // Botón de guardar
          FloatingActionButton.extended(
            onPressed: _saveAndExit,
            icon: Icon(Icons.save),
            label: Text('Guardar'),
            backgroundColor: Colors.green.shade600,
            heroTag: 'save',
          ),
        ],
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
                      image: AssetImage('assets/habilidades.png'), // Usamos una imagen existente como textura
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
                      
                      // Marcador de goles en la parte superior
                      _buildScoreBoard(fieldWidth),
                      
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
            },
            onLongPressEnd: (_) {
              setState(() {
                _elevatedPlayers[playerId] = false;
                _draggingPlayerId = null;
              });
            },
            onTap: () => _showPlayerOptions(player),
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
                  ? [Colors.blue.shade600, Colors.blue.shade900] 
                  : [Colors.red.shade600, Colors.red.shade900],
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
  
  Widget _buildUnassignedParticipants() {
    if (_unassignedParticipants.isEmpty) {
      return Container(
        margin: EdgeInsets.fromLTRB(16, 0, 16, 16),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            'No hay participantes sin asignar',
            style: TextStyle(
              color: Colors.grey.shade700,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    }
    
    return Container(
      margin: EdgeInsets.fromLTRB(16, 0, 16, 16),
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
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.people, color: Colors.grey.shade800),
                SizedBox(width: 8),
                Text(
                  'Participantes sin asignar',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Colors.grey.shade200,
                  radius: 12,
                  child: Text(
                    '${_unassignedParticipants.length}',
                    style: TextStyle(
                      color: Colors.grey.shade800,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1),
          Container(
            height: 120, // Altura fija para limitar el espacio en la pantalla
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _unassignedParticipants.length,
              itemBuilder: (context, index) {
                final participant = _unassignedParticipants[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: participant['avatar_url'] != null
                        ? NetworkImage(participant['avatar_url'])
                        : null,
                    backgroundColor: Colors.grey.shade200,
                    child: participant['avatar_url'] == null
                        ? Icon(Icons.person, color: Colors.grey.shade700)
                        : null,
                  ),
                  title: Text(
                    participant['nombre'] ?? 'Usuario',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    participant['email'] ?? '',
                    style: TextStyle(fontSize: 12),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () => _assignToTeam(participant, 'claro'),
                        icon: Icon(Icons.add_circle, color: Colors.blue.shade700),
                        tooltip: 'Asignar a Equipo Claro',
                      ),
                      IconButton(
                        onPressed: () => _assignToTeam(participant, 'oscuro'),
                        icon: Icon(Icons.add_circle, color: Colors.red.shade700),
                        tooltip: 'Asignar a Equipo Oscuro',
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  
  void _showPlayerOptions(Map<String, dynamic> player) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundImage: player['avatar_url'] != null
                      ? NetworkImage(player['avatar_url'])
                      : null,
                  backgroundColor: player['equipo'] == 'claro'
                      ? Colors.blue.shade100
                      : Colors.red.shade100,
                  child: player['avatar_url'] == null
                      ? Icon(
                          Icons.person,
                          color: player['equipo'] == 'claro'
                              ? Colors.blue.shade800
                              : Colors.red.shade800,
                        )
                      : null,
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        player['nombre'] ?? 'Usuario',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        player['email'] ?? '',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            Divider(),
            SizedBox(height: 10),
            if (player['equipo'] == 'claro') ...[
              _buildOptionButton(
                icon: Icons.swap_horiz,
                text: 'Mover a Equipo Oscuro',
                color: Colors.red.shade700,
                onTap: () {
                  Navigator.pop(context);
                  _assignToTeam(player, 'oscuro');
                },
              ),
              SizedBox(height: 10),
              _buildOptionButton(
                icon: Icons.person_remove,
                text: 'Quitar del equipo',
                color: Colors.grey.shade700,
                onTap: () {
                  Navigator.pop(context);
                  _assignToTeam(player, null);
                },
              ),
            ] else if (player['equipo'] == 'oscuro') ...[
              _buildOptionButton(
                icon: Icons.swap_horiz,
                text: 'Mover a Equipo Claro',
                color: Colors.blue.shade700,
                onTap: () {
                  Navigator.pop(context);
                  _assignToTeam(player, 'claro');
                },
              ),
              SizedBox(height: 10),
              _buildOptionButton(
                icon: Icons.person_remove,
                text: 'Quitar del equipo',
                color: Colors.grey.shade700,
                onTap: () {
                  Navigator.pop(context);
                  _assignToTeam(player, null);
                },
              ),
            ],
            SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
  
  Widget _buildOptionButton({
    required IconData icon,
    required String text,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            SizedBox(width: 12),
            Text(
              text,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _saveAndExit() {
    // Ya hemos guardado los cambios en la base de datos al asignar jugadores
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Equipos guardados correctamente'),
        backgroundColor: Colors.green,
      ),
    );
    Navigator.pop(context, true); // Regresamos con resultado para actualizar
  }
  
  // Método para cargar el marcador del partido desde la base de datos
  Future<void> _loadMatchScore() async {
    try {
      final matchData = await supabase
          .from('partidos')
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
      print('Error al cargar el marcador: $e');
      // Mantener los valores por defecto (0-0)
    }
  }
  
  // Método para actualizar el marcador en la base de datos
  Future<void> _updateMatchScore() async {
    try {
      await supabase
          .from('partidos')
          .update({
            'resultado_claro': _resultadoClaro,
            'resultado_oscuro': _resultadoOscuro,
          })
          .eq('id', widget.match['id']);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Marcador actualizado'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 1),
        ),
      );
    } catch (e) {
      print('Error al actualizar el marcador: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al actualizar el marcador: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Construir el marcador de goles en la parte superior del campo
  Widget _buildScoreBoard(double fieldWidth) {
    return Positioned(
      top: 10,
      left: fieldWidth / 2 - 80,
      child: Container(
        width: 160,
        padding: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.black.withOpacity(0.7), Colors.black.withOpacity(0.8)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Equipo Claro
            GestureDetector(
              onTap: () {
                setState(() {
                  _resultadoClaro++;
                  _updateMatchScore();
                });
              },
              onLongPress: () {
                if (_resultadoClaro > 0) {
                  setState(() {
                    _resultadoClaro--;
                    _updateMatchScore();
                  });
                }
              },
              child: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  "$_resultadoClaro",
                  style: TextStyle(
                    color: Colors.blue.shade200,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
            ),
            
            // Separador
            Container(
              margin: EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                "-",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
            ),
            
            // Equipo Oscuro
            GestureDetector(
              onTap: () {
                setState(() {
                  _resultadoOscuro++;
                  _updateMatchScore();
                });
              },
              onLongPress: () {
                if (_resultadoOscuro > 0) {
                  setState(() {
                    _resultadoOscuro--;
                    _updateMatchScore();
                  });
                }
              },
              child: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  "$_resultadoOscuro",
                  style: TextStyle(
                    color: Colors.red.shade200,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Función para construir posiciones vacías en el campo
  List<Widget> _buildEmptyPositions(int count, bool isTeamA, double fieldWidth, double fieldHeight) {
    List<Widget> positions = [];
    List<List<double>> formationPositions = _getFormationPositions(count);
    
    for (int i = 0; i < count; i++) {
      if (_isPositionOccupied(i, isTeamA)) continue;
      
      double posX = formationPositions[i][0] * fieldWidth;
      double posY = isTeamA 
          ? formationPositions[i][1] * fieldHeight
          : (1 - formationPositions[i][1]) * fieldHeight;
      
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
                                        : (player['email'] ?? ''),
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
      final String userName = userEmail.split('@')[0]; // Usar parte del email como nombre
      
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
        // Actualizar directamente en la base de datos antes de actualizar localmente
        await supabase
          .from('match_participants')
          .update({'equipo': targetTeam})
          .eq('id', playerId);
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
      print('Error al asignar jugador a posición: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al asignar jugador: $e'),
          backgroundColor: Colors.red,
        ),
      );
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