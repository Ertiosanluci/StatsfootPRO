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

class UserMenuScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<UserMenuScreen> createState() => _UserMenuScreenState();
}

class _UserMenuScreenState extends ConsumerState<UserMenuScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Timer _refreshTimer;
  String _username = "Usuario";
  bool _isLoading = true;
  String? _profileImageUrl;

  @override
  void initState() {
    super.initState();
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
      body: Container(
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
                child: _buildUserHeader(),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 30),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader("Administración"),
                      SizedBox(height: 15),
                      _buildFeaturesGrid(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, '/create_match');
        },
        backgroundColor: Colors.orange.shade600,
        elevation: 8,
        icon: Icon(Icons.add, color: Colors.white),
        label: Text(
          "Nuevo Partido",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
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

  Widget _buildUserHeader() {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 10, 20, 25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Mensaje de bienvenida (sin el avatar)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FadeTransition(
                opacity: Tween<double>(begin: 0, end: 1).animate(
                  CurvedAnimation(
                    parent: _animationController,
                    curve: Interval(0.3, 0.7, curve: Curves.easeOut),
                  ),
                ),
                child: Text(
                  "Bienvenido de nuevo,",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ),
              SizedBox(height: 4),
              FadeTransition(
                opacity: Tween<double>(begin: 0, end: 1).animate(
                  CurvedAnimation(
                    parent: _animationController,
                    curve: Interval(0.4, 0.8, curve: Curves.easeOut),
                  ),
                ),
                child: Text(
                  _isLoading ? "Cargando..." : _username,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          FadeTransition(
            opacity: Tween<double>(begin: 0, end: 1).animate(
              CurvedAnimation(
                parent: _animationController,
                curve: Interval(0.5, 0.9, curve: Curves.easeOut),
              ),
            ),
            child: SlideTransition(
              position: Tween<Offset>(
                begin: Offset(0, 0.2),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(
                  parent: _animationController,
                  curve: Interval(0.5, 0.9, curve: Curves.easeOut),
                ),
              ),
              child: Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.orange.shade300, Colors.orange.shade600],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 12,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.sports_soccer,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Acceso Rápido",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "Consulta o crea nuevos partidos",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/match_list');
                      },
                      icon: Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.2),
                        padding: EdgeInsets.all(8),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedAvatar() {
    return ScaleTransition(
      scale: Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Interval(0.0, 0.6, curve: Curves.elasticOut),
        ),
      ),
      child: Container(
        width: 65,
        height: 65,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [Colors.blue.shade400, Colors.blue.shade700],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
          border: Border.all(
            color: Colors.white.withOpacity(0.4),
            width: 2,
          ),
        ),
        child: Center(
          child: Icon(
            Icons.person,
            color: Colors.white,
            size: 32,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Interval(0.6, 1.0, curve: Curves.easeOut),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.orange.shade600,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(width: 10),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              color: Colors.white,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesGrid() {
    final state = ref.watch(friendControllerProvider);
    final int pendingRequestsCount = state.pendingReceivedRequests.length;

    final List<Map<String, dynamic>> features = [
      {
        'icon': Icons.sports_soccer,
        'title': 'Crear partido',
        'color': Colors.blue,
        'route': '/create_match',
      },
      {
        'icon': Icons.calendar_today,
        'title': 'Ver partidos',
        'color': Colors.green,
        'route': '/match_list',
      },
      // "Gestionar equipos" button removed while preserving its underlying functionality
      {
        'icon': Icons.people_alt,
        'title': 'Personas',
        'color': Colors.teal,
        'route': '/friends',
        'badge': pendingRequestsCount > 0 ? pendingRequestsCount.toString() : null,
      },
    ];

    return FadeTransition(
      opacity: Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Interval(0.7, 1.0, curve: Curves.easeOut),
        ),
      ),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: Offset(0, 0.2),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Interval(0.7, 1.0, curve: Curves.easeOut),
          ),
        ),
        child: GridView.builder(
          physics: NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: features.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.5,
            crossAxisSpacing: 15,
            mainAxisSpacing: 15,
          ),
          itemBuilder: (context, index) {
            final feature = features[index];
            return _buildFeatureCard(
              icon: feature['icon'] as IconData,
              title: feature['title'] as String,
              color: feature['color'] as Color,
              onTap: () {
                Navigator.pushNamed(context, feature['route'] as String);
              },
              badge: feature['badge'] as String?,
            );
          },
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
    String? badge,
  }) {
    return Material(
      color: Colors.white.withOpacity(0.1),
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        splashColor: color.withOpacity(0.1),
        highlightColor: color.withOpacity(0.05),
        child: Container(
          padding: EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: badge != null
                      ? Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Icon(
                              icon,
                              color: color,
                              size: 26,
                            ),
                            Positioned(
                              top: -8,
                              right: -8,
                              child: Container(
                                padding: EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 1.5),
                                ),
                                constraints: BoxConstraints(
                                  minWidth: 16,
                                  minHeight: 16,
                                ),
                                child: Text(
                                  badge,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ],
                        )
                      : Icon(
                          icon,
                          color: color,
                          size: 32,
                        ),
                ),
              ),
              SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCards() {
    final features = [
      {
        'icon': Icons.sports_soccer_rounded,
        'title': 'Partidos',
        'color': Colors.orange.shade600,
        'route': '/match_list'
      },
      {
        'icon': Icons.add_chart_rounded,
        'title': 'Estadísticas',
        'color': Colors.red.shade600,
        'route': '/match_list'
      },
    ];

    return FadeTransition(
      opacity: Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Interval(0.7, 1.0, curve: Curves.easeOut),
        ),
      ),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: Offset(0, 0.2),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Interval(0.7, 1.0, curve: Curves.easeOut),
          ),
        ),
        child: GridView.builder(
          physics: NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: features.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.5,
            crossAxisSpacing: 15,
            mainAxisSpacing: 15,
          ),
          itemBuilder: (context, index) {
            final feature = features[index];
            return _buildFeatureCard(
              icon: feature['icon'] as IconData,
              title: feature['title'] as String,
              color: feature['color'] as Color,
              onTap: () {
                Navigator.pushNamed(context, feature['route'] as String);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatisticCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        splashColor: color.withOpacity(0.1),
        highlightColor: color.withOpacity(0.05),
        child: Container(
          padding: EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.07),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Icon(
                    icon,
                    color: color,
                    size: 26,
                  ),
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
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          value,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            subtitle,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.white.withOpacity(0.5),
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }
}