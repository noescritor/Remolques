-- ============================================================
-- FIX: Hacer que el trigger de registro de usuarios sea insensible a mayúsculas/minúsculas
-- Esto previene el error "Database error saving new user" cuando hay diferencias de caso en el email.
-- ============================================================

CREATE OR REPLACE FUNCTION on_auth_user_created()
RETURNS TRIGGER AS $$
DECLARE
  invitacion RECORD;
BEGIN
  -- Buscar si el usuario fue invitado a alguna organización (insensible a mayúsculas/minúsculas)
  SELECT * INTO invitacion 
  FROM invitaciones_equipo 
  WHERE LOWER(email) = LOWER(NEW.email);

  IF FOUND THEN
    -- Si fue invitado, asignarlo a la organización con el rol definido
    INSERT INTO perfiles_organizacion (organizacion_id, usuario_id, rol)
    VALUES (invitacion.organizacion_id, NEW.id, invitacion.rol);
    
    -- Borrar la invitación una vez aceptada
    DELETE FROM invitaciones_equipo WHERE id = invitacion.id;
  ELSE
    -- Si no hay invitación, bloqueamos el registro
    RAISE EXCEPTION 'Registro denegado: El correo % no tiene una invitación activa.', NEW.email;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
