import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:statsfoota/features/friends/presentation/controllers/friend_controller.dart';
import 'package:statsfoota/features/friends/presentation/screens/user_profile_screen.dart';

class PeopleScreen extends ConsumerStatefulWidget {
  const PeopleScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<PeopleScreen> createState() => _PeopleScreenState();
}

class _PeopleScreenState extends ConsumerState<PeopleScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  bool _isInitialLoad = true;

  @override
  void initState() {
    super.initState();
    // We'll load users after the build method completes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUsers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    print('PeopleScreen: _loadUsers called');
    try {
      await ref.read(friendControllerProvider.notifier).loadAllUsers();
      if (mounted) {
        setState(() {
          _isInitialLoad = false;
        });
      }
    } catch (e) {
      print('PeopleScreen ERROR: Failed to load users: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar usuarios. Por favor, intenta de nuevo.'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Reintentar',
              textColor: Colors.white,
              onPressed: _loadUsers,
            ),
          ),
        );
      }
    }
  }

  void _searchUsers(String query) {
    print('PeopleScreen: _searchUsers called with query: $query');
    ref.read(friendControllerProvider.notifier).loadAllUsers(searchQuery: query);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(friendControllerProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.blueGrey.shade900,
      appBar: AppBar(
        title: _isSearching 
          ? TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Buscar personas...',
                hintStyle: TextStyle(color: Colors.white70),
                border: InputBorder.none,
              ),
              style: TextStyle(color: Colors.white),
              onChanged: _searchUsers,
            )
          : Text('Personas'),
        backgroundColor: Colors.blueGrey.shade800,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  _loadUsers();
                }
              });
            },
          ),
        ],
      ),
      body: state.isLoading
          ? Center(child: CircularProgressIndicator(color: Colors.white))
          : state.errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, color: Colors.red, size: 50),
                      SizedBox(height: 16),
                      Text(
                        'Error al cargar usuarios',
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                      SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _loadUsers,
                        child: Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : state.allUsers.isEmpty
                  ? Center(
                      child: Text(
                        'No se encontraron usuarios',
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.all(16),
                      itemCount: state.allUsers.length,
                      itemBuilder: (context, index) {
                        final user = state.allUsers[index];
                        
                        bool isFriend = state.friends.any((f) => f.id == user.id);
                        bool hasPendingSentRequest = state.pendingSentRequests.any(
                          (r) => r.userId2 == user.id
                        );
                        bool hasPendingReceivedRequest = state.pendingReceivedRequests.any(
                          (r) => r.userId1 == user.id
                        );
                        
                        return Card(
                          elevation: 2,
                          color: Colors.blueGrey.shade800,
                          margin: EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.blueGrey.shade700, width: 1),
                          ),
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => UserProfileScreen(userId: user.id),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 28,
                                    backgroundColor: Colors.blue.shade700,
                                    backgroundImage: user.avatarUrl != null
                                        ? NetworkImage(user.avatarUrl!)
                                        : null,
                                    child: user.avatarUrl == null
                                        ? Text(
                                            user.username.substring(0, 1).toUpperCase(),
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
                                          user.username,
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        if (user.fieldPosition != null)
                                          Text(
                                            user.fieldPosition!,
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.white70,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  _buildUserStatusButton(
                                    user.id, 
                                    isFriend, 
                                    hasPendingSentRequest, 
                                    hasPendingReceivedRequest
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

  Widget _buildUserStatusButton(
    String userId, 
    bool isFriend, 
    bool hasPendingSentRequest, 
    bool hasPendingReceivedRequest
  ) {
    if (isFriend) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.green, width: 1),
        ),
        child: Text(
          'Amigo',
          style: TextStyle(color: Colors.green, fontSize: 12),
        ),
      );
    } else if (hasPendingSentRequest) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.orange, width: 1),
        ),
        child: Text(
          'Enviada',
          style: TextStyle(color: Colors.orange, fontSize: 12),
        ),
      );
    } else if (hasPendingReceivedRequest) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.blue, width: 1),
        ),
        child: Text(
          'Pendiente',
          style: TextStyle(color: Colors.blue, fontSize: 12),
        ),
      );
    } else {
      return IconButton(
        icon: Icon(Icons.person_add, color: Colors.blue),
        onPressed: () {
          ref.read(friendControllerProvider.notifier).sendFriendRequest(userId);
        },
      );
    }
  }
}
