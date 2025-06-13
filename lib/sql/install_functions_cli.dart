import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:developer' as dev;
import 'install_sql_functions.dart';

/// Script de línea de comandos para instalar funciones SQL
void main() async {
  try {
    // Inicializar Supabase
    await Supabase.initialize(
      url: 'https://vlygdxrppzoqlkntfypx.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZseWdkeHJwcHpvcWxrbnRmeXB4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDAwMzk0MDEsImV4cCI6MjA1NTYxNTQwMX0.gch5BXjGqXbNI2f0zkA3wPg2b357ZfxF97AMEk5CPdE',
    );
    
    print('Supabase inicializado correctamente');
    
    // Obtener la instancia de Supabase
    final supabase = Supabase.instance.client;
    
    // Crear el instalador de funciones SQL
    final installer = SqlFunctionInstaller(supabase: supabase);
    
    // Instalar todas las funciones SQL
    print('Instalando funciones SQL...');
    final bool result = await installer.installAllFunctions();
    
    if (result) {
      print('✅ Todas las funciones SQL instaladas correctamente');
    } else {
      print('❌ Error al instalar algunas funciones SQL');
    }
  } catch (e) {
    print('❌ Error: $e');
  } finally {
    // Cerrar la aplicación
    print('Finalizando script...');
  }
}
