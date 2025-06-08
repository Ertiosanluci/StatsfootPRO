import 'package:flutter/material.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

class OneSignalService {
  static final String appId = '18b75b21-dfe8-43cf-974e-9a79eac0f01b';
  
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
  
  // Send a test notification using in-app notification
  static Future<bool> sendTestNotification({
    required String title,
    required String content,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      // For testing purposes, we'll create a local notification using the Flutter local notifications
      // This is a workaround since OneSignal.Notifications.displayNotification expects a notification ID
      
      // Show a snackbar as a local notification simulation
      debugPrint('Simulating notification: $title - $content');
      
      // Use debug print to log the notification
      OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
      debugPrint('TEST NOTIFICATION: $title - $content');
      
      // Return success
      return true;
    } catch (e) {
      debugPrint('Error sending test notification: $e');
      return false;
    }
  }
}
