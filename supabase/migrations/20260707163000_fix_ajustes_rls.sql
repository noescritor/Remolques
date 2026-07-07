-- Fix RLS policy on ajustes table to prevent leaking settings across organizations and resolve .single() queries failing
DROP POLICY IF EXISTS "Acceso total para usuarios autenticados en ajustes" ON ajustes;
DROP POLICY IF EXISTS "rls_ajustes" ON ajustes;

CREATE POLICY "rls_ajustes" ON ajustes
  FOR ALL TO authenticated
  USING (id = get_current_org_id())
  WITH CHECK (id = get_current_org_id());
