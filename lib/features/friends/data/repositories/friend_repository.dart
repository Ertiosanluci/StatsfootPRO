import 'dart:math' as math;
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
        throw Exception('User not authenticated');
      }
      
      // Retry mechanism for better reliability
      int maxRetries = 3;
      List<dynamic> response = [];
      Exception? lastError;
      
      for (int attempt = 1; attempt <= maxRetries; attempt++) {
        try {
          // Modify the query to ensure we're getting all profile fields
          var query = _supabaseClient
              .from('profiles')
              .select('*')  // Explicitly select all fields
              .neq('id', currentUserId);

          if (searchQuery != null && searchQuery.isNotEmpty) {
            query = query.ilike('username', '%$searchQuery%');
          }

          print('FriendRepository: Executing query, attempt $attempt of $maxRetries...');
          response = await query;
          
          // Si llegamos aquí, la consulta fue exitosa
          lastError = null;
          break;
        } catch (e) {
          lastError = Exception('Error al obtener usuarios: $e');
          print('FriendRepository: Error on attempt $attempt: $e');
          
          // Esperar antes de reintentar, con aumento exponencial
          if (attempt < maxRetries) {
            await Future.delayed(Duration(milliseconds: 200 * attempt));
          }
        }
      }
      
      // Si después de todos los intentos seguimos teniendo un error
      if (lastError != null) {
        throw lastError;
      }
      
      print('FriendRepository: Got ${response.length} users with raw data: ${response.toString().substring(0, math.min(100, response.toString().length))}...');
      
      // Transform the response into UserProfile objects with more explicit error handling
      List<UserProfile> users = [];
      for (var json in response) {
        try {
          users.add(UserProfile.fromJson(json));
        } catch (e) {
          print('Error parsing user profile: $e for data: $json');
        }
      }
      
      print('FriendRepository: Successfully parsed ${users.length} UserProfile objects');
      return users;
    } catch (e) {
      print('FriendRepository ERROR: Failed to get all users: $e');
      // Return an empty list instead of throwing to prevent breaking the UI
      return [];
    }
  }

  Future<void> sendFriendRequest(String receiverId) async {
    try {
      print('FriendRepository: Sending friend request to user ID: $receiverId');
      
      final currentUserId = _supabaseClient.auth.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // Verificar si el receiverId existe en la tabla 'profiles'
      final receiverExists = await _supabaseClient
          .from('profiles')
          .select('id')
          .eq('id', receiverId)
          .maybeSingle();
          
      if (receiverExists == null) {
        print('FriendRepository: Receiver ID $receiverId does not exist');
        throw Exception('El usuario destinatario no existe');
      }

      // Check if there's already a request between these users
      final existingRequest = await _supabaseClient
          .from('friends')
          .select()
          .or('and(user_id_1.eq.$currentUserId,user_id_2.eq.$receiverId),and(user_id_1.eq.$receiverId,user_id_2.eq.$currentUserId)')
          .maybeSingle();

      if (existingRequest != null) {
        print('FriendRepository: Friend request already exists between users $currentUserId and $receiverId');
        throw Exception('Ya existe una solicitud de amistad entre estos usuarios');
      }

      // Get sender's name to include in the notification
      final senderProfile = await _supabaseClient
          .from('profiles')
          .select('username')
          .eq('id', currentUserId)
          .maybeSingle();
      
      final senderName = (senderProfile != null ? senderProfile['username'] : null) as String? ?? 'Usuario';
      
      print('FriendRepository: Creating friend request from $senderName (ID: $currentUserId) to userId: $receiverId');

      try {
        // Create new friend request with better error handling
        final response = await _supabaseClient.from('friends').insert({
          'user_id_1': currentUserId,
          'user_id_2': receiverId,
          'status': 'pending',
        }).select();

        print('FriendRepository: Friend request created successfully: ${response.length} records');
        
        if (response.isNotEmpty) {
          // Create a notification for the receiver
          String requestId;
          try {
            requestId = response[0]['id'] as String;
          } catch (e) {
            print('FriendRepository: Error extracting request ID: $e');
            requestId = DateTime.now().millisecondsSinceEpoch.toString(); // Fallback ID
          }
          
          try {
            // Create notification with better error handling
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
            
            print('FriendRepository: Notification created successfully');
          } catch (notifError) {
            // No interrumpir el flujo principal si falla la notificación
            print('FriendRepository: Failed to create notification: $notifError');
            // La solicitud de amistad ya se creó, así que no lanzamos excepción
          }
        }
      } catch (insertError) {
        print('FriendRepository: Error inserting friend request: $insertError');
        
        // Verificar si el error es por una constraint violation (duplicado)
        if (insertError.toString().contains('duplicate') || 
            insertError.toString().contains('unique constraint') ||
            insertError.toString().contains('already exists')) {
          throw Exception('Ya existe una solicitud de amistad con este usuario');
        } else {
          throw Exception('No se pudo enviar la solicitud de amistad: ${insertError.toString()}');
        }
      }
    } catch (e) {
      print('Error sending friend request: $e');
      throw Exception('No se pudo enviar la solicitud de amistad: ${e.toString()}');
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
      print('Fetching profile for user ID: $userId');
      final response = await _supabaseClient
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle(); // Uso de maybeSingle en lugar de single para no lanzar error si no existe
      
      if (response == null) {
        print('No profile found for user ID: $userId');
        // Devolver un perfil básico con el ID y un nombre de usuario predeterminado
        return UserProfile(
          id: userId,
          username: 'Usuario',
        );
      }
      
      // Calcular edad a partir de la fecha de nacimiento si está disponible
      int? age;
      if (response['birthdate'] != null && response['birthdate'] != '') {
        try {
          final birthDate = DateTime.parse(response['birthdate']);
          final today = DateTime.now();
          age = today.year - birthDate.year;
          // Ajustar la edad si aún no ha sido el cumpleaños este año
          if (today.month < birthDate.month || 
              (today.month == birthDate.month && today.day < birthDate.day)) {
            age--;
          }
        } catch (e) {
          print('Error calculando la edad: $e');
        }
      }
      
      // Crear perfil con los campos correctamente mapeados
      return UserProfile(
        id: response['id'] as String,
        username: response['username'] as String,
        avatarUrl: response['avatar_url'] as String?,
        age: age,
        gender: response['gender'] as String?,
        fieldPosition: response['position'] as String?, // Mapear 'position' a 'fieldPosition'
        playFrequency: response['frequency'] as String?, // Mapear 'frequency' a 'playFrequency'
        skillLevel: response['level'] as String?, // Mapear 'level' a 'skillLevel'
        description: response['description'] as String?,
      );
    } catch (e) {
      print('Error al obtener perfil de usuario: $e');
      throw Exception('Failed to get user profile: $e');
    }
  }
}
