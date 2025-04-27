import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseClient {
  static final SupabaseClient _instance = SupabaseClient._internal();
  factory SupabaseClient() => _instance;
  SupabaseClient._internal();

  final supabase = Supabase.instance.client;

  void initialize() async {
    await Supabase.initialize(
      url: 'https://vlygdxrppzoqlkntfypx.supabase.co', // Reemplaza con tu URL de Supabase
        anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZseWdkeHJwcHpvcWxrbnRmeXB4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDAwMzk0MDEsImV4cCI6MjA1NTYxNTQwMX0.gch5BXjGqXbNI2f0zkA3wPg2b357ZfxF97AMEk5CPdE',  // Reemplaza con tu clave pública
    );
  }
}