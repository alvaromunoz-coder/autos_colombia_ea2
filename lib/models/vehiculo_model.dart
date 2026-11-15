enum TipoVehiculo { carro, moto }

class VehiculoModel {
  final String placa;
  final TipoVehiculo tipoVehiculo;
  final int idUsuario;

  VehiculoModel({
    required this.placa,
    required this.tipoVehiculo,
    required this.idUsuario,
  });

  factory VehiculoModel.fromJson(Map<String, dynamic> json) {
    return VehiculoModel(
      placa: json['placa'] as String,
      tipoVehiculo: json['tipo_vehiculo'] == 'MOTO'
          ? TipoVehiculo.moto
          : TipoVehiculo.carro,
      idUsuario: json['id_usuario'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'placa': placa,
      'tipo_vehiculo': tipoVehiculo == TipoVehiculo.moto ? 'MOTO' : 'CARRO',
      'id_usuario': idUsuario,
    };
  }
}
