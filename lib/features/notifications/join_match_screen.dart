import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:statsfoota/features/notifications/presentation/controllers/notification_controller.dart';

/// Pantalla para unirse a un partido desde una notificación de invitación
class JoinMatchScreen extends ConsumerStatefulWidget {
  final int matchId;
  final Map<String, dynamic>? matchData;
  final bool fromNotification;

  const JoinMatchScreen({
    Key? key,
    required this.matchId,
    this.matchData,
    this.fromNotification = false,
  }) : super(key: key);

  @override
  ConsumerState<JoinMatchScreen> createState() => _JoinMatchScreenState();
}

class _JoinMatchScreenState extends ConsumerState<JoinMatchScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  Map<String, dynamic>? _matchDetails;
  bool _isJoining = false;
  bool _hasJoined = false;

  @override
  void initState() {
    super.initState();
    _loadMatchDetails();
  }

  Future<void> _loadMatchDetails() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      // Si tenemos datos del partido desde la notificación, los usamos
      if (widget.matchData != null && widget.matchData!.isNotEmpty) {
        setState(() {
          _matchDetails = widget.matchData;
          _isLoading = false;
        });
        return;
      }

      // Si no tenemos datos, los cargamos desde la base de datos
      final matchResult = await _supabase
          .from('matches')
          .select('*, profiles:created_by(username)')
          .eq('id', widget.matchId)
          .single();

      // Verificar si el usuario ya es participante
      final userId = _supabase.auth.currentUser!.id;
      final participantResult = await _supabase
          .from('match_participants')
          .select()
          .eq('match_id', widget.matchId)
          .eq('user_id', userId)
          .maybeSingle();

      setState(() {
        _matchDetails = matchResult;
        _hasJoined = participantResult != null;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Error al cargar los detalles del partido: $e';
      });
      debugPrint(_errorMessage);
    }
  }

  Future<void> _joinMatch() async {
    if (_hasJoined) return;

    setState(() {
      _isJoining = true;
    });

    try {
      final userId = _supabase.auth.currentUser!.id;

      // Verificar si ya existe una invitación
      final invitationResult = await _supabase
          .from('match_invitations')
          .select()
          .eq('match_id', widget.matchId)
          .eq('invited_id', userId)
          .maybeSingle();

      // Si existe una invitación, actualizarla a 'accepted'
      if (invitationResult != null) {
        await _supabase
            .from('match_invitations')
            .update({'status': 'accepted'})
            .eq('id', invitationResult['id']);
      }

      // Añadir al usuario como participante
      await _supabase.from('match_participants').insert({
        'match_id': widget.matchId,
        'user_id': userId,
      });

      // Si la notificación viene de una notificación, marcarla como leída
      if (widget.fromNotification) {
        // Buscar la notificación relacionada con esta invitación
        final notificationResult = await _supabase
            .from('notifications')
            .select()
            .eq('resource_id', widget.matchId)
            .eq('type', 'match_invitation')
            .eq('recipient_id', userId)
            .maybeSingle();

        if (notificationResult != null) {
          final notificationId = notificationResult['id'];
          
          // Marcar como leída en la base de datos
          await _supabase
              .from('notifications')
              .update({'read': true})
              .eq('id', notificationId);
          
          // Actualizar el estado local
          ref.read(notificationControllerProvider.notifier).markAsRead(notificationId);
        }
      }

      setState(() {
        _hasJoined = true;
        _isJoining = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Te has unido al partido correctamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isJoining = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al unirse al partido: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _declineInvitation() async {
    setState(() {
      _isJoining = true;
    });

    try {
      final userId = _supabase.auth.currentUser!.id;

      // Actualizar el estado de la invitación a 'declined'
      await _supabase
          .from('match_invitations')
          .update({'status': 'declined'})
          .eq('match_id', widget.matchId)
          .eq('invited_id', userId);

      // Si la notificación viene de una notificación, marcarla como leída
      if (widget.fromNotification) {
        // Buscar la notificación relacionada con esta invitación
        final notificationResult = await _supabase
            .from('notifications')
            .select()
            .eq('resource_id', widget.matchId)
            .eq('type', 'match_invitation')
            .eq('recipient_id', userId)
            .maybeSingle();

        if (notificationResult != null) {
          final notificationId = notificationResult['id'];
          
          // Marcar como leída en la base de datos
          await _supabase
              .from('notifications')
              .update({'read': true})
              .eq('id', notificationId);
          
          // Actualizar el estado local
          ref.read(notificationControllerProvider.notifier).markAsRead(notificationId);
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Has rechazado la invitación'),
            backgroundColor: Colors.orange,
          ),
        );
        
        // Volver a la pantalla anterior
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() {
        _isJoining = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al rechazar la invitación: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invitación a partido'),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _hasError
              ? _buildErrorView()
              : _buildMatchDetailsView(),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 60.0,
            ),
            const SizedBox(height: 16.0),
            Text(
              'No se pudo cargar la información del partido',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8.0),
            Text(
              _errorMessage,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24.0),
            ElevatedButton(
              onPressed: _loadMatchDetails,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade800,
                foregroundColor: Colors.white,
              ),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchDetailsView() {
    // Usar los campos correctos de la tabla matches
    final String matchName = _matchDetails?['match_name'] ?? _matchDetails?['nombre'] ?? 'Partido sin nombre';
    final String location = _matchDetails?['nombre'] ?? 'Ubicación no especificada';
    final String date = _matchDetails?['fecha']?.toString() ?? 'Fecha no especificada';
    final String format = _matchDetails?['formato'] ?? 'Formato no especificado';
    final String creatorName = _matchDetails?['profiles']?['username'] ?? 
                              _matchDetails?['inviter_name'] ?? 'Organizador desconocido';

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encabezado con icono y título
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade600,
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: const Icon(
                    Icons.sports_soccer,
                    color: Colors.white,
                    size: 32.0,
                  ),
                ),
                const SizedBox(width: 16.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Has sido invitado a',
                        style: TextStyle(
                          fontSize: 16.0,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        matchName,
                        style: const TextStyle(
                          fontSize: 24.0,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 32.0),
            
            // Detalles del partido
            _buildDetailItem(
              icon: Icons.person,
              title: 'Organizador',
              value: creatorName,
            ),
            
            _buildDetailItem(
              icon: Icons.location_on,
              title: 'Nombre',
              value: location,
            ),
            
            _buildDetailItem(
              icon: Icons.calendar_today,
              title: 'Fecha',
              value: date,
            ),
            
            _buildDetailItem(
              icon: Icons.sports_soccer,
              title: 'Formato',
              value: format,
            ),
            
            const SizedBox(height: 40.0),
            
            // Botones de acción
            if (!_hasJoined)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isJoining ? null : _joinMatch,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                      ),
                      child: _isJoining
                          ? const SizedBox(
                              width: 24.0,
                              height: 24.0,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.0,
                              ),
                            )
                          : const Text(
                              'UNIRME AL PARTIDO',
                              style: TextStyle(
                                fontSize: 16.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 16.0),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isJoining ? null : _declineInvitation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade400,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                      ),
                      child: const Text(
                        'RECHAZAR',
                        style: TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              )
            else
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade800,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
                child: const Text(
                  'YA TE HAS UNIDO A ESTE PARTIDO',
                  style: TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: Colors.blue.shade800,
            size: 24.0,
          ),
          const SizedBox(width: 16.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14.0,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
