import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'dart:developer' as dev;

/// Clase para instalar funciones SQL en la base de datos Supabase
class SqlFunctionInstaller {
  final SupabaseClient supabase;
  
  const SqlFunctionInstaller({required this.supabase});
  
  /// Instala la función SQL mejorada para crear partidos
  Future<bool> installCreateMatchFunction() async {
    try {
      // Leer el contenido del archivo SQL
      final String sqlContent = await File('lib/sql/create_match_improved.sql').readAsString();
      
      // Ejecutar el SQL en Supabase
      await supabase.rpc('exec_sql', params: {
        'sql_query': sqlContent,
      });
      
      dev.log('Función SQL create_match instalada correctamente');
      return true;
    } catch (e) {
      dev.log('Error al instalar la función SQL create_match: $e');
      return false;
    }
  }
  
  /// Instala todas las funciones SQL necesarias para la aplicación
  Future<bool> installAllFunctions() async {
    try {
      // Instalar la función de creación de partidos
      final bool createMatchResult = await installCreateMatchFunction();
      
      // Aquí se pueden agregar más instalaciones de funciones SQL si es necesario
      
      return createMatchResult;
    } catch (e) {
      dev.log('Error al instalar las funciones SQL: $e');
      return false;
    }
  }
}

/// Función para inicializar las funciones SQL en la aplicación
Future<void> initializeSqlFunctions(SupabaseClient supabase) async {
  if (kReleaseMode) {
    // En modo de producción, no instalamos las funciones automáticamente
    dev.log('Modo de producción: no se instalan funciones SQL automáticamente');
    return;
  }
  
  // En modo de desarrollo, instalamos las funciones
  dev.log('Instalando funciones SQL...');
  final installer = SqlFunctionInstaller(supabase: supabase);
  final bool result = await installer.installAllFunctions();
  
  if (result) {
    dev.log('Todas las funciones SQL instaladas correctamente');
  } else {
    dev.log('Error al instalar algunas funciones SQL');
  }
}
