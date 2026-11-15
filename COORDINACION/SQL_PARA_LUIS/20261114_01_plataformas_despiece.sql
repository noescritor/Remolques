-- Migración: Despiece complementario de plataformas
-- Fecha: 2026-11-14
-- Propósito:
--   1. Alta de 5 materiales en catálogo de productos con costo 0:
--      - TORNILLO GALVANIZADO 1/2 X 1 1/2 GRADO 5 (PZA)
--      - BISAGRA 5/8 (PZA)
--      - CADENA 3/16 (M)
--      - PIJA 5/16 X 2 (PZA)
--      - PIJA 5/16 X 2 1/2 (PZA)
--   2. Agregar a receta_base de los 10 modelos de plataforma:
--      - TORNILLO CABEZA DE COCHE 1/4 X 1 1/2 (x4, uso 'Placa de logo', paso 'TERMINADO', seccion NULL)
--   3. Agregar 26 componentes a opcion_componentes:
--      - Adicionales / Caja auxiliar (4 componentes)
--      - Adicionales / Bicicletera (2 componentes)
--      - Riel / Con riel (1 componente)
--      - Opciones de Piso (9 opciones x 2 pijas = 18 componentes)
--      - Suspensión / Fleet Master (1 componente)
-- Reglas:
--   - Idempotente (dos pasadas seguras sin duplicados).
--   - No altera precios ni costos (seccion NULL en receta_base y opcion_componentes, costo 0.00 en productos).
--   - Sin UUIDs de organización fijos en código.

BEGIN;

DO $$
DECLARE
    v_org_id uuid;
    v_mat_tornillo_coche text;
    v_mat_tornillo_allen text;
    v_mat_tuerca_std text;
    v_mat_tapon_fm text;
    v_mat_tornillo_galv text;
    v_mat_bisagra text;
    v_mat_cadena text;
    v_mat_pija_2 text;
    v_mat_pija_2_half text;

    v_opc_caja_aux uuid;
    v_opc_bicicletera uuid;
    v_opc_con_riel uuid;
    v_opc_fleet_master uuid;

    r_mod record;
    r_piso record;
BEGIN
    -- Obtener ID de la organización dinámicamente
    SELECT id INTO v_org_id FROM public.organizaciones LIMIT 1;
    IF v_org_id IS NULL THEN
        RAISE EXCEPTION 'No se encontró ninguna organización en la base de datos.';
    END IF;

    -- =========================================================================
    -- 1. Alta de materiales (5 productos nuevos con costo 0.00)
    -- =========================================================================
    INSERT INTO public.productos (nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, organizacion_id)
    SELECT 'TORNILLO GALVANIZADO 1/2 X 1 1/2 GRADO 5', 'bien', 'materia_prima', 'PZA', 0.00, 0.00, 'Tornillo galvanizado 1/2 x 1 1/2 Grado 5 para bicicletero y riel de matracas', v_org_id
    WHERE NOT EXISTS (
        SELECT 1 FROM public.productos WHERE nombre = 'TORNILLO GALVANIZADO 1/2 X 1 1/2 GRADO 5' AND organizacion_id = v_org_id
    );

    INSERT INTO public.productos (nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, organizacion_id)
    SELECT 'BISAGRA 5/8', 'bien', 'materia_prima', 'PZA', 0.00, 0.00, 'Bisagra 5/8 para caja auxiliar', v_org_id
    WHERE NOT EXISTS (
        SELECT 1 FROM public.productos WHERE nombre = 'BISAGRA 5/8' AND organizacion_id = v_org_id
    );

    INSERT INTO public.productos (nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, organizacion_id)
    SELECT 'CADENA 3/16', 'bien', 'materia_prima', 'M', 0.00, 0.00, 'Cadena 3/16 para caja auxiliar (por metro)', v_org_id
    WHERE NOT EXISTS (
        SELECT 1 FROM public.productos WHERE nombre = 'CADENA 3/16' AND organizacion_id = v_org_id
    );

    INSERT INTO public.productos (nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, organizacion_id)
    SELECT 'PIJA 5/16 X 2', 'bien', 'materia_prima', 'PZA', 0.00, 0.00, 'Pija 5/16 x 2 para fijación de piso', v_org_id
    WHERE NOT EXISTS (
        SELECT 1 FROM public.productos WHERE nombre = 'PIJA 5/16 X 2' AND organizacion_id = v_org_id
    );

    INSERT INTO public.productos (nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, organizacion_id)
    SELECT 'PIJA 5/16 X 2 1/2', 'bien', 'materia_prima', 'PZA', 0.00, 0.00, 'Pija 5/16 x 2 1/2 para fijación de piso', v_org_id
    WHERE NOT EXISTS (
        SELECT 1 FROM public.productos WHERE nombre = 'PIJA 5/16 X 2 1/2' AND organizacion_id = v_org_id
    );

    -- Resolver IDs de materiales
    SELECT id INTO v_mat_tornillo_coche FROM public.productos WHERE nombre = 'TORNILLO CABEZA DE COCHE 1/4 X 1 1/2' AND organizacion_id = v_org_id LIMIT 1;
    SELECT id INTO v_mat_tornillo_allen FROM public.productos WHERE nombre = 'TORNILLO ALLEN 1/2 X 1 1/2' AND organizacion_id = v_org_id LIMIT 1;
    SELECT id INTO v_mat_tuerca_std FROM public.productos WHERE nombre = 'TUERCA ESTANDAR 1/2 GRADO 5' AND organizacion_id = v_org_id LIMIT 1;
    SELECT id INTO v_mat_tapon_fm FROM public.productos WHERE nombre = 'TAPON 1/4 SUSPENSION FM + 4' AND organizacion_id = v_org_id LIMIT 1;
    SELECT id INTO v_mat_tornillo_galv FROM public.productos WHERE nombre = 'TORNILLO GALVANIZADO 1/2 X 1 1/2 GRADO 5' AND organizacion_id = v_org_id LIMIT 1;
    SELECT id INTO v_mat_bisagra FROM public.productos WHERE nombre = 'BISAGRA 5/8' AND organizacion_id = v_org_id LIMIT 1;
    SELECT id INTO v_mat_cadena FROM public.productos WHERE nombre = 'CADENA 3/16' AND organizacion_id = v_org_id LIMIT 1;
    SELECT id INTO v_mat_pija_2 FROM public.productos WHERE nombre = 'PIJA 5/16 X 2' AND organizacion_id = v_org_id LIMIT 1;
    SELECT id INTO v_mat_pija_2_half FROM public.productos WHERE nombre = 'PIJA 5/16 X 2 1/2' AND organizacion_id = v_org_id LIMIT 1;

    IF v_mat_tornillo_coche IS NULL OR v_mat_tornillo_allen IS NULL OR v_mat_tuerca_std IS NULL OR v_mat_tapon_fm IS NULL THEN
        RAISE EXCEPTION 'No se pudieron resolver los materiales base preexistentes en el catálogo.';
    END IF;

    -- =========================================================================
    -- 2. Receta base: TORNILLO CABEZA DE COCHE 1/4 X 1 1/2 en los 10 modelos de plataforma
    -- =========================================================================
    FOR r_mod IN
        SELECT m.id
        FROM public.modelos m
        WHERE m.tipo = 'plataforma' AND m.organizacion_id = v_org_id
    LOOP
        INSERT INTO public.receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
        SELECT r_mod.id, v_mat_tornillo_coche, 4, 'fija', 'TERMINADO', 'Placa de logo', NULL, NULL, 'Placa de logo (reutiliza TORNILLO CABEZA DE COCHE 1/4 X 1 1/2)'
        WHERE NOT EXISTS (
            SELECT 1 FROM public.receta_base rb
            WHERE rb.modelo_id = r_mod.id
              AND rb.material_id = v_mat_tornillo_coche
              AND rb.uso = 'Placa de logo'
        );
    END LOOP;

    -- =========================================================================
    -- 3. Componentes de Opciones (26 componentes en total)
    -- =========================================================================

    -- A. Adicionales / Caja auxiliar (4 componentes)
    SELECT o.id INTO v_opc_caja_aux
    FROM public.opciones_configuracion o
    JOIN public.grupos_configuracion g ON g.id = o.grupo_id
    WHERE g.clave = 'adicionales' AND o.clave = 'caja_auxiliar' AND o.organizacion_id = v_org_id;

    IF v_opc_caja_aux IS NOT NULL THEN
        -- Bisagra 5/8 (cant 2)
        INSERT INTO public.opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, uso, seccion, condicion, notas)
        SELECT v_opc_caja_aux, v_mat_bisagra, 2, 'fija', 'componente', NULL, 'Caja auxiliar', NULL, NULL, 'Bisagra para caja auxiliar'
        WHERE NOT EXISTS (
            SELECT 1 FROM public.opcion_componentes WHERE opcion_id = v_opc_caja_aux AND material_id = v_mat_bisagra
        );

        -- Cadena 3/16 (cant 0.3 m)
        INSERT INTO public.opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, uso, seccion, condicion, notas)
        SELECT v_opc_caja_aux, v_mat_cadena, 0.3, 'fija', 'componente', NULL, 'Caja auxiliar (m)', NULL, NULL, 'Cadena 3/16 (0.30 m) para retención de tapa de caja auxiliar'
        WHERE NOT EXISTS (
            SELECT 1 FROM public.opcion_componentes WHERE opcion_id = v_opc_caja_aux AND material_id = v_mat_cadena
        );

        -- Tornillo Allen 1/2 X 1 1/2 (cant 2)
        INSERT INTO public.opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, uso, seccion, condicion, notas)
        SELECT v_opc_caja_aux, v_mat_tornillo_allen, 2, 'fija', 'componente', NULL, 'Caja auxiliar', NULL, NULL, 'Tornillería para montaje de caja auxiliar'
        WHERE NOT EXISTS (
            SELECT 1 FROM public.opcion_componentes WHERE opcion_id = v_opc_caja_aux AND material_id = v_mat_tornillo_allen
        );

        -- Tuerca Estándar 1/2 Grado 5 (cant 2)
        INSERT INTO public.opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, uso, seccion, condicion, notas)
        SELECT v_opc_caja_aux, v_mat_tuerca_std, 2, 'fija', 'componente', NULL, 'Caja auxiliar', NULL, NULL, 'Tuerca estándar 1/2 grado 5 para caja auxiliar'
        WHERE NOT EXISTS (
            SELECT 1 FROM public.opcion_componentes WHERE opcion_id = v_opc_caja_aux AND material_id = v_mat_tuerca_std
        );
    END IF;

    -- B. Adicionales / Bicicletera (2 componentes)
    SELECT o.id INTO v_opc_bicicletera
    FROM public.opciones_configuracion o
    JOIN public.grupos_configuracion g ON g.id = o.grupo_id
    WHERE g.clave = 'adicionales' AND o.clave = 'bicicletera' AND o.organizacion_id = v_org_id;

    IF v_opc_bicicletera IS NOT NULL THEN
        -- Tornillo Galvanizado 1/2 X 1 1/2 Grado 5 (cant 2)
        INSERT INTO public.opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, uso, seccion, condicion, notas)
        SELECT v_opc_bicicletera, v_mat_tornillo_galv, 2, 'fija', 'componente', NULL, 'Bicicletero', NULL, NULL, 'Tornillería para montaje de bicicletero'
        WHERE NOT EXISTS (
            SELECT 1 FROM public.opcion_componentes WHERE opcion_id = v_opc_bicicletera AND material_id = v_mat_tornillo_galv
        );

        -- Tuerca Estándar 1/2 Grado 5 (cant 2)
        INSERT INTO public.opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, uso, seccion, condicion, notas)
        SELECT v_opc_bicicletera, v_mat_tuerca_std, 2, 'fija', 'componente', NULL, 'Bicicletero', NULL, NULL, 'Tuerca estándar 1/2 grado 5 para bicicletero'
        WHERE NOT EXISTS (
            SELECT 1 FROM public.opcion_componentes WHERE opcion_id = v_opc_bicicletera AND material_id = v_mat_tuerca_std
        );
    END IF;

    -- C. Riel / Con riel (1 componente)
    SELECT o.id INTO v_opc_con_riel
    FROM public.opciones_configuracion o
    JOIN public.grupos_configuracion g ON g.id = o.grupo_id
    WHERE g.clave = 'riel' AND o.clave = 'con_riel' AND o.organizacion_id = v_org_id;

    IF v_opc_con_riel IS NOT NULL THEN
        -- Tornillo Galvanizado 1/2 X 1 1/2 Grado 5 (cant 2)
        INSERT INTO public.opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, uso, seccion, condicion, notas)
        SELECT v_opc_con_riel, v_mat_tornillo_galv, 2, 'fija', 'componente', NULL, 'Riel de matracas', NULL, NULL, 'Conflicto: manual dice tornillo 1/2 X 1 3/4; lista dice 1/2 X 1 1/2 Grado 5'
        WHERE NOT EXISTS (
            SELECT 1 FROM public.opcion_componentes WHERE opcion_id = v_opc_con_riel AND material_id = v_mat_tornillo_galv
        );
    END IF;

    -- D. Opciones de Piso (9 opciones x 2 pijas = 18 componentes)
    FOR r_piso IN
        SELECT o.id, o.clave
        FROM public.opciones_configuracion o
        JOIN public.grupos_configuracion g ON g.id = o.grupo_id
        WHERE g.clave = 'piso' AND o.clave != 'sin_piso' AND o.organizacion_id = v_org_id
    LOOP
        -- Pija 5/16 X 2 (cant 450)
        INSERT INTO public.opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, uso, seccion, condicion, notas)
        SELECT r_piso.id, v_mat_pija_2, 450, 'fija', 'componente', NULL, 'Pijas del piso', NULL, NULL, 'Cantidad preliminar 450 pzas según union de listados paso 11; pendiente confirmación Leolca por tipo de piso'
        WHERE NOT EXISTS (
            SELECT 1 FROM public.opcion_componentes WHERE opcion_id = r_piso.id AND material_id = v_mat_pija_2
        );

        -- Pija 5/16 X 2 1/2 (cant 150)
        INSERT INTO public.opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, uso, seccion, condicion, notas)
        SELECT r_piso.id, v_mat_pija_2_half, 150, 'fija', 'componente', NULL, 'Pijas del piso', NULL, NULL, 'Cantidad preliminar 150 pzas según union de listados paso 11; pendiente confirmación Leolca por tipo de piso'
        WHERE NOT EXISTS (
            SELECT 1 FROM public.opcion_componentes WHERE opcion_id = r_piso.id AND material_id = v_mat_pija_2_half
        );
    END LOOP;

    -- E. Suspensión / Fleet Master (1 componente)
    SELECT o.id INTO v_opc_fleet_master
    FROM public.opciones_configuracion o
    JOIN public.grupos_configuracion g ON g.id = o.grupo_id
    WHERE g.clave = 'suspension' AND o.clave = 'fleet_master' AND o.organizacion_id = v_org_id;

    IF v_opc_fleet_master IS NOT NULL THEN
        -- Tapón 1/4 suspensión FM + 4 (cant 3, paso AIRE)
        INSERT INTO public.opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, uso, seccion, condicion, notas)
        SELECT v_opc_fleet_master, v_mat_tapon_fm, 3, 'fija', 'componente', 'AIRE', 'Kit de aire con suspensión Fleet Master', NULL, NULL, 'Tapón 1/4 para suspensión Fleet Master'
        WHERE NOT EXISTS (
            SELECT 1 FROM public.opcion_componentes WHERE opcion_id = v_opc_fleet_master AND material_id = v_mat_tapon_fm
        );
    END IF;

END $$;

COMMIT;
