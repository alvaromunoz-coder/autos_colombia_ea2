// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:autos_colombia_ea1/config/supabase_config.dart';
import 'package:autos_colombia_ea1/main.dart';

void main() {
  setUpAll(() async {
    // Simula el almacenamiento local (shared_preferences) requerido por Supabase.
    SharedPreferences.setMockInitialValues({});
    await SupabaseConfig.init();
  });

  testWidgets('La app carga y muestra la navegación principal',
      (WidgetTester tester) async {
    await tester.pumpWidget(const AutosColombiaApp());
    await tester.pump();

    expect(find.text('Entrada'), findsOneWidget);
    expect(find.text('Salida'), findsOneWidget);
    expect(find.text('Usuarios'), findsOneWidget);
    expect(find.text('Celdas'), findsOneWidget);
  });
}
