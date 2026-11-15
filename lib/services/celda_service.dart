import 'package:supabase_flutter/supabase_flutter.dart';

class CeldaService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<dynamic>> listarCeldas() async {
    final response = await _supabase
        .from('celdas')
        .select()
        .order('codigo_celda', ascending: true);
    return List<dynamic>.from(response);
  }

  Future<void> crearCelda({
    required String codigoCelda,
    required String tipoVehiculo,
  }) async {
    await _supabase.from('celdas').insert({
      'codigo_celda': codigoCelda.trim().toUpperCase(),
      'tipo_vehiculo': tipoVehiculo,
      'estado': 'DISPONIBLE',
    });
  }

  Future<void> cambiarEstadoMantenimiento({
    required int idCelda,
    required String estadoActual,
  }) async {
    if (estadoActual == 'OCUPADA') {
      throw Exception('No se puede poner en mantenimiento una celda OCUPADA.');
    }
    final nuevoEstado = (estadoActual == 'DISPONIBLE') ? 'MANTENIMIENTO' : 'DISPONIBLE';
    await _supabase
        .from('celdas')
        .update({'estado': nuevoEstado})
        .eq('id_celda', idCelda);
  }
}