import 'package:flutter/material.dart';
import '../services/celda_service.dart';

class CeldasPage extends StatefulWidget {
  const CeldasPage({super.key});

  @override
  State<CeldasPage> createState() => _CeldasPageState();
}

class _CeldasPageState extends State<CeldasPage> {
  final CeldaService _celdaService = CeldaService();
  List<dynamic> _celdas = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarCeldas();
  }

  Future<void> _cargarCeldas() async {
    setState(() => _cargando = true);
    try {
      final data = await _celdaService.listarCeldas();
      setState(() {
        _celdas = data;
        _cargando = false;
      });
    } catch (e) {
      setState(() => _cargando = false);
      _mostrarMensaje('Error al cargar celdas: $e', esError: true);
    }
  }

  void _mostrarMensaje(String msg, {bool esError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: esError ? Colors.red[700] : Colors.green[700],
      ),
    );
  }

  void _abrirDialogoNuevaCelda() {
    final codigoCtrl = TextEditingController();
    String tipoVehiculo = 'CARRO';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: const Text('Crear Nueva Celda'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: codigoCtrl,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(labelText: 'Código de Celda (Ej: C-106 o M-206)'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: tipoVehiculo,
                decoration: const InputDecoration(labelText: 'Tipo de Vehículo'),
                items: const [
                  DropdownMenuItem(value: 'CARRO', child: Text('CARRO')),
                  DropdownMenuItem(value: 'MOTO', child: Text('MOTO')),
                ],
                onChanged: (val) => setModalState(() => tipoVehiculo = val!),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey[900]),
              onPressed: () async {
                if (codigoCtrl.text.isEmpty) return;
                try {
                  await _celdaService.crearCelda(
                    codigoCelda: codigoCtrl.text,
                    tipoVehiculo: tipoVehiculo,
                  );
                  if (ctx.mounted) Navigator.pop(ctx);
                  _mostrarMensaje('Celda creada exitosamente');
                  _cargarCeldas();
                } catch (e) {
                  _mostrarMensaje('Error (¿Código duplicado?): $e', esError: true);
                }
              },
              child: const Text('Crear', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Color _colorPorEstado(String estado) {
    switch (estado) {
      case 'DISPONIBLE':
        return Colors.green[700]!;
      case 'OCUPADA':
        return Colors.red[700]!;
      case 'MANTENIMIENTO':
        return Colors.orange[800]!;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final disponibles = _celdas.where((c) => c['estado'] == 'DISPONIBLE').length;
    final ocupadas = _celdas.where((c) => c['estado'] == 'OCUPADA').length;
    final mantenimiento = _celdas.where((c) => c['estado'] == 'MANTENIMIENTO').length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Autos Colombia - Celdas'),
        backgroundColor: Colors.blueGrey[900],
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _cargarCeldas),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.blueGrey[900],
        onPressed: _abrirDialogoNuevaCelda,
        icon: const Icon(Icons.add_location_alt, color: Colors.white),
        label: const Text('Nueva Celda', style: TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Wrap(
              spacing: 8,
              children: [
                Chip(label: Text('Disponibles: $disponibles'), backgroundColor: Colors.green[100]),
                Chip(label: Text('Ocupadas: $ocupadas'), backgroundColor: Colors.red[100]),
                Chip(label: Text('Mantenimiento: $mantenimiento'), backgroundColor: Colors.orange[100]),
              ],
            ),
          ),
          const Text(
            'Toca una celda libre para alternar Mantenimiento',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          Expanded(
            child: _cargando
                ? const Center(child: CircularProgressIndicator())
                : GridView.builder(
                    padding: const EdgeInsets.all(15),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 1.25,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: _celdas.length,
                    itemBuilder: (context, index) {
                      final c = _celdas[index];
                      final estado = c['estado'];
                      return InkWell(
                        onTap: () async {
                          try {
                            await _celdaService.cambiarEstadoMantenimiento(
                              idCelda: c['id_celda'],
                              estadoActual: estado,
                            );
                            _mostrarMensaje('Estado de ${c['codigo_celda']} actualizado');
                            _cargarCeldas();
                          } catch (e) {
                            _mostrarMensaje(e.toString().replaceAll('Exception: ', ''), esError: true);
                          }
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: _colorPorEstado(estado),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                c['tipo_vehiculo'] == 'CARRO' ? Icons.directions_car : Icons.two_wheeler,
                                color: Colors.white,
                                size: 26,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                c['codigo_celda'],
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              Text(
                                estado,
                                style: const TextStyle(color: Colors.white70, fontSize: 10),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}