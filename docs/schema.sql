-- =============================================================================
-- PARQUEADERO AUTOS COLOMBIA - ITERACIÓN 1 (GESTIÓN ENTRADA Y SALIDA)
-- SCRIPT DE BASE DE DATOS PARA POSTGRESQL / SUPABASE
-- =============================================================================

-- 1. LIMPIEZA PREVIA (Opcional para reiniciar tablas)
DROP TABLE IF EXISTS movimientos CASCADE;
DROP TABLE IF EXISTS pagos_mensualidades CASCADE;
DROP TABLE IF EXISTS vehiculos CASCADE;
DROP TABLE IF EXISTS celdas CASCADE;
DROP TABLE IF EXISTS usuarios CASCADE;

-- 2. TABLA DE USUARIOS / CLIENTES
CREATE TABLE usuarios (
    id_usuario SERIAL PRIMARY KEY,
    documento VARCHAR(20) UNIQUE NOT NULL,
    nombre VARCHAR(100) NOT NULL,
    telefono VARCHAR(20),
    email VARCHAR(100),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 3. TABLA DE CELDAS
CREATE TABLE celdas (
    id_celda SERIAL PRIMARY KEY,
    codigo_celda VARCHAR(10) UNIQUE NOT NULL,
    tipo_vehiculo VARCHAR(10) CHECK (tipo_vehiculo IN ('CARRO', 'MOTO')) NOT NULL,
    estado VARCHAR(15) CHECK (estado IN ('DISPONIBLE', 'OCUPADA', 'MANTENIMIENTO')) DEFAULT 'DISPONIBLE'
);

-- 4. TABLA DE VEHÍCULOS
CREATE TABLE vehiculos (
    placa VARCHAR(10) PRIMARY KEY,
    tipo_vehiculo VARCHAR(10) CHECK (tipo_vehiculo IN ('CARRO', 'MOTO')) NOT NULL,
    id_usuario INT REFERENCES usuarios(id_usuario) ON DELETE CASCADE
);

-- 5. TABLA DE PAGOS DE MENSUALIDADES (Tarifas Medellín)
CREATE TABLE pagos_mensualidades (
    id_pago SERIAL PRIMARY KEY,
    placa VARCHAR(10) REFERENCES vehiculos(placa) ON DELETE CASCADE,
    fecha_pago TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_vencimiento TIMESTAMP WITH TIME ZONE NOT NULL,
    monto NUMERIC(10,2) NOT NULL,
    metodo_pago VARCHAR(20) CHECK (metodo_pago IN ('EFECTIVO', 'VIRTUAL')) NOT NULL
);

-- 6. TABLA DE MOVIMIENTOS (ENTRADAS Y SALIDAS 24/7)
CREATE TABLE movimientos (
    id_movimiento SERIAL PRIMARY KEY,
    placa VARCHAR(10) REFERENCES vehiculos(placa) ON DELETE CASCADE,
    id_celda INT REFERENCES celdas(id_celda),
    fecha_hora_entrada TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    fecha_hora_salida TIMESTAMP WITH TIME ZONE NULL,
    novedad_entrada TEXT,
    novedad_salida TEXT
);

-- =============================================================================
-- VISTA DE CONSULTA RÁPIDA: CONTROL DE ACCESO
-- Muestra el estado actual del vehículo y la validez de su mensualidad
-- =============================================================================
CREATE OR REPLACE VIEW vista_estado_mensualidades AS
SELECT 
    v.placa,
    v.tipo_vehiculo,
    u.nombre AS propietario,
    u.documento,
    pm.fecha_pago,
    pm.fecha_vencimiento,
    CASE 
        WHEN CURRENT_TIMESTAMP <= pm.fecha_vencimiento THEN 'AL_DIA'
        ELSE 'EN_MORA'
    END AS estado_pago
FROM vehiculos v
JOIN usuarios u ON v.id_usuario = u.id_usuario
LEFT JOIN LATERAL (
    SELECT fecha_pago, fecha_vencimiento 
    FROM pagos_mensualidades 
    WHERE placa = v.placa 
    ORDER BY fecha_vencimiento DESC 
    LIMIT 1
) pm ON TRUE;

-- =============================================================================
-- DATOS DE PRUEBA (SEED DATA)
-- =============================================================================

INSERT INTO usuarios (documento, nombre, telefono, email) VALUES
('1017000111', 'Carlos Mario Restrepo', '3001234567', 'carlos.restrepo@gmail.com'),
('1017000222', 'Ana María Jaramillo', '3119876543', 'ana.jaramillo@outlook.com'),
('1017000333', 'Juan Fernando Gómez', '3205554433', 'juan.gomez@yahoo.com');

INSERT INTO celdas (codigo_celda, tipo_vehiculo, estado) VALUES
('C-101', 'CARRO', 'DISPONIBLE'),
('C-102', 'CARRO', 'DISPONIBLE'),
('C-103', 'CARRO', 'DISPONIBLE'),
('C-104', 'CARRO', 'DISPONIBLE'),
('C-105', 'CARRO', 'DISPONIBLE'),
('M-201', 'MOTO', 'DISPONIBLE'),
('M-202', 'MOTO', 'DISPONIBLE'),
('M-203', 'MOTO', 'DISPONIBLE'),
('M-204', 'MOTO', 'DISPONIBLE'),
('M-205', 'MOTO', 'DISPONIBLE');

INSERT INTO vehiculos (placa, tipo_vehiculo, id_usuario) VALUES
('KNL316', 'CARRO', 1),
('OKN890', 'MOTO', 2),
('XYZ123', 'CARRO', 3);

INSERT INTO pagos_mensualidades (placa, fecha_pago, fecha_vencimiento, monto, metodo_pago) VALUES
('KNL316', '2026-10-15 08:00:00-05', '2026-11-15 08:00:00-05', 220000.00, 'VIRTUAL'),
('OKN890', '2026-10-20 10:30:00-05', '2026-11-20 10:30:00-05', 80000.00, 'EFECTIVO'),
('XYZ123', '2026-08-01 09:00:00-05', '2026-09-01 09:00:00-05', 220000.00, 'VIRTUAL');

-- =============================================================================
-- FUNCIONES RPC (TRANSACCIONES ATÓMICAS)
-- Invocadas desde el frontend (Flutter) para registrar entradas y salidas.
-- =============================================================================

-- 7. REGISTRAR ENTRADA (valida mensualidad, asigna celda y crea movimiento)
CREATE OR REPLACE FUNCTION registrar_entrada_tx(
    p_placa TEXT,
    p_novedad TEXT DEFAULT NULL
)
RETURNS json
LANGUAGE plpgsql
AS $$
DECLARE
    v_vehiculo vehiculos%ROWTYPE;
    v_propietario usuarios%ROWTYPE;
    v_mensualidad pagos_mensualidades%ROWTYPE;
    v_celda celdas%ROWTYPE;
BEGIN
    -- 1. Validar que el vehículo exista
    SELECT * INTO v_vehiculo
    FROM vehiculos
    WHERE placa = UPPER(TRIM(p_placa));

    IF NOT FOUND THEN
        RETURN json_build_object('ok', false, 'mensaje', 'Vehículo no registrado en el sistema.');
    END IF;

    -- 2. Validar propietario
    SELECT * INTO v_propietario
    FROM usuarios
    WHERE id_usuario = v_vehiculo.id_usuario;

    IF NOT FOUND THEN
        RETURN json_build_object('ok', false, 'mensaje', 'No se encontró el propietario del vehículo.');
    END IF;

    -- 3. Validar mensualidad vigente (30 días calendario)
    SELECT * INTO v_mensualidad
    FROM pagos_mensualidades
    WHERE placa = v_vehiculo.placa
    ORDER BY fecha_vencimiento DESC
    LIMIT 1;

    IF NOT FOUND THEN
        RETURN json_build_object('ok', false, 'mensaje', 'El vehículo no tiene mensualidad activa.');
    END IF;

    IF v_mensualidad.fecha_vencimiento < CURRENT_TIMESTAMP THEN
        RETURN json_build_object('ok', false, 'mensaje', 'Mensualidad vencida. Debe renovar antes de ingresar.');
    END IF;

    -- 4. Validar que no tenga un ingreso abierto
    IF EXISTS (
        SELECT 1 FROM movimientos
        WHERE placa = v_vehiculo.placa AND fecha_hora_salida IS NULL
    ) THEN
        RETURN json_build_object('ok', false, 'mensaje', 'El vehículo ya se encuentra dentro del parqueadero.');
    END IF;

    -- 5. Asignar celda disponible del tipo correspondiente (aleatoria)
    SELECT * INTO v_celda
    FROM celdas
    WHERE tipo_vehiculo = v_vehiculo.tipo_vehiculo AND estado = 'DISPONIBLE'
    ORDER BY random()
    LIMIT 1;

    IF NOT FOUND THEN
        RETURN json_build_object('ok', false, 'mensaje', 'No hay celdas disponibles para este tipo de vehículo.');
    END IF;

    -- 6. Crear movimiento de entrada
    INSERT INTO movimientos (placa, id_celda, novedad_entrada)
    VALUES (v_vehiculo.placa, v_celda.id_celda, p_novedad);

    -- 7. Marcar celda como ocupada
    UPDATE celdas SET estado = 'OCUPADA' WHERE id_celda = v_celda.id_celda;

    RETURN json_build_object(
        'ok', true,
        'mensaje', 'Ingreso autorizado y celda asignada correctamente.',
        'celda', v_celda.codigo_celda,
        'tipo', v_vehiculo.tipo_vehiculo,
        'propietario', v_propietario.nombre
    );
END;
$$;

-- 8. REGISTRAR SALIDA (cierra movimiento y libera celda)
CREATE OR REPLACE FUNCTION registrar_salida_tx(
    p_placa TEXT,
    p_novedad TEXT DEFAULT NULL
)
RETURNS json
LANGUAGE plpgsql
AS $$
DECLARE
    v_movimiento movimientos%ROWTYPE;
    v_codigo_celda TEXT;
BEGIN
    -- 1. Buscar el ingreso abierto más reciente
    SELECT * INTO v_movimiento
    FROM movimientos
    WHERE placa = UPPER(TRIM(p_placa)) AND fecha_hora_salida IS NULL
    ORDER BY fecha_hora_entrada DESC
    LIMIT 1;

    IF NOT FOUND THEN
        RETURN json_build_object('ok', false, 'mensaje', 'No hay un ingreso activo para esta placa.');
    END IF;

    -- 2. Liberar celda (si tiene asignada)
    IF v_movimiento.id_celda IS NOT NULL THEN
        SELECT codigo_celda INTO v_codigo_celda
        FROM celdas WHERE id_celda = v_movimiento.id_celda;

        UPDATE celdas SET estado = 'DISPONIBLE' WHERE id_celda = v_movimiento.id_celda;
    ELSE
        v_codigo_celda := '';
    END IF;

    -- 3. Cerrar movimiento de salida
    UPDATE movimientos
    SET fecha_hora_salida = CURRENT_TIMESTAMP, novedad_salida = p_novedad
    WHERE id_movimiento = v_movimiento.id_movimiento;

    RETURN json_build_object(
        'ok', true,
        'mensaje', 'Salida registrada y celda liberada en tiempo real.',
        'celda_liberada', v_codigo_celda
    );
END;
$$;
