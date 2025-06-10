import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class InviteFriendsScreen extends StatefulWidget {
  final String matchId;
  
  const InviteFriendsScreen({Key? key, required this.matchId}) : super(key: key);

  @override
  _InviteFriendsScreenState createState() => _InviteFriendsScreenState();
}

class _InviteFriendsScreenState extends State<InviteFriendsScreen> {
  List<Map<String, dynamic>> _friends = [];
  final List<String> _selectedFriendIds = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  Future<void> _loadFriends() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Aquí cargaríamos amigos desde Supabase
      // Por ahora usamos datos de ejemplo
      setState(() {
        _friends = [
          {'id': '1', 'name': 'Amigo 1', 'avatar_url': null},
          {'id': '2', 'name': 'Amigo 2', 'avatar_url': null},
          {'id': '3', 'name': 'Amigo 3', 'avatar_url': null},
        ];
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar amigos: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _toggleFriendSelection(String friendId) {
    setState(() {
      if (_selectedFriendIds.contains(friendId)) {
        _selectedFriendIds.remove(friendId);
      } else {
        _selectedFriendIds.add(friendId);
      }
    });
  }

  Future<void> _inviteSelectedFriends() async {
    if (_selectedFriendIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona al menos un amigo')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Aquí enviaríamos invitaciones a través de Supabase
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invitaciones enviadas con éxito')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al enviar invitaciones: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invitar Amigos', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF0D47A1),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
          ),
        ),
        child: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: _friends.length,
                    itemBuilder: (context, index) {
                      final friend = _friends[index];
                      final isSelected = _selectedFriendIds.contains(friend['id']);
                      
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.white,
                          child: Text(friend['name'][0], style: TextStyle(color: Color(0xFF0D47A1))),
                        ),
                        title: Text(friend['name'], style: TextStyle(color: Colors.white)),
                        trailing: Icon(
                          isSelected ? Icons.check_circle : Icons.circle_outlined,
                          color: Colors.white,
                        ),
                        onTap: () => _toggleFriendSelection(friend['id']),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Color(0xFF0D47A1),
                      minimumSize: Size(double.infinity, 50),
                    ),
                    onPressed: _inviteSelectedFriends,
                    child: const Text('Invitar seleccionados'),
                  ),
                ),
              ],
            ),
      ),
    );
  }
}
