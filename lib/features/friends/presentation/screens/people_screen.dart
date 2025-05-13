import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:statsfoota/features/friends/presentation/controllers/friend_controller.dart';
import 'package:statsfoota/features/friends/presentation/screens/user_profile_screen.dart';
import 'package:statsfoota/features/friends/presentation/state/friend_state.dart'; // Añadiendo importación necesaria

class PeopleScreen extends ConsumerStatefulWidget {
  const PeopleScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<PeopleScreen> createState() => _PeopleScreenState();
}

class _PeopleScreenState extends ConsumerState<PeopleScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isFirstLoad = true;

  @override
  void initState() {
    super.initState();
    // Usamos un Timer de un frame para retrasar la carga hasta después del build inicial
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUsersWithDelay();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Método seguro para cargar usuarios
  Future<void> _loadUsersWithDelay() async {
    try {
      if (!mounted) return;
      
      // Establecer un delay para asegurar que el widget ya ha terminado de construirse
      await Future.delayed(const Duration(milliseconds: 100));
      
      if (mounted) {
        setState(() {
          _isFirstLoad = false;
        });
        
        // Usamos ref.read aquí para evitar una dependencia de observación
        await ref.read(friendControllerProvider.notifier).loadAllUsers();
      }
    } catch (e) {
      debugPrint('Error al cargar usuarios: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar usuarios'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Reintentar',
              textColor: Colors.white,
              onPressed: _loadUsersWithDelay,
            ),
          ),
        );
      }
    }
  }

  // Método para buscar usuarios
  void _searchUsers(String query) {
    setState(() {
      _searchQuery = query;
    });
    
    // Cancelamos cualquier búsqueda previa
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!mounted) return;
      ref.read(friendControllerProvider.notifier).loadAllUsers(searchQuery: query);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Si es la primera carga, usamos un estado inicial vacío para evitar triggers
    // durante la construcción
    final state = _isFirstLoad 
        ? FriendState.initial() 
        : ref.watch(friendControllerProvider);
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF1565C0),
              Color(0xFF1976D2),
              Color(0xFF1E88E5),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            // Buscador de personas
            Padding(
              padding: EdgeInsets.fromLTRB(16, 10, 16, 8),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Buscar personas...',
                    hintStyle: TextStyle(color: Colors.white70),
                    prefixIcon: Icon(Icons.search, color: Colors.white70),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear, color: Colors.white70),
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                                _searchQuery = '';
                                _loadUsersWithDelay();
                              });
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                  ),
                  style: TextStyle(color: Colors.white),
                  onChanged: _searchUsers,
                ),
              ),
            ),

            // Lista de personas
            Expanded(
              child: SafeArea(
                child: _buildContent(state),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(FriendState state) {
    // Si es la primera carga, mostrar indicador
    if (_isFirstLoad) {
      return Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }
    
    // Si está cargando después del primer build
    if (state.isLoading) {
      return Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    // Si hay error
    if (state.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.red, size: 48),
              SizedBox(height: 16),
              Text(
                'Error: ${state.errorMessage}',
                style: TextStyle(color: Colors.white, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _loadUsersWithDelay,
                child: Text('Reintentar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Si no hay usuarios
    if (state.allUsers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, color: Colors.white70, size: 64),
            SizedBox(height: 16),
            Text(
              _searchController.text.isNotEmpty
                ? 'No se encontraron usuarios con ese nombre'
                : 'No hay usuarios disponibles',
              style: TextStyle(color: Colors.white, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            if (_searchController.text.isNotEmpty)
              ElevatedButton(
                onPressed: () {
                  _searchController.clear();
                  _loadUsersWithDelay();
                },
                child: Text('Ver todos los usuarios'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade800,
                  foregroundColor: Colors.white,
                ),
              )
          ],
        ),
      );
    }

    // Lista de usuarios simple
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: state.allUsers.length,
      itemBuilder: (context, index) {
        final user = state.allUsers[index];
        return _buildSimpleUserItem(user, state);
      },
    );
  }

  // Construir un item de usuario simple y seguro
  Widget _buildSimpleUserItem(user, FriendState state) {
    // Determina el estado de amistad
    bool isFriend = state.friends.any((f) => f.id == user.id);
    bool hasPendingSentRequest = state.pendingSentRequests.any(
        (r) => r.userId2 == user.id);
    bool hasPendingReceivedRequest = state.pendingReceivedRequests.any(
        (r) => r.userId1 == user.id);

    return Card(
      margin: EdgeInsets.only(bottom: 10),
      color: Colors.white.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade600,
          backgroundImage: user.avatarUrl != null && user.avatarUrl.isNotEmpty
              ? NetworkImage(user.avatarUrl)
              : null,
          child: (user.avatarUrl == null || user.avatarUrl.isEmpty)
              ? Text(
                  user.username != null && user.username.isNotEmpty
                      ? user.username[0].toUpperCase()
                      : '?',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                )
              : null,
        ),
        title: Text(
          user.username ?? 'Sin nombre',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        subtitle: user.fieldPosition != null
            ? Text(
                user.fieldPosition,
                style: TextStyle(color: Colors.white70),
              )
            : null,
        trailing: _buildFriendshipButton(user.id, isFriend,
            hasPendingSentRequest, hasPendingReceivedRequest),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UserProfileScreen(userId: user.id),
          ),
        ),
      ),
    );
  }

  // Construir el botón según el estado de amistad
  Widget _buildFriendshipButton(String userId, bool isFriend,
      bool hasPendingSentRequest, bool hasPendingReceivedRequest) {
    if (isFriend) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.green,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          'Amigos',
          style: TextStyle(color: Colors.white, fontSize: 12),
        ),
      );
    } else if (hasPendingSentRequest) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.orange,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          'Enviada',
          style: TextStyle(color: Colors.white, fontSize: 12),
        ),
      );
    } else if (hasPendingReceivedRequest) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.blue,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          'Pendiente',
          style: TextStyle(color: Colors.white, fontSize: 12),
        ),
      );
    } else {
      return ElevatedButton(
        onPressed: () {
          // Ejecutamos en un futuro para evitar actualizar durante la construcción
          Future.microtask(() {
            if (!mounted) return;
            ref.read(friendControllerProvider.notifier).sendFriendRequest(userId);
          });
        },
        child: Text('Añadir'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(horizontal: 12),
          minimumSize: Size(80, 30),
        ),
      );
    }
  }
}
