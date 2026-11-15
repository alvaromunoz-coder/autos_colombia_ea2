# 📋 Bitácora de Revisión y Corrección — Parqueadero "Autos Colombia"

**Proyecto:** `autos_colombia_ea1` (Flutter + Supabase)  
**Fecha:** 15 de noviembre de 2026  
**Alcance:** Revisión general del proyecto y corrección de los **18 problemas** reportados por el analizador estático (`flutter analyze`), más dos hallazgos adicionales que afectaban el funcionamiento.

## 📝 Resumen de lo reparado y realizado

**1. Corrección de los 18 problemas del analizador (`flutter analyze`):**
- Se repararon las anotaciones de tipo rotas `List>` → `List<dynamic>` en `celda_service.dart`, `usuario_service.dart` y `usuarios_page.dart`, que generaban errores de sintaxis en cascada.
- Se actualizó el parámetro deprecado `value:` → `initialValue:` en los `DropdownButtonFormField` de `celdas_page.dart` y `usuarios_page.dart`.
- Resultado: el proyecto pasó de **18 issues** a **0 issues**.

**2. Funciones de base de datos que faltaban (`docs/schema.sql`):**
- Se crearon las funciones RPC `registrar_entrada_tx` y `registrar_salida_tx`, que la app necesita para el ingreso y salida de vehículos (validación de mensualidad a 30 días, asignación aleatoria de celda, creación/cierre de movimientos y liberación de celdas).

**3. Test de la app arreglado (`test/widget_test.dart`):**
- Se reemplazó el test por defecto de "contador" (de la plantilla) por una prueba de humo que valida la navegación principal (Entrada, Salida, Usuarios, Celdas).
- Se agregó `shared_preferences` a `dev_dependencies` en `pubspec.yaml` para poder simular el almacenamiento local de Supabase en las pruebas.

**4. Manejo robusto de errores en tiempo de ejecución (`control_acceso_service.dart`):**
- Se mejoró la lectura de la respuesta RPC (soporta objeto JSON, cadena JSON o lista).
- Se agregaron mensajes claros: si falta la función en la base de datos (`PGRST202`), la app ahora indica ejecutar `docs/schema.sql` en Supabase.

**Validación final:**
- `flutter analyze` → ✅ **No issues found!**
- `flutter test` → ✅ **All tests passed!**

---

## 1. Resumen ejecutivo

| Verificación | Antes | Después |
|---|---|---|
| `flutter analyze` | ❌ 18 issues (errores + warnings) | ✅ **No issues found!** |
| `flutter test` | ❌ Test por defecto roto ("Counter") | ✅ **All tests passed!** |
| `docs/schema.sql` | ❌ Faltaban las funciones RPC usadas por la app | ✅ Funciones `registrar_entrada_tx` y `registrar_salida_tx` creadas |

---

## 2. Los 18 problemas corregidos

La causa raíz de la mayoría de errores fue que las anotaciones de tipo `List<dynamic>` aparecían **rotas como `List>`** (les faltaba el fragmento `<dynamic`), lo que generaba errores de sintaxis en cascada. Además, el parámetro `value:` de `DropdownButtonFormField` estaba **deprecado** (reemplazo: `initialValue`).

### A. Errores de sintaxis por tipo `List>` roto

| # | Archivo | Línea | Problema original | Corrección |
|---|---|---|---|---|
| 1 | `lib/services/celda_service.dart` | 11 | `return List>.from(response);` (undefined_operator) | `return List<dynamic>.from(response);` |
| 2 | `lib/services/celda_service.dart` | 11 | `List>.from` (dot_shorthand_undefined_member) | ídem |
| 3 | `lib/services/usuario_service.dart` | 11 | `return List>.from(response);` (undefined_operator) | `return List<dynamic>.from(response);` |
| 4 | `lib/services/usuario_service.dart` | 11 | `List>.from` (dot_shorthand_undefined_member) | ídem |
| 5–13 | `lib/views/usuarios_page.dart` | 13 | `List> _usuarios = [];` (9 errores en cascada: expected_token, missing_const_final_var_or_type, missing_method_parameters, wrong_number_of_parameters_for_operator, missing_keyword_operator, missing_function_body, prefer_typing_uninitialized_variables, non_constant_identifier_names) | `List<dynamic> _usuarios = [];` |
| 14 | `lib/views/usuarios_page.dart` | 225 | `(u['vehiculos'] as List? ?? [])` (cast_to_non_type) | `as List<dynamic>?` |
| 15 | `lib/views/usuarios_page.dart` | 265 | `u['vehiculos'] as List? ?? [];` (cast_to_non_type) | `as List<dynamic>?` |

### B. Uso de API deprecada (`value:` → `initialValue:`)

| # | Archivo | Línea | Corrección |
|---|---|---|---|
| 16 | `lib/views/celdas_page.dart` | 65 | `DropdownButtonFormField<String>(value: tipoVehiculo)` → `initialValue: tipoVehiculo` |
| 17 | `lib/views/usuarios_page.dart` | 76 | `value:` → `initialValue:` (dialogo "Registrar Cliente") |
| 18 | `lib/views/usuarios_page.dart` | 182 | `value:` → `initialValue:` (dialogo "Vincular Vehículo") |

---

## 3. Hallazgos adicionales corregidos (más allá de los 18)

Durante la revisión se detectaron dos defectos que, aunque no eran reportados por el analizador, impedían el correcto funcionamiento:

### 3.1. Funciones RPC faltantes en la base de datos (`docs/schema.sql`)

- **Problema:** `lib/services/control_acceso_service.dart` invoca las funciones PostgreSQL `registrar_entrada_tx` y `registrar_salida_tx`, pero estas **no existían** en `docs/schema.sql`. El registro de entrada/salida habría fallado en tiempo de ejecución.
- **Corrección:** Se agregaron las dos funciones al final del script:
  - `registrar_entrada_tx(p_placa, p_novedad)`: valida vehículo, propietario y mensualidad vigente (30 días), evita doble ingreso, asigna una celda disponible del tipo correcto (aleatoria) y crea el movimiento.
  - `registrar_salida_tx(p_placa, p_novedad)`: busca el ingreso abierto, libera la celda y cierra el movimiento.
- **Acción requerida:** volver a ejecutar `docs/schema.sql` en el SQL Editor de Supabase.

### 3.2. Test por defecto roto (`test/widget_test.dart`)

- **Problema:** el archivo contenía el "Counter increments smoke test" generado por plantilla, que busca un contador (`Icons.add`, textos "0"/"1") inexistente en esta app.
- **Corrección:** se reescribió como una prueba de humo que verifica que la app carga y muestra la navegación principal (Entrada, Salida, Usuarios, Celdas).
- **Soporte:** se agregó `shared_preferences` a `dev_dependencies` en `pubspec.yaml` para simular el almacenamiento local que usa Supabase en las pruebas (`SharedPreferences.setMockInitialValues({})`).

---

## 4. Validación realizada

```text
$ flutter analyze
Analyzing autos_colombia_ea1...
No issues found! (ran in 1.6s)

$ flutter test
00:02 +1: All tests passed!
```

---

## 5. Notas y recomendaciones (no bloqueantes)

- **Concurrencia en asignación de celdas:** la función `registrar_entrada_tx` asigna celdas con `ORDER BY random()`. Para un entorno 24/7 con múltiples operadores, convendría usar bloqueo de filas (`FOR UPDATE SKIP LOCKED`) para evitar que dos ingresos simultáneos tomen la misma celda.
- **Tipos en `Map<String, dynamic>`:** la app aún maneja la lista de celdas/usuarios como `List<dynamic>` (mapas sin tipar). Sería más robusto usar los modelos ya existentes (`CeldaModel`, `VehiculoModel`, `MovimientoModel`) para tipar las respuestas.
- **Credenciales en el código:** `lib/config/supabase_config.dart` contiene la URL y la `publishableKey` (anon key) directamente. Es aceptable para un cliente público, pero conviene recordar que **nunca** debe exponerse la `service_role` key.

---

## 6. Corrección posterior: error en pantalla al registrar ingreso

- **Síntoma reportado:** al intentar registrar un ingreso (placa), la app mostraba un error en pantalla.
- **Causa raíz identificada:** las funciones RPC `registrar_entrada_tx` / `registrar_salida_tx` no existen en la base de datos de Supabase (el `schema.sql` original nunca las definió), por lo que PostgREST devuelve el error `PGRST202` ("Could not find the function..."). Adicionalmente, el servicio mostraba este error con un texto genérico y confuso ("Error de conexión...").
- **Corrección aplicada en `lib/services/control_acceso_service.dart`:**
  - Se agregó `_decodificarRespuesta()` para tolerar los formatos que puede devolver PostgREST (objeto JSON, cadena JSON o lista).
  - Se agregó `_mensajeDeError()` que detecta el código `PGRST202` y muestra un mensaje claro: *"La función de base de datos no existe. Abre Supabase, ejecuta el script docs/schema.sql en el SQL Editor y vuelve a intentar."*
- **Acción requerida por el usuario:** ejecutar `docs/schema.sql` completo en el SQL Editor de Supabase (o al menos las dos funciones `CREATE OR REPLACE FUNCTION` del final).
- **Nota:** el dato de prueba del script es la placa `KNL316` (no `KML316`). Si se ingresa una placa que no esté registrada, la respuesta correcta del sistema es "Vehículo no registrado en el sistema." (eso no es un error, es una validación de negocio).

