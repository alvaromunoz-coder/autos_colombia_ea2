import 'package:supabase_flutter/supabase_flutter.dart';

class UsuarioService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<dynamic>> listarUsuariosConVehiculos() async {
    final response = await _supabase
        .from('usuarios')
        .select('*, vehiculos(*)')
        .order('id_usuario', ascending: false);
    return List<dynamic>.from(response);
  }

  Future<void> registrarUsuarioYVehiculo({
    required String documento,
    required String nombre,
    required String telefono,
    required String email,
    required String placa,
    required String tipoVehiculo,
    bool activarMensualidadPrueba = true,
  }) async {
    final usuarioInsertado = await _supabase
        .from('usuarios')
        .insert({
          'documento': documento.trim(),
          'nombre': nombre.trim(),
          'telefono': telefono.trim(),
          'email': email.trim(),
        })
        .select()
        .single();

    final int idUsuario = usuarioInsertado['id_usuario'];
    final String placaLimpia = placa.trim().toUpperCase();

    await _supabase.from('vehiculos').insert({
      'placa': placaLimpia,
      'tipo_vehiculo': tipoVehiculo,
      'id_usuario': idUsuario,
    });

    // Opcional: Deja el vehículo con mensualidad activa por 30 días para probar ingresos de inmediato
    if (activarMensualidadPrueba) {
      await _supabase.from('pagos_mensualidades').insert({
        'placa': placaLimpia,
        'fecha_vencimiento': DateTime.now().add(const Duration(days: 30)).toIso8601String(),
        'monto': tipoVehiculo == 'CARRO' ? 220000 : 80000,
        'metodo_pago': 'EFECTIVO',
      });
    }
  }

  Future<void> actualizarUsuario({
    required int idUsuario,
    required String nombre,
    required String telefono,
    required String email,
  }) async {
    await _supabase.from('usuarios').update({
      'nombre': nombre.trim(),
      'telefono': telefono.trim(),
      'email': email.trim(),
    }).eq('id_usuario', idUsuario);
  }

  Future<void> agregarVehiculoAUsuario({
    required int idUsuario,
    required String placa,
    required String tipoVehiculo,
  }) async {
    await _supabase.from('vehiculos').insert({
      'placa': placa.trim().toUpperCase(),
      'tipo_vehiculo': tipoVehiculo,
      'id_usuario': idUsuario,
    });
  }
}