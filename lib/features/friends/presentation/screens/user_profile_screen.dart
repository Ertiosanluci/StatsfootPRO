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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Perfil',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF0D47A1),  // Azul más oscuro (coincide con el splash)
              Color(0xFF1565C0),  // Azul oscuro
              Color(0xFF1976D2),  // Azul medio
              Color(0xFF1E88E5),  // Azul claro
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
            )
          : _error != null
              ? _buildErrorView()
              : _userProfile == null
                  ? _buildNotFoundView()
                  : _buildProfile(),
      ),
    );
  }
  
  Widget _buildErrorView() {
    return Center(
      child: Container(
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade300, size: 70),
            SizedBox(height: 16),
            Text(
              'Error al cargar perfil',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              _error?.toString() ?? 'Ha ocurrido un error inesperado',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
            ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadUserProfile,
              icon: Icon(Icons.refresh),
              label: Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 4,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildNotFoundView() {
    return Center(
      child: Container(
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_off, color: Colors.white.withOpacity(0.7), size: 70),
            SizedBox(height: 16),
            Text(
              'Usuario no encontrado',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfile() {
    final profile = _userProfile!;
    
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        physics: BouncingScrollPhysics(),
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
                    child: Container(
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 10,
                            spreadRadius: 2,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
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
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 5,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                              )
                            : null,
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  
                  // Username
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      profile.username,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 24),
                  
                  // Friend status button
                  _buildFriendActionButton(),
                  SizedBox(height: 30),
                ],
              ),
            ),

            // Profile details
            Card(
              color: Colors.white.withOpacity(0.1),
              elevation: 6,
              shadowColor: Colors.black.withOpacity(0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader('Información del Perfil'),
                    SizedBox(height: 16),
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
                color: Colors.white.withOpacity(0.1),
                elevation: 6,
                shadowColor: Colors.black.withOpacity(0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader('Descripción'),
                      SizedBox(height: 16),
                      Text(
                        profile.description!,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.85),
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
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
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blue.shade800.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon, 
              color: Colors.white,
              size: 22,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.7),
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
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      color: Colors.white.withOpacity(0.2),
      height: 20,
    );
  }

  Widget _buildFriendActionButton() {
    if (_isFriend) {
      return ElevatedButton.icon(
        icon: Icon(Icons.check_circle),
        label: Text('Amigos'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green.shade600,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 5,
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
          backgroundColor: Colors.orange.shade600,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 5,
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
              backgroundColor: Colors.green.shade600,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 5,
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
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 5,
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
          backgroundColor: Colors.blue.shade600,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 5,
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
        backgroundColor: Colors.blue.shade800,
        elevation: 24,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
        title: Text(
          'Eliminar amigo',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          '¿Estás seguro de que quieres eliminar a ${_userProfile!.username} de tu lista de amigos?',
          style: TextStyle(color: Colors.white.withOpacity(0.9)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white.withOpacity(0.8),
            ),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(friendControllerProvider.notifier).removeFriend(widget.userId);
              setState(() {
                _isFriend = false;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}
