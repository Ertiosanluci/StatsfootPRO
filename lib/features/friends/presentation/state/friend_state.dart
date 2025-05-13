import '../../domain/models/friend_request.dart';
import '../../domain/models/user_profile.dart';

class FriendState {
  final bool isLoading;
  final String? errorMessage;
  final List<UserProfile> friends;
  final List<UserProfile> allUsers;
  final List<FriendRequest> pendingSentRequests;
  final List<FriendRequest> pendingReceivedRequests;
  final String? searchQuery;

  const FriendState({
    this.isLoading = false,
    this.errorMessage,
    this.friends = const [],
    this.allUsers = const [],
    this.pendingSentRequests = const [],
    this.pendingReceivedRequests = const [],
    this.searchQuery,
  });

  factory FriendState.initial() => const FriendState();

  FriendState copyWith({
    bool? isLoading,
    String? errorMessage,
    List<UserProfile>? friends,
    List<UserProfile>? allUsers,
    List<FriendRequest>? pendingSentRequests,
    List<FriendRequest>? pendingReceivedRequests,
    String? searchQuery,
  }) {
    return FriendState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      friends: friends ?? this.friends,
      allUsers: allUsers ?? this.allUsers,
      pendingSentRequests: pendingSentRequests ?? this.pendingSentRequests,
      pendingReceivedRequests: pendingReceivedRequests ?? this.pendingReceivedRequests,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}
