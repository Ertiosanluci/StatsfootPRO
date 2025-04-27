import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PlayerListScreen extends StatefulWidget {
  @override
  _PlayerListScreenState createState() => _PlayerListScreenState();
}

class _PlayerListScreenState extends State<PlayerListScreen> {
  List<Map<String, dynamic>> _players = []; // Lista de jugadores
  List<Map<String, dynamic>> _playersFiltrados = []; // Lista de jugadores filtrados
  bool _isLoading = true; // Indicador de carga
  TextEditingController _searchController = TextEditingController(); // Controlador para el campo de búsqueda

  @override
  void initState() {
    super.initState();
    _fetchPlayers(); // Obtener los jugadores al iniciar la pantalla
  }

  // Método para obtener los jugadores desde Supabase
    // Método para obtener los jugadores desde Supabase
  Future<void> _fetchPlayers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;

      if (user != null) {
        // Consultar solo los jugadores del usuario actual
        final response = await Supabase.instance.client
            .from('jugadores')
            .select()
            .eq('user_id', user.id); // Filtrar por el ID del usuario actual

        if (mounted) {
          setState(() {
            _players = List<Map<String, dynamic>>.from(response);
            _playersFiltrados = _players;
            _isLoading = false;
          });
        }
      } else {
        // El usuario no ha iniciado sesión
        if (mounted) {
          setState(() {
            _players = [];
            _playersFiltrados = [];
            _isLoading = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('No se ha iniciado sesión'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Error al cargar jugadores: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar jugadores: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  // Método para filtrar jugadores según el texto de búsqueda
  void _filterPlayers(String query) {
    setState(() {
      _playersFiltrados = _players
          .where((player) =>
          player['nombre'].toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "Mis Jugadores",
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.blue.shade900.withOpacity(0.9),
                Colors.blue.shade700.withOpacity(0.85),
              ],
            ),
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.pushNamed(context, '/create_player').then((_) {
                _fetchPlayers(); // Actualizar lista al regresar
              });
            },
            icon: Icon(Icons.person_add, color: Colors.white),
            tooltip: "Añadir jugador",
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF1A237E), // Azul índigo oscuro
              Color(0xFF303F9F), // Azul índigo
              Color(0xFF3949AB), // Azul índigo claro
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Buscador mejorado
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Buscar jugador...',
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                      prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.8)),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 14),
                    ),
                    onChanged: _filterPlayers,
                  ),
                ),
              ),

              // Información y filtros
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Text(
                      "${_playersFiltrados.length} jugadores",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                  ],
                ),
              ),

              // Lista de jugadores
              Expanded(
                child: _isLoading
                    ? Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                    : _playersFiltrados.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                  physics: BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(16.0),
                  itemCount: _playersFiltrados.length,
                  itemBuilder: (context, index) {
                    final player = _playersFiltrados[index];

                    // Animación de entrada para cada tarjeta
                    return AnimatedContainer(
                      duration: Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                      margin: EdgeInsets.only(bottom: 16.0),
                      child: _buildPlayerCard(context, player),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

// Widget para dropdown de ordenamiento


// Widget para el botón flotante
  Widget _buildFloatingActionButton() {
    return Container(
      margin: EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Botón de actualización
          FloatingActionButton(
            onPressed: _fetchPlayers,
            heroTag: 'refresh',
            backgroundColor: Colors.blue.shade600,
            child: Icon(Icons.refresh, color: Colors.white),
            tooltip: "Actualizar lista",
          ),
          SizedBox(width: 16),
          // Botón principal para añadir
          FloatingActionButton.extended(
            onPressed: () {
              Navigator.pushNamed(context, '/create_player').then((_) {
                _fetchPlayers();
              });
            },
            heroTag: 'add',
            backgroundColor: Colors.orange.shade600,
            icon: Icon(Icons.person_add, color: Colors.white),
            label: Text(
              "Añadir Jugador",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            elevation: 8,
          ),
        ],
      ),
    );
  }

// Widget para mostrar estado vacío
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.people_alt_outlined,
              size: 70,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          SizedBox(height: 20),
          Text(
            'No tienes jugadores registrados',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Añade jugadores a tu equipo para empezar a registrar sus estadísticas',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

// Tarjeta de jugador mejorada
  Widget _buildPlayerCard(BuildContext context, Map<String, dynamic> player) {
    // Determinar colores según posición
    Color positionColor;
    switch (player['posicion']) {
      case 'Delantero':
        positionColor = Colors.red.shade400;
        break;
      case 'Mediocampista':
        positionColor = Colors.green.shade400;
        break;
      case 'Defensa':
        positionColor = Colors.blue.shade400;
        break;
      case 'Portero':
        positionColor = Colors.orange.shade400;
        break;
      default:
        positionColor = Colors.grey;
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        borderRadius: BorderRadius.circular(15),
        color: Colors.white.withOpacity(0.08),
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PlayerStatsScreen(player: player),
              ),
            ).then((_) {
              _fetchPlayers(); // Actualizar al volver
            });
          },
          splashColor: positionColor.withOpacity(0.1),
          highlightColor: positionColor.withOpacity(0.05),
          child: Container(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                // Media del jugador
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        _getMediaColor(player['media'] ?? 0),
                        _getMediaColor(player['media'] ?? 0).withOpacity(0.7),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _getMediaColor(player['media'] ?? 0).withOpacity(0.3),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ],
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '${player['media'] ?? 0}',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16),

                // Foto y nombre
                Expanded(
                  child: Row(
                    children: [
                      // Foto de perfil
                      Hero(
                        tag: 'player_${player['id']}',
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: positionColor.withOpacity(0.3), width: 2),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(25),
                            child: player['foto_perfil'] != null
                                ? Image.network(
                              player['foto_perfil'],
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Icon(Icons.person, color: Colors.white70, size: 30),
                            )
                                : Icon(Icons.person, color: Colors.white70, size: 30),
                          ),
                        ),
                      ),
                      SizedBox(width: 16),

                      // Nombre y posición
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              player['nombre'] ?? 'Sin nombre',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 4),
                            Row(
                              children: [
                                // Posición
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: positionColor.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: positionColor.withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    _getShortPosition(player['posicion'] ?? ''),
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 10),
                                // Calificación
                                Row(
                                  children: [
                                    Icon(
                                      Icons.star,
                                      size: 14,
                                      color: Colors.amber.shade400,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      '${player['calificacion'] ?? 0}',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Flecha y menú
                Column(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.more_vert,
                        color: Colors.white70,
                        size: 20,
                      ),
                      onPressed: () => _showPlayerOptions(context, player),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: Colors.white38,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

// Función para mostrar opciones del jugador
  void _showPlayerOptions(BuildContext context, Map<String, dynamic> player) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.indigo.shade900,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: Icon(Icons.edit, color: Colors.white),
              title: Text('Editar jugador', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PlayerEditScreen(player: player),
                  ),
                ).then((_) => _fetchPlayers());
              },
            ),
            ListTile(
              leading: Icon(Icons.bar_chart, color: Colors.white),
              title: Text('Ver estadísticas', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PlayerStatsScreen(player: player),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: Colors.red.shade300),
              title: Text('Eliminar', style: TextStyle(color: Colors.red.shade300)),
              onTap: () {
                Navigator.pop(context);
                _confirmDeletePlayer(context, player);
              },
            ),
          ],
        ),
      ),
    );
  }

// Confirmar eliminación del jugador
  Future<void> _confirmDeletePlayer(BuildContext context, Map<String, dynamic> player) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.indigo.shade900,
        title: Text('Eliminar Jugador', style: TextStyle(color: Colors.white)),
        content: Text(
          '¿Estás seguro que deseas eliminar a ${player['nombre']}? Esta acción no se puede deshacer.',
          style: TextStyle(color: Colors.white.withOpacity(0.8)),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await Supabase.instance.client
                    .from('jugadores')
                    .delete()
                    .eq('id', player['id']);

                _fetchPlayers();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${player['nombre']} eliminado correctamente'),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error al eliminar el jugador: ${e.toString()}'),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: Text('Eliminar'),
          ),
        ],
      ),
    );
  }

// Obtener color según la media del jugador
  Color _getMediaColor(int media) {
    if (media >= 85) return Colors.green.shade700;
    if (media >= 75) return Colors.green.shade500;
    if (media >= 65) return Colors.lime.shade600;
    if (media >= 55) return Colors.orange.shade500;
    if (media >= 45) return Colors.orange.shade700;
    if (media >= 35) return Colors.deepOrange;
    return Colors.red;
  }

// Acortar nombre de posición
  String _getShortPosition(String position) {
    switch (position) {
      case 'Delantero': return 'DEL';
      case 'Mediocampista': return 'MED';
      case 'Defensa': return 'DEF';
      case 'Portero': return 'POR';
      default: return position;
    }
  }
}

class PlayerStatsScreen extends StatelessWidget {
  final Map<String, dynamic> player;

  const PlayerStatsScreen({super.key, required this.player});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue.shade900,
        elevation: 0,
        title: Text(
          "Estadísticas",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        height: MediaQuery.of(context).size.height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.blue.shade900,
              Colors.blue.shade800,
              Colors.indigo.shade800,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Cabecera del jugador
              _buildPlayerHeader(),

              SizedBox(height: 24),

              // Tarjeta de estadísticas
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                color: Colors.white.withOpacity(0.1),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        "Estadísticas",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Divider(
                        color: Colors.white.withOpacity(0.3),
                        height: 24,
                      ),

                      // Estadísticas en dos columnas
                      Row(
                        children: [
                          // Primera columna
                          Expanded(
                            child: Column(
                              children: [
                                _buildStatRow('Tiro', player['tiro'] ?? 0),
                                SizedBox(height: 12),
                                _buildStatRow('Regate', player['regate'] ?? 0),
                                SizedBox(height: 12),
                                _buildStatRow('Técnica', player['tecnica'] ?? 0),
                                SizedBox(height: 12),
                                _buildStatRow('Defensa', player['defensa'] ?? 0),
                              ],
                            ),
                          ),

                          SizedBox(width: 16),

                          // Segunda columna
                          Expanded(
                            child: Column(
                              children: [
                                _buildStatRow('Velocidad', player['velocidad'] ?? 0),
                                SizedBox(height: 12),
                                _buildStatRow('Aguante', player['aguante'] ?? 0),
                                SizedBox(height: 12),
                                _buildStatRow('Control', player['control'] ?? 0),
                              ],
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 16),

                      // Media global
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _getMediaColor(player['media'] ?? 0).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Media global:",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(width: 8),
                            Text(
                              "${player['media'] ?? 0}",
                              style: TextStyle(
                                color: _getMediaColor(player['media'] ?? 0),
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 16),

              // Botones de acción
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PlayerEditScreen(player: player),
                          ),
                        );
                      },
                      icon: Icon(Icons.edit),
                      label: Text("Editar Jugador"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade600,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Cabecera con foto y datos principales
  Widget _buildPlayerHeader() {
    return Column(
      children: [
        // Foto del jugador con círculo de media superpuesto
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            // Foto
            CircleAvatar(
              radius: 60,
              backgroundColor: Colors.white.withOpacity(0.2),
              backgroundImage: player['foto_perfil'] != null
                  ? NetworkImage(player['foto_perfil'])
                  : null,
              child: player['foto_perfil'] == null
                  ? Icon(Icons.person, color: Colors.white, size: 60)
                  : null,
            ),

            // Círculo de media
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _getMediaColor(player['media'] ?? 0),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Center(
                child: Text(
                  '${player['media'] ?? 0}',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),

        SizedBox(height: 16),

        // Nombre del jugador
        Text(
          player['nombre'] ?? 'Sin nombre',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),

        SizedBox(height: 4),

        // Posición y calificación
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: _getPositionColor(player['posicion']).withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _getPositionColor(player['posicion']).withOpacity(0.4),
                  width: 1,
                ),
              ),
              child: Text(
                player['posicion'] ?? 'Jugador',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            SizedBox(width: 12),

            // Estrellas de calificación
            Row(
              children: [
                Icon(Icons.star, color: Colors.amber, size: 20),
                SizedBox(width: 4),
                Text(
                  "${player['calificacion'] ?? 0}",
                  style: TextStyle(
                    color: Colors.amber,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  // Fila de estadística con barra de progreso
  Widget _buildStatRow(String statName, int value) {
    final Color statColor = _getStatColor(value);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              statName,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
            Text(
              "$value",
              style: TextStyle(
                color: statColor,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
        SizedBox(height: 6),
        LinearProgressIndicator(
          value: value / 100,
          backgroundColor: Colors.white.withOpacity(0.1),
          valueColor: AlwaysStoppedAnimation<Color>(statColor),
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  // Color según la posición
  Color _getPositionColor(String? position) {
    switch (position) {
      case 'Delantero': return Colors.red.shade400;
      case 'Mediocampista': return Colors.green.shade400;
      case 'Defensa': return Colors.blue.shade400;
      case 'Portero': return Colors.orange.shade400;
      default: return Colors.purple.shade400;
    }
  }

  // Color según la media
  Color _getMediaColor(int media) {
    if (media >= 85) return Colors.green.shade600;
    if (media >= 75) return Colors.lightGreen.shade600;
    if (media >= 65) return Colors.yellow.shade700;
    if (media >= 55) return Colors.orange.shade500;
    if (media >= 45) return Colors.deepOrange.shade500;
    return Colors.red.shade500;
  }

  // Color según el valor de la estadística
  Color _getStatColor(int value) {
    if (value >= 85) return Colors.green.shade400;
    if (value >= 75) return Colors.lightGreen.shade500;
    if (value >= 65) return Colors.amber.shade500;
    if (value >= 55) return Colors.orange.shade400;
    if (value >= 45) return Colors.deepOrange.shade400;
    return Colors.red.shade400;
  }
}
class PlayerEditScreen extends StatefulWidget {
  final Map<String, dynamic> player; // Jugador que se va a editar
  final Function(Map<String, dynamic>)? onSave; // Función para guardar cambios

  PlayerEditScreen({required this.player, this.onSave});

  @override
  _PlayerEditScreenState createState() => _PlayerEditScreenState();
}

class _PlayerEditScreenState extends State<PlayerEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String antiguonombre = '';
  int _rating = 5; // Calificación inicial
  int _media = 50;
  final Map<String, double> _stats = {
    'Tiro': 50,
    'Regate': 50,
    'Técnica': 50,
    'Defensa': 50,
    'Velocidad': 50,
    'Aguante': 50,
    'Control': 50,
  };
  String _position = 'Delantero'; // Posición inicial
  File? _profilePhoto; // Archivo de la foto de perfil
  String? _currentPhotoUrl; // URL de la foto actual

  void _calcularMedia() {
    double calcularMedia = 0;
    _stats.forEach((key, value) {
      calcularMedia += value;
    });
    setState(() {
      _media = (calcularMedia / _stats.length).round(); // Redondea la media al entero más cercano
    });
  }

  @override
  void initState() {
    super.initState();
    // Inicializa los valores con los datos del jugador existente
    _nameController.text = widget.player['nombre'];
    antiguonombre = _nameController.text;
    _rating = widget.player['calificacion'] ?? 5;
    _position = widget.player['posicion'] ?? 'Delantero';
    _currentPhotoUrl = widget.player['foto_perfil'];

    // Inicializa las estadísticas
    _stats['Tiro'] = widget.player['tiro']?.toDouble() ?? 50;
    _stats['Regate'] = widget.player['regate']?.toDouble() ?? 50;
    _stats['Técnica'] = widget.player['tecnica']?.toDouble() ?? 50;
    _stats['Defensa'] = widget.player['defensa']?.toDouble() ?? 50;
    _stats['Velocidad'] = widget.player['velocidad']?.toDouble() ?? 50;
    _stats['Aguante'] = widget.player['aguante']?.toDouble() ?? 50;
    _stats['Control'] = widget.player['control']?.toDouble() ?? 50;

    _calcularMedia();
  }

  Future<void> _deletePlayer(String nombre) async {
    try {
      await Supabase.instance.client
          .from('jugadores')
          .delete()
          .eq('nombre', nombre); // Eliminar el jugador por su ID

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Jugador eliminado exitosamente')),
      );

      Navigator.pop(context); // Volver a la pantalla anterior
    } catch (e) {
      print('Error al eliminar el jugador: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al eliminar el jugador: $e')),
      );
    }
  }

  // Método para seleccionar una foto de perfil
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _profilePhoto = File(pickedFile.path);
      });
    }
  }

  // Método para subir la foto a Supabase Storage
  Future<String?> _uploadPhoto(File photo, String playername) async {
    final String? user = Supabase.instance.client.auth.currentUser?.id;
    try {
      final fileName = '$user/$antiguonombre.jpg';
      final fileNamenuevo = '$user/$playername.jpg';

      // Borrar archivo antes de subir
      try {
        await Supabase.instance.client.storage
            .from('images')
            .remove(['$fileName']); // Elimina el archivo antiguo
      } catch (e) {
        print("No se pudo eliminar el archivo antiguo: $e");
        Fluttertoast.showToast(msg: 'No se pudo eliminar la antigua foto');
        // Si no existe el archivo, no hay problema
      }
      // Subir archivo nuevo
      await Supabase.instance.client.storage
          .from('images')
          .upload(fileNamenuevo, photo);

      // Obtener la URL pública de la foto subida
      final publicUrl = Supabase.instance.client.storage
          .from('images/')
          .getPublicUrl(fileNamenuevo);
      return publicUrl;
    } catch (e) {
      print('Error al subir la foto: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al subir la foto: $e')),
      );
      return null;
    }
  }

  // Método para actualizar el jugador en Supabase
  Future<void> _updatePlayer() async {
    if (_formKey.currentState!.validate()) {
      String? photoUrl = _currentPhotoUrl;
      if (_profilePhoto != null) {
        photoUrl = await _uploadPhoto(_profilePhoto!, _nameController.text);
      }

      final playerData = {
        'nombre': _nameController.text,
        'calificacion': _rating,
        'tiro': _stats['Tiro']!.round(),
        'regate': _stats['Regate']!.round(),
        'tecnica': _stats['Técnica']!.round(),
        'defensa': _stats['Defensa']!.round(),
        'velocidad': _stats['Velocidad']!.round(),
        'aguante': _stats['Aguante']!.round(),
        'control': _stats['Control']!.round(),
        'media': _media,
        'posicion': _position,
        'foto_perfil': photoUrl,
      };

      try {
        await Supabase.instance.client
            .from('jugadores')
            .update(playerData)
            .eq('id', widget.player['id']); // Actualiza el jugador por su ID

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Jugador actualizado exitosamente')),
        );

        if (widget.onSave != null) {
          widget.onSave!(playerData); // Llama a la función onSave con los cambios
        }
        Navigator.pop(context); // Regresa a la pantalla anterior
      } catch (e) {
        print('Error al actualizar el jugador: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al actualizar el jugador: $e')),
        );
      }
    }
  }

  @override
  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Editar Jugador",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: Colors.blue.shade900,
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _updatePlayer,
            icon: Icon(Icons.save_outlined,
              color: Colors.white,),
            tooltip: "Guardar cambios",
            color: Colors.white,

          ),
        ],
      ),
      body: Container(
        height: screenSize.height,
        width: screenSize.width,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.blue.shade900,
              Colors.indigo.shade800,
              Colors.indigo.shade900,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Foto y nombre del jugador
                  _buildPlayerHeader(),

                  SizedBox(height: 24),

                  // Sección de calificación y posición
                  _buildRatingAndPositionSection(),

                  SizedBox(height: 24),

                  // Sección de estadísticas
                  _buildStatsSection(),

                  SizedBox(height: 24),

                  // Botones de acción
                  _buildActionButtons(),

                  SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

// Sección de foto y nombre del jugador
  Widget _buildPlayerHeader() {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: Colors.white.withOpacity(0.08),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Foto del jugador
            GestureDetector(
              onTap: _pickImage,
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.5),
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 15,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      backgroundImage: _getProfileImage(),
                      child: _showDefaultIcon()
                          ? Icon(Icons.person, size: 50, color: Colors.white.withOpacity(0.7))
                          : null,
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade600,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 24),

            // Nombre del jugador
            TextFormField(
              controller: _nameController,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                labelText: 'Nombre del Jugador',
                labelStyle: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue.shade400),
                  borderRadius: BorderRadius.circular(12),
                ),
                errorBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.red.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.red.shade400),
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 16,
                ),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor, ingresa un nombre';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

// Sección de calificación y posición
  Widget _buildRatingAndPositionSection() {
    return Row(
      children: [
        // Calificación
        Expanded(
          flex: 3,
          child: Card(
            elevation: 6,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            color: Colors.white.withOpacity(0.08),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    'Calificación',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '$_rating',
                    style: TextStyle(
                      color: _getRatingColor(_rating),
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  SliderTheme(
                    data: SliderThemeData(
                      activeTrackColor: _getRatingColor(_rating),
                      inactiveTrackColor: Colors.white.withOpacity(0.1),
                      thumbColor: _getRatingColor(_rating),
                      overlayColor: _getRatingColor(_rating).withOpacity(0.2),
                      thumbShape: RoundSliderThumbShape(enabledThumbRadius: 10),
                      trackHeight: 4,
                    ),
                    child: Slider(
                      value: _rating.toDouble(),
                      min: 1,
                      max: 10,
                      divisions: 9,
                      label: _rating.toString(),
                      onChanged: (value) {
                        setState(() {
                          _rating = value.round();
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        SizedBox(width: 12),

        // Posición
        Expanded(
          flex: 2,
          child: Card(
            elevation: 6,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            color: Colors.white.withOpacity(0.08),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    'Posición',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 12),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getPositionColor(_position).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _getPositionColor(_position).withOpacity(0.4),
                        width: 1,
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _position,
                        icon: Icon(Icons.arrow_drop_down, color: Colors.white70),
                        dropdownColor: Colors.indigo.shade900,
                        isExpanded: true,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _position = newValue;
                            });
                          }
                        },
                        items: ['Delantero', 'Mediocampista', 'Defensa', 'Portero']
                            .map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Center(child: Text(value)),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                  Icon(
                    _getPositionIcon(_position),
                    color: _getPositionColor(_position),
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

// Sección de estadísticas
  Widget _buildStatsSection() {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: Colors.white.withOpacity(0.08),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encabezado con media
            Row(
              children: [
                Text(
                  "Estadísticas",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getMediaColor(_media).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getMediaColor(_media).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Media:",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(width: 4),
                      Text(
                        "$_media",
                        style: TextStyle(
                          color: _getMediaColor(_media),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            Divider(
              color: Colors.white.withOpacity(0.2),
              height: 24,
            ),

            // Distribución de las estadísticas en dos columnas
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Primera columna de estadísticas
                Expanded(
                  child: Column(
                    children: [
                      _buildStatSlider('Tiro', _stats['Tiro']!),
                      SizedBox(height: 16),
                      _buildStatSlider('Regate', _stats['Regate']!),
                      SizedBox(height: 16),
                      _buildStatSlider('Técnica', _stats['Técnica']!),
                      SizedBox(height: 16),
                      _buildStatSlider('Defensa', _stats['Defensa']!),
                    ],
                  ),
                ),

                SizedBox(width: 16),

                // Segunda columna de estadísticas
                Expanded(
                  child: Column(
                    children: [
                      _buildStatSlider('Velocidad', _stats['Velocidad']!),
                      SizedBox(height: 16),
                      _buildStatSlider('Aguante', _stats['Aguante']!),
                      SizedBox(height: 16),
                      _buildStatSlider('Control', _stats['Control']!),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

// Botones de acción
  Widget _buildActionButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Botón para guardar cambios
        ElevatedButton(
          onPressed: _updatePlayer,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green.shade600,
            foregroundColor: Colors.white,
            elevation: 8,
            padding: EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.save_outlined,
                color: Colors.white,
              ),
              SizedBox(width: 8),
              Text(
                'Guardar Cambios',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: 16),

        // Botón para eliminar jugador
        ElevatedButton(
          onPressed: () => _confirmDeleteDialog(),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.shade700,
            foregroundColor: Colors.white,
            elevation: 8,
            padding: EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.delete_outline,
                color: Colors.white,),

              SizedBox(width: 8),
              Text(
                'Eliminar Jugador',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

// Control deslizante para cada estadística
  Widget _buildStatSlider(String statName, double statValue) {
    final Color statColor = _getStatColor(statValue.round());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              statName,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 14,
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: statColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                statValue.round().toString(),
                style: TextStyle(
                  color: statColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: statColor,
            inactiveTrackColor: Colors.white.withOpacity(0.1),
            thumbColor: Colors.white,
            overlayColor: statColor.withOpacity(0.2),
            thumbShape: RoundSliderThumbShape(enabledThumbRadius: 8),
            trackHeight: 4,
          ),
          child: Slider(
            value: statValue,
            min: 0,
            max: 100,
            onChanged: (value) {
              setState(() {
                _stats[statName] = value;
                _calcularMedia();
              });
            },
          ),
        ),
      ],
    );
  }

// Diálogo de confirmación para eliminar jugador
  void _confirmDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.indigo.shade900,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.red.shade300,
            ),
            SizedBox(width: 8),
            Text(
              'Eliminar Jugador',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          '¿Estás seguro de que deseas eliminar a ${_nameController.text}? Esta acción no se puede deshacer.',
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancelar',
              style: TextStyle(
                color: Colors.white70,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deletePlayer(antiguonombre);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Text('Eliminar'),
          ),
        ],
      ),
    );
  }

// Métodos auxiliares para obtener la imagen de perfil
  ImageProvider? _getProfileImage() {
    if (_profilePhoto != null) {
      return FileImage(_profilePhoto!);
    } else if (_currentPhotoUrl != null) {
      return NetworkImage(_currentPhotoUrl!);
    }
    return null;
  }

  bool _showDefaultIcon() {
    return _profilePhoto == null && _currentPhotoUrl == null;
  }

// Color para la calificación
  Color _getRatingColor(int rating) {
    if (rating >= 9) return Colors.green.shade400;
    if (rating >= 7) return Colors.lime.shade400;
    if (rating >= 5) return Colors.amber.shade400;
    if (rating >= 3) return Colors.orange.shade400;
    return Colors.red.shade400;
  }

// Color según la posición
  Color _getPositionColor(String position) {
    switch (position) {
      case 'Delantero': return Colors.red.shade400;
      case 'Mediocampista': return Colors.green.shade400;
      case 'Defensa': return Colors.blue.shade400;
      case 'Portero': return Colors.orange.shade400;
      default: return Colors.purple.shade400;
    }
  }

// Icono según la posición
  IconData _getPositionIcon(String position) {
    switch (position) {
      case 'Delantero': return Icons.sports_soccer;
      case 'Mediocampista': return Icons.sports_handball;
      case 'Defensa': return Icons.shield;
      case 'Portero': return Icons.pan_tool;
      default: return Icons.sports;
    }
  }

// Color según la media
  Color _getMediaColor(int media) {
    if (media >= 85) return Colors.green.shade500;
    if (media >= 75) return Colors.lightGreen.shade500;
    if (media >= 65) return Colors.amber.shade500;
    if (media >= 55) return Colors.orange.shade500;
    if (media >= 45) return Colors.deepOrange.shade500;
    return Colors.red.shade500;
  }

// Color según el valor de la estadística
  Color _getStatColor(int value) {
    if (value >= 85) return Colors.green.shade500;
    if (value >= 70) return Colors.lightGreen.shade500;
    if (value >= 55) return Colors.amber.shade500;
    if (value >= 40) return Colors.orange.shade500;
    return Colors.red.shade500;
  }

  // Método para construir una fila de estadística con slider
  Widget _buildStatRow(String statName, double statValue) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2), // Reducir el espaciado vertical
      child: Row(
        children: [
          // Nombre de la estadística
          Expanded(
            flex: 2,
            child: Text(
              _getShortStatName(statName),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ),
          // Slider para editar el valor
          Expanded(
            flex: 5,
            child: Slider(
              value: statValue,
              min: 0,
              max: 100,
              onChanged: (value) {
                setState(() {
                  _stats[statName] = value;
                  _calcularMedia(); // Recalcula la media al cambiar una estadística
                });
              },
              activeColor: Colors.orange.shade600,
              inactiveColor: Colors.white70,
              thumbColor: Colors.orange.shade600, // Color del círculo del slider
            ),
          ),
          // Valor numérico de la estadística
          Expanded(
            flex: 1,
            child: Text(
              '${statValue.round()}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Método para acortar el nombre de la posición
  String _getShortPosition(String position) {
    switch (position) {
      case 'Delantero':
        return 'DEL';
      case 'Mediocampista':
        return 'MED';
      case 'Defensa':
        return 'DEF';
      case 'Portero':
        return 'POR';
      default:
        return position;
    }
  }

  // Método para acortar el nombre de la estadística
  String _getShortStatName(String statName) {
    switch (statName) {
      case 'Tiro':
        return 'TIRO';
      case 'Regate':
        return 'REG';
      case 'Técnica':
        return 'TEC';
      case 'Defensa':
        return 'DEF';
      case 'Velocidad':
        return 'VEL';
      case 'Aguante':
        return 'AGU';
      case 'Control':
        return 'CTL';
      default:
        return statName;
    }
  }
}