-- Prueba transaccional de validación T2 Ronda 4
-- Prueba obligatoria: Segunda org con productos de UUID distinto -> 0 líneas de plataforma sin fase_id en ambas orgs
-- RLS estricto SELECT para authenticated y aislamiento completo.

\set ON_ERROR_STOP on

BEGIN;

-- 1. Crear Organización B de prueba con UUID distinto
INSERT INTO organizaciones (id, nombre)
VALUES ('00000000-0000-0000-0000-000000000002', 'ORGANIZACION PRUEBA B T2')
ON CONFLICT (id) DO NOTHING;

-- 2. Crear Usuarios en auth.users y perfiles_organizacion
INSERT INTO auth.users (id, email, raw_user_meta_data)
VALUES
    ('a988611b-2949-4ab7-b670-daf4a21f4e18', 'test_user_a@remolques.test', '{"nombre":"Usuario A"}'),
    ('00000000-0000-0000-0000-0000000000b2', 'test_user_b@remolques.test', '{"nombre":"Usuario B"}')
ON CONFLICT (id) DO NOTHING;

INSERT INTO perfiles_organizacion (usuario_id, organizacion_id, rol)
VALUES
    ('a988611b-2949-4ab7-b670-daf4a21f4e18', '00000000-0000-0000-0000-000000000001', 'usuario'),
    ('00000000-0000-0000-0000-0000000000b2', '00000000-0000-0000-0000-000000000002', 'usuario')
ON CONFLICT DO NOTHING;

-- 3. Clonar productos para Org B con gen_random_uuid()::text (UUIDs completamente distintos a Org A)
INSERT INTO productos (id, organizacion_id, nombre, tipo_item, unidad, costo)
SELECT gen_random_uuid()::text, '00000000-0000-0000-0000-000000000002', nombre, tipo_item, unidad, costo
FROM productos
WHERE organizacion_id = '00000000-0000-0000-0000-000000000001'
ON CONFLICT DO NOTHING;

-- 4. Clonar modelo PLATAFORMA 2 40 FT para Org B con sus 202 líneas
DO $$
DECLARE
    v_mod_a UUID;
    v_mod_b UUID := '00000000-0000-0000-0000-0000000000b0';
    v_prod_mod_b TEXT;
BEGIN
    SELECT id INTO v_mod_a FROM modelos WHERE organizacion_id = '00000000-0000-0000-0000-000000000001' AND tipo = 'plataforma' AND largo_ft = 40 AND num_ejes = 2;
    
    SELECT min(id) INTO v_prod_mod_b FROM productos WHERE organizacion_id = '00000000-0000-0000-0000-000000000002' AND nombre ILIKE '%PLATAFORMA%40%';
    IF v_prod_mod_b IS NULL THEN
        v_prod_mod_b := gen_random_uuid()::text;
        INSERT INTO productos (id, organizacion_id, nombre, tipo_item, unidad)
        VALUES (v_prod_mod_b, '00000000-0000-0000-0000-000000000002', 'PLATAFORMA 2 40 FT TERMINADA', 'producto_terminado', 'pz');
    END IF;

    INSERT INTO modelos (id, organizacion_id, producto_id, tipo, num_ejes, largo_ft, activo)
    VALUES (v_mod_b, '00000000-0000-0000-0000-000000000002', v_prod_mod_b, 'plataforma', 2, 40, true)
    ON CONFLICT (id) DO NOTHING;

    -- Insertar las 202 líneas en Org B asociadas a los productos de Org B (con UUIDs generados)
    INSERT INTO receta_base (modelo_id, material_id, cantidad, paso, uso, escala)
    SELECT v_mod_b, pb.id, rb.cantidad, rb.paso, rb.uso, rb.escala
    FROM receta_base rb
    JOIN productos pa ON pa.id = rb.material_id
    JOIN productos pb ON pb.nombre = pa.nombre AND pb.organizacion_id = '00000000-0000-0000-0000-000000000002'
    WHERE rb.modelo_id = v_mod_a;
END $$;

-- 5. Ejecutar la migración completa (población y asignación multitenant por nombre de producto)
-- El bloque DO de la migración correrá para TODAS las organizaciones (A y B)
DO $$
DECLARE
    r_org RECORD;
    v_fase_id UUID;
    v_fase_5 UUID;
    v_fase_6 UUID;
    v_fase_8 UUID;
    v_fase_11 UUID;
    v_fase_llantas_rines UUID;
    v_fase_extras UUID;
    r_acero RECORD;
    v_mat_id TEXT;
    v_mat_count INT;
    v_target_fase_id UUID;
BEGIN
    FOR r_org IN SELECT id FROM organizaciones WHERE id IN ('00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000002') LOOP

        -- Fases
        INSERT INTO fases_despiece (organizacion_id, clave, nombre, subtitulo, orden, descripcion, activo)
        VALUES
            (r_org.id, 'paso_1', 'Paso 1', 'Armado y corte de almas', 1, 'Corte almas', true),
            (r_org.id, 'paso_2', 'Paso 2', 'Soleras de refuerzo de almas', 2, 'Soleras almas', true),
            (r_org.id, 'paso_3', 'Paso 3', 'Estructura primaria', 3, 'Bordas y puentes', true),
            (r_org.id, 'paso_4', 'Paso 4', 'Cargadores transversales', 4, 'Cargadores IPR', true),
            (r_org.id, 'paso_5', 'Paso 5', 'Instalacion de suspension', 5, 'Suspension', true),
            (r_org.id, 'paso_6', 'Paso 6', 'Patines y ejes', 6, 'Patines y ejes', true),
            (r_org.id, 'paso_7', 'PASO 7', 'Lavado quimico', 7, 'Lavado', true),
            (r_org.id, 'paso_8', 'PASO 8', 'Pintura', 8, 'Pintura', true),
            (r_org.id, 'paso_9', 'PASO 9', 'Kit neumatico', 9, 'Aire', true),
            (r_org.id, 'paso_10', 'PASO 10', 'Iluminacion', 10, 'Luz', true),
            (r_org.id, 'paso_11', 'PASO 11', 'Pisos', 11, 'Pisos', true),
            (r_org.id, 'paso_12', 'PASO 12', 'Acabados y loderas', 12, 'Terminado', true),
            (r_org.id, 'extras', 'EXTRAS', 'Equipamiento adicional', 13, 'Extras', true),
            (r_org.id, 'llantas_rines', 'LLANTAS Y RINES', 'Rodado', 14, 'Rines y llantas', true)
        ON CONFLICT (organizacion_id, clave) DO UPDATE SET updated_at = now();

        -- Equivalencias
        INSERT INTO fases_despiece_equivalencias (organizacion_id, paso_legacy, fase_id, notas)
        SELECT r_org.id, fe.paso_legacy, fd.id, 'Equivalencia prueba'
        FROM (VALUES
            ('PASO 1', 'paso_1'), ('PASO 2', 'paso_2'), ('PASO 3', 'paso_3'),
            ('PASO 4', 'paso_4'), ('PASO 5', 'paso_5'), ('PASO 6', 'paso_6'),
            ('PASO 7', 'paso_7'), ('LIMPIEZA', 'paso_7'),
            ('PASO 8', 'paso_8'), ('PINTURA', 'paso_8'),
            ('PASO 9', 'paso_9'), ('AIRE', 'paso_9'),
            ('PASO 10', 'paso_10'), ('LUZ', 'paso_10'),
            ('PASO 11', 'paso_11'), ('PISOS', 'paso_11'),
            ('PASO 12', 'paso_12'), ('TERMINADO', 'paso_12'),
            ('EXTRAS', 'extras'), ('LLANTAS Y RINES', 'llantas_rines'),
            ('LLANTAS', 'llantas_rines'), ('RINES', 'llantas_rines')
        ) AS fe(paso_legacy, clave_fase)
        JOIN fases_despiece fd ON fd.organizacion_id = r_org.id AND fd.clave = fe.clave_fase
        ON CONFLICT (organizacion_id, paso_legacy) DO NOTHING;

        -- Bloque D: Resolucion de acero por nombre exacto (CERO UUIDs)
        FOR r_acero IN
            SELECT * FROM (VALUES
                ('paso_1', 'ALMA (PLACA DE GRADO A-50 CAL. 1/4")'),
                ('paso_2', 'SOLERA DE ALMA (SOLERA DE GRADO A-529 A 1/2" X 6")'),
                ('paso_3', 'BORDA DELANTERA (PLACA DE GRADO A-36 CAL. 3/16")'),
                ('paso_3', 'BORDA TRASERA (PLACA DE GRADO A-36 CAL. 3/16")'),
                ('paso_3', 'PUENTES DE SUSPENSIÓN (PTR A 2 X 6")'),
                ('paso_3', 'PLANCHA PARA LA QUINTA (PLACA DE GRADO A-36 CAL. 3/8")'),
                ('paso_3', 'PUENTES TIPO J (PLACA DE GRADO A-36 CAL. 3/16")'),
                ('paso_3', 'PUENTES DE LA PLANCHA (CANAL U 5")'),
                ('paso_3', 'BOTONES (PLACA DE GRADO A-36 CAL. 1/4")'),
                ('paso_3', 'ATIZADORES INTERNOS (PLACA DE GRADO A-36 CAL. 1/4")'),
                ('paso_3', 'ATIZADORES EXTERNOS 27 CM (SOLERA DE GRADO A-36 A 3/8" X 2")'),
                ('paso_3', 'ATIZADORES EXTERNOS 29CM'),
                ('paso_3', 'JALON (PLACA DE GRADO A-36 CAL. 1/2")'),
                ('paso_3', 'REFUERZO DE JALON (PLACA DE GRADO A-36 CAL. 3/8")'),
                ('paso_3', 'PERNO REY (PERNO REY HOLLAND 3/8")'),
                ('paso_3', 'TAPA PARA PERNO REY (CANAL U 6")'),
                ('paso_4', 'KIT DE ALETAS 27 X 50 CM (PLACA DE GRADO A-36 CAL. 10)'),
                ('paso_4', 'KIT DE ALETAS 27 X 60 CM'),
                ('paso_4', 'KIT DE ALETAS 40 X 50 CM'),
                ('paso_4', 'KIT DE ALETAS 40 X 60 CM'),
                ('paso_4', 'KIT DE ALETAS 45 X 50 CM'),
                ('paso_4', 'KIT DE ALETAS 45 X 60 CM'),
                ('paso_4', 'ESQUINERO DELANTERO (PLACA DE GRADO A-36 CAL. 1/4")'),
                ('paso_4', 'ESQUINERO TRASERO (PLACA DE GRADO A-36 CAL. 1/4")'),
                ('paso_4', 'BUCHACAS (PLACA DE GRADO A-36 CAL. 1/4")'),
                ('paso_4', 'TUBOS LATERALES (TUBO DE 1 1/4" CED. 40)'),
                ('paso_4', 'BASE PARA ESTRIBO PLACA TRASERA (PLACA DE GRADO A-36 CAL. 1/4")'),
                ('paso_4', 'BASE PARA ESTRIBO PLACA FRONTAL (PLACA DE GRADO A-36 CAL. 1/4")'),
                ('paso_4', 'BASE PARA ESTRIBO PLACA INTERMEDIA (PLACA DE GRADO A-36 CAL. 1/4")'),
                ('paso_4', 'CARGADOR (IPR DE 4")'),
                ('paso_4', 'BORDAS LATERALES (CANAL U 6")'),
                ('paso_5', 'BASE PARA TANQUES (PLACA DE GRADO A-36 CAL. 1/4")'),
                ('paso_5', 'BASE PARA PATINES PLACAS (PLACA DE GRADO A-36 CAL. 1/4")'),
                ('paso_5', 'BASE PARA PATINES SOLERA (SOLERA DE GRADO A-36 A 3/8" X 2")'),
                ('paso_5', 'BASE PARA MANITAS (PLACA DE GRADO A-36 CAL. 1/4")'),
                ('paso_5', 'BASE PARA PERCHAS (SOLERA DE GRADO A-36 A 1/2" X 6")'),
                ('paso_5', 'BASE PARA PLATOS (SOLERA DE GRADO A-36 A 1/2" X 3")'),
                ('paso_5', 'PESTAÑAS (PLACA DE GRADO A-36 CAL. 1/4")'),
                ('paso_5', 'GANCHOS (REDONDO DE 1/2")'),
                ('paso_5', 'PLAFONES OVALADOS (PLACA DE GRADO A-36 CAL. 1/4")'),
                ('paso_5', 'CARTABONES PARA JALON (PLACA DE GRADO A-36 CAL. 3/8")'),
                ('paso_5', 'SOLERA PARA ESQUINEROS (PLACA DE GRADO A-36 CAL. 3/16")'),
                ('paso_6', 'U PARA JALON (REDONDO DE 1")'),
                ('paso_6', 'BASE PARA FOCO DE ABS (PLACA DE GRADO A-36 CAL. 1/4")'),
                ('paso_6', 'BASE PARA ABS (PLACA DE GRADO A-36 CAL. 1/4")'),
                ('paso_6', 'PORTA PLACAS (PLACA DE GRADO A-36 CAL. 10)'),
                ('paso_6', 'CINCHO (SOLERA DE GRADO A-36 A 3/8" X 2")'),
                ('paso_6', 'HERAJE PARA PATINES 110CM (PLACA DE GRADO A-36 CAL. 3/16")'),
                ('paso_6', 'HERAJE PARA PATINES 125CM'),
                ('paso_6', 'HERAJE PARA PATINES 70CM'),
                ('paso_6', 'HERAJE PARA PATINES 67CM'),
                ('paso_6', 'HERAJE PARA PATINES 23CM'),
                ('paso_6', 'HERAJE PARA PATINES 7CM (SOLERA DE GRADO A-36 A 1/2" X 3")'),
                ('paso_6', 'HERAJE PARA PATINES 27CM'),
                ('paso_6', 'HERAJE PARA PATINES 30CM'),
                ('paso_6', 'HERAJE PARA PATINES BUCHACA (PLACA DE GRADO A-36 CAL. 1/4")'),
                ('paso_6', 'PORTA LLANTAS (PLACA DE GRADO A-36 CAL. 1/4")'),
                ('paso_6', 'PORTA LLANTAS (PLACA DE GRADO A-36 CAL. 1/4") #2'),
                ('paso_6', 'PORTA LLANTAS (SOLERA DE GRADO A-36 A 1/2" X 3")'),
                ('paso_6', 'ESTRIBO (PTR DE 4X4" A 6.10M)'),
                ('paso_6', 'PORTA LODERAS (PLACA DE GRADO A-36 CAL. 12)')
            ) AS t(fase_clave, producto_nombre)
        LOOP
            SELECT id INTO v_target_fase_id
            FROM fases_despiece
            WHERE organizacion_id = r_org.id AND clave = r_acero.fase_clave;

            IF v_target_fase_id IS NULL THEN
                RAISE EXCEPTION 'Fase % no encontrada para org %', r_acero.fase_clave, r_org.id;
            END IF;

            SELECT count(*), min(id) INTO v_mat_count, v_mat_id
            FROM productos
            WHERE organizacion_id = r_org.id
              AND nombre = r_acero.producto_nombre
              AND tipo_item = 'materia_prima';

            IF v_mat_count = 0 THEN
                RAISE EXCEPTION 'Producto no encontrado: % (org: %)', r_acero.producto_nombre, r_org.id;
            ELSIF v_mat_count > 1 THEN
                RAISE EXCEPTION 'Producto ambiguo (%): % (org: %)', v_mat_count, r_acero.producto_nombre, r_org.id;
            END IF;

            UPDATE receta_base rb
            SET fase_id = v_target_fase_id
            FROM modelos m
            WHERE rb.modelo_id = m.id
              AND m.organizacion_id = r_org.id
              AND m.tipo = 'plataforma'
              AND rb.material_id = v_mat_id
              AND (rb.fase_id IS NULL OR rb.fase_id != v_target_fase_id);
        END LOOP;

        -- Bloque E: Equivalencias
        UPDATE receta_base rb
        SET fase_id = fe.fase_id
        FROM fases_despiece_equivalencias fe, modelos m
        WHERE m.id = rb.modelo_id
          AND m.tipo = 'plataforma'
          AND fe.organizacion_id = r_org.id
          AND m.organizacion_id = r_org.id
          AND upper(trim(rb.paso)) = upper(trim(fe.paso_legacy))
          AND (rb.fase_id IS NULL OR rb.fase_id != fe.fase_id);

    END LOOP;
END $$;

-- 6. VERIFICAR QUE AMBAS ORGANIZACIONES (A Y B) TIENEN CERO LÍNEAS DE PLATAFORMA SIN FASE
DO $$
DECLARE
    v_sin_fase_a INT;
    v_sin_fase_b INT;
    v_total_a INT;
    v_total_b INT;
BEGIN
    SELECT count(*), count(*) FILTER (WHERE rb.fase_id IS NULL)
    INTO v_total_a, v_sin_fase_a
    FROM receta_base rb
    JOIN modelos m ON m.id = rb.modelo_id
    WHERE m.organizacion_id = '00000000-0000-0000-0000-000000000001' AND m.tipo = 'plataforma' AND m.largo_ft = 40 AND m.num_ejes = 2;

    SELECT count(*), count(*) FILTER (WHERE rb.fase_id IS NULL)
    INTO v_total_b, v_sin_fase_b
    FROM receta_base rb
    JOIN modelos m ON m.id = rb.modelo_id
    WHERE m.organizacion_id = '00000000-0000-0000-0000-000000000002' AND m.tipo = 'plataforma' AND m.largo_ft = 40 AND m.num_ejes = 2;

    IF v_sin_fase_a <> 0 THEN
        RAISE EXCEPTION 'Org A fallo: % lineas sin fase_id', v_sin_fase_a;
    END IF;

    IF v_sin_fase_b <> 0 THEN
        RAISE EXCEPTION 'Org B fallo: % lineas sin fase_id con UUIDs clonados', v_sin_fase_b;
    END IF;

    IF v_total_a <> 202 OR v_total_b <> 202 THEN
        RAISE EXCEPTION 'Totales incorrectos: Org A=%, Org B=% (esperado 202)', v_total_a, v_total_b;
    END IF;

    RAISE NOTICE 'PRUEBA MULTI-ORG RESOLUCION POR NOMBRE: EXITOSA (Org A: 202/202 con fase, Org B: 202/202 con fase)';
END $$;

-- 7. VERIFICAR RLS CON SET LOCAL ROLE authenticated
SET LOCAL ROLE authenticated;
SET LOCAL request.jwt.claim.sub = 'a988611b-2949-4ab7-b670-daf4a21f4e18';

DO $$
DECLARE
    v_count INT;
    v_error_disparado BOOLEAN := false;
BEGIN
    SELECT count(*) INTO v_count FROM fases_despiece;
    IF v_count <> 14 THEN
        RAISE EXCEPTION 'RLS Fallo: Usuario A debio ver 14 fases de Org A pero vio %', v_count;
    END IF;

    BEGIN
        INSERT INTO fases_despiece (organizacion_id, clave, nombre, orden)
        VALUES ('00000000-0000-0000-0000-000000000001', 'hack_fase', 'Fase Inyectada', 99);
    EXCEPTION WHEN OTHERS THEN
        v_error_disparado := true;
    END;

    IF NOT v_error_disparado THEN
        RAISE EXCEPTION 'RLS Fallo: Usuario authenticated pudo insertar en fases_despiece';
    END IF;

    RAISE NOTICE 'PRUEBA RLS USUARIO A (SELECT AISLADO 14 FASES + BLOQUEO INSERT): EXITOSA';
END $$;

SET LOCAL request.jwt.claim.sub = '00000000-0000-0000-0000-0000000000b2';

DO $$
DECLARE
    v_count INT;
BEGIN
    SELECT count(*) INTO v_count FROM fases_despiece;
    IF v_count <> 14 THEN
        RAISE EXCEPTION 'RLS Fallo: Usuario B debio ver 14 fases de Org B pero vio %', v_count;
    END IF;

    RAISE NOTICE 'PRUEBA RLS USUARIO B (AISLAMIENTO TOTAL RESPECTO A ORG A): EXITOSA';
END $$;

RESET ROLE;

ROLLBACK;
