import 'package:flutter/material.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';

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
      
      // Add notification will display in foreground handler
      OneSignal.Notifications.addForegroundWillDisplayListener(
        (OSNotificationWillDisplayEvent event) {
          // Will be called whenever a notification is received in foreground
          debugPrint('Notification received in foreground: ${event.notification.title}');
          
          // Complete with null means show the notification
          event.notification.display();
        }
      );
      
      // Add notification click listener
      OneSignal.Notifications.addClickListener((OSNotificationClickEvent event) {
        // Will be called whenever a notification is opened/button pressed
        debugPrint('Notification clicked: ${event.notification.title}');
        
        // Handle notification data
        final additionalData = event.notification.additionalData;
        if (additionalData != null) {
          debugPrint('Additional data: $additionalData');
          // Handle navigation or other actions based on data
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
  
  // Guardar el token del dispositivo (player ID) en Supabase
  static Future<void> savePlayerIdToSupabase(String playerId) async {
    try {
      if (_supabase.auth.currentUser == null) {
        debugPrint('No se puede guardar el player ID: Usuario no autenticado');
        return;
      }
      
      final userId = _supabase.auth.currentUser!.id;
      
      // Verificar si ya existe un registro para este usuario
      final existingData = await _supabase
          .from('user_push_tokens')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      
      if (existingData != null) {
        // Actualizar el registro existente
        await _supabase
            .from('user_push_tokens')
            .update({
              'player_id': playerId,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('user_id', userId);
        debugPrint('Token de dispositivo actualizado para el usuario: $userId');
      } else {
        // Crear un nuevo registro
        await _supabase
            .from('user_push_tokens')
            .insert({
              'user_id': userId,
              'player_id': playerId,
              'device_type': 'mobile', // Puedes obtener más información del dispositivo si lo necesitas
              'created_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            });
        debugPrint('Token de dispositivo guardado para el usuario: $userId');
      }
    } catch (e) {
      debugPrint('Error al guardar el token del dispositivo: $e');
      // Si el error es porque la tabla no existe, mostramos un mensaje específico
      if (e.toString().contains('relation "public.user_push_tokens" does not exist')) {
        debugPrint('La tabla user_push_tokens no existe en la base de datos. Por favor, créala primero.');
      }
    }
  }
  
  // Obtener el player ID de un usuario específico desde Supabase
  static Future<String?> getPlayerIdByUserId(String userId) async {
    try {
      final data = await _supabase
          .from('user_push_tokens')
          .select('player_id')
          .eq('user_id', userId)
          .maybeSingle();
      
      return data != null ? data['player_id'] as String? : null;
    } catch (e) {
      debugPrint('Error al obtener el player ID del usuario $userId: $e');
      return null;
    }
  }
  
  // API Key para OneSignal REST API
  static const String _restApiKey = 'dc3vwio75bb47f2otj46vqhqdof6zpfdzc3earnlyhgiowm744x4xicqlyvvfestpgn2cw4rv6rix5agp6uxwwm2itnxc7rf2fjke6y';
  
  // Enviar una notificación usando la API REST de OneSignal
  static Future<void> sendTestNotification({
    required String title,
    required String content,
    Map<String, dynamic>? additionalData,
    String? externalUserId, // ID del usuario destinatario (opcional)
    String? playerIds, // IDs de dispositivos específicos (opcional)
  }) async {
    try {
      // Log para depuración
      debugPrint('Enviando notificación de prueba:');
      debugPrint('Título: $title');
      debugPrint('Contenido: $content');
      if (additionalData != null) {
        debugPrint('Datos adicionales: $additionalData');
      }
      
      // Para la API v2 de OneSignal
      final Uri url = Uri.parse('https://onesignal.com/api/v2/notifications');
      
      // Preparar el cuerpo de la solicitud
      final Map<String, dynamic> requestBody = {
        'app_id': appId,
        'headings': {'en': title},
        'contents': {'en': content},
        'data': additionalData ?? {},
      };
      
      // Configurar los destinatarios de la notificación
      if (externalUserId != null && externalUserId.isNotEmpty) {
        // Si se proporciona un ID de usuario específico
        requestBody['include_external_user_ids'] = [externalUserId];
      } 
      else if (playerIds != null && playerIds.isNotEmpty) {
        // Si se proporciona un ID de dispositivo específico
        requestBody['include_player_ids'] = [playerIds];
        debugPrint('Enviando notificación al dispositivo específico: $playerIds');
      } 
      else {
        // Para pruebas, enviar solo al dispositivo actual
        final currentPlayerId = await getPlayerId();
        if (currentPlayerId != null) {
          requestBody['include_player_ids'] = [currentPlayerId];
          debugPrint('Enviando notificación al dispositivo actual: $currentPlayerId');
        } else {
          // Si no podemos obtener el ID actual, enviar a todos los suscriptores
          requestBody['included_segments'] = ['Subscribed Users'];
          debugPrint('Enviando notificación a todos los usuarios suscritos');
        }
      }
      
      // Agregar configuración adicional para mejorar la entrega
      requestBody['channel_for_external_user_ids'] = 'push';
      requestBody['isAnyWeb'] = false;
      
      debugPrint('Cuerpo de la solicitud: ${jsonEncode(requestBody)}');
      
      // Realizar la solicitud HTTP POST
      // Para la API REST de OneSignal, usamos Basic Auth
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Authorization': 'Basic $_restApiKey',
        },
        body: jsonEncode(requestBody),
      );
      
      // Verificar la respuesta
      debugPrint('Código de respuesta: ${response.statusCode}');
      debugPrint('Cuerpo de respuesta: ${response.body}');
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final responseData = jsonDecode(response.body);
        debugPrint('Notificación enviada correctamente: ${response.statusCode}');
        debugPrint('ID de notificación: ${responseData['id']}');
      } else {
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
