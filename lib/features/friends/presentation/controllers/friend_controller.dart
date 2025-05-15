import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/repositories/friend_repository.dart';
import '../../domain/models/user_profile.dart';
import '../state/friend_state.dart';

final friendRepositoryProvider = Provider<FriendRepository>((ref) {
  return FriendRepository(supabaseClient: Supabase.instance.client);
});

// Modificamos el provider para evitar cualquier carga automática
final friendControllerProvider = StateNotifierProvider<FriendController, FriendState>((ref) {
  final friendRepository = ref.watch(friendRepositoryProvider);
  return FriendController(friendRepository: friendRepository);
});

class FriendController extends StateNotifier<FriendState> {
  final FriendRepository _friendRepository;

  FriendController({required FriendRepository friendRepository})
      : _friendRepository = friendRepository,
        super(FriendState.initial());

  // Esta función segura para cargar datos no modifica el estado inmediatamente
  Future<void> loadFriends() async {
    // Manejo seguro de estado para evitar excepciones durante la construcción
    try {
      // Importante: este await permite que cualquier ciclo de construcción termine primero
      await Future.delayed(Duration.zero);
      
      // Ahora podemos actualizar el estado de manera segura
      if (mounted) {
        state = state.copyWith(isLoading: true, errorMessage: null);
        
        final friends = await _friendRepository.getFriends();
        
        if (mounted) {
          state = state.copyWith(friends: friends, isLoading: false);
        }
      }
    } catch (e) {
      print('Error loading friends: $e');
      if (mounted) {
        state = state.copyWith(errorMessage: e.toString(), isLoading: false);
      }
    }
  }

  Future<void> loadAllUsers({String? searchQuery}) async {
    try {
      print('FriendController: loadAllUsers called with query: $searchQuery');
      
      // Espera a que cualquier ciclo de construcción termine
      await Future.delayed(Duration.zero);
      
      if (mounted) {
        // Preservamos la búsqueda anterior si no se proporciona una nueva
        final effectiveQuery = searchQuery ?? state.searchQuery;
        
        state = state.copyWith(isLoading: true, errorMessage: null, searchQuery: effectiveQuery);
        
        print('FriendController: Calling repository getAllUsers');
        final users = await _friendRepository.getAllUsers(searchQuery: effectiveQuery);
        print('FriendController: Got ${users.length} users from repository');
        
        if (mounted) {
          state = state.copyWith(allUsers: users, isLoading: false);
        }
      }
    } catch (e) {
      print('FriendController ERROR: ${e.toString()}');
      if (mounted) {
        // En caso de error, mantenemos la lista de usuarios anterior
        // para evitar una pantalla vacía y solo actualizamos el estado de error
        state = state.copyWith(
          errorMessage: e.toString(), 
          isLoading: false,
          // No actualizamos allUsers para preservar los datos anteriores
        );
      }
    }
  }

  Future<void> loadPendingRequests() async {
    try {
      // Esperar hasta que termine cualquier ciclo de construcción
      await Future.delayed(Duration.zero);
      
      if (mounted) {
        state = state.copyWith(isLoading: true, errorMessage: null);
        
        final sentRequests = await _friendRepository.getPendingSentRequests();
        final receivedRequests = await _friendRepository.getPendingReceivedRequests();
        
        print('Loaded ${receivedRequests.length} pending received requests');
        print('Loaded ${sentRequests.length} pending sent requests');
        
        if (mounted) {
          state = state.copyWith(
            pendingSentRequests: sentRequests,
            pendingReceivedRequests: receivedRequests,
            isLoading: false,
          );
        }
      }
    } catch (e) {
      print('Error loading pending requests: $e');
      if (mounted) {
        state = state.copyWith(errorMessage: e.toString(), isLoading: false);
      }
    }
  }

  // Todos los métodos ahora siguen el mismo patrón seguro
  
  Future<void> sendFriendRequest(String receiverId) async {
    try {
      await Future.delayed(Duration.zero);
      
      if (mounted) {
        state = state.copyWith(isLoading: true, errorMessage: null);
        
        await _friendRepository.sendFriendRequest(receiverId);
        
        if (mounted) {
          // Recargamos las solicitudes pendientes
          await loadPendingRequests();
          
          // Actualizamos también la lista de usuarios
          await loadAllUsers(searchQuery: state.searchQuery);
        }
      }
    } catch (e) {
      print('Error sending friend request: $e');
      if (mounted) {
        // Mantenemos la UI actualizada a pesar del error
        state = state.copyWith(errorMessage: e.toString(), isLoading: false);
        
        // Importante: recargar la lista de usuarios incluso después de un error
        try {
          await loadAllUsers(searchQuery: state.searchQuery);
        } catch (_) {
          // Ignoramos errores secundarios para evitar cascadas
        }
      }
    }
  }

  Future<void> acceptFriendRequest(String requestId) async {
    try {
      await Future.delayed(Duration.zero);
      
      if (mounted) {
        state = state.copyWith(isLoading: true, errorMessage: null);
        
        await _friendRepository.acceptFriendRequest(requestId);
        
        if (mounted) {
          await loadPendingRequests();
          await loadFriends();
        }
      }
    } catch (e) {
      print('Error accepting friend request: $e');
      if (mounted) {
        state = state.copyWith(errorMessage: e.toString(), isLoading: false);
      }
    }
  }

  Future<void> rejectFriendRequest(String requestId) async {
    try {
      await Future.delayed(Duration.zero);
      
      if (mounted) {
        state = state.copyWith(isLoading: true, errorMessage: null);
        
        await _friendRepository.rejectFriendRequest(requestId);
        
        if (mounted) {
          await loadPendingRequests();
        }
      }
    } catch (e) {
      print('Error rejecting friend request: $e');
      if (mounted) {
        state = state.copyWith(errorMessage: e.toString(), isLoading: false);
      }
    }
  }

  Future<void> cancelFriendRequest(String requestId) async {
    try {
      await Future.delayed(Duration.zero);
      
      if (mounted) {
        state = state.copyWith(isLoading: true, errorMessage: null);
        
        await _friendRepository.cancelFriendRequest(requestId);
        
        if (mounted) {
          await loadPendingRequests();
        }
      }
    } catch (e) {
      print('Error canceling friend request: $e');
      if (mounted) {
        state = state.copyWith(errorMessage: e.toString(), isLoading: false);
      }
    }
  }

  Future<void> removeFriend(String friendId) async {
    try {
      await Future.delayed(Duration.zero);
      
      if (mounted) {
        state = state.copyWith(isLoading: true, errorMessage: null);
        
        await _friendRepository.removeFriend(friendId);
        
        if (mounted) {
          await loadFriends();
        }
      }
    } catch (e) {
      print('Error removing friend: $e');
      if (mounted) {
        state = state.copyWith(errorMessage: e.toString(), isLoading: false);
      }
    }
  }

  Future<UserProfile> getUserProfile(String userId) async {
    try {
      return await _friendRepository.getUserProfile(userId);
    } catch (e) {
      print('Error fetching user profile: $e');
      return UserProfile(
        id: userId,
        username: 'Usuario',
      );
    }
  }
}
