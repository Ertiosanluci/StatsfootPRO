import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:statsfoota/widgets/invite_friends_dialog.dart';
import 'create_match.dart';
import 'match_details_screen.dart';
import 'team_management_screen.dart';
import 'utils/match_operations.dart';

class MatchListScreen extends StatefulWidget {
  @override
  _MatchListScreenState createState() => _MatchListScreenState();
}

class _MatchListScreenState extends State<MatchListScreen> with SingleTickerProviderStateMixin {
  // Controller para el campo de búsqueda
  final TextEditingController _searchController = TextEditingController();
  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _myMatches = []; // Partidos organizados por el usuario
  List<Map<String, dynamic>> _friendsMatches = []; // Partidos de amigos (privados)
  List<Map<String, dynamic>> _publicMatches = []; // Partidos públicos
  
  // Cache para los contadores de participantes
  final Map<int, int> _participantCountCache = {};
  
  // Listas filtradas por tiempo (próximos/pasados)
  List<Map<String, dynamic>> _filteredMyMatches = [];
  List<Map<String, dynamic>> _filteredFriendsMatches = [];
  List<Map<String, dynamic>> _filteredPublicMatches = [];
  
  // Variable para el filtro de tiempo
  String _timeFilter = 'Próximos'; // 'Próximos', 'Pasados', 'Todos'
  
  // Variables para la selección múltiple
  bool _isSelectionMode = false;
  Set<int> _selectedMatches = {}; // Conjunto de IDs de partidos seleccionados
  
  bool _isLoading = true;
  late TabController _tabController;
  String? _error;
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this); // 3 pestañas: Mis Partidos, Amigos, Públicos
    
    // Establecer el filtro por defecto para Mis Partidos como "Próximos"
    _timeFilter = 'Próximos';
    
    // Add listener to handle tab changes
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        print("Tab switched to: ${_tabController.index}");
        
        // Si cambiamos a la pestaña de Amigos o Públicos, asegurarse de que solo se muestren partidos futuros
        if (_tabController.index == 1 || _tabController.index == 2) {
          if (_timeFilter != 'Próximos') {
            setState(() {
              _timeFilter = 'Próximos';
              _applyTimeFilter();
            });
          }
        }
      }
    });
    
    _fetchMatches();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }
  
  // Método para aplicar el filtro de tiempo a las listas de partidos
  void _applyTimeFilter() {
    final now = DateTime.now();
    
    setState(() {      if (_timeFilter == 'Próximos') {
        // Filtrar solo partidos con fecha futura
        _filteredMyMatches = _myMatches.where((match) {
          final matchDate = DateTime.parse(match['fecha']);
          // Para Mis Partidos, filtrar solo por fecha futura
          return matchDate.isAfter(now);
        }).toList();
        
        _filteredFriendsMatches = _friendsMatches.where((match) {
          final matchDate = DateTime.parse(match['fecha']);
          return matchDate.isAfter(now);
        }).toList();
        
        _filteredPublicMatches = _publicMatches.where((match) {
          final matchDate = DateTime.parse(match['fecha']);
          return matchDate.isAfter(now);
        }).toList();
      } 
      else if (_timeFilter == 'Pasados') {
        // Filtrar solo partidos con fecha pasada
        _filteredMyMatches = _myMatches.where((match) {
          final matchDate = DateTime.parse(match['fecha']);
          return matchDate.isBefore(now);
        }).toList();
        
        // Para las tabs de Amigos y Públicos, no mostramos partidos pasados
        // independientemente del filtro seleccionado
        if (_tabController.index == 1 || _tabController.index == 2) {
          _filteredFriendsMatches = [];
          _filteredPublicMatches = [];
        } else {
          _filteredFriendsMatches = _friendsMatches.where((match) {
            final matchDate = DateTime.parse(match['fecha']);
            return matchDate.isBefore(now);
          }).toList();
          
          _filteredPublicMatches = _publicMatches.where((match) {
            final matchDate = DateTime.parse(match['fecha']);
            return matchDate.isBefore(now);
          }).toList();
        }
      } 
      else {
        // Mostrar todos los partidos para Mis Partidos
        _filteredMyMatches = List.from(_myMatches);
        
        // Para las tabs de Amigos y Públicos, solo mostramos partidos futuros
        if (_tabController.index == 1 || _tabController.index == 2) {
          _filteredFriendsMatches = _friendsMatches.where((match) {
            final matchDate = DateTime.parse(match['fecha']);
            return matchDate.isAfter(now);
          }).toList();
          
          _filteredPublicMatches = _publicMatches.where((match) {
            final matchDate = DateTime.parse(match['fecha']);
            return matchDate.isAfter(now);
          }).toList();
        } else {
          _filteredFriendsMatches = List.from(_friendsMatches);
          _filteredPublicMatches = List.from(_publicMatches);
        }
      }
    });
  }
  Future<void> _fetchMatches() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
        // Limpiar caché de contadores de participantes
        _participantCountCache.clear();
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
      final List<Map<String, dynamic>> userMatches = [];
      final List<Map<String, dynamic>> friendsMatchesList = [];
      final List<Map<String, dynamic>> publicMatchesList = [];

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
          
          userMatches.add(matchWithProfile);
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
              
              // Añadir a la lista de partidos del usuario
              userMatches.add(matchData);
            }
          }
        }
        
        // 3. Cargar partidos públicos (que no son del usuario actual)
        final publicMatchesResponse = await supabase
            .from('matches')
            .select('*')
            .eq('publico', true)
            .neq('creador_id', currentUser.id) // No incluir los partidos del usuario actual
            .order('fecha', ascending: false);

        for (final match in publicMatchesResponse) {
          final Map<String, dynamic> matchWithProfile = Map.from(match);
          
          try {
            final creatorData = await supabase
                .from('profiles')
                .select('*')
                .eq('id', match['creador_id'])
                .maybeSingle();
                
            if (creatorData != null) {
              matchWithProfile['profiles'] = creatorData;
            }
          } catch (e) {
            print('Error al cargar perfil del creador: $e');
          }
          
          matchWithProfile['isOrganizer'] = false;
          publicMatchesList.add(matchWithProfile);
        }
        
        // 4. Cargar lista de amigos del usuario
        final friendsResponseAsUser1 = await supabase
            .from('friends')
            .select('user_id_2')
            .eq('user_id_1', currentUser.id)
            .eq('status', 'accepted'); // Solo amigos aceptados cuando el usuario actual es user_id_1
        
        final friendsResponseAsUser2 = await supabase
            .from('friends')
            .select('user_id_1')
            .eq('user_id_2', currentUser.id)
            .eq('status', 'accepted'); // Solo amigos aceptados cuando el usuario actual es user_id_2
        
        List<String> friendIds = [];
        
        // Añadir IDs de amigos donde el usuario actual es user_id_1
        for (final friend in friendsResponseAsUser1) {
          friendIds.add(friend['user_id_2']);
        }
        
        // Añadir IDs de amigos donde el usuario actual es user_id_2
        for (final friend in friendsResponseAsUser2) {
          friendIds.add(friend['user_id_1']);
        }
        
        print('Amigos encontrados: ${friendIds.length}');

        // 5. Cargar partidos privados de amigos
        if (friendIds.isNotEmpty) {
          final friendsMatchesResponse = await supabase
              .from('matches')
              .select('*')
              .eq('publico', false) // Solo partidos privados
              .filter('creador_id', 'in', friendIds) // Creados por amigos - Método correcto
              .order('fecha', ascending: false);

          for (final match in friendsMatchesResponse) {
            final Map<String, dynamic> matchWithProfile = Map.from(match);
            
            try {
              final creatorData = await supabase
                  .from('profiles')
                  .select('*')
                  .eq('id', match['creador_id'])
                  .maybeSingle();
                  
              if (creatorData != null) {
                matchWithProfile['profiles'] = creatorData;
              }
            } catch (e) {
              print('Error al cargar perfil del creador: $e');
            }
            
            matchWithProfile['isOrganizer'] = false;
            friendsMatchesList.add(matchWithProfile);
          }
        }
        
        print('Total de partidos cargados - Usuario: ${userMatches.length}, Públicos: ${publicMatchesList.length}, Amigos: ${friendsMatchesList.length}');

        // Ordenar todos los partidos por fecha (más reciente primero)
        userMatches.sort((a, b) {
          DateTime dateA = DateTime.parse(a['fecha']);
          DateTime dateB = DateTime.parse(b['fecha']);
          return dateB.compareTo(dateA);
        });

        publicMatchesList.sort((a, b) {
          DateTime dateA = DateTime.parse(a['fecha']);
          DateTime dateB = DateTime.parse(b['fecha']);
          return dateB.compareTo(dateA);
        });

        friendsMatchesList.sort((a, b) {
          DateTime dateA = DateTime.parse(a['fecha']);
          DateTime dateB = DateTime.parse(b['fecha']);
          return dateB.compareTo(dateA);
        });

        setState(() {
          _myMatches = userMatches;
          _publicMatches = publicMatchesList;
          _friendsMatches = friendsMatchesList;
          _isLoading = false;
          
          // Aplicar el filtro de tiempo actual
          _applyTimeFilter();
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

  void _showInviteFriendsDialog(Map<String, dynamic> match) {
    showDialog(
      context: context,
      builder: (context) => InviteFriendsDialog(
        matchId: match['id'],
        matchName: match['nombre'] ?? 'Partido',
      ),
    );
  }

  void _shareMatchLink(Map<String, dynamic> match) async {
    try {      // Obtener información del partido
      final int matchId = match['id'];
      final DateTime matchDate = DateTime.parse(match['fecha']);
      final String formattedDate = DateFormat('EEEE, d MMM yyyy', 'es_ES').format(matchDate);
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
  
  // Método para eliminar múltiples partidos seleccionados
  Future<void> _deleteSelectedMatches() async {
    // Verificar que hay partidos seleccionados
    if (_selectedMatches.isEmpty) return;
    
    // Mostrar diálogo de confirmación
    bool confirmDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Eliminar partidos'),
          content: Text(
            'Estás a punto de eliminar ${_selectedMatches.length} partido${_selectedMatches.length > 1 ? "s" : ""}. '
            'Esta acción no se puede deshacer.'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    ) ?? false;

    if (!confirmDelete) {
      return;
    }

    // Mostrar diálogo de carga
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                CircularProgressIndicator(),
                SizedBox(height: 20),
                Text('Eliminando partidos...'),
              ],
            ),
          ),
        );
      },
    );

    try {
      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Debes iniciar sesión para eliminar partidos'),
          backgroundColor: Colors.red,
        ));
        return;
      }

      final List<int> matchIds = _selectedMatches.toList();
      for (final matchId in matchIds) {
        final match = _myMatches.firstWhere(
          (m) => m['id'] == matchId,
          orElse: () => <String, dynamic>{},
        );

        if (match.isEmpty) continue;
        
        // Solo permitir eliminar partidos que el usuario ha creado
        if (match['creador_id'] != currentUser.id) continue;

        // Eliminar estadísticas relacionadas con el partido
        await supabase.from('estadisticas').delete().eq('partido_id', matchId);
        
        // Eliminar participantes del partido
        await supabase.from('match_participants').delete().eq('match_id', matchId);
        
        // Eliminar el partido
        await supabase.from('matches').delete().eq('id', matchId);
      }

      // Cerrar diálogo y mostrar mensaje de éxito
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            matchIds.length > 1
                ? '${matchIds.length} partidos eliminados correctamente'
                : 'Partido eliminado correctamente'
          ),
          backgroundColor: Colors.green,
        ),
      );

      // Salir del modo de selección
      setState(() {
        _isSelectionMode = false;
        _selectedMatches.clear();
      });

      // Refrescar la lista de partidos
      _fetchMatches();
    } catch (e) {
      // Cerrar diálogo de carga
      Navigator.of(context).pop();

      // Mostrar mensaje de error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al eliminar los partidos: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _isSelectionMode
      ? AppBar(
          backgroundColor: Colors.red.shade700,
          title: Text('${_selectedMatches.length} seleccionados'),
          leading: IconButton(
            icon: Icon(Icons.close),
            onPressed: () {
              setState(() {
                _isSelectionMode = false;
                _selectedMatches.clear();
              });
            },
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.delete),
              onPressed: _selectedMatches.isNotEmpty ? _deleteSelectedMatches : null,
            ),
          ],
        )
      : AppBar(
          title: Text(
            'StatsFut',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.blue.shade800,
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: CircleAvatar(
                radius: 16,
                backgroundColor: Colors.white,
                child: Icon(
                  Icons.person,
                  color: Colors.blue.shade800,
                  size: 20,
                ),
              ),
              onPressed: () {
                // Acción para perfil de usuario
              },
            ),
          ],
          leading: IconButton(
            icon: Icon(Icons.notifications, color: Colors.white),
            onPressed: () {
              // Acción para notificaciones
            },
          ),
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(text: 'Mis Partidos'),
              Tab(text: 'Amigos'),
              Tab(text: 'Públicos'),
            ],
          ),
        ),
      body: SafeArea(
        child: Container(
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
                  : Column(
                      children: [
                        // Filtro de tiempo (Próximos/Pasados/Todos)
                        _buildTimeFilterRow(),
                        // Lista de partidos
                        Expanded(
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              // Tab 0: Mis Partidos (incluye organizados + unidos)
                              _buildMatchListView(_filteredMyMatches, isOrganizer: false, listType: "my"),
                              // Tab 1: Amigos
                              _buildMatchListView(_filteredFriendsMatches, isOrganizer: false, listType: "friends"),
                              // Tab 2: Públicos
                              _buildMatchListView(_filteredPublicMatches, isOrganizer: false, listType: "public"),
                            ],
                          ),
                        ),
                      ],
                    ),
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

  Widget _buildTimeFilterRow() {
  return Container(
    padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
    decoration: BoxDecoration(
      color: Colors.blue.shade900.withOpacity(0.5),
    ),
    child: Column(
      children: [
        // Search bar
        Container(
          margin: EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextField(
            style: TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Buscar partidos...',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
              prefixIcon: Icon(Icons.search, color: Colors.white),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 12),
            ),
            onChanged: (value) {
              // Implementar la búsqueda aquí
              // TODO: Filtrar partidos por nombre
            },
          ),
        ),
        // Filter row
        Row(
          children: [
            Icon(Icons.filter_list, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'Mostrar:',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _timeFilter,
                    isDense: true,
                    dropdownColor: Colors.blue.shade800,
                    icon: Icon(Icons.arrow_drop_down, color: Colors.white),
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _timeFilter = newValue;
                          _applyTimeFilter();
                        });
                      }
                    },
                    items: ['Próximos', 'Pasados', 'Todos']
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
            SizedBox(width: 12),
            // Date picker button
            InkWell(
              onTap: () async {
                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                  builder: (BuildContext context, Widget? child) {
                    return Theme(
                      data: ThemeData.light().copyWith(
                        primaryColor: Colors.blue.shade800,
                        colorScheme: ColorScheme.light(
                          primary: Colors.blue.shade800,
                          onPrimary: Colors.white,
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (picked != null) {
                  // Implementar filtro por fecha
                  // TODO: Filtrar partidos por fecha seleccionada
                }
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, color: Colors.white, size: 20),
                    SizedBox(width: 4),
                    Text(
                      'Fecha',
                      style: TextStyle(color: Colors.white),
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

  Widget _buildMatchListView(List<Map<String, dynamic>> matches, {required bool isOrganizer, required String listType}) {
    // Icons and messages based on the list type
    IconData emptyIcon;
    String emptyTitle;
    String emptySubtitle;
    
    switch (listType) {
      case "my":
        emptyIcon = Icons.sports_soccer;
        emptyTitle = 'Aún no tienes partidos';
        emptySubtitle = 'Toca el botón + para crear uno nuevo';
        break;
      case "friends":
        emptyIcon = Icons.group;
        emptyTitle = 'No hay partidos de amigos';
        emptySubtitle = 'Tus amigos aún no han creado partidos privados';
        break;
      case "public":
        emptyIcon = Icons.public;
        emptyTitle = 'No hay partidos públicos';
        emptySubtitle = 'No hay partidos públicos disponibles en este momento';
        break;
      default:
        emptyIcon = Icons.sports_soccer;
        emptyTitle = 'No hay partidos';
        emptySubtitle = 'No se encontraron partidos';
    }
    
    return RefreshIndicator(
      onRefresh: _fetchMatches,
      child: matches.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    emptyIcon,
                    color: Colors.white.withOpacity(0.8),
                    size: 80,
                  ),
                  SizedBox(height: 20),
                  Text(
                    emptyTitle,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 10),
                  Text(
                    emptySubtitle,
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
    final int matchId = match['id'];
    final bool isSelected = _selectedMatches.contains(matchId);
    final bool isPast = DateTime.parse(match['fecha']).isBefore(DateTime.now());
    final bool isPublic = match['es_publico'] ?? false;
    final String formattedDate = DateFormat('dd/MM/yyyy').format(DateTime.parse(match['fecha']));
    final String formattedTime = DateFormat('HH:mm').format(DateTime.parse(match['fecha']));
    // Use isOrganizer instead of a separate isCreator variable
    
    // Función para navegar a los detalles del partido
    void navigateToMatchDetails() {
      if (_isSelectionMode) {
        setState(() {
          if (isSelected) {
            _selectedMatches.remove(matchId);
            if (_selectedMatches.isEmpty) {
              _isSelectionMode = false;
            }
          } else {
            _selectedMatches.add(matchId);
          }
        });
      } else {
        Navigator.push(context, MaterialPageRoute(builder: (context) => MatchDetailsScreen(matchId: matchId.toString()))).then((_) => _fetchMatches());
      }
    }

    // Función para activar el modo de selección con pulsación larga
    void handleLongPress() {
      setState(() {
        _isSelectionMode = true;
        _selectedMatches.add(matchId);
      });
    }
    
    return GestureDetector(
      onTap: navigateToMatchDetails,
      onLongPress: handleLongPress,
      child: Card(
        margin: EdgeInsets.only(bottom: 16),
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        // Añadir un color de fondo si está seleccionado
        color: isSelected ? Colors.blue.shade50 : null,
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
                      // Checkbox para selección múltiple
                      if (_isSelectionMode || isSelected)
                        Transform.scale(
                          scale: 1.2,
                          child: Checkbox(
                            value: isSelected,
                            onChanged: (bool? value) {
                              setState(() {
                                if (value == true) {
                                  _selectedMatches.add(matchId);
                                  _isSelectionMode = true;
                                } else {
                                  _selectedMatches.remove(matchId);
                                  if (_selectedMatches.isEmpty) {
                                    _isSelectionMode = false;
                                  }
                                }
                              });
                            },
                            activeColor: Colors.blue.shade700,
                            checkColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
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
                      Expanded(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            _buildInfoBadge(Icons.calendar_today, formattedDate),
                            _buildInfoBadge(Icons.access_time, formattedTime),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                              decoration: BoxDecoration(
                                color: isPublic ? Colors.green.shade600.withOpacity(0.8) : Colors.orange.shade600.withOpacity(0.8),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isPublic ? Icons.public : Icons.lock,
                                    color: Colors.white,
                                    size: 12,
                                  ),
                                  SizedBox(width: 2),
                                  Text(
                                    isPublic ? 'Público' : 'Privado',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
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
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
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
                          if (!isOrganizer && match['is_participant'] == true)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
                  // Mostrar número de participantes con dropdown
                  Container(
                    margin: EdgeInsets.symmetric(vertical: 12),
                    padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(Icons.group, color: Colors.blue.shade700, size: 20),
                            SizedBox(width: 8),
                            FutureBuilder<int>(
                              future: _getMatchParticipantsCount(match['id']),
                              builder: (context, snapshot) {
                                final int count = snapshot.data ?? 0;
                                final String formato = match['formato'] ?? '?v?';
                                final int totalPlayers = int.parse(formato.split('v')[0]) * 2;
                                
                                return Text(
                                  '$count/$totalPlayers jugadores unidos',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade800,
                                  ),
                                );
                              }
                            ),
                            Spacer(),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade100,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.orange.shade300),
                              ),
                              child: Text(
                                match['formato'],
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange.shade800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        FutureBuilder<List<Map<String, dynamic>>>(
                          future: _getMatchParticipants(match['id']),
                          builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              ),
                            );
                          }
                          
                          if (!snapshot.hasData || snapshot.data == null) {
                            return SizedBox.shrink();
                          }
                          
                          final participants = snapshot.data!;
                          if (participants.isEmpty) {
                            return Text(
                              'No hay participantes aún',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                              ),
                            );
                          }

                          return ExpansionTile(
                            title: Text(
                              'Ver participantes (${participants.length})',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.blue.shade800,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            tilePadding: EdgeInsets.zero,
                            childrenPadding: EdgeInsets.symmetric(vertical: 8),
                            children: participants.map((participant) {
                              final username = participant['username'] ?? 'Usuario desconocido';
                              final avatarUrl = participant['avatar_url'];
                              
                              return ListTile(
                                leading: CircleAvatar(
                                  radius: 14,
                                  backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                                  child: avatarUrl == null ? Icon(Icons.person, size: 14) : null,
                                ),
                                title: Text(
                                  username,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.blue.shade900,
                                  ),
                                ),
                                dense: true,
                                visualDensity: VisualDensity.compact,
                              );
                            }).toList(),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: 8),
                  // Action buttons
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
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
                              label: 'Detalles',
                              onPressed: () => _navigateToMatchJoinScreen(match['id'].toString()),
                              color: Colors.blue,
                            ),
                            _buildActionButton(
                              icon: Icons.person_add,
                              label: 'Invitar',
                              onPressed: () => _showInviteFriendsDialog(match),
                              color: Colors.teal,
                            ),
                            _buildActionButton(
                              icon: Icons.share,
                              label: 'Compartir',
                              onPressed: () => _shareMatchLink(match),
                              color: Colors.indigo,
                            ),
                            // Añadir botón de eliminar partido para el organizador
                            if (!isPast) // Solo si el partido no ha pasado
                              _buildActionButton(
                                icon: Icons.delete,
                                label: 'Eliminar',
                                onPressed: () => _deleteMatch(match),
                                color: Colors.red,
                              ),
                          ]
                        : match['is_participant'] == true // Si el usuario es participante pero no organizador
                          ? [
                              _buildActionButton(
                                icon: Icons.article,
                                label: 'Detalles',
                                onPressed: () => _navigateToMatchJoinScreen(match['id'].toString()),
                                color: Colors.blue,
                              ),
                              // Añadir botón de abandonar partido si no ha pasado la fecha
                              if (!isPast) // Solo si el partido no ha pasado
                                _buildActionButton(
                                  icon: Icons.exit_to_app,
                                  label: 'Abandonar',
                                  onPressed: () => _leaveMatch(match),
                                  color: Colors.red,
                                ),
                            ]
                          : match['publico'] == true // Verificamos si el partido es público
                            ? [
                                _buildActionButton(
                                  icon: Icons.article,
                                  label: 'Detalles',
                                  onPressed: () => _navigateToMatchJoinScreen(match['id'].toString()),
                                  color: Colors.blue,
                                ),
                                if (!isPast) // Solo si el partido no ha pasado
                                  _buildActionButton(
                                    icon: Icons.person_add,
                                    label: 'Unirse',
                                    onPressed: () => _joinMatch(match['id'].toString()),
                                    color: Colors.green,
                                  ),
                              ]
                            : [
                                _buildActionButton(
                                  icon: Icons.article,
                                  label: 'Detalles',
                                  onPressed: () => _navigateToMatchJoinScreen(match['id'].toString()),
                                  color: Colors.blue,
                                ),
                              ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ));
  }
  
  void _navigateToMatchJoinScreen(String matchId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MatchDetailsScreen(matchId: matchId),
      ),
    );
  }  // Método para obtener el número de participantes de un partido
  Future<int> _getMatchParticipantsCount(dynamic matchId) async {
    // Convertir el ID a entero para usarlo como clave del mapa
    int matchIdInt;
    if (matchId is int) {
      matchIdInt = matchId;
    } else {
      try {
        matchIdInt = int.parse(matchId.toString());
      } catch (e) {
        print('Error convirtiendo ID a entero: $e');
        return 0;
      }
    }
    
    // Verificar si tenemos la cuenta en caché
    if (_participantCountCache.containsKey(matchIdInt)) {
      return _participantCountCache[matchIdInt]!;
    }
    
    try {
      final response = await supabase
          .from('match_participants')
          .select('id')
          .eq('match_id', matchIdInt);
      
      final count = response.length;
      
      // Guardar en caché
      _participantCountCache[matchIdInt] = count;
      
      return count;
    } catch (e) {
      print('Error al obtener participantes: $e');
      return 0;
    }
  }
    Future<List<Map<String, dynamic>>> _getMatchParticipants(dynamic matchId) async {
    try {
      // Obtener los IDs de participantes primero
      final participantsResponse = await supabase
          .from('match_participants')
          .select('user_id')
          .eq('match_id', matchId);
      
      // Lista para almacenar la información completa de los participantes
      List<Map<String, dynamic>> participantsWithProfiles = [];
      
      // Para cada participante, obtener su perfil
      for (final participant in participantsResponse) {
        final userId = participant['user_id'];
        
        // Obtener datos del perfil
        final profileData = await supabase
            .from('profiles')
            .select('username, avatar_url')
            .eq('id', userId)
            .maybeSingle();
        
        if (profileData != null) {
          participantsWithProfiles.add({
            'user_id': userId,
            'username': profileData['username'] ?? 'Usuario',
            'avatar_url': profileData['avatar_url']
          });
        } else {
          // Si no hay perfil, añadir datos básicos
          participantsWithProfiles.add({
            'user_id': userId,
            'username': 'Usuario ${userId.substring(0, 4)}',
            'avatar_url': null
          });
        }
      }
      
      print('Participantes obtenidos: ${participantsWithProfiles.length}');
      return participantsWithProfiles;
    } catch (e) {
      print('Error al obtener participantes: $e');
      return [];
    }
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
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
                size: 18,
              ),
            ),
            SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: color.shade700,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Método para que el usuario se una a un partido público
  Future<void> _joinMatch(String matchId) async {
    try {
      // Mostrar diálogo de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Dialog(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text('Uniéndote al partido...'),
                ],
              ),
            ),
          );
        },
      );

      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) {
        Navigator.of(context).pop(); // Cerrar diálogo
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Debes iniciar sesión para unirte a un partido'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Convertir a entero si es posible
      int? matchIdInt;
      try {
        matchIdInt = int.parse(matchId);
      } catch (e) {
        print('Error al convertir ID: $e');
      }
      final matchIdValue = matchIdInt ?? matchId;

      // Verificar si el usuario ya está unido al partido
      final existingParticipant = await supabase
          .from('match_participants')
          .select()
          .eq('match_id', matchIdValue)
          .eq('user_id', currentUser.id)
          .maybeSingle();

      if (existingParticipant != null) {
        Navigator.of(context).pop(); // Cerrar diálogo
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ya estás unido a este partido'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Verificar si el usuario tiene un perfil, si no, crearlo
      final profileExists = await supabase
          .from('profiles')
          .select('id, username')
          .eq('id', currentUser.id)
          .maybeSingle();

      if (profileExists == null) {
        try {
          // Crear un perfil básico
          await supabase.from('profiles').insert({
            'id': currentUser.id,
            'username': currentUser.email?.split('@')[0] ?? 'user_${currentUser.id.substring(0, 8)}',
            'created_at': DateTime.now().toIso8601String(),
          });
        } catch (profileError) {
          print('Error al crear perfil: $profileError');
          // Continuar aunque falle la creación del perfil
        }
      }

      // Añadir usuario a match_participants
      await supabase.from('match_participants').insert({
        'match_id': matchIdValue,
        'user_id': currentUser.id,
        'equipo': null, // El equipo será asignado por el organizador
        'es_organizador': false,
        'joined_at': DateTime.now().toIso8601String(),
      });      // Cerrar diálogo y mostrar mensaje de éxito
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('¡Te has unido al partido correctamente!'),
          backgroundColor: Colors.green,
        ),
      );

      // Actualizar la caché de participantes para este partido
      if (matchIdInt != null && _participantCountCache.containsKey(matchIdInt)) {
        _participantCountCache[matchIdInt] = _participantCountCache[matchIdInt]! + 1;
      }

      // Refrescar la lista de partidos
      _fetchMatches();

    } catch (e) {
      // Cerrar diálogo de carga
      Navigator.of(context).pop();

      // Mostrar mensaje de error con recomendaciones
      String errorMessage = 'Error al unirse al partido: $e';
      String? solutionMessage;

      if (e.toString().contains("duplicate key")) {
        errorMessage = 'Ya parece que estás unido a este partido.';
        solutionMessage = 'Actualiza la lista para ver los cambios.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(errorMessage),
              if (solutionMessage != null)
                Text(
                  solutionMessage,
                  style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                ),
            ],
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ),
      );    }
  }
  
  // Método para que un usuario abandone un partido
  Future<void> _leaveMatch(Map<String, dynamic> match) async {
    // Mostrar diálogo de confirmación
    final bool confirmLeave = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Abandonar partido'),
          content: Text('¿Estás seguro de que quieres abandonar este partido? Podrás volver a unirte más tarde si lo deseas.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Abandonar', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },    ) ?? false;

    if (!confirmLeave) return;

    // Mostrar diálogo de carga
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 20),
                Text('Abandonando el partido...'),
              ],
            ),
          ),
        );
      },
    );

    try {
      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) {
        if (Navigator.canPop(context)) {
          Navigator.pop(context); // Cerrar diálogo
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Debes iniciar sesión para abandonar un partido'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
        // Obtener el ID del partido
      final matchId = match['id'];
      print('Abandonando partido con ID: $matchId');
      print('Usuario actual: ${currentUser.id}');
      
      // Convertir el ID del partido a entero si es necesario
      int matchIdInt;
      try {
        matchIdInt = matchId is int ? matchId : int.parse(matchId.toString());
      } catch (e) {
        print('Error al convertir match_id a entero: $e');
        matchIdInt = -1; // Valor inválido que causará error controlado
      }
      
      // Verificar primero si el usuario está en el partido
      final participante = await supabase
          .from('match_participants')
          .select()
          .eq('match_id', matchIdInt)
          .eq('user_id', currentUser.id)
          .maybeSingle();
          
      if (participante == null) {
        if (Navigator.canPop(context)) {
          Navigator.pop(context); // Cerrar diálogo
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No estás registrado en este partido'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }      print('Participante encontrado: ${participante['id']}');
      
      // Eliminar al usuario de match_participants usando match_id y user_id (más compatible con RLS)
      await supabase
          .from('match_participants')
          .delete()
          .eq('match_id', matchIdInt)
          .eq('user_id', currentUser.id);
          
      print('Usuario eliminado del partido (usando match_id y user_id)');
      
      // Actualizar la caché de participantes para este partido
      try {
        matchIdInt = int.parse(matchId.toString());
        if (_participantCountCache.containsKey(matchIdInt)) {
          _participantCountCache[matchIdInt] = (_participantCountCache[matchIdInt]! - 1).clamp(0, double.infinity).toInt();
          print('Caché de participantes actualizada. Ahora hay ${_participantCountCache[matchIdInt]} participantes en el partido $matchIdInt');
        }
      } catch (e) {
        print('Error al actualizar caché: $e');
      }
      
      // Cerrar diálogo
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
        // Mostrar mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Has abandonado el partido correctamente'),
          backgroundColor: Colors.green,
        ),
      );

      // En lugar de intentar modificar las listas localmente (que puede causar problemas),
      // vamos a recargar completamente los datos desde Supabase
      print('Recargando todos los partidos desde la base de datos...');
      await _fetchMatches();
      
      // Seleccionar la pestaña "Mis Partidos" para que el usuario vea los cambios
      _tabController.animateTo(0); // Asegura que mostramos la pestaña "Mis Partidos"
      
      // Forzar la actualización de la UI
      setState(() {
        print('UI actualizada después de abandonar el partido');
      });
      
    } catch (e) {
      print('Error en _leaveMatch: $e');
      
      // Cerrar diálogo de carga de forma segura
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      // Mostrar mensaje de error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al abandonar el partido: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ),
      );
    }
  }

  // Método para que un organizador elimine un partido
  Future<void> _deleteMatch(Map<String, dynamic> match) async {
    // Mostrar diálogo de confirmación
    bool confirmDelete = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Eliminar partido'),
          content: Text('¿Estás seguro de que quieres eliminar este partido? Esta acción no se puede deshacer.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Eliminar', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    ) ?? false;

    if (!confirmDelete) return;

    // Mostrar diálogo de carga
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 20),
                Text('Eliminando el partido...'),
              ],
            ),
          ),
        );
      },
    );

    try {
      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) {
        Navigator.of(context).pop(); // Cerrar diálogo
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Debes iniciar sesión para eliminar un partido'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Verificar que el usuario es el creador del partido
      if (match['creador_id'] != currentUser.id) {
        Navigator.of(context).pop(); // Cerrar diálogo
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Solo el creador puede eliminar el partido'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Obtener el ID del partido
      final matchId = match['id'];
      print('Eliminando partido con ID: $matchId');
      print('Usuario actual: ${currentUser.id}');      // Eliminar el partido y todos los registros relacionados
      
      // Primero eliminar las estadísticas de los jugadores
      await supabase
          .from('estadisticas')
          .delete()
          .eq('partido_id', matchId);
      
      print('Eliminadas estadísticas del partido: $matchId');
      
      // Luego eliminar los participantes
      await supabase
          .from('match_participants')
          .delete()
          .eq('match_id', matchId);
      
      print('Eliminados participantes del partido: $matchId');

      // Finalmente eliminar el partido
      await supabase
          .from('matches')
          .delete()
          .eq('id', matchId);

      // Cerrar diálogo y mostrar mensaje de éxito
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Partido eliminado correctamente'),
          backgroundColor: Colors.green,
        ),
      );

      // Refrescar la lista de partidos
      _fetchMatches();
    } catch (e) {
      // Cerrar diálogo de carga
      Navigator.of(context).pop();

      // Mostrar mensaje de error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al eliminar el partido: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ),
      );
    }
  }
}