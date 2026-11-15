enum EstadoCelda { disponible, ocupada, mantenimiento }

class CeldaModel {
  final int idCelda;
  final String codigoCelda;
  final String tipoVehiculo;
  final EstadoCelda estado;

  CeldaModel({
    required this.idCelda,
    required this.codigoCelda,
    required this.tipoVehiculo,
    required this.estado,
  });

  factory CeldaModel.fromJson(Map<String, dynamic> json) {
    EstadoCelda parseEstado(String est) {
      switch (est) {
        case 'OCUPADA':
          return EstadoCelda.ocupada;
        case 'MANTENIMIENTO':
          return EstadoCelda.mantenimiento;
        default:
          return EstadoCelda.disponible;
      }
    }

    return CeldaModel(
      idCelda: json['id_celda'] as int,
      codigoCelda: json['codigo_celda'] as String,
      tipoVehiculo: json['tipo_vehiculo'] as String,
      estado: parseEstado(json['estado'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_celda': idCelda,
      'codigo_celda': codigoCelda,
      'tipo_vehiculo': tipoVehiculo,
      'estado': estado.name.toUpperCase(),
    };
  }
}
