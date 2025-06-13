import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:statsfoota/features/notifications/join_match_screen.dart';

class OneSignalService {
  static final String appId = '18b75b21-dfe8-43cf-974e-9a79eac0f01b';
  
  // Referencia a Supabase
  static final _supabase = Supabase.instance.client;
  
  // Initialize OneSignal
  static Future<void> initializeOneSignal() async {
    try {
      // Enable debug logs for development
      OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
      
      // Initialize OneSignal
      OneSignal.initialize(appId);
      
      // Request permission to send notifications
      await OneSignal.Notifications.requestPermission(true);
      
      // Add notification click listener
      OneSignal.Notifications.addClickListener((OSNotificationClickEvent event) {
        final additionalData = event.notification.additionalData;
        if (additionalData != null) {
          debugPrint('Notificación pulsada con datos: $additionalData');
          
          // Verificar si es una invitación a partido
          if (additionalData.containsKey('type') && 
              additionalData['type'] == 'match_invitation' &&
              additionalData.containsKey('match_id')) {
            // Extraer el ID del partido
            final matchId = int.tryParse(additionalData['match_id'].toString());
            if (matchId != null) {
              debugPrint('Navigating to match details for match ID: $matchId');
              
              // Use a static method to handle navigation
              // This will be called regardless of whether the app is in foreground, background or closed
              _handleMatchInvitationNavigation(matchId, additionalData);
            }
          }
        }
      });
      
      // Add permission observer
      OneSignal.Notifications.addPermissionObserver((bool hasPermission) {
        debugPrint('Permission changed: $hasPermission');
      });
      
      // Guardar el token del dispositivo en Supabase cuando el usuario esté autenticado
      if (_supabase.auth.currentUser != null) {
        final playerId = await getPlayerId();
        if (playerId != null) {
          await savePlayerIdToSupabase(playerId);
        }
      }
      
      // Registrar un listener para cuando cambie el token del dispositivo
      OneSignal.User.pushSubscription.addObserver((state) async {
        debugPrint('Push subscription changed: ${state.current.id}');
        if (_supabase.auth.currentUser != null && state.current.id != null) {
          await savePlayerIdToSupabase(state.current.id!);
        }
      });
      
      debugPrint('OneSignal initialized successfully');
    } catch (e) {
      debugPrint('Error initializing OneSignal: $e');
    }
  }
  
  // Get the OneSignal user ID (player ID)
  static Future<String?> getPlayerId() async {
    try {
      // Get the subscription status
      final status = OneSignal.User.pushSubscription;
      return status.id;
    } catch (e) {
      debugPrint('Error getting player ID: $e');
      return null;
    }
  }
  
  // Guardar el token del dispositivo (player ID) en Supabase usando la tabla user_devices
  static Future<void> savePlayerIdToSupabase(String playerId) async {
    try {
      if (_supabase.auth.currentUser == null) {
        debugPrint('No se puede guardar el player ID: Usuario no autenticado');
        return;
      }
      
      final userId = _supabase.auth.currentUser!.id;
      final deviceType = 'mobile'; // Podría determinarse dinámicamente si es necesario
      
      // Verificar si ya existe un registro para este usuario y este dispositivo
      final existingData = await _supabase
          .from('user_devices')
          .select()
          .eq('user_id', userId)
          .eq('onesignal_player_id', playerId)
          .maybeSingle();
      
      final now = DateTime.now().toIso8601String();
      
      if (existingData != null) {
        // Actualizar el registro existente (solo la fecha de último uso)
        await _supabase
            .from('user_devices')
            .update({
              'last_used_at': now,
            })
            .eq('id', existingData['id']);
        debugPrint('Dispositivo actualizado para el usuario: $userId');
      } else {
        // Crear un nuevo registro para este dispositivo
        await _supabase
            .from('user_devices')
            .insert({
              'user_id': userId,
              'onesignal_player_id': playerId,
              'device_type': deviceType,
              'created_at': now,
              'last_used_at': now,
            });
        debugPrint('Nuevo dispositivo registrado para el usuario: $userId');
      }
      
      // Para mantener compatibilidad con el código existente, también actualizamos la tabla user_push_tokens
      try {
        final existingToken = await _supabase
            .from('user_push_tokens')
            .select()
            .eq('user_id', userId)
            .eq('player_id', playerId)
            .maybeSingle();
            
        if (existingToken != null) {
          await _supabase
              .from('user_push_tokens')
              .update({
                'updated_at': now,
              })
              .eq('id', existingToken['id']);
        } else {
          await _supabase
              .from('user_push_tokens')
              .insert({
                'user_id': userId,
                'player_id': playerId,
                'created_at': now,
                'updated_at': now,
              });
        }
      } catch (tokenError) {
        // Si hay un error con la tabla antigua, lo registramos pero no interrumpimos el flujo
        debugPrint('Nota: Error al actualizar la tabla user_push_tokens (no crítico): $tokenError');
      }
    } catch (e) {
      debugPrint('Error al guardar el dispositivo: $e');
      if (e.toString().contains('relation "public.user_devices" does not exist')) {
        debugPrint('La tabla user_devices no existe en la base de datos. Por favor, créala primero.');
      }
    }
  }
  
  // Obtener todos los player IDs de un usuario específico desde Supabase
  static Future<List<String>> getPlayerIdsByUserId(String userId) async {
    try {
      debugPrint('Buscando player_ids para el usuario: $userId en la tabla user_devices');
      
      // Intentar obtener los IDs de la nueva tabla user_devices
      final devices = await _supabase
          .from('user_devices')
          .select('onesignal_player_id')
          .eq('user_id', userId.trim());
      
      List<String> playerIds = [];
      
      if (devices.isNotEmpty) {
        playerIds = devices
            .map((item) => item['onesignal_player_id'] as String)
            .where((id) => id.isNotEmpty) // Filtrar IDs vacíos
            .toList();
        
        debugPrint('Encontrados ${playerIds.length} dispositivos para el usuario $userId en user_devices');
        for (var playerId in playerIds) {
          debugPrint('  - Player ID: $playerId');
        }
      } else {
        debugPrint('No se encontraron dispositivos para el usuario $userId en user_devices');
        
        // Como fallback, intentar obtener de la tabla antigua
        try {
          final oldTokens = await _supabase
              .from('user_push_tokens')
              .select('player_id')
              .eq('user_id', userId.trim());
          
          if (oldTokens.isNotEmpty) {
            final oldPlayerIds = oldTokens
                .map((item) => item['player_id'] as String)
                .where((id) => id.isNotEmpty)
                .toList();
            
            playerIds.addAll(oldPlayerIds);
            debugPrint('Encontrados ${oldPlayerIds.length} tokens en la tabla antigua user_push_tokens');
          }
        } catch (fallbackError) {
          debugPrint('Error al intentar obtener tokens de la tabla antigua: $fallbackError');
        }
      }
      
      // Eliminar duplicados si los hubiera
      playerIds = playerIds.toSet().toList();
      
      if (playerIds.isNotEmpty) {
        debugPrint('Total de Player IDs encontrados para $userId: ${playerIds.length}');
        return playerIds;
      } else {
        debugPrint('No se encontró ningún dispositivo registrado para el usuario $userId');
        return [];
      }
    } catch (e) {
      debugPrint('Error al obtener los player IDs del usuario $userId: $e');
      return [];
    }
  }
  
  // Método de compatibilidad para código existente
  static Future<String?> getPlayerIdByUserId(String userId) async {
    final playerIds = await getPlayerIdsByUserId(userId);
    return playerIds.isNotEmpty ? playerIds.first : null;
  }
  
  // Método para migrar tokens de la tabla antigua a la nueva
  static Future<void> migrateTokensToDevices() async {
    try {
      if (_supabase.auth.currentUser == null) {
        debugPrint('No se puede migrar tokens: Usuario no autenticado');
        return;
      }
      
      final userId = _supabase.auth.currentUser!.id;
      debugPrint('Migrando tokens para el usuario: $userId');
      
      // Obtener todos los tokens del usuario en la tabla antigua
      final oldTokens = await _supabase
          .from('user_push_tokens')
          .select('player_id')
          .eq('user_id', userId);
      
      if (oldTokens.isEmpty) {
        debugPrint('No hay tokens para migrar');
        return;
      }
      
      debugPrint('Encontrados ${oldTokens.length} tokens para migrar');
      final now = DateTime.now().toIso8601String();
      
      // Migrar cada token a la nueva tabla
      for (var token in oldTokens) {
        final playerId = token['player_id'] as String;
        
        // Verificar si ya existe en la nueva tabla
        final existingDevice = await _supabase
            .from('user_devices')
            .select()
            .eq('user_id', userId)
            .eq('onesignal_player_id', playerId)
            .maybeSingle();
        
        if (existingDevice == null) {
          // Crear nuevo registro en user_devices
          await _supabase
              .from('user_devices')
              .insert({
                'user_id': userId,
                'onesignal_player_id': playerId,
                'device_type': 'mobile', // Valor por defecto
                'created_at': now,
                'last_used_at': now,
              });
          debugPrint('Token migrado: $playerId');
        } else {
          debugPrint('Token ya existente en user_devices: $playerId');
        }
      }
      
      debugPrint('Migración completada con éxito');
    } catch (e) {
      debugPrint('Error durante la migración de tokens: $e');
    }
  }
  
  // API Key para OneSignal REST API
  static const String _restApiKey = 'os_v2_app_dc3vwio75bb47f2otj46vqhqdof6zpfdzc3earnlyhgiowm744x4xicqlyvvfestpgn2cw4rv6rix5agp6uxwwm2itnxc7rf2fjke6y';
  
  // Clave global para acceder al navegador desde cualquier parte de la app
  static GlobalKey<NavigatorState>? _navigatorKey;
  
  // Getter para obtener la clave de navegación
  static GlobalKey<NavigatorState> get navigatorKey {
    _navigatorKey ??= GlobalKey<NavigatorState>();
    return _navigatorKey!;
  }
  
  // Setter para establecer la clave de navegación desde fuera
  static set navigatorKey(GlobalKey<NavigatorState> key) {
    _navigatorKey = key;
  }
  
  // Método para manejar la navegación cuando se pulsa una notificación de invitación a partido
  static void _handleMatchInvitationNavigation(int matchId, Map<String, dynamic> data) {
    debugPrint('Preparando navegación a pantalla de unirse al partido con ID: $matchId');
    
    // Construir la ruta con los parámetros necesarios usando los campos que existen en la tabla matches
    final Map<String, dynamic> matchData = {
      'match_id': matchId,
      'match_name': data['match_name'] ?? 'Partido de fútbol',
      'inviter_name': data['inviter_name'] ?? 'Un amigo',
      'nombre': data['nombre'] ?? '',
      'fecha': data['fecha'] ?? '',
      'formato': data['formato'] ?? '',
      'from_notification': true
    };
    
    // Retrasar la navegación para asegurar que la app esté completamente inicializada
    // cuando se abre desde una notificación con la app cerrada
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (navigatorKey.currentState != null) {
        debugPrint('Navegando a JoinMatchScreen después del retraso de inicialización');
        
        // Asegurarse de que estamos en la pantalla principal antes de navegar
        navigatorKey.currentState!.popUntil((route) => route.isFirst);
        
        // Usar pushReplacement en lugar de push para evitar problemas de navegación
        // cuando la app se abre desde una notificación
        navigatorKey.currentState!.pushReplacement(
          MaterialPageRoute(
            builder: (context) => JoinMatchScreen(
              matchId: matchId,
              matchData: matchData,
              fromNotification: true,
            ),
          ),
        );
        
        debugPrint('Navegación iniciada a JoinMatchScreen con ID: $matchId');
      } else {
        // Si todavía no tenemos acceso al navigatorKey, intentar de nuevo después de un tiempo
        debugPrint('navigatorKey.currentState es null, intentando de nuevo en 1 segundo...');
        Future.delayed(const Duration(seconds: 1), () {
          if (navigatorKey.currentState != null) {
            navigatorKey.currentState!.pushReplacement(
              MaterialPageRoute(
                builder: (context) => JoinMatchScreen(
                  matchId: matchId,
                  matchData: matchData,
                  fromNotification: true,
                ),
              ),
            );
            debugPrint('Segundo intento de navegación exitoso');
          } else {
            debugPrint('No se pudo navegar después de múltiples intentos');
          }
        });
      }
    });
  }
  
  // Nota: La autenticación se realiza directamente en el método sendTestNotification
  
  
  // Enviar una notificación usando la API REST de OneSignal
  static Future<void> sendTestNotification({
    required String title,
    required String content,
    Map<String, dynamic>? additionalData,
    String? externalUserId,
    String? playerIds,
    String? userId,
  }) async {
    try {
      debugPrint('Enviando notificación usando la API REST de OneSignal');
      debugPrint('Enviando notificación de prueba:');
      debugPrint('Título: $title');
      debugPrint('Contenido: $content');
      debugPrint('Datos adicionales: $additionalData');
      
      final Uri url = Uri.parse('https://onesignal.com/api/v1/notifications');
      final Map<String, dynamic> requestBody = {
        'app_id': appId,
        'headings': {'en': title},
        'contents': {'en': content},
        'data': additionalData ?? {},
        'target_channel': 'push', // Parámetro requerido según la documentación
      };
      
      // Configurar los destinatarios de la notificación
      if (userId != null && userId.isNotEmpty) {
        // Si tenemos un userId, obtenemos todos sus dispositivos
        final userPlayerIds = await getPlayerIdsByUserId(userId);
        if (userPlayerIds.isNotEmpty) {
          requestBody['include_player_ids'] = userPlayerIds;
          debugPrint('Enviando notificación a todos los dispositivos del usuario $userId: $userPlayerIds');
        } else {
          debugPrint('No se encontraron dispositivos registrados para el usuario $userId');
          return; // No hay dispositivos a los que enviar la notificación
        }
      } else if (externalUserId != null && externalUserId.isNotEmpty) {
        requestBody['include_external_user_ids'] = [externalUserId];
      } else if (playerIds != null && playerIds.isNotEmpty) {
        // Asegurarnos de que playerIds sea siempre un array
        List<String> playerIdList;
        if (playerIds.contains(',')) {
          // Si contiene comas, dividirlo en una lista
          playerIdList = playerIds.split(',').map((id) => id.trim()).toList();
        } else {
          playerIdList = [playerIds];
        }
        requestBody['include_player_ids'] = playerIdList;
        debugPrint('Enviando notificación a player_ids específicos: $playerIdList');
      } else {
        final currentPlayerId = await getPlayerId();
        if (currentPlayerId != null) {
          requestBody['include_player_ids'] = [currentPlayerId];
          debugPrint('Enviando notificación al dispositivo actual: $currentPlayerId');
        } else {
          requestBody['included_segments'] = ['Subscribed Users'];
          debugPrint('Enviando notificación a todos los usuarios suscritos');
        }
      }
      
      // Agregar configuración adicional para mejorar la entrega
      requestBody['channel_for_external_user_ids'] = 'push';
      requestBody['isAnyWeb'] = false;
      
      debugPrint('Cuerpo de la solicitud: ${jsonEncode(requestBody)}');
      
      // Realizar la solicitud HTTP POST
      // Según la documentación oficial de OneSignal, el formato correcto es 'Key YOUR_API_KEY'
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Authorization': 'Key $_restApiKey',
        },
        body: jsonEncode(requestBody),
      );
      
      debugPrint('Código de respuesta: ${response.statusCode}');
      debugPrint('Cuerpo de respuesta: ${response.body}\n');
      
      // Verificar la respuesta
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final responseData = jsonDecode(response.body);
        debugPrint('Notificación enviada correctamente: ${response.statusCode}');
        debugPrint('ID de notificación: ${responseData['id']}');
      }else {
        debugPrint('Error al enviar notificación: ${response.statusCode}');
        debugPrint('Respuesta: ${response.body}');
        throw Exception('Error al enviar notificación: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error al enviar notificación de prueba: $e');
      rethrow; // Relanzar la excepción para que el llamador pueda manejarla
    }
  }
}
