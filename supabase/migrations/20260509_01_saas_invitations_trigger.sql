-- ============================================================
-- SAAS MULTI-TENANT: INVITACIONES Y TRIGGERS DE AUTH
-- ============================================================

-- 1. Crear tabla de invitaciones (Pre-registro)
CREATE TABLE IF NOT EXISTS invitaciones_equipo (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organizacion_id UUID NOT NULL REFERENCES organizaciones(id) ON DELETE CASCADE,
  email TEXT NOT NULL,
  rol TEXT CHECK (rol IN ('propietario', 'admin', 'usuario')) DEFAULT 'usuario',
  invitado_por UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(organizacion_id, email)
);

-- RLS para invitaciones: los usuarios de una organización pueden ver sus invitaciones
ALTER TABLE invitaciones_equipo ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Ver invitaciones de mi org" ON invitaciones_equipo 
  FOR SELECT TO authenticated 
  USING (organizacion_id IN (SELECT organizacion_id FROM perfiles_organizacion WHERE usuario_id = auth.uid()));

CREATE POLICY "Admins pueden crear invitaciones" ON invitaciones_equipo 
  FOR INSERT TO authenticated 
  WITH CHECK (
    organizacion_id IN (
      SELECT organizacion_id FROM perfiles_organizacion 
      WHERE usuario_id = auth.uid() AND rol IN ('propietario', 'admin')
    )
  );

CREATE POLICY "Admins pueden eliminar invitaciones" ON invitaciones_equipo 
  FOR DELETE TO authenticated 
  USING (
    organizacion_id IN (
      SELECT organizacion_id FROM perfiles_organizacion 
      WHERE usuario_id = auth.uid() AND rol IN ('propietario', 'admin')
    )
  );

-- 2. Trigger en auth.users para asignar usuarios al registrarse
CREATE OR REPLACE FUNCTION on_auth_user_created()
RETURNS TRIGGER AS $$
DECLARE
  invitacion RECORD;
BEGIN
  -- Buscar si el usuario fue invitado a alguna organización
  SELECT * INTO invitacion FROM invitaciones_equipo WHERE email = NEW.email;

  IF FOUND THEN
    -- Si fue invitado, asignarlo a la organización con el rol definido
    INSERT INTO perfiles_organizacion (organizacion_id, usuario_id, rol)
    VALUES (invitacion.organizacion_id, NEW.id, invitacion.rol);
    
    -- (Opcional) Borrar la invitación una vez aceptada
    DELETE FROM invitaciones_equipo WHERE id = invitacion.id;
  ELSE
    -- FASE 1: Solo por invitación. Si no hay invitación, bloqueamos el registro.
    -- Cuando se quiera abrir al público, aquí se crearía una nueva organización automáticamente.
    RAISE EXCEPTION 'Registro denegado: El correo % no tiene una invitación activa.', NEW.email;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Eliminar el trigger si ya existía y volver a crearlo
DROP TRIGGER IF EXISTS on_auth_user_created_trigger ON auth.users;

CREATE TRIGGER on_auth_user_created_trigger
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION on_auth_user_created();

-- 3. Función auxiliar para obtener el ID de la organización actual (útil para Edge Functions)
CREATE OR REPLACE FUNCTION get_current_org_id()
RETURNS UUID AS $$
DECLARE
  org_id UUID;
BEGIN
  -- Usamos LIMIT 1 para evitar errores si un usuario estuviera en múltiples organizaciones accidentalmente
  SELECT organizacion_id INTO org_id 
  FROM perfiles_organizacion 
  WHERE usuario_id = auth.uid() 
  LIMIT 1;
  
  RETURN org_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
