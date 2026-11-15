class MovimientoModel {
  final int? idMovimiento;
  final String placa;
  final int idCelda;
  final DateTime fechaHoraEntrada;
  final DateTime? fechaHoraSalida;
  final String? novedadEntrada;
  final String? novedadSalida;

  MovimientoModel({
    this.idMovimiento,
    required this.placa,
    required this.idCelda,
    required this.fechaHoraEntrada,
    this.fechaHoraSalida,
    this.novedadEntrada,
    this.novedadSalida,
  });

  factory MovimientoModel.fromJson(Map<String, dynamic> json) {
    return MovimientoModel(
      idMovimiento: json['id_movimiento'] as int?,
      placa: json['placa'] as String,
      idCelda: json['id_celda'] as int,
      fechaHoraEntrada: DateTime.parse(json['fecha_hora_entrada'] as String),
      fechaHoraSalida: json['fecha_hora_salida'] != null
          ? DateTime.parse(json['fecha_hora_salida'] as String)
          : null,
      novedadEntrada: json['novedad_entrada'] as String?,
      novedadSalida: json['novedad_salida'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (idMovimiento != null) 'id_movimiento': idMovimiento,
      'placa': placa,
      'id_celda': idCelda,
      'fecha_hora_entrada': fechaHoraEntrada.toIso8601String(),
      'fecha_hora_salida': fechaHoraSalida?.toIso8601String(),
      'novedad_entrada': novedadEntrada,
      'novedad_salida': novedadSalida,
    };
  }
}
