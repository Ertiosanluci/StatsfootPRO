import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../features/notifications/domain/models/notification_model.dart';
import '../../domain/models/friend_request.dart';
import '../../domain/models/user_profile.dart';

class FriendRepository {
  final SupabaseClient _supabaseClient;

  FriendRepository({
    required SupabaseClient supabaseClient,
  }) : _supabaseClient = supabaseClient;

  Future<List<FriendRequest>> getFriendRequests() async {
    try {
      final currentUserId = _supabaseClient.auth.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final response = await _supabaseClient
          .from('friends')
          .select()
          .or('user_id_1.eq.$currentUserId,user_id_2.eq.$currentUserId');

      return response.map((json) => FriendRequest.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get friend requests: $e');
    }
  }

  Future<List<FriendRequest>> getPendingReceivedRequests() async {
    try {
      final currentUserId = _supabaseClient.auth.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final response = await _supabaseClient
          .from('friends')
          .select()
          .eq('status', 'pending')
          .eq('user_id_2', currentUserId);

      return response.map((json) => FriendRequest.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get pending received requests: $e');
    }
  }

  Future<List<FriendRequest>> getPendingSentRequests() async {
    try {
      final currentUserId = _supabaseClient.auth.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final response = await _supabaseClient
          .from('friends')
          .select()
          .eq('status', 'pending')
          .eq('user_id_1', currentUserId);

      return response.map((json) => FriendRequest.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get pending sent requests: $e');
    }
  }

  Future<List<UserProfile>> getFriends() async {
    try {
      final currentUserId = _supabaseClient.auth.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // Get friend relationships where current user is user_id_1
      final friends1Response = await _supabaseClient
          .from('friends')
          .select('user_id_2')
          .eq('status', 'accepted')
          .eq('user_id_1', currentUserId);

      // Get friend relationships where current user is user_id_2
      final friends2Response = await _supabaseClient
          .from('friends')
          .select('user_id_1')
          .eq('status', 'accepted')
          .eq('user_id_2', currentUserId);

      // Extract user IDs
      final List<String> friendIds = [
        ...friends1Response.map((item) => item['user_id_2'] as String),
        ...friends2Response.map((item) => item['user_id_1'] as String),
      ];

      if (friendIds.isEmpty) {
        return [];
      }

      // Get user profiles for all friends
      final profiles = await _supabaseClient
          .from('profiles')
          .select()
          .filter('id', 'in', friendIds);

      return profiles.map((json) => UserProfile.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get friends: $e');
    }
  }

  Future<List<UserProfile>> getAllUsers({String? searchQuery}) async {
    try {
      final currentUserId = _supabaseClient.auth.currentUser?.id;
      if (currentUserId == null) {
        print('FriendRepository: User not authenticated');
        throw Exception('User not authenticated');
      }

      print('FriendRepository: Fetching users with query: $searchQuery');
      
      var query = _supabaseClient
          .from('profiles')
          .select()
          .neq('id', currentUserId);

      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.ilike('username', '%$searchQuery%');
      }

      print('FriendRepository: Executing query...');
      final response = await query;
      print('FriendRepository: Got ${response.length} users');
      
      return response.map((json) => UserProfile.fromJson(json)).toList();
    } catch (e) {
      print('FriendRepository ERROR: Failed to get all users: $e');
      throw Exception('Failed to get all users: $e');
    }
  }

  Future<void> sendFriendRequest(String receiverId) async {
    try {
      final currentUserId = _supabaseClient.auth.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // Check if there's already a request between these users
      final existingRequest = await _supabaseClient
          .from('friends')
          .select()
          .or('and(user_id_1.eq.$currentUserId,user_id_2.eq.$receiverId),and(user_id_1.eq.$receiverId,user_id_2.eq.$currentUserId)');

      if (existingRequest.isNotEmpty) {
        throw Exception('A friend request already exists between these users');
      }

      // Get sender's name to include in the notification
      final senderProfile = await _supabaseClient
          .from('profiles')
          .select('username')
          .eq('id', currentUserId)
          .single();
      
      final senderName = senderProfile['username'] as String? ?? 'Usuario';

      // Create new friend request
      final response = await _supabaseClient.from('friends').insert({
        'user_id_1': currentUserId,
        'user_id_2': receiverId,
        'status': 'pending',
      }).select();

      if (response.isNotEmpty) {
        // Create a notification for the receiver
        final requestId = response[0]['id'] as String;
        
        await _supabaseClient.from('notifications').insert({
          'id': DateTime.now().millisecondsSinceEpoch.toString(),
          'user_id': receiverId,
          'sender_id': currentUserId,
          'type': 'friend_request',
          'title': 'Nueva solicitud de amistad',
          'message': '$senderName te ha enviado una solicitud de amistad',
          'resource_id': requestId,
          'created_at': DateTime.now().toIso8601String(),
          'is_read': false,
        });
      }
    } catch (e) {
      print('Error sending friend request: $e');
      throw Exception('Failed to send friend request: $e');
    }
  }

  Future<void> acceptFriendRequest(String requestId) async {
    try {
      final currentUserId = _supabaseClient.auth.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // Verify the request is directed to the current user
      final response = await _supabaseClient
          .from('friends')
          .select('user_id_1, user_id_2')
          .eq('id', requestId)
          .eq('user_id_2', currentUserId)
          .eq('status', 'pending')
          .single();

      if (response == null) {
        throw Exception('Friend request not found or not eligible for acceptance');
      }

      final senderId = response['user_id_1'] as String;

      // Get current user's name
      final currentUserProfile = await _supabaseClient
          .from('profiles')
          .select('username')
          .eq('id', currentUserId)
          .single();
      
      final currentUserName = currentUserProfile['username'] as String? ?? 'Usuario';

      // Update the request status to accepted
      await _supabaseClient
          .from('friends')
          .update({'status': 'accepted'})
          .eq('id', requestId);

      // Create notification for the original sender
      await _supabaseClient.from('notifications').insert({
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'user_id': senderId,
        'sender_id': currentUserId,
        'type': 'friend_accepted',
        'title': 'Solicitud aceptada',
        'message': '$currentUserName ha aceptado tu solicitud de amistad',
        'created_at': DateTime.now().toIso8601String(),
        'is_read': false,
      });
    } catch (e) {
      print('Error accepting friend request: $e');
      throw Exception('Failed to accept friend request: $e');
    }
  }

  Future<void> rejectFriendRequest(String requestId) async {
    try {
      final currentUserId = _supabaseClient.auth.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // Verify the request is directed to the current user
      final response = await _supabaseClient
          .from('friends')
          .select()
          .eq('id', requestId)
          .eq('user_id_2', currentUserId)
          .eq('status', 'pending');

      if (response.isEmpty) {
        throw Exception('Friend request not found or not eligible for rejection');
      }

      // Delete the friend request
      await _supabaseClient
          .from('friends')
          .delete()
          .eq('id', requestId);
    } catch (e) {
      throw Exception('Failed to reject friend request: $e');
    }
  }

  Future<void> cancelFriendRequest(String requestId) async {
    try {
      final currentUserId = _supabaseClient.auth.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // Verify the request was sent by the current user
      final response = await _supabaseClient
          .from('friends')
          .select()
          .eq('id', requestId)
          .eq('user_id_1', currentUserId)
          .eq('status', 'pending');

      if (response.isEmpty) {
        throw Exception('Friend request not found or not eligible for cancellation');
      }

      // Delete the friend request
      await _supabaseClient
          .from('friends')
          .delete()
          .eq('id', requestId);
    } catch (e) {
      throw Exception('Failed to cancel friend request: $e');
    }
  }

  Future<void> removeFriend(String friendId) async {
    try {
      final currentUserId = _supabaseClient.auth.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // Delete the friendship from both directions
      await _supabaseClient
          .from('friends')
          .delete()
          .or('and(user_id_1.eq.$currentUserId,user_id_2.eq.$friendId),and(user_id_1.eq.$friendId,user_id_2.eq.$currentUserId)');
    } catch (e) {
      throw Exception('Failed to remove friend: $e');
    }
  }
  
  Future<UserProfile> getUserProfile(String userId) async {
    try {
      final response = await _supabaseClient
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();
      
      return UserProfile.fromJson(response);
    } catch (e) {
      throw Exception('Failed to get user profile: $e');
    }
  }
}
