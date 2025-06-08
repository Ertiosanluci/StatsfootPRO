import 'dart:async';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:onesignal_flutter/onesignal_flutter.dart' as onesignal;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider para el servicio de notificaciones push
final pushNotificationServiceProvider = Provider<PushNotificationService>((ref) {
  return PushNotificationService();
});

/// Servicio para manejar las notificaciones push con OneSignal
class PushNotificationService {
  /// OneSignal App ID proporcionado por el usuario
  static const String oneSignalAppId = '18b75b21-dfe8-43cf-974e-9a79eac0f01b';
  
  /// Cliente de Supabase
  final SupabaseClient _supabaseClient = Supabase.instance.client;
  
  /// Inicializa OneSignal y configura los manejadores de notificaciones
  Future<void> initialize() async {
    try {
      // Habilitar el registro en consola para depuración
      onesignal.OneSignal.Debug.setLogLevel(onesignal.OSLogLevel.verbose);
      
      // Inicializar OneSignal con el App ID
      onesignal.OneSignal.initialize(oneSignalAppId);
      
      // Solicitar permisos para notificaciones
      onesignal.OneSignal.Notifications.requestPermission(true);
      
      // Configurar manejadores para notificaciones
      _setupNotificationHandlers();
      
      // Asociar el ID de usuario de Supabase con OneSignal cuando esté autenticado
      await _loginUser();
      
      // Guardar el ID del jugador en Supabase
      await _savePlayerIdToSupabase();
      
      if (kDebugMode) {
        print('OneSignal inicializado correctamente');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error al inicializar OneSignal: $e');
      }
    }
  }
  
  /// Configura los manejadores para las notificaciones
  void _setupNotificationHandlers() {
    // Cuando se recibe una notificación en primer plano
    onesignal.OneSignal.Notifications.addForegroundWillDisplayListener((event) {
      // Mostrar la notificación incluso cuando la app está en primer plano
      if (kDebugMode) {
        print('Notificación recibida en primer plano: ${event.notification.title}');
      }
      
      // Mostrar la notificación
      event.notification.display();
    });
    
    // Cuando se hace clic en una notificación
    onesignal.OneSignal.Notifications.addClickListener((event) {
      if (kDebugMode) {
        print('Notificación abierta: ${event.notification.title}');
        print('Datos adicionales: ${event.notification.additionalData}');
      }
      
      // Aquí se puede implementar la navegación a pantallas específicas
      // según el tipo de notificación y los datos adicionales
    });
    
    // Observar cambios en el estado de la suscripción
    onesignal.OneSignal.User.pushSubscription.addObserver((state) {
      if (kDebugMode) {
        print('Estado de suscripción: ${state.current.jsonRepresentation()}');
      }
    });
  }
  
  /// Asocia el ID de usuario de Supabase con OneSignal
  Future<void> _loginUser() async {
    final String? userId = _supabaseClient.auth.currentUser?.id;
    
    if (userId != null) {
      // Establecer el ID externo de usuario en OneSignal
      onesignal.OneSignal.login(userId);
      
      if (kDebugMode) {
        print('OneSignal: ID externo de usuario establecido: $userId');
      }
    } else {
      if (kDebugMode) {
        print('No se pudo asociar el ID de usuario: Usuario no autenticado');
      }
    }
  }
  
  /// Guarda el ID del jugador de OneSignal en Supabase
  Future<void> _savePlayerIdToSupabase() async {
    try {
      // Obtener el ID del usuario actual
      final String? userId = _supabaseClient.auth.currentUser?.id;
      
      if (userId != null) {
        // Esperar un momento para asegurar que OneSignal haya generado el ID
        await Future.delayed(const Duration(seconds: 2));
        
        // Obtener el ID del jugador de OneSignal
        final String? playerId = await getPlayerId();
        
        if (playerId != null && playerId.isNotEmpty) {
          // Guardar el ID del jugador en la tabla profiles
          await _supabaseClient
              .from('profiles')
              .update({'onesignal_id': playerId})
              .eq('id', userId);
          
          if (kDebugMode) {
            print('ID de OneSignal guardado en Supabase: $playerId');
          }
        } else {
          if (kDebugMode) {
            print('No se pudo obtener el ID del jugador de OneSignal');
          }
        }
      } else {
        if (kDebugMode) {
          print('Usuario no autenticado');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error al guardar el ID del jugador en Supabase: $e');
      }
    }
  }
  
  /// Obtiene el ID del jugador de OneSignal
  Future<String?> getPlayerId() async {
    return onesignal.OneSignal.User.pushSubscription.id;
  }
  
  /// Cierra la sesión del usuario en OneSignal
  Future<void> logout() async {
    onesignal.OneSignal.logout();
    if (kDebugMode) {
      print('Usuario desconectado de OneSignal');
    }
  }
}
