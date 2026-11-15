import 'package:flutter/material.dart';
import '../services/usuario_service.dart';

class UsuariosPage extends StatefulWidget {
  const UsuariosPage({super.key});

  @override
  State<UsuariosPage> createState() => _UsuariosPageState();
}

class _UsuariosPageState extends State<UsuariosPage> {
  final UsuarioService _usuarioService = UsuarioService();
  List<dynamic> _usuarios = [];
  String _filtro = '';
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarUsuarios();
  }

  Future<void> _cargarUsuarios() async {
    setState(() => _cargando = true);
    try {
      final data = await _usuarioService.listarUsuariosConVehiculos();
      setState(() {
        _usuarios = data;
        _cargando = false;
      });
    } catch (e) {
      setState(() => _cargando = false);
      _mostrarMensaje('Error al cargar usuarios: $e', esError: true);
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

  void _abrirDialogoNuevoUsuario() {
    final docCtrl = TextEditingController();
    final nomCtrl = TextEditingController();
    final telCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final placaCtrl = TextEditingController();
    String tipoVehiculo = 'CARRO';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: const Text('Registrar Cliente y Vehículo'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: docCtrl, decoration: const InputDecoration(labelText: 'Documento / Cédula *')),
                TextField(controller: nomCtrl, decoration: const InputDecoration(labelText: 'Nombre Completo *')),
                TextField(controller: telCtrl, decoration: const InputDecoration(labelText: 'Teléfono')),
                TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Correo Electrónico')),
                const Divider(height: 24),
                TextField(
                  controller: placaCtrl,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(labelText: 'Placa del Vehículo * (Ej: ABC123)'),
                ),
                const SizedBox(height: 10),
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
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey[900]),
              onPressed: () async {
                if (docCtrl.text.isEmpty || nomCtrl.text.isEmpty || placaCtrl.text.isEmpty) {
                  _mostrarMensaje('Completa los campos obligatorios (*)', esError: true);
                  return;
                }
                try {
                  await _usuarioService.registrarUsuarioYVehiculo(
                    documento: docCtrl.text,
                    nombre: nomCtrl.text,
                    telefono: telCtrl.text,
                    email: emailCtrl.text,
                    placa: placaCtrl.text,
                    tipoVehiculo: tipoVehiculo,
                  );
                  if (ctx.mounted) Navigator.pop(ctx);
                  _mostrarMensaje('Usuario y vehículo registrados exitosamente');
                  _cargarUsuarios();
                } catch (e) {
                  _mostrarMensaje('Error (¿Cédula o placa ya registrada?): $e', esError: true);
                }
              },
              child: const Text('Guardar', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _abrirDialogoEditarUsuario(Map<String, dynamic> usuario) {
    final nomCtrl = TextEditingController(text: usuario['nombre']);
    final telCtrl = TextEditingController(text: usuario['telefono'] ?? '');
    final emailCtrl = TextEditingController(text: usuario['email'] ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Editar Cliente (${usuario['documento']})'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nomCtrl, decoration: const InputDecoration(labelText: 'Nombre Completo')),
            TextField(controller: telCtrl, decoration: const InputDecoration(labelText: 'Teléfono')),
            TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Correo Electrónico')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey[900]),
            onPressed: () async {
              try {
                await _usuarioService.actualizarUsuario(
                  idUsuario: usuario['id_usuario'],
                  nombre: nomCtrl.text,
                  telefono: telCtrl.text,
                  email: emailCtrl.text,
                );
                if (ctx.mounted) Navigator.pop(ctx);
                _mostrarMensaje('Datos actualizados');
                _cargarUsuarios();
              } catch (e) {
                _mostrarMensaje('Error al actualizar: $e', esError: true);
              }
            },
            child: const Text('Actualizar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _abrirDialogoAgregarVehiculo(Map<String, dynamic> usuario) {
    final placaCtrl = TextEditingController();
    String tipoVehiculo = 'CARRO';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: Text('Vincular Vehículo a ${usuario['nombre']}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: placaCtrl,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(labelText: 'Nueva Placa *'),
              ),
              const SizedBox(height: 10),
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
                if (placaCtrl.text.isEmpty) return;
                try {
                  await _usuarioService.agregarVehiculoAUsuario(
                    idUsuario: usuario['id_usuario'],
                    placa: placaCtrl.text,
                    tipoVehiculo: tipoVehiculo,
                  );
                  if (ctx.mounted) Navigator.pop(ctx);
                  _mostrarMensaje('Vehículo vinculado correctamente');
                  _cargarUsuarios();
                } catch (e) {
                  _mostrarMensaje('Error al vincular placa: $e', esError: true);
                }
              },
              child: const Text('Vincular', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtrados = _usuarios.where((u) {
      final texto = _filtro.toLowerCase();
      final nombre = (u['nombre'] ?? '').toString().toLowerCase();
      final doc = (u['documento'] ?? '').toString().toLowerCase();
      final vehiculos = (u['vehiculos'] as List<dynamic>? ?? [])
          .map((v) => v['placa'].toString().toLowerCase())
          .join(' ');
      return nombre.contains(texto) || doc.contains(texto) || vehiculos.contains(texto);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Autos Colombia - Usuarios'),
        backgroundColor: Colors.blueGrey[900],
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _cargarUsuarios),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.blueGrey[900],
        onPressed: _abrirDialogoNuevoUsuario,
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: const Text('Nuevo Usuario', style: TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Buscar por nombre, cédula o placa...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (val) => setState(() => _filtro = val),
            ),
          ),
          Expanded(
            child: _cargando
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: filtrados.length,
                    itemBuilder: (context, index) {
                      final u = filtrados[index];
                      final vehiculos = u['vehiculos'] as List<dynamic>? ?? [];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.blueGrey[900],
                            child: const Icon(Icons.person, color: Colors.white),
                          ),
                          title: Text(
                            '${u['nombre']} (CC: ${u['documento']})',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Tel: ${u['telefono'] ?? 'N/A'} | Email: ${u['email'] ?? 'N/A'}'),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 6,
                                children: vehiculos.map((v) {
                                  return Chip(
                                    avatar: Icon(
                                      v['tipo_vehiculo'] == 'CARRO' ? Icons.directions_car : Icons.two_wheeler,
                                      size: 16,
                                    ),
                                    label: Text('${v['placa']} (${v['tipo_vehiculo']})'),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'Editar datos',
                                icon: const Icon(Icons.edit),
                                onPressed: () => _abrirDialogoEditarUsuario(u),
                              ),
                              IconButton(
                                tooltip: 'Agregar vehículo',
                                icon: const Icon(Icons.add_circle_outline),
                                onPressed: () => _abrirDialogoAgregarVehiculo(u),
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