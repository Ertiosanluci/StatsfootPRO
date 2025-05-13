import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:statsfoota/features/friends/domain/models/user_profile.dart'; // Add import for UserProfile
import 'package:statsfoota/features/friends/presentation/controllers/friend_controller.dart';

class NotificationsDrawer extends ConsumerWidget {
  const NotificationsDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Obtenemos el estado de las solicitudes de amistad
    final state = ref.watch(friendControllerProvider);
    final pendingRequests = state.pendingReceivedRequests;
    final sentRequests = state.pendingSentRequests;
    
    // Verifica si no hay solicitudes (para mostrar bandeja vacía)
    final bool isEmpty = pendingRequests.isEmpty && sentRequests.isEmpty;
    
    return Drawer(
      backgroundColor: Colors.white,
      elevation: 10,
      width: MediaQuery.of(context).size.width * 0.85,
      child: Column(
        children: [
          // Cabecera del drawer
          Container(
            padding: EdgeInsets.fromLTRB(20, 50, 20, 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.blue.shade800,
                  Colors.blue.shade600,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.notifications,
                      color: Colors.white,
                      size: 28,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Notificaciones',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Spacer(),
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                SizedBox(height: 5),
                Text(
                  'Mantente al día con tus solicitudes y actividades',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          // Contenido del drawer
          Expanded(
            child: isEmpty 
              ? _buildEmptyState() 
              : _buildNotificationsList(context, pendingRequests, sentRequests, ref),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          SizedBox(height: 20),
          Text(
            'Bandeja de Entrada Vacía',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'No tienes notificaciones pendientes en este momento.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList(
    BuildContext context,
    List pendingRequests,
    List sentRequests,
    WidgetRef ref,
  ) {
    return ListView(
      padding: EdgeInsets.all(0),
      children: [
        // Sección de solicitudes recibidas
        if (pendingRequests.isNotEmpty) ...[
          _buildSectionHeader('Solicitudes Recibidas'),
          ...pendingRequests.map((request) => _buildFriendRequestItem(
                context,
                request,
                isReceived: true,
                ref: ref,
              )),
        ],

        // Sección de solicitudes enviadas
        if (sentRequests.isNotEmpty) ...[
          _buildSectionHeader('Solicitudes Enviadas'),
          ...sentRequests.map((request) => _buildFriendRequestItem(
                context,
                request,
                isReceived: false,
                ref: ref,
              )),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      color: Colors.grey.shade100,
      child: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade800,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildFriendRequestItem(
    BuildContext context,
    dynamic request,
    {required bool isReceived,
    required WidgetRef ref}
  ) {
    // Since request is a FriendRequest object, we need to get the user's profile
    // Get the user ID of the other person (not the current user)
    final String otherId = isReceived ? request.userId1 : request.userId2;
    
    return FutureBuilder<UserProfile>(
      // Fetch the user profile information for this request
      future: ref.read(friendControllerProvider.notifier).getUserProfile(otherId),
      builder: (context, AsyncSnapshot<UserProfile> snapshot) {
        // Default values in case the profile fetch hasn't completed yet
        String userName = 'Usuario';
        String? avatarUrl;
        
        // If we have successfully fetched the profile
        if (snapshot.connectionState == ConnectionState.done && 
            snapshot.hasData && 
            snapshot.data != null) {
          // Get user data from the profile
          UserProfile profile = snapshot.data!;
          userName = profile.username;
          avatarUrl = profile.avatarUrl;
        }

        return Container(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Row(
            children: [
              // Avatar del usuario
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blue.shade100,
                  image: avatarUrl != null
                      ? DecorationImage(
                          image: NetworkImage(avatarUrl),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: avatarUrl == null
                    ? Icon(Icons.person, color: Colors.blue.shade800)
                    : null,
              ),
              SizedBox(width: 15),
              
              // Información y botones
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      isReceived 
                          ? 'Te ha enviado una solicitud de amistad' 
                          : 'Has enviado una solicitud de amistad',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                    SizedBox(height: 8),
                    
                    // Botones de acción según el tipo de solicitud
                    if (isReceived)
                      Row(
                        children: [
                          _buildActionButton(
                            label: 'Aceptar',
                            color: Colors.green,
                            onPressed: () {
                              // Aceptar solicitud
                              final friendController = ref.read(friendControllerProvider.notifier);
                              friendController.acceptFriendRequest(request.id);
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Solicitud aceptada'))
                              );
                            },
                          ),
                          SizedBox(width: 10),
                          _buildActionButton(
                            label: 'Rechazar',
                            color: Colors.red,
                            onPressed: () {
                              // Rechazar solicitud
                              final friendController = ref.read(friendControllerProvider.notifier);
                              friendController.rejectFriendRequest(request.id);
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Solicitud rechazada'))
                              );
                            },
                          ),
                        ],
                      )
                    else
                      _buildActionButton(
                        label: 'Cancelar solicitud',
                        color: Colors.orange,
                        onPressed: () {
                          // Cancelar solicitud enviada
                          final friendController = ref.read(friendControllerProvider.notifier);
                          friendController.cancelFriendRequest(request.id);
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Solicitud cancelada'))
                          );
                        },
                        isFullWidth: true,
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionButton({
    required String label,
    required Color color,
    required VoidCallback onPressed,
    bool isFullWidth = false,
  }) {
    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      height: 30,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: EdgeInsets.symmetric(horizontal: 10),
          textStyle: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: Text(label),
      ),
    );
  }
}