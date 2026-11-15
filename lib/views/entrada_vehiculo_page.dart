import 'package:flutter/material.dart';
import '../services/control_acceso_service.dart';

class EntradaVehiculoPage extends StatefulWidget {
  const EntradaVehiculoPage({super.key});

  @override
  State<EntradaVehiculoPage> createState() => _EntradaVehiculoPageState();
}

class _EntradaVehiculoPageState extends State<EntradaVehiculoPage> {
  final _placaController = TextEditingController();
  final _novedadController = TextEditingController();
  final _controlAcceso = ControlAccesoService();
  bool _cargando = false;

  void _procesarIngreso() async {
    if (_placaController.text.trim().isEmpty) return;

    setState(() => _cargando = true);
    final resultado = await _controlAcceso.registrarEntrada(
      placa: _placaController.text.trim(),
      novedad: _novedadController.text.trim(),
    );
    setState(() => _cargando = false);

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          resultado['exito'] ? '✅ Acceso Permitido' : '❌ Acceso Denegado',
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
                'Celda Asignada: ${resultado['celda']}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text('Vehículo: ${resultado['tipo']}'),
              Text('Propietario: ${resultado['propietario']}'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (resultado['exito'] == true) {
                _placaController.clear();
                _novedadController.clear();
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
        title: const Text('Autos Colombia - Control de Ingreso'),
        backgroundColor: Colors.blueGrey[900],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Registro de Entrada 24/7',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _placaController,
                decoration: const InputDecoration(
                  labelText: 'Ingrese Placa del Vehículo',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.directions_car),
                ),
                textCapitalization: TextCapitalization.characters,
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _novedadController,
                decoration: const InputDecoration(
                  labelText: 'Novedades / Observaciones (Opcional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.note_add),
                ),
              ),
              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _cargando ? null : _procesarIngreso,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey[900],
                  ),
                  child: _cargando
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'VALIDAR E INGRESAR',
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
