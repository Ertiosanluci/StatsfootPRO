import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:statsfoota/features/friends/presentation/controllers/friend_controller.dart';
import 'package:statsfoota/features/friends/presentation/screens/friends_main_screen.dart';
import 'package:statsfoota/features/friends/presentation/screens/friend_requests_screen.dart';
import 'package:statsfoota/features/friends/presentation/screens/people_screen.dart';
import 'package:statsfoota/features/friends/presentation/screens/user_profile_screen.dart';
import 'package:statsfoota/features/friends/presentation/widgets/friend_request_badge.dart';

/// A module that provides all the components for the friends system
class FriendsModule {
  /// Returns the count of pending friend requests
  static int getPendingRequestCount(BuildContext context) {
    final container = ProviderScope.containerOf(context);
    return container.read(friendControllerProvider).pendingReceivedRequests.length;
  }
  
  /// Main screen for the friends feature that includes:
  /// - People list (all users)
  /// - Friends list
  /// - Friend requests
  static Widget mainScreen() {
    return const FriendsMainScreen();
  }
  
  /// Screen for viewing all people in the app
  static Widget peopleScreen() {
    return const PeopleScreen();
  }
  
  /// Screen for viewing pending friend requests
  static Widget friendRequestsScreen() {
    return const FriendRequestsScreen();
  }
  
  /// Navigates to the user profile screen
  static void navigateToUserProfile(BuildContext context, String userId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserProfileScreen(userId: userId),
      ),
    );
  }
  
  /// Widget that adds a badge notification for friend requests
  static Widget addFriendRequestBadge({
    required Widget child,
    Color badgeColor = Colors.red,
  }) {
    return FriendRequestBadge(
      child: child,
      badgeColor: badgeColor,
    );
  }
  
  /// Initialize friend system data
  static Future<void> initialize(WidgetRef ref) async {
    await ref.read(friendControllerProvider.notifier).loadFriends();
    await ref.read(friendControllerProvider.notifier).loadPendingRequests();
  }
  
  /// Check if a user is a friend
  static bool isFriend(WidgetRef ref, String userId) {
    final friends = ref.read(friendControllerProvider).friends;
    return friends.any((friend) => friend.id == userId);
  }
  
  /// Register routes for the friends feature
  static Map<String, WidgetBuilder> getRoutes() {
    return {
      '/friends': (context) => const FriendsMainScreen(),
      '/people': (context) => const PeopleScreen(),
      '/friend_requests': (context) => const FriendRequestsScreen(),
    };
  }
}
