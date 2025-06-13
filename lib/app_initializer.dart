import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:developer' as dev;
import 'sql/install_sql_functions.dart';

/// Clase para inicializar la aplicación
class AppInitializer {
  final SupabaseClient supabase;
  
  const AppInitializer({required this.supabase});
  
  /// Inicializa todos los componentes necesarios para la aplicación
  Future<void> initialize() async {
    try {
      // Inicializar funciones SQL en modo desarrollo
      if (!kReleaseMode) {
        await initializeSqlFunctions(supabase);
      }
      
      // Aquí se pueden agregar más inicializaciones si es necesario
      
      dev.log('Aplicación inicializada correctamente');
    } catch (e) {
      dev.log('Error al inicializar la aplicación: $e');
    }
  }
}

/// Función para inicializar la aplicación
Future<void> initializeApp(SupabaseClient supabase) async {
  final initializer = AppInitializer(supabase: supabase);
  await initializer.initialize();
}
