import 'package:flutter/material.dart';
import 'config/supabase_config.dart';
import 'views/entrada_vehiculo_page.dart';
import 'views/salida_vehiculo_page.dart';
import 'views/usuarios_page.dart';
import 'views/celdas_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Supabase
  await SupabaseConfig.init();

  runApp(const AutosColombiaApp());
}

class AutosColombiaApp extends StatelessWidget {
  const AutosColombiaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Autos Colombia - Control de Acceso',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
        scaffoldBackgroundColor: Colors.grey[100],
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.blueGrey[900],
          foregroundColor: Colors.white,
        ),
      ),
      home: const MainPage(),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    EntradaVehiculoPage(),
    SalidaVehiculoPage(),
    UsuariosPage(),
    CeldasPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: Colors.blueGrey[900],
        unselectedItemColor: Colors.grey[600],
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.login), label: 'Entrada'),
          BottomNavigationBarItem(icon: Icon(Icons.logout), label: 'Salida'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Usuarios'),
          BottomNavigationBarItem(icon: Icon(Icons.grid_view), label: 'Celdas'),
        ],
      ),
    );
  }
}
