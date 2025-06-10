import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:statsfoota/widgets/invite_friends_dialog.dart';
import 'create_match.dart';
import 'match_details_screen.dart';
import 'team_management_screen.dart';
import 'utils/match_operations.dart';

class MatchListScreen extends StatefulWidget {
  @override
  _MatchListScreenState createState() => _MatchListScreenState();
}

class _MatchListScreenState extends State<MatchListScreen> with SingleTickerProviderStateMixin {
  // Controller para el campo de búsqueda
  final TextEditingController _searchController = TextEditingController();
  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _myMatches = []; // Partidos organizados por el usuario
  List<Map<String, dynamic>> _friendsMatches = []; // Partidos de amigos (privados)
  List<Map<String, dynamic>> _publicMatches = []; // Partidos públicos
  
  // Cache para los contadores de participantes
  final Map<int, int> _participantCountCache = {};
  
  // Listas filtradas por tiempo (próximos/pasados)
  List<Map<String, dynamic>> _filteredMyMatches = [];
  List<Map<String, dynamic>> _filteredFriendsMatches = [];
  List<Map<String, dynamic>> _filteredPublicMatches = [];
  
  // Variable para el filtro de tiempo
  String _timeFilter = 'Próximos'; // 'Próximos', 'Pasados', 'Todos'
  
  // Variables para la selección múltiple
  bool _isSelectionMode = false;
  Set<int> _selectedMatches = {}; // Conjunto de IDs de partidos seleccionados
  
  bool _isLoading = true;
  late TabController _tabController;
  String? _error;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this); // 3 pestañas: Mis Partidos, Amigos, Públicos
    
    // Establecer el filtro por defecto para Mis Partidos como "Próximos"
    _timeFilter = 'Próximos';
    
    // Add listener to handle tab changes
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        print("Tab switched to: ${_tabController.index}");
        
        // Si cambiamos a la pestaña de Amigos o Públicos, asegurarse de que solo se muestren partidos futuros
        if (_tabController.index == 1 || _tabController.index == 2) {
          if (_timeFilter != 'Próximos') {
            setState(() {
              _timeFilter = 'Próximos';
              _applyTimeFilter();
            });
          }
        }
      }
    });
    
    _fetchMatches();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }
  
  // Resto del código existente...
  // Método para aplicar el filtro de tiempo a las listas de partidos
  void _applyTimeFilter() {
    final now = DateTime.now();
    
    setState(() {      if (_timeFilter == 'Próximos') {
        // Filtrar solo partidos con fecha futura
        _filteredMyMatches = _myMatches.where((match) {
          final matchDate = DateTime.parse(match['fecha']);
          // Para Mis Partidos, filtrar solo por fecha futura
          return matchDate.isAfter(now);
        }).toList();
        
        _filteredFriendsMatches = _friendsMatches.where((match) {
          final matchDate = DateTime.parse(match['fecha']);
          return matchDate.isAfter(now);
        }).toList();
        
        _filteredPublicMatches = _publicMatches.where((match) {
          final matchDate = DateTime.parse(match['fecha']);
          return matchDate.isAfter(now);
        }).toList();
      } 
      else if (_timeFilter == 'Pasados') {
        // Filtrar solo partidos con fecha pasada
        _filteredMyMatches = _myMatches.where((match) {
          final matchDate = DateTime.parse(match['fecha']);
          return matchDate.isBefore(now);
        }).toList();
        
        // Para Amigos y Públicos, no mostrar partidos pasados
        _filteredFriendsMatches = [];
        _filteredPublicMatches = [];
      } 
      else {
        // Mostrar todos los partidos
        _filteredMyMatches = List.from(_myMatches);
        _filteredFriendsMatches = List.from(_friendsMatches);
        _filteredPublicMatches = List.from(_publicMatches);
      }
    });
  }

  // Método para obtener los partidos del usuario
  Future<void> _fetchMatches() async {
    // Implementación existente...
  }

  // Resto de métodos existentes...

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _isSelectionMode
        ? AppBar(
            backgroundColor: Colors.red.shade700,
            title: Text('${_selectedMatches.length} seleccionados'),
            leading: IconButton(
              icon: Icon(Icons.close),
              onPressed: () {
                setState(() {
                  _isSelectionMode = false;
                  _selectedMatches.clear();
                });
              },
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.delete),
                onPressed: _selectedMatches.isNotEmpty ? _deleteSelectedMatches : null,
              ),
            ],
          )
        : PreferredSize(
            preferredSize: Size.fromHeight(kToolbarHeight),
            child: Container(
              color: Colors.blue.shade800,
              child: SafeArea(
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: Colors.white,
                  indicatorWeight: 3,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white70,
                  tabs: [
                    Tab(text: 'Mis Partidos'),
                    Tab(text: 'Amigos'),
                    Tab(text: 'Públicos'),
                  ],
                ),
              ),
            ),
          ),
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade300, Colors.blue.shade800],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: _isLoading
              ? Center(child: CircularProgressIndicator(color: Colors.white))
              : _error != null
                  ? _buildErrorMessage()
                  : Column(
                      children: [
                        // Filtro de tiempo (Próximos/Pasados/Todos)
                        _buildTimeFilterRow(),
                        // Lista de partidos
                        Expanded(
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              // Tab 0: Mis Partidos (incluye organizados + unidos)
                              _buildMatchListView(_filteredMyMatches, isOrganizer: false, listType: "my"),
                              // Tab 1: Amigos
                              _buildMatchListView(_filteredFriendsMatches, isOrganizer: false, listType: "friends"),
                              // Tab 2: Públicos
                              _buildMatchListView(_filteredPublicMatches, isOrganizer: false, listType: "public"),
                            ],
                          ),
                        ),
                      ],
                    ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CreateMatchScreen()),
          );
          _fetchMatches();
        },
        child: Icon(Icons.add, color: Colors.white),
        backgroundColor: Colors.orange.shade600,
      ),
    );
  }
  
  // Resto de métodos existentes...
  Widget _buildTimeFilterRow() {
    // Implementación existente...
    return Container();
  }
  
  Widget _buildErrorMessage() {
    // Implementación existente...
    return Container();
  }
  
  Widget _buildMatchListView(List<Map<String, dynamic>> matches, {required bool isOrganizer, required String listType}) {
    // Implementación existente...
    return Container();
  }
  
  // Resto de métodos existentes...
}
