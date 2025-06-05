import '../../domain/models/match_invitation_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MatchInvitationRepository {
  final SupabaseClient _supabaseClient;
  static const String _tableName = 'match_invitations';

  MatchInvitationRepository({
    required SupabaseClient supabaseClient,
  }) : _supabaseClient = supabaseClient;  /// Responds to a match invitation (accept or reject)
  Future<bool> respondToInvitation({
    required String invitationId,
    required String response, // 'accepted' or 'rejected'
  }) async {
    try {
      print('Debug: Responding to invitation with ID: $invitationId, response: $response');
      
      final result = await _supabaseClient.rpc('respond_to_match_invitation', params: {
        'invitation_id': invitationId,
        'response': response,
      });      print('Debug: RPC result: $result');
      
      // Check if the result indicates success
      if (result is Map<String, dynamic>) {
        final success = result['success'] as bool?;
        if (success == false) {
          final message = result['message'] as String? ?? 'Error desconocido';
          throw Exception(message);
        }
        return success == true;
      }
      
      return result != null;
    } catch (e) {
      print('Error responding to match invitation: $e');
      return false;
    }
  }
  /// Gets match invitations for a specific user
  Future<List<MatchInvitation>> getUserInvitations(String userId) async {
    try {
      final response = await _supabaseClient
          .from(_tableName)
          .select('''
            id,
            match_id,
            inviter_id,
            invited_user_id,
            status,
            created_at,
            responded_at,
            matches!inner(
              id,
              title,
              description,
              date,
              time,
              location,
              max_players,
              creator_id
            ),
            inviter:profiles!match_invitations_inviter_id_fkey(
              id,
              username,
              avatar_url
            )
          ''')
          .eq('invited_user_id', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => MatchInvitation.fromJson(json))
          .toList();
    } catch (e) {
      print('Error getting user invitations: $e');
      return [];
    }
  }
  /// Gets a specific match invitation by ID
  Future<MatchInvitation?> getInvitationById(String invitationId) async {
    try {
      final response = await _supabaseClient
          .from(_tableName)
          .select('''
            id,
            match_id,
            inviter_id,
            invited_user_id,
            status,
            created_at,
            responded_at,
            matches!inner(
              id,
              title,
              description,
              date,
              time,
              location,
              max_players,
              creator_id
            ),
            inviter:profiles!match_invitations_inviter_id_fkey(
              id,
              username,
              avatar_url
            )
          ''')
          .eq('id', invitationId)
          .single();

      return MatchInvitation.fromJson(response);
    } catch (e) {
      print('Error getting invitation by ID: $e');
      return null;
    }
  }
}
