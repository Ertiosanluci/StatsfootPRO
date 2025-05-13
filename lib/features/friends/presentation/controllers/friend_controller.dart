import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/repositories/friend_repository.dart';
import '../../domain/models/user_profile.dart'; // Added import for UserProfile
import '../state/friend_state.dart';

final friendRepositoryProvider = Provider<FriendRepository>((ref) {
  return FriendRepository(supabaseClient: Supabase.instance.client);
});

final friendControllerProvider = StateNotifierProvider<FriendController, FriendState>((ref) {
  final friendRepository = ref.watch(friendRepositoryProvider);
  return FriendController(friendRepository: friendRepository);
});

class FriendController extends StateNotifier<FriendState> {
  final FriendRepository _friendRepository;

  FriendController({required FriendRepository friendRepository})
      : _friendRepository = friendRepository,
        super(FriendState.initial()) {
    // Load pending requests as soon as the controller is created
    loadPendingRequests(); 
  }

  Future<void> loadFriends() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final friends = await _friendRepository.getFriends();
      state = state.copyWith(friends: friends, isLoading: false);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString(), isLoading: false);
    }
  }

  Future<void> loadAllUsers({String? searchQuery}) async {
    print('FriendController: loadAllUsers called with query: $searchQuery');
    state = state.copyWith(isLoading: true, errorMessage: null, searchQuery: searchQuery);
    try {
      print('FriendController: Calling repository getAllUsers');
      final users = await _friendRepository.getAllUsers(searchQuery: searchQuery);
      print('FriendController: Got ${users.length} users from repository');
      state = state.copyWith(allUsers: users, isLoading: false);
    } catch (e) {
      print('FriendController ERROR: ${e.toString()}');
      state = state.copyWith(errorMessage: e.toString(), isLoading: false);
    }
  }

  // Enhanced method to load pending requests with more explicit error handling
  Future<void> loadPendingRequests() async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      
      final sentRequests = await _friendRepository.getPendingSentRequests();
      final receivedRequests = await _friendRepository.getPendingReceivedRequests();
      
      print('Loaded ${receivedRequests.length} pending received requests');
      print('Loaded ${sentRequests.length} pending sent requests');
      
      state = state.copyWith(
        pendingSentRequests: sentRequests,
        pendingReceivedRequests: receivedRequests,
        isLoading: false,
      );
    } catch (e) {
      print('Error loading pending requests: $e');
      state = state.copyWith(errorMessage: e.toString(), isLoading: false);
    }
  }

  Future<void> sendFriendRequest(String receiverId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _friendRepository.sendFriendRequest(receiverId);
      await loadPendingRequests();
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString(), isLoading: false);
    }
  }

  Future<void> acceptFriendRequest(String requestId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _friendRepository.acceptFriendRequest(requestId);
      await loadPendingRequests();
      await loadFriends();
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString(), isLoading: false);
    }
  }

  Future<void> rejectFriendRequest(String requestId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _friendRepository.rejectFriendRequest(requestId);
      await loadPendingRequests();
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString(), isLoading: false);
    }
  }

  Future<void> cancelFriendRequest(String requestId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _friendRepository.cancelFriendRequest(requestId);
      await loadPendingRequests();
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString(), isLoading: false);
    }
  }

  Future<void> removeFriend(String friendId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _friendRepository.removeFriend(friendId);
      await loadFriends();
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString(), isLoading: false);
    }
  }

  // New method to get a user's profile by ID
  Future<UserProfile> getUserProfile(String userId) async {
    try {
      return await _friendRepository.getUserProfile(userId);
    } catch (e) {
      print('Error fetching user profile: $e');
      // Return a placeholder profile in case of error
      return UserProfile(
        id: userId,
        username: 'Usuario',
      );
    }
  }
}
