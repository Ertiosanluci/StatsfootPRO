import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:statsfoota/features/friends/presentation/controllers/friend_controller.dart';
import 'package:statsfoota/features/friends/presentation/screens/friend_requests_screen.dart';
import 'package:statsfoota/features/friends/presentation/screens/friends_list_screen.dart';
import 'package:statsfoota/features/friends/presentation/screens/people_screen.dart';

class FriendsMainScreen extends ConsumerStatefulWidget {
  const FriendsMainScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<FriendsMainScreen> createState() => _FriendsMainScreenState();
}

class _FriendsMainScreenState extends ConsumerState<FriendsMainScreen> {
  int _selectedIndex = 0;
  final List<Widget> _screens = [
    const PeopleScreen(),
    const FriendsListScreen(),
    const FriendRequestsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // Initialize all the required data for the friend system
    await ref.read(friendControllerProvider.notifier).loadFriends();
    await ref.read(friendControllerProvider.notifier).loadAllUsers();
    await ref.read(friendControllerProvider.notifier).loadPendingRequests();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(friendControllerProvider);
    
    return Scaffold(
      backgroundColor: Colors.blueGrey.shade900,
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        backgroundColor: Colors.blueGrey.shade800,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.white.withOpacity(0.6),
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.people_alt),
            label: 'Personas',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.group),
            label: 'Mis amigos',
          ),
          BottomNavigationBarItem(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications),
                if (state.pendingReceivedRequests.isNotEmpty)
                  Positioned(
                    top: -5,
                    right: -5,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.blueGrey.shade800, width: 1.5),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        state.pendingReceivedRequests.length.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            label: 'Solicitudes',
          ),
        ],
      ),
    );
  }
}
