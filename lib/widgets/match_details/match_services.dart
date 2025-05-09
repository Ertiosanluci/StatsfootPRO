import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fluttertoast/fluttertoast.dart';

/// Clase de servicios para manejar la lógica de datos del partido
class MatchServices {
  final SupabaseClient supabase = Supabase.instance.client;
  
  /// Obtiene los detalles del partido por su ID
  Future<Map<String, dynamic>> getMatchDetails(dynamic matchId) async {
    try {
      // Convertir matchId a int si es necesario
      int matchIdInt;
      if (matchId is int) {
        matchIdInt = matchId;
      } else {
        matchIdInt = int.parse(matchId.toString());
      }
      
      // Obtener los datos del partido usando la tabla 'matches'
      final response = await supabase
          .from('matches')
          .select('*')
          .eq('id', matchIdInt)
          .maybeSingle();
      
      // Verificar si se encontró el partido
      if (response == null) {
        throw Exception('No se encontró ningún partido con el ID $matchIdInt');
      }
      
      return response;
    } catch (e) {
      print('Error al cargar detalles del partido: $e');
      throw e;
    }
  }
  
  /// Obtiene los participantes del partido con información detallada
  Future<Map<String, List<Map<String, dynamic>>>> getMatchParticipants(int matchId) async {
    List<Map<String, dynamic>> teamClaro = [];
    List<Map<String, dynamic>> teamOscuro = [];
    
    try {
      // Imprimir ID del partido para depuración
      print('Obteniendo participantes para el partido ID: $matchId');
      
      // Obtener todos los participantes del partido con sus usernames desde profiles usando RPC
      final response = await supabase
          .rpc('get_match_participants_with_profiles', params: {'match_id_param': matchId});
      
      if (response == null || response.isEmpty) {
        print('No se encontraron participantes para el partido $matchId');
        
        // Si la RPC falla, intentar método de respaldo
        return await _getParticipantsFallback(matchId);
      }
      
      List<dynamic> participants = response;
      
      // Procesar los resultados y dividir en equipos
      for (var participant in participants) {
        Map<String, dynamic> playerData = {
          'id': participant['user_id'],
          'nombre': participant['username'] ?? 'Usuario sin nombre',
          'foto_perfil': participant['avatar_url'],
          'es_organizador': participant['es_organizador'] ?? false,
        };
        
        // Obtener estadísticas del jugador en este partido
        final statsResponse = await supabase
            .from('estadisticas')
            .select('*')
            .eq('jugador_id', playerData['id'])
            .eq('partido_id', matchId)
            .maybeSingle();
        
        // Añadir estadísticas si existen
        if (statsResponse != null) {
          playerData['goles'] = statsResponse['goles'] ?? 0;
          playerData['asistencias'] = statsResponse['asistencias'] ?? 0;
          playerData['goles_propios'] = statsResponse['goles_propios'] ?? 0;
        } else {
          playerData['goles'] = 0;
          playerData['asistencias'] = 0;
          playerData['goles_propios'] = 0;
        }
        
        // Agregar al equipo correspondiente según el valor de 'equipo'
        if (participant['equipo'] == 'claro') {
          teamClaro.add(playerData);
        } else if (participant['equipo'] == 'oscuro') {
          teamOscuro.add(playerData);
        }
      }
      
      return {
        'teamClaro': teamClaro,
        'teamOscuro': teamOscuro,
      };
    } catch (e) {
      print('Error al cargar participantes del partido: $e');
      
      // Intentar método de respaldo si falla la función RPC
      return await _getParticipantsFallback(matchId);
    }
  }
  
  /// Método de respaldo para obtener participantes si falla el RPC
  Future<Map<String, List<Map<String, dynamic>>>> _getParticipantsFallback(int matchId) async {
    List<Map<String, dynamic>> teamClaro = [];
    List<Map<String, dynamic>> teamOscuro = [];
    
    try {
      print('Ejecutando método de respaldo para obtener participantes');
      
      final response = await supabase
          .from('match_participants')
          .select('''
            match_id, 
            user_id, 
            equipo, 
            es_organizador, 
            joined_at,
            profiles!inner(id, username, avatar_url)
          ''')
          .eq('match_id', matchId);
      
      print('Método de respaldo - participantes encontrados: ${response.length}');
      
      for (var item in response) {
        // Extraer los datos de profiles que están anidados
        final profile = item['profiles'];
        
        Map<String, dynamic> playerData = {
          'id': item['user_id'],
          'nombre': profile['username'] ?? 'Usuario sin nombre',
          'foto_perfil': profile['avatar_url'],
          'es_organizador': item['es_organizador'] ?? false,
        };
        
        // Obtener estadísticas
        final statsResponse = await supabase
            .from('estadisticas')
            .select('*')
            .eq('jugador_id', playerData['id'])
            .eq('partido_id', matchId)
            .maybeSingle();
        
        if (statsResponse != null) {
          playerData['goles'] = statsResponse['goles'] ?? 0;
          playerData['asistencias'] = statsResponse['asistencias'] ?? 0;
          playerData['goles_propios'] = statsResponse['goles_propios'] ?? 0;
        } else {
          playerData['goles'] = 0;
          playerData['asistencias'] = 0;
          playerData['goles_propios'] = 0;
        }
        
        // Agregar al equipo correspondiente
        if (item['equipo'] == 'claro') {
          teamClaro.add(playerData);
        } else if (item['equipo'] == 'oscuro') {
          teamOscuro.add(playerData);
        }
      }
      
      return {
        'teamClaro': teamClaro,
        'teamOscuro': teamOscuro,
      };
    } catch (e) {
      print('Error en método de respaldo para cargar participantes: $e');
      
      // Devolver listas vacías si todo falla
      return {
        'teamClaro': [],
        'teamOscuro': [],
      };
    }
  }
  
  /// Actualizar las estadísticas del jugador en el partido
  Future<void> updatePlayerStats(int matchId, dynamic playerId, int goles, int asistencias, int golesPropios, bool isTeamClaro) async {
    try {
      // Verificar si existe un registro para este jugador y partido
      final statsResponse = await supabase
          .from('estadisticas')
          .select()
          .eq('jugador_id', playerId)
          .eq('partido_id', matchId)
          .maybeSingle();
      
      // Crear o actualizar el registro
      if (statsResponse == null) {
        // Crear nuevo registro
        await supabase.from('estadisticas').insert({
          'jugador_id': playerId,
          'partido_id': matchId,
          'goles': goles,
          'asistencias': asistencias,
          'goles_propios': golesPropios,
          'equipo': isTeamClaro ? 'claro' : 'oscuro',
        });
      } else {
        // Actualizar registro existente
        await supabase
            .from('estadisticas')
            .update({
              'goles': goles,
              'asistencias': asistencias,
              'goles_propios': golesPropios,
            })
            .eq('jugador_id', playerId)
            .eq('partido_id', matchId);
      }
      
      // Mostrar mensaje de éxito
      Fluttertoast.showToast(
        msg: "Estadísticas actualizadas",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );
      
    } catch (e) {
      print('Error al actualizar estadísticas: $e');
      
      // Mostrar mensaje de error
      Fluttertoast.showToast(
        msg: "Error al actualizar estadísticas",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      
      throw e;
    }
  }
  
  /// Actualizar el marcador del partido
  Future<Map<String, dynamic>> updateMatchScore(int matchId) async {
    try {
      // Obtener todas las estadísticas de este partido
      final allStats = await supabase
          .from('estadisticas')
          .select('goles, goles_propios, equipo')
          .eq('partido_id', matchId);
      
      // Calcular los goles para cada equipo
      int golesEquipoClaro = 0;
      int golesEquipoOscuro = 0;
      
      for (var stat in allStats) {
        if (stat['equipo'] == 'claro') {
          // Goles directos del equipo claro
          golesEquipoClaro += (stat['goles'] as int? ?? 0);
        } else if (stat['equipo'] == 'oscuro') {
          // Goles directos del equipo oscuro
          golesEquipoOscuro += (stat['goles'] as int? ?? 0);
        }
      }
      
      // Sumar goles en propia puerta (los goles en propia del equipo claro suman para el oscuro y viceversa)
      for (var stat in allStats) {
        if (stat['equipo'] == 'claro' && stat['goles_propios'] != null) {
          golesEquipoOscuro += (stat['goles_propios'] as int? ?? 0);
        } else if (stat['equipo'] == 'oscuro' && stat['goles_propios'] != null) {
          golesEquipoClaro += (stat['goles_propios'] as int? ?? 0);
        }
      }
      
      // Actualizar el marcador en la base de datos
      await supabase
          .from('matches')
          .update({
            'resultado_claro': golesEquipoClaro,
            'resultado_oscuro': golesEquipoOscuro,
          })
          .eq('id', matchId);
      
      return {
        'resultado_claro': golesEquipoClaro,
        'resultado_oscuro': golesEquipoOscuro,
      };
      
    } catch (e) {
      print('Error al actualizar marcador: $e');
      throw e;
    }
  }
  
  /// Guardar las posiciones de los jugadores en la base de datos
  Future<void> savePlayerPositions(int matchId, Map<String, dynamic> positions, bool isTeamClaro) async {
    try {
      // Actualizar en la base de datos según el equipo
      if (isTeamClaro) {
        await supabase
            .from('matches')
            .update({'team_claro_positions': positions})
            .eq('id', matchId);
      } else {
        await supabase
            .from('matches')
            .update({'team_oscuro_positions': positions})
            .eq('id', matchId);
      }
      
      // Mostrar mensaje de éxito
      Fluttertoast.showToast(
        msg: "Posiciones guardadas correctamente",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );
      
    } catch (e) {
      print('Error al guardar posiciones: $e');
      
      // Mostrar mensaje de error
      Fluttertoast.showToast(
        msg: "Error al guardar posiciones",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      
      throw e;
    }
  }
  
  /// Finalizar el partido
  Future<void> finishMatch(int matchId, String? mvpTeamClaro, String? mvpTeamOscuro) async {
    try {
      // Actualizar el estado del partido a "finalizado" y guardar los MVPs
      await supabase
          .from('matches')
          .update({
            'estado': 'finalizado',
            'mvp_team_claro': mvpTeamClaro,
            'mvp_team_oscuro': mvpTeamOscuro
          })
          .eq('id', matchId);
      
    } catch (e) {
      print('Error al finalizar el partido: $e');
      throw e;
    }
  }
}