-- ============================================================
-- FIX: Hacer que el trigger de registro de usuarios sea insensible a mayúsculas/minúsculas
-- y configurar 'search_path = public' con calificadores de esquema para evitar
-- fallos de resolución de relaciones cuando el trigger es llamado por supabase_auth_admin.
-- ============================================================

CREATE OR REPLACE FUNCTION on_auth_user_created()
RETURNS TRIGGER AS $$
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
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;
