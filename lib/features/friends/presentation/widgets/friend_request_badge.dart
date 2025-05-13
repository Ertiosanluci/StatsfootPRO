import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:statsfoota/features/friends/presentation/controllers/friend_controller.dart';
import 'package:statsfoota/features/friends/presentation/screens/friend_requests_screen.dart';

class FriendRequestBadge extends ConsumerWidget {
  final Widget child;
  final Color badgeColor;
  
  const FriendRequestBadge({
    Key? key,
    required this.child,
    this.badgeColor = Colors.red,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(friendControllerProvider);
    final int pendingRequestsCount = state.pendingReceivedRequests.length;
    
    if (pendingRequestsCount == 0) {
      return child;
    }
    
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          top: -5,
          right: -5,
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FriendRequestsScreen(),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: badgeColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              constraints: const BoxConstraints(
                minWidth: 18,
                minHeight: 18,
              ),
              child: Text(
                pendingRequestsCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
