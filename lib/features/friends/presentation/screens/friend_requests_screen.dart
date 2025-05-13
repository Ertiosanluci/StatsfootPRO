import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    _loadFriendRequests();
  }

  @override
  void dispose() {
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
    final state = ref.read(friendControllerProvider);
    final repository = ref.read(friendRepositoryProvider);
    
    // Load user profiles for received requests
    final List<UserProfile> receivedProfiles = [];
    for (FriendRequest request in state.pendingReceivedRequests) {
      try {
        final profile = await repository.getUserProfile(request.userId1);
        receivedProfiles.add(profile);
      } catch (e) {
        print('Error loading profile for user ${request.userId1}: $e');
      }
    }
    
    // Load user profiles for sent requests
    final List<UserProfile> sentProfiles = [];
    for (FriendRequest request in state.pendingSentRequests) {
      try {
        final profile = await repository.getUserProfile(request.userId2);
        sentProfiles.add(profile);
      } catch (e) {
        print('Error loading profile for user ${request.userId2}: $e');
      }
    }
    
    setState(() {
      _receivedRequestUsers = receivedProfiles;
      _sentRequestUsers = sentProfiles;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(friendControllerProvider);

    return Scaffold(
      // Usando PreferredSize para controlar la altura exactamente
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight - 8), // Reduciendo la altura
        child: AppBar(
          backgroundColor: Colors.blue.shade800,
          elevation: 0,
          // Sin título y sin espacio extra
          flexibleSpace: Container(
            alignment: Alignment.bottomCenter,
            child: TabBar(
              controller: _tabController,
              indicatorColor: Colors.orange.shade600,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white.withOpacity(0.7),
              tabs: [
                Tab(
                  icon: Icon(Icons.inbox, color: Colors.white),
                  child: Text(
                    'Recibidas (${state.pendingReceivedRequests.length})',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                Tab(
                  icon: Icon(Icons.outbox, color: Colors.white),
                  child: Text(
                    'Enviadas (${state.pendingSentRequests.length})',
                    style: TextStyle(color: Colors.white),
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
}
