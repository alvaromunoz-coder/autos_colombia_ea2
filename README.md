# Sistema de Información - Parqueadero "Autos Colombia"
## Evidencia de Aprendizaje 1 (Iteración 1: Gestión de Entrada y Salida)

Este repositorio contiene la solución técnica para el módulo de control de accesos 24/7 del Parqueadero Autos Colombia en Medellín.

### 🚀 Tecnologías Utilizadas
* **Frontend:** Flutter (Dart) - Multiplataforma.
* **Backend & BD:** Supabase (PostgreSQL).
* **Lógica Core:** Asignación aleatoria de celdas por tipo de vehículo y validación estricta de mensualidad a 30 días calendario.

### 📋 Tablas de Base de Datos
* `usuarios`: Gestión de propietarios abonados.
* `vehiculos`: Tipificación estricta (`CARRO` / `MOTO`).
* `celdas`: Mapa de celdas y estado (`DISPONIBLE`, `OCUPADA`).
* `pagos_mensualidades`: Histórico y control de vencimiento.
* `movimientos`: Registros de entrada, salida y novedades.

### 🔧 Instrucciones de Ejecución
1. Clonar este repositorio.
2. Ejecutar el script `docs/schema.sql` en el SQL Editor de Supabase.
3. Configurar la URL y Anon Key en `lib/config/supabase_config.dart`.
4. Ejecutar `flutter run`.
