-- ============================================================
-- FIX: Reemplazar TODAS las políticas RLS con get_current_org_id()
-- Esta función es SECURITY DEFINER y bypasea RLS automáticamente
-- ============================================================

-- 1. Borrar TODAS las políticas actuales (las que usan subqueries problemáticas)

-- perfiles_organizacion
DROP POLICY IF EXISTS "Usuarios pueden ver perfiles de su org" ON perfiles_organizacion;
DROP POLICY IF EXISTS "Usuarios ven su propio perfil" ON perfiles_organizacion;

-- invitaciones_equipo
DROP POLICY IF EXISTS "Ver invitaciones de mi org" ON invitaciones_equipo;
DROP POLICY IF EXISTS "Admins pueden crear invitaciones" ON invitaciones_equipo;
DROP POLICY IF EXISTS "Admins pueden eliminar invitaciones" ON invitaciones_equipo;

-- tablas de negocio
DROP POLICY IF EXISTS "s_clientes" ON clientes;
DROP POLICY IF EXISTS "s_productos" ON productos;
DROP POLICY IF EXISTS "s_cotizaciones" ON cotizaciones;
DROP POLICY IF EXISTS "s_items" ON items_cotizacion;
DROP POLICY IF EXISTS "s_pagos" ON pagos;
DROP POLICY IF EXISTS "s_plantillas" ON plantillas_cotizacion;
DROP POLICY IF EXISTS "s_proyectos" ON proyectos;
DROP POLICY IF EXISTS "s_auditoria" ON auditoria;
DROP POLICY IF EXISTS "s_historial" ON historial_precios;

-- organizaciones
DROP POLICY IF EXISTS "Usuarios pueden ver sus organizaciones" ON organizaciones;

-- 2. Recrear TODAS usando get_current_org_id() (SECURITY DEFINER, sin RLS circular)

-- perfiles_organizacion: el usuario ve sus propios registros
CREATE POLICY "po_select" ON perfiles_organizacion 
  FOR SELECT TO authenticated 
  USING (usuario_id = auth.uid());

-- organizaciones
CREATE POLICY "org_select" ON organizaciones 
  FOR SELECT TO authenticated 
  USING (id = get_current_org_id());

-- invitaciones_equipo
CREATE POLICY "inv_select" ON invitaciones_equipo 
  FOR SELECT TO authenticated 
  USING (organizacion_id = get_current_org_id());

CREATE POLICY "inv_insert" ON invitaciones_equipo 
  FOR INSERT TO authenticated 
  WITH CHECK (organizacion_id = get_current_org_id());

CREATE POLICY "inv_delete" ON invitaciones_equipo 
  FOR DELETE TO authenticated 
  USING (organizacion_id = get_current_org_id());

-- clientes
CREATE POLICY "rls_clientes" ON clientes 
  FOR ALL TO authenticated 
  USING (organizacion_id = get_current_org_id()) 
  WITH CHECK (organizacion_id = get_current_org_id());

-- productos
CREATE POLICY "rls_productos" ON productos 
  FOR ALL TO authenticated 
  USING (organizacion_id = get_current_org_id()) 
  WITH CHECK (organizacion_id = get_current_org_id());

-- cotizaciones
CREATE POLICY "rls_cotizaciones" ON cotizaciones 
  FOR ALL TO authenticated 
  USING (organizacion_id = get_current_org_id()) 
  WITH CHECK (organizacion_id = get_current_org_id());

-- items_cotizacion
CREATE POLICY "rls_items" ON items_cotizacion 
  FOR ALL TO authenticated 
  USING (organizacion_id = get_current_org_id()) 
  WITH CHECK (organizacion_id = get_current_org_id());

-- pagos
CREATE POLICY "rls_pagos" ON pagos 
  FOR ALL TO authenticated 
  USING (organizacion_id = get_current_org_id()) 
  WITH CHECK (organizacion_id = get_current_org_id());

-- plantillas_cotizacion
CREATE POLICY "rls_plantillas" ON plantillas_cotizacion 
  FOR ALL TO authenticated 
  USING (organizacion_id = get_current_org_id()) 
  WITH CHECK (organizacion_id = get_current_org_id());

-- proyectos
CREATE POLICY "rls_proyectos" ON proyectos 
  FOR ALL TO authenticated 
  USING (organizacion_id = get_current_org_id()) 
  WITH CHECK (organizacion_id = get_current_org_id());

-- auditoria
CREATE POLICY "rls_auditoria" ON auditoria 
  FOR ALL TO authenticated 
  USING (organizacion_id = get_current_org_id()) 
  WITH CHECK (organizacion_id = get_current_org_id());

-- historial_precios
CREATE POLICY "rls_historial" ON historial_precios 
  FOR ALL TO authenticated 
  USING (organizacion_id = get_current_org_id()) 
  WITH CHECK (organizacion_id = get_current_org_id());
