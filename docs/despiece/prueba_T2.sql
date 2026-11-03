-- Prueba transaccional de T2: Fases, equivalencias, asignación de árbol y aislamiento RLS con 2 organizaciones
-- Se ejecuta dentro de un bloque BEGIN ... ROLLBACK con SET LOCAL ROLE authenticated

BEGIN;

DO $$
DECLARE
    v_org_a UUID := '00000000-0000-0000-0000-000000000001';
    v_org_b UUID := '00000000-0000-0000-0000-000000000002';
    v_user_a UUID := 'a988611b-2949-4ab7-b670-daf4a21f4e18';
    v_user_b UUID := '00000000-0000-0000-0000-0000000000b2';
    v_count INT;
    v_cruzados INT;
BEGIN
    -- 1. Asegurar organización B de prueba
    INSERT INTO organizaciones (id, nombre, modulos)
    VALUES (v_org_b, 'Org de Prueba B (T2 Test)', '{"cotizador": true}')
    ON CONFLICT (id) DO NOTHING;

    -- 2. Asegurar usuario B y perfil de organización
    INSERT INTO auth.users (id, instance_id, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at)
    VALUES (
        v_user_b,
        '00000000-0000-0000-0000-000000000000',
        'usuario_b_t2@test.com',
        'password123',
        now(),
        '{"provider": "email", "providers": ["email"]}'::jsonb,
        '{}'::jsonb,
        now(),
        now()
    ) ON CONFLICT (id) DO NOTHING;

    INSERT INTO perfiles_organizacion (usuario_id, organizacion_id, rol)
    VALUES (v_user_b, v_org_b, 'usuario')
    ON CONFLICT (organizacion_id, usuario_id) DO NOTHING;

    -- 3. Poblar fases para Org B
    INSERT INTO fases_despiece (organizacion_id, clave, nombre, orden)
    VALUES 
        (v_org_b, 'paso_1', 'Paso 1', 1),
        (v_org_b, 'paso_2', 'Paso 2', 2),
        (v_org_b, 'paso_3', 'Paso 3', 3),
        (v_org_b, 'paso_4', 'Paso 4', 4),
        (v_org_b, 'paso_5', 'Paso 5', 5),
        (v_org_b, 'paso_6', 'Paso 6', 6),
        (v_org_b, 'paso_7', 'PASO 7', 7),
        (v_org_b, 'paso_8', 'PASO 8', 8),
        (v_org_b, 'paso_9', 'PASO 9', 9),
        (v_org_b, 'paso_10', 'PASO 10', 10),
        (v_org_b, 'paso_11', 'PASO 11', 11),
        (v_org_b, 'paso_12', 'PASO 12', 12),
        (v_org_b, 'extras', 'EXTRAS', 13),
        (v_org_b, 'llantas_rines', 'LLANTAS Y RINES', 14)
    ON CONFLICT (organizacion_id, clave) DO NOTHING;

    -- 4. Verificar que no exista fuga entre organizaciones en receta_base
    SELECT count(*) INTO v_cruzados
    FROM receta_base rb
    JOIN modelos m ON m.id = rb.modelo_id
    JOIN fases_despiece f ON f.id = rb.fase_id
    WHERE f.organizacion_id <> m.organizacion_id;

    IF v_cruzados > 0 THEN
        RAISE EXCEPTION 'Fuga entre organizaciones detectada en receta_base: % filas', v_cruzados;
    END IF;

    -- 5. Verificar que no exista fuga entre organizaciones en opcion_componentes
    SELECT count(*) INTO v_cruzados
    FROM opcion_componentes oc
    JOIN opciones_configuracion o ON o.id = oc.opcion_id
    JOIN fases_despiece f ON f.id = oc.fase_id
    WHERE f.organizacion_id <> o.organizacion_id;

    IF v_cruzados > 0 THEN
        RAISE EXCEPTION 'Fuga entre organizaciones detectada en opcion_componentes: % filas', v_cruzados;
    END IF;

    RAISE NOTICE 'VALIDACION ESTRUCTURAL DE TENANTS: EXITOSA';
END $$;

-- 6. PRUEBA DE POLÍTICA RLS CON ROLE authenticated Y JWT DE USUARIO A
SET LOCAL ROLE authenticated;
SET LOCAL request.jwt.claim.sub = 'a988611b-2949-4ab7-b670-daf4a21f4e18';

DO $$
DECLARE
    v_count INT;
    v_error_disparado BOOLEAN := false;
BEGIN
    -- Debe ver exactamente las 14 fases de Org A
    SELECT count(*) INTO v_count FROM fases_despiece;
    IF v_count <> 14 THEN
        RAISE EXCEPTION 'RLS Fallo: Usuario A debio ver 14 fases de Org A pero vio %', v_count;
    END IF;

    -- Debe tener prohibido el INSERT (sólo SELECT está permitido para authenticated)
    BEGIN
        INSERT INTO fases_despiece (organizacion_id, clave, nombre, orden)
        VALUES ('00000000-0000-0000-0000-000000000001', 'hack_fase', 'Fase Inyectada', 99);
    EXCEPTION WHEN OTHERS THEN
        v_error_disparado := true;
    END;

    IF NOT v_error_disparado THEN
        RAISE EXCEPTION 'RLS Fallo: Usuario authenticated pudo insertar en fases_despiece cuando solo tiene SELECT';
    END IF;

    RAISE NOTICE 'PRUEBA RLS USUARIO A (SELECT AISLADO + BLOQUEO DE INSERT): EXITOSA';
END $$;

-- 7. PRUEBA DE POLÍTICA RLS CON ROLE authenticated Y JWT DE USUARIO B
SET LOCAL request.jwt.claim.sub = '00000000-0000-0000-0000-0000000000b2';

DO $$
DECLARE
    v_count INT;
BEGIN
    -- Debe ver exactamente las 14 fases de Org B y CERO fases de Org A
    SELECT count(*) INTO v_count FROM fases_despiece;
    IF v_count <> 14 THEN
        RAISE EXCEPTION 'RLS Fallo: Usuario B debio ver 14 fases de Org B pero vio %', v_count;
    END IF;

    RAISE NOTICE 'PRUEBA RLS USUARIO B (AISLAMIENTO TOTAL RESPECTO A ORG A): EXITOSA';
END $$;

RESET ROLE;

ROLLBACK;
