import type { Configuracion, DatosModelo } from "./tipos.ts";

export function validarCompatibilidad(
  config: Configuracion,
  datos: DatosModelo,
  errores: string[]
) {
  // Extract selected options with their metadata
  const selectedOptions = new Map<string, any>();
  for (const [gClave, val] of Object.entries(config.grupos || {})) {
    const oClave = typeof val === "string" ? val : val.opcion;
    const grupo = datos.grupos.find((g) => g.clave === gClave);
    if (!grupo) continue;
    const opcion = datos.opciones.find((o) => o.grupo_id === grupo.id && o.clave === oClave);
    if (opcion) {
      selectedOptions.set(gClave, opcion);
    }
  }

  // Regla 1: Suspensión vs Retráctil
  const susp = selectedOptions.get("suspension");
  const retr = selectedOptions.get("retractil");

  if (susp && retr) {
    if (retr.clave !== "sin_retractil" && retr.clave !== "paleta") {
      if (susp.clase === "alta" && retr.clave !== "grande") {
        errores.push(`Incompatibilidad: La suspensión de clase alta requiere un retráctil grande (seleccionado: ${retr.nombre}).`);
      } else if (susp.clase === "normal" && retr.clave !== "chico") {
        errores.push(`Incompatibilidad: La suspensión de clase normal requiere un retráctil chico (seleccionado: ${retr.nombre}).`);
      }
    }
  }

  // Regla 2: Dona vs Gancho
  const dona = selectedOptions.get("dona");
  const gancho = selectedOptions.get("gancho");

  if (dona && gancho && dona.clave !== "sin_dona" && gancho.clave !== "sin_gancho") {
    // Both dona and gancho have 'clase' based on their bolt count (e.g. '8', '6_bestia')
    // Wait, let's just check if they are related. If their clases don't match or similar.
    // The prompt says "dona debe corresponder al gancho".
    if (dona.clase !== gancho.clase && dona.clase !== "universal") {
        errores.push(`Incompatibilidad: La dona (clase ${dona.clase || dona.clave}) no corresponde al gancho (clase ${gancho.clase || gancho.clave}).`);
    }
  }
}
