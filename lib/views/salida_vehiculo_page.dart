import 'package:flutter/material.dart';
import '../services/control_acceso_service.dart';

class SalidaVehiculoPage extends StatefulWidget {
  const SalidaVehiculoPage({super.key});

  @override
  State<SalidaVehiculoPage> createState() => _SalidaVehiculoPageState();
}

class _SalidaVehiculoPageState extends State<SalidaVehiculoPage> {
  final _placaController = TextEditingController();
  final _novedadSalidaController = TextEditingController();
  final _controlAcceso = ControlAccesoService();
  bool _cargando = false;

  void _procesarSalida() async {
    if (_placaController.text.trim().isEmpty) return;

    setState(() => _cargando = true);

    final resultado = await _controlAcceso.registrarSalida(
      placa: _placaController.text.trim(),
      novedadSalida: _novedadSalidaController.text.trim(),
    );

    setState(() => _cargando = false);

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          resultado['exito'] ? '✅ Salida Exitosa' : '❌ Error de Salida',
          style: TextStyle(
            color: resultado['exito'] ? Colors.green : Colors.red,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(resultado['mensaje']),
            if (resultado['exito'] == true) ...[
              const SizedBox(height: 10),
              Text(
                'Celda Liberada: ${resultado['celdaLiberada']}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (resultado['exito'] == true) {
                _placaController.clear();
                _novedadSalidaController.clear();
              }
            },
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Autos Colombia - Registro de Salida'),
        backgroundColor: Colors.blueGrey[900],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Liberación de Celdas 24/7',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _placaController,
              decoration: const InputDecoration(
                labelText: 'Ingrese Placa del Vehículo a Salir',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.no_crash),
              ),
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _novedadSalidaController,
              decoration: const InputDecoration(
                labelText: 'Novedades al Salir (Opcional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.assignment_turned_in),
              ),
            ),
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _cargando ? null : _procesarSalida,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent[700],
                ),
                child: _cargando
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'REGISTRAR SALIDA Y LIBERAR CELDA',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
