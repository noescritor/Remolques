import type { DatosModelo, GrupoOpcion, Opcion } from "./tipos.ts";
import { fusionarFilasConfig, normalizarClaveOpcion, limpiarTextoColorPersonalizado } from "./reglas_compatibilidad.ts";

export interface CabeceraFicha {
  cliente: string;
  telefono: string;
  correo: string;
  numero_pedido: string;
  nombre_proyecto: string;
  fecha_pedido: string;
  pedido_recibido_por: string;
  fecha_inicio_prevista: string;
  fecha_fin_prevista: string;
  trabajo_autorizado_por: string;
  compilada_por: string;
}

export interface FichaOrdenTrabajo {
  cabecera: CabeceraFicha;
  cantidad_texto: string;
  caracteristicas: { etiqueta: string; valor: string }[];
  accesorios_extra: { etiqueta: string; valor: string }[];
  nota: string;
}

export interface ParametrosConstruirFicha {
  item: any;
  cotizacion?: any;
  cliente?: any;
  ajustes?: any;
  datosModelo?: DatosModelo | null;
}

function formatearFecha(f: string | null | undefined): string {
  if (!f) return "";
  if (/^\d{2}\/\d{2}\/\d{2,4}$/.test(f)) return f;
  const d = new Date(f);
  if (isNaN(d.getTime())) return f;
  const dia = d.getUTCDate().toString().padStart(2, "0");
  const mes = (d.getUTCMonth() + 1).toString().padStart(2, "0");
  const anio = d.getUTCFullYear().toString().slice(-2);
  return `${dia}/${mes}/${anio}`;
}

export function formatearCantidadTexto(modelo: any): string {
  const tipo = (modelo?.tipo || "").toLowerCase();
  const largo = modelo?.largo_ft;
  const ejes = modelo?.num_ejes;

  const femenino =
    tipo.includes("plataforma") ||
    tipo.includes("gondola") ||
    tipo.includes("góndola") ||
    tipo.includes("caja") ||
    tipo.includes("jaula");
  const art = femenino ? "Una" : "Un";

  let tipoCap = tipo.charAt(0).toUpperCase() + tipo.slice(1);
  if (tipo === "gondola") tipoCap = "Góndola";
  else if (tipo === "dolly") tipoCap = "Dolly";
  else if (tipo === "plataforma") tipoCap = "Plataforma";
  else if (!tipoCap) tipoCap = "Remolque";

  const partes = [art, tipoCap];
  if (largo && Number(largo) > 0) {
    partes.push(`${largo} ft`);
  }
  if (ejes && Number(ejes) > 0) {
    partes.push(`${ejes} ejes`);
  }
  return partes.join(" ");
}

function numeroAPalabras(n: number, femenino = false): string {
  const palabrasMasculinas = [
    "Cero",
    "Uno",
    "Dos",
    "Tres",
    "Cuatro",
    "Cinco",
    "Seis",
    "Siete",
    "Ocho",
    "Nueve",
    "Diez",
    "Once",
    "Doce",
    "Trece",
    "Catorce",
    "Quince",
    "Dieciséis",
    "Diecisiete",
    "Dieciocho",
    "Diecinueve",
    "Veinte",
  ];
  const palabrasFemeninas = [
    "Cero",
    "Una",
    "Dos",
    "Tres",
    "Cuatro",
    "Cinco",
    "Seis",
    "Siete",
    "Ocho",
    "Nueve",
    "Diez",
    "Once",
    "Doce",
    "Trece",
    "Catorce",
    "Quince",
    "Dieciséis",
    "Diecisiete",
    "Dieciocho",
    "Diecinueve",
    "Veinte",
  ];
  const tabla = femenino ? palabrasFemeninas : palabrasMasculinas;
  if (n >= 0 && n <= 20) return tabla[n];
  return String(n);
}

function limpiarTextoOpcion(nombre: string, grupoNombre?: string): string {
  let limpio = nombre.replace(/\s*\(.*?\)\s*/g, "").trim();
  if (grupoNombre) {
    const prefijo = grupoNombre.trim();
    if (limpio.toLowerCase().startsWith(prefijo.toLowerCase())) {
      limpio = limpio.substring(prefijo.length).trim();
    }
  }
  return limpio;
}

function aOracion(txt: string): string {
  if (!txt) return "";
  const t = txt.trim();
  return t.charAt(0).toUpperCase() + t.slice(1);
}

function obtenerFilasGrupo(gruposConfig: any, claveGrupo: string): any[] {
  if (!gruposConfig || typeof gruposConfig !== "object") return [];
  const val = gruposConfig[claveGrupo];
  if (!val) return [];
  const raw = Array.isArray(val) ? val : [val];
  return fusionarFilasConfig(raw);
}

function obtenerAdicionales(configuracion: any): any[] {
  if (!configuracion || typeof configuracion !== "object") return [];
  const deGrupos = configuracion.grupos?.adicionales;
  const deRaiz = configuracion.adicionales;
  const raw = deGrupos || deRaiz || [];
  const lista = Array.isArray(raw) ? raw : [raw];
  return fusionarFilasConfig(lista);
}

export const APLICA_A_DEFECTO: Record<string, string[]> = {
  piso: ["plataforma"],
  riel: ["plataforma"],
  frente: ["plataforma"],
  redilas: ["plataforma"],
  gancho: ["plataforma"],
  patin: ["plataforma", "gondola", "jaula", "caja_seca"],
  eje: ["plataforma", "dolly", "gondola", "jaula", "caja_seca"],
  suspension: ["plataforma", "dolly", "gondola", "jaula", "caja_seca"],
  abs: ["plataforma", "dolly", "gondola", "jaula", "caja_seca"],
  retractil: ["plataforma", "dolly", "gondola", "jaula", "caja_seca"],
  rines: ["plataforma", "dolly", "gondola", "jaula", "caja_seca"],
  llantas: ["plataforma", "dolly", "gondola", "jaula", "caja_seca"],
  color: ["plataforma", "dolly", "gondola", "jaula", "caja_seca"],
};

export function grupoAplicaAlTipo(
  claveGrupo: string,
  tipoModelo: string,
  gruposCat: GrupoOpcion[] = []
): boolean {
  if (!tipoModelo) return true;
  const tipoNorm = tipoModelo.toLowerCase().trim();

  // 1. Buscar en el catálogo inyectado
  const grupo = gruposCat.find((g) => g.clave === claveGrupo);
  if (grupo && grupo.aplica_a !== undefined && grupo.aplica_a !== null) {
    if (Array.isArray(grupo.aplica_a)) {
      return grupo.aplica_a.map((t: string) => t.toLowerCase().trim()).includes(tipoNorm);
    }
    if (typeof grupo.aplica_a === "string") {
      return (grupo.aplica_a as string).toLowerCase().trim() === tipoNorm;
    }
  }

  // 2. Diccionario de respaldo con los grupos del catálogo oficial
  const def = APLICA_A_DEFECTO[claveGrupo];
  if (def) {
    return def.includes(tipoNorm);
  }

  return true;
}

export function construirFichaOrdenTrabajo(
  params: ParametrosConstruirFicha
): FichaOrdenTrabajo {
  const { item, cotizacion, cliente, datosModelo } = params;

  const cfg = item?.configuracion || {};
  const gruposConfig = cfg.grupos || {};
  const modelo: any = datosModelo?.modelo || {};
  const gruposCat: GrupoOpcion[] = datosModelo?.grupos || [];
  const opcionesCat: Opcion[] = datosModelo?.opciones || [];

  let tipoModelo = (modelo.tipo || "").toLowerCase().trim();
  if (!tipoModelo && item?.descripcion) {
    const desc = item.descripcion.toLowerCase();
    if (desc.includes("dolly")) tipoModelo = "dolly";
    else if (desc.includes("gondola") || desc.includes("góndola")) tipoModelo = "gondola";
    else if (desc.includes("plataforma") || desc.includes("plana")) tipoModelo = "plataforma";
    else if (desc.includes("jaula")) tipoModelo = "jaula";
    else if (desc.includes("cama baja")) tipoModelo = "cama_baja";
    else if (desc.includes("multimodal")) tipoModelo = "multimodal";
    else if (desc.includes("porta")) tipoModelo = "portacontenedor";
    else if (desc.includes("seca")) tipoModelo = "caja_seca";
  }
  const esDolly = tipoModelo === "dolly";
  const aplicaGrupo = (clave: string) => grupoAplicaAlTipo(clave, tipoModelo, gruposCat);

  // Buscar opción en catálogo por grupo y clave
  const buscarOpcion = (claveGrupo: string, claveOpcion: string): Opcion | undefined => {
    const grupo = gruposCat.find((g) => g.clave === claveGrupo);
    return opcionesCat.find((o) => o.grupo_id === grupo?.id && o.clave === claveOpcion);
  };

  // 1. CABECERA
  const clienteNombre =
    cliente?.nombre_razon_social || cliente?.nombre || "";
  const telefono = cliente?.telefono || "";
  const correo = cliente?.correo || "";
  const numeroPedido = cotizacion?.folio || "";
  const nombreProyecto = cotizacion?.descripcion || "";
  const fechaPedido = formatearFecha(cotizacion?.firma_fecha || cotizacion?.fecha);

  const cabecera: CabeceraFicha = {
    cliente: clienteNombre,
    telefono,
    correo,
    numero_pedido: numeroPedido,
    nombre_proyecto: nombreProyecto,
    fecha_pedido: fechaPedido,
    pedido_recibido_por: "",
    fecha_inicio_prevista: "",
    fecha_fin_prevista: "",
    trabajo_autorizado_por: "",
    compilada_por: "",
  };

  // 2. CANTIDAD_TEXTO
  const cantidadTexto = formatearCantidadTexto(modelo);

  // 3. CARACTERÍSTICAS
  // EJES
  let valorEjes = aplicaGrupo("eje") ? "Por definir" : "No aplica";
  if (aplicaGrupo("eje")) {
    const filasEjes = obtenerFilasGrupo(gruposConfig, "eje");
    if (filasEjes.length > 0) {
      const primerEje = filasEjes[0];
      const opClave = typeof primerEje === "string" ? primerEje : primerEje?.opcion;
      if (opClave?.startsWith("sin_")) {
        valorEjes = "No aplica";
      } else {
        const opt = buscarOpcion("eje", opClave);
        let nom = opt ? limpiarTextoOpcion(opt.nombre, "Eje") : opClave || "Por definir";
        if (primerEje?.marca && !nom.toLowerCase().includes(primerEje.marca.toLowerCase())) {
          nom = `${nom} ${primerEje.marca}`;
        }
        valorEjes = nom;
      }
    }
  }

  // SUSPENSIÓN
  let valorSuspension = aplicaGrupo("suspension") ? "Por definir" : "No aplica";
  if (aplicaGrupo("suspension")) {
    const filasSusp = obtenerFilasGrupo(gruposConfig, "suspension");
    if (filasSusp.length > 0) {
      const primerSusp = filasSusp[0];
      const opClave = typeof primerSusp === "string" ? primerSusp : primerSusp?.opcion;
      if (opClave?.startsWith("sin_")) {
        valorSuspension = "No aplica";
      } else {
        const opt = buscarOpcion("suspension", opClave);
        let nom = opt ? limpiarTextoOpcion(opt.nombre, "Suspensión") : opClave || "Por definir";
        if (primerSusp?.marca && !nom.toLowerCase().includes(primerSusp.marca.toLowerCase())) {
          nom = `${nom} ${primerSusp.marca}`;
        }
        valorSuspension = nom;
      }
    }
  }

  // PATINES
  let valorPatines = aplicaGrupo("patin") ? "Por definir" : "No aplica";
  if (aplicaGrupo("patin")) {
    const filasPatin = obtenerFilasGrupo(gruposConfig, "patin");
    if (filasPatin.length > 0) {
      const primerPatin = filasPatin[0];
      const opClave = typeof primerPatin === "string" ? primerPatin : primerPatin?.opcion;
      if (opClave?.startsWith("sin_")) {
        valorPatines = "No aplica";
      } else {
        const opt = buscarOpcion("patin", opClave);
        const nom = opt ? limpiarTextoOpcion(opt.nombre, "Patines") : opClave || "Por definir";
        const cant = typeof primerPatin === "object" && primerPatin?.cantidad ? primerPatin.cantidad : 2;
        valorPatines = `${numeroAPalabras(cant)} ${nom}`;
      }
    }
  }

  // PISO
  let valorPiso = aplicaGrupo("piso") ? "Por definir" : "No aplica";
  if (aplicaGrupo("piso")) {
    const filasPiso = obtenerFilasGrupo(gruposConfig, "piso");
    if (filasPiso.length > 0) {
      const primerPiso = filasPiso[0];
      const opClave = typeof primerPiso === "string" ? primerPiso : primerPiso?.opcion;
      if (opClave?.startsWith("sin_")) {
        valorPiso = "No aplica";
      } else {
        const opt = buscarOpcion("piso", opClave);
        valorPiso = opt ? opt.nombre : aOracion(opClave || "Por definir");
      }
    }
  }

  // RIEL
  let valorRiel = "No aplica";
  if (aplicaGrupo("riel")) {
    const filasRiel = obtenerFilasGrupo(gruposConfig, "riel");
    if (filasRiel.length > 0) {
      const primerRiel = filasRiel[0];
      const opClave = typeof primerRiel === "string" ? primerRiel : primerRiel?.opcion;
      if (opClave && !opClave.startsWith("sin_")) {
        // Sumar piezas de matracas
        const filasMatracas = obtenerFilasGrupo(gruposConfig, "matracas");
        let totalMatracas = 0;
        for (const m of filasMatracas) {
          const mClave = typeof m === "string" ? m : m?.opcion;
          if (mClave && !mClave.startsWith("sin_")) {
            const c = typeof m === "object" && typeof m?.cantidad === "number" ? m.cantidad : (filasMatracas.length === 1 ? 10 : 1);
            totalMatracas += c;
          }
        }
        if (totalMatracas > 0) {
          valorRiel = `Con ${totalMatracas} winches`;
        } else {
          valorRiel = "Con riel";
        }
      }
    }
  }

  // GANCHO
  let valorGancho = "No aplica";
  if (aplicaGrupo("gancho")) {
    const filasGancho = obtenerFilasGrupo(gruposConfig, "gancho");
    if (filasGancho.length > 0) {
      const primerGancho = filasGancho[0];
      const opClave = typeof primerGancho === "string" ? primerGancho : primerGancho?.opcion;
      if (opClave && !opClave.startsWith("sin_")) {
        const opt = buscarOpcion("gancho", opClave);
        let nom = opt ? opt.nombre : opClave;
        // Limpiar "(...)" y "8/10 barrenos", etc.
        nom = nom.replace(/\s*\(.*?\)\s*/g, "").replace(/\s*(\d+\/\d+|\d+)\s*barrenos/i, "").trim();
        valorGancho = nom;
      }
    }
  }

  // FRENTE
  let valorFrente = "No aplica";
  if (aplicaGrupo("frente")) {
    const filasFrente = obtenerFilasGrupo(gruposConfig, "frente");
    if (filasFrente.length > 0) {
      const primerFrente = filasFrente[0];
      const opClave = typeof primerFrente === "string" ? primerFrente : primerFrente?.opcion;
      if (opClave && !opClave.startsWith("sin_")) {
        const opt = buscarOpcion("frente", opClave);
        let baseNom = opt ? opt.nombre : opClave;
        if (baseNom.toLowerCase().startsWith("concha")) {
          baseNom = "Concha";
        } else if (baseNom.toLowerCase().startsWith("burro")) {
          baseNom = "Burro";
        } else {
          baseNom = limpiarTextoOpcion(baseNom, "Frente");
        }
        const medida = typeof primerFrente === "object" ? primerFrente?.medida : undefined;
        if (medida) {
          const medStr = String(medida).trim();
          const sufijo = medStr.includes("m") ? "" : " mts.";
          valorFrente = `${baseNom} a ${medStr}${sufijo}`;
        } else {
          valorFrente = baseNom;
        }
      }
    }
  }

  // RETRÁCTIL
  let valorRetractil = "No aplica";
  if (aplicaGrupo("retractil")) {
    const filasRetractil = obtenerFilasGrupo(gruposConfig, "retractil");
    if (filasRetractil.length > 0) {
      let cantRetractil = 0;
      for (const r of filasRetractil) {
        const rawClave = typeof r === "string" ? r : r?.opcion;
        const opClave = normalizarClaveOpcion("retractil", rawClave);
        if (opClave && !opClave.startsWith("sin_")) {
          const c = typeof r === "object" && typeof r?.cantidad === "number" ? r.cantidad : 1;
          cantRetractil += c;
        }
      }
      if (cantRetractil > 0) {
        valorRetractil = numeroAPalabras(cantRetractil);
      }
    }
  }

  // ADICIONALES (para portallantas, caja de herramientas, canastilla, bicicletera, y nota)
  const adicionales = obtenerAdicionales(cfg);

  // PORTALLANTAS
  let valorPortallantas = esDolly ? "No aplica" : "Uno";
  let cantPortallantas = esDolly ? 0 : 1;
  for (const ad of adicionales) {
    const op = typeof ad === "string" ? ad : ad?.opcion;
    if (op === "portallantas_extra" || op === "portallantas") {
      const c = typeof ad === "object" && typeof ad?.cantidad === "number" ? ad.cantidad : 1;
      cantPortallantas += c;
    }
  }
  if (cantPortallantas > 0) {
    valorPortallantas = numeroAPalabras(cantPortallantas);
  }

  // CAJA DE HERRAMIENTAS
  let valorCaja = "No aplica";
  let cantCaja = 0;
  for (const ad of adicionales) {
    const op = typeof ad === "string" ? ad : ad?.opcion;
    if (op === "caja_herr_chica" || op === "caja_herr_grande" || op === "caja_auxiliar") {
      const c = typeof ad === "object" && typeof ad?.cantidad === "number" ? ad.cantidad : 1;
      cantCaja += c;
    }
  }
  if (cantCaja > 0) {
    valorCaja = numeroAPalabras(cantCaja, true);
  }

  // LODERAS
  const valorLoderas = "Un par";

  // COLOR
  let valorColor = aplicaGrupo("color") ? "Por definir" : "No aplica";
  if (aplicaGrupo("color")) {
    const filasColor = obtenerFilasGrupo(gruposConfig, "color");
    if (filasColor.length > 0) {
      const primerColor = filasColor[0];
      const rawClave = typeof primerColor === "string" ? primerColor : primerColor?.opcion;
      const opClave = normalizarClaveOpcion("color", rawClave);
      if (opClave === "personalizado") {
        const txt = typeof primerColor === "object" && primerColor?.texto ? limpiarTextoColorPersonalizado(primerColor.texto) : "";
        valorColor = txt || "Color personalizado";
      } else {
        const opt = buscarOpcion("color", opClave);
        valorColor = opt ? opt.nombre : aOracion(opClave || "Por definir");
      }
    }
  }

  // CANASTILLA O POLINERA
  let valorCanastilla = "No aplica";
  let cantCanastilla = 0;
  for (const ad of adicionales) {
    const op = typeof ad === "string" ? ad : ad?.opcion;
    if (op === "canastilla" || (op?.startsWith("polinera") && op !== "polinera_bicicletera")) {
      const c = typeof ad === "object" && typeof ad?.cantidad === "number" ? ad.cantidad : 1;
      cantCanastilla += c;
    }
  }
  if (cantCanastilla > 0) {
    valorCanastilla = numeroAPalabras(cantCanastilla, true);
  }

  // BICICLETERA
  let valorBicicletera = "No aplica";
  let cantBicicletera = 0;
  for (const ad of adicionales) {
    const op = typeof ad === "string" ? ad : ad?.opcion;
    if (op === "bicicletera" || op === "polinera_bicicletera") {
      const c = typeof ad === "object" && typeof ad?.cantidad === "number" ? ad.cantidad : 1;
      cantBicicletera += c;
    }
  }
  if (cantBicicletera > 0) {
    valorBicicletera = numeroAPalabras(cantBicicletera, true);
  }

  const caracteristicas = [
    { etiqueta: "EJES", valor: valorEjes },
    { etiqueta: "SUSPENSIÓN", valor: valorSuspension },
    { etiqueta: "PATINES", valor: valorPatines },
    { etiqueta: "PISO", valor: valorPiso },
    { etiqueta: "RIEL", valor: valorRiel },
    { etiqueta: "GANCHO", valor: valorGancho },
    { etiqueta: "FRENTE", valor: valorFrente },
    { etiqueta: "RETRÁCTIL", valor: valorRetractil },
    { etiqueta: "PORTALLANTAS", valor: valorPortallantas },
    { etiqueta: "CAJA DE HERRAMIENTAS", valor: valorCaja },
    { etiqueta: "LODERAS", valor: valorLoderas },
    { etiqueta: "COLOR", valor: valorColor },
    { etiqueta: "CANASTILLA O POLINERA", valor: valorCanastilla },
    { etiqueta: "BICICLETERA", valor: valorBicicletera },
  ];

  // 4. ACCESORIOS EXTRA
  // PLAFONES EN ESTRIBO
  let valorPlafonesEstribo = "No aplica";
  const filasPlafones = obtenerFilasGrupo(gruposConfig, "plafones");
  const estribos = filasPlafones.filter((p) => {
    const op = typeof p === "string" ? p : p?.opcion;
    return op && op.includes("estribo") && !op.startsWith("sin_");
  });
  if (estribos.length > 0) {
    const partes = estribos.map((p) => {
      const op = typeof p === "string" ? p : p.opcion;
      const c = typeof p === "object" && typeof p.cantidad === "number" ? p.cantidad : 1;
      const opt = buscarOpcion("plafones", op);
      const nom = opt ? limpiarTextoOpcion(opt.nombre).toLowerCase() : op.replace("_estribo", "");
      return `${c} ${nom}`;
    });
    valorPlafonesEstribo = partes.join(", ");
  }

  // PLAFONES LATERALES
  let valorPlafonesLaterales = "No aplica";
  const laterales = filasPlafones.filter((p) => {
    const op = typeof p === "string" ? p : p?.opcion;
    return op && (op.includes("laterales") || op.includes("lateral")) && !op.startsWith("sin_");
  });
  if (laterales.length > 0) {
    const partes = laterales.map((p) => {
      const op = typeof p === "string" ? p : p.opcion;
      const c = typeof p === "object" && typeof p.cantidad === "number" ? p.cantidad : 1;
      const opt = buscarOpcion("plafones", op);
      const nom = opt ? limpiarTextoOpcion(opt.nombre).toLowerCase() : op.replace("_laterales", "");
      return `${c} ${nom}`;
    });
    valorPlafonesLaterales = partes.join(", ");
  }

  // RINES
  let valorRines = "No aplica";
  const filasRines = obtenerFilasGrupo(gruposConfig, "rines");
  const rinesActivos = filasRines.filter((r) => {
    const op = typeof r === "string" ? r : r?.opcion;
    return op && !op.startsWith("sin_");
  });
  if (rinesActivos.length > 0) {
    const clienteRow = rinesActivos.find((r) => {
      const op = typeof r === "string" ? r : r?.opcion;
      return op === "cliente";
    });
    if (clienteRow) {
      valorRines = "Los proporciona el cliente";
    } else {
      const partesRines = rinesActivos.map((r) => {
        const op = typeof r === "string" ? r : r.opcion;
        const opt = buscarOpcion("rines", op);
        const mat = opt ? limpiarTextoOpcion(opt.nombre, "Rines de").toLowerCase() : op.toLowerCase();
        const numEjes = modelo.num_ejes || 2;
        const defQty = rinesActivos.length === 1 ? numEjes * 4 : 1;
        const cant = typeof r === "object" && typeof r.cantidad === "number" ? r.cantidad : defQty;
        const marca = typeof r === "object" && r.marca ? ` ${r.marca}` : "";
        return `${cant} de ${mat}${marca}`;
      });
      valorRines = partesRines.join(" y ");
    }
  }

  // LLANTAS
  let valorLlantas = "No aplica";
  const filasLlantas = obtenerFilasGrupo(gruposConfig, "llantas");
  const llantasActivas = filasLlantas.filter((l) => {
    const op = typeof l === "string" ? l : l?.opcion;
    return op && !op.startsWith("sin_");
  });
  if (llantasActivas.length > 0) {
    const clienteRow = llantasActivas.find((l) => {
      const op = typeof l === "string" ? l : l?.opcion;
      return op === "cliente";
    });
    if (clienteRow) {
      valorLlantas = "Las proporciona el cliente";
    } else {
      const partesLlantas = llantasActivas.map((l) => {
        const op = typeof l === "string" ? l : l.opcion;
        const opt = buscarOpcion("llantas", op);
        const nom = opt ? opt.nombre : op;
        const numEjes = modelo.num_ejes || 2;
        const defQty = llantasActivas.length === 1 ? numEjes * 4 : 1;
        const cant = typeof l === "object" && typeof l.cantidad === "number" ? l.cantidad : defQty;
        return `${cant} ${nom}`;
      });
      valorLlantas = partesLlantas.join(" y ");
    }
  }

  const accesoriosExtra = [
    { etiqueta: "PLAFONES EN ESTRIBO", valor: valorPlafonesEstribo },
    { etiqueta: "PLAFONES LATERALES", valor: valorPlafonesLaterales },
    { etiqueta: "RINES", valor: valorRines },
    { etiqueta: "LLANTAS", valor: valorLlantas },
  ];

  // 5. NOTA
  // Redilas + otros adicionales que no tienen renglón + ajustes manuales
  const partesNota: string[] = [];

  // Redilas
  const filasRedilas = obtenerFilasGrupo(gruposConfig, "redilas");
  if (filasRedilas.length > 0) {
    const primerRedilas = filasRedilas[0];
    const opClave = typeof primerRedilas === "string" ? primerRedilas : primerRedilas?.opcion;
    if (opClave && !opClave.startsWith("sin_")) {
      const opt = buscarOpcion("redilas", opClave);
      let nom = opt ? opt.nombre : opClave;
      // Convertir "Redilas de 80 cm" o "80" en "Redillas a 80 cm"
      const matchCm = nom.match(/(\d+\s*(?:cm|m)?)/i);
      if (matchCm) {
        const med = matchCm[1].includes("cm") || matchCm[1].includes("m") ? matchCm[1] : `${matchCm[1]} cm`;
        partesNota.push(`Redillas a ${med}`);
      } else {
        partesNota.push(`Redillas ${nom}`);
      }
    }
  }

  // Otros adicionales
  const ADICIONALES_CON_RENGLON = new Set([
    "caja_herr_chica",
    "caja_herr_grande",
    "caja_auxiliar",
    "portallantas_extra",
    "portallantas",
    "canastilla",
    "bicicletera",
    "polinera_bicicletera",
  ]);

  for (const ad of adicionales) {
    const op = typeof ad === "string" ? ad : ad?.opcion;
    if (!op || op.startsWith("sin_") || ADICIONALES_CON_RENGLON.has(op)) continue;
    const opt = buscarOpcion("adicionales", op);
    const nom = opt ? opt.nombre : aOracion(op.replace(/_/g, " "));
    const cant = typeof ad === "object" && typeof ad?.cantidad === "number" ? ad.cantidad : 1;
    if (cant > 1) {
      partesNota.push(`${cant} ${nom.toLowerCase()}`);
    } else {
      partesNota.push(nom);
    }
  }

  // Ajustes manuales del concepto
  const ajustesManuales = cfg.ajustes || [];
  for (const aj of ajustesManuales) {
    if (aj?.concepto) {
      const cant = typeof aj.cantidad === "number" ? aj.cantidad : 1;
      if (cant > 1) {
        partesNota.push(`${cant} ${aj.concepto}`);
      } else {
        partesNota.push(aj.concepto);
      }
    }
  }

  const nota = partesNota.join("; ");

  const resultado: FichaOrdenTrabajo = {
    cabecera,
    cantidad_texto: cantidadTexto,
    caracteristicas,
    accesorios_extra: accesoriosExtra,
    nota,
  };

  return Object.freeze(resultado);
}
