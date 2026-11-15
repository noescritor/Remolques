-- Migración: Despiece de DOLLY 2 EJES (solo datos, sin mover precios)
-- Fecha: 2026-11-14
-- Propósito:
--   1. Alta de 14 materiales en productos con costo 0.00 y precio 0.00:
--      (Oreja, Bisagra de dolly, Perno de dolly, Buje cónico grande, 3 Donas, Tuerca Gripco 5/8,
--       2 Quintas, Tornillo 5/8x2 1/2 gr 8, Manguera espiral, Macho 7 polos, Cable 7 polos).
--   2. Cargar 53 renglones a receta_base de DOLLY 2 EJES (seccion NULL, escala 'fija').
--   3. Cargar 20 componentes en opcion_componentes (3 donas x 4 componentes, 2 quintas x 4 componentes).
--   4. Asignación condicional de fase_id si fases_despiece existe.
-- Reglas duras:
--   - Idempotente (dos pasadas con ON_ERROR_STOP=1 sin duplicados).
--   - Cero impacto en precios ni costos (seccion NULL, costo 0.00).
--   - Sin UUIDs fijos de organización en código.

BEGIN;

DO $$
DECLARE
    v_org_id uuid;
    v_mod_dolly uuid;
    v_fase_paso_1 uuid;
    v_fase_limpieza uuid;
    v_fase_aire uuid;
    v_fase_luz uuid;
    v_fase_terminado uuid;
    v_fase_extras uuid;

    v_mat_id text;
    v_opc_id uuid;
BEGIN
    -- 0. Resolver ID de organización
    SELECT id INTO v_org_id FROM public.organizaciones LIMIT 1;
    IF v_org_id IS NULL THEN
        RAISE EXCEPTION 'No se encontró ninguna organización en la base de datos.';
    END IF;

    -- Resolver modelo de DOLLY 2 EJES
    SELECT m.id INTO v_mod_dolly
    FROM public.modelos m
    WHERE m.tipo = 'dolly' AND m.organizacion_id = v_org_id
    LIMIT 1;
    IF v_mod_dolly IS NULL THEN
        RAISE EXCEPTION 'No se encontró el modelo de DOLLY 2 EJES.';
    END IF;

    -- =========================================================================
    -- 1. Alta de 14 materiales nuevos (costo 0.00, precio 0.00)
    -- =========================================================================
    INSERT INTO public.productos (nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, organizacion_id)
    SELECT 'OREJA', 'bien', 'materia_prima', 'PZA', 0.00, 0.00, 'OREJA para CUADRO', v_org_id
    WHERE NOT EXISTS (
        SELECT 1 FROM public.productos WHERE nombre = 'OREJA' AND organizacion_id = v_org_id
    );
    INSERT INTO public.productos (nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, organizacion_id)
    SELECT 'BISAGRA DE DOLLY', 'bien', 'materia_prima', 'PZA', 0.00, 0.00, 'BISAGRA DE DOLLY para CUADRO', v_org_id
    WHERE NOT EXISTS (
        SELECT 1 FROM public.productos WHERE nombre = 'BISAGRA DE DOLLY' AND organizacion_id = v_org_id
    );
    INSERT INTO public.productos (nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, organizacion_id)
    SELECT 'PERNO DE DOLLY', 'bien', 'materia_prima', 'PZA', 0.00, 0.00, 'PERNO DE DOLLY para CUADRO', v_org_id
    WHERE NOT EXISTS (
        SELECT 1 FROM public.productos WHERE nombre = 'PERNO DE DOLLY' AND organizacion_id = v_org_id
    );
    INSERT INTO public.productos (nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, organizacion_id)
    SELECT 'BUJE CONICO GRANDE', 'bien', 'materia_prima', 'PZA', 0.00, 0.00, 'BUJE CONICO GRANDE para CUADRO', v_org_id
    WHERE NOT EXISTS (
        SELECT 1 FROM public.productos WHERE nombre = 'BUJE CONICO GRANDE' AND organizacion_id = v_org_id
    );
    INSERT INTO public.productos (nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, organizacion_id)
    SELECT 'DONA HOLLAND', 'bien', 'materia_prima', 'PZA', 0.00, 0.00, 'DONA HOLLAND para PARA GANCHO HOLLAND', v_org_id
    WHERE NOT EXISTS (
        SELECT 1 FROM public.productos WHERE nombre = 'DONA HOLLAND' AND organizacion_id = v_org_id
    );
    INSERT INTO public.productos (nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, organizacion_id)
    SELECT 'DONA PREMIER', 'bien', 'materia_prima', 'PZA', 0.00, 0.00, 'DONA PREMIER para PARA GANCHO PREMIER', v_org_id
    WHERE NOT EXISTS (
        SELECT 1 FROM public.productos WHERE nombre = 'DONA PREMIER' AND organizacion_id = v_org_id
    );
    INSERT INTO public.productos (nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, organizacion_id)
    SELECT 'DONA PREMIER BESTIA', 'bien', 'materia_prima', 'PZA', 0.00, 0.00, 'DONA PREMIER BESTIA para PARA GANCHO BESTIA', v_org_id
    WHERE NOT EXISTS (
        SELECT 1 FROM public.productos WHERE nombre = 'DONA PREMIER BESTIA' AND organizacion_id = v_org_id
    );
    INSERT INTO public.productos (nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, organizacion_id)
    SELECT 'TUERCA GRIPCO 5/8', 'bien', 'materia_prima', 'PZA', 0.00, 0.00, 'TUERCA GRIPCO 5/8 para TORNILLERIA DE DONA; TORNILLERIA DE QUINTA', v_org_id
    WHERE NOT EXISTS (
        SELECT 1 FROM public.productos WHERE nombre = 'TUERCA GRIPCO 5/8' AND organizacion_id = v_org_id
    );
    INSERT INTO public.productos (nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, organizacion_id)
    SELECT 'QUINTA HOLLAND', 'bien', 'materia_prima', 'PZA', 0.00, 0.00, 'QUINTA HOLLAND para Opción Quinta (Holland)', v_org_id
    WHERE NOT EXISTS (
        SELECT 1 FROM public.productos WHERE nombre = 'QUINTA HOLLAND' AND organizacion_id = v_org_id
    );
    INSERT INTO public.productos (nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, organizacion_id)
    SELECT 'QUINTA FONTAINE', 'bien', 'materia_prima', 'PZA', 0.00, 0.00, 'QUINTA FONTAINE para Opción Quinta (Fontaine)', v_org_id
    WHERE NOT EXISTS (
        SELECT 1 FROM public.productos WHERE nombre = 'QUINTA FONTAINE' AND organizacion_id = v_org_id
    );
    INSERT INTO public.productos (nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, organizacion_id)
    SELECT 'TORNILLO 5/8 X 2 1/2 GRADO 8', 'bien', 'materia_prima', 'PZA', 0.00, 0.00, 'TORNILLO 5/8 X 2 1/2 GRADO 8 para TORNILLERIA DE QUINTA', v_org_id
    WHERE NOT EXISTS (
        SELECT 1 FROM public.productos WHERE nombre = 'TORNILLO 5/8 X 2 1/2 GRADO 8' AND organizacion_id = v_org_id
    );
    INSERT INTO public.productos (nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, organizacion_id)
    SELECT 'JUEGO DE MANGUERA ESPIRAL AZUL Y ROJA', 'bien', 'materia_prima', 'PZA', 0.00, 0.00, 'JUEGO DE MANGUERA ESPIRAL AZUL Y ROJA para Receta base', v_org_id
    WHERE NOT EXISTS (
        SELECT 1 FROM public.productos WHERE nombre = 'JUEGO DE MANGUERA ESPIRAL AZUL Y ROJA' AND organizacion_id = v_org_id
    );
    INSERT INTO public.productos (nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, organizacion_id)
    SELECT 'MACHO SOLO 7 POLOS', 'bien', 'materia_prima', 'PZA', 0.00, 0.00, 'MACHO SOLO 7 POLOS para Receta base', v_org_id
    WHERE NOT EXISTS (
        SELECT 1 FROM public.productos WHERE nombre = 'MACHO SOLO 7 POLOS' AND organizacion_id = v_org_id
    );
    INSERT INTO public.productos (nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, organizacion_id)
    SELECT 'CABLE 7 POLOS', 'bien', 'materia_prima', 'M', 0.00, 0.00, 'CABLE 7 POLOS para Receta base', v_org_id
    WHERE NOT EXISTS (
        SELECT 1 FROM public.productos WHERE nombre = 'CABLE 7 POLOS' AND organizacion_id = v_org_id
    );

    -- =========================================================================
    -- 2. Receta base de DOLLY 2 EJES (53 renglones)
    -- =========================================================================
    -- [1] DISCO LAMINADO 7 (cant: 1.0, paso: PASO 1)
    SELECT id INTO v_mat_id FROM public.productos WHERE nombre = 'DISCO LAMINADO 7' AND organizacion_id = v_org_id LIMIT 1;
    IF v_mat_id IS NOT NULL THEN
        INSERT INTO public.receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
        SELECT v_mod_dolly, v_mat_id, 1.0, 'fija', 'PASO 1', 'ARMADO', NULL, NULL, 'Solo en el manual (el kit tipo H no lo trae)'
        WHERE NOT EXISTS (
            SELECT 1 FROM public.receta_base WHERE modelo_id = v_mod_dolly AND material_id = v_mat_id
        );

        UPDATE public.receta_base
        SET cantidad = 1.0, escala = 'fija', paso = 'PASO 1', uso = 'ARMADO', seccion = NULL, condicion = NULL, notas = 'Solo en el manual (el kit tipo H no lo trae)'
        WHERE modelo_id = v_mod_dolly AND material_id = v_mat_id AND (paso IS NULL OR paso != 'PASO 1');
    END IF;
    -- [2] DISCO DE CORTE 7 (cant: 1.0, paso: PASO 1)
    SELECT id INTO v_mat_id FROM public.productos WHERE nombre = 'DISCO DE CORTE 7' AND organizacion_id = v_org_id LIMIT 1;
    IF v_mat_id IS NOT NULL THEN
        INSERT INTO public.receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
        SELECT v_mod_dolly, v_mat_id, 1.0, 'fija', 'PASO 1', 'ARMADO', NULL, NULL, 'Solo en el manual (el kit tipo H no lo trae)'
        WHERE NOT EXISTS (
            SELECT 1 FROM public.receta_base WHERE modelo_id = v_mod_dolly AND material_id = v_mat_id
        );

        UPDATE public.receta_base
        SET cantidad = 1.0, escala = 'fija', paso = 'PASO 1', uso = 'ARMADO', seccion = NULL, condicion = NULL, notas = 'Solo en el manual (el kit tipo H no lo trae)'
        WHERE modelo_id = v_mod_dolly AND material_id = v_mat_id AND (paso IS NULL OR paso != 'PASO 1');
    END IF;
    -- [3] DISCO DE DESBASTE 9 (cant: 1.0, paso: PASO 1)
    SELECT id INTO v_mat_id FROM public.productos WHERE nombre = 'DISCO DE DESBASTE 9' AND organizacion_id = v_org_id LIMIT 1;
    IF v_mat_id IS NOT NULL THEN
        INSERT INTO public.receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
        SELECT v_mod_dolly, v_mat_id, 1.0, 'fija', 'PASO 1', 'ARMADO', NULL, NULL, 'Solo en el manual (el kit tipo H no lo trae)'
        WHERE NOT EXISTS (
            SELECT 1 FROM public.receta_base WHERE modelo_id = v_mod_dolly AND material_id = v_mat_id
        );

        UPDATE public.receta_base
        SET cantidad = 1.0, escala = 'fija', paso = 'PASO 1', uso = 'ARMADO', seccion = NULL, condicion = NULL, notas = 'Solo en el manual (el kit tipo H no lo trae)'
        WHERE modelo_id = v_mod_dolly AND material_id = v_mat_id AND (paso IS NULL OR paso != 'PASO 1');
    END IF;
    -- [4] CONSUMIBLE 65 (cant: 0.25, paso: PASO 1)
    SELECT id INTO v_mat_id FROM public.productos WHERE nombre = 'CONSUMIBLE 65' AND organizacion_id = v_org_id LIMIT 1;
    IF v_mat_id IS NOT NULL THEN
        INSERT INTO public.receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
        SELECT v_mod_dolly, v_mat_id, 0.25, 'fija', 'PASO 1', 'ARMADO', NULL, NULL, 'Solo en el manual (el kit tipo H no lo trae)'
        WHERE NOT EXISTS (
            SELECT 1 FROM public.receta_base WHERE modelo_id = v_mod_dolly AND material_id = v_mat_id
        );

        UPDATE public.receta_base
        SET cantidad = 0.25, escala = 'fija', paso = 'PASO 1', uso = 'ARMADO', seccion = NULL, condicion = NULL, notas = 'Solo en el manual (el kit tipo H no lo trae)'
        WHERE modelo_id = v_mod_dolly AND material_id = v_mat_id AND (paso IS NULL OR paso != 'PASO 1');
    END IF;
    -- [5] ROLLO DE MICROALAMBRE (cant: 1.0, paso: PASO 1)
    SELECT id INTO v_mat_id FROM public.productos WHERE nombre = 'ROLLO DE MICROALAMBRE' AND organizacion_id = v_org_id LIMIT 1;
    IF v_mat_id IS NOT NULL THEN
        INSERT INTO public.receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
        SELECT v_mod_dolly, v_mat_id, 1.0, 'fija', 'PASO 1', 'ARMADO', NULL, NULL, 'Solo en el manual (el kit tipo H no lo trae)'
        WHERE NOT EXISTS (
            SELECT 1 FROM public.receta_base WHERE modelo_id = v_mod_dolly AND material_id = v_mat_id
        );

        UPDATE public.receta_base
        SET cantidad = 1.0, escala = 'fija', paso = 'PASO 1', uso = 'ARMADO', seccion = NULL, condicion = NULL, notas = 'Solo en el manual (el kit tipo H no lo trae)'
        WHERE modelo_id = v_mod_dolly AND material_id = v_mat_id AND (paso IS NULL OR paso != 'PASO 1');
    END IF;
    -- [6] CO2 (cant: 1.0, paso: PASO 1)
    SELECT id INTO v_mat_id FROM public.productos WHERE nombre = 'CO2' AND organizacion_id = v_org_id LIMIT 1;
    IF v_mat_id IS NOT NULL THEN
        INSERT INTO public.receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
        SELECT v_mod_dolly, v_mat_id, 1.0, 'fija', 'PASO 1', 'ARMADO', NULL, NULL, 'Solo en el manual (el kit tipo H no lo trae)'
        WHERE NOT EXISTS (
            SELECT 1 FROM public.receta_base WHERE modelo_id = v_mod_dolly AND material_id = v_mat_id
        );

        UPDATE public.receta_base
        SET cantidad = 1.0, escala = 'fija', paso = 'PASO 1', uso = 'ARMADO', seccion = NULL, condicion = NULL, notas = 'Solo en el manual (el kit tipo H no lo trae)'
        WHERE modelo_id = v_mod_dolly AND material_id = v_mat_id AND (paso IS NULL OR paso != 'PASO 1');
    END IF;
    -- [7] OXIGENO (cant: 0.25, paso: PASO 1)
    SELECT id INTO v_mat_id FROM public.productos WHERE nombre = 'OXIGENO' AND organizacion_id = v_org_id LIMIT 1;
    IF v_mat_id IS NOT NULL THEN
        INSERT INTO public.receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
        SELECT v_mod_dolly, v_mat_id, 0.25, 'fija', 'PASO 1', 'ARMADO', NULL, NULL, 'Solo en el manual (el kit tipo H no lo trae)'
        WHERE NOT EXISTS (
            SELECT 1 FROM public.receta_base WHERE modelo_id = v_mod_dolly AND material_id = v_mat_id
        );

        UPDATE public.receta_base
        SET cantidad = 0.25, escala = 'fija', paso = 'PASO 1', uso = 'ARMADO', seccion = NULL, condicion = NULL, notas = 'Solo en el manual (el kit tipo H no lo trae)'
        WHERE modelo_id = v_mod_dolly AND material_id = v_mat_id AND (paso IS NULL OR paso != 'PASO 1');
    END IF;
    -- [8] TORNILLO 5/8 X 1 1/2 GRADO 5 (cant: 44.0, paso: PASO 1)
    SELECT id INTO v_mat_id FROM public.productos WHERE nombre = 'TORNILLO 5/8 X 1 1/2 GRADO 5' AND organizacion_id = v_org_id LIMIT 1;
    IF v_mat_id IS NOT NULL THEN
        INSERT INTO public.receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
        SELECT v_mod_dolly, v_mat_id, 44.0, 'fija', 'PASO 1', '2 PARES DE PATINES', NULL, NULL, 'Solo en el manual (el kit tipo H no lo trae)'
        WHERE NOT EXISTS (
            SELECT 1 FROM public.receta_base WHERE modelo_id = v_mod_dolly AND material_id = v_mat_id
        );

        UPDATE public.receta_base
        SET cantidad = 44.0, escala = 'fija', paso = 'PASO 1', uso = '2 PARES DE PATINES', seccion = NULL, condicion = NULL, notas = 'Solo en el manual (el kit tipo H no lo trae)'
        WHERE modelo_id = v_mod_dolly AND material_id = v_mat_id AND (paso IS NULL OR paso != 'PASO 1');
    END IF;
    -- [9] TUERCA ESTANDAR 5/8 GRADO 5 (cant: 44.0, paso: PASO 1)
    SELECT id INTO v_mat_id FROM public.productos WHERE nombre = 'TUERCA ESTANDAR 5/8 GRADO 5' AND organizacion_id = v_org_id LIMIT 1;
    IF v_mat_id IS NOT NULL THEN
        INSERT INTO public.receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
        SELECT v_mod_dolly, v_mat_id, 44.0, 'fija', 'PASO 1', '2 PARES DE PATINES', NULL, NULL, 'Solo en el manual (el kit tipo H no lo trae)'
        WHERE NOT EXISTS (
            SELECT 1 FROM public.receta_base WHERE modelo_id = v_mod_dolly AND material_id = v_mat_id
        );

        UPDATE public.receta_base
        SET cantidad = 44.0, escala = 'fija', paso = 'PASO 1', uso = '2 PARES DE PATINES', seccion = NULL, condicion = NULL, notas = 'Solo en el manual (el kit tipo H no lo trae)'
        WHERE modelo_id = v_mod_dolly AND material_id = v_mat_id AND (paso IS NULL OR paso != 'PASO 1');
    END IF;
    -- [10] LIJA #80 (cant: 2.0, paso: LIMPIEZA)
    SELECT id INTO v_mat_id FROM public.productos WHERE nombre = 'LIJA #80' AND organizacion_id = v_org_id LIMIT 1;
    IF v_mat_id IS NOT NULL THEN
        INSERT INTO public.receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
        SELECT v_mod_dolly, v_mat_id, 2.0, 'fija', 'LIMPIEZA', NULL, NULL, NULL, 'Solo en el manual (el kit tipo H no lo trae)'
        WHERE NOT EXISTS (
            SELECT 1 FROM public.receta_base WHERE modelo_id = v_mod_dolly AND material_id = v_mat_id
        );

        UPDATE public.receta_base
        SET cantidad = 2.0, escala = 'fija', paso = 'LIMPIEZA', uso = NULL, seccion = NULL, condicion = NULL, notas = 'Solo en el manual (el kit tipo H no lo trae)'
        WHERE modelo_id = v_mod_dolly AND material_id = v_mat_id AND (paso IS NULL OR paso != 'LIMPIEZA');
    END IF;
    -- [11] CARDA 5/8 DE 3" (cant: 1.0, paso: LIMPIEZA)
    SELECT id INTO v_mat_id FROM public.productos WHERE nombre = 'CARDA 5/8 DE 3"' AND organizacion_id = v_org_id LIMIT 1;
    IF v_mat_id IS NOT NULL THEN
        INSERT INTO public.receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
        SELECT v_mod_dolly, v_mat_id, 1.0, 'fija', 'LIMPIEZA', NULL, NULL, NULL, 'Solo en el manual (el kit tipo H no lo trae)'
        WHERE NOT EXISTS (
            SELECT 1 FROM public.receta_base WHERE modelo_id = v_mod_dolly AND material_id = v_mat_id
        );

        UPDATE public.receta_base
        SET cantidad = 1.0, escala = 'fija', paso = 'LIMPIEZA', uso = NULL, seccion = NULL, condicion = NULL, notas = 'Solo en el manual (el kit tipo H no lo trae)'
        WHERE modelo_id = v_mod_dolly AND material_id = v_mat_id AND (paso IS NULL OR paso != 'LIMPIEZA');
    END IF;
    -- [12] DISCO LAMINADO 4 1/2 (cant: 1.0, paso: LIMPIEZA)
    SELECT id INTO v_mat_id FROM public.productos WHERE nombre = 'DISCO LAMINADO 4 1/2' AND organizacion_id = v_org_id LIMIT 1;
    IF v_mat_id IS NOT NULL THEN
        INSERT INTO public.receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
        SELECT v_mod_dolly, v_mat_id, 1.0, 'fija', 'LIMPIEZA', NULL, NULL, NULL, 'Solo en el manual (el kit tipo H no lo trae)'
        WHERE NOT EXISTS (
            SELECT 1 FROM public.receta_base WHERE modelo_id = v_mod_dolly AND material_id = v_mat_id
        );

        UPDATE public.receta_base
        SET cantidad = 1.0, escala = 'fija', paso = 'LIMPIEZA', uso = NULL, seccion = NULL, condicion = NULL, notas = 'Solo en el manual (el kit tipo H no lo trae)'
        WHERE modelo_id = v_mod_dolly AND material_id = v_mat_id AND (paso IS NULL OR paso != 'LIMPIEZA');
    END IF;
    -- [13] FOSFATO (cant: 1.0, paso: LIMPIEZA)
    SELECT id INTO v_mat_id FROM public.productos WHERE nombre = 'FOSFATO' AND organizacion_id = v_org_id LIMIT 1;
    IF v_mat_id IS NOT NULL THEN
        INSERT INTO public.receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
        SELECT v_mod_dolly, v_mat_id, 1.0, 'fija', 'LIMPIEZA', NULL, NULL, NULL, 'Solo en el manual (el kit tipo H no lo trae)'
        WHERE NOT EXISTS (
            SELECT 1 FROM public.receta_base WHERE modelo_id = v_mod_dolly AND material_id = v_mat_id
        );

        UPDATE public.receta_base
        SET cantidad = 1.0, escala = 'fija', paso = 'LIMPIEZA', uso = NULL, seccion = NULL, condicion = NULL, notas = 'Solo en el manual (el kit tipo H no lo trae)'
        WHERE modelo_id = v_mod_dolly AND material_id = v_mat_id AND (paso IS NULL OR paso != 'LIMPIEZA');
    END IF;
    -- [14] REDUCCION 3/4 * 1/2 (cant: 1.0, paso: AIRE)
    SELECT id INTO v_mat_id FROM public.productos WHERE nombre = 'REDUCCION 3/4 * 1/2' AND organizacion_id = v_org_id LIMIT 1;
    IF v_mat_id IS NOT NULL THEN
        INSERT INTO public.receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
        SELECT v_mod_dolly, v_mat_id, 1.0, 'fija', 'AIRE', NULL, NULL, NULL, 'Manual y kit tipo H coinciden'
        WHERE NOT EXISTS (
            SELECT 1 FROM public.receta_base WHERE modelo_id = v_mod_dolly AND material_id = v_mat_id
        );

        UPDATE public.receta_base
        SET cantidad = 1.0, escala = 'fija', paso = 'AIRE', uso = NULL, seccion = NULL, condicion = NULL, notas = 'Manual y kit tipo H coinciden'
        WHERE modelo_id = v_mod_dolly AND material_id = v_mat_id AND (paso IS NULL OR paso != 'AIRE');
    END IF;
    -- [15] TE UNIO 3/8 (cant: 1.0, paso: AIRE)
    SELECT id INTO v_mat_id FROM public.productos WHERE nombre = 'TE UNIO 3/8' AND organizacion_id = v_org_id LIMIT 1;
    IF v_mat_id IS NOT NULL THEN
        INSERT INTO public.receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
        SELECT v_mod_dolly, v_mat_id, 1.0, 'fija', 'AIRE', NULL, NULL, NULL, 'Solo en el manual (el kit tipo H no lo trae)'
        WHERE NOT EXISTS (
            SELECT 1 FROM public.receta_base WHERE modelo_id = v_mod_dolly AND material_id = v_mat_id
        );

        UPDATE public.receta_base
        SET cantidad = 1.0, escala = 'fija', paso = 'AIRE', uso = NULL, seccion = NULL, condicion = NULL, notas = 'Solo en el manual (el kit tipo H no lo trae)'
        WHERE modelo_id = v_mod_dolly AND material_id = v_mat_id AND (paso IS NULL OR paso != 'AIRE');
    END IF;
    -- [16] ADAPTADOR 3/8 (cant: 8.0, paso: AIRE)
    SELECT id INTO v_mat_id FROM public.productos WHERE nombre = 'ADAPTADOR 3/8' AND organizacion_id = v_org_id LIMIT 1;
    IF v_mat_id IS NOT NULL THEN
        INSERT INTO public.receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
        SELECT v_mod_dolly, v_mat_id, 8.0, 'fija', 'AIRE', NULL, NULL, NULL, 'Manual y kit tipo H coinciden'
        WHERE NOT EXISTS (
            SELECT 1 FROM public.receta_base WHERE modelo_id = v_mod_dolly AND material_id = v_mat_id
        );

        UPDATE public.receta_base
        SET cantidad = 8.0, escala = 'fija', paso = 'AIRE', uso = NULL, seccion = NULL, condicion = NULL, notas = 'Manual y kit tipo H coinciden'
        WHERE modelo_id = v_mod_dolly AND material_id = v_mat_id AND (paso IS NULL OR paso != 'AIRE');
    END IF;
    -- [17] MACHO 3/8 (cant: 8.0, paso: AIRE)
    SELECT id INTO v_mat_id FROM public.productos WHERE nombre = 'MACHO 3/8' AND organizacion_id = v_org_id LIMIT 1;
    IF v_mat_id IS NOT NULL THEN
        INSERT INTO public.receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
        SELECT v_mod_dolly, v_mat_id, 8.0, 'fija', 'AIRE', NULL, NULL, NULL, 'Manual y kit tipo H coinciden'
        WHERE NOT EXISTS (
            SELECT 1 FROM public.receta_base WHERE modelo_id = v_mod_dolly AND material_id = v_mat_id
        );

        UPDATE public.receta_base
        SET cantidad = 8.0, escala = 'fija', paso = 'AIRE', uso = NULL, seccion = NULL, condicion = NULL, notas = 'Manual y kit tipo H coinciden'
        WHERE modelo_id = v_mod_dolly AND material_id = v_mat_id AND (paso IS NULL OR paso != 'AIRE');
    END IF;
    -- [18] HEMBRA 3/8 (cant: 8.0, paso: AIRE)
    SELECT id INTO v_mat_id FROM public.productos WHERE nombre = 'HEMBRA 3/8' AND organizacion_id = v_org_id LIMIT 1;
    IF v_mat_id IS NOT NULL THEN
        INSERT INTO public.receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
        SELECT v_mod_dolly, v_mat_id, 8.0, 'fija', 'AIRE', NULL, NULL, NULL, 'Manual y kit tipo H coinciden'
        WHERE NOT EXISTS (
            SELECT 1 FROM public.receta_base WHERE modelo_id = v_mod_dolly AND material_id = v_mat_id
        );

        UPDATE public.receta_base
        SET cantidad = 8.0, escala = 'fija', paso = 'AIRE', uso = NULL, seccion = NULL, condicion = NULL, notas = 'Manual y kit tipo H coinciden'
        WHERE modelo_id = v_mod_dolly AND material_id = v_mat_id AND (paso IS NULL OR paso != 'AIRE');
    END IF;
    -- [19] KIT DE ABS 2 EJES BENDIX (cant: 1.0, paso: AIRE)
    SELECT id INTO v_mat_id FROM public.productos WHERE nombre = 'KIT DE ABS 2 EJES BENDIX' AND organizacion_id = v_org_id LIMIT 1;
    IF v_mat_id IS NOT NULL THEN
        INSERT INTO public.receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
        SELECT v_mod_dolly, v_mat_id, 1.0, 'fija', 'AIRE', NULL, NULL, NULL, 'Manual y kit tipo H coinciden'
        WHERE NOT EXISTS (
            SELECT 1 FROM public.receta_base WHERE modelo_id = v_mod_dolly AND material_id = v_mat_id
        );

        UPDATE public.receta_base
        SET cantidad = 1.0, escala = 'fija', paso = 'AIRE', uso = NULL, seccion = NULL, condicion = NULL, notas = 'Manual y kit tipo H coinciden'
        WHERE modelo_id = v_mod_dolly AND material_id = v_mat_id AND (paso IS NULL OR paso != 'AIRE');
    END IF;
    -- [20] VALVULA PROTECTORA (cant: 1.0, paso: AIRE)
    SELECT id INTO v_mat_id FROM public.productos WHERE nombre = 'VALVULA PROTECTORA' AND organizacion_id = v_org_id LIMIT 1;
    IF v_mat_id IS NOT NULL THEN
        INSERT INTO public.receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
        SELECT v_mod_dolly, v_mat_id, 1.0, 'fija', 'AIRE', NULL, NULL, NULL, 'Manual y kit tipo H coinciden'
        WHERE NOT EXISTS (
            SELECT 1 FROM public.receta_base WHERE modelo_id = v_mod_dolly AND material_id = v_mat_id
        );

        UPDATE public.receta_base
        SET cantidad = 1.0, escala = 'fija', paso = 'AIRE', uso = NULL, seccion = NULL, condicion = NULL, notas = 'Manual y kit tipo H coinciden'
        WHERE modelo_id = v_mod_dolly AND material_id = v_mat_id AND (paso IS NULL OR paso != 'AIRE');
    END IF;
    -- [21] TUERCA DE SEGURIDAD 5/16 (cant: 2.0, paso: AIRE)
    SELECT id INTO v_mat_id FROM public.productos WHERE nombre = 'TUERCA DE SEGURIDAD 5/16' AND organizacion_id = v_org_id LIMIT 1;
    IF v_mat_id IS NOT NULL THEN
        INSERT INTO public.receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
        SELECT v_mod_dolly, v_mat_id, 2.0, 'fija', 'AIRE', 'KIT DE TORNILLOS DE ABS', NULL, NULL, 'Manual y kit tipo H coinciden'
        WHERE NOT EXISTS (
            SELECT 1 FROM public.receta_base WHERE modelo_id = v_mod_dolly AND material_id = v_mat_id
        );

        UPDATE public.receta_base
        SET cantidad = 2.0, escala = 'fija', paso = 'AIRE', uso = 'KIT DE TORNILLOS DE ABS', seccion = NULL, condicion = NULL, notas = 'Manual y kit tipo H coinciden'
        WHERE modelo_id = v_mod_dolly AND material_id = v_mat_id AND (paso IS NULL OR paso != 'AIRE');
    END IF;
    -- [22] MANITA ROJA S/LLAVE (cant: 2.0, paso: AIRE)
    SELECT id INTO v_mat_id FROM public.productos WHERE nombre = 'MANITA ROJA S/LLAVE' AND organizacion_id = v_org_id LIMIT 1;
    IF v_mat_id IS NOT NULL THEN
        INSERT INTO public.receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
        SELECT v_mod_dolly, v_mat_id, 2.0, 'fija', 'AIRE', NULL, NULL, NULL, 'Manual y kit tipo H coinciden'
        WHERE NOT EXISTS (
            SELECT 1 FROM public.receta_base WHERE modelo_id = v_mod_dolly AND material_id = v_mat_id
        );

        UPDATE public.receta_base
        SET cantidad = 2.0, escala = 'fija', paso = 'AIRE', uso = NULL, seccion = NULL, condicion = NULL, notas = 'Manual y kit tipo H coinciden'
        WHERE modelo_id = v_mod_dolly AND material_id = v_mat_id AND (paso IS NULL OR paso != 'AIRE');
    END IF;
    -- [23] MANGUERA ROJA 3/8 (cant: 20.0, paso: AIRE)
    SELECT id INTO v_mat_id FROM public.productos WHERE nombre = 'MANGUERA ROJA 3/8' AND organizacion_id = v_org_id LIMIT 1;
    IF v_mat_id IS NOT NULL THEN
        INSERT INTO public.receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
        SELECT v_mod_dolly, v_mat_id, 20.0, 'fija', 'AIRE', NULL, NULL, NULL, 'Solo en el manual (el kit tipo H no lo trae)'
        WHERE NOT EXISTS (
            SELECT 1 FROM public.receta_base WHERE modelo_id = v_mod_dolly AND material_id = v_mat_id
        );

        UPDATE public.receta_base
        SET cantidad = 20.0, escala = 'fija', paso = 'AIRE', uso = NULL, seccion = NULL, condicion = NULL, notas = 'Solo en el manual (el kit tipo H no lo trae)'
        WHERE modelo_id = v_mod_dolly AND material_id = v_mat_id AND (paso IS NULL OR paso != 'AIRE');
    END IF;
    -- [24] MANGUERA CHAMBER 3/8 (cant: 8.0, paso: AIRE)
    SELECT id INTO v_mat_id FROM public.productos WHERE nombre = 'MANGUERA CHAMBER 3/8' AND organizacion_id = v_org_id LIMIT 1;
    IF v_mat_id IS NOT NULL THEN
        INSERT INTO public.receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
        SELECT v_mod_dolly, v_mat_id, 8.0, 'fija', 'AIRE', NULL, NULL, NULL, 'Manual y kit tipo H coinciden'
        WHERE NOT EXISTS (
            SELECT 1 FROM public.receta_base WHERE modelo_id = v_mod_dolly AND material_id = v_mat_id
        );

        UPDATE public.receta_base
        SET cantidad = 8.0, escala = 'fija', paso = 'AIRE', uso = NULL, seccion = NULL, condicion = NULL, notas = 'Manual y kit tipo H coinciden'
        WHERE modelo_id = v_mod_dolly AND material_id = v_mat_id AND (paso IS NULL OR paso != 'AIRE');
    END IF;
    -- [25] JUEGO DE MANGUERA ESPIRAL AZUL Y ROJA (cant: 2.0, paso: AIRE)
    SELECT id INTO v_mat_id FROM public.productos WHERE nombre = 'JUEGO DE MANGUERA ESPIRAL AZUL Y ROJA' AND organizacion_id = v_org_id LIMIT 1;
    IF v_mat_id IS NOT NULL THEN
        INSERT INTO public.receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
        SELECT v_mod_dolly, v_mat_id, 2.0, 'fija', 'AIRE', NULL, NULL, NULL, 'Manual y kit tipo H coinciden'
        WHERE NOT EXISTS (
            SELECT 1 FROM public.receta_base WHERE modelo_id = v_mod_dolly AND material_id = v_mat_id
        );

        UPDATE public.receta_base
        SET cantidad = 2.0, escala = 'fija', paso = 'AIRE', uso = NULL, seccion = NULL, condicion = NULL, notas = 'Manual y kit tipo H coinciden'
        WHERE modelo_id = v_mod_dolly AND material_id = v_mat_id AND (paso IS NULL OR paso != 'AIRE');
    END IF;
    -- [26] HEMBRA 7 POLOS (cant: 1.0, paso: LUZ)
    SELECT id INTO v_mat_id FROM public.productos WHERE nombre = 'HEMBRA 7 POLOS' AND organizacion_id = v_org_id LIMIT 1;
    IF v_mat_id IS NOT NULL THEN
        INSERT INTO public.receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
        SELECT v_mod_dolly, v_mat_id, 1.0, 'fija', 'LUZ', NULL, NULL, NULL, 'Manual y kit tipo H coinciden'
        WHERE NOT EXISTS (
            SELECT 1 FROM public.receta_base WHERE modelo_id = v_mod_dolly AND material_id = v_mat_id
        );

        UPDATE public.receta_base
        SET cantidad = 1.0, escala = 'fija', paso = 'LUZ', uso = NULL, seccion = NULL, condicion = NULL, notas = 'Manual y kit tipo H coinciden'
        WHERE modelo_id = v_mod_dolly AND material_id = v_mat_id AND (paso IS NULL OR paso != 'LUZ');
    END IF;
    -- [27] MACHO SOLO 7 POLOS (cant: 1.0, paso: LUZ)
    SELECT id INTO v_mat_id FROM public.productos WHERE nombre = 'MACHO SOLO 7 POLOS' AND organizacion_id = v_org_id LIMIT 1;
    IF v_mat_id IS NOT NULL THEN
        INSERT INTO public.receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
        SELECT v_mod_dolly, v_mat_id, 1.0, 'fija', 'LUZ', NULL, NULL, NULL, 'Manual y kit tipo H coinciden'
        WHERE NOT EXISTS (
            SELECT 1 FROM public.receta_base WHERE modelo_id = v_mod_dolly AND material_id = v_mat_id
        );

        UPDATE public.receta_base
        SET cantidad = 1.0, escala = 'fija', paso = 'LUZ', uso = NULL, seccion = NULL, condicion = NULL, notas = 'Manual y kit tipo H coinciden'
        WHERE modelo_id = v_mod_dolly AND material_id = v_mat_id AND (paso IS NULL OR paso != 'LUZ');
    END IF;
    -- [28] TORNILLO 1/4 X 1 GALVANIZADO (cant: 4.0, paso: LUZ)
    SELECT id INTO v_mat_id FROM public.productos WHERE nombre = 'TORNILLO 1/4 X 1 GALVANIZADO' AND organizacion_id = v_org_id LIMIT 1;
    IF v_mat_id IS NOT NULL THEN
        INSERT INTO public.receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
        SELECT v_mod_dolly, v_mat_id, 4.0, 'fija', 'LUZ', 'HEMBRAS Y PLAFON ABS', NULL, NULL, 'Solo en el manual (el kit tipo H no lo trae)'
        WHERE NOT EXISTS (
            SELECT 1 FROM public.receta_base WHERE modelo_id = v_mod_dolly AND material_id = v_mat_id
        );

        UPDATE public.receta_base
        SET cantidad = 4.0, escala = 'fija', paso = 'LUZ', uso = 'HEMBRAS Y PLAFON ABS', seccion = NULL, condicion = NULL, notas = 'Solo en el manual (el kit tipo H no lo trae)'
        WHERE modelo_id = v_mod_dolly AND material_id = v_mat_id AND (paso IS NULL OR paso != 'LUZ');
    END IF;
    -- [29] TUERCA ESTANDAR 1/4 (cant: 4.0, paso: LUZ)
    SELECT id INTO v_mat_id FROM public.productos WHERE nombre = 'TUERCA ESTANDAR 1/4' AND organizacion_id = v_org_id LIMIT 1;
    IF v_mat_id IS NOT NULL THEN
        INSERT INTO public.receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
        SELECT v_mod_dolly, v_mat_id, 4.0, 'fija', 'LUZ', 'HEMBRAS Y PLAFON ABS', NULL, NULL, 'Solo en el manual (el kit tipo H no lo trae)'
        WHERE NOT EXISTS (
            SELECT 1 FROM public.receta_base WHERE modelo_id = v_mod_dolly AND material_id = v_mat_id
        );

        UPDATE public.receta_base
        SET cantidad = 4.0, escala = 'fija', paso = 'LUZ', uso = 'HEMBRAS Y PLAFON ABS', seccion = NULL, condicion = NULL, notas = 'Solo en el manual (el kit tipo H no lo trae)'
        WHERE modelo_id = v_mod_dolly AND material_id = v_mat_id AND (paso IS NULL OR paso != 'LUZ');
    END IF;
    -- [30] CABLE 7 POLOS (cant: 2.5, paso: LUZ)
    SELECT id INTO v_mat_id FROM public.productos WHERE nombre = 'CABLE 7 POLOS' AND organizacion_id = v_org_id LIMIT 1;
    IF v_mat_id IS NOT NULL THEN
        INSERT INTO public.receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
        SELECT v_mod_dolly, v_mat_id, 2.5, 'fija', 'LUZ', NULL, NULL, NULL, 'Material por metro (unidad M).'
        WHERE NOT EXISTS (
            SELECT 1 FROM public.receta_base WHERE modelo_id = v_mod_dolly AND material_id = v_mat_id
        );

        UPDATE public.receta_base
        SET cantidad = 2.5, escala = 'fija', paso = 'LUZ', uso = NULL, seccion = NULL, condicion = NULL, notas = 'Material por metro (unidad M).'
        WHERE modelo_id = v_mod_dolly AND material_id = v_mat_id AND (paso IS NULL OR paso != 'LUZ');
    END IF;
    -- [31] CABLE ROJO CAL,12 (cant: 6.6, paso: LUZ)
    SELECT id INTO v_mat_id FROM public.productos WHERE nombre = 'CABLE ROJO CAL,12' AND organizacion_id = v_org_id LIMIT 1;
    IF v_mat_id IS NOT NULL THEN
        INSERT INTO public.receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
        SELECT v_mod_dolly, v_mat_id, 6.6, 'fija', 'LUZ', NULL, NULL, NULL, 'Solo en el manual (el kit tipo H no lo trae)'
        WHERE NOT EXISTS (
            SELECT 1 FROM public.receta_base WHERE modelo_id = v_mod_dolly AND material_id = v_mat_id
        );

        UPDATE public.receta_base
        SET cantidad = 6.6, escala = 'fija', paso = 'LUZ', uso = NULL, seccion = NULL, condicion = NULL, notas = 'Solo en el manual (el kit tipo H no lo trae)'
        WHERE modelo_id = v_mod_dolly AND material_id = v_mat_id AND (paso IS NULL OR paso != 'LUZ');
    END IF;
    -- [32] CABLE AMARILLO CAL,12 (cant: 5.0, paso: LUZ)
    SELECT id INTO v_mat_id FROM public.productos WHERE nombre = 'CABLE AMARILLO CAL,12' AND organizacion_id = v_org_id LIMIT 1;
    IF v_mat_id IS NOT NULL THEN
        INSERT INTO public.receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
        SELECT v_mod_dolly, v_mat_id, 5.0, 'fija', 'LUZ', NULL, NULL, NULL, 'Solo en el manual (el kit tipo H no lo trae)'
        WHERE NOT EXISTS (
            SELECT 1 FROM public.receta_base WHERE modelo_id = v_mod_dolly AND material_id = v_mat_id
        );

        UPDATE public.receta_base
        SET cantidad = 5.0, escala = 'fija', paso = 'LUZ', uso = NULL, seccion = NULL, condicion = NULL, notas = 'Solo en el manual (el kit tipo H no lo trae)'
        WHERE modelo_id = v_mod_dolly AND material_id = v_mat_id AND (paso IS NULL OR paso != 'LUZ');
    END IF;
    -- [33] CABLE VERDE CAL,12 (cant: 4.2, paso: LUZ)
    SELECT id INTO v_mat_id FROM public.productos WHERE nombre = 'CABLE VERDE CAL,12' AND organizacion_id = v_org_id LIMIT 1;
    IF v_mat_id IS NOT NULL THEN
        INSERT INTO public.receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
        SELECT v_mod_dolly, v_mat_id, 4.2, 'fija', 'LUZ', NULL, NULL, NULL, 'Solo en el manual (el kit tipo H no lo trae)'
        WHERE NOT EXISTS (
            SELECT 1 FROM public.receta_base WHERE modelo_id = v_mod_dolly AND material_id = v_mat_id
        );

        UPDATE public.receta_base
        SET cantidad = 4.2, escala = 'fija', paso = 'LUZ', uso = NULL, seccion = NULL, condicion = NULL, notas = 'Solo en el manual (el kit tipo H no lo trae)'
        WHERE modelo_id = v_mod_dolly AND material_id = v_mat_id AND (paso IS NULL OR paso != 'LUZ');
    END IF;
    -- [34] CABLE CAFE CAL,12 (cant: 6.6, paso: LUZ)
    SELECT id INTO v_mat_id FROM public.productos WHERE nombre = 'CABLE CAFE CAL,12' AND organizacion_id = v_org_id LIMIT 1;
    IF v_mat_id IS NOT NULL THEN
        INSERT INTO public.receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
        SELECT v_mod_dolly, v_mat_id, 6.6, 'fija', 'LUZ', NULL, NULL, NULL, 'Solo en el manual (el kit tipo H no lo trae)'
        WHERE NOT EXISTS (
            SELECT 1 FROM public.receta_base WHERE modelo_id = v_mod_dolly AND material_id = v_mat_id
        );

        UPDATE public.receta_base
        SET cantidad = 6.6, escala = 'fija', paso = 'LUZ', uso = NULL, seccion = NULL, condicion = NULL, notas = 'Solo en el manual (el kit tipo H no lo trae)'
        WHERE modelo_id = v_mod_dolly AND material_id = v_mat_id AND (paso IS NULL OR paso != 'LUZ');
    END IF;
    -- [35] CORRUGADO 3/8 (cant: 7.5, paso: LUZ)
    SELECT id INTO v_mat_id FROM public.productos WHERE nombre = 'CORRUGADO 3/8' AND organizacion_id = v_org_id LIMIT 1;
    IF v_mat_id IS NOT NULL THEN
        INSERT INTO public.receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
        SELECT v_mod_dolly, v_mat_id, 7.5, 'fija', 'LUZ', NULL, NULL, NULL, 'Solo en el manual (el kit tipo H no lo trae)'
        WHERE NOT EXISTS (
            SELECT 1 FROM public.receta_base WHERE modelo_id = v_mod_dolly AND material_id = v_mat_id
        );

        UPDATE public.receta_base
        SET cantidad = 7.5, escala = 'fija', paso = 'LUZ', uso = NULL, seccion = NULL, condicion = NULL, notas = 'Solo en el manual (el kit tipo H no lo trae)'
        WHERE modelo_id = v_mod_dolly AND material_id = v_mat_id AND (paso IS NULL OR paso != 'LUZ');
    END IF;
    -- [36] TERMINAL 3/16 (cant: 6.0, paso: LUZ)
    SELECT id INTO v_mat_id FROM public.productos WHERE nombre = 'TERMINAL 3/16' AND organizacion_id = v_org_id LIMIT 1;
    IF v_mat_id IS NOT NULL THEN
        INSERT INTO public.receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
        SELECT v_mod_dolly, v_mat_id, 6.0, 'fija', 'LUZ', 'PLAFONES PRINCIPALES', NULL, NULL, 'Manual y kit tipo H coinciden'
        WHERE NOT EXISTS (
            SELECT 1 FROM public.receta_base WHERE modelo_id = v_mod_dolly AND material_id = v_mat_id
        );

        UPDATE public.receta_base
        SET cantidad = 6.0, escala = 'fija', paso = 'LUZ', uso = 'PLAFONES PRINCIPALES', seccion = NULL, condicion = NULL, notas = 'Manual y kit tipo H coinciden'
        WHERE modelo_id = v_mod_dolly AND material_id = v_mat_id AND (paso IS NULL OR paso != 'LUZ');
    END IF;
    -- [37] CINTA DE AISLAR (cant: 1.0, paso: LUZ)
    SELECT id INTO v_mat_id FROM public.productos WHERE nombre = 'CINTA DE AISLAR' AND organizacion_id = v_org_id LIMIT 1;
    IF v_mat_id IS NOT NULL THEN
        INSERT INTO public.receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
        SELECT v_mod_dolly, v_mat_id, 1.0, 'fija', 'LUZ', NULL, NULL, NULL, 'Manual y kit tipo H coinciden'
        WHERE NOT EXISTS (
            SELECT 1 FROM public.receta_base WHERE modelo_id = v_mod_dolly AND material_id = v_mat_id
        );

        UPDATE public.receta_base
        SET cantidad = 1.0, escala = 'fija', paso = 'LUZ', uso = NULL, seccion = NULL, condicion = NULL, notas = 'Manual y kit tipo H coinciden'
        WHERE modelo_id = v_mod_dolly AND material_id = v_mat_id AND (paso IS NULL OR paso != 'LUZ');
    END IF;
    -- [38] PLAFON ROJO 4 (cant: 6.0, paso: LUZ)
    SELECT id INTO v_mat_id FROM public.productos WHERE nombre = 'PLAFON ROJO 4' AND organizacion_id = v_org_id LIMIT 1;
    IF v_mat_id IS NOT NULL THEN
        INSERT INTO public.receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
        SELECT v_mod_dolly, v_mat_id, 6.0, 'fija', 'LUZ', NULL, NULL, NULL, 'Manual y kit tipo H coinciden'
        WHERE NOT EXISTS (
            SELECT 1 FROM public.receta_base WHERE modelo_id = v_mod_dolly AND material_id = v_mat_id
        );

        UPDATE public.receta_base
        SET cantidad = 6.0, escala = 'fija', paso = 'LUZ', uso = NULL, seccion = NULL, condicion = NULL, notas = 'Manual y kit tipo H coinciden'
        WHERE modelo_id = v_mod_dolly AND material_id = v_mat_id AND (paso IS NULL OR paso != 'LUZ');
    END IF;
    -- [39] LODERA BLANCA O NEGRA (cant: 2.0, paso: TERMINADO)
    SELECT id INTO v_mat_id FROM public.productos WHERE nombre = 'LODERA BLANCA O NEGRA' AND organizacion_id = v_org_id LIMIT 1;
    IF v_mat_id IS NOT NULL THEN
        INSERT INTO public.receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
        SELECT v_mod_dolly, v_mat_id, 2.0, 'fija', 'TERMINADO', NULL, NULL, NULL, 'El sistema ya cobra ''Lodera blanca'' ×2 a $303.99 (otros).'
        WHERE NOT EXISTS (
            SELECT 1 FROM public.receta_base WHERE modelo_id = v_mod_dolly AND material_id = v_mat_id
        );

        UPDATE public.receta_base
        SET cantidad = 2.0, escala = 'fija', paso = 'TERMINADO', uso = NULL, seccion = NULL, condicion = NULL, notas = 'El sistema ya cobra ''Lodera blanca'' ×2 a $303.99 (otros).'
        WHERE modelo_id = v_mod_dolly AND material_id = v_mat_id AND (paso IS NULL OR paso != 'TERMINADO');
    END IF;
    -- [40] FLEJE (cant: 2.0, paso: TERMINADO)
    SELECT id INTO v_mat_id FROM public.productos WHERE nombre = 'FLEJE' AND organizacion_id = v_org_id LIMIT 1;
    IF v_mat_id IS NOT NULL THEN
        INSERT INTO public.receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
        SELECT v_mod_dolly, v_mat_id, 2.0, 'fija', 'TERMINADO', NULL, NULL, NULL, 'El sistema ya cobra ''Flejes'' ×2 a $232 (otros).'
        WHERE NOT EXISTS (
            SELECT 1 FROM public.receta_base WHERE modelo_id = v_mod_dolly AND material_id = v_mat_id
        );

        UPDATE public.receta_base
        SET cantidad = 2.0, escala = 'fija', paso = 'TERMINADO', uso = NULL, seccion = NULL, condicion = NULL, notas = 'El sistema ya cobra ''Flejes'' ×2 a $232 (otros).'
        WHERE modelo_id = v_mod_dolly AND material_id = v_mat_id AND (paso IS NULL OR paso != 'TERMINADO');
    END IF;
    -- [41] KIT DE ROTULACION (cant: 1.0, paso: TERMINADO)
    SELECT id INTO v_mat_id FROM public.productos WHERE nombre = 'KIT DE ROTULACION' AND organizacion_id = v_org_id LIMIT 1;
    IF v_mat_id IS NOT NULL THEN
        INSERT INTO public.receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
        SELECT v_mod_dolly, v_mat_id, 1.0, 'fija', 'TERMINADO', NULL, NULL, NULL, 'El sistema ya cobra ''Kit de rotulación'' a $400 (otros).'
        WHERE NOT EXISTS (
            SELECT 1 FROM public.receta_base WHERE modelo_id = v_mod_dolly AND material_id = v_mat_id
        );

        UPDATE public.receta_base
        SET cantidad = 1.0, escala = 'fija', paso = 'TERMINADO', uso = NULL, seccion = NULL, condicion = NULL, notas = 'El sistema ya cobra ''Kit de rotulación'' a $400 (otros).'
        WHERE modelo_id = v_mod_dolly AND material_id = v_mat_id AND (paso IS NULL OR paso != 'TERMINADO');
    END IF;
    -- [42] CINTA REFLEJANTE (cant: 1.0, paso: TERMINADO)
    SELECT id INTO v_mat_id FROM public.productos WHERE nombre = 'CINTA REFLEJANTE' AND organizacion_id = v_org_id LIMIT 1;
    IF v_mat_id IS NOT NULL THEN
        INSERT INTO public.receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
        SELECT v_mod_dolly, v_mat_id, 1.0, 'fija', 'TERMINADO', NULL, NULL, NULL, 'El sistema ya cobra ''Cinta reflejante'' a $200 (otros).'
        WHERE NOT EXISTS (
            SELECT 1 FROM public.receta_base WHERE modelo_id = v_mod_dolly AND material_id = v_mat_id
        );

        UPDATE public.receta_base
        SET cantidad = 1.0, escala = 'fija', paso = 'TERMINADO', uso = NULL, seccion = NULL, condicion = NULL, notas = 'El sistema ya cobra ''Cinta reflejante'' a $200 (otros).'
        WHERE modelo_id = v_mod_dolly AND material_id = v_mat_id AND (paso IS NULL OR paso != 'TERMINADO');
    END IF;
    -- [43] PLACA DE NIP (cant: 1.0, paso: TERMINADO)
    SELECT id INTO v_mat_id FROM public.productos WHERE nombre = 'PLACA DE NIP' AND organizacion_id = v_org_id LIMIT 1;
    IF v_mat_id IS NOT NULL THEN
        INSERT INTO public.receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
        SELECT v_mod_dolly, v_mat_id, 1.0, 'fija', 'TERMINADO', NULL, NULL, NULL, 'Sin concepto de cobro en el dolly.'
        WHERE NOT EXISTS (
            SELECT 1 FROM public.receta_base WHERE modelo_id = v_mod_dolly AND material_id = v_mat_id
        );

        UPDATE public.receta_base
        SET cantidad = 1.0, escala = 'fija', paso = 'TERMINADO', uso = NULL, seccion = NULL, condicion = NULL, notas = 'Sin concepto de cobro en el dolly.'
        WHERE modelo_id = v_mod_dolly AND material_id = v_mat_id AND (paso IS NULL OR paso != 'TERMINADO');
    END IF;
    -- [44] TORNILLO 1/2 X 1 3/4 (cant: 8.0, paso: TERMINADO)
    SELECT id INTO v_mat_id FROM public.productos WHERE nombre = 'TORNILLO 1/2 X 1 3/4' AND organizacion_id = v_org_id LIMIT 1;
    IF v_mat_id IS NOT NULL THEN
        INSERT INTO public.receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
        SELECT v_mod_dolly, v_mat_id, 8.0, 'fija', 'TERMINADO', 'PORTA LODERA', NULL, NULL, 'Solo en el manual (el kit tipo H no lo trae)'
        WHERE NOT EXISTS (
            SELECT 1 FROM public.receta_base WHERE modelo_id = v_mod_dolly AND material_id = v_mat_id
        );

        UPDATE public.receta_base
        SET cantidad = 8.0, escala = 'fija', paso = 'TERMINADO', uso = 'PORTA LODERA', seccion = NULL, condicion = NULL, notas = 'Solo en el manual (el kit tipo H no lo trae)'
        WHERE modelo_id = v_mod_dolly AND material_id = v_mat_id AND (paso IS NULL OR paso != 'TERMINADO');
    END IF;
    -- [45] TUERCA DE SEGURIDAD 1/2 (cant: 8.0, paso: TERMINADO)
    SELECT id INTO v_mat_id FROM public.productos WHERE nombre = 'TUERCA DE SEGURIDAD 1/2' AND organizacion_id = v_org_id LIMIT 1;
    IF v_mat_id IS NOT NULL THEN
        INSERT INTO public.receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
        SELECT v_mod_dolly, v_mat_id, 8.0, 'fija', 'TERMINADO', 'PORTA LODERA', NULL, NULL, 'Solo en el manual (el kit tipo H no lo trae)'
        WHERE NOT EXISTS (
            SELECT 1 FROM public.receta_base WHERE modelo_id = v_mod_dolly AND material_id = v_mat_id
        );

        UPDATE public.receta_base
        SET cantidad = 8.0, escala = 'fija', paso = 'TERMINADO', uso = 'PORTA LODERA', seccion = NULL, condicion = NULL, notas = 'Solo en el manual (el kit tipo H no lo trae)'
        WHERE modelo_id = v_mod_dolly AND material_id = v_mat_id AND (paso IS NULL OR paso != 'TERMINADO');
    END IF;
    -- [46] TORNILLO 3/4 X 6 GRADO 8 (cant: 2.0, paso: EXTRAS)
    SELECT id INTO v_mat_id FROM public.productos WHERE nombre = 'TORNILLO 3/4 X 6 GRADO 8' AND organizacion_id = v_org_id LIMIT 1;
    IF v_mat_id IS NOT NULL THEN
        INSERT INTO public.receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
        SELECT v_mod_dolly, v_mat_id, 2.0, 'fija', 'EXTRAS', 'AMORTIGUADOR DE ALTA', NULL, '{"todas":[{"op":"in","campo":"suspension","valor":["alta_hendrickson","alta_fleet_master","hj_alta"]}]}'::jsonb, 'Condición: suspension in [alta_hendrickson, alta_fleet_master, hj_alta] (igual que plataformas)'
        WHERE NOT EXISTS (
            SELECT 1 FROM public.receta_base WHERE modelo_id = v_mod_dolly AND material_id = v_mat_id
        );

        UPDATE public.receta_base
        SET cantidad = 2.0, escala = 'fija', paso = 'EXTRAS', uso = 'AMORTIGUADOR DE ALTA', seccion = NULL, condicion = '{"todas":[{"op":"in","campo":"suspension","valor":["alta_hendrickson","alta_fleet_master","hj_alta"]}]}'::jsonb, notas = 'Condición: suspension in [alta_hendrickson, alta_fleet_master, hj_alta] (igual que plataformas)'
        WHERE modelo_id = v_mod_dolly AND material_id = v_mat_id AND (paso IS NULL OR paso != 'EXTRAS');
    END IF;
    -- [47] TUERCA DE SEGURIDAD 3/4 (cant: 4.0, paso: EXTRAS)
    SELECT id INTO v_mat_id FROM public.productos WHERE nombre = 'TUERCA DE SEGURIDAD 3/4' AND organizacion_id = v_org_id LIMIT 1;
    IF v_mat_id IS NOT NULL THEN
        INSERT INTO public.receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
        SELECT v_mod_dolly, v_mat_id, 4.0, 'fija', 'EXTRAS', 'AMORTIGUADOR DE ALTA', NULL, '{"todas":[{"op":"in","campo":"suspension","valor":["alta_hendrickson","alta_fleet_master","hj_alta"]}]}'::jsonb, 'Condición: suspension in [alta_hendrickson, alta_fleet_master, hj_alta] (igual que plataformas)'
        WHERE NOT EXISTS (
            SELECT 1 FROM public.receta_base WHERE modelo_id = v_mod_dolly AND material_id = v_mat_id
        );

        UPDATE public.receta_base
        SET cantidad = 4.0, escala = 'fija', paso = 'EXTRAS', uso = 'AMORTIGUADOR DE ALTA', seccion = NULL, condicion = '{"todas":[{"op":"in","campo":"suspension","valor":["alta_hendrickson","alta_fleet_master","hj_alta"]}]}'::jsonb, notas = 'Condición: suspension in [alta_hendrickson, alta_fleet_master, hj_alta] (igual que plataformas)'
        WHERE modelo_id = v_mod_dolly AND material_id = v_mat_id AND (paso IS NULL OR paso != 'EXTRAS');
    END IF;
    -- [48] TORNILLO 3/4 X 3 1/2 GRADO 8 (cant: 2.0, paso: EXTRAS)
    SELECT id INTO v_mat_id FROM public.productos WHERE nombre = 'TORNILLO 3/4 X 3 1/2 GRADO 8' AND organizacion_id = v_org_id LIMIT 1;
    IF v_mat_id IS NOT NULL THEN
        INSERT INTO public.receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
        SELECT v_mod_dolly, v_mat_id, 2.0, 'fija', 'EXTRAS', 'AMORTIGUADOR DE ALTA', NULL, '{"todas":[{"op":"in","campo":"suspension","valor":["alta_hendrickson","alta_fleet_master","hj_alta"]}]}'::jsonb, 'Condición: suspension in [alta_hendrickson, alta_fleet_master, hj_alta] (igual que plataformas)'
        WHERE NOT EXISTS (
            SELECT 1 FROM public.receta_base WHERE modelo_id = v_mod_dolly AND material_id = v_mat_id
        );

        UPDATE public.receta_base
        SET cantidad = 2.0, escala = 'fija', paso = 'EXTRAS', uso = 'AMORTIGUADOR DE ALTA', seccion = NULL, condicion = '{"todas":[{"op":"in","campo":"suspension","valor":["alta_hendrickson","alta_fleet_master","hj_alta"]}]}'::jsonb, notas = 'Condición: suspension in [alta_hendrickson, alta_fleet_master, hj_alta] (igual que plataformas)'
        WHERE modelo_id = v_mod_dolly AND material_id = v_mat_id AND (paso IS NULL OR paso != 'EXTRAS');
    END IF;
    -- [49] RONDANA AUTOMOTRIZ 3/4 (cant: 4.0, paso: EXTRAS)
    SELECT id INTO v_mat_id FROM public.productos WHERE nombre = 'RONDANA AUTOMOTRIZ 3/4' AND organizacion_id = v_org_id LIMIT 1;
    IF v_mat_id IS NOT NULL THEN
        INSERT INTO public.receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
        SELECT v_mod_dolly, v_mat_id, 4.0, 'fija', 'EXTRAS', 'AMORTIGUADOR DE ALTA', NULL, '{"todas":[{"op":"in","campo":"suspension","valor":["alta_hendrickson","alta_fleet_master","hj_alta"]}]}'::jsonb, 'Condición: suspension in [alta_hendrickson, alta_fleet_master, hj_alta] (igual que plataformas)'
        WHERE NOT EXISTS (
            SELECT 1 FROM public.receta_base WHERE modelo_id = v_mod_dolly AND material_id = v_mat_id
        );

        UPDATE public.receta_base
        SET cantidad = 4.0, escala = 'fija', paso = 'EXTRAS', uso = 'AMORTIGUADOR DE ALTA', seccion = NULL, condicion = '{"todas":[{"op":"in","campo":"suspension","valor":["alta_hendrickson","alta_fleet_master","hj_alta"]}]}'::jsonb, notas = 'Condición: suspension in [alta_hendrickson, alta_fleet_master, hj_alta] (igual que plataformas)'
        WHERE modelo_id = v_mod_dolly AND material_id = v_mat_id AND (paso IS NULL OR paso != 'EXTRAS');
    END IF;
    -- [50] OREJA (cant: 2.0, paso: PASO 1)
    SELECT id INTO v_mat_id FROM public.productos WHERE nombre = 'OREJA' AND organizacion_id = v_org_id LIMIT 1;
    IF v_mat_id IS NOT NULL THEN
        INSERT INTO public.receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
        SELECT v_mod_dolly, v_mat_id, 2.0, 'fija', 'PASO 1', 'CUADRO', NULL, NULL, 'Pieza de maquila/compra sin precio de catálogo. El sistema ya cobra ''Oreja'' ×2 a $843 en conceptos (otros): el despiece solo agrega el renglón de almacén.'
        WHERE NOT EXISTS (
            SELECT 1 FROM public.receta_base WHERE modelo_id = v_mod_dolly AND material_id = v_mat_id
        );

        UPDATE public.receta_base
        SET cantidad = 2.0, escala = 'fija', paso = 'PASO 1', uso = 'CUADRO', seccion = NULL, condicion = NULL, notas = 'Pieza de maquila/compra sin precio de catálogo. El sistema ya cobra ''Oreja'' ×2 a $843 en conceptos (otros): el despiece solo agrega el renglón de almacén.'
        WHERE modelo_id = v_mod_dolly AND material_id = v_mat_id AND (paso IS NULL OR paso != 'PASO 1');
    END IF;
    -- [51] BISAGRA DE DOLLY (cant: 2.0, paso: PASO 1)
    SELECT id INTO v_mat_id FROM public.productos WHERE nombre = 'BISAGRA DE DOLLY' AND organizacion_id = v_org_id LIMIT 1;
    IF v_mat_id IS NOT NULL THEN
        INSERT INTO public.receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
        SELECT v_mod_dolly, v_mat_id, 2.0, 'fija', 'PASO 1', 'CUADRO', NULL, NULL, 'NO es la ''BISAGRA 5/8'' de la caja auxiliar ($11): el sistema ya cobra ''Bisagra'' ×2 a $1,041 en conceptos (otros). Crear como material aparte.'
        WHERE NOT EXISTS (
            SELECT 1 FROM public.receta_base WHERE modelo_id = v_mod_dolly AND material_id = v_mat_id
        );

        UPDATE public.receta_base
        SET cantidad = 2.0, escala = 'fija', paso = 'PASO 1', uso = 'CUADRO', seccion = NULL, condicion = NULL, notas = 'NO es la ''BISAGRA 5/8'' de la caja auxiliar ($11): el sistema ya cobra ''Bisagra'' ×2 a $1,041 en conceptos (otros). Crear como material aparte.'
        WHERE modelo_id = v_mod_dolly AND material_id = v_mat_id AND (paso IS NULL OR paso != 'PASO 1');
    END IF;
    -- [52] PERNO DE DOLLY (cant: 2.0, paso: PASO 1)
    SELECT id INTO v_mat_id FROM public.productos WHERE nombre = 'PERNO DE DOLLY' AND organizacion_id = v_org_id LIMIT 1;
    IF v_mat_id IS NOT NULL THEN
        INSERT INTO public.receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
        SELECT v_mod_dolly, v_mat_id, 2.0, 'fija', 'PASO 1', 'CUADRO', NULL, NULL, 'El sistema ya cobra ''Perno de Dona'' ×2 a $421.08 en conceptos (otros); es el mismo perno (nombre distinto). Solo agrega el renglón de almacén.'
        WHERE NOT EXISTS (
            SELECT 1 FROM public.receta_base WHERE modelo_id = v_mod_dolly AND material_id = v_mat_id
        );

        UPDATE public.receta_base
        SET cantidad = 2.0, escala = 'fija', paso = 'PASO 1', uso = 'CUADRO', seccion = NULL, condicion = NULL, notas = 'El sistema ya cobra ''Perno de Dona'' ×2 a $421.08 en conceptos (otros); es el mismo perno (nombre distinto). Solo agrega el renglón de almacén.'
        WHERE modelo_id = v_mod_dolly AND material_id = v_mat_id AND (paso IS NULL OR paso != 'PASO 1');
    END IF;
    -- [53] BUJE CONICO GRANDE (cant: 4.0, paso: PASO 1)
    SELECT id INTO v_mat_id FROM public.productos WHERE nombre = 'BUJE CONICO GRANDE' AND organizacion_id = v_org_id LIMIT 1;
    IF v_mat_id IS NOT NULL THEN
        INSERT INTO public.receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
        SELECT v_mod_dolly, v_mat_id, 4.0, 'fija', 'PASO 1', 'CUADRO', NULL, NULL, 'El sistema ya cobra ''Buje cónico'' ×4 a $160 en conceptos (otros). Solo agrega el renglón de almacén.'
        WHERE NOT EXISTS (
            SELECT 1 FROM public.receta_base WHERE modelo_id = v_mod_dolly AND material_id = v_mat_id
        );

        UPDATE public.receta_base
        SET cantidad = 4.0, escala = 'fija', paso = 'PASO 1', uso = 'CUADRO', seccion = NULL, condicion = NULL, notas = 'El sistema ya cobra ''Buje cónico'' ×4 a $160 en conceptos (otros). Solo agrega el renglón de almacén.'
        WHERE modelo_id = v_mod_dolly AND material_id = v_mat_id AND (paso IS NULL OR paso != 'PASO 1');
    END IF;

    -- =========================================================================
    -- 3. Componentes de opciones (20 renglones: 3 donas x 4, 2 quintas x 4)
    -- =========================================================================

    -- Grupo dona / Opción holland (4 componentes)
    SELECT o.id INTO v_opc_id
    FROM public.opciones_configuracion o
    JOIN public.grupos_configuracion g ON g.id = o.grupo_id
    WHERE g.clave = 'dona' AND o.clave = 'holland' AND o.organizacion_id = v_org_id;

    IF v_opc_id IS NOT NULL THEN
        SELECT id INTO v_mat_id FROM public.productos WHERE nombre = 'DONA HOLLAND' AND organizacion_id = v_org_id LIMIT 1;
        IF v_mat_id IS NOT NULL THEN
            INSERT INTO public.opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, uso, seccion, condicion, notas)
            SELECT v_opc_id, v_mat_id, 1.0, 'fija', 'componente', 'PASO 1', 'La dona misma', NULL, NULL, 'La dona es la pieza de la opción; crear con costo 0'
            WHERE NOT EXISTS (
                SELECT 1 FROM public.opcion_componentes WHERE opcion_id = v_opc_id AND material_id = v_mat_id
            );

            UPDATE public.opcion_componentes
            SET paso = 'PASO 1', uso = 'La dona misma', notas = 'La dona es la pieza de la opción; crear con costo 0'
            WHERE opcion_id = v_opc_id AND material_id = v_mat_id AND (paso IS NULL OR paso != 'PASO 1');
        END IF;
        SELECT id INTO v_mat_id FROM public.productos WHERE nombre = 'TORNILLO 5/8*5 GRADO 8' AND organizacion_id = v_org_id LIMIT 1;
        IF v_mat_id IS NOT NULL THEN
            INSERT INTO public.opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, uso, seccion, condicion, notas)
            SELECT v_opc_id, v_mat_id, 6.0, 'fija', 'componente', 'PASO 1', 'TORNILLERIA DE DONA', NULL, NULL, 'Tornillería de dona; igual para las 3 (confirmar)'
            WHERE NOT EXISTS (
                SELECT 1 FROM public.opcion_componentes WHERE opcion_id = v_opc_id AND material_id = v_mat_id
            );

            UPDATE public.opcion_componentes
            SET paso = 'PASO 1', uso = 'TORNILLERIA DE DONA', notas = 'Tornillería de dona; igual para las 3 (confirmar)'
            WHERE opcion_id = v_opc_id AND material_id = v_mat_id AND (paso IS NULL OR paso != 'PASO 1');
        END IF;
        SELECT id INTO v_mat_id FROM public.productos WHERE nombre = 'TUERCA GRIPCO 5/8' AND organizacion_id = v_org_id LIMIT 1;
        IF v_mat_id IS NOT NULL THEN
            INSERT INTO public.opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, uso, seccion, condicion, notas)
            SELECT v_opc_id, v_mat_id, 6.0, 'fija', 'componente', 'PASO 1', 'TORNILLERIA DE DONA', NULL, NULL, 'Tornillería de dona; igual para las 3 (confirmar)'
            WHERE NOT EXISTS (
                SELECT 1 FROM public.opcion_componentes WHERE opcion_id = v_opc_id AND material_id = v_mat_id
            );

            UPDATE public.opcion_componentes
            SET paso = 'PASO 1', uso = 'TORNILLERIA DE DONA', notas = 'Tornillería de dona; igual para las 3 (confirmar)'
            WHERE opcion_id = v_opc_id AND material_id = v_mat_id AND (paso IS NULL OR paso != 'PASO 1');
        END IF;
        SELECT id INTO v_mat_id FROM public.productos WHERE nombre = 'RONDANA AUTOMOTRIZ 5/8' AND organizacion_id = v_org_id LIMIT 1;
        IF v_mat_id IS NOT NULL THEN
            INSERT INTO public.opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, uso, seccion, condicion, notas)
            SELECT v_opc_id, v_mat_id, 12.0, 'fija', 'componente', 'PASO 1', 'TORNILLERIA DE DONA', NULL, NULL, 'Tornillería de dona; igual para las 3 (confirmar)'
            WHERE NOT EXISTS (
                SELECT 1 FROM public.opcion_componentes WHERE opcion_id = v_opc_id AND material_id = v_mat_id
            );

            UPDATE public.opcion_componentes
            SET paso = 'PASO 1', uso = 'TORNILLERIA DE DONA', notas = 'Tornillería de dona; igual para las 3 (confirmar)'
            WHERE opcion_id = v_opc_id AND material_id = v_mat_id AND (paso IS NULL OR paso != 'PASO 1');
        END IF;
    END IF;

    -- Grupo dona / Opción premier (4 componentes)
    SELECT o.id INTO v_opc_id
    FROM public.opciones_configuracion o
    JOIN public.grupos_configuracion g ON g.id = o.grupo_id
    WHERE g.clave = 'dona' AND o.clave = 'premier' AND o.organizacion_id = v_org_id;

    IF v_opc_id IS NOT NULL THEN
        SELECT id INTO v_mat_id FROM public.productos WHERE nombre = 'DONA PREMIER' AND organizacion_id = v_org_id LIMIT 1;
        IF v_mat_id IS NOT NULL THEN
            INSERT INTO public.opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, uso, seccion, condicion, notas)
            SELECT v_opc_id, v_mat_id, 1.0, 'fija', 'componente', 'PASO 1', 'La dona misma', NULL, NULL, 'La dona es la pieza de la opción; crear con costo 0'
            WHERE NOT EXISTS (
                SELECT 1 FROM public.opcion_componentes WHERE opcion_id = v_opc_id AND material_id = v_mat_id
            );

            UPDATE public.opcion_componentes
            SET paso = 'PASO 1', uso = 'La dona misma', notas = 'La dona es la pieza de la opción; crear con costo 0'
            WHERE opcion_id = v_opc_id AND material_id = v_mat_id AND (paso IS NULL OR paso != 'PASO 1');
        END IF;
        SELECT id INTO v_mat_id FROM public.productos WHERE nombre = 'TORNILLO 5/8*5 GRADO 8' AND organizacion_id = v_org_id LIMIT 1;
        IF v_mat_id IS NOT NULL THEN
            INSERT INTO public.opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, uso, seccion, condicion, notas)
            SELECT v_opc_id, v_mat_id, 6.0, 'fija', 'componente', 'PASO 1', 'TORNILLERIA DE DONA', NULL, NULL, 'Tornillería de dona; igual para las 3 (confirmar)'
            WHERE NOT EXISTS (
                SELECT 1 FROM public.opcion_componentes WHERE opcion_id = v_opc_id AND material_id = v_mat_id
            );

            UPDATE public.opcion_componentes
            SET paso = 'PASO 1', uso = 'TORNILLERIA DE DONA', notas = 'Tornillería de dona; igual para las 3 (confirmar)'
            WHERE opcion_id = v_opc_id AND material_id = v_mat_id AND (paso IS NULL OR paso != 'PASO 1');
        END IF;
        SELECT id INTO v_mat_id FROM public.productos WHERE nombre = 'TUERCA GRIPCO 5/8' AND organizacion_id = v_org_id LIMIT 1;
        IF v_mat_id IS NOT NULL THEN
            INSERT INTO public.opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, uso, seccion, condicion, notas)
            SELECT v_opc_id, v_mat_id, 6.0, 'fija', 'componente', 'PASO 1', 'TORNILLERIA DE DONA', NULL, NULL, 'Tornillería de dona; igual para las 3 (confirmar)'
            WHERE NOT EXISTS (
                SELECT 1 FROM public.opcion_componentes WHERE opcion_id = v_opc_id AND material_id = v_mat_id
            );

            UPDATE public.opcion_componentes
            SET paso = 'PASO 1', uso = 'TORNILLERIA DE DONA', notas = 'Tornillería de dona; igual para las 3 (confirmar)'
            WHERE opcion_id = v_opc_id AND material_id = v_mat_id AND (paso IS NULL OR paso != 'PASO 1');
        END IF;
        SELECT id INTO v_mat_id FROM public.productos WHERE nombre = 'RONDANA AUTOMOTRIZ 5/8' AND organizacion_id = v_org_id LIMIT 1;
        IF v_mat_id IS NOT NULL THEN
            INSERT INTO public.opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, uso, seccion, condicion, notas)
            SELECT v_opc_id, v_mat_id, 12.0, 'fija', 'componente', 'PASO 1', 'TORNILLERIA DE DONA', NULL, NULL, 'Tornillería de dona; igual para las 3 (confirmar)'
            WHERE NOT EXISTS (
                SELECT 1 FROM public.opcion_componentes WHERE opcion_id = v_opc_id AND material_id = v_mat_id
            );

            UPDATE public.opcion_componentes
            SET paso = 'PASO 1', uso = 'TORNILLERIA DE DONA', notas = 'Tornillería de dona; igual para las 3 (confirmar)'
            WHERE opcion_id = v_opc_id AND material_id = v_mat_id AND (paso IS NULL OR paso != 'PASO 1');
        END IF;
    END IF;

    -- Grupo dona / Opción bestia (4 componentes)
    SELECT o.id INTO v_opc_id
    FROM public.opciones_configuracion o
    JOIN public.grupos_configuracion g ON g.id = o.grupo_id
    WHERE g.clave = 'dona' AND o.clave = 'bestia' AND o.organizacion_id = v_org_id;

    IF v_opc_id IS NOT NULL THEN
        SELECT id INTO v_mat_id FROM public.productos WHERE nombre = 'DONA PREMIER BESTIA' AND organizacion_id = v_org_id LIMIT 1;
        IF v_mat_id IS NOT NULL THEN
            INSERT INTO public.opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, uso, seccion, condicion, notas)
            SELECT v_opc_id, v_mat_id, 1.0, 'fija', 'componente', 'PASO 1', 'La dona misma', NULL, NULL, 'La dona es la pieza de la opción; crear con costo 0'
            WHERE NOT EXISTS (
                SELECT 1 FROM public.opcion_componentes WHERE opcion_id = v_opc_id AND material_id = v_mat_id
            );

            UPDATE public.opcion_componentes
            SET paso = 'PASO 1', uso = 'La dona misma', notas = 'La dona es la pieza de la opción; crear con costo 0'
            WHERE opcion_id = v_opc_id AND material_id = v_mat_id AND (paso IS NULL OR paso != 'PASO 1');
        END IF;
        SELECT id INTO v_mat_id FROM public.productos WHERE nombre = 'TORNILLO 5/8*5 GRADO 8' AND organizacion_id = v_org_id LIMIT 1;
        IF v_mat_id IS NOT NULL THEN
            INSERT INTO public.opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, uso, seccion, condicion, notas)
            SELECT v_opc_id, v_mat_id, 6.0, 'fija', 'componente', 'PASO 1', 'TORNILLERIA DE DONA', NULL, NULL, 'Tornillería de dona; igual para las 3 (confirmar)'
            WHERE NOT EXISTS (
                SELECT 1 FROM public.opcion_componentes WHERE opcion_id = v_opc_id AND material_id = v_mat_id
            );

            UPDATE public.opcion_componentes
            SET paso = 'PASO 1', uso = 'TORNILLERIA DE DONA', notas = 'Tornillería de dona; igual para las 3 (confirmar)'
            WHERE opcion_id = v_opc_id AND material_id = v_mat_id AND (paso IS NULL OR paso != 'PASO 1');
        END IF;
        SELECT id INTO v_mat_id FROM public.productos WHERE nombre = 'TUERCA GRIPCO 5/8' AND organizacion_id = v_org_id LIMIT 1;
        IF v_mat_id IS NOT NULL THEN
            INSERT INTO public.opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, uso, seccion, condicion, notas)
            SELECT v_opc_id, v_mat_id, 6.0, 'fija', 'componente', 'PASO 1', 'TORNILLERIA DE DONA', NULL, NULL, 'Tornillería de dona; igual para las 3 (confirmar)'
            WHERE NOT EXISTS (
                SELECT 1 FROM public.opcion_componentes WHERE opcion_id = v_opc_id AND material_id = v_mat_id
            );

            UPDATE public.opcion_componentes
            SET paso = 'PASO 1', uso = 'TORNILLERIA DE DONA', notas = 'Tornillería de dona; igual para las 3 (confirmar)'
            WHERE opcion_id = v_opc_id AND material_id = v_mat_id AND (paso IS NULL OR paso != 'PASO 1');
        END IF;
        SELECT id INTO v_mat_id FROM public.productos WHERE nombre = 'RONDANA AUTOMOTRIZ 5/8' AND organizacion_id = v_org_id LIMIT 1;
        IF v_mat_id IS NOT NULL THEN
            INSERT INTO public.opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, uso, seccion, condicion, notas)
            SELECT v_opc_id, v_mat_id, 12.0, 'fija', 'componente', 'PASO 1', 'TORNILLERIA DE DONA', NULL, NULL, 'Tornillería de dona; igual para las 3 (confirmar)'
            WHERE NOT EXISTS (
                SELECT 1 FROM public.opcion_componentes WHERE opcion_id = v_opc_id AND material_id = v_mat_id
            );

            UPDATE public.opcion_componentes
            SET paso = 'PASO 1', uso = 'TORNILLERIA DE DONA', notas = 'Tornillería de dona; igual para las 3 (confirmar)'
            WHERE opcion_id = v_opc_id AND material_id = v_mat_id AND (paso IS NULL OR paso != 'PASO 1');
        END IF;
    END IF;

    -- Grupo quinta / Opción holland (4 componentes)
    SELECT o.id INTO v_opc_id
    FROM public.opciones_configuracion o
    JOIN public.grupos_configuracion g ON g.id = o.grupo_id
    WHERE g.clave = 'quinta' AND o.clave = 'holland' AND o.organizacion_id = v_org_id;

    IF v_opc_id IS NOT NULL THEN
        SELECT id INTO v_mat_id FROM public.productos WHERE nombre = 'QUINTA HOLLAND' AND organizacion_id = v_org_id LIMIT 1;
        IF v_mat_id IS NOT NULL THEN
            INSERT INTO public.opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, uso, seccion, condicion, notas)
            SELECT v_opc_id, v_mat_id, 1.0, 'fija', 'componente', 'TERMINADO', 'La quinta misma', NULL, NULL, 'La quinta es la pieza de la opción; crear con costo 0 (el precio ya está en opcion_costos)'
            WHERE NOT EXISTS (
                SELECT 1 FROM public.opcion_componentes WHERE opcion_id = v_opc_id AND material_id = v_mat_id
            );

            UPDATE public.opcion_componentes
            SET paso = 'TERMINADO', uso = 'La quinta misma', notas = 'La quinta es la pieza de la opción; crear con costo 0 (el precio ya está en opcion_costos)'
            WHERE opcion_id = v_opc_id AND material_id = v_mat_id AND (paso IS NULL OR paso != 'TERMINADO');
        END IF;
        SELECT id INTO v_mat_id FROM public.productos WHERE nombre = 'TORNILLO 5/8 X 2 1/2 GRADO 8' AND organizacion_id = v_org_id LIMIT 1;
        IF v_mat_id IS NOT NULL THEN
            INSERT INTO public.opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, uso, seccion, condicion, notas)
            SELECT v_opc_id, v_mat_id, 10.0, 'fija', 'componente', 'TERMINADO', 'TORNILLERIA DE QUINTA', NULL, NULL, 'Tornillería de quinta; igual para ambas (confirmar). Tornillería de quinta; misma para Holland y Fontaine (confirmar) (El kit tipo H suma 24 de este material entre todos sus usos.)'
            WHERE NOT EXISTS (
                SELECT 1 FROM public.opcion_componentes WHERE opcion_id = v_opc_id AND material_id = v_mat_id
            );

            UPDATE public.opcion_componentes
            SET paso = 'TERMINADO', uso = 'TORNILLERIA DE QUINTA', notas = 'Tornillería de quinta; igual para ambas (confirmar). Tornillería de quinta; misma para Holland y Fontaine (confirmar) (El kit tipo H suma 24 de este material entre todos sus usos.)'
            WHERE opcion_id = v_opc_id AND material_id = v_mat_id AND (paso IS NULL OR paso != 'TERMINADO');
        END IF;
        SELECT id INTO v_mat_id FROM public.productos WHERE nombre = 'TUERCA GRIPCO 5/8' AND organizacion_id = v_org_id LIMIT 1;
        IF v_mat_id IS NOT NULL THEN
            INSERT INTO public.opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, uso, seccion, condicion, notas)
            SELECT v_opc_id, v_mat_id, 10.0, 'fija', 'componente', 'TERMINADO', 'TORNILLERIA DE QUINTA', NULL, NULL, 'Tornillería de quinta; igual para ambas (confirmar).'
            WHERE NOT EXISTS (
                SELECT 1 FROM public.opcion_componentes WHERE opcion_id = v_opc_id AND material_id = v_mat_id
            );

            UPDATE public.opcion_componentes
            SET paso = 'TERMINADO', uso = 'TORNILLERIA DE QUINTA', notas = 'Tornillería de quinta; igual para ambas (confirmar).'
            WHERE opcion_id = v_opc_id AND material_id = v_mat_id AND (paso IS NULL OR paso != 'TERMINADO');
        END IF;
        SELECT id INTO v_mat_id FROM public.productos WHERE nombre = 'RONDANA AUTOMOTRIZ 5/8' AND organizacion_id = v_org_id LIMIT 1;
        IF v_mat_id IS NOT NULL THEN
            INSERT INTO public.opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, uso, seccion, condicion, notas)
            SELECT v_opc_id, v_mat_id, 20.0, 'fija', 'componente', 'TERMINADO', 'TORNILLERIA DE QUINTA', NULL, NULL, 'Tornillería de quinta; igual para ambas (confirmar). Tornillería de quinta; misma para Holland y Fontaine (confirmar) (El kit tipo H suma 60 de este material entre todos sus usos.)'
            WHERE NOT EXISTS (
                SELECT 1 FROM public.opcion_componentes WHERE opcion_id = v_opc_id AND material_id = v_mat_id
            );

            UPDATE public.opcion_componentes
            SET paso = 'TERMINADO', uso = 'TORNILLERIA DE QUINTA', notas = 'Tornillería de quinta; igual para ambas (confirmar). Tornillería de quinta; misma para Holland y Fontaine (confirmar) (El kit tipo H suma 60 de este material entre todos sus usos.)'
            WHERE opcion_id = v_opc_id AND material_id = v_mat_id AND (paso IS NULL OR paso != 'TERMINADO');
        END IF;
    END IF;

    -- Grupo quinta / Opción fontaine (4 componentes)
    SELECT o.id INTO v_opc_id
    FROM public.opciones_configuracion o
    JOIN public.grupos_configuracion g ON g.id = o.grupo_id
    WHERE g.clave = 'quinta' AND o.clave = 'fontaine' AND o.organizacion_id = v_org_id;

    IF v_opc_id IS NOT NULL THEN
        SELECT id INTO v_mat_id FROM public.productos WHERE nombre = 'QUINTA FONTAINE' AND organizacion_id = v_org_id LIMIT 1;
        IF v_mat_id IS NOT NULL THEN
            INSERT INTO public.opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, uso, seccion, condicion, notas)
            SELECT v_opc_id, v_mat_id, 1.0, 'fija', 'componente', 'TERMINADO', 'La quinta misma', NULL, NULL, 'La quinta es la pieza de la opción; crear con costo 0 (el precio ya está en opcion_costos)'
            WHERE NOT EXISTS (
                SELECT 1 FROM public.opcion_componentes WHERE opcion_id = v_opc_id AND material_id = v_mat_id
            );

            UPDATE public.opcion_componentes
            SET paso = 'TERMINADO', uso = 'La quinta misma', notas = 'La quinta es la pieza de la opción; crear con costo 0 (el precio ya está en opcion_costos)'
            WHERE opcion_id = v_opc_id AND material_id = v_mat_id AND (paso IS NULL OR paso != 'TERMINADO');
        END IF;
        SELECT id INTO v_mat_id FROM public.productos WHERE nombre = 'TORNILLO 5/8 X 2 1/2 GRADO 8' AND organizacion_id = v_org_id LIMIT 1;
        IF v_mat_id IS NOT NULL THEN
            INSERT INTO public.opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, uso, seccion, condicion, notas)
            SELECT v_opc_id, v_mat_id, 10.0, 'fija', 'componente', 'TERMINADO', 'TORNILLERIA DE QUINTA', NULL, NULL, 'Tornillería de quinta; igual para ambas (confirmar). Tornillería de quinta; misma para Holland y Fontaine (confirmar) (El kit tipo H suma 24 de este material entre todos sus usos.)'
            WHERE NOT EXISTS (
                SELECT 1 FROM public.opcion_componentes WHERE opcion_id = v_opc_id AND material_id = v_mat_id
            );

            UPDATE public.opcion_componentes
            SET paso = 'TERMINADO', uso = 'TORNILLERIA DE QUINTA', notas = 'Tornillería de quinta; igual para ambas (confirmar). Tornillería de quinta; misma para Holland y Fontaine (confirmar) (El kit tipo H suma 24 de este material entre todos sus usos.)'
            WHERE opcion_id = v_opc_id AND material_id = v_mat_id AND (paso IS NULL OR paso != 'TERMINADO');
        END IF;
        SELECT id INTO v_mat_id FROM public.productos WHERE nombre = 'TUERCA GRIPCO 5/8' AND organizacion_id = v_org_id LIMIT 1;
        IF v_mat_id IS NOT NULL THEN
            INSERT INTO public.opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, uso, seccion, condicion, notas)
            SELECT v_opc_id, v_mat_id, 10.0, 'fija', 'componente', 'TERMINADO', 'TORNILLERIA DE QUINTA', NULL, NULL, 'Tornillería de quinta; igual para ambas (confirmar).'
            WHERE NOT EXISTS (
                SELECT 1 FROM public.opcion_componentes WHERE opcion_id = v_opc_id AND material_id = v_mat_id
            );

            UPDATE public.opcion_componentes
            SET paso = 'TERMINADO', uso = 'TORNILLERIA DE QUINTA', notas = 'Tornillería de quinta; igual para ambas (confirmar).'
            WHERE opcion_id = v_opc_id AND material_id = v_mat_id AND (paso IS NULL OR paso != 'TERMINADO');
        END IF;
        SELECT id INTO v_mat_id FROM public.productos WHERE nombre = 'RONDANA AUTOMOTRIZ 5/8' AND organizacion_id = v_org_id LIMIT 1;
        IF v_mat_id IS NOT NULL THEN
            INSERT INTO public.opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, uso, seccion, condicion, notas)
            SELECT v_opc_id, v_mat_id, 20.0, 'fija', 'componente', 'TERMINADO', 'TORNILLERIA DE QUINTA', NULL, NULL, 'Tornillería de quinta; igual para ambas (confirmar). Tornillería de quinta; misma para Holland y Fontaine (confirmar) (El kit tipo H suma 60 de este material entre todos sus usos.)'
            WHERE NOT EXISTS (
                SELECT 1 FROM public.opcion_componentes WHERE opcion_id = v_opc_id AND material_id = v_mat_id
            );

            UPDATE public.opcion_componentes
            SET paso = 'TERMINADO', uso = 'TORNILLERIA DE QUINTA', notas = 'Tornillería de quinta; igual para ambas (confirmar). Tornillería de quinta; misma para Holland y Fontaine (confirmar) (El kit tipo H suma 60 de este material entre todos sus usos.)'
            WHERE opcion_id = v_opc_id AND material_id = v_mat_id AND (paso IS NULL OR paso != 'TERMINADO');
        END IF;
    END IF;

    -- =========================================================================
    -- 4. Asignación de fase_id (condicional si fases_despiece existe en la base)
    -- =========================================================================
    IF to_regclass('public.fases_despiece') IS NOT NULL THEN
        EXECUTE 'SELECT id FROM public.fases_despiece WHERE clave = ''paso_1'' AND organizacion_id = $1 LIMIT 1' INTO v_fase_paso_1 USING v_org_id;
        EXECUTE 'SELECT id FROM public.fases_despiece WHERE clave = ''paso_7'' AND organizacion_id = $1 LIMIT 1' INTO v_fase_limpieza USING v_org_id;
        EXECUTE 'SELECT id FROM public.fases_despiece WHERE clave = ''paso_9'' AND organizacion_id = $1 LIMIT 1' INTO v_fase_aire USING v_org_id;
        EXECUTE 'SELECT id FROM public.fases_despiece WHERE clave = ''paso_10'' AND organizacion_id = $1 LIMIT 1' INTO v_fase_luz USING v_org_id;
        EXECUTE 'SELECT id FROM public.fases_despiece WHERE clave = ''paso_12'' AND organizacion_id = $1 LIMIT 1' INTO v_fase_terminado USING v_org_id;
        EXECUTE 'SELECT id FROM public.fases_despiece WHERE clave = ''extras'' AND organizacion_id = $1 LIMIT 1' INTO v_fase_extras USING v_org_id;

        -- Fallbacks a equivalencias si aplica
        IF v_fase_paso_1 IS NULL AND to_regclass('public.fases_despiece_equivalencias') IS NOT NULL THEN
            EXECUTE 'SELECT fase_id FROM public.fases_despiece_equivalencias WHERE paso_legacy = ''PASO 1'' AND organizacion_id = $1 LIMIT 1' INTO v_fase_paso_1 USING v_org_id;
        END IF;
        IF v_fase_limpieza IS NULL AND to_regclass('public.fases_despiece_equivalencias') IS NOT NULL THEN
            EXECUTE 'SELECT fase_id FROM public.fases_despiece_equivalencias WHERE paso_legacy = ''LIMPIEZA'' AND organizacion_id = $1 LIMIT 1' INTO v_fase_limpieza USING v_org_id;
        END IF;
        IF v_fase_aire IS NULL AND to_regclass('public.fases_despiece_equivalencias') IS NOT NULL THEN
            EXECUTE 'SELECT fase_id FROM public.fases_despiece_equivalencias WHERE paso_legacy = ''AIRE'' AND organizacion_id = $1 LIMIT 1' INTO v_fase_aire USING v_org_id;
        END IF;
        IF v_fase_luz IS NULL AND to_regclass('public.fases_despiece_equivalencias') IS NOT NULL THEN
            EXECUTE 'SELECT fase_id FROM public.fases_despiece_equivalencias WHERE paso_legacy = ''LUZ'' AND organizacion_id = $1 LIMIT 1' INTO v_fase_luz USING v_org_id;
        END IF;
        IF v_fase_terminado IS NULL AND to_regclass('public.fases_despiece_equivalencias') IS NOT NULL THEN
            EXECUTE 'SELECT fase_id FROM public.fases_despiece_equivalencias WHERE paso_legacy = ''TERMINADO'' AND organizacion_id = $1 LIMIT 1' INTO v_fase_terminado USING v_org_id;
        END IF;
        IF v_fase_extras IS NULL AND to_regclass('public.fases_despiece_equivalencias') IS NOT NULL THEN
            EXECUTE 'SELECT fase_id FROM public.fases_despiece_equivalencias WHERE paso_legacy = ''EXTRAS'' AND organizacion_id = $1 LIMIT 1' INTO v_fase_extras USING v_org_id;
        END IF;

        -- Asignar en receta_base del dolly
        IF v_fase_paso_1 IS NOT NULL THEN
            UPDATE public.receta_base SET fase_id = v_fase_paso_1
            WHERE modelo_id = v_mod_dolly AND paso = 'PASO 1' AND (fase_id IS NULL OR fase_id != v_fase_paso_1);
        END IF;
        IF v_fase_limpieza IS NOT NULL THEN
            UPDATE public.receta_base SET fase_id = v_fase_limpieza
            WHERE modelo_id = v_mod_dolly AND paso = 'LIMPIEZA' AND (fase_id IS NULL OR fase_id != v_fase_limpieza);
        END IF;
        IF v_fase_aire IS NOT NULL THEN
            UPDATE public.receta_base SET fase_id = v_fase_aire
            WHERE modelo_id = v_mod_dolly AND paso = 'AIRE' AND (fase_id IS NULL OR fase_id != v_fase_aire);
        END IF;
        IF v_fase_luz IS NOT NULL THEN
            UPDATE public.receta_base SET fase_id = v_fase_luz
            WHERE modelo_id = v_mod_dolly AND paso = 'LUZ' AND (fase_id IS NULL OR fase_id != v_fase_luz);
        END IF;
        IF v_fase_terminado IS NOT NULL THEN
            UPDATE public.receta_base SET fase_id = v_fase_terminado
            WHERE modelo_id = v_mod_dolly AND paso = 'TERMINADO' AND (fase_id IS NULL OR fase_id != v_fase_terminado);
        END IF;
        IF v_fase_extras IS NOT NULL THEN
            UPDATE public.receta_base SET fase_id = v_fase_extras
            WHERE modelo_id = v_mod_dolly AND paso = 'EXTRAS' AND (fase_id IS NULL OR fase_id != v_fase_extras);
        END IF;

        -- Asignar en opcion_componentes de donas y quintas
        IF v_fase_paso_1 IS NOT NULL THEN
            UPDATE public.opcion_componentes oc
            SET fase_id = v_fase_paso_1
            FROM public.opciones_configuracion o, public.grupos_configuracion g
            WHERE oc.opcion_id = o.id AND o.grupo_id = g.id
              AND g.clave = 'dona' AND oc.paso = 'PASO 1'
              AND (oc.fase_id IS NULL OR oc.fase_id != v_fase_paso_1);
        END IF;
        IF v_fase_terminado IS NOT NULL THEN
            UPDATE public.opcion_componentes oc
            SET fase_id = v_fase_terminado
            FROM public.opciones_configuracion o, public.grupos_configuracion g
            WHERE oc.opcion_id = o.id AND o.grupo_id = g.id
              AND g.clave = 'quinta' AND oc.paso = 'TERMINADO'
              AND (oc.fase_id IS NULL OR oc.fase_id != v_fase_terminado);
        END IF;
    END IF;

END $$;

COMMIT;