-- Migración 20261127_02_cuentas_permisos.sql
-- Bloque: Cuentas y permisos
-- 1. RLS estricto en invitaciones_equipo (solo admin/propietario de la org; nunca rol 'propietario' desde esta vía)
-- 2. Protección contra escritura directa en ordenes_trabajo (trigger BEFORE UPDATE OR DELETE SECURITY INVOKER)
-- 3. Trigger de alta de cuentas en auth.users (on_auth_user_created versión 20260616 + trigger idempotente)
-- 4. Cierre de vista_saldo_cliente (security_invoker + REVOKE anon/public) y permisos de obtener_siguiente_produccion()

BEGIN;

-- ═══════════════════════════════════════════════════════════════════════════
-- 1. Helper de rol y RLS estricto en invitaciones_equipo
-- ═══════════════════════════════════════════════════════════════════════════
CREATE OR REPLACE FUNCTION public.es_admin_o_propietario_org(p_org UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.perfiles_organizacion
    WHERE organizacion_id = p_org
      AND usuario_id = auth.uid()
      AND LOWER(TRIM(rol)) IN ('admin', 'propietario')
  );
$$;

REVOKE ALL ON FUNCTION public.es_admin_o_propietario_org(UUID) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.es_admin_o_propietario_org(UUID) TO authenticated, service_role;

ALTER TABLE public.invitaciones_equipo ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Ver invitaciones de mi org" ON public.invitaciones_equipo;
DROP POLICY IF EXISTS "Admins pueden crear invitaciones" ON public.invitaciones_equipo;
DROP POLICY IF EXISTS "Admins pueden eliminar invitaciones" ON public.invitaciones_equipo;
DROP POLICY IF EXISTS "inv_select" ON public.invitaciones_equipo;
DROP POLICY IF EXISTS "inv_insert" ON public.invitaciones_equipo;
DROP POLICY IF EXISTS "inv_delete" ON public.invitaciones_equipo;

CREATE POLICY "inv_select" ON public.invitaciones_equipo
  FOR SELECT TO authenticated
  USING (organizacion_id = get_current_org_id());

-- Solo admin o propietario de la organización pueden invitar, y nunca con rol 'propietario' desde esta vía
CREATE POLICY "inv_insert" ON public.invitaciones_equipo
  FOR INSERT TO authenticated
  WITH CHECK (
    organizacion_id = get_current_org_id()
    AND public.es_admin_o_propietario_org(organizacion_id)
    AND LOWER(TRIM(COALESCE(rol, ''))) IN ('admin', 'usuario')
  );

-- Solo admin o propietario de la organización pueden borrar invitaciones
CREATE POLICY "inv_delete" ON public.invitaciones_equipo
  FOR DELETE TO authenticated
  USING (
    organizacion_id = get_current_org_id()
    AND public.es_admin_o_propietario_org(organizacion_id)
  );

REVOKE ALL ON public.invitaciones_equipo FROM PUBLIC, anon;
REVOKE UPDATE, TRUNCATE ON public.invitaciones_equipo FROM authenticated;
GRANT SELECT, INSERT, DELETE ON public.invitaciones_equipo TO authenticated;
GRANT ALL ON public.invitaciones_equipo TO service_role;

-- ═══════════════════════════════════════════════════════════════════════════
-- 2. Protección de ordenes_trabajo contra borrado o modificación directa
--    de campos protegidos desde authenticated/anon (SECURITY INVOKER)
-- ═══════════════════════════════════════════════════════════════════════════
CREATE OR REPLACE FUNCTION public.trg_proteger_ordenes_trabajo_directo()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_old_json JSONB;
  v_new_json JSONB;
BEGIN
  -- Solo restringe escrituras directas con rol authenticated o anon.
  -- Las RPC SECURITY DEFINER (owner), service_role y ON DELETE CASCADE desde cotizaciones
  -- corren bajo roles privilegiados y siguen funcionando con normalidad.
  IF current_user NOT IN ('authenticated', 'anon') THEN
    IF TG_OP = 'DELETE' THEN
      RETURN OLD;
    END IF;
    RETURN NEW;
  END IF;

  IF TG_OP = 'DELETE' THEN
    RAISE EXCEPTION 'operacion_no_permitida: No se pueden eliminar equipos directamente; utiliza la cancelación autorizada.'
      USING ERRCODE = '42501';
  END IF;

  IF TG_OP = 'UPDATE' THEN
    v_old_json := to_jsonb(OLD);
    v_new_json := to_jsonb(NEW);

    IF (v_old_json->>'cancelada_el') IS DISTINCT FROM (v_new_json->>'cancelada_el')
       OR (v_old_json->>'cancelada_por') IS DISTINCT FROM (v_new_json->>'cancelada_por')
       OR (v_old_json->>'motivo_cancelacion') IS DISTINCT FROM (v_new_json->>'motivo_cancelacion')
       OR OLD.cliente_id IS DISTINCT FROM NEW.cliente_id
       OR OLD.organizacion_id IS DISTINCT FROM NEW.organizacion_id
       OR OLD.cotizacion_id IS DISTINCT FROM NEW.cotizacion_id
       OR (v_old_json->>'origen') IS DISTINCT FROM (v_new_json->>'origen')
       OR OLD.nomenclatura_id IS DISTINCT FROM NEW.nomenclatura_id
    THEN
      RAISE EXCEPTION 'campo_protegido: No puedes modificar campos protegidos del equipo directamente.'
        USING ERRCODE = '42501';
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_proteger_ordenes_trabajo_directo ON public.ordenes_trabajo;
CREATE TRIGGER trg_proteger_ordenes_trabajo_directo
  BEFORE UPDATE OR DELETE ON public.ordenes_trabajo
  FOR EACH ROW
  EXECUTE FUNCTION public.trg_proteger_ordenes_trabajo_directo();

-- ═══════════════════════════════════════════════════════════════════════════
-- 3. Alta de cuentas: función on_auth_user_created (versión 20260616) + trigger
--    en auth.users (idempotente; no altera usuarios existentes)
-- ═══════════════════════════════════════════════════════════════════════════
CREATE OR REPLACE FUNCTION public.on_auth_user_created()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  invitacion RECORD;
BEGIN
  -- Buscar si el usuario fue invitado a alguna organización (insensible a mayúsculas/minúsculas)
  SELECT * INTO invitacion
  FROM public.invitaciones_equipo
  WHERE LOWER(email) = LOWER(NEW.email);

  IF FOUND THEN
    -- Si fue invitado, asignarlo a la organización con el rol definido
    INSERT INTO public.perfiles_organizacion (organizacion_id, usuario_id, rol)
    VALUES (invitacion.organizacion_id, NEW.id, invitacion.rol);

    -- Borrar la invitación una vez aceptada
    DELETE FROM public.invitaciones_equipo WHERE id = invitacion.id;
  ELSE
    -- Si no hay invitación, bloqueamos el registro
    RAISE EXCEPTION 'Registro denegado: El correo % no tiene una invitación activa.', NEW.email;
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created_trigger ON auth.users;
CREATE TRIGGER on_auth_user_created_trigger
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.on_auth_user_created();

-- ═══════════════════════════════════════════════════════════════════════════
-- 4. Cierre de vista_saldo_cliente y permisos de obtener_siguiente_produccion()
--    (idéntico a SQL_PARA_LUIS/2026-11-27-ACCESOS/1_cerrar_vista.sql)
-- ═══════════════════════════════════════════════════════════════════════════
ALTER VIEW public.vista_saldo_cliente SET (security_invoker = true);
REVOKE ALL ON public.vista_saldo_cliente FROM anon, public;
REVOKE INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER ON public.vista_saldo_cliente FROM authenticated;
REVOKE EXECUTE ON FUNCTION public.obtener_siguiente_produccion() FROM public, anon;
GRANT EXECUTE ON FUNCTION public.obtener_siguiente_produccion() TO authenticated, service_role;

COMMIT;
