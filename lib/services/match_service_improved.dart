import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'dart:developer' as dev;

/// Servicio mejorado para manejar operaciones relacionadas con partidos
class MatchServiceImproved {
  final SupabaseClient supabase;
  
  const MatchServiceImproved({
    required this.supabase,
  });
  
  /// Crea un nuevo partido utilizando la función SQL mejorada
  Future<Map<String, dynamic>?> createMatch({
    required String matchName,
    required DateTime fecha,
    required String formato,
    required String ubicacion,
    required String descripcion,
    required bool isPublic,
  }) async {
    try {
      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) {
        Fluttertoast.showToast(
          msg: "Debes iniciar sesión para crear un partido",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
        return null;
      }
      
      // Formatear la fecha en formato YYYY-MM-DD HH:MM:SS
      final formattedDateTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(fecha);
      
      // Llamar a la función SQL mejorada para crear el partido
      final result = await supabase.rpc('create_match', params: {
        'p_creador_id': currentUser.id,
        'p_nombre': matchName.trim(),
        'p_formato': formato,
        'p_fecha': formattedDateTime,
        'p_ubicacion': ubicacion.trim(),
        'p_descripcion': descripcion.trim(),
        'p_publico': isPublic,
      });
      
      if (result['success'] == true) {
        Fluttertoast.showToast(
          msg: "Partido creado correctamente",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );
        return result;
      } else {
        Fluttertoast.showToast(
          msg: "Error al crear partido: ${result['message']}",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
        return null;
      }
    } catch (e) {
      dev.log('Error al crear partido: $e');
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
  
  /// Obtiene los detalles de un partido utilizando la función SQL mejorada
  Future<Map<String, dynamic>?> getMatchDetails(int matchId) async {
    try {
      final result = await supabase.rpc('get_match_details', params: {
        'p_match_id': matchId,
      });
      
      if (result['success'] == true) {
        return result['match'];
      } else {
        Fluttertoast.showToast(
          msg: "Error al obtener detalles del partido: ${result['message']}",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
        return null;
      }
    } catch (e) {
      print('Error al obtener detalles del partido: $e');
      Fluttertoast.showToast(
        msg: "Error al obtener detalles del partido",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return null;
    }
  }
  
  /// Actualiza la pantalla de invitación a partido para mostrar correctamente el organizador
  Future<Map<String, dynamic>?> getMatchInvitationDetails(int matchId) async {
    try {
      final matchDetails = await getMatchDetails(matchId);
      if (matchDetails == null) return null;
      
      // Añadir información adicional necesaria para la pantalla de invitación
      matchDetails['organizador'] = matchDetails['creador']['username'] ?? 'Usuario desconocido';
      matchDetails['organizador_avatar'] = matchDetails['creador']['avatar_url'];
      
      return matchDetails;
    } catch (e) {
      print('Error al obtener detalles de invitación: $e');
      return null;
    }
  }
}
