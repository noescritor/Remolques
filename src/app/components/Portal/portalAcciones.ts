export interface RespuestaAccionPortal {
  ok: boolean;
  status: number;
  error?: string;
  codigo?: string;
  reintentable?: boolean;
  data?: any;
}

function mensajePorErrorPortal(
  status: number,
  body: any,
  accion: 'aprobar' | 'rechazar' | 'solicitar-cambios'
): { error: string; codigo?: string; reintentable: boolean } {
  const codigo = body?.codigo as string | undefined;
  const serverMsg = typeof body?.error === 'string' ? body.error : '';

  if (status === 410 || codigo === 'TOKEN_EXPIRADO') {
    return {
      error: 'El enlace expiró.',
      codigo: 'TOKEN_EXPIRADO',
      reintentable: false,
    };
  }

  if (status === 404 || codigo === 'TOKEN_INVALIDO') {
    return {
      error: 'Este enlace no es válido o la cotización no existe.',
      codigo: 'TOKEN_INVALIDO',
      reintentable: false,
    };
  }

  if (status === 409) {
    if (codigo === 'YA_APROBADA' || body?.estado_actual === 'Aprobada') {
      return {
        error: 'Esta cotización ya fue aprobada.',
        codigo: 'YA_APROBADA',
        reintentable: false,
      };
    }
    const verbo = accion === 'aprobar' ? 'aprobar' : accion === 'rechazar' ? 'rechazar' : 'solicitar cambios';
    return {
      error: `Esta cotización ya no está disponible para ${verbo}, contacta a tu asesor.`,
      codigo: codigo || 'ESTADO_NO_DISPONIBLE',
      reintentable: false,
    };
  }

  if (status === 400 && serverMsg) {
    return {
      error: serverMsg,
      codigo,
      reintentable: false,
    };
  }

  return {
    error: serverMsg || 'Ocurrió un error al procesar tu solicitud. Intenta de nuevo.',
    codigo: codigo || 'ERROR_SERVIDOR',
    reintentable: true,
  };
}

export async function enviarAccionPortal(
  baseUrl: string,
  token: string,
  accion: 'aprobar' | 'rechazar' | 'solicitar-cambios',
  payload: Record<string, unknown>,
  fetchImpl: typeof fetch = fetch
): Promise<RespuestaAccionPortal> {
  try {
    const res = await fetchImpl(`${baseUrl}/portal/${token}/${accion}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload),
    });

    let body: any = null;
    try {
      body = await res.json();
    } catch {
      body = null;
    }

    if (!res.ok) {
      const detalle = mensajePorErrorPortal(res.status, body, accion);
      return {
        ok: false,
        status: res.status,
        error: detalle.error,
        codigo: detalle.codigo,
        reintentable: detalle.reintentable,
      };
    }

    return {
      ok: true,
      status: res.status,
      data: body,
    };
  } catch {
    return {
      ok: false,
      status: 0,
      error: 'No se pudo conectar con el servidor. Verifica tu conexión e intenta de nuevo.',
      codigo: 'ERROR_RED',
      reintentable: true,
    };
  }
}
