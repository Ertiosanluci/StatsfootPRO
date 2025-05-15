import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:statsfoota/profile_edit_screen.dart'; // Importación para la pantalla de edición de perfil
import 'package:statsfoota/player_stats_graph_screen.dart'; // Importación para la pantalla de estadísticas
import 'package:statsfoota/features/friends/friends_module.dart';
import 'package:statsfoota/features/friends/presentation/controllers/friend_controller.dart';
import 'package:statsfoota/features/notifications/notifications_drawer.dart'; // Importación para el drawer de notificaciones
import 'package:statsfoota/features/friends/presentation/screens/friends_main_screen.dart'; // Para la pantalla de amigos
import 'package:statsfoota/create_match.dart'; // Para la pantalla de crear partido
import 'package:statsfoota/match_list.dart'; // Para la pantalla de ver partidos

class UserMenuScreen extends ConsumerStatefulWidget {
  final int initialTabIndex;
  
  const UserMenuScreen({Key? key, this.initialTabIndex = 0}) : super(key: key);
  
  @override
  ConsumerState<UserMenuScreen> createState() => _UserMenuScreenState();
}

class _UserMenuScreenState extends ConsumerState<UserMenuScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Timer _refreshTimer;
  String _username = "Usuario";
  bool _isLoading = true;
  String? _profileImageUrl;
  late int _currentIndex;

  // Lista de pantallas para la navegación inferior
  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    // Inicializar el índice de la pestaña actual con el valor proporcionado
    _currentIndex = widget.initialTabIndex;
    
    _animationController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );
    _animationController.forward();
    _loadUserData();
    // Inicializar el sistema de amigos
    FriendsModule.initialize(ref);
    
    // Cargar las solicitudes de amistad pendientes al iniciar
    ref.read(friendControllerProvider.notifier).loadPendingRequests();
    
    // Configurar un timer para refrescar periodicamente las solicitudes de amistad
    _refreshTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      if (mounted) {
        ref.read(friendControllerProvider.notifier).loadPendingRequests();
      }
    });

    // Inicializar las pantallas
    _screens = [
      _buildMainScreen(), // Pantalla principal
      MatchListScreen(), // Pantalla de ver partidos
      CreateMatchScreen(), // Pantalla de crear partido
      FriendsMainScreen(), // Pantalla de personas/amigos
    ];
  }

  @override
  void dispose() {
    _animationController.dispose();
    _refreshTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "StatsFut",
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        leading: IconButton(
          icon: Badge(
            label: _getBadgeLabel(),
            isLabelVisible: _hasPendingFriendRequests(),
            child: Icon(Icons.menu, color: Colors.white),
          ),
          onPressed: () {
            _showNotificationsDrawer();
          },
        ),
        automaticallyImplyLeading: false,
        actions: [
          // Botón de perfil con imagen de usuario
          GestureDetector(
            onTap: _showUserMenu,
            child: Container(
              margin: EdgeInsets.only(right: 16),
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: ClipOval(
                child: _profileImageUrl != null && _profileImageUrl!.isNotEmpty
                    ? Image.network(
                        _profileImageUrl!,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: Colors.blue.shade400,
                            child: Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 20,
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.blue.shade400,
                            child: Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 20,
                            ),
                          );
                        },
                      )
                    : Container(
                        color: Colors.blue.shade400,
                        child: Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
              ),
            ),
          ),
        ],
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.blue.shade800.withOpacity(0.9),
                Colors.blue.shade600.withOpacity(0.7),
              ],
            ),
          ),
        ),
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        backgroundColor: Colors.blue.shade800,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white.withOpacity(0.6),
        elevation: 8,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Ver partidos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.sports_soccer),
            label: 'Crear partido',
          ),
          BottomNavigationBarItem(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(Icons.search), // Cambiado de people_alt a search (lupa)
                if (_hasPendingFriendRequests())
                  Positioned(
                    top: -5,
                    right: -5,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.blue.shade800, width: 1.5),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        ref.watch(friendControllerProvider).pendingReceivedRequests.length.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            label: 'Personas',
          ),
        ],
      ),
    );
  }
  
  // Pantalla principal (home)
  Widget _buildMainScreen() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF1565C0),  // Azul oscuro
            Color(0xFF1976D2),  // Azul medio
            Color(0xFF1E88E5),  // Azul claro
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        child: CustomScrollView(
          physics: BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    SizedBox(height: 20),
                    Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.sports_soccer,
                            size: 100,
                            color: Colors.white,
                          ),
                          SizedBox(height: 20),
                          Text(
                            "StatsFut PRO",
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 10),
                          Text(
                            "Tu plataforma para organizar partidos de fútbol",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 40),
                    _buildInfoSection(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoSection() {
    return Column(
      children: [
        _buildInfoCard(
          icon: Icons.calendar_today,
          title: "Ver tus próximos partidos",
          description: "Consulta todos tus partidos y los detalles",
          color: Colors.green,
          onTap: () {
            setState(() {
              _currentIndex = 1; // Cambiar a la pestaña de Ver partidos
            });
          },
        ),
        SizedBox(height: 16),
        _buildInfoCard(
          icon: Icons.sports_soccer,
          title: "Crear un nuevo partido",
          description: "Organiza un partido y comparte con amigos",
          color: Colors.blue,
          onTap: () {
            setState(() {
              _currentIndex = 2; // Cambiar a la pestaña de Crear partido
            });
          },
        ),
        SizedBox(height: 16),
        _buildInfoCard(
          icon: Icons.people_alt,
          title: "Gestionar amigos",
          description: "Conecta con otros jugadores",
          color: Colors.teal,
          onTap: () {
            setState(() {
              _currentIndex = 3; // Cambiar a la pestaña de Personas
            });
          },
        ),
        SizedBox(height: 16),
        _buildInfoCard(
          icon: Icons.bar_chart,
          title: "Ver estadísticas",
          description: "Analiza tu rendimiento en los partidos",
          color: Colors.orange,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => PlayerStatsGraphScreen()),
            );
          },
        ),
      ],
    );
  }
  
  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white.withOpacity(0.1),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.white.withOpacity(0.7),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // Método para verificar si hay solicitudes de amistad pendientes
  bool _hasPendingFriendRequests() {
    final state = ref.watch(friendControllerProvider);
    return state.pendingReceivedRequests.isNotEmpty;
  }
  
  // Método para obtener el número de solicitudes pendientes
  Widget _getBadgeLabel() {
    final state = ref.watch(friendControllerProvider);
    final count = state.pendingReceivedRequests.length;
    return Text(
      count.toString(),
      style: TextStyle(color: Colors.white, fontSize: 10),
    );
  }
  
  // Método para mostrar el drawer de notificaciones
  void _showNotificationsDrawer() {
    // Abre el drawer de notificaciones personalizado desde la izquierda
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 1.0,
        minChildSize: 0.5,
        maxChildSize: 1.0,
        builder: (_, scrollController) => Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: NotificationsDrawer(),
        ),
      ),
    );
  }

  Future<void> _loadUserData() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;

      if (user != null) {
        // Primero intentamos obtener el nombre y la foto de perfil
        try {
          final profileData = await Supabase.instance.client
              .from('profiles')
              .select('username, avatar_url')
              .eq('id', user.id)
              .single();

          if (profileData != null && mounted) {
            setState(() {
              _username = profileData['username'] ?? "Usuario";
              _profileImageUrl = profileData['avatar_url'];
              _isLoading = false;
            });
            return; // Terminamos aquí si encontramos datos en 'profiles'
          }
        } catch (profileError) {
          print('Error al buscar en tabla profiles: $profileError');
          // Continuamos con el siguiente intento
        }

        // Si no hay datos en profiles, intentamos con metadatos de usuario
        final displayName = user.userMetadata?["username"];

        if (displayName != null) {
          // Si existe en los metadatos, lo usamos
          if (mounted) {
            setState(() {
              _username = displayName;
              _isLoading = false;
            });
          }
          return; // Terminamos aquí si encontramos el display_name
        }

        // Si no hay username en metadatos, usamos el email cortado en @
        if (user.email != null && user.email!.isNotEmpty) {
          final emailUsername = user.email!.split('@')[0]; // Obtiene la parte antes del @

          if (mounted) {
            setState(() {
              _username = emailUsername;
              _isLoading = false;
            });
          }
          return; // Terminamos aquí si pudimos extraer el nombre del email
        }

        // Como último recurso, intentamos con la tabla 'usuarios'
        try {
          final userResponse = await Supabase.instance.client
              .from('usuarios')
              .select('username')
              .eq('id', user.id)
              .single();

          if (userResponse != null && mounted) {
            setState(() {
              _username = userResponse['username'] ?? "Usuario";
              _isLoading = false;
            });
          }
        } catch (userError) {
          print('Error al buscar en tabla usuarios: $userError');
          if (mounted) {
            setState(() {
              _username = "Usuario";
              _isLoading = false;
            });
          }
        }
      } else {
        // No hay usuario autenticado
        if (mounted) {
          setState(() {
            _username = "Usuario";
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error general al cargar datos del usuario: $e');
      if (mounted) {
        setState(() {
          _username = "Usuario";
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _signOut() async {
    try {
      await Supabase.instance.client.auth.signOut();
      // Navegar directamente a la pantalla de inicio sin mostrar diálogo
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    } catch (e) {
      print('Error al cerrar sesión: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cerrar sesión. Inténtalo de nuevo.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showUserMenu() {
    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        MediaQuery.of(context).size.width,
        kToolbarHeight + MediaQuery.of(context).padding.top,
        0,
        0
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      items: [
        PopupMenuItem<String>(
          value: 'edit_profile',
          child: Row(
            children: [
              Icon(Icons.edit, color: Colors.blue.shade600),
              SizedBox(width: 10),
              Text('Editar perfil'),
            ],
          ),
          onTap: () {
            // Navegar a la pantalla de edición de perfil después de que el menú se cierre
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfileEditScreen()),
              ).then((_) {
                // Actualizar datos después de volver de la pantalla de edición
                _loadUserData();
              });
            });
          },
        ),
        PopupMenuItem<String>(
          value: 'player_stats',
          child: Row(
            children: [
              Icon(Icons.bar_chart, color: Colors.green.shade600),
              SizedBox(width: 10),
              Text('Mis Estadísticas'),
            ],
          ),
          onTap: () {
            // Navegar a la pantalla de estadísticas después de que el menú se cierre
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PlayerStatsGraphScreen()),
              );
            });
          },
        ),
        PopupMenuItem<String>(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout, color: Colors.red.shade600),
              SizedBox(width: 10),
              Text('Cerrar sesión'),
            ],
          ),
          onTap: () {
            // Llamar directamente a _signOut después de que el menú se cierre
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _signOut();
            });
          },
        ),
      ],
    );
  }
}