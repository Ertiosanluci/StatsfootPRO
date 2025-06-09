import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:developer' as dev;
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
      dev.log(_errorMessage);
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
        try {
          // Buscar la notificación relacionada con esta invitación usando los campos correctos
          final notificationResult = await _supabase
              .from('notifications')
              .select()
              .eq('type', 'match_invitation')
              .eq('user_id', userId)
              .maybeSingle();

          if (notificationResult != null) {
            // Verificar si la notificación contiene datos sobre este partido
            final data = notificationResult['data'];
            bool isMatchingNotification = false;
            
            if (data != null && data is Map) {
              // Comprobar si el match_id en los datos coincide con el partido actual
              isMatchingNotification = data['match_id'] == widget.matchId;
            }
            
            if (isMatchingNotification) {
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
        } catch (notifError) {
          // Solo registrar el error, no interrumpir el flujo principal
          dev.log('Error al actualizar la notificación: $notifError');
        }
      }

      setState(() {
        _hasJoined = true;
        _isJoining = false;
      });

      if (mounted) {
        // Mostrar mensaje de éxito brevemente
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Te has unido al partido correctamente'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );
        
        // Navegar a la pantalla del partido
        Future.delayed(const Duration(milliseconds: 500), () {
          if (!mounted) return;
          
          // Si viene de una notificación, navegar a la pantalla de detalles del partido
          if (widget.fromNotification) {
            // Navegar a la pantalla de detalles del partido
            Navigator.of(context).pushNamedAndRemoveUntil(
              '/match-detail', // Ruta a la pantalla de detalles del partido
              (route) => false, // Eliminar todas las rutas anteriores
              arguments: {'matchId': widget.matchId}, // Pasar el ID del partido como argumento
            );
          } else {
            // Si no viene de notificación, simplemente volver a la pantalla anterior
            Navigator.of(context).pop(true); // Devolver true para indicar que se unió
          }
        });
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
        try {
          // Buscar la notificación relacionada con esta invitación usando los campos correctos
          final notificationResult = await _supabase
              .from('notifications')
              .select()
              .eq('type', 'match_invitation')
              .eq('user_id', userId)
              .maybeSingle();

          if (notificationResult != null) {
            // Verificar si la notificación contiene datos sobre este partido
            final data = notificationResult['data'];
            bool isMatchingNotification = false;
            
            if (data != null && data is Map) {
              // Comprobar si el match_id en los datos coincide con el partido actual
              isMatchingNotification = data['match_id'] == widget.matchId;
            }
            
            if (isMatchingNotification) {
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
        } catch (notifError) {
          // Solo registrar el error, no interrumpir el flujo principal
          dev.log('Error al actualizar la notificación: $notifError');
        }
      }

      setState(() {
        _isJoining = false;
      });

      if (mounted) {
        // Mostrar mensaje de rechazo brevemente
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Has rechazado la invitación'),
            backgroundColor: Colors.grey,
            duration: Duration(seconds: 1),
          ),
        );
        
        // Navegar según el origen de la invitación
        Future.delayed(const Duration(milliseconds: 500), () {
          if (!mounted) return;
          
          if (widget.fromNotification) {
            // Si viene de una notificación, navegar a la tab de partidos
            Navigator.of(context).pushNamedAndRemoveUntil(
              '/matches', // Ruta a la tab de partidos
              (route) => false, // Eliminar todas las rutas anteriores
            );
          } else {
            // Si no viene de notificación, simplemente volver a la pantalla anterior
            Navigator.of(context).pop();
          }
        });
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
    final matchName = _matchDetails!['nombre'] ?? 'Partido sin nombre';
    final matchDate = _matchDetails!['fecha'] ?? 'Fecha no especificada';
    final matchFormat = _matchDetails!['formato'] ?? 'Formato no especificado';
    final matchLocation = _matchDetails!['ubicacion'] ?? 'Ubicación no especificada';
    final matchCreator = _matchDetails!['profiles']?['username'] ?? 'Usuario desconocido';
    final matchDescription = _matchDetails!['descripcion'] ?? 'Sin descripción';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Encabezado con estilo moderno
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.blue.shade700, Colors.blue.shade900],
              ),
              borderRadius: BorderRadius.circular(16.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.sports_soccer,
                    size: 40.0,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16.0),
                Text(
                  'Invitación a Partido',
                  style: const TextStyle(
                    fontSize: 22.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8.0),
                Text(
                  'Has sido invitado a unirte a este partido',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14.0,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24.0),
          
          // Nombre del partido con estilo destacado
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Text(
              matchName,
              style: const TextStyle(
                fontSize: 22.0,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          
          const SizedBox(height: 24.0),
          
          // Detalles del partido con tarjetas modernas
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildDetailItem(
                  icon: Icons.calendar_today,
                  title: 'Fecha y Hora',
                  value: matchDate,
                  showDivider: true,
                ),
                
                _buildDetailItem(
                  icon: Icons.sports_soccer,
                  title: 'Formato',
                  value: matchFormat,
                  showDivider: true,
                ),
                
                _buildDetailItem(
                  icon: Icons.location_on,
                  title: 'Ubicación',
                  value: matchLocation,
                  showDivider: true,
                ),
                
                _buildDetailItem(
                  icon: Icons.person,
                  title: 'Organizador',
                  value: matchCreator,
                  showDivider: matchDescription.isNotEmpty,
                ),
                
                if (matchDescription.isNotEmpty)
                  _buildDetailItem(
                    icon: Icons.description,
                    title: 'Descripción',
                    value: matchDescription,
                    showDivider: false,
                  ),
              ],
            ),
          ),
          
          const SizedBox(height: 32.0),
          
          // Botones de acción con estilo moderno
          if (!_hasJoined)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isJoining ? null : _joinMatch,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      elevation: 3,
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
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.check_circle_outline),
                              SizedBox(width: 8),
                              Text(
                                'UNIRME',
                                style: TextStyle(
                                  fontSize: 16.0,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(width: 16.0),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isJoining ? null : _declineInvitation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade500,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.close),
                        SizedBox(width: 8),
                        Text(
                          'RECHAZAR',
                          style: TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ]
            )
          else
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade800,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 56.0),
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.check_circle),
                  SizedBox(width: 8),
                  Text(
                    'YA TE HAS UNIDO',
                    style: TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String title,
    required String value,
    bool showDivider = false,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Icon(
                  icon,
                  color: Colors.blue.shade800,
                  size: 22.0,
                ),
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
                        fontWeight: FontWeight.w500,
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
        ),
        if (showDivider)
          Divider(
            color: Colors.grey.shade200,
            height: 1,
            thickness: 1,
            indent: 16,
            endIndent: 16,
          ),
      ],
    );
  }
}
