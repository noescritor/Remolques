-- Seed para prueba E2E de navegador: Gestión de equipos
-- Usa la organización y usuario admin estándar del puente local (local_supabase_bridge.cjs)

DO $$
DECLARE
    v_org UUID;
    v_user UUID := 'a988611b-2949-4ab7-b670-daf4a21f4e18';
    v_linea UUID;
    v_ot_man UUID;
    v_ot_cot UUID;
BEGIN
    SELECT id INTO v_org FROM organizaciones LIMIT 1;
    IF v_org IS NULL THEN
        v_org := '11111111-1111-4111-8111-111111111111';
        INSERT INTO organizaciones (id, nombre) VALUES (v_org, 'Leolca Remolques');
    END IF;

    INSERT INTO auth.users (id, email) VALUES (v_user, 'admin@remolques.com') ON CONFLICT (id) DO NOTHING;

    DELETE FROM perfiles_organizacion WHERE usuario_id = v_user;
    INSERT INTO perfiles_organizacion (organizacion_id, usuario_id, rol)
    VALUES (v_org, v_user, 'propietario');

    PERFORM sembrar_tablero_produccion(v_org);
    SELECT id INTO v_linea FROM lineas_producto WHERE organizacion_id = v_org AND clave = 'plataforma' LIMIT 1;

    INSERT INTO clientes (id, organizacion_id, nombre_razon_social, nombre_contacto)
    VALUES
        ('cli-e2e-1', v_org, 'Transportes del Norte SA', 'Ing. Roberto Garza'),
        ('cli-e2e-2', v_org, 'Autotransportes Bajío', 'Lic. Elena Morales')
    ON CONFLICT (id) DO UPDATE SET nombre_razon_social = EXCLUDED.nombre_razon_social;

    INSERT INTO cotizaciones (id, organizacion_id, cliente_id, folio, descripcion, estado, total, fecha)
    VALUES ('cot-e2e-1', v_org, 'cli-e2e-1', 'COT-E2E-001', 'Plataforma 40 ft Especial', 'Aprobada', 385000, '2026-11-18')
    ON CONFLICT (id) DO UPDATE SET estado = 'Aprobada';

    -- Limpiar órdenes previas de prueba si existieran
    DELETE FROM ordenes_trabajo WHERE nomenclatura_id IN ('501-TDN011126-1', '502-INV011126-1');

    INSERT INTO ordenes_trabajo (
        organizacion_id, cotizacion_id, cliente_id, etiqueta, nomenclatura_id,
        modelo, tipo_equipo, origen, linea_producto_id, estado, estado_kanban,
        fecha_pedido, fecha_compromiso
    ) VALUES (
        v_org, 'cot-e2e-1', 'cli-e2e-1', 'Transportes del Norte SA', '501-TDN011126-1',
        'Plataforma 40 ft 2 ejes', '01', 'cotizacion', v_linea, 'En Producción', 'en_proceso',
        '2026-11-18', '2026-12-10'
    ) RETURNING id INTO v_ot_cot;

    INSERT INTO ordenes_trabajo (
        organizacion_id, cotizacion_id, cliente_id, etiqueta, nomenclatura_id,
        modelo, tipo_equipo, origen, linea_producto_id, estado, estado_kanban,
        fecha_pedido, fecha_compromiso
    ) VALUES (
        v_org, NULL, 'cli-e2e-1', 'Unidad Stock Planta #1', '502-INV011126-1',
        'Plataforma 43 ft 3 ejes', '01', 'manual', v_linea, 'Pendiente', 'pendiente',
        '2026-11-22', '2026-12-18'
    ) RETURNING id INTO v_ot_man;

    PERFORM crear_fases_orden(v_org, v_ot_cot);
    PERFORM crear_fases_orden(v_org, v_ot_man);
END $$;
