import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:statsfoota/features/friends/presentation/controllers/friend_controller.dart';
import '../services/onesignal_service.dart';

class InviteFriendsDialog extends ConsumerStatefulWidget {
  final int matchId;
  final String matchName;

  const InviteFriendsDialog({
    Key? key,
    required this.matchId,
    required this.matchName,
  }) : super(key: key);

  @override
  ConsumerState<InviteFriendsDialog> createState() => _InviteFriendsDialogState();
}

class _InviteFriendsDialogState extends ConsumerState<InviteFriendsDialog> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isLoading = false;
  bool _isSearching = false;
  List<Map<String, dynamic>> _invitedFriends = [];

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFriends() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }
    
    try {
      await ref.read(friendControllerProvider.notifier).loadFriends();
      
      // Cargar amigos que ya han sido invitados a este partido
      final invitedResult = await _supabase
          .from('match_invitations')
          .select('invited_id')
          .eq('match_id', widget.matchId);
      
      setState(() {
        _invitedFriends = List<Map<String, dynamic>>.from(invitedResult);
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar amigos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Verifica si el amigo ya ha sido invitado
  bool _isAlreadyInvited(String friendId) {
    return _invitedFriends.any((invite) => invite['invited_id'] == friendId);
  }

  // Invitar a un amigo al partido
  Future<void> _inviteFriend(String friendId, String friendName) async {
    try {
      setState(() {
        _isSearching = true;
      });

      final userId = _supabase.auth.currentUser!.id;
      final currentUser = await _supabase
          .from('profiles')
          .select('username')
          .eq('id', userId)
          .single();
      final inviterName = currentUser['username'] as String? ?? 'Un amigo';
      
      final result = await _supabase.rpc(
        'create_match_invitation',
        params: {
          'p_match_id': widget.matchId,
          'p_inviter_id': userId,
          'p_invited_id': friendId
        },
      );

      if (mounted) {
        setState(() {
          _isSearching = false;
        });

        if (result['success'] == true) {
          // Agregar el amigo a la lista de invitados
          setState(() {
            _invitedFriends.add({'invited_id': friendId});
          });
          debugPrint('ID de friend desde ListView: $friendId');
  final matchingUser = await _supabase.from('profiles').select('id').eq('username', friendName).maybeSingle();
debugPrint('ID real en Supabase para $friendName: ${matchingUser?['id']}');

debugPrint('\n');
debugPrint(' friendId: $friendId');
debugPrint(' friendName: $friendName');
debugPrint(' inviterName: $inviterName');
debugPrint(' matchId: ${widget.matchId}');
debugPrint(' matchName: ${widget.matchName}');
debugPrint('\n');

          // Enviar notificación al amigo invitado
          _sendInvitationNotification(
            friendId: friendId, 
            friendName: friendName, 
            inviterName: inviterName, 
            matchId: widget.matchId, 
            matchName: widget.matchName
          );
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Has invitado a $friendName al partido'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Error al invitar al amigo'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al invitar al amigo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  // Enviar notificación de invitación a un partido
  Future<void> _sendInvitationNotification({
    required String friendId,
    required String friendName,
    required String inviterName,
    required int matchId,
    required String matchName,
  }) async {
    bool notificationSent = false;
    String errorMessage = '';
    
    try {
      debugPrint('Intentando enviar notificación a $friendName (ID: $friendId)');
      
      // Obtener el player ID del amigo invitado
      final playerIdToSend = await OneSignalService.getPlayerIdByUserId(friendId);
      
      if (playerIdToSend != null && playerIdToSend.isNotEmpty) {
        // Preparar los datos adicionales para la notificación
        final additionalData = {
          'type': 'match_invitation',
          'match_id': matchId,
          'inviter_id': _supabase.auth.currentUser!.id,
          'inviter_name': inviterName,
          'match_name': matchName
        };
        
        debugPrint('Enviando notificación a $friendName con player_id: $playerIdToSend');
        
        try {
          // Enviar notificación usando OneSignal
          await OneSignalService.sendTestNotification(
            title: 'Invitación a partido',
            content: '$inviterName te ha invitado al partido $matchName',
            additionalData: additionalData,
            playerIds: playerIdToSend, // Usar el player_id del destinatario
          );
          
          notificationSent = true;
          debugPrint('Notificación enviada exitosamente a $friendName');
        } catch (notifError) {
          errorMessage = 'Error al enviar la notificación: $notifError';
          debugPrint(errorMessage);
        }
      } else {
        errorMessage = 'No se encontró ID de OneSignal para $friendName';
        debugPrint('$errorMessage. Verificando tabla user_push_tokens...');
        
        // Verificar directamente en la tabla para depuración
        try {
          final result = await _supabase
              .from('user_push_tokens')
              .select('*')
              .eq('user_id', friendId);
          
          if (result.isNotEmpty) {
            final tokenData = result[0];
            debugPrint('Se encontró registro en user_push_tokens: $tokenData');
          } else {
            debugPrint('No existe registro en user_push_tokens para el usuario $friendId');
            
            // Verificar si el usuario existe en la base de datos
            final userExists = await _supabase
                .from('profiles')
                .select('id')
                .eq('id', friendId)
                .maybeSingle();
                
            if (userExists != null) {
              debugPrint('El usuario $friendName existe pero no tiene token de OneSignal registrado');
            } else {
              debugPrint('El usuario $friendName no existe en la base de datos');
            }
          }
        } catch (dbError) {
          debugPrint('Error al verificar la tabla user_push_tokens: $dbError');
        }
      }
      
      // Mostrar mensaje apropiado al usuario
      if (mounted) {
        if (notificationSent) {
          // La notificación se envió correctamente
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Has invitado a $friendName al partido'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          // La notificación no se pudo enviar, pero la invitación se registró
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Has invitado a $friendName al partido, pero no recibirá una notificación push'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error general al enviar notificación: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al enviar la notificación a $friendName'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(friendControllerProvider);
    
    // Filtrar amigos según el término de búsqueda
    final filteredFriends = _searchQuery.isEmpty
        ? state.friends
        : state.friends
            .where((friend) =>
                friend.username.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();
    
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
      backgroundColor: Colors.blue.shade800,
      child: Container(
        width: double.maxFinite,
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Invitar amigos a ${widget.matchName}',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20.0),
            
            // Buscador
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20.0),
              ),
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: TextField(
                controller: _searchController,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Buscar amigos...',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                  prefixIcon: Icon(Icons.search, color: Colors.white70),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, color: Colors.white70),
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),
            SizedBox(height: 20.0),
            
            // Lista de amigos
            if (_isLoading)
              CircularProgressIndicator(color: Colors.white)
            else if (state.friends.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20.0),
                child: Column(
                  children: [
                    Icon(Icons.group_off, color: Colors.white70, size: 48.0),
                    SizedBox(height: 16.0),
                    Text(
                      'No tienes amigos para invitar',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              )
            else if (filteredFriends.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20.0),
                child: Column(
                  children: [
                    Icon(Icons.search_off, color: Colors.white70, size: 48.0),
                    SizedBox(height: 16.0),
                    Text(
                      'No se encontraron amigos con ese nombre',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: filteredFriends.length,
                  itemBuilder: (context, index) {
                    final friend = filteredFriends[index];
                    final isInvited = _isAlreadyInvited(friend.id);
                    
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.orange.shade600,
                        backgroundImage: friend.avatarUrl != null
                            ? NetworkImage(friend.avatarUrl!)
                            : null,
                        child: friend.avatarUrl == null
                            ? Text(
                                friend.username.substring(0, 1).toUpperCase(),
                                style: TextStyle(color: Colors.white),
                              )
                            : null,
                      ),
                      title: Text(
                        friend.username,
                        style: TextStyle(color: Colors.white),
                      ),
                      subtitle: friend.fieldPosition != null
                          ? Text(
                              friend.fieldPosition!,
                              style: TextStyle(color: Colors.white70),
                            )
                          : null,
                      trailing: isInvited
                          ? Container(
                              padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(20.0),
                              ),
                              child: Text(
                                'Invitado',
                                style: TextStyle(color: Colors.white, fontSize: 12.0),
                              ),
                            )
                          : ElevatedButton(
                              onPressed: _isSearching
                                  ? null
                                  : () => _inviteFriend(friend.id, friend.username),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange.shade600,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(horizontal: 16.0),
                                minimumSize: Size(80, 30),
                              ),
                              child: _isSearching
                                  ? SizedBox(
                                      width: 20.0,
                                      height: 20.0,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.0,
                                      ),
                                    )
                                  : Text('Invitar'),
                            ),
                    );
                  },
                ),
              ),
            
            SizedBox(height: 20.0),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.blue.shade800,
                minimumSize: Size(double.infinity, 45),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.0),
                ),
              ),
              child: Text('Cerrar'),
            ),
          ],
        ),
      ),
    );
  }
}
