import { useState, useEffect, useCallback } from 'react';
import { supabase } from '../utils/supabase/client';

export interface EstadoRolOrganizacion {
  rolActual: string;
  cargandoRol: boolean;
  errorRol: string | null;
  esAdminOPropietario: boolean;
  reintentarRol: () => Promise<void>;
}

/**
 * Fuente única de verdad para el rol del usuario en la organización actual.
 * Lee exclusivamente de `perfiles_organizacion` (nunca de `user_metadata`).
 * Si falla la consulta, trata al usuario como `'usuario'` y expone `errorRol` + `reintentarRol`.
 */
export function useRolOrganizacion(
  session: any,
  organizacionId?: string | null
): EstadoRolOrganizacion {
  const [rolActual, setRolActual] = useState<string>('usuario');
  const [cargandoRol, setCargandoRol] = useState<boolean>(false);
  const [errorRol, setErrorRol] = useState<string | null>(null);

  const userId = session?.user?.id as string | undefined;

  const cargarRol = useCallback(async () => {
    if (!userId) {
      setRolActual('usuario');
      setErrorRol(null);
      setCargandoRol(false);
      return;
    }

    setCargandoRol(true);
    setErrorRol(null);
    try {
      let query = supabase
        .from('perfiles_organizacion')
        .select('rol, organizacion_id')
        .eq('usuario_id', userId);

      if (organizacionId) {
        query = query.eq('organizacion_id', organizacionId);
      }

      const { data, error } = await query.limit(1).maybeSingle();
      if (error) {
        console.error('[useRolOrganizacion] Error leyendo perfiles_organizacion:', error);
        setRolActual('usuario');
        setErrorRol(error.message || 'No se pudo verificar tu rol en la organización.');
        return;
      }

      const rolNormalizado = String(data?.rol || 'usuario').trim().toLowerCase() || 'usuario';
      setRolActual(rolNormalizado);
    } catch (err: any) {
      console.error('[useRolOrganizacion] Excepción leyendo perfiles_organizacion:', err);
      setRolActual('usuario');
      setErrorRol(err?.message || 'Error de conexión al verificar tu rol.');
    } finally {
      setCargandoRol(false);
    }
  }, [userId, organizacionId]);

  useEffect(() => {
    cargarRol();
  }, [cargarRol]);

  const esAdminOPropietario = rolActual === 'admin' || rolActual === 'propietario';

  return {
    rolActual,
    cargandoRol,
    errorRol,
    esAdminOPropietario,
    reintentarRol: cargarRol,
  };
}
