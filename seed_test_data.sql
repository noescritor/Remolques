-- SEED SCRIPT: Llenar la base de datos con información de prueba completa (Todos los módulos)
-- IMPORTANTE: Ejecutar en el editor SQL de Supabase.

DO $$
DECLARE
    v_org_id uuid;
    v_cliente1_id text;
    v_cliente2_id text;
    v_proveedor_id uuid;
    v_prod1_id text;
    v_prod2_id text;
    v_cat_prod_id uuid;
    v_linea1_id uuid;
    v_fase1_1_id uuid;
    v_fase1_2_id uuid;
    v_cot1_id text;
    v_presu_id uuid;
    v_orden_id uuid;
    v_compra_id uuid;
    v_suffix text := to_char(now(), 'YYYYMMDDHH24MISS');
BEGIN
    SELECT id INTO v_org_id FROM organizaciones LIMIT 1;
    IF v_org_id IS NULL THEN
        RAISE EXCEPTION 'No se encontró ninguna organización.';
    END IF;

    -- Clientes y Proveedores
    INSERT INTO clientes (nombre_razon_social, nombre_contacto, telefono, correo, organizacion_id)
    VALUES ('Transportes del Norte S.A. ' || v_suffix, 'Juan Pérez', '555-0101', 'juan@norte.com', v_org_id) RETURNING id INTO v_cliente1_id;

    INSERT INTO clientes (nombre_razon_social, nombre_contacto, telefono, correo, organizacion_id)
    VALUES ('Logística Integral ' || v_suffix, 'María López', '555-0202', 'maria@logistica.com', v_org_id) RETURNING id INTO v_cliente2_id;

    INSERT INTO proveedores (nombre, contacto, telefono, tiempo_entrega_dias, condiciones_pago, organizacion_id)
    VALUES ('Aceros Monterrey ' || v_suffix, 'Carlos Slim', '555-0303', 3, 'Crédito 30 días', v_org_id) RETURNING id INTO v_proveedor_id;

    -- Productos y Compras
    INSERT INTO categorias_producto (nombre, color, icono, organizacion_id) VALUES ('Acero ' || v_suffix, '#ff0000', 'box', v_org_id) RETURNING id INTO v_cat_prod_id;

    INSERT INTO productos (nombre, descripcion, unidad, tipo, costo, precio_unitario, categoria_id, organizacion_id, stock_actual)
    VALUES ('Viga IPR 10" ' || v_suffix, 'Viga de acero estructural', 'Pieza', 'bien', 1500, 2000, v_cat_prod_id, v_org_id, 50) RETURNING id INTO v_prod1_id;

    INSERT INTO productos (nombre, descripcion, unidad, tipo, costo, precio_unitario, categoria_id, organizacion_id, stock_actual)
    VALUES ('Llanta 22.5 ' || v_suffix, 'Llanta radial para remolque', 'Pieza', 'bien', 3500, 4200, NULL, v_org_id, 100) RETURNING id INTO v_prod2_id;

    INSERT INTO compras_proveedor (folio, proveedor_id, estado, fecha, organizacion_id)
    VALUES ('COMP-TEST-' || v_suffix, v_proveedor_id, 'Recibida', now() - interval '5 days', v_org_id) RETURNING id INTO v_compra_id;

    BEGIN
        INSERT INTO compra_items (compra_id, material_id, cantidad, costo_unitario)
        VALUES (v_compra_id, v_prod1_id::uuid, 50, 1500);
    EXCEPTION WHEN others THEN
        RAISE NOTICE 'Ignorando compra_items por error de compatibilidad de tipos (uuid/text)';
    END;

    -- Cotizaciones y Pagos
    INSERT INTO cotizaciones (folio, cliente_id, estado, total, subtotal, iva, fecha, validez_dias, organizacion_id)
    VALUES ('COT-TEST-' || v_suffix, v_cliente1_id, 'Aprobada', 116000, 100000, 16000, CURRENT_DATE - integer '10', 15, v_org_id) RETURNING id INTO v_cot1_id;

    INSERT INTO items_cotizacion (cotizacion_id, producto_id, posicion, cantidad, unidad, descripcion, precio_unitario, total_item, organizacion_id)
    VALUES (v_cot1_id, v_prod1_id, 1, 50, 'Pieza', 'Viga IPR 10" para chasis', 2000, 100000, v_org_id);

    INSERT INTO pagos (cotizacion_id, monto, fecha, tipo_pago, referencia, organizacion_id)
    VALUES (v_cot1_id, 50000, CURRENT_DATE - integer '2', 'Transferencia', 'SPEI-' || v_suffix, v_org_id);

    -- Presupuestos
    INSERT INTO presupuestos (cliente_id, folio, nomenclatura_id, concepto, datos, total_costo, precio_venta, organizacion_id)
    VALUES (v_cliente1_id, 'PRE-TEST-' || v_suffix, 'TN-PLAT-' || v_suffix, 'Chasis Plataforma 40FT', '{"items": [{"pzas": 1, "material": "Chasis Plataforma", "peso": 1200, "precio": 50000, "importe": 50000}], "notas": "Presupuesto inicial"}'::jsonb, 50000, 116000, v_org_id) RETURNING id INTO v_presu_id;

    -- Tablero de Producción (Configuración y Órdenes)
    INSERT INTO lineas_producto (clave, nombre, organizacion_id) VALUES ('PLATAFORMA-' || v_suffix, 'Plataforma Test', v_org_id) RETURNING id INTO v_linea1_id;

    INSERT INTO fases_produccion (linea_producto_id, orden, nombre, organizacion_id) VALUES (v_linea1_id, 1, 'Corte', v_org_id) RETURNING id INTO v_fase1_1_id;
    INSERT INTO fases_produccion (linea_producto_id, orden, nombre, organizacion_id) VALUES (v_linea1_id, 2, 'Armado de Chasis', v_org_id) RETURNING id INTO v_fase1_2_id;
    INSERT INTO fases_produccion (linea_producto_id, orden, nombre, organizacion_id) VALUES (v_linea1_id, 3, 'Pintura', v_org_id);

    INSERT INTO ordenes_trabajo (organizacion_id, cotizacion_id, cliente_id, nomenclatura_id, tipo_equipo, estado, linea_producto_id, fase_actual_id, estado_kanban, material_faltante)
    VALUES (v_org_id, v_cot1_id, v_cliente1_id, 'TN-PLAT-' || v_suffix, 'Plataforma 40FT', 'En Producción', v_linea1_id, v_fase1_2_id, 'en_proceso', 'Faltan patines reforzados') RETURNING id INTO v_orden_id;

    INSERT INTO historial_fases (orden_trabajo_id, fase_id, estado, organizacion_id, fecha_cambio) VALUES (v_orden_id, v_fase1_1_id, 'completada', v_org_id, now() - interval '2 days');
    INSERT INTO historial_fases (orden_trabajo_id, fase_id, estado, organizacion_id, fecha_cambio) VALUES (v_orden_id, v_fase1_2_id, 'en_proceso', v_org_id, now() - interval '1 day');
END $$;
