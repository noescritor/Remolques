-- Migración: Despiece complementario de plataformas
-- Fecha: 2026-11-14 (Corrección Ronda 2)
-- Propósito:
--   1. Alta de 6 materiales en catálogo de productos con costo 0:
--      - TORNILLO GALVANIZADO 1/2 X 1 1/2 GRADO 5 (PZA)
--      - BISAGRA 5/8 (PZA)
--      - CADENA 3/16 (M)
--      - PIJA 5/16 X 2 (PZA)
--      - PIJA 5/16 X 2 1/2 (PZA)
--      - TORNILLO CABEZA DE COCHE 1/4 X 3 (PZA)
--   2. Agregar a receta_base de los 10 modelos de plataforma:
--      - TORNILLO CABEZA DE COCHE 1/4 X 3 (x4, uso 'Placa de logo', paso 'TERMINADO', seccion NULL)
--   3. Agregar 26 componentes a opcion_componentes con paso y fase definidos:
--      - Adicionales / Caja auxiliar (4 componentes, paso 'EXTRAS', fase 'extras')
--      - Adicionales / Bicicletera (2 componentes, paso 'EXTRAS', fase 'extras')
--      - Riel / Con riel (1 componente, paso 'TERMINADO', fase 'paso_12')
--      - Opciones de Piso (9 opciones x 2 pijas = 18 componentes, paso 'PASO 11', fase 'paso_11')
--      - Suspensión / Fleet Master (1 componente, paso 'AIRE', fase 'paso_9')
--   4. Asignación condicional de fase_id si fases_despiece existe.
-- Reglas:
--   - Idempotente (dos pasadas seguras sin duplicados).
--   - No altera precios ni costos (seccion NULL en receta_base y opcion_componentes, costo 0.00 en productos).
--   - Sin UUIDs de organización fijos en código.

BEGIN;

DO $$
DECLARE
    v_org_id uuid;
    v_mat_tornillo_coche_3 text;
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

    v_fase_piso uuid;
    v_fase_extras uuid;
    v_fase_terminado uuid;
    v_fase_aire uuid;

    r_mod record;
    r_piso record;
BEGIN
    -- Obtener ID de la organización dinámicamente
    SELECT id INTO v_org_id FROM public.organizaciones LIMIT 1;
    IF v_org_id IS NULL THEN
        RAISE EXCEPTION 'No se encontró ninguna organización en la base de datos.';
    END IF;

    -- =========================================================================
    -- 1. Alta de materiales (6 productos nuevos con costo 0.00)
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

    INSERT INTO public.productos (nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, organizacion_id)
    SELECT 'TORNILLO CABEZA DE COCHE 1/4 X 3', 'bien', 'materia_prima', 'PZA', 0.00, 0.00, 'Tornillo cabeza de coche 1/4 x 3 para placa de logo', v_org_id
    WHERE NOT EXISTS (
        SELECT 1 FROM public.productos WHERE nombre = 'TORNILLO CABEZA DE COCHE 1/4 X 3' AND organizacion_id = v_org_id
    );

    -- Resolver IDs de materiales
    SELECT id INTO v_mat_tornillo_coche_3 FROM public.productos WHERE nombre = 'TORNILLO CABEZA DE COCHE 1/4 X 3' AND organizacion_id = v_org_id LIMIT 1;
    SELECT id INTO v_mat_tornillo_allen FROM public.productos WHERE nombre = 'TORNILLO ALLEN 1/2 X 1 1/2' AND organizacion_id = v_org_id LIMIT 1;
    SELECT id INTO v_mat_tuerca_std FROM public.productos WHERE nombre = 'TUERCA ESTANDAR 1/2 GRADO 5' AND organizacion_id = v_org_id LIMIT 1;
    SELECT id INTO v_mat_tapon_fm FROM public.productos WHERE nombre = 'TAPON 1/4 SUSPENSION FM + 4' AND organizacion_id = v_org_id LIMIT 1;
    SELECT id INTO v_mat_tornillo_galv FROM public.productos WHERE nombre = 'TORNILLO GALVANIZADO 1/2 X 1 1/2 GRADO 5' AND organizacion_id = v_org_id LIMIT 1;
    SELECT id INTO v_mat_bisagra FROM public.productos WHERE nombre = 'BISAGRA 5/8' AND organizacion_id = v_org_id LIMIT 1;
    SELECT id INTO v_mat_cadena FROM public.productos WHERE nombre = 'CADENA 3/16' AND organizacion_id = v_org_id LIMIT 1;
    SELECT id INTO v_mat_pija_2 FROM public.productos WHERE nombre = 'PIJA 5/16 X 2' AND organizacion_id = v_org_id LIMIT 1;
    SELECT id INTO v_mat_pija_2_half FROM public.productos WHERE nombre = 'PIJA 5/16 X 2 1/2' AND organizacion_id = v_org_id LIMIT 1;

    IF v_mat_tornillo_coche_3 IS NULL OR v_mat_tornillo_allen IS NULL OR v_mat_tuerca_std IS NULL OR v_mat_tapon_fm IS NULL THEN
        RAISE EXCEPTION 'No se pudieron resolver los materiales requeridos en el catálogo.';
    END IF;

    -- =========================================================================
    -- 2. Receta base: TORNILLO CABEZA DE COCHE 1/4 X 3 en los 10 modelos de plataforma
    -- =========================================================================
    -- Limpiar versión previa si se había insertado 1/4 X 1 1/2 para placa de logo
    DELETE FROM public.receta_base rb
    WHERE rb.uso = 'Placa de logo'
      AND rb.material_id = (
          SELECT id FROM public.productos
          WHERE nombre = 'TORNILLO CABEZA DE COCHE 1/4 X 1 1/2' AND organizacion_id = v_org_id
          LIMIT 1
      );

    FOR r_mod IN
        SELECT m.id
        FROM public.modelos m
        WHERE m.tipo = 'plataforma' AND m.organizacion_id = v_org_id
    LOOP
        INSERT INTO public.receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
        SELECT r_mod.id, v_mat_tornillo_coche_3, 4, 'fija', 'TERMINADO', 'Placa de logo', NULL, NULL, 'Placa de logo'
        WHERE NOT EXISTS (
            SELECT 1 FROM public.receta_base rb
            WHERE rb.modelo_id = r_mod.id
              AND rb.material_id = v_mat_tornillo_coche_3
              AND rb.uso = 'Placa de logo'
        );
    END LOOP;

    -- =========================================================================
    -- 3. Componentes de Opciones (26 componentes en total con paso explícito)
    -- =========================================================================

    -- A. Adicionales / Caja auxiliar (4 componentes, paso 'EXTRAS')
    SELECT o.id INTO v_opc_caja_aux
    FROM public.opciones_configuracion o
    JOIN public.grupos_configuracion g ON g.id = o.grupo_id
    WHERE g.clave = 'adicionales' AND o.clave = 'caja_auxiliar' AND o.organizacion_id = v_org_id;

    IF v_opc_caja_aux IS NOT NULL THEN
        -- Bisagra 5/8 (cant 2)
        INSERT INTO public.opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, uso, seccion, condicion, notas)
        SELECT v_opc_caja_aux, v_mat_bisagra, 2, 'fija', 'componente', 'EXTRAS', 'Caja auxiliar', NULL, NULL, 'Bisagra para caja auxiliar'
        WHERE NOT EXISTS (
            SELECT 1 FROM public.opcion_componentes WHERE opcion_id = v_opc_caja_aux AND material_id = v_mat_bisagra
        );

        -- Cadena 3/16 (cant 0.3 m)
        INSERT INTO public.opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, uso, seccion, condicion, notas)
        SELECT v_opc_caja_aux, v_mat_cadena, 0.3, 'fija', 'componente', 'EXTRAS', 'Caja auxiliar (m)', NULL, NULL, 'Cadena 3/16 (0.30 m) para retención de tapa de caja auxiliar'
        WHERE NOT EXISTS (
            SELECT 1 FROM public.opcion_componentes WHERE opcion_id = v_opc_caja_aux AND material_id = v_mat_cadena
        );

        -- Tornillo Allen 1/2 X 1 1/2 (cant 2)
        INSERT INTO public.opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, uso, seccion, condicion, notas)
        SELECT v_opc_caja_aux, v_mat_tornillo_allen, 2, 'fija', 'componente', 'EXTRAS', 'Caja auxiliar', NULL, NULL, 'Tornillería para montaje de caja auxiliar'
        WHERE NOT EXISTS (
            SELECT 1 FROM public.opcion_componentes WHERE opcion_id = v_opc_caja_aux AND material_id = v_mat_tornillo_allen
        );

        -- Tuerca Estándar 1/2 Grado 5 (cant 2)
        INSERT INTO public.opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, uso, seccion, condicion, notas)
        SELECT v_opc_caja_aux, v_mat_tuerca_std, 2, 'fija', 'componente', 'EXTRAS', 'Caja auxiliar', NULL, NULL, 'Tuerca estándar 1/2 grado 5 para caja auxiliar'
        WHERE NOT EXISTS (
            SELECT 1 FROM public.opcion_componentes WHERE opcion_id = v_opc_caja_aux AND material_id = v_mat_tuerca_std
        );

        -- Asegurar paso 'EXTRAS' si ya existían
        UPDATE public.opcion_componentes
        SET paso = 'EXTRAS'
        WHERE opcion_id = v_opc_caja_aux AND (paso IS NULL OR paso != 'EXTRAS');
    END IF;

    -- B. Adicionales / Bicicletera (2 componentes, paso 'EXTRAS')
    SELECT o.id INTO v_opc_bicicletera
    FROM public.opciones_configuracion o
    JOIN public.grupos_configuracion g ON g.id = o.grupo_id
    WHERE g.clave = 'adicionales' AND o.clave = 'bicicletera' AND o.organizacion_id = v_org_id;

    IF v_opc_bicicletera IS NOT NULL THEN
        -- Tornillo Galvanizado 1/2 X 1 1/2 Grado 5 (cant 2)
        INSERT INTO public.opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, uso, seccion, condicion, notas)
        SELECT v_opc_bicicletera, v_mat_tornillo_galv, 2, 'fija', 'componente', 'EXTRAS', 'Bicicletero', NULL, NULL, 'Tornillería para montaje de bicicletero'
        WHERE NOT EXISTS (
            SELECT 1 FROM public.opcion_componentes WHERE opcion_id = v_opc_bicicletera AND material_id = v_mat_tornillo_galv
        );

        -- Tuerca Estándar 1/2 Grado 5 (cant 2)
        INSERT INTO public.opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, uso, seccion, condicion, notas)
        SELECT v_opc_bicicletera, v_mat_tuerca_std, 2, 'fija', 'componente', 'EXTRAS', 'Bicicletero', NULL, NULL, 'Tuerca estándar 1/2 grado 5 para bicicletero'
        WHERE NOT EXISTS (
            SELECT 1 FROM public.opcion_componentes WHERE opcion_id = v_opc_bicicletera AND material_id = v_mat_tuerca_std
        );

        -- Asegurar paso 'EXTRAS' si ya existían
        UPDATE public.opcion_componentes
        SET paso = 'EXTRAS'
        WHERE opcion_id = v_opc_bicicletera AND (paso IS NULL OR paso != 'EXTRAS');
    END IF;

    -- C. Riel / Con riel (1 componente, paso 'TERMINADO')
    SELECT o.id INTO v_opc_con_riel
    FROM public.opciones_configuracion o
    JOIN public.grupos_configuracion g ON g.id = o.grupo_id
    WHERE g.clave = 'riel' AND o.clave = 'con_riel' AND o.organizacion_id = v_org_id;

    IF v_opc_con_riel IS NOT NULL THEN
        -- Tornillo Galvanizado 1/2 X 1 1/2 Grado 5 (cant 2)
        INSERT INTO public.opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, uso, seccion, condicion, notas)
        SELECT v_opc_con_riel, v_mat_tornillo_galv, 2, 'fija', 'componente', 'TERMINADO', 'Riel de matracas', NULL, NULL, 'Conflicto: manual dice tornillo 1/2 X 1 3/4; lista dice 1/2 X 1 1/2 Grado 5'
        WHERE NOT EXISTS (
            SELECT 1 FROM public.opcion_componentes WHERE opcion_id = v_opc_con_riel AND material_id = v_mat_tornillo_galv
        );

        -- Asegurar paso 'TERMINADO' si ya existía
        UPDATE public.opcion_componentes
        SET paso = 'TERMINADO'
        WHERE opcion_id = v_opc_con_riel AND material_id = v_mat_tornillo_galv AND (paso IS NULL OR paso != 'TERMINADO');
    END IF;

    -- D. Opciones de Piso (9 opciones x 2 pijas = 18 componentes, paso 'PASO 11')
    FOR r_piso IN
        SELECT o.id, o.clave
        FROM public.opciones_configuracion o
        JOIN public.grupos_configuracion g ON g.id = o.grupo_id
        WHERE g.clave = 'piso' AND o.clave != 'sin_piso' AND o.organizacion_id = v_org_id
    LOOP
        -- Pija 5/16 X 2 (cant 450)
        INSERT INTO public.opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, uso, seccion, condicion, notas)
        SELECT r_piso.id, v_mat_pija_2, 450, 'fija', 'componente', 'PASO 11', 'Pijas del piso', NULL, NULL, 'Cantidad preliminar 450 pzas según union de listados paso 11; pendiente confirmación Leolca por tipo de piso'
        WHERE NOT EXISTS (
            SELECT 1 FROM public.opcion_componentes WHERE opcion_id = r_piso.id AND material_id = v_mat_pija_2
        );

        -- Pija 5/16 X 2 1/2 (cant 150)
        INSERT INTO public.opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, uso, seccion, condicion, notas)
        SELECT r_piso.id, v_mat_pija_2_half, 150, 'fija', 'componente', 'PASO 11', 'Pijas del piso', NULL, NULL, 'Cantidad preliminar 150 pzas según union de listados paso 11; pendiente confirmación Leolca por tipo de piso'
        WHERE NOT EXISTS (
            SELECT 1 FROM public.opcion_componentes WHERE opcion_id = r_piso.id AND material_id = v_mat_pija_2_half
        );

        -- Asegurar paso 'PASO 11' si ya existían
        UPDATE public.opcion_componentes
        SET paso = 'PASO 11'
        WHERE opcion_id = r_piso.id AND material_id IN (v_mat_pija_2, v_mat_pija_2_half) AND (paso IS NULL OR paso != 'PASO 11');
    END LOOP;

    -- E. Suspensión / Fleet Master (1 componente, paso 'AIRE')
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

        -- Asegurar paso 'AIRE' si ya existía
        UPDATE public.opcion_componentes
        SET paso = 'AIRE'
        WHERE opcion_id = v_opc_fleet_master AND material_id = v_mat_tapon_fm AND (paso IS NULL OR paso != 'AIRE');
    END IF;

    -- =========================================================================
    -- 4. Asignación de fase_id (condicional si fases_despiece existe en la base)
    -- =========================================================================
    IF to_regclass('public.fases_despiece') IS NOT NULL THEN
        -- Resolver fase_id de cada paso mediante consulta dinámica segura
        EXECUTE 'SELECT id FROM public.fases_despiece WHERE clave = ''paso_11'' AND organizacion_id = $1 LIMIT 1' INTO v_fase_piso USING v_org_id;
        EXECUTE 'SELECT id FROM public.fases_despiece WHERE clave = ''extras'' AND organizacion_id = $1 LIMIT 1' INTO v_fase_extras USING v_org_id;
        EXECUTE 'SELECT id FROM public.fases_despiece WHERE clave = ''paso_12'' AND organizacion_id = $1 LIMIT 1' INTO v_fase_terminado USING v_org_id;
        EXECUTE 'SELECT id FROM public.fases_despiece WHERE clave = ''paso_9'' AND organizacion_id = $1 LIMIT 1' INTO v_fase_aire USING v_org_id;

        -- Fallback a fases_despiece_equivalencias si aplica
        IF v_fase_piso IS NULL AND to_regclass('public.fases_despiece_equivalencias') IS NOT NULL THEN
            EXECUTE 'SELECT fase_id FROM public.fases_despiece_equivalencias WHERE paso_legacy = ''PASO 11'' AND organizacion_id = $1 LIMIT 1' INTO v_fase_piso USING v_org_id;
        END IF;
        IF v_fase_extras IS NULL AND to_regclass('public.fases_despiece_equivalencias') IS NOT NULL THEN
            EXECUTE 'SELECT fase_id FROM public.fases_despiece_equivalencias WHERE paso_legacy = ''EXTRAS'' AND organizacion_id = $1 LIMIT 1' INTO v_fase_extras USING v_org_id;
        END IF;
        IF v_fase_terminado IS NULL AND to_regclass('public.fases_despiece_equivalencias') IS NOT NULL THEN
            EXECUTE 'SELECT fase_id FROM public.fases_despiece_equivalencias WHERE paso_legacy = ''TERMINADO'' AND organizacion_id = $1 LIMIT 1' INTO v_fase_terminado USING v_org_id;
        END IF;
        IF v_fase_aire IS NULL AND to_regclass('public.fases_despiece_equivalencias') IS NOT NULL THEN
            EXECUTE 'SELECT fase_id FROM public.fases_despiece_equivalencias WHERE paso_legacy = ''AIRE'' AND organizacion_id = $1 LIMIT 1' INTO v_fase_aire USING v_org_id;
        END IF;

        -- Asignar en opcion_componentes (solo las filas que esta migración gestiona)
        IF v_fase_piso IS NOT NULL THEN
            UPDATE public.opcion_componentes oc
            SET fase_id = v_fase_piso
            FROM public.opciones_configuracion o, public.grupos_configuracion g
            WHERE oc.opcion_id = o.id AND o.grupo_id = g.id
              AND g.clave = 'piso' AND o.clave != 'sin_piso'
              AND oc.material_id IN (v_mat_pija_2, v_mat_pija_2_half)
              AND (oc.fase_id IS NULL OR oc.fase_id != v_fase_piso);
        END IF;

        IF v_fase_extras IS NOT NULL THEN
            UPDATE public.opcion_componentes oc
            SET fase_id = v_fase_extras
            FROM public.opciones_configuracion o, public.grupos_configuracion g
            WHERE oc.opcion_id = o.id AND o.grupo_id = g.id
              AND g.clave = 'adicionales' AND o.clave IN ('caja_auxiliar', 'bicicletera')
              AND oc.material_id IN (v_mat_bisagra, v_mat_cadena, v_mat_tornillo_allen, v_mat_tuerca_std, v_mat_tornillo_galv)
              AND (oc.fase_id IS NULL OR oc.fase_id != v_fase_extras);
        END IF;

        IF v_fase_terminado IS NOT NULL THEN
            UPDATE public.opcion_componentes oc
            SET fase_id = v_fase_terminado
            FROM public.opciones_configuracion o, public.grupos_configuracion g
            WHERE oc.opcion_id = o.id AND o.grupo_id = g.id
              AND g.clave = 'riel' AND o.clave = 'con_riel'
              AND oc.material_id = v_mat_tornillo_galv
              AND (oc.fase_id IS NULL OR oc.fase_id != v_fase_terminado);
        END IF;

        IF v_fase_aire IS NOT NULL THEN
            UPDATE public.opcion_componentes oc
            SET fase_id = v_fase_aire
            FROM public.opciones_configuracion o, public.grupos_configuracion g
            WHERE oc.opcion_id = o.id AND o.grupo_id = g.id
              AND g.clave = 'suspension' AND o.clave = 'fleet_master'
              AND oc.material_id = v_mat_tapon_fm
              AND (oc.fase_id IS NULL OR oc.fase_id != v_fase_aire);
        END IF;

        -- Asignar en receta_base (Placa de logo -> TERMINADO / paso_12)
        IF v_fase_terminado IS NOT NULL THEN
            UPDATE public.receta_base rb
            SET fase_id = v_fase_terminado
            FROM public.modelos m
            WHERE m.id = rb.modelo_id
              AND m.tipo = 'plataforma'
              AND rb.material_id = v_mat_tornillo_coche_3
              AND rb.uso = 'Placa de logo'
              AND (rb.fase_id IS NULL OR rb.fase_id != v_fase_terminado);
        END IF;
    END IF;

END $$;

COMMIT;
