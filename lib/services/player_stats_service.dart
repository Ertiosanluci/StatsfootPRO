import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Servicio para manejar las estadísticas de los jugadores
/// Proporciona métodos para actualizar estadísticas, calcular marcadores
/// y manejar la sincronización con la base de datos
class PlayerStatsService {
  final SupabaseClient supabase;
  
  const PlayerStatsService({
    required this.supabase,
  });
  
  /// Actualiza las estadísticas de un jugador y recalcula el marcador del partido
  /// Retorna el nuevo marcador como un Map con 'resultado_claro' y 'resultado_oscuro'
  Future<Map<String, int>> updatePlayerStats({
    required dynamic playerId,
    required int goles,
    required int asistencias,
    required int golesPropios,
    required bool isTeamClaro,
    required int matchId,
  }) async {
    try {
      // Convertir matchId a int si es necesario
      int matchIdInt;
      if (matchId is int) {
        matchIdInt = matchId;
      } else {
        matchIdInt = int.parse(matchId.toString());
      }
      
      // Verificar si existe un registro para este jugador y partido
      final statsResponse = await supabase
          .from('estadisticas')
          .select()
          .eq('jugador_id', playerId)
          .eq('partido_id', matchIdInt)
          .maybeSingle();
      
      // Crear o actualizar el registro
      if (statsResponse == null) {
        // Crear nuevo registro
        await supabase.from('estadisticas').insert({
          'jugador_id': playerId,
          'partido_id': matchIdInt,
          'goles': goles,
          'asistencias': asistencias,
          'goles_propios': golesPropios,
          'equipo': isTeamClaro ? 'team_claro' : 'team_oscuro',
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
            .eq('partido_id', matchIdInt);
      }
      
      // Recalcular y actualizar el marcador
      final Map<String, int> newScore = await _recalculateMatchScore(matchIdInt);
            
      // Mostrar mensaje de éxito
      Fluttertoast.showToast(
        msg: "Estadísticas actualizadas",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );
      
      return newScore;
      
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
      
      return {'resultado_claro': 0, 'resultado_oscuro': 0};
    }
  }
  
  /// Recalcula el marcador del partido basado en todas las estadísticas
  /// Actualiza la base de datos y devuelve el nuevo marcador
  Future<Map<String, int>> _recalculateMatchScore(int matchId) async {
    try {
      // Obtener todos los datos de estadísticas
      final allStats = await supabase
          .from('estadisticas')
          .select('goles, goles_propios, equipo')
          .eq('partido_id', matchId);
      
      // Calcular los goles para cada equipo
      int golesEquipoClaro = 0;
      int golesEquipoOscuro = 0;
      
      for (var stat in allStats) {
        if (stat['equipo'] == 'team_claro') {
          // Goles directos del equipo claro
          golesEquipoClaro += (stat['goles'] as int? ?? 0);
        } else if (stat['equipo'] == 'team_oscuro') {
          // Goles directos del equipo oscuro
          golesEquipoOscuro += (stat['goles'] as int? ?? 0);
        }
      }
      
      // Sumar goles en propia puerta del equipo contrario
      // Los goles en propia puerta del equipo claro suman para el equipo oscuro
      final golesPropiosClaro = await supabase
          .from('estadisticas')
          .select('goles_propios')
          .eq('partido_id', matchId)
          .eq('equipo', 'team_claro');
          
      for (var stat in golesPropiosClaro) {
        golesEquipoOscuro += (stat['goles_propios'] as int? ?? 0);
      }
      
      // Los goles en propia puerta del equipo oscuro suman para el equipo claro
      final golesPropiosOscuro = await supabase
          .from('estadisticas')
          .select('goles_propios')
          .eq('partido_id', matchId)
          .eq('equipo', 'team_oscuro');
          
      for (var stat in golesPropiosOscuro) {
        golesEquipoClaro += (stat['goles_propios'] as int? ?? 0);
      }
      
      // Actualizar el marcador en la base de datos
      await supabase
          .from('partidos')
          .update({
            'resultado_claro': golesEquipoClaro,
            'resultado_oscuro': golesEquipoOscuro
          })
          .eq('id', matchId);
          
      return {
        'resultado_claro': golesEquipoClaro,
        'resultado_oscuro': golesEquipoOscuro
      };
    } catch (e) {
      print('Error al recalcular marcador: $e');
      throw Exception('Error al recalcular marcador: $e');
    }
  }
  
  /// Finaliza un partido y establece los MVPs
  Future<void> finalizeMatch({
    required int matchId,
    required String? mvpTeamClaro,
    required String? mvpTeamOscuro,
  }) async {
    try {
      await supabase
          .from('partidos')
          .update({
            'estado': 'finalizado',
            'mvp_team_claro': mvpTeamClaro,
            'mvp_team_oscuro': mvpTeamOscuro,
            'fecha_fin': DateTime.now().toIso8601String(),
          })
          .eq('id', matchId);
      
      Fluttertoast.showToast(
        msg: "Partido finalizado con éxito",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );
    } catch (e) {
      print('Error al finalizar partido: $e');
      
      Fluttertoast.showToast(
        msg: "Error al finalizar el partido",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      
      throw Exception('Error al finalizar partido: $e');
    }
  }
  
  /// Actualiza las posiciones de los jugadores en el campo
  Future<void> updatePlayerPositions({
    required int matchId, 
    required String team,
    required Map<String, Offset> positions,
  }) async {
    try {
      // Convertir las posiciones a un formato que pueda ser almacenado en Supabase
      final Map<String, Map<String, double>> positionsMap = {};
      
      positions.forEach((playerId, offset) {
        positionsMap[playerId] = {
          'x': offset.dx,
          'y': offset.dy,
        };
      });
      
      // Actualizar en la base de datos
      await supabase
          .from('partidos')
          .update({
            '${team}_positions': positionsMap,
          })
          .eq('id', matchId);
      
    } catch (e) {
      print('Error al actualizar posiciones: $e');
      throw Exception('Error al actualizar posiciones: $e');
    }
  }
  
  /// Carga las posiciones de los jugadores desde la base de datos
  Future<Map<String, Offset>> loadPlayerPositions({
    required int matchId,
    required String team,
  }) async {
    try {
      final response = await supabase
          .from('partidos')
          .select('${team}_positions')
          .eq('id', matchId)
          .single();
      
      final Map<String, Offset> positions = {};
      final positionsData = response['${team}_positions'] as Map?;
      
      if (positionsData != null) {
        positionsData.forEach((playerId, position) {
          if (position is Map && position.containsKey('x') && position.containsKey('y')) {
            positions[playerId.toString()] = Offset(
              (position['x'] as num).toDouble(),
              (position['y'] as num).toDouble(),
            );
          }
        });
      }
      
      return positions;
    } catch (e) {
      print('Error al cargar posiciones: $e');
      return {};
    }
  }
}
