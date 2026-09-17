DO $$
DECLARE
    v_org_id uuid;
    v_linea_id uuid;
    v_fase_corte uuid;
    v_fase_armado uuid;
    v_fase_pintura uuid;
    v_suffix text := to_char(now(), 'YYYYMMDDHH24MISS');
    v_orden_id uuid;
    v_cliente_id uuid;
    v_cotizacion_id uuid;
BEGIN
    -- 1. Obtener la organizacion
    SELECT id INTO v_org_id FROM organizaciones LIMIT 1;
    IF v_org_id IS NULL THEN
        RAISE EXCEPTION 'No se encontro ninguna organizacion.';
    END IF;

    -- 2. Insertar Linea de Producto
    INSERT INTO lineas_producto (clave, nombre, organizacion_id) 
    VALUES ('L-PLAT-' || v_suffix, 'Plataformas (Demo)', v_org_id) 
    RETURNING id INTO v_linea_id;

    -- 3. Insertar Fases de Produccion
    INSERT INTO fases_produccion (linea_producto_id, orden, nombre, organizacion_id) 
    VALUES (v_linea_id, 1, 'Corte y Doblez', v_org_id) RETURNING id INTO v_fase_corte;
    
    INSERT INTO fases_produccion (linea_producto_id, orden, nombre, organizacion_id) 
    VALUES (v_linea_id, 2, 'Armado de Estructura', v_org_id) RETURNING id INTO v_fase_armado;
    
    INSERT INTO fases_produccion (linea_producto_id, orden, nombre, organizacion_id) 
    VALUES (v_linea_id, 3, 'Pintura y Acabados', v_org_id) RETURNING id INTO v_fase_pintura;

    -- 4. Asociar las ordenes de trabajo existentes a la nueva linea para que aparezcan en el tablero
    -- Asignaremos la mitad a "Corte" y la mitad a "Armado"
    UPDATE ordenes_trabajo 
    SET linea_producto_id = v_linea_id, 
        fase_actual_id = v_fase_corte,
        estado_kanban = 'en_proceso'
    WHERE organizacion_id = v_org_id 
      AND id IN (SELECT id FROM ordenes_trabajo LIMIT 1);
      
    UPDATE ordenes_trabajo 
    SET linea_producto_id = v_linea_id, 
        fase_actual_id = v_fase_armado,
        estado_kanban = 'en_proceso'
    WHERE organizacion_id = v_org_id 
      AND linea_producto_id IS NULL 
      AND id IN (SELECT id FROM ordenes_trabajo LIMIT 1);

END $$;
