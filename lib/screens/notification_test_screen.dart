import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:statsfoota/services/onesignal_service.dart';

class NotificationTestScreen extends ConsumerStatefulWidget {
  const NotificationTestScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<NotificationTestScreen> createState() => _NotificationTestScreenState();
}

class _NotificationTestScreenState extends ConsumerState<NotificationTestScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  String? _playerId;
  bool _isLoading = false;
  String _statusMessage = '';

  @override
  void initState() {
    super.initState();
    _initializeOneSignal();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _initializeOneSignal() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Inicializando OneSignal...';
    });

    try {
      // Initialize OneSignal
      await OneSignalService.initializeOneSignal();
      
      // Get player ID
      final playerId = await OneSignalService.getPlayerId();
      
      setState(() {
        _playerId = playerId;
        _statusMessage = playerId != null 
            ? 'OneSignal inicializado correctamente'
            : 'Error: No se pudo obtener el ID del dispositivo';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error al inicializar OneSignal: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _sendTestNotification() async {
    if (_titleController.text.isEmpty || _contentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, completa todos los campos')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = 'Enviando notificación...';
    });

    try {
      await OneSignalService.sendTestNotification(
        title: _titleController.text,
        content: _contentController.text,
        additionalData: {'test': true, 'timestamp': DateTime.now().toIso8601String()},
      );
      
      setState(() {
        _statusMessage = 'Notificación enviada correctamente';
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notificación enviada'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _statusMessage = 'Error al enviar la notificación: $e';
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
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
        title: const Text('Prueba de Notificaciones'),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // OneSignal status card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Estado de OneSignal',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'App ID: ${OneSignalService.appId}',
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text('Player ID: ', style: TextStyle(fontWeight: FontWeight.bold)),
                        Expanded(
                          child: Text(
                            _playerId ?? 'No disponible',
                            style: TextStyle(
                              color: _playerId != null ? Colors.green.shade700 : Colors.red,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text('Estado: ', style: TextStyle(fontWeight: FontWeight.bold)),
                        Expanded(
                          child: Text(
                            _statusMessage,
                            style: TextStyle(
                              color: _statusMessage.contains('Error') 
                                  ? Colors.red 
                                  : Colors.green.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Form for sending test notifications
            const Text(
              'Enviar notificación de prueba',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Título',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.title),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _contentController,
              decoration: InputDecoration(
                labelText: 'Contenido',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.message),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _sendTestNotification,
              icon: const Icon(Icons.send),
              label: Text(_isLoading ? 'Enviando...' : 'Enviar notificación'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade800,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.only(top: 16.0),
                child: Center(child: CircularProgressIndicator()),
              ),
              
            const Spacer(),
            
            // Info text
            const Text(
              'Nota: Esta pantalla permite enviar notificaciones de prueba a tu propio dispositivo. En una aplicación real, las notificaciones serían enviadas desde un servidor backend.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
