import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:ui' as ui;

class CreateMatchScreen extends StatefulWidget {
  @override
  _CreateMatchScreenState createState() => _CreateMatchScreenState();
}

class _CreateMatchScreenState extends State<CreateMatchScreen> with SingleTickerProviderStateMixin {
  final SupabaseClient supabase = Supabase.instance.client;
  String _selectedFormat = '';
  List<Map<String, dynamic>> _players = [];
  // Lists to store player IDs for each team
  List<String> _teamA = [];
  List<String> _teamB = [];
  final TextEditingController _matchNameController = TextEditingController();
  
  // New variables for tracking player positions
  Map<String, Offset> _teamAPositions = {};
  Map<String, Offset> _teamBPositions = {};
  // Mapas para rastrear qué posición ocupa cada jugador
  Map<int, String> _teamAPositionIndices = {};
  Map<int, String> _teamBPositionIndices = {};
  String? _draggingPlayerId;
  bool _isDraggingTeamA = false;
  Offset? _lastTapPosition;
  // Variables para la detección precisa de toques
  GlobalKey _fieldKey = GlobalKey();
  double _fieldLeftPosition = 0;
  double _fieldTopPosition = 0;
  double _fieldWidth = 0;
  double _fieldHeight = 0;
  
  // Variable para controlar la animación de elevación
  Map<String, bool> _elevatedPlayers = {};
  
  // Variable para controlar qué jugador está seleccionado para mover
  String? _selectedPlayerId;
  
  // Tab controller para las pestañas de equipos
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _fetchPlayers();
    _tabController = TabController(length: 2, vsync: this);
    
    // Mostrar instrucciones como toast al iniciar la pantalla
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showInstructionsToast();
    });
  }
  
  @override
  void dispose() {
    _matchNameController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchPlayers() async {
    try {
      // Obtener el ID del usuario actual
      final currentUser = supabase.auth.currentUser;
      
      if (currentUser == null) {
        // Si no hay usuario autenticado, mostrar mensaje y no cargar jugadores
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Debes iniciar sesión para crear un partido'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _players = [];
        });
        return;
      }
      
      // Consultar solo los jugadores del usuario actual
      final response = await supabase
          .from('jugadores')
          .select()
          .eq('user_id', currentUser.id)
          .order('nombre', ascending: true);
      
      if (response != null && response.isNotEmpty) {
        setState(() {
          _players = List<Map<String, dynamic>>.from(response);
        });
      } else {
        setState(() {
          _players = [];
        });
      }
    } catch (e) {
      print('Error al cargar jugadores: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar jugadores: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Función para continuar a la siguiente pantalla con los datos del partido
  void _continueToNextScreen() {
    final String matchName = _matchNameController.text.trim().isNotEmpty 
      ? _matchNameController.text.trim() 
      : 'Partido ${_selectedFormat}';
      
    if (_teamA.length == int.parse(_selectedFormat.split('v')[0]) &&
        _teamB.length == int.parse(_selectedFormat.split('v')[1])) {
      
      // Crear mapa con la información del partido para pasar a la siguiente pantalla
      final Map<String, dynamic> matchData = {
        'nombre': matchName,
        'formato': _selectedFormat,
        'team_claro': _teamA,
        'team_oscuro': _teamB,
        'team_claro_positions': _teamAPositions,
        'team_oscuro_positions': _teamBPositions,
      };
      
      // Navegar a la siguiente pantalla para configurar fecha y hora
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MatchDetailsScreen(matchData: matchData),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Completa ambos equipos antes de continuar'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  // Función para seleccionar un jugador para una posición específica
  void _selectPlayerForPosition(bool isTeamA, int positionIndex) {
    // Controlador para el campo de búsqueda
    final TextEditingController searchController = TextEditingController();
    // Lista filtrada de jugadores
    List<Map<String, dynamic>> filteredPlayers = [];
    
    // Verificar si la posición ya está ocupada por un jugador
    String? currentPlayerId;
    if (isTeamA && _teamAPositionIndices.containsKey(positionIndex)) {
      currentPlayerId = _teamAPositionIndices[positionIndex];
    } else if (!isTeamA && _teamBPositionIndices.containsKey(positionIndex)) {
      currentPlayerId = _teamBPositionIndices[positionIndex];
    }
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        // Inicializar la lista filtrada con todos los jugadores disponibles
        // y también incluir el jugador actual de esta posición (si existe)
        filteredPlayers = _players.where((player) {
          final playerId = player['id'].toString();
          return !_teamA.contains(playerId) && !_teamB.contains(playerId) ||
                 playerId == currentPlayerId; // Incluir el jugador actual
        }).toList();
        
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
                    
                    // Campo de búsqueda
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: TextField(
                        controller: searchController,
                        decoration: InputDecoration(
                          hintText: 'Buscar jugador...',
                          prefixIcon: Icon(Icons.search, color: Colors.grey.shade600),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 15),
                        ),
                        onChanged: (value) {
                          setState(() {
                            // Filtrar jugadores según el texto de búsqueda
                            if (value.isEmpty) {
                              // Si el campo está vacío, mostrar todos los jugadores disponibles
                              filteredPlayers = _players.where((player) {
                                final playerId = player['id'].toString();
                                return !_teamA.contains(playerId) && !_teamB.contains(playerId);
                              }).toList();
                            } else {
                              // Filtrar por nombre
                              filteredPlayers = _players.where((player) {
                                final playerId = player['id'].toString();
                                final nombre = player['nombre'].toString().toLowerCase();
                                return !_teamA.contains(playerId) && 
                                      !_teamB.contains(playerId) && 
                                      nombre.contains(value.toLowerCase());
                              }).toList();
                            }
                          });
                        },
                      ),
                    ),
                    SizedBox(height: 16),
                    
                    Expanded(
                      child: filteredPlayers.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.person_search,
                                    size: 48,
                                    color: Colors.grey.shade400,
                                  ),
                                  SizedBox(height: 12),
                                  Text(
                                    'No hay jugadores disponibles',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  if (searchController.text.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Text(
                                        'Intenta con otro término de búsqueda',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey.shade500,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              controller: scrollController,
                              itemCount: filteredPlayers.length,
                              itemBuilder: (context, index) {
                                final player = filteredPlayers[index];
                                
                                // Calcular promedio de habilidades
                                final stats = [
                                  player['tiro'] ?? 0,
                                  player['regate'] ?? 0,
                                  player['tecnica'] ?? 0,
                                  player['defensa'] ?? 0,
                                  player['velocidad'] ?? 0,
                                  player['aguante'] ?? 0,
                                  player['control'] ?? 0,
                                ];
                                final average = stats.isNotEmpty 
                                    ? stats.reduce((a, b) => a + b) / stats.length 
                                    : 0;
                                
                                return Card(
                                  elevation: 2,
                                  margin: EdgeInsets.symmetric(vertical: 8),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: isTeamA ? Colors.blue : Colors.red,
                                      radius: 20,
                                      backgroundImage: player['foto_perfil'] != null
                                          ? NetworkImage(player['foto_perfil'])
                                          : null,
                                      child: player['foto_perfil'] == null
                                          ? Text(player['nombre'][0].toUpperCase())
                                          : null,
                                    ),
                                    title: Text(
                                      player['nombre'] ?? '',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    trailing: Container(
                                      padding: EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: _getAverageColor(average),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Text(
                                        average.toStringAsFixed(0),
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    onTap: () {
                                      this.setState(() {
                                        final playerId = player['id'].toString();
                                        
                                        // Si ya hay un jugador en esta posición, eliminarlo primero
                                        if (isTeamA) {
                                          // Verificar si la posición ya está ocupada
                                          if (_teamAPositionIndices.containsKey(positionIndex)) {
                                            // Obtener el ID del jugador que ocupa esta posición
                                            String oldPlayerId = _teamAPositionIndices[positionIndex]!;
                                            // Si el jugador seleccionado es el mismo que ya está en esta posición, no hacer nada
                                            if (oldPlayerId == playerId) {
                                              Navigator.pop(context);
                                              return;
                                            }
                                            // Eliminar este jugador del equipo
                                            _teamA.remove(oldPlayerId);
                                            // Mantener su posición en el mapa de posiciones (por si se vuelve a añadir)
                                          }
                                          
                                          // Si el jugador ya está en otro equipo, eliminarlo de ahí primero
                                          if (_teamB.contains(playerId)) {
                                            _teamB.remove(playerId);
                                            // Eliminar cualquier referencia en el mapa de índices de posición del equipo B
                                            _teamBPositionIndices.removeWhere((index, id) => id == playerId);
                                          }
                                          
                                          // Añadir el nuevo jugador
                                          _teamA.add(playerId);
                                          // Registrar qué posición ocupa este jugador
                                          _teamAPositionIndices[positionIndex] = playerId;
                                          
                                          // Asignar posición por defecto si no tenía una
                                          if (!_teamAPositions.containsKey(playerId)) {
                                            _teamAPositions[playerId] = _getDefaultPositions(
                                              int.parse(_selectedFormat.split('v')[0]), 
                                              positionIndex, 
                                              true
                                            );
                                          }
                                        } else {
                                          // Verificar si la posición ya está ocupada
                                          if (_teamBPositionIndices.containsKey(positionIndex)) {
                                            // Obtener el ID del jugador que ocupa esta posición
                                            String oldPlayerId = _teamBPositionIndices[positionIndex]!;
                                            // Si el jugador seleccionado es el mismo que ya está en esta posición, no hacer nada
                                            if (oldPlayerId == playerId) {
                                              Navigator.pop(context);
                                              return;
                                            }
                                            // Eliminar este jugador del equipo
                                            _teamB.remove(oldPlayerId);
                                            // Mantener su posición en el mapa de posiciones (por si se vuelve a añadir)
                                          }
                                          
                                          // Si el jugador ya está en otro equipo, eliminarlo de ahí primero
                                          if (_teamA.contains(playerId)) {
                                            _teamA.remove(playerId);
                                            // Eliminar cualquier referencia en el mapa de índices de posición del equipo A
                                            _teamAPositionIndices.removeWhere((index, id) => id == playerId);
                                          }
                                          
                                          // Añadir el nuevo jugador
                                          _teamB.add(playerId);
                                          // Registrar qué posición ocupa este jugador
                                          _teamBPositionIndices[positionIndex] = playerId;
                                          
                                          // Asignar posición por defecto si no tenía una
                                          if (!_teamBPositions.containsKey(playerId)) {
                                            _teamBPositions[playerId] = _getDefaultPositions(
                                              int.parse(_selectedFormat.split('v')[1]), 
                                              positionIndex, 
                                              false
                                            );
                                          }
                                        }
                                      });
                                      Navigator.pop(context);
                                    },
                                  ),
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

  // Función para obtener posiciones predeterminadas basadas en la formación
  Offset _getDefaultPositions(int totalPlayers, int index, bool isTeamA) {
    List<List<double>> positions = _getFormationPositions(totalPlayers);
    if (index < positions.length) {
      return Offset(positions[index][0], isTeamA ? positions[index][1] : 1.0 - positions[index][1]);
    }
    return Offset(0.5, isTeamA ? 0.3 : 0.7); // Posición por defecto
  }

  // Función para eliminar un jugador de un equipo
  void _removePlayerFromTeam(String playerId, bool isTeamA) {
    setState(() {
      if (isTeamA) {
        _teamA.remove(playerId);
        // No eliminamos la posición para mantenerla si el jugador se vuelve a añadir
        // _teamAPositions.remove(playerId);
        
        // Eliminar la referencia en el mapa de índices de posición
        _teamAPositionIndices.removeWhere((index, id) => id == playerId);
      } else {
        _teamB.remove(playerId);
        // No eliminamos la posición para mantenerla si el jugador se vuelve a añadir
        // _teamBPositions.remove(playerId);
        
        // Eliminar la referencia en el mapa de índices de posición
        _teamBPositionIndices.removeWhere((index, id) => id == playerId);
      }
    });
  }

  // Función para mostrar el toast con instrucciones
  void _showInstructionsToast() {
    Fluttertoast.showToast(
      msg: "Toca las posiciones vacías para agregar jugadores. Mantén presionado y arrastra para mover las posiciones.",
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 4,
      backgroundColor: Colors.black.withOpacity(0.7),
      textColor: Colors.white,
      fontSize: 16.0
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Crear Partido'),
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
        backgroundColor: const Color(0xFF1A237E), // Azul más oscuro y profesional
        elevation: 0, // Eliminar la sombra para un estilo más moderno
        actions: [
          if (_selectedFormat.isNotEmpty)
            Container(
              margin: EdgeInsets.only(right: 12),
              child: IconButton(
                icon: Icon(Icons.arrow_forward),
                onPressed: _continueToNextScreen,
                tooltip: 'Continuar',
                style: IconButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          // Gradiente sutil y profesional
          gradient: LinearGradient(
            colors: [
              const Color(0xFF1A237E),
              const Color(0xFF283593),
              const Color(0xFF3949AB),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            // Panel de configuración del partido
            _buildConfigurationPanel(),

            // Siempre mostramos el contenido, independientemente de si hay formato seleccionado
            Expanded(
              child: _buildTabView(),
            ),
          ],
        ),
      ),
    );
  }
  
  // Panel de configuración rediseñado con estilo más profesional
  Widget _buildConfigurationPanel() {
    return Container(
      margin: EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Dropdown para seleccionar formato
            Expanded(
              flex: 2,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedFormat.isEmpty ? null : _selectedFormat,
                    hint: Text(
                      'Formato',
                      style: TextStyle(
                        color: const Color(0xFF1A237E).withOpacity(0.8),
                      ),
                    ),
                    icon: Icon(Icons.keyboard_arrow_down, color: const Color(0xFF1A237E)),
                    isExpanded: true,
                    items: ['5v5', '6v6', '7v7', '8v8', '9v9', '10v10', '11v11'].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(
                          value, 
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1A237E),
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        _selectedFormat = newValue!;
                        _teamA.clear();
                        _teamB.clear();
                        _teamAPositions.clear();
                        _teamBPositions.clear();
                        _teamAPositionIndices.clear();
                        _teamBPositionIndices.clear();
                      });
                    },
                  ),
                ),
              ),
            ),
            
            SizedBox(width: 16),
            
            // TextField para nombre del partido a la derecha
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _matchNameController,
                  style: TextStyle(
                    color: const Color(0xFF1A237E),
                  ),
                  decoration: InputDecoration(
                    labelText: 'Nombre del partido',
                    labelStyle: TextStyle(
                      color: const Color(0xFF1A237E).withOpacity(0.8),
                    ),
                    hintText: 'Ej: Liga Barrial - J3',
                    border: InputBorder.none,
                    prefixIcon: Icon(Icons.sports_soccer, color: const Color(0xFF283593)),
                    contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabView() {
    // Obtenemos el tamaño del equipo solo si hay formato seleccionado
    final int teamASize = _selectedFormat.isNotEmpty 
        ? int.parse(_selectedFormat.split('v')[0]) 
        : 0;
    final int teamBSize = _selectedFormat.isNotEmpty 
        ? int.parse(_selectedFormat.split('v')[1]) 
        : 0;
    
    return Column(
      children: [
        // TabBar de equipos - sin margen vertical
        Container(
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 0),
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
            indicatorSize: TabBarIndicatorSize.tab, // Asegura que el indicador cubra toda la pestaña
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
            indicatorColor: Colors.transparent, // Eliminar la línea del indicador
            indicatorWeight: 0, // Establecer el grosor a 0
            dividerColor: Colors.transparent, // Eliminar la línea divisoria
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white.withOpacity(0.7),
            labelStyle: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              letterSpacing: 0.5,
            ),
            tabs: [
              // Tab Equipo Claro - usando Row con mainAxisSize: MainAxisSize.min
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
                      if (_selectedFormat.isNotEmpty) SizedBox(width: 4),
                      if (_selectedFormat.isNotEmpty)
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _teamA.length == teamASize 
                                ? Colors.green.shade600 
                                : Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            "${_teamA.length}/${teamASize}",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              // Tab Equipo Oscuro - usando Row con mainAxisSize: MainAxisSize.min
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
                      if (_selectedFormat.isNotEmpty) SizedBox(width: 4),
                      if (_selectedFormat.isNotEmpty)
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _teamB.length == teamBSize 
                                ? Colors.green.shade600 
                                : Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            "${_teamB.length}/${teamBSize}",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
            onTap: (index) {
              setState(() {}); // Para actualizar colores de pestañas
            },
          ),
        ),
        
        // Contenido de las pestañas - sin espacio adicional
        Expanded(
          child: TabBarView(
            controller: _tabController,
            physics: NeverScrollableScrollPhysics(), // Prevenir deslizamiento horizontal
            children: [
              // Pestaña Equipo Claro
              _buildFootballField(true),
              
              // Pestaña Equipo Oscuro
              _buildFootballField(false),
            ],
          ),
        ),
      ],
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
                left: (maxWidth - fieldWidth - (margin * 2)) / 2,
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
                      image: AssetImage('assets/grass_texture.png'),
                      fit: BoxFit.cover,
                      opacity: 0.2, // Sutil, no distraer demasiado
                    ),
                  ),
                  clipBehavior: Clip.antiAlias, // Para que el hijo no sobresalga del borde redondeado
                  child: Stack(
                    children: [
                      // Campo de fútbol mejorado
                      _buildFootballFieldElements(fieldWidth, fieldHeight, isTeamA),
                      
                      // Añadir reflejo/brillo para dar efecto profesional
                      Positioned.fill(
                        child: CustomPaint(
                          painter: GlassPainter(),
                        ),
                      ),
                      
                      // Detector de toques para campo completo
                      Positioned.fill(
                        child: Container(
                          // Contenedor transparente que reemplaza al GestureDetector
                          // pero no tiene funcionalidad de toque
                          color: Colors.transparent,
                        ),
                      ),
                      
                      // Posiciones vacías para el equipo seleccionado (solo si hay formato)
                      if (_selectedFormat.isNotEmpty)
                        ..._buildEmptyPositions(
                          int.parse(_selectedFormat.split('v')[isTeamA ? 0 : 1]),
                          isTeamA,
                          fieldWidth,
                          fieldHeight,
                        ),
                        
                      // Jugadores del equipo seleccionado
                      if (isTeamA && _teamA.isNotEmpty)
                        ..._buildTeamPlayers(_teamA, _teamAPositions, true, fieldWidth, fieldHeight),
                      
                      if (!isTeamA && _teamB.isNotEmpty)
                        ..._buildTeamPlayers(_teamB, _teamBPositions, false, fieldWidth, fieldHeight),
                      
                      // Indicador cuando no hay formato seleccionado (sutil, no popup)
                      if (_selectedFormat.isEmpty)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.black.withOpacity(0.5),
                                  Colors.black.withOpacity(0.7),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.arrow_upward_rounded,
                                    color: Colors.white,
                                    size: 40,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black.withOpacity(0.8),
                                        blurRadius: 10,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    margin: EdgeInsets.symmetric(vertical: 10),
                                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [Colors.blue.shade700, Colors.indigo.shade900],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.5),
                                          blurRadius: 10,
                                          offset: Offset(0, 4),
                                        ),
                                      ],
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.3),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Text(
                                      "SELECCIONA UN FORMATO",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.0,
                                        shadows: [
                                          Shadow(
                                            color: Colors.black.withOpacity(0.7),
                                            blurRadius: 5,
                                            offset: Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Container(
                                    width: 220,
                                    margin: EdgeInsets.only(top: 10),
                                    child: Text(
                                      "Define cuántos jugadores participarán en cada equipo",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        height: 1.3,
                                        shadows: [
                                          Shadow(
                                            color: Colors.black,
                                            blurRadius: 3,
                                            offset: Offset(0, 1),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      
                      // Botón de ayuda integrado en la esquina del campo
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _showInstructionsToast,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.help_outline,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
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
      },
    );
  }
  
  // Widget para mostrar mensaje cuando no hay formato seleccionado
  Widget _buildFormatSelectionMessage() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.5),
        child: Center(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.sports_soccer,
                  size: 42,
                  color: const Color(0xFF1A237E),
                ),
                SizedBox(height: 12),
                Text(
                  "Selecciona un formato de partido",
                  style: TextStyle(
                    color: const Color(0xFF1A237E),
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "Elige el número de jugadores por equipo\npara configurar la alineación",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => _showFormatSelectionDialog(),
                  icon: Icon(Icons.format_list_numbered),
                  label: Text("Seleccionar formato"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A237E),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Método para mostrar diálogo de selección de formato
  void _showFormatSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.sports_soccer,
              color: const Color(0xFF1A237E),
              size: 28,
            ),
            SizedBox(width: 10),
            Text(
              "SELECCIONA EL FORMATO",
              style: TextStyle(
                color: const Color(0xFF1A237E),
                fontWeight: FontWeight.bold,
                fontSize: 18,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 8,
        contentPadding: EdgeInsets.symmetric(vertical: 20, horizontal: 10),
        content: Container(
          width: double.minPositive,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Número de jugadores por equipo",
                style: TextStyle(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 15),
              ...'5v5,6v6,7v7,8v8,9v9,10v10,11v11'.split(',').map((format) => Card(
                elevation: 2,
                margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ListTile(
                  title: Text(
                    format,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1A237E),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  leading: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.people,
                      color: const Color(0xFF1A237E),
                    ),
                  ),
                  onTap: () {
                    setState(() {
                      _selectedFormat = format;
                      _teamA.clear();
                      _teamB.clear();
                      _teamAPositions.clear();
                      _teamBPositions.clear();
                    });
                    Navigator.pop(context);
                  },
                ),
              )).toList(),
            ],
          ),
        ),
        actions: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "Cancelar",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.shade600,
                padding: EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFootballFieldElements(double width, double height, bool isTeamA) {
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
        
        // Indicador de equipo
        Positioned(
          top: height * 0.04,
          left: width * 0.5 - 60,
          child: Container(
            width: 120,
            padding: EdgeInsets.symmetric(vertical: 4, horizontal: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isTeamA 
                    ? [Colors.blue.shade700, Colors.blue.shade900] 
                    : [Colors.red.shade700, Colors.red.shade900],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
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
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.sports_soccer,
                  color: Colors.white,
                  size: 16,
                ),
                SizedBox(width: 6),
                Flexible(
                  child: Text(
                    isTeamA ? "Equipo Claro" : "Equipo Oscuro",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 0.5,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

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

  bool _isPositionOccupied(int index, bool isTeamA) {
    // Comprobar si la posición está ocupada usando el mapa de índices de posición
    if (isTeamA) {
      return _teamAPositionIndices.containsKey(index);
    } else {
      return _teamBPositionIndices.containsKey(index);
    }
  }

  List<Widget> _buildTeamPlayers(
      List<String> team, 
      Map<String, Offset> positions, 
      bool isTeamA, 
      double fieldWidth, 
      double fieldHeight) {
    List<Widget> playerWidgets = [];
    
    for (int i = 0; i < team.length; i++) {
      final playerId = team[i];
      final player = _players.firstWhere(
        (p) => p['id'].toString() == playerId,
        orElse: () => {'nombre': isTeamA ? 'A${i + 1}' : 'B${i + 1}', 'foto_perfil': null},
      );
      
      // Calcular el promedio de habilidades
      final stats = [
        player['tiro'] ?? 0,
        player['regate'] ?? 0,
        player['tecnica'] ?? 0,
        player['defensa'] ?? 0,
        player['velocidad'] ?? 0,
        player['aguante'] ?? 0,
        player['control'] ?? 0,
      ];
      final average = stats.isNotEmpty 
          ? stats.reduce((a, b) => a + b) / stats.length 
          : 0;
      
      // Obtener la posición actual o usar una posición predeterminada
      final Offset position = positions[playerId] ?? 
          _getDefaultPositions(
            int.parse(_selectedFormat.split('v')[isTeamA ? 0 : 1]),
            i,
            isTeamA
          );
      
      // Convertir la posición relativa (0-1) a coordenadas reales en el campo
      final double posX = position.dx * fieldWidth;
      final double posY = position.dy * fieldHeight;
      
      // Crear widget para el avatar del jugador
      playerWidgets.add(
        AnimatedPositioned(
          duration: Duration(milliseconds: 200),
          curve: Curves.easeOutQuad,
          left: posX - 30,
          top: _elevatedPlayers[playerId] == true 
              ? posY - 45 // Posición elevada (15px más arriba)
              : posY - 30, // Posición normal
          child: GestureDetector(
            // Simplificado: ahora el longPress inicia directamente el arrastre
            onLongPress: () {
              setState(() {
                _draggingPlayerId = playerId;
                _isDraggingTeamA = isTeamA;
                // Activar efecto de elevación
                _elevatedPlayers[playerId] = true;
              });
              
              // Mostrar indicación visual
              Fluttertoast.showToast(
                msg: "Arrastra para mover la posición",
                toastLength: Toast.LENGTH_SHORT,
                gravity: ToastGravity.CENTER,
                backgroundColor: Colors.black.withOpacity(0.7),
                textColor: Colors.white,
              );
            },
            onLongPressMoveUpdate: (details) {
              if (_draggingPlayerId == playerId) {
                setState(() {
                  // Mantener el efecto de elevación mientras se arrastra
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
                    _teamAPositions[playerId] = Offset(dx, dy);
                  } else {
                    _teamBPositions[playerId] = Offset(dx, dy);
                  }
                });
              }
            },
            onLongPressEnd: (_) {
              setState(() {
                // Quitar efecto de elevación cuando se suelta
                _elevatedPlayers[playerId] = false;
                _draggingPlayerId = null;
              });
            },
            child: _buildPlayerAvatar(player, isTeamA, average, playerId),
          ),
        ),
      );
      
      // Añadir el nombre del jugador debajo
      playerWidgets.add(
        AnimatedPositioned(
          duration: Duration(milliseconds: 100),
          curve: Curves.easeInOut,
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
              player['nombre'] ?? (isTeamA ? 'A${i + 1}' : 'B${i + 1}'),
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
  
  Widget _buildPlayerAvatar(Map<String, dynamic> player, bool isTeamA, double average, String playerId) {
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
            child: player['foto_perfil'] != null
                ? ClipOval(
                    child: Image.network(
                      player['foto_perfil'],
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded / 
                                  loadingProgress.expectedTotalBytes!
                              : null,
                        );
                      },
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
        
        // Botón para eliminar jugador
        GestureDetector(
          onTap: () => _removePlayerFromTeam(playerId, isTeamA),
          child: Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.grey.shade800, Colors.black],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black54,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.close,
              size: 16,
              color: Colors.white,
            ),
          ),
        ),
        
        // Rating del jugador
        Positioned(
          top: 0,
          right: 0,
          child: Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _getAverageColor(average).withOpacity(0.8),
                  _getAverageColor(average),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                average.toStringAsFixed(0),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Color _getAverageColor(double average) {
    if (average >= 80) return Colors.green;
    if (average >= 60) return Colors.orange;
    return Colors.red;
  }

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
}

// Clase para la pantalla de detalles del partido (fecha y hora)
class MatchDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> matchData;
  
  const MatchDetailsScreen({Key? key, required this.matchData}) : super(key: key);
  
  @override
  _MatchDetailsScreenState createState() => _MatchDetailsScreenState();
}

class _MatchDetailsScreenState extends State<MatchDetailsScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  late TimeOfDay _selectedTime;
  late DateTime _selectedDate;
  
  @override
  void initState() {
    super.initState();
    _selectedTime = TimeOfDay.now();
    _selectedDate = DateTime.now();
  }
  
  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.orange.shade600,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }
  
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.orange.shade600,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }
  
  Future<void> _saveMatch() async {
    try {
      // Mostrar indicador de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: CircularProgressIndicator(
            color: Colors.orange.shade600,
          ),
        ),
      );

      final DateTime matchDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      // Convertir posiciones de Offset a formato guardable
      Map<String, Map<String, double>> teamClaroPositionsData = {};
      Map<String, Map<String, double>> teamOscuroPositionsData = {};
      
      // Procesar posiciones de equipo claro
      widget.matchData['team_claro_positions'].forEach((playerId, offset) {
        teamClaroPositionsData[playerId] = {
          'dx': offset.dx,
          'dy': offset.dy,
        };
      });
      
      // Procesar posiciones de equipo oscuro
      widget.matchData['team_oscuro_positions'].forEach((playerId, offset) {
        teamOscuroPositionsData[playerId] = {
          'dx': offset.dx,
          'dy': offset.dy,
        };
      });

      // 1. Crear el partido con posiciones incluidas
      final matchResponse = await supabase.from('partidos').insert({
        'nombre': widget.matchData['nombre'],
        'formato': widget.matchData['formato'],
        'team_claro': widget.matchData['team_claro'],
        'team_oscuro': widget.matchData['team_oscuro'],
        'team_claro_positions': teamClaroPositionsData,
        'team_oscuro_positions': teamOscuroPositionsData,
        'fecha': matchDateTime.toIso8601String(),
        'estado': 'pendiente',
        'user_id': supabase.auth.currentUser!.id,
        'resultado_claro': 0,
        'resultado_oscuro': 0,
      }).select();

      // Obtener el ID del partido recién creado
      final int matchId = matchResponse[0]['id'];

      // 2. Inicializar estadísticas para equipo claro (team A)
      for (String playerId in widget.matchData['team_claro']) {
        await supabase.from('estadisticas').insert({
          'jugador_id': playerId,
          'partido_id': matchId,
          'goles': 0,
          'asistencias': 0,
          'equipo': 'team_claro'
        });
      }

      // 3. Inicializar estadísticas para equipo oscuro (team B)
      for (String playerId in widget.matchData['team_oscuro']) {
        await supabase.from('estadisticas').insert({
          'jugador_id':playerId,
          'partido_id': matchId,
          'goles': 0,
          'asistencias': 0,
          'equipo': 'team_oscuro'
        });
      }

      // Cerrar el indicador de carga
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Partido guardado correctamente'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Navegar de vuelta a la pantalla principal (o a donde corresponda)
      Navigator.pop(context);
      Navigator.pop(context); // Volver a la pantalla anterior a la creación
    } catch (e) {
      // Cerrar el indicador de carga si hay error
      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar el partido: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detalles del Partido'),
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
        backgroundColor: Colors.blue.shade800,
        actions: [
          IconButton(
            icon: Icon(Icons.save, color: Colors.white),
            onPressed: _saveMatch,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade300, Colors.blue.shade800],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            // Información del partido
            Padding(
              padding: EdgeInsets.all(16),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Información del Partido',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade800,
                        ),
                      ),
                      Divider(),
                      ListTile(
                        leading: Icon(Icons.sports_soccer, color: Colors.orange.shade600),
                        title: Text('Nombre'),
                        subtitle: Text(
                          widget.matchData['nombre'],
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      ListTile(
                        leading: Icon(Icons.people, color: Colors.orange.shade600),
                        title: Text('Formato'),
                        subtitle: Text(
                          widget.matchData['formato'],
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      ListTile(
                        leading: Icon(Icons.group, color: Colors.blue),
                        title: Text('Equipo Claro'),
                        subtitle: Text(
                          '${widget.matchData['team_claro'].length} jugadores',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      ListTile(
                        leading: Icon(Icons.group, color: Colors.red),
                        title: Text('Equipo Oscuro'),
                        subtitle: Text(
                          '${widget.matchData['team_oscuro'].length} jugadores',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Selección de fecha y hora
            Padding(
              padding: EdgeInsets.all(16),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Fecha y Hora del Partido',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade800,
                        ),
                      ),
                      Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: Icon(Icons.calendar_today),
                              label: Text(
                                '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                                style: TextStyle(color: Colors.white),
                              ),
                              onPressed: () => _selectDate(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue.shade700,
                                padding: EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: Icon(Icons.access_time),
                              label: Text(
                                _selectedTime.format(context),
                                style: TextStyle(color: Colors.white),
                              ),
                              onPressed: () => _selectTime(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange.shade600,
                                padding: EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            Spacer(),
            
            // Botón para guardar
            Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _saveMatch,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                  child: Text(
                    'GUARDAR PARTIDO',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Painter para el efecto de reflejo del campo
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