import 'package:supabase_flutter/supabase_flutter.dart';

class DebugFunctions {
  static final SupabaseClient _supabase = Supabase.instance.client;

  // Verificar si existe la función create_match_invitation
  static Future<void> checkFunctionExists() async {
    try {
      // Intentar ejecutar la función con parámetros de prueba
      final result = await _supabase.rpc('create_match_invitation', params: {
        'p_match_id': 999999, // ID que no existe
        'p_inviter_id': 'test',
        'p_invited_id': 'test'
      });
      print('Función existe - Resultado: $result');
    } catch (e) {
      print('Error al ejecutar función: $e');
      
      // Verificar el tipo de error
      if (e.toString().contains('function') && e.toString().contains('does not exist')) {
        print('❌ La función create_match_invitation NO existe en la base de datos');
      } else {
        print('✅ La función existe pero hay otro tipo de error: $e');
      }
    }
  }

  // Verificar si las tablas necesarias existen
  static Future<void> checkTablesExist() async {
    final tables = ['match_invitations', 'notifications', 'matches', 'profiles'];
    
    for (String table in tables) {
      try {
        await _supabase.from(table).select('*').limit(1);
        print('✅ Tabla $table existe');
      } catch (e) {
        print('❌ Tabla $table NO existe o no tienes permisos: $e');
      }
    }
  }

  // Verificar la estructura de la tabla match_invitations
  static Future<void> checkMatchInvitationsStructure() async {
    try {
      final result = await _supabase
          .from('match_invitations')
          .select('*')
          .limit(1);
      
      if (result.isNotEmpty) {
        print('✅ match_invitations tiene datos. Estructura de ejemplo:');
        print(result.first.keys.toList());
      } else {
        print('✅ match_invitations existe pero está vacía');
      }
    } catch (e) {
      print('❌ Error al acceder a match_invitations: $e');
    }
  }
}
