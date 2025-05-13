import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:statsfoota/features/friends/domain/models/user_profile.dart';
import 'package:statsfoota/features/friends/presentation/controllers/friend_controller.dart';

class UserProfileScreen extends ConsumerStatefulWidget {
  final String userId;

  const UserProfileScreen({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  ConsumerState<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends ConsumerState<UserProfileScreen> {
  UserProfile? _userProfile;
  bool _isLoading = true;
  String? _error;
  bool _isFriend = false;
  bool _hasPendingSentRequest = false;
  bool _hasPendingReceivedRequest = false;
  String? _pendingRequestId;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load the user profile
      final repository = ref.read(friendRepositoryProvider);
      final userProfile = await repository.getUserProfile(widget.userId);
      
      // Check status with current user
      final state = ref.read(friendControllerProvider);
      
      final isFriend = state.friends.any((friend) => friend.id == widget.userId);
      
      final pendingSentRequest = state.pendingSentRequests
          .where((request) => request.userId2 == widget.userId)
          .toList();
      
      final pendingReceivedRequest = state.pendingReceivedRequests
          .where((request) => request.userId1 == widget.userId)
          .toList();
      
      setState(() {
        _userProfile = userProfile;
        _isLoading = false;
        _isFriend = isFriend;
        _hasPendingSentRequest = pendingSentRequest.isNotEmpty;
        _hasPendingReceivedRequest = pendingReceivedRequest.isNotEmpty;
        
        if (_hasPendingSentRequest) {
          _pendingRequestId = pendingSentRequest.first.id;
        } else if (_hasPendingReceivedRequest) {
          _pendingRequestId = pendingReceivedRequest.first.id;
        }
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey.shade900,
      appBar: AppBar(
        title: Text('Perfil'),
        backgroundColor: Colors.blueGrey.shade800,
        elevation: 0,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Colors.white))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, color: Colors.red, size: 50),
                      SizedBox(height: 16),
                      Text(
                        'Error al cargar perfil',
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                      SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _loadUserProfile,
                        child: Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : _userProfile == null
                  ? Center(
                      child: Text(
                        'Usuario no encontrado',
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                    )
                  : _buildProfile(),
    );
  }

  Widget _buildProfile() {
    final profile = _userProfile!;
    
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Profile header
          Center(
            child: Column(
              children: [
                // Avatar
                Hero(
                  tag: 'avatar-${profile.id}',
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.blue.shade700,
                    backgroundImage: profile.avatarUrl != null
                        ? NetworkImage(profile.avatarUrl!)
                        : null,
                    child: profile.avatarUrl == null
                        ? Text(
                            profile.username.substring(0, 1).toUpperCase(),
                            style: TextStyle(
                              fontSize: 40,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                ),
                SizedBox(height: 16),
                
                // Username
                Text(
                  profile.username,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 20),
                
                // Friend status button
                _buildFriendActionButton(),
                SizedBox(height: 24),
              ],
            ),
          ),

          // Profile details
          Card(
            color: Colors.blueGrey.shade800,
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailItem(
                    'Edad',
                    profile.age != null ? '${profile.age} años' : 'No especificada',
                    Icons.cake,
                  ),
                  _buildDivider(),
                  _buildDetailItem(
                    'Género',
                    profile.gender ?? 'No especificado',
                    Icons.person,
                  ),
                  _buildDivider(),
                  _buildDetailItem(
                    'Posición',
                    profile.fieldPosition ?? 'No especificada',
                    Icons.sports_soccer,
                  ),
                  _buildDivider(),
                  _buildDetailItem(
                    'Frecuencia de juego',
                    profile.playFrequency ?? 'No especificada',
                    Icons.calendar_today,
                  ),
                  _buildDivider(),
                  _buildDetailItem(
                    'Nivel de juego',
                    profile.skillLevel ?? 'No especificado',
                    Icons.trending_up,
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 20),
          
          // Description card
          if (profile.description != null && profile.description!.isNotEmpty)
            Card(
              color: Colors.blueGrey.shade800,
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.description, color: Colors.white70),
                        SizedBox(width: 12),
                        Text(
                          'Descripción',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Text(
                      profile.description!,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 22),
          SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
              SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      color: Colors.blueGrey.shade700,
      height: 20,
    );
  }

  Widget _buildFriendActionButton() {
    if (_isFriend) {
      return ElevatedButton.icon(
        icon: Icon(Icons.check_circle),
        label: Text('Amigos'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        onPressed: () {
          _showRemoveFriendDialog();
        },
      );
    } else if (_hasPendingSentRequest) {
      return ElevatedButton.icon(
        icon: Icon(Icons.hourglass_top),
        label: Text('Cancelar solicitud'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        onPressed: () {
          if (_pendingRequestId != null) {
            ref.read(friendControllerProvider.notifier).cancelFriendRequest(_pendingRequestId!);
            setState(() {
              _hasPendingSentRequest = false;
              _pendingRequestId = null;
            });
          }
        },
      );
    } else if (_hasPendingReceivedRequest) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ElevatedButton.icon(
            icon: Icon(Icons.check),
            label: Text('Aceptar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            onPressed: () {
              if (_pendingRequestId != null) {
                ref.read(friendControllerProvider.notifier).acceptFriendRequest(_pendingRequestId!);
                setState(() {
                  _hasPendingReceivedRequest = false;
                  _pendingRequestId = null;
                  _isFriend = true;
                });
              }
            },
          ),
          SizedBox(width: 12),
          ElevatedButton.icon(
            icon: Icon(Icons.close),
            label: Text('Rechazar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            onPressed: () {
              if (_pendingRequestId != null) {
                ref.read(friendControllerProvider.notifier).rejectFriendRequest(_pendingRequestId!);
                setState(() {
                  _hasPendingReceivedRequest = false;
                  _pendingRequestId = null;
                });
              }
            },
          ),
        ],
      );
    } else {
      return ElevatedButton.icon(
        icon: Icon(Icons.person_add),
        label: Text('Enviar solicitud de amistad'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        onPressed: () {
          ref.read(friendControllerProvider.notifier).sendFriendRequest(widget.userId);
          setState(() {
            _hasPendingSentRequest = true;
          });
        },
      );
    }
  }

  void _showRemoveFriendDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.blueGrey.shade800,
        title: Text(
          'Eliminar amigo',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          '¿Estás seguro de que quieres eliminar a ${_userProfile!.username} de tu lista de amigos?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(friendControllerProvider.notifier).removeFriend(widget.userId);
              setState(() {
                _isFriend = false;
              });
            },
            child: Text(
              'Eliminar',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
