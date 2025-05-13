import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:statsfoota/features/friends/domain/models/user_profile.dart';
import 'package:statsfoota/features/friends/presentation/controllers/friend_controller.dart';
import 'package:statsfoota/features/notifications/domain/models/notification_model.dart';
import 'package:statsfoota/features/notifications/presentation/controllers/notification_controller.dart';

class NotificationsDrawer extends ConsumerStatefulWidget {
  const NotificationsDrawer({Key? key}) : super(key: key);

  @override
  ConsumerState<NotificationsDrawer> createState() => _NotificationsDrawerState();
}

class _NotificationsDrawerState extends ConsumerState<NotificationsDrawer> {
  @override
  void initState() {
    super.initState();
    // Load both friend requests and notifications when drawer opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationControllerProvider.notifier).loadNotifications();
    });
  }
  
  @override
  Widget build(BuildContext context) {
    // Get both friend requests and notification data
    final friendState = ref.watch(friendControllerProvider);
    final notificationState = ref.watch(notificationControllerProvider);
    
    final pendingRequests = friendState.pendingReceivedRequests;
    final sentRequests = friendState.pendingSentRequests;
    final notifications = notificationState.notifications;
    
    // Check if there's content to display
    final bool isEmpty = pendingRequests.isEmpty && 
                        sentRequests.isEmpty && 
                        notifications.isEmpty;
    
    final bool isLoading = friendState.isLoading || notificationState.isLoading;
    
    return Drawer(
      backgroundColor: Colors.white,
      elevation: 10,
      width: MediaQuery.of(context).size.width * 0.85,
      child: Column(
        children: [
          // Drawer header
          _buildHeader(),
          
          // Drawer content
          if (isLoading)
            Expanded(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          else
            Expanded(
              child: isEmpty 
                ? _buildEmptyState() 
                : _buildNotificationsList(
                    context,
                    pendingRequests,
                    sentRequests,
                    notifications,
                  ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildHeader() {
    return Container(
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
    List<NotificationModel> notifications,
  ) {
    return ListView(
      padding: EdgeInsets.all(0),
      children: [
        // Friend requests section
        if (pendingRequests.isNotEmpty) ...[
          _buildSectionHeader('Solicitudes Recibidas'),
          ...pendingRequests.map((request) => _buildFriendRequestItem(
                context,
                request,
                isReceived: true,
              )),
        ],

        // Sent requests section
        if (sentRequests.isNotEmpty) ...[
          _buildSectionHeader('Solicitudes Enviadas'),
          ...sentRequests.map((request) => _buildFriendRequestItem(
                context,
                request,
                isReceived: false,
              )),
        ],
        
        // Regular notifications section
        if (notifications.isNotEmpty) ...[
          _buildSectionHeader('Notificaciones'),
          ...notifications.map((notification) => _buildNotificationItem(context, notification)),
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
  
  Widget _buildNotificationItem(BuildContext context, NotificationModel notification) {
    // Mark notification as read when viewed
    if (!notification.isRead) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(notificationControllerProvider.notifier).markAsRead(notification.id);
      });
    }
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: notification.isRead ? Colors.white : Colors.blue.shade50,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          // Notification icon
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.blue.shade100,
            ),
            child: Icon(
              _getNotificationIcon(notification.type),
              color: Colors.blue.shade800,
              size: 28,
            ),
          ),
          SizedBox(width: 15),
          
          // Notification content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification.title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  notification.message,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  _formatNotificationTime(notification.createdAt),
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          
          // Delete button
          IconButton(
            icon: Icon(Icons.close, color: Colors.grey.shade400, size: 18),
            onPressed: () {
              ref.read(notificationControllerProvider.notifier).deleteNotification(notification.id);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFriendRequestItem(
    BuildContext context,
    dynamic request,
    {required bool isReceived}
  ) {
    // Get the user ID of the other person
    final String otherId = isReceived ? request.userId1 : request.userId2;
    
    return FutureBuilder<UserProfile>(
      future: ref.read(friendControllerProvider.notifier).getUserProfile(otherId),
      builder: (context, AsyncSnapshot<UserProfile> snapshot) {
        // Default values until profile loads
        String userName = 'Usuario';
        String? avatarUrl;
        
        if (snapshot.connectionState == ConnectionState.done && 
            snapshot.hasData && 
            snapshot.data != null) {
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
              // User avatar
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
              
              // Request info and buttons
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
                    
                    // Action buttons
                    if (isReceived)
                      Row(
                        children: [
                          _buildActionButton(
                            label: 'Aceptar',
                            color: Colors.green,
                            onPressed: () {
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
  
  // Helper method to get appropriate icon for notification type
  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.friendRequest:
        return Icons.person_add;
      case NotificationType.friendAccepted:
        return Icons.people;
      case NotificationType.matchInvite:
        return Icons.sports_soccer;
      case NotificationType.systemNotice:
        return Icons.info;
      default:
        return Icons.notifications;
    }
  }
  
  // Format notification timestamp
  String _formatNotificationTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'día' : 'días'} atrás';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hora' : 'horas'} atrás';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minuto' : 'minutos'} atrás';
    } else {
      return 'Ahora mismo';
    }
  }
}