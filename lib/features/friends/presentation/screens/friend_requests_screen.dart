import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:statsfoota/features/friends/data/repositories/friend_repository.dart';
import 'package:statsfoota/features/friends/domain/models/friend_request.dart';
import 'package:statsfoota/features/friends/domain/models/user_profile.dart';
import 'package:statsfoota/features/friends/presentation/controllers/friend_controller.dart';
import 'package:statsfoota/features/friends/presentation/screens/user_profile_screen.dart';

class FriendRequestsScreen extends ConsumerStatefulWidget {
  const FriendRequestsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<FriendRequestsScreen> createState() => _FriendRequestsScreenState();
}

class _FriendRequestsScreenState extends ConsumerState<FriendRequestsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  List<UserProfile> _receivedRequestUsers = [];
  List<UserProfile> _sentRequestUsers = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);
    _loadFriendRequests();
  }
  
  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      setState(() {
        // Forzar una reconstrucción cuando cambia la pestaña
      });
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadFriendRequests() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await ref.read(friendControllerProvider.notifier).loadPendingRequests();
      await _loadUserProfiles();
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar solicitudes de amistad')),
      );
    }
  }

  Future<void> _loadUserProfiles() async {
    try {
      print('Iniciando carga de perfiles de usuarios');
      final state = ref.read(friendControllerProvider);
      // State no puede ser nulo ya que es un StateNotifierProvider
      
      final repository = ref.read(friendRepositoryProvider);
      // Repository no puede ser nulo ya que es un Provider
      
      print('Requests recibidas: ${state.pendingReceivedRequests.length}');
      print('Requests enviadas: ${state.pendingSentRequests.length}');
      
      // Load user profiles for received requests
      final List<UserProfile> receivedProfiles = [];
      if (state.pendingReceivedRequests.isNotEmpty) {
        for (FriendRequest request in state.pendingReceivedRequests) {
          try {
            print('Cargando perfil para solicitud recibida de usuario: ${request.userId1}');
            final profile = await repository.getUserProfile(request.userId1);
            receivedProfiles.add(profile);
            print('Perfil cargado correctamente para: ${profile.username}');
          } catch (e) {
            print('Error loading profile for user ${request.userId1}: $e');
            // Agregar un perfil de respaldo con información limitada
            receivedProfiles.add(UserProfile(
              id: request.userId1,
              username: 'Usuario (Sin datos)',
            ));
          }
        }
      }
      
      // Load user profiles for sent requests
      final List<UserProfile> sentProfiles = [];
      if (state.pendingSentRequests.isNotEmpty) {
        for (FriendRequest request in state.pendingSentRequests) {
          try {
            print('Cargando perfil para solicitud enviada a usuario: ${request.userId2}');
            final profile = await repository.getUserProfile(request.userId2);
            sentProfiles.add(profile);
            print('Perfil cargado correctamente para: ${profile.username}');
          } catch (e) {
            print('Error loading profile for user ${request.userId2}: $e');
            // Agregar un perfil de respaldo con información limitada
            sentProfiles.add(UserProfile(
              id: request.userId2,
              username: 'Usuario (Sin datos)',
            ));
          }
        }
      }
    
      setState(() {
        _receivedRequestUsers = receivedProfiles;
        _sentRequestUsers = sentProfiles;
      });
    } catch (e) {
      print('Error en _loadUserProfiles: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar perfiles de usuarios')),
      );
    }
  }

  Widget _buildReceivedRequestsList() {
    final state = ref.watch(friendControllerProvider);
    
    if (state.pendingReceivedRequests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_search,
              size: 80,
              color: Colors.white.withOpacity(0.3),
            ),
            SizedBox(height: 16),
            Text(
              'No tienes solicitudes recibidas',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }
    
    return RefreshIndicator(
      onRefresh: _loadFriendRequests,
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: _receivedRequestUsers.length,
        itemBuilder: (context, index) {
          final userProfile = _receivedRequestUsers[index];
          final request = state.pendingReceivedRequests.firstWhere(
            (r) => r.userId1 == userProfile.id,
          );
          
          return Card(
            elevation: 2,
            color: Colors.white.withOpacity(0.1),
            margin: EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UserProfileScreen(userId: userProfile.id),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.blue.shade700,
                          backgroundImage: userProfile.avatarUrl != null
                              ? NetworkImage(userProfile.avatarUrl!)
                              : null,
                          child: userProfile.avatarUrl == null
                              ? Text(
                                  userProfile.username.substring(0, 1).toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 24,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                userProfile.username,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Quiere ser tu amigo',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: () {
                            ref.read(friendControllerProvider.notifier)
                                .rejectFriendRequest(request.id);
                            setState(() {
                              _receivedRequestUsers.removeAt(index);
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text('Rechazar'),
                        ),
                        SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () {
                            ref.read(friendControllerProvider.notifier)
                                .acceptFriendRequest(request.id);
                            setState(() {
                              _receivedRequestUsers.removeAt(index);
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text('Aceptar'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSentRequestsList() {
    final state = ref.watch(friendControllerProvider);
    
    if (state.pendingSentRequests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.outgoing_mail,
              size: 80,
              color: Colors.white.withOpacity(0.3),
            ),
            SizedBox(height: 16),
            Text(
              'No has enviado solicitudes de amistad',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }
    
    return RefreshIndicator(
      onRefresh: _loadFriendRequests,
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: _sentRequestUsers.length,
        itemBuilder: (context, index) {
          final userProfile = _sentRequestUsers[index];
          final request = state.pendingSentRequests.firstWhere(
            (r) => r.userId2 == userProfile.id,
          );
          
          return Card(
            elevation: 2,
            color: Colors.white.withOpacity(0.1),
            margin: EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UserProfileScreen(userId: userProfile.id),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.blue.shade700,
                      backgroundImage: userProfile.avatarUrl != null
                          ? NetworkImage(userProfile.avatarUrl!)
                          : null,
                      child: userProfile.avatarUrl == null
                          ? Text(
                              userProfile.username.substring(0, 1).toUpperCase(),
                              style: TextStyle(
                                fontSize: 24,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userProfile.username,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Solicitud pendiente',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        ref.read(friendControllerProvider.notifier)
                            .cancelFriendRequest(request.id);
                        setState(() {
                          _sentRequestUsers.removeAt(index);
                        });
                      },
                      icon: Icon(Icons.cancel, color: Colors.red),
                      label: Text(
                        'Cancelar',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(friendControllerProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue.shade800,
        elevation: 0,
        toolbarHeight: 56, // Altura estándar de toolbar
        flexibleSpace: SafeArea(
          child: Container(
            alignment: Alignment.bottomCenter,
            padding: EdgeInsets.only(bottom: 0),
            child: TabBar(
              controller: _tabController,
              indicatorColor: Colors.orange.shade600,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white.withOpacity(0.7),
              labelPadding: EdgeInsets.symmetric(horizontal: 2.0),
              indicatorSize: TabBarIndicatorSize.label,
              tabs: [
                Tab(
                  height: 44,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.inbox,
                        color: _tabController.index == 0 
                            ? Colors.white 
                            : Colors.white.withOpacity(0.5),
                        size: 20,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Recibidas (${state.pendingReceivedRequests.length})',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Tab(
                  height: 44,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.outbox,
                        color: _tabController.index == 1 
                            ? Colors.white 
                            : Colors.white.withOpacity(0.5),
                        size: 20,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Enviadas (${state.pendingSentRequests.length})',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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
        child: _isLoading
            ? Center(child: CircularProgressIndicator(color: Colors.white))
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildReceivedRequestsList(),
                  _buildSentRequestsList(),
                ],
              ),
      ),
    );
  }
}
