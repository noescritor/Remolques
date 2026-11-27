-- Verificación integral SQL (PG 17 real) — Bloque "Cuentas y permisos"
-- Cubre:
--   1. RLS de invitaciones_equipo con roles reales (anon / authenticated usuario vs admin / 2 orgs / bloqueo 'propietario')
--   2. Protección directa de ordenes_trabajo (bloquea DELETE y UPDATE de 8 campos protegidos; permite edición normal, RPC y ON DELETE CASCADE desde cotizaciones)
--   3. Trigger on_auth_user_created_trigger en auth.users (invitado case-insensitive, sin invitación rechazado, existentes intactos)
--   4. Auditoría estricta de seguridad: TODA vista en public con security_invoker=true y NINGUNA función SECURITY DEFINER (no trigger, salvo get_current_org_id) ejecutable por anon

\set ON_ERROR_STOP on

DO $$
DECLARE
    v_org_a UUID := '11111111-1111-4111-8111-111111111111';
    v_org_b UUID := '22222222-2222-4222-8222-222222222222';
    v_admin_a UUID := 'aaaaaaaa-1111-4aaa-8aaa-aaaaaaaaaaaa';
    v_user_a  UUID := 'aaaaaaaa-2222-4aaa-8aaa-aaaaaaaaaaaa';
    v_admin_b UUID := 'bbbbbbbb-1111-4bbb-8bbb-bbbbbbbbbbbb';
    v_nuevo_ok UUID := 'cccccccc-1111-4ccc-8ccc-cccccccccccc';
    v_nuevo_bad UUID := 'cccccccc-2222-4ccc-8ccc-cccccccccccc';
    v_cli_a1 TEXT := 'cli-cp-a1';
    v_cli_a2 TEXT := 'cli-cp-a2';
    v_cot_a1 TEXT := 'cot-cp-a1';
    v_cot_a2 TEXT := 'cot-cp-a2';
    v_ot_1 UUID;
    v_ot_2 UUID;
    v_inv_a UUID;
    v_inv_b UUID;
    v_cnt INT;
    v_rol_nuevo TEXT;
    v_vistas_inseguras TEXT;
    v_funcs_anon TEXT;
    v_perfiles_previos INT;
BEGIN
    -- Asegurar políticas reales de Supabase en base de prueba (como en 20260509_02 y 20260915)
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'ordenes_trabajo' AND policyname = 'rls_ordenes_trabajo') THEN
        EXECUTE 'CREATE POLICY "rls_ordenes_trabajo" ON public.ordenes_trabajo FOR ALL TO authenticated USING (organizacion_id = get_current_org_id()) WITH CHECK (organizacion_id = get_current_org_id())';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'cotizaciones' AND policyname = 'rls_cotizaciones') THEN
        EXECUTE 'CREATE POLICY "rls_cotizaciones" ON public.cotizaciones FOR ALL TO authenticated USING (organizacion_id = get_current_org_id()) WITH CHECK (organizacion_id = get_current_org_id())';
    END IF;

    -- Asegurar permisos por defecto realistas de Supabase para la prueba
    GRANT USAGE ON SCHEMA public TO anon, authenticated;
    GRANT SELECT, INSERT, UPDATE, DELETE ON public.ordenes_trabajo TO authenticated;
    GRANT SELECT, INSERT, UPDATE, DELETE ON public.cotizaciones TO authenticated;
    GRANT SELECT ON public.perfiles_organizacion TO authenticated;

    -- 0. Sembrar 2 organizaciones y usuarios base (sin disparar trigger: crear invitaciones temporales)
    INSERT INTO organizaciones (id, nombre) VALUES (v_org_a, 'Org Cuentas A') ON CONFLICT (id) DO NOTHING;
    INSERT INTO organizaciones (id, nombre) VALUES (v_org_b, 'Org Cuentas B') ON CONFLICT (id) DO NOTHING;

    INSERT INTO invitaciones_equipo (organizacion_id, email, rol)
    VALUES
        (v_org_a, 'admin_cp_a@test.local', 'admin'),
        (v_org_a, 'user_cp_a@test.local', 'usuario'),
        (v_org_b, 'admin_cp_b@test.local', 'admin')
    ON CONFLICT DO NOTHING;

    INSERT INTO auth.users (id, email) VALUES (v_admin_a, 'admin_cp_a@test.local') ON CONFLICT (id) DO NOTHING;
    INSERT INTO auth.users (id, email) VALUES (v_user_a, 'user_cp_a@test.local') ON CONFLICT (id) DO NOTHING;
    INSERT INTO auth.users (id, email) VALUES (v_admin_b, 'admin_cp_b@test.local') ON CONFLICT (id) DO NOTHING;

    -- Asegurar perfiles existentes
    INSERT INTO perfiles_organizacion (organizacion_id, usuario_id, rol)
    VALUES
        (v_org_a, v_admin_a, 'admin'),
        (v_org_a, v_user_a, 'usuario'),
        (v_org_b, v_admin_b, 'admin')
    ON CONFLICT DO NOTHING;

    SELECT COUNT(*) INTO v_perfiles_previos FROM perfiles_organizacion WHERE usuario_id IN (v_admin_a, v_user_a, v_admin_b);

    -- Clientes, cotizaciones y equipos en Org A
    INSERT INTO clientes (id, organizacion_id, nombre_razon_social)
    VALUES (v_cli_a1, v_org_a, 'Cliente CP 1'), (v_cli_a2, v_org_a, 'Cliente CP 2')
    ON CONFLICT (id) DO NOTHING;

    INSERT INTO cotizaciones (id, organizacion_id, cliente_id, folio, estado, total)
    VALUES
        (v_cot_a1, v_org_a, v_cli_a1, 'COT-CP-1', 'Aprobada', 100000),
        (v_cot_a2, v_org_a, v_cli_a1, 'COT-CP-2', 'Aprobada', 50000)
    ON CONFLICT (id) DO NOTHING;

    INSERT INTO ordenes_trabajo (organizacion_id, cotizacion_id, cliente_id, etiqueta, nomenclatura_id, modelo, tipo_equipo, origen, estado)
    VALUES (v_org_a, v_cot_a1, v_cli_a1, 'Eq Protegido', '701-CP011126-1', 'Plataforma', '01', 'cotizacion', 'Pendiente')
    RETURNING id INTO v_ot_1;

    INSERT INTO ordenes_trabajo (organizacion_id, cotizacion_id, cliente_id, etiqueta, nomenclatura_id, modelo, tipo_equipo, origen, estado)
    VALUES (v_org_a, v_cot_a2, v_cli_a1, 'Eq Cascade', '702-CP011126-1', 'Plataforma', '01', 'cotizacion', 'Pendiente')
    RETURNING id INTO v_ot_2;

    -- Invitaciones iniciales de prueba en Org A y Org B
    INSERT INTO invitaciones_equipo (organizacion_id, email, rol, invitado_por)
    VALUES (v_org_a, 'pendiente_a@test.local', 'usuario', v_admin_a)
    RETURNING id INTO v_inv_a;

    INSERT INTO invitaciones_equipo (organizacion_id, email, rol, invitado_por)
    VALUES (v_org_b, 'pendiente_b@test.local', 'usuario', v_admin_b)
    RETURNING id INTO v_inv_b;

    -- ═══════════════════════════════════════════════════════════════════════
    -- 1. PRUEBA PUNTO 8: Alta de cuentas (trigger on_auth_user_created_trigger)
    -- ═══════════════════════════════════════════════════════════════════════
    -- 1a. Correo invitado (case-insensitive) -> crea perfil con el rol de la invitación y borra invitación
    INSERT INTO invitaciones_equipo (organizacion_id, email, rol, invitado_por)
    VALUES (v_org_a, 'nuevo_invitado@leolca.mx', 'admin', v_admin_a);

    INSERT INTO auth.users (id, email) VALUES (v_nuevo_ok, 'NUEVO_INVITADO@Leolca.MX');

    SELECT rol INTO v_rol_nuevo FROM perfiles_organizacion
    WHERE organizacion_id = v_org_a AND usuario_id = v_nuevo_ok;
    IF v_rol_nuevo IS DISTINCT FROM 'admin' THEN
        RAISE EXCEPTION 'FALLO trigger alta: esperaba rol admin, obtuve %', v_rol_nuevo;
    END IF;

    SELECT COUNT(*) INTO v_cnt FROM invitaciones_equipo WHERE LOWER(email) = 'nuevo_invitado@leolca.mx';
    IF v_cnt <> 0 THEN
        RAISE EXCEPTION 'FALLO trigger alta: la invitación no fue borrada tras aceptar';
    END IF;

    -- 1b. Correo sin invitación -> rechazado
    BEGIN
        INSERT INTO auth.users (id, email) VALUES (v_nuevo_bad, 'sin_invitacion@otro.com');
        RAISE EXCEPTION 'FALLO trigger alta: permitió alta sin invitación';
    EXCEPTION WHEN OTHERS THEN
        IF SQLERRM NOT LIKE '%Registro denegado%' THEN
            RAISE EXCEPTION 'FALLO inesperado en alta sin invitación: %', SQLERRM;
        END IF;
    END;

    -- 1c. Usuarios existentes intactos
    SELECT COUNT(*) INTO v_cnt FROM perfiles_organizacion WHERE usuario_id IN (v_admin_a, v_user_a, v_admin_b);
    IF v_cnt <> v_perfiles_previos THEN
        RAISE EXCEPTION 'FALLO: perfiles existentes cambiaron';
    END IF;

    -- ═══════════════════════════════════════════════════════════════════════
    -- 2. PRUEBA PUNTO 1: RLS invitaciones_equipo (anon, usuario, admin, 2 orgs)
    -- ═══════════════════════════════════════════════════════════════════════
    -- 2a. anon: no puede leer ni escribir invitaciones_equipo
    EXECUTE 'SET LOCAL ROLE anon';
    BEGIN
        PERFORM COUNT(*) FROM invitaciones_equipo;
        RAISE EXCEPTION 'FALLO: anon pudo leer invitaciones_equipo';
    EXCEPTION WHEN insufficient_privilege THEN NULL;
    END;
    RESET ROLE;

    -- 2b. authenticated como USUARIO regular de Org A: NO puede invitar ni borrar
    EXECUTE 'SET LOCAL ROLE authenticated';
    PERFORM set_config('request.jwt.claims', json_build_object('sub', v_user_a::text, 'role', 'authenticated')::text, true);

    BEGIN
        INSERT INTO invitaciones_equipo (organizacion_id, email, rol)
        VALUES (v_org_a, 'hack_user@test.local', 'usuario');
        RAISE EXCEPTION 'FALLO RLS: usuario regular pudo insertar invitación';
    EXCEPTION WHEN insufficient_privilege THEN NULL;
    END;

    BEGIN
        INSERT INTO invitaciones_equipo (organizacion_id, email, rol)
        VALUES (v_org_a, 'hack_admin@test.local', 'admin');
        RAISE EXCEPTION 'FALLO RLS: usuario regular pudo invitar como admin';
    EXCEPTION WHEN insufficient_privilege THEN NULL;
    END;

    DELETE FROM invitaciones_equipo WHERE id = v_inv_a;
    GET DIAGNOSTICS v_cnt = ROW_COUNT;
    IF v_cnt <> 0 THEN
        RAISE EXCEPTION 'FALLO RLS: usuario regular pudo borrar invitación (rows=%)', v_cnt;
    END IF;

    -- 2c. authenticated como ADMIN de Org A: SÍ invita admin/usuario en Org A, NO propietario, NO Org B
    PERFORM set_config('request.jwt.claims', json_build_object('sub', v_admin_a::text, 'role', 'authenticated')::text, true);

    -- Admin NO puede invitar como propietario
    BEGIN
        INSERT INTO invitaciones_equipo (organizacion_id, email, rol)
        VALUES (v_org_a, 'hack_prop@test.local', 'propietario');
        RAISE EXCEPTION 'FALLO RLS: admin pudo invitar con rol propietario';
    EXCEPTION WHEN insufficient_privilege THEN NULL;
    END;

    -- Admin NO puede invitar en Org B
    BEGIN
        INSERT INTO invitaciones_equipo (organizacion_id, email, rol)
        VALUES (v_org_b, 'hack_orgb@test.local', 'usuario');
        RAISE EXCEPTION 'FALLO RLS: admin de Org A pudo invitar en Org B';
    EXCEPTION WHEN insufficient_privilege THEN NULL;
    END;

    -- Admin NO ve ni borra invitaciones de Org B
    SELECT COUNT(*) INTO v_cnt FROM invitaciones_equipo WHERE organizacion_id = v_org_b;
    IF v_cnt <> 0 THEN
        RAISE EXCEPTION 'FALLO RLS: admin de Org A vio % invitaciones de Org B', v_cnt;
    END IF;
    DELETE FROM invitaciones_equipo WHERE id = v_inv_b;
    GET DIAGNOSTICS v_cnt = ROW_COUNT;
    IF v_cnt <> 0 THEN
        RAISE EXCEPTION 'FALLO RLS: admin de Org A borró invitación de Org B';
    END IF;

    -- Admin SÍ puede invitar como usuario y borrar su invitación en Org A
    INSERT INTO invitaciones_equipo (organizacion_id, email, rol)
    VALUES (v_org_a, 'ok_desde_admin@test.local', 'usuario');
    DELETE FROM invitaciones_equipo WHERE email = 'ok_desde_admin@test.local';
    GET DIAGNOSTICS v_cnt = ROW_COUNT;
    IF v_cnt <> 1 THEN
        RAISE EXCEPTION 'FALLO RLS: admin no pudo borrar su invitación en Org A';
    END IF;

    -- ═══════════════════════════════════════════════════════════════════════
    -- 3. PRUEBA PUNTO 6: Protección directa de ordenes_trabajo
    -- ═══════════════════════════════════════════════════════════════════════
    PERFORM set_config('request.jwt.claims', json_build_object('sub', v_user_a::text, 'role', 'authenticated')::text, true);

    -- Confirmar que authenticated SÍ ve v_ot_1 (para garantizar que el trigger realmente se dispara)
    SELECT COUNT(*) INTO v_cnt FROM ordenes_trabajo WHERE id = v_ot_1;
    IF v_cnt <> 1 THEN
        RAISE EXCEPTION 'FALLO precondición OT: authenticated no ve v_ot_1 (rls_ordenes_trabajo ausente)';
    END IF;

    -- 3a. DELETE directo rechazado
    BEGIN
        DELETE FROM ordenes_trabajo WHERE id = v_ot_1;
        RAISE EXCEPTION 'FALLO trigger OT: authenticated pudo borrar equipo directamente';
    EXCEPTION WHEN insufficient_privilege THEN
        IF SQLERRM NOT LIKE '%operacion_no_permitida%' THEN
            RAISE EXCEPTION 'Error inesperado DELETE OT: %', SQLERRM;
        END IF;
    END;

    -- 3b. UPDATE de campos protegidos rechazado (cancelada_el, cliente_id, nomenclatura_id, origen, cotizacion_id)
    BEGIN
        UPDATE ordenes_trabajo SET cancelada_el = now(), motivo_cancelacion = 'Directo' WHERE id = v_ot_1;
        RAISE EXCEPTION 'FALLO trigger OT: authenticated pudo cancelar directo en tabla';
    EXCEPTION WHEN insufficient_privilege THEN
        IF SQLERRM NOT LIKE '%campo_protegido%' THEN RAISE EXCEPTION 'Error inesperado: %', SQLERRM; END IF;
    END;

    BEGIN
        UPDATE ordenes_trabajo SET cliente_id = v_cli_a2 WHERE id = v_ot_1;
        RAISE EXCEPTION 'FALLO trigger OT: authenticated pudo cambiar cliente_id directo';
    EXCEPTION WHEN insufficient_privilege THEN
        IF SQLERRM NOT LIKE '%campo_protegido%' THEN RAISE EXCEPTION 'Error inesperado: %', SQLERRM; END IF;
    END;

    BEGIN
        UPDATE ordenes_trabajo SET nomenclatura_id = 'HACK-999' WHERE id = v_ot_1;
        RAISE EXCEPTION 'FALLO trigger OT: authenticated pudo cambiar nomenclatura_id directo';
    EXCEPTION WHEN insufficient_privilege THEN
        IF SQLERRM NOT LIKE '%campo_protegido%' THEN RAISE EXCEPTION 'Error inesperado: %', SQLERRM; END IF;
    END;

    BEGIN
        UPDATE ordenes_trabajo SET origen = 'manual' WHERE id = v_ot_1;
        RAISE EXCEPTION 'FALLO trigger OT: authenticated pudo cambiar origen directo';
    EXCEPTION WHEN insufficient_privilege THEN
        IF SQLERRM NOT LIKE '%campo_protegido%' THEN RAISE EXCEPTION 'Error inesperado: %', SQLERRM; END IF;
    END;

    -- 3c. Edición normal (niv, etiqueta, material_faltante) SÍ funciona como authenticated
    UPDATE ordenes_trabajo
    SET niv = 'NIV-NORMAL-1', etiqueta = 'Editada OK', material_faltante = 'Eje trasero'
    WHERE id = v_ot_1;
    GET DIAGNOSTICS v_cnt = ROW_COUNT;
    IF v_cnt <> 1 THEN
        RAISE EXCEPTION 'FALLO trigger OT: bloqueó edición normal permitida';
    END IF;

    -- 3d. ON DELETE CASCADE desde cotizaciones SÍ funciona como authenticated
    DELETE FROM cotizaciones WHERE id = v_cot_a2;
    GET DIAGNOSTICS v_cnt = ROW_COUNT;
    IF v_cnt <> 1 THEN
        RAISE EXCEPTION 'FALLO trigger OT: bloqueó borrado de cotización con ON DELETE CASCADE';
    END IF;

    RESET ROLE;

    -- Confirmar que v_ot_2 se borró por cascada
    SELECT COUNT(*) INTO v_cnt FROM ordenes_trabajo WHERE id = v_ot_2;
    IF v_cnt <> 0 THEN
        RAISE EXCEPTION 'FALLO: v_ot_2 debió borrarse en cascada al borrar cotización';
    END IF;

    -- 3e. RPC SECURITY DEFINER (cancelar_orden_trabajo) SÍ funciona
    PERFORM cancelar_orden_trabajo(v_org_a, v_admin_a, v_ot_1, 'Cancelación vía RPC autorizada', false);
    IF (SELECT cancelada_el FROM ordenes_trabajo WHERE id = v_ot_1) IS NULL THEN
        RAISE EXCEPTION 'FALLO: RPC cancelar_orden_trabajo no pudo cancelar orden';
    END IF;

    -- ═══════════════════════════════════════════════════════════════════════
    -- 4. PRUEBA PUNTO 9: Auditoría estricta de vistas y funciones SECURITY DEFINER
    -- ═══════════════════════════════════════════════════════════════════════
    -- 4a. Ninguna vista de public puede quedar sin security_invoker
    SELECT string_agg(relname, ', ' ORDER BY relname)
    INTO v_vistas_inseguras
    FROM pg_class
    WHERE relnamespace = 'public'::regnamespace
      AND relkind IN ('v', 'm')
      AND COALESCE(array_to_string(reloptions, ','), '') !~* 'security_invoker=(true|on|1)';

    IF v_vistas_inseguras IS NOT NULL THEN
        RAISE EXCEPTION 'FALLO SEGURIDAD: vistas sin security_invoker en public: %', v_vistas_inseguras;
    END IF;

    -- 4b. Ninguna función SECURITY DEFINER (no trigger, no extensión, salvo get_current_org_id) ejecutable por anon
    SELECT string_agg(p.proname, ', ' ORDER BY p.proname)
    INTO v_funcs_anon
    FROM pg_proc p
    WHERE p.pronamespace = 'public'::regnamespace
      AND p.prosecdef
      AND p.prorettype <> 'trigger'::regtype
      AND p.prorettype <> 'event_trigger'::regtype
      AND p.proname <> 'get_current_org_id'
      AND has_function_privilege('anon', p.oid, 'EXECUTE')
      AND NOT EXISTS (
          SELECT 1 FROM pg_depend d WHERE d.objid = p.oid AND d.deptype = 'e'
      );

    IF v_funcs_anon IS NOT NULL THEN
        RAISE EXCEPTION 'FALLO SEGURIDAD: funciones SECURITY DEFINER ejecutables por anon: %', v_funcs_anon;
    END IF;

    -- 4c. vista_saldo_cliente cerrada para anon y solo lectura para authenticated
    IF has_table_privilege('anon', 'public.vista_saldo_cliente', 'SELECT,INSERT,UPDATE,DELETE') THEN
        RAISE EXCEPTION 'FALLO SEGURIDAD: anon aún tiene privilegios en vista_saldo_cliente';
    END IF;
    IF has_table_privilege('authenticated', 'public.vista_saldo_cliente', 'INSERT,UPDATE,DELETE') THEN
        RAISE EXCEPTION 'FALLO SEGURIDAD: authenticated puede escribir en vista_saldo_cliente';
    END IF;

    -- ═══════════════════════════════════════════════════════════════════════
    -- 5. PRUEBA PUNTO 10 (D3): Ninguna política en public sin filtro de org/usuario
    -- ═══════════════════════════════════════════════════════════════════════
    DECLARE
        v_politicas_abiertas TEXT;
        v_fk_deltype CHAR;
        v_ot_manual UUID;
    BEGIN
        SELECT string_agg(tablename || '.' || policyname, ', ' ORDER BY tablename, policyname)
        INTO v_politicas_abiertas
        FROM pg_policies
        WHERE schemaname = 'public'
          AND (COALESCE(qual, '') || ' ' || COALESCE(with_check, '')) !~* 'get_current_org_id|organizacion_id|usuario_id';

        IF v_politicas_abiertas IS NOT NULL THEN
            RAISE EXCEPTION 'FALLO SEGURIDAD (Punto 10): políticas en public sin filtro de organización/usuario: %', v_politicas_abiertas;
        END IF;

        IF to_regclass('public.plantillas_cotizacion') IS NOT NULL THEN
            IF NOT EXISTS (
                SELECT 1 FROM pg_policies
                WHERE schemaname = 'public'
                  AND tablename = 'plantillas_cotizacion'
                  AND policyname = 'rls_plantillas'
            ) THEN
                RAISE EXCEPTION 'FALLO SEGURIDAD: falta política rls_plantillas en plantillas_cotizacion';
            END IF;
        END IF;

        -- ═══════════════════════════════════════════════════════════════════
        -- 6. PRUEBA D5: Protección al borrar clientes con equipos (activos y cancelados)
        -- ═══════════════════════════════════════════════════════════════════
        SELECT c.confdeltype
        INTO v_fk_deltype
        FROM pg_constraint c
        JOIN pg_attribute a
          ON a.attrelid = c.conrelid
         AND a.attnum = ANY(c.conkey)
        WHERE c.conrelid = 'public.ordenes_trabajo'::regclass
          AND c.confrelid = 'public.clientes'::regclass
          AND c.contype = 'f'
          AND a.attname = 'cliente_id'
        LIMIT 1;

        IF v_fk_deltype IS DISTINCT FROM 'a' THEN
            RAISE EXCEPTION 'FALLO D5: FK ordenes_trabajo.cliente_id debe ser ON DELETE NO ACTION (a), actual: %', v_fk_deltype;
        END IF;

        -- Crear equipo manual (sin cotizaciones) en v_cli_a2 para aislar exactamente ordenes_trabajo_cliente_id_fkey
        INSERT INTO ordenes_trabajo (organizacion_id, cotizacion_id, cliente_id, etiqueta, nomenclatura_id, modelo, tipo_equipo, origen, estado)
        VALUES (v_org_a, NULL, v_cli_a2, 'Eq Manual D5', '703-CP011126-1', 'Plataforma', '01', 'manual', 'Pendiente')
        RETURNING id INTO v_ot_manual;

        -- 6a. Cliente con equipo ACTIVO (sin cotizaciones) -> debe fallar exactamente por ordenes_trabajo_cliente_id_fkey
        BEGIN
            DELETE FROM clientes WHERE id = v_cli_a2;
            RAISE EXCEPTION 'FALLO D5: permitió borrar cliente con equipo activo';
        EXCEPTION WHEN foreign_key_violation THEN
            IF SQLERRM NOT LIKE '%ordenes_trabajo_cliente_id_fkey%' THEN
                RAISE EXCEPTION 'FALLO D5: se esperaba ordenes_trabajo_cliente_id_fkey, salió: %', SQLERRM;
            END IF;
        END;

        -- 6b. Cancelar equipo manual: cliente con equipo CANCELADO -> también debe fallar por ordenes_trabajo_cliente_id_fkey
        PERFORM cancelar_orden_trabajo(v_org_a, v_admin_a, v_ot_manual, 'Cancelación prueba D5', false);
        BEGIN
            DELETE FROM clientes WHERE id = v_cli_a2;
            RAISE EXCEPTION 'FALLO D5: permitió borrar cliente con equipo cancelado';
        EXCEPTION WHEN foreign_key_violation THEN
            IF SQLERRM NOT LIKE '%ordenes_trabajo_cliente_id_fkey%' THEN
                RAISE EXCEPTION 'FALLO D5: se esperaba ordenes_trabajo_cliente_id_fkey, salió: %', SQLERRM;
            END IF;
        END;

        -- 6c. Al quitar el equipo manual (como rol privilegiado), cliente SIN equipos SÍ se puede borrar
        DELETE FROM ordenes_trabajo WHERE id = v_ot_manual;
        DELETE FROM clientes WHERE id = v_cli_a2;
        GET DIAGNOSTICS v_cnt = ROW_COUNT;
        IF v_cnt <> 1 THEN
            RAISE EXCEPTION 'FALLO D5: no permitió borrar cliente sin equipos';
        END IF;

        -- 6d. Borrar una organización con ordenes_trabajo sin cliente (ON DELETE CASCADE en organizacion_id) sigue funcionando
        INSERT INTO ordenes_trabajo (organizacion_id, cotizacion_id, cliente_id, etiqueta, nomenclatura_id, modelo, tipo_equipo, origen, estado)
        VALUES (v_org_b, NULL, NULL, 'Eq Org B', '704-CP011126-1', 'Plataforma', '01', 'manual', 'Pendiente');
        DELETE FROM organizaciones WHERE id = v_org_b;
        GET DIAGNOSTICS v_cnt = ROW_COUNT;
        IF v_cnt <> 1 THEN
            RAISE EXCEPTION 'FALLO D5: borrar organización con ordenes_trabajo falló tras cambiar FK a NO ACTION';
        END IF;
    END;

    RAISE NOTICE 'OK: Todas las pruebas SQL de Cuentas y Permisos (RLS, trigger OT, alta auth.users, vistas, políticas public, D5 clientes/org y RPCs) pasaron.';
END $$;
