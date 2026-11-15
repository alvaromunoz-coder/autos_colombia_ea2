import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

class ControlAccesoService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Convierte la respuesta de una RPC a un mapa, tolerando los formatos que
  /// puede devolver PostgREST (objeto JSON, cadena JSON o lista de un elemento).
  Map<String, dynamic> _decodificarRespuesta(dynamic response) {
    if (response is Map) {
      return Map<String, dynamic>.from(response);
    }
    if (response is String) {
      final decoded = jsonDecode(response);
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
      throw FormatException('La respuesta RPC no es un objeto JSON: $response');
    }
    if (response is List && response.isNotEmpty) {
      final first = response.first;
      if (first is Map) {
        return Map<String, dynamic>.from(first);
      }
    }
    throw FormatException('Respuesta RPC inesperada: $response');
  }

  /// Traduce errores técnicos a mensajes claros y accionables.
  String _mensajeDeError(Object error) {
    if (error is PostgrestException) {
      // La función no existe en la base de datos (el script no se ha ejecutado).
      if (error.code == 'PGRST202' ||
          error.message.contains('Could not find the function')) {
        return 'La función de base de datos no existe. Abre Supabase, ejecuta '
            'el script docs/schema.sql en el SQL Editor y vuelve a intentar.';
      }
      return 'Error de base de datos: ${error.message}';
    }
    return 'Error inesperado: $error';
  }

  /// Registra entrada mediante transacción atómica RPC en PostgreSQL
  Future<Map<String, dynamic>> registrarEntrada({
    required String placa,
    String? novedad,
  }) async {
    try {
      final response = await _supabase.rpc(
        'registrar_entrada_tx',
        params: {
          'p_placa': placa.trim().toUpperCase(),
          'p_novedad': (novedad != null && novedad.trim().isNotEmpty)
              ? novedad.trim()
              : null,
        },
      );

      final data = _decodificarRespuesta(response);
      final bool ok = data['ok'] == true;

      return {
        'exito': ok,
        'mensaje': ok
            ? 'Ingreso autorizado y celda asignada correctamente.'
            : ((data['mensaje'] as String?) ?? 'Acceso denegado.'),
        'celda': (data['celda'] as String?) ?? '',
        'tipo': (data['tipo'] as String?) ?? '',
        'propietario': (data['propietario'] as String?) ?? '',
      };
    } catch (e) {
      return {
        'exito': false,
        'mensaje': _mensajeDeError(e),
      };
    }
  }

  /// Registra salida y libera celda mediante transacción atómica RPC
  Future<Map<String, dynamic>> registrarSalida({
    required String placa,
    String? novedadSalida,
  }) async {
    try {
      final response = await _supabase.rpc(
        'registrar_salida_tx',
        params: {
          'p_placa': placa.trim().toUpperCase(),
          'p_novedad':
              (novedadSalida != null && novedadSalida.trim().isNotEmpty)
                  ? novedadSalida.trim()
                  : null,
        },
      );

      final data = _decodificarRespuesta(response);
      final bool ok = data['ok'] == true;

      return {
        'exito': ok,
        'mensaje': ok
            ? 'Salida registrada y celda liberada en tiempo real.'
            : ((data['mensaje'] as String?) ?? 'No se pudo registrar la salida.'),
        'celdaLiberada': (data['celda_liberada'] as String?) ?? '',
      };
    } catch (e) {
      return {
        'exito': false,
        'mensaje': _mensajeDeError(e),
      };
    }
  }
}
