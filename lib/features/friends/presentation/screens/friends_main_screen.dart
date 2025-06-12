import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:statsfoota/features/friends/presentation/controllers/friend_controller.dart';
import 'package:statsfoota/features/friends/presentation/screens/friends_list_screen.dart';
import 'package:statsfoota/features/friends/presentation/screens/people_screen.dart';

class FriendsMainScreen extends ConsumerStatefulWidget {
  const FriendsMainScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<FriendsMainScreen> createState() => _FriendsMainScreenState();
}

class _FriendsMainScreenState extends ConsumerState<FriendsMainScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<Widget> _screens = [
    const PeopleScreen(),
    const FriendsListScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    // Initialize all the required data for the friend system
    await ref.read(friendControllerProvider.notifier).loadFriends();
    await ref.read(friendControllerProvider.notifier).loadAllUsers();
    await ref.read(friendControllerProvider.notifier).loadPendingRequests();
  }

  @override
  Widget build(BuildContext context) {
    // Calculando la altura con margen adicional para las pestañas
    final double tabBarHeight = kToolbarHeight + 16.0;
    
    return Scaffold(
      // Desactivamos explícitamente la flecha de retroceso para todas las plataformas
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(tabBarHeight),
        child: AppBar(
          automaticallyImplyLeading: false, // Esto desactiva la flecha de retroceso en todas las plataformas
          backgroundColor: Colors.blue.shade800,
          elevation: 0,
          flexibleSpace: SafeArea(
            child: Container(
              alignment: Alignment.bottomCenter,
              padding: EdgeInsets.only(top: 4),
              child: TabBar(
                controller: _tabController,
                indicatorColor: Colors.orange.shade600,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white.withOpacity(0.6),
                // Reducir padding horizontal para dar más espacio al texto
                labelPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 0),
                // Agregar isScrollable para evitar overflow y hacer las pestañas más compactas
                isScrollable: false,
                tabs: [
                  Tab(
                    height: 60, // Altura fija para el Tab
                    icon: Icon(Icons.search, size: 22),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'Buscar',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                  Tab(
                    height: 60, // Altura fija para el Tab
                    icon: Icon(Icons.group, size: 22),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'Mis amigos',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF1565C0),  // Azul oscuro
              Color(0xFF1976D2),  // Azul medio
              Color(0xFF1E88E5),  // Azul claro
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: TabBarView(
          controller: _tabController,
          children: _screens,
        ),
      ),
    );
  }
}
