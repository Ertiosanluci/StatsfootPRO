import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:ui' as ui;

/// Widget que implementa campos de fútbol con tabs para mostrar los equipos
/// Permite visualizar y posicionar jugadores en un campo de fútbol
class FootballFieldTabs extends StatefulWidget {
  /// Lista de jugadores del equipo claro
  final List<String> teamClaro;
  
  /// Lista de jugadores del equipo oscuro
  final List<String> teamOscuro;
  
  /// Mapa de posiciones para el equipo claro
  final Map<String, Offset> teamClaroPositions;
  
  /// Mapa de posiciones para el equipo oscuro
  final Map<String, Offset> teamOscuroPositions;
  
  /// Formato del partido (ej: "5v5", "7v7", "11v11")
  final String formato;
  
  /// Lista de todos los jugadores disponibles
  final List<Map<String, dynamic>> allPlayers;
  
  /// Función que se llama cuando se actualiza la posición de un jugador
  final Function(String playerId, Offset position, bool isTeamClaro)? onPositionUpdated;
  
  /// Función que se llama cuando se cambia un jugador en una posición
  final Function(String playerId, int positionIndex, bool isTeamClaro)? onPlayerChanged;
  
  /// Función que se llama cuando se elimina un jugador
  final Function(String playerId, bool isTeamClaro)? onPlayerRemoved;
  
  /// Si es true, permite interactuar con los jugadores (mover, eliminar, etc.)
  final bool interactive;

  const FootballFieldTabs({
    Key? key,
    required this.teamClaro,
    required this.teamOscuro,
    required this.teamClaroPositions,
    required this.teamOscuroPositions,
    required this.formato,
    required this.allPlayers,
    this.onPositionUpdated,
    this.onPlayerChanged,
    this.onPlayerRemoved,
    this.interactive = true,
  }) : super(key: key);

  @override
  _FootballFieldTabsState createState() => _FootballFieldTabsState();
}

class _FootballFieldTabsState extends State<FootballFieldTabs> with SingleTickerProviderStateMixin {
  // Controller para las pestañas
  late TabController _tabController;

  // Variables para manejar el arrastre de jugadores
  String? _draggingPlayerId;
  bool _isDraggingTeamClaro = false;
  
  // Mapas para referencia local de posiciones
  late Map<String, Offset> _teamClaroPositions;
  late Map<String, Offset> _teamOscuroPositions;
  
  // Mapas para rastrear qué posición ocupa cada jugador
  late Map<int, String> _teamClaroPositionIndices = {};
  late Map<int, String> _teamOscuroPositionIndices = {};
  
  // Referencia al campo de fútbol
  GlobalKey _fieldKey = GlobalKey();
  
  // Variable para controlar la animación de elevación
  Map<String, bool> _elevatedPlayers = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Inicializar mapas locales con las referencias pasadas
    _teamClaroPositions = Map.from(widget.teamClaroPositions);
    _teamOscuroPositions = Map.from(widget.teamOscuroPositions);
    
    // Calcular índices de posición basados en las posiciones actuales
    _calculatePositionIndices();
    
    // Mostrar instrucciones si el modo es interactivo
    if (widget.interactive) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showInstructionsToast();
      });
    }
  }
  
  @override
  void didUpdateWidget(FootballFieldTabs oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Actualizar mapas locales si los datos de entrada cambian
    if (oldWidget.teamClaroPositions != widget.teamClaroPositions) {
      _teamClaroPositions = Map.from(widget.teamClaroPositions);
    }
    
    if (oldWidget.teamOscuroPositions != widget.teamOscuroPositions) {
      _teamOscuroPositions = Map.from(widget.teamOscuroPositions);
    }
    
    // Recalcular índices de posición
    _calculatePositionIndices();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Ensure we update positions when dependencies change
    _teamClaroPositions = Map.from(widget.teamClaroPositions);
    _teamOscuroPositions = Map.from(widget.teamOscuroPositions);
    _calculatePositionIndices();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Calcular los índices de posición basados en las posiciones actuales
  void _calculatePositionIndices() {
    _teamClaroPositionIndices.clear();
    _teamOscuroPositionIndices.clear();
    
    // Calcular posiciones para el equipo claro
    final int teamClaroSize = _getTeamSize(true);
    List<List<double>> teamClaroFormationPositions = _getFormationPositions(teamClaroSize);
    
    for (int i = 0; i < widget.teamClaro.length; i++) {
      String playerId = widget.teamClaro[i];
      
      // Si ya tiene una posición, encontrar el índice más cercano
      if (_teamClaroPositions.containsKey(playerId)) {
        int closestIndex = _findClosestPositionIndex(
          _teamClaroPositions[playerId]!,
          teamClaroFormationPositions,
          true
        );
        _teamClaroPositionIndices[closestIndex] = playerId;
      } else {
        // Si no tiene posición, asignar a un índice disponible
        int availableIndex = _findFirstAvailableIndex(_teamClaroPositionIndices, teamClaroSize);
        _teamClaroPositionIndices[availableIndex] = playerId;
        
        // Asignar posición predeterminada
        _teamClaroPositions[playerId] = _getDefaultPositions(
          teamClaroSize,
          availableIndex,
          true
        );
      }
    }
    
    // Calcular posiciones para el equipo oscuro
    final int teamOscuroSize = _getTeamSize(false);
    List<List<double>> teamOscuroFormationPositions = _getFormationPositions(teamOscuroSize);
    
    for (int i = 0; i < widget.teamOscuro.length; i++) {
      String playerId = widget.teamOscuro[i];
      
      // Si ya tiene una posición, encontrar el índice más cercano
      if (_teamOscuroPositions.containsKey(playerId)) {
        int closestIndex = _findClosestPositionIndex(
          _teamOscuroPositions[playerId]!,
          teamOscuroFormationPositions,
          false
        );
        _teamOscuroPositionIndices[closestIndex] = playerId;
      } else {
        // Si no tiene posición, asignar a un índice disponible
        int availableIndex = _findFirstAvailableIndex(_teamOscuroPositionIndices, teamOscuroSize);
        _teamOscuroPositionIndices[availableIndex] = playerId;
        
        // Asignar posición predeterminada
        _teamOscuroPositions[playerId] = _getDefaultPositions(
          teamOscuroSize,
          availableIndex,
          false
        );
      }
    }
  }
  
  // Encuentra el índice de posición más cercano a una posición dada
  int _findClosestPositionIndex(Offset position, List<List<double>> formationPositions, bool isTeamClaro) {
    double minDistance = double.infinity;
    int closestIndex = 0;
    
    for (int i = 0; i < formationPositions.length; i++) {
      double posY = isTeamClaro 
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
    return 0;  // Fallback to position 0 if all taken
  }

  // Obtener el tamaño del equipo basado en el formato
  int _getTeamSize(bool isTeamClaro) {
    if (widget.formato.isEmpty) return 0;
    
    final parts = widget.formato.split('v');
    if (parts.length != 2) return 0;
    
    return int.tryParse(isTeamClaro ? parts[0] : parts[1]) ?? 0;
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

  // Función para seleccionar un jugador para una posición específica
  void _selectPlayerForPosition(bool isTeamClaro, int positionIndex) {
    if (!widget.interactive) return;
    
    // Controlador para el campo de búsqueda
    final TextEditingController searchController = TextEditingController();
    // Lista filtrada de jugadores
    List<Map<String, dynamic>> filteredPlayers = [];
    
    // Verificar si la posición ya está ocupada por un jugador
    String? currentPlayerId;
    if (isTeamClaro && _teamClaroPositionIndices.containsKey(positionIndex)) {
      currentPlayerId = _teamClaroPositionIndices[positionIndex];
    } else if (!isTeamClaro && _teamOscuroPositionIndices.containsKey(positionIndex)) {
      currentPlayerId = _teamOscuroPositionIndices[positionIndex];
    }
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        // Inicializar la lista filtrada con todos los jugadores disponibles
        // y también incluir el jugador actual de esta posición (si existe)
        filteredPlayers = widget.allPlayers.where((player) {
          final playerId = player['id'].toString();
          return !widget.teamClaro.contains(playerId) && 
                 !widget.teamOscuro.contains(playerId) ||
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
                      'Seleccionar jugador para ${isTeamClaro ? "Equipo Claro" : "Equipo Oscuro"}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isTeamClaro ? Colors.blue.shade800 : Colors.red.shade800,
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
                              filteredPlayers = widget.allPlayers.where((player) {
                                final playerId = player['id'].toString();
                                return !widget.teamClaro.contains(playerId) && 
                                      !widget.teamOscuro.contains(playerId) ||
                                      playerId == currentPlayerId;
                              }).toList();
                            } else {
                              // Filtrar por nombre
                              filteredPlayers = widget.allPlayers.where((player) {
                                final playerId = player['id'].toString();
                                final nombre = player['nombre'].toString().toLowerCase();
                                return (!widget.teamClaro.contains(playerId) && 
                                       !widget.teamOscuro.contains(playerId) ||
                                       playerId == currentPlayerId) && 
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
                                      backgroundColor: isTeamClaro ? Colors.blue : Colors.red,
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
                                      final playerId = player['id'].toString();
                                      
                                      // Notificar a la clase padre del cambio
                                      if (widget.onPlayerChanged != null) {
                                        widget.onPlayerChanged!(playerId, positionIndex, isTeamClaro);
                                      }
                                      
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
  Offset _getDefaultPositions(int totalPlayers, int index, bool isTeamClaro) {
    List<List<double>> positions = _getFormationPositions(totalPlayers);
    if (index < positions.length) {
      return Offset(positions[index][0], isTeamClaro ? positions[index][1] : 1.0 - positions[index][1]);
    }
    return Offset(0.5, isTeamClaro ? 0.3 : 0.7); // Posición por defecto
  }

  // Función para eliminar un jugador de un equipo
  void _removePlayerFromTeam(String playerId, bool isTeamClaro) {
    if (!widget.interactive) return;
    
    // Notificar a la clase padre
    if (widget.onPlayerRemoved != null) {
      widget.onPlayerRemoved!(playerId, isTeamClaro);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // TabBar de equipos
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
                      if (widget.formato.isNotEmpty) SizedBox(width: 4),
                      if (widget.formato.isNotEmpty)
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: widget.teamClaro.length == _getTeamSize(true) 
                                ? Colors.green.withOpacity(0.7)
                                : Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            "${widget.teamClaro.length}/${_getTeamSize(true)}",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
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
                      if (widget.formato.isNotEmpty) SizedBox(width: 4),
                      if (widget.formato.isNotEmpty)
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: widget.teamOscuro.length == _getTeamSize(false) 
                                ? Colors.green.withOpacity(0.7)
                                : Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            "${widget.teamOscuro.length}/${_getTeamSize(false)}",
                            style: TextStyle(
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
        
        // Contenido de las pestañas
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
  
  Widget _buildFootballField(bool isTeamClaro) {
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
                    // Efecto de textura de césped (si tienes la imagen)
                    image: const DecorationImage(
                      image: AssetImage('assets/grass_texture.png'),
                      fit: BoxFit.cover,
                      opacity: 0.2, // Sutil, no distraer demasiado
                    ),
                  ),
                  clipBehavior: Clip.antiAlias, // Para que el hijo no sobresalga del borde redondeado
                  child: Stack(
                    children: [
                      // Campo de fútbol mejorado
                      _buildFootballFieldElements(fieldWidth, fieldHeight, isTeamClaro),
                      
                      // Añadir reflejo/brillo para dar efecto profesional
                      Positioned.fill(
                        child: CustomPaint(
                          painter: GlassPainter(),
                        ),
                      ),
                      
                      // Posiciones vacías para el equipo seleccionado (solo si hay formato)
                      if (widget.formato.isNotEmpty)
                        ..._buildEmptyPositions(
                          _getTeamSize(isTeamClaro),
                          isTeamClaro,
                          fieldWidth,
                          fieldHeight,
                        ),
                        
                      // Jugadores del equipo seleccionado
                      if (isTeamClaro && widget.teamClaro.isNotEmpty)
                        ..._buildTeamPlayers(widget.teamClaro, _teamClaroPositions, true, fieldWidth, fieldHeight),
                      
                      if (!isTeamClaro && widget.teamOscuro.isNotEmpty)
                        ..._buildTeamPlayers(widget.teamOscuro, _teamOscuroPositions, false, fieldWidth, fieldHeight),
                      
                      // Indicador cuando no hay formato seleccionado
                      if (widget.formato.isEmpty)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                "Selecciona un formato de partido",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      
                      // Botón de ayuda integrado en la esquina del campo
                      if (widget.interactive)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _showInstructionsToast,
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.3),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.help_outline,
                                  color: Colors.white,
                                  size: 20,
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

  Widget _buildFootballFieldElements(double width, double height, bool isTeamClaro) {
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
                colors: isTeamClaro 
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
                    isTeamClaro ? "Equipo Claro" : "Equipo Oscuro",
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

  List<Widget> _buildEmptyPositions(int count, bool isTeamClaro, double fieldWidth, double fieldHeight) {
    List<Widget> positions = [];
    List<List<double>> formationPositions = _getFormationPositions(count);
    
    for (int i = 0; i < count; i++) {
      if (_isPositionOccupied(i, isTeamClaro)) continue;
      
      double posX = formationPositions[i][0] * fieldWidth;
      double posY = isTeamClaro 
          ? formationPositions[i][1] * fieldHeight
          : (1 - formationPositions[i][1]) * fieldHeight;
      
      positions.add(
        Positioned(
          left: posX - 25,
          top: posY - 25,
          child: GestureDetector(
            onTap: () => _selectPlayerForPosition(isTeamClaro, i),
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isTeamClaro 
                      ? [Colors.blue.withOpacity(0.2), Colors.blue.withOpacity(0.4)] 
                      : [Colors.red.withOpacity(0.2), Colors.red.withOpacity(0.4)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isTeamClaro ? Colors.blue.shade300 : Colors.red.shade300,
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

  bool _isPositionOccupied(int index, bool isTeamClaro) {
    if (isTeamClaro) {
      return _teamClaroPositionIndices.containsKey(index);
    } else {
      return _teamOscuroPositionIndices.containsKey(index);
    }
  }

  List<Widget> _buildTeamPlayers(
      List<String> team, 
      Map<String, Offset> positions, 
      bool isTeamClaro, 
      double fieldWidth, 
      double fieldHeight) {
    List<Widget> playerWidgets = [];
    
    for (int i = 0; i < team.length; i++) {
      final playerId = team[i];
      
      // Buscar el jugador en la lista de todos los jugadores
      final player = widget.allPlayers.firstWhere(
        (p) => p['id'].toString() == playerId,
        orElse: () => {'nombre': isTeamClaro ? 'A${i + 1}' : 'B${i + 1}', 'foto_perfil': null},
      );
      
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
      
      // Obtener la posición actual o una predeterminada
      final Offset position = positions[playerId] ?? 
          _getDefaultPositions(
            _getTeamSize(isTeamClaro),
            i,
            isTeamClaro
          );
      
      // Convertir la posición relativa (0-1) a coordenadas reales
      final double posX = position.dx * fieldWidth;
      final double posY = position.dy * fieldHeight;
      
      // Crear widget del jugador
      playerWidgets.add(
        AnimatedPositioned(
          duration: Duration(milliseconds: 200),
          curve: Curves.easeOutQuad,
          left: posX - 30,
          top: _elevatedPlayers[playerId] == true 
              ? posY - 45 // Posición elevada (15px más arriba)
              : posY - 30, // Posición normal
          child: GestureDetector(
            onLongPress: widget.interactive ? () {
              setState(() {
                _draggingPlayerId = playerId;
                _isDraggingTeamClaro = isTeamClaro;
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
            } : null,
            onLongPressMoveUpdate: widget.interactive ? (details) {
              if (_draggingPlayerId == playerId) {
                setState(() {
                  // Mantener el efecto de elevación mientras arrastra
                  _elevatedPlayers[playerId] = true;
                  
                  // Calcular nueva posición relativa
                  final RenderBox renderBox = _fieldKey.currentContext!.findRenderObject() as RenderBox;
                  final Offset localPosition = renderBox.globalToLocal(details.globalPosition);

                  double dx = localPosition.dx / renderBox.size.width;
                  double dy = localPosition.dy / renderBox.size.height;

                  // Limitar posiciones para que no salgan del campo
                  dx = dx.clamp(0.05, 0.95);
                  dy = dy.clamp(0.05, 0.95);
                  
                  // Actualizar en el mapa local
                  if (isTeamClaro) {
                    _teamClaroPositions[playerId] = Offset(dx, dy);
                  } else {
                    _teamOscuroPositions[playerId] = Offset(dx, dy);
                  }
                  
                  // Notificar a la clase padre
                  if (widget.onPositionUpdated != null) {
                    widget.onPositionUpdated!(playerId, Offset(dx, dy), isTeamClaro);
                  }
                });
              }
            } : null,
            onLongPressEnd: widget.interactive ? (_) {
              setState(() {
                // Quitar efecto de elevación al soltar
                _elevatedPlayers[playerId] = false;
                _draggingPlayerId = null;
              });
            } : null,
            child: _buildPlayerAvatar(player, isTeamClaro, average, playerId),
          ),
        ),
      );
      
      // Añadir nombre del jugador debajo
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
                color: isTeamClaro 
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
              player['nombre'] ?? (isTeamClaro ? 'A${i + 1}' : 'B${i + 1}'),
              style: TextStyle(
                color: isTeamClaro ? Colors.blue.shade200 : Colors.red.shade200,
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
  
  Widget _buildPlayerAvatar(Map<String, dynamic> player, bool isTeamClaro, double average, String playerId) {
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
              colors: isTeamClaro 
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
                color: (isTeamClaro ? Colors.blue : Colors.red).withOpacity(0.3),
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
        if (widget.interactive)
          GestureDetector(
            onTap: () => _removePlayerFromTeam(playerId, isTeamClaro),
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
  bool shouldRepaint(covariant GlassPainter oldDelegate) => false;
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
  bool shouldRepaint(covariant AvatarGlowPainter oldDelegate) => false;
}