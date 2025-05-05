import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Servicio para manejar operaciones relacionadas con partidos
class MatchService {
  final SupabaseClient supabase;
  
  const MatchService({
    required this.supabase,
  });
  
  /// Carga los detalles de un partido específico
  Future<Map<String, dynamic>> loadMatchDetails(dynamic matchId) async {
    try {
      // Convertir matchId a int si es necesario
      int matchIdInt;
      if (matchId is int) {
        matchIdInt = matchId;
      } else {
        matchIdInt = int.parse(matchId.toString());
      }
      
      // Obtener datos del partido
      final matchData = await supabase
          .from('partidos')
          .select()
          .eq('id', matchIdInt)
          .single();
      
      return matchData;
    } catch (e) {
      print('Error al cargar detalles del partido: $e');
      Fluttertoast.showToast(
        msg: "Error al cargar detalles del partido",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      
      throw Exception('Error al cargar detalles del partido: $e');
    }
  }
  
  /// Carga los equipos (jugadores) de un partido
  Future<Map<String, List<Map<String, dynamic>>>> loadMatchTeams(dynamic matchId) async {
    try {
      int matchIdInt = matchId is int ? matchId : int.parse(matchId.toString());
      
      // Obtener los jugadores del equipo claro
      final teamClaro = await supabase
          .from('equipos_partido_jugadores')
          .select('*, jugadores(*)')
          .eq('partido_id', matchIdInt)
          .eq('equipo', 'team_claro');
      
      // Obtener los jugadores del equipo oscuro
      final teamOscuro = await supabase
          .from('equipos_partido_jugadores')
          .select('*, jugadores(*)')
          .eq('partido_id', matchIdInt)
          .eq('equipo', 'team_oscuro');
      
      // Procesar los datos para obtener un formato manejable
      List<Map<String, dynamic>> processedTeamClaro = [];
      List<Map<String, dynamic>> processedTeamOscuro = [];
      
      // Procesar equipo claro
      for (var player in teamClaro) {
        if (player['jugadores'] != null) {
          Map<String, dynamic> playerData = {...player['jugadores']};
          
          // Obtener estadísticas del jugador para este partido
          final playerStats = await supabase
              .from('estadisticas')
              .select()
              .eq('jugador_id', playerData['id'])
              .eq('partido_id', matchIdInt)
              .maybeSingle();
          
          if (playerStats != null) {
            playerData['goles'] = playerStats['goles'] ?? 0;
            playerData['asistencias'] = playerStats['asistencias'] ?? 0;
            playerData['goles_propios'] = playerStats['goles_propios'] ?? 0;
          } else {
            playerData['goles'] = 0;
            playerData['asistencias'] = 0;
            playerData['goles_propios'] = 0;
          }
          
          processedTeamClaro.add(playerData);
        }
      }
      
      // Procesar equipo oscuro
      for (var player in teamOscuro) {
        if (player['jugadores'] != null) {
          Map<String, dynamic> playerData = {...player['jugadores']};
          
          // Obtener estadísticas del jugador para este partido
          final playerStats = await supabase
              .from('estadisticas')
              .select()
              .eq('jugador_id', playerData['id'])
              .eq('partido_id', matchIdInt)
              .maybeSingle();
          
          if (playerStats != null) {
            playerData['goles'] = playerStats['goles'] ?? 0;
            playerData['asistencias'] = playerStats['asistencias'] ?? 0;
            playerData['goles_propios'] = playerStats['goles_propios'] ?? 0;
          } else {
            playerData['goles'] = 0;
            playerData['asistencias'] = 0;
            playerData['goles_propios'] = 0;
          }
          
          processedTeamOscuro.add(playerData);
        }
      }
      
      return {
        'teamClaro': processedTeamClaro,
        'teamOscuro': processedTeamOscuro,
      };
    } catch (e) {
      print('Error al cargar equipos del partido: $e');
      Fluttertoast.showToast(
        msg: "Error al cargar equipos del partido",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      
      throw Exception('Error al cargar equipos del partido: $e');
    }
  }
  
  /// Busca un partido por su código
  Future<Map<String, dynamic>?> findMatchByCode(String matchCode) async {
    try {
      final result = await supabase
          .from('partidos')
          .select()
          .eq('codigo', matchCode)
          .maybeSingle();
      
      return result;
    } catch (e) {
      print('Error al buscar partido: $e');
      return null;
    }
  }
  
  /// Añade un jugador a un partido existente
  Future<bool> joinMatch({
    required int matchId,
    required int playerId,
    required String team,
  }) async {
    try {
      // Verificar si el jugador ya está en el partido
      final existingPlayer = await supabase
          .from('equipos_partido_jugadores')
          .select()
          .eq('partido_id', matchId)
          .eq('jugador_id', playerId)
          .maybeSingle();
      
      if (existingPlayer != null) {
        // El jugador ya está en el partido, podríamos actualizar su equipo si es diferente
        if (existingPlayer['equipo'] != team) {
          await supabase
              .from('equipos_partido_jugadores')
              .update({'equipo': team})
              .eq('id', existingPlayer['id']);
        }
      } else {
        // Añadir el jugador al partido
        await supabase.from('equipos_partido_jugadores').insert({
          'partido_id': matchId,
          'jugador_id': playerId,
          'equipo': team,
        });
      }
      
      Fluttertoast.showToast(
        msg: "Te has unido al partido exitosamente",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );
      
      return true;
    } catch (e) {
      print('Error al unirse al partido: $e');
      Fluttertoast.showToast(
        msg: "Error al unirse al partido",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      
      return false;
    }
  }
  
  /// Crea un nuevo partido
  Future<Map<String, dynamic>?> createMatch({
    required String matchName,
    required DateTime fecha,
    required String ubicacion,
  }) async {
    try {
      // Generar un código único para el partido
      String matchCode = _generateMatchCode();
      
      // Crear el partido
      final result = await supabase.from('partidos').insert({
        'nombre': matchName,
        'fecha': fecha.toIso8601String(),
        'ubicacion': ubicacion,
        'estado': 'pendiente',
        'codigo': matchCode,
        'resultado_claro': 0,
        'resultado_oscuro': 0,
      }).select();
      
      if (result.isNotEmpty) {
        return result[0];
      }
      
      return null;
    } catch (e) {
      print('Error al crear partido: $e');
      Fluttertoast.showToast(
        msg: "Error al crear partido",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      
      return null;
    }
  }
  
  /// Genera un código aleatorio para un partido
  String _generateMatchCode() {
    const String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    String code = '';
    
    for (int i = 0; i < 6; i++) {
      code += chars[DateTime.now().millisecondsSinceEpoch % chars.length];
    }
    
    return code;
  }
}
