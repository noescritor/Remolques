import { useState } from "react";
import {
  FileText, ClipboardList, Truck, Package, Route, LayoutDashboard, Users, Building2,
  Ruler, Layers, CircleDot, Circle, Grid3x3,
  CheckCircle2, AlertTriangle, ChevronRight, ArrowLeft, Plus, X
} from "lucide-react";

const C = {
  bg: "#EEF0EA",
  surface: "#FFFFFF",
  ink: "#1C2127",
  inkMuted: "#5C6570",
  border: "#D9DBD2",
  accent: "#1F3A52",
  accentSoft: "#E3EAEF",
  amber: "#A8690E",
  amberSoft: "#FAEEDC",
  green: "#3B6B3D",
  greenSoft: "#E6EFE2",
  red: "#AE3A2E",
  redSoft: "#FAE7E3",
};

const money = (n) => "$" + n.toLocaleString("es-MX");

const MATERIALES_INICIAL = [
  { id: "MAT-001", nombre: 'Perfil estructural 4x2"', unidad: "m", costo: 185, stock: 210, icono: "ruler" },
  { id: "MAT-002", nombre: "Lámina rolada cal. 10", unidad: "pza", costo: 2400, stock: 14, icono: "layers" },
  { id: "MAT-003", nombre: "Eje 7000 lb", unidad: "pza", costo: 3800, stock: 1, icono: "eje" },
  { id: "MAT-004", nombre: "Llanta 235/75R17.5", unidad: "pza", costo: 2950, stock: 22, icono: "llanta" },
  { id: "MAT-005", nombre: "Piso de madera tratada", unidad: "pza", costo: 1150, stock: 0, icono: "piso" },
];

const ICONOS_MATERIAL = { ruler: Ruler, layers: Layers, eje: CircleDot, llanta: Circle, piso: Grid3x3 };

const BOM = {
  "Remolque plataforma 40'": [
    { id: "MAT-001", cant: 40 },
    { id: "MAT-003", cant: 4 },
    { id: "MAT-004", cant: 16 },
    { id: "MAT-005", cant: 2 },
  ],
  "Tolva ganadera 3 ejes": [
    { id: "MAT-002", cant: 6 },
    { id: "MAT-003", cant: 3 },
    { id: "MAT-004", cant: 12 },
  ],
  "Caja seca 48'": [
    { id: "MAT-002", cant: 10 },
    { id: "MAT-005", cant: 2 },
  ],
};

const CLIENTES = [
  { id: "CLI-01", nombre: "Transportes del Bajío", razonSocial: "Transportes del Bajío S.A. de C.V.", telefono: "477 123 4567", correo: "compras@transportesbajio.mx", contacto: "Ing. Raúl Mendoza", limite: 500000, usado: 210000 },
  { id: "CLI-02", nombre: "Fletes Industriales Puebla", razonSocial: "Fletes Industriales Puebla S.A. de C.V.", telefono: "222 456 7890", correo: "administracion@fletespuebla.mx", contacto: "Lic. Denisse Rojas", limite: 250000, usado: 238000 },
  { id: "CLI-03", nombre: "Agropecuaria Los Pinos", razonSocial: "Agropecuaria Los Pinos S. de P.R.", telefono: "461 789 0123", correo: "compras@lospinosagro.mx", contacto: "Sr. Pedro León", limite: 150000, usado: 40000 },
];

const PAGOS_INICIAL = [
  { clienteId: "CLI-01", monto: 180000, fecha: "12 sep 2026" },
  { clienteId: "CLI-02", monto: 95000, fecha: "15 sep 2026" },
  { clienteId: "CLI-03", monto: 60000, fecha: "20 sep 2026" },
];

const PROVEEDORES = [
  { id: "PROV-01", nombre: "Aceros y Perfiles del Centro", contacto: "Lic. Iván Casas", telefono: "477 900 1122", materiales: ["MAT-001", "MAT-003"], tiempoEntregaDias: 5, condicionesPago: "30 días" },
  { id: "PROV-02", nombre: "Láminas y Aceros del Bajío", contacto: "Ing. Marta Ibarra", telefono: "461 233 4455", materiales: ["MAT-002"], tiempoEntregaDias: 7, condicionesPago: "Contado" },
  { id: "PROV-03", nombre: "Llantas y Rodamientos JR", contacto: "Sr. Jorge Ramos", telefono: "222 678 9012", materiales: ["MAT-004"], tiempoEntregaDias: 3, condicionesPago: "15 días" },
  { id: "PROV-04", nombre: "Maderas Tratadas del Norte", contacto: "Sra. Lucía Peña", telefono: "844 321 0099", materiales: ["MAT-005"], tiempoEntregaDias: 10, condicionesPago: "Contado" },
];

const PRECIO_ACTUALIZADO = { "MAT-003": 4200 };

const USUARIOS = [
  { id: "USR-01", nombre: "Ana Torres", rol: "Ventas" },
  { id: "USR-02", nombre: "Miguel Ruiz", rol: "Compras" },
  { id: "USR-03", nombre: "Sofía Nava", rol: "Almacén" },
  { id: "USR-04", nombre: "Dirección", rol: "Gerencia" },
];

const COTIZACIONES_INICIAL = [
  { folio: "COT-2026-118", clienteId: "CLI-01", producto: "Remolque plataforma 40'", cantidad: 2, total: 486000, fecha: "02 sep 2026", convertida: false },
  { folio: "COT-2026-119", clienteId: "CLI-02", producto: "Tolva ganadera 3 ejes", cantidad: 1, total: 312500, fecha: "03 sep 2026", convertida: true },
  { folio: "COT-2026-121", clienteId: "CLI-03", producto: "Caja seca 48'", cantidad: 1, total: 268000, fecha: "04 sep 2026", convertida: true },
  { folio: "COT-2026-123", clienteId: "CLI-01", producto: "Tolva ganadera 3 ejes", cantidad: 1, total: 318000, fecha: "05 sep 2026", convertida: false },
];

const ORDENES_INICIAL = [
  {
    folio: "OC-2026-041", cotFolio: "COT-2026-119", clienteId: "CLI-02",
    producto: "Tolva ganadera 3 ejes", cantidad: 1, total: 312500,
    estatus: "Compra a proveedor en curso", folioProduccion: "PROD-2026-041",
    fechaCompromiso: "18 sep 2026", diasRestantes: 2, costoEstimado: 61200, costoReal: null,
    historial: [
      { t: "03 sep · 09:10", ev: "Cotización COT-2026-119 generada" },
      { t: "03 sep · 11:40", ev: "OC del cliente registrada — Ana Torres (Ventas)" },
      { t: "03 sep · 11:42", ev: "Aprobada — folio de producción PROD-2026-041 asignado — Ana Torres (Ventas)" },
      { t: "03 sep · 11:42", ev: "Requisición: falta Eje 7000 lb (2 pza)" },
      { t: "03 sep · 12:05", ev: "Compra a proveedor generada — OCP-2026-018 — Miguel Ruiz (Compras)" },
    ],
  },
  {
    folio: "OC-2026-038", cotFolio: "COT-2026-121", clienteId: "CLI-03",
    producto: "Caja seca 48'", cantidad: 1, total: 268000,
    estatus: "Surtida", folioProduccion: "PROD-2026-038",
    fechaCompromiso: "04 sep 2026", diasRestantes: 0, costoEstimado: 26300, costoReal: 26300,
    historial: [
      { t: "04 sep · 08:15", ev: "Cotización COT-2026-121 generada" },
      { t: "04 sep · 09:00", ev: "OC del cliente registrada — Ana Torres (Ventas)" },
      { t: "04 sep · 09:05", ev: "Aprobada — folio de producción PROD-2026-038 asignado — Ana Torres (Ventas)" },
      { t: "04 sep · 09:05", ev: "Requisición: stock suficiente" },
      { t: "04 sep · 15:30", ev: "Salida de almacén registrada — Sofía Nava (Almacén)" },
      { t: "04 sep · 15:31", ev: "Orden surtida · margen real igual al estimado" },
    ],
  },
];

const COMPRAS_INICIAL = [
  {
    folio: "OCP-2026-018", ordenFolio: "OC-2026-041", proveedorId: "PROV-01",
    materiales: [{ id: "MAT-003", cant: 2, costoUnitario: 4200 }], estatus: "Pendiente", fecha: "03 sep 2026",
  },
];

const MOVIMIENTOS_INICIAL = [
  { t: "04 sep · 15:30", tipo: "Salida producción", material: "Lámina rolada cal. 10", cantidad: 10, ref: "PROD-2026-038" },
  { t: "04 sep · 15:30", tipo: "Salida producción", material: "Piso de madera tratada", cantidad: 2, ref: "PROD-2026-038" },
];

const NAV = [
  { id: "dashboard", label: "Dashboard", icon: LayoutDashboard },
  { id: "clientes", label: "Clientes", icon: Users },
  { id: "cotizaciones", label: "Cotizaciones", icon: FileText },
  { id: "ordenes", label: "Órdenes de compra", icon: ClipboardList },
  { id: "compras", label: "Compra a proveedor", icon: Truck },
  { id: "proveedores", label: "Proveedores", icon: Building2 },
  { id: "almacen", label: "Almacén", icon: Package },
  { id: "trazabilidad", label: "Trazabilidad", icon: Route },
];

function StatusPill({ estatus }) {
  const map = {
    "Pendiente de aprobar": { bg: C.border, text: C.inkMuted },
    "Aprobada": { bg: C.accentSoft, text: C.accent },
    "Compra a proveedor en curso": { bg: C.amberSoft, text: C.amber },
    "Lista para producción": { bg: C.accentSoft, text: C.accent },
    "Surtida": { bg: C.greenSoft, text: C.green },
    "Pendiente": { bg: C.amberSoft, text: C.amber },
    "Recibida": { bg: C.greenSoft, text: C.green },
  };
  const s = map[estatus] || { bg: C.border, text: C.inkMuted };
  return (
    <span className="text-xs font-medium px-2 py-1 rounded" style={{ background: s.bg, color: s.text }}>
      {estatus}
    </span>
  );
}

function Folio({ children }) {
  return <span className="font-mono text-sm" style={{ color: C.ink }}>{children}</span>;
}

function BotonAccion({ rolesPermitidos, rolActual, color, label, onClick, compact }) {
  const permitido = rolesPermitidos.includes(rolActual);
  return (
    <div className="flex flex-col gap-1">
      <button
        disabled={!permitido}
        onClick={onClick}
        className={compact ? "text-xs font-medium px-3 py-1.5 rounded" : "text-sm font-medium px-4 py-2 rounded"}
        style={{ background: color, color: "#fff", opacity: permitido ? 1 : 0.4, cursor: permitido ? "pointer" : "not-allowed" }}
      >
        {label}
      </button>
      {!permitido && <span className="text-xs" style={{ color: C.inkMuted }}>Requiere rol: {rolesPermitidos.join(" o ")}</span>}
    </div>
  );
}

function EntregaBadge({ diasRestantes, estatus }) {
  if (estatus === "Surtida") return null;
  if (diasRestantes <= 3) {
    return <span className="text-xs font-medium px-2 py-1 rounded" style={{ background: C.redSoft, color: C.red }}>Entrega en {diasRestantes} días</span>;
  }
  return null;
}

export default function SistemaDemo() {
  const [materiales, setMateriales] = useState(MATERIALES_INICIAL);
  const [cotizaciones, setCotizaciones] = useState(COTIZACIONES_INICIAL);
  const [ordenes, setOrdenes] = useState(ORDENES_INICIAL);
  const [compras, setCompras] = useState(COMPRAS_INICIAL);
  const [movimientos, setMovimientos] = useState(MOVIMIENTOS_INICIAL);

  const [screen, setScreen] = useState("dashboard");
  const [selectedOrden, setSelectedOrden] = useState(null);
  const [selectedCliente, setSelectedCliente] = useState(null);
  const [selectedTraza, setSelectedTraza] = useState(ORDENES_INICIAL[1].folio);
  const [devForm, setDevForm] = useState({ tipo: "Entrada devolución interna", materialId: "MAT-001", cantidad: 1, ref: "" });
  const [currentUserId, setCurrentUserId] = useState("USR-01");
  const pagos = PAGOS_INICIAL;
  const currentUser = USUARIOS.find((u) => u.id === currentUserId);

  const clienteDe = (id) => CLIENTES.find((c) => c.id === id);
  const ordenDe = (folio) => ordenes.find((o) => o.folio === folio);
  const materialDe = (id) => materiales.find((m) => m.id === id);
  const proveedorDe = (id) => PROVEEDORES.find((p) => p.id === id);
  const proveedorDeMaterial = (materialId) => PROVEEDORES.find((p) => p.materiales.includes(materialId));

  const log = (folio, ev) => {
    const t = "hoy · " + new Date().toLocaleTimeString("es-MX", { hour: "2-digit", minute: "2-digit" });
    setOrdenes((prev) => prev.map((o) => (o.folio === folio ? { ...o, historial: [...o.historial, { t, ev: `${ev} — ${currentUser.nombre} (${currentUser.rol})` }] } : o)));
  };

  const requisicionDe = (orden) => {
    const bom = BOM[orden.producto] || [];
    return bom.map((item) => {
      const requerido = item.cant * orden.cantidad;
      const disponible = materialDe(item.id)?.stock ?? 0;
      return { ...item, nombre: materialDe(item.id)?.nombre, unidad: materialDe(item.id)?.unidad, requerido, disponible, falta: Math.max(0, requerido - disponible) };
    });
  };

  const convertirCotizacion = (cot) => {
    const folio = "OC-2026-0" + (45 + ordenes.length);
    const nueva = {
      folio, cotFolio: cot.folio, clienteId: cot.clienteId, producto: cot.producto, cantidad: cot.cantidad, total: cot.total,
      estatus: "Pendiente de aprobar", folioProduccion: null,
      fechaCompromiso: "por definir", diasRestantes: 15, costoEstimado: null, costoReal: null,
      historial: [
        { t: cot.fecha, ev: `Cotización ${cot.folio} generada` },
        { t: "hoy", ev: `OC del cliente registrada — ${currentUser.nombre} (${currentUser.rol})` },
      ],
    };
    setOrdenes((prev) => [...prev, nueva]);
    setCotizaciones((prev) => prev.map((c) => (c.folio === cot.folio ? { ...c, convertida: true } : c)));
    setScreen("ordenes");
    setSelectedOrden(folio);
  };

  const aprobarOrden = (folio) => {
    const orden = ordenDe(folio);
    const req = requisicionDe(orden);
    const faltantes = req.filter((r) => r.falta > 0);
    const folioProduccion = "PROD-2026-" + folio.split("-").pop();
    const costoEstimado = req.reduce((s, r) => s + r.requerido * (materialDe(r.id)?.costo ?? 0), 0);
    const nuevoEstatus = faltantes.length ? "Compra a proveedor en curso" : "Lista para producción";
    setOrdenes((prev) => prev.map((o) => (o.folio === folio ? { ...o, estatus: nuevoEstatus, folioProduccion, costoEstimado } : o)));
    log(folio, `Aprobada — folio de producción ${folioProduccion} asignado`);
    log(folio, faltantes.length
      ? "Requisición: falta " + faltantes.map((f) => `${f.nombre} (${f.falta} ${f.unidad})`).join(", ")
      : "Requisición: stock suficiente");
  };

  const generarCompra = (folio) => {
    const orden = ordenDe(folio);
    const req = requisicionDe(orden);
    const faltantes = req.filter((r) => r.falta > 0);
    const porProveedor = {};
    faltantes.forEach((f) => {
      const prov = proveedorDeMaterial(f.id);
      const key = prov ? prov.id : "SIN-ASIGNAR";
      if (!porProveedor[key]) porProveedor[key] = [];
      porProveedor[key].push({ id: f.id, cant: f.falta, costoUnitario: PRECIO_ACTUALIZADO[f.id] ?? materialDe(f.id)?.costo ?? 0 });
    });
    const nuevas = Object.entries(porProveedor).map(([provId, items], idx) => ({
      folio: "OCP-2026-0" + (18 + compras.length + idx),
      ordenFolio: folio, proveedorId: provId === "SIN-ASIGNAR" ? null : provId,
      materiales: items, estatus: "Pendiente", fecha: "hoy",
    }));
    setCompras((prev) => [...prev, ...nuevas]);
    nuevas.forEach((c) => log(folio, `Compra a proveedor generada — ${c.folio}`));
    setScreen("compras");
  };

  const recibirCompra = (compraFolio) => {
    const compra = compras.find((c) => c.folio === compraFolio);
    setMateriales((prev) => prev.map((m) => {
      const item = compra.materiales.find((x) => x.id === m.id);
      return item ? { ...m, stock: m.stock + item.cant, costo: item.costoUnitario } : m;
    }));
    setMovimientos((prev) => [
      ...compra.materiales.map((it) => ({ t: "hoy", tipo: "Entrada compra", material: materialDe(it.id)?.nombre, cantidad: it.cant, ref: compraFolio })),
      ...prev,
    ]);
    const comprasActualizadas = compras.map((c) => (c.folio === compraFolio ? { ...c, estatus: "Recibida" } : c));
    setCompras(comprasActualizadas);
    const cambioDePrecio = compra.materiales.some((it) => it.costoUnitario !== materialDe(it.id)?.costo);
    log(compra.ordenFolio, `Entrada de almacén registrada — ${compraFolio}${cambioDePrecio ? " · costo actualizado" : ""}`);
    const todasRecibidas = comprasActualizadas.filter((c) => c.ordenFolio === compra.ordenFolio).every((c) => c.estatus === "Recibida");
    if (todasRecibidas) setOrdenes((prev) => prev.map((o) => (o.folio === compra.ordenFolio ? { ...o, estatus: "Lista para producción" } : o)));
  };

  const registrarSalida = (folio) => {
    const orden = ordenDe(folio);
    const req = requisicionDe(orden);
    const costoReal = req.reduce((s, r) => s + r.requerido * (materialDe(r.id)?.costo ?? 0), 0);
    setMateriales((prev) => prev.map((m) => {
      const item = req.find((r) => r.id === m.id);
      return item ? { ...m, stock: m.stock - item.requerido } : m;
    }));
    setMovimientos((prev) => [
      ...req.map((r) => ({ t: "hoy", tipo: "Salida producción", material: r.nombre, cantidad: r.requerido, ref: orden.folioProduccion })),
      ...prev,
    ]);
    setOrdenes((prev) => prev.map((o) => (o.folio === folio ? { ...o, estatus: "Surtida", costoReal } : o)));
    log(folio, "Salida de almacén registrada");
    log(folio, costoReal > orden.costoEstimado ? `Orden surtida · margen real por debajo del estimado (costo subió ${money(costoReal - orden.costoEstimado)})` : "Orden surtida · margen real conforme a lo cotizado");
  };

  const registrarDevolucion = () => {
    const mat = materialDe(devForm.materialId);
    const esEntrada = devForm.tipo.startsWith("Entrada");
    setMateriales((prev) => prev.map((m) => (m.id === devForm.materialId ? { ...m, stock: m.stock + (esEntrada ? 1 : -1) * devForm.cantidad } : m)));
    setMovimientos((prev) => [{ t: "hoy", tipo: devForm.tipo, material: mat.nombre, cantidad: devForm.cantidad, ref: devForm.ref || "—" }, ...prev]);
    setDevForm({ ...devForm, cantidad: 1, ref: "" });
  };

  const orden = selectedOrden ? ordenDe(selectedOrden) : null;
  const req = orden ? requisicionDe(orden) : [];
  const faltantes = req.filter((r) => r.falta > 0);
  const cliente = orden ? clienteDe(orden.clienteId) : null;
  const excedeCredito = cliente ? cliente.usado + orden.total > cliente.limite : false;
  const trazaOrden = ordenDe(selectedTraza);

  const ordenesEnProceso = ordenes.filter((o) => o.estatus !== "Surtida");
  const ordenesFinalizadas = ordenes.filter((o) => o.estatus === "Surtida");
  const valorEnProceso = ordenesEnProceso.reduce((s, o) => s + o.total, 0);
  const creditoUsado = CLIENTES.reduce((s, c) => s + c.usado, 0);
  const creditoLimite = CLIENTES.reduce((s, c) => s + c.limite, 0);
  const materialesBajoStock = materiales.filter((m) => m.stock < 5);
  const cotizacionesPendientes = cotizaciones.filter((c) => !c.convertida);
  const cli = selectedCliente ? clienteDe(selectedCliente) : null;
  const cotDeCliente = (id) => cotizaciones.filter((c) => c.clienteId === id);
  const ordenesDeCliente = (id) => ordenes.filter((o) => o.clienteId === id);

  return (
    <div className="flex w-full" style={{ background: C.bg, color: C.ink, fontFamily: "ui-sans-serif, system-ui, sans-serif", minHeight: 600 }}>
      <aside className="shrink-0 flex flex-col" style={{ width: 216, borderRight: `1px solid ${C.border}`, padding: "20px 12px" }}>
        <div className="px-2 mb-6">
          <div className="text-sm font-medium" style={{ color: C.ink }}>Control de producción</div>
          <div className="text-xs mt-0.5" style={{ color: C.inkMuted }}>Remolques · plataformas · tolvas · caja seca</div>
        </div>
        <nav className="flex flex-col gap-1">
          {NAV.map((n) => {
            const Icon = n.icon;
            const active = screen === n.id;
            return (
              <button
                key={n.id}
                onClick={() => { setScreen(n.id); setSelectedOrden(null); setSelectedCliente(null); }}
                className="flex items-center gap-2 text-sm px-3 py-2 rounded text-left"
                style={{ background: active ? C.accentSoft : "transparent", color: active ? C.accent : C.inkMuted, fontWeight: active ? 500 : 400 }}
              >
                <Icon size={16} />
                {n.label}
              </button>
            );
          })}
        </nav>
      </aside>

      <main className="flex-1 p-8 overflow-auto">
        <div className="flex items-center justify-end gap-2 mb-6">
          <span className="text-xs" style={{ color: C.inkMuted }}>Actuando como</span>
          <select value={currentUserId} onChange={(e) => setCurrentUserId(e.target.value)} className="text-sm px-2 py-1.5 rounded" style={{ border: `1px solid ${C.border}`, background: C.surface }}>
            {USUARIOS.map((u) => <option key={u.id} value={u.id}>{u.nombre} — {u.rol}</option>)}
          </select>
        </div>

        {screen === "dashboard" && (
          <div>
            <h1 className="text-lg font-medium mb-1">Dashboard</h1>
            <p className="text-sm mb-5" style={{ color: C.inkMuted }}>Cómo va el negocio hoy, de un vistazo.</p>

            <div className="grid grid-cols-4 gap-4 mb-6">
              {[
                { label: "Cotizaciones enviadas", value: cotizaciones.length, sub: `${cotizacionesPendientes.length} sin convertir` },
                { label: "OC en proceso", value: ordenesEnProceso.length, sub: money(valorEnProceso) },
                { label: "OC finalizadas", value: ordenesFinalizadas.length, sub: "este periodo" },
                { label: "Crédito abierto", value: money(creditoUsado), sub: `de ${money(creditoLimite)} disponible` },
              ].map((k) => (
                <div key={k.label} className="rounded p-4" style={{ background: C.surface, border: `1px solid ${C.border}` }}>
                  <div className="text-xs mb-2" style={{ color: C.inkMuted }}>{k.label}</div>
                  <div className="text-xl font-mono mb-1">{k.value}</div>
                  <div className="text-xs" style={{ color: C.inkMuted }}>{k.sub}</div>
                </div>
              ))}
            </div>

            <div className="grid grid-cols-2 gap-5">
              <div className="rounded" style={{ background: C.surface, border: `1px solid ${C.border}` }}>
                <div className="px-4 py-2 text-xs font-medium" style={{ borderBottom: `1px solid ${C.border}`, color: C.inkMuted }}>Órdenes en proceso</div>
                {ordenesEnProceso.length === 0 && <div className="px-4 py-3 text-sm" style={{ color: C.inkMuted }}>No hay órdenes en proceso.</div>}
                {ordenesEnProceso.map((o, i) => (
                  <button key={o.folio} onClick={() => { setScreen("ordenes"); setSelectedOrden(o.folio); }} className="w-full flex items-center justify-between px-4 py-2.5 text-left" style={{ borderTop: i ? `1px solid ${C.border}` : "none" }}>
                    <div className="flex flex-col">
                      <Folio>{o.folio}</Folio>
                      <span className="text-xs" style={{ color: C.inkMuted }}>{clienteDe(o.clienteId).nombre}</span>
                    </div>
                    <div className="flex items-center gap-2">
                      <EntregaBadge diasRestantes={o.diasRestantes} estatus={o.estatus} />
                      <StatusPill estatus={o.estatus} />
                    </div>
                  </button>
                ))}
              </div>

              <div className="rounded" style={{ background: C.surface, border: `1px solid ${C.border}` }}>
                <div className="px-4 py-2 text-xs font-medium" style={{ borderBottom: `1px solid ${C.border}`, color: C.inkMuted }}>Próximos cobros</div>
                {pagos.map((p, i) => (
                  <div key={i} className="flex items-center justify-between px-4 py-2.5 text-sm" style={{ borderTop: i ? `1px solid ${C.border}` : "none" }}>
                    <span>{clienteDe(p.clienteId).nombre}</span>
                    <div className="flex items-center gap-3">
                      <span className="text-xs" style={{ color: C.inkMuted }}>{p.fecha}</span>
                      <span className="font-mono text-xs">{money(p.monto)}</span>
                    </div>
                  </div>
                ))}
                <div className="px-4 py-2 text-xs font-medium mt-1" style={{ borderTop: `1px solid ${C.border}`, color: C.inkMuted }}>Material en alerta de stock</div>
                {materialesBajoStock.map((m, i) => (
                  <div key={m.id} className="flex items-center justify-between px-4 py-2.5 text-sm" style={{ borderTop: i ? `1px solid ${C.border}` : "none" }}>
                    <span>{m.nombre}</span>
                    <span className="font-mono text-xs" style={{ color: C.red }}>{m.stock} {m.unidad}</span>
                  </div>
                ))}
              </div>
            </div>
          </div>
        )}

        {screen === "clientes" && !cli && (
          <div>
            <h1 className="text-lg font-medium mb-1">Clientes</h1>
            <p className="text-sm mb-5" style={{ color: C.inkMuted }}>Datos generales, cotizaciones y órdenes de cada cliente.</p>
            <div className="rounded" style={{ background: C.surface, border: `1px solid ${C.border}` }}>
              {CLIENTES.map((c, i) => (
                <button key={c.id} onClick={() => setSelectedCliente(c.id)} className="w-full flex items-center justify-between px-4 py-3 text-left" style={{ borderTop: i ? `1px solid ${C.border}` : "none" }}>
                  <div className="flex flex-col gap-0.5">
                    <span className="text-sm font-medium">{c.nombre}</span>
                    <span className="text-xs" style={{ color: C.inkMuted }}>{c.contacto} · {c.telefono}</span>
                  </div>
                  <ChevronRight size={16} color={C.inkMuted} />
                </button>
              ))}
            </div>
          </div>
        )}

        {screen === "clientes" && cli && (
          <div>
            <button onClick={() => setSelectedCliente(null)} className="flex items-center gap-1 text-sm mb-4" style={{ color: C.inkMuted }}>
              <ArrowLeft size={14} /> Volver a clientes
            </button>
            <h1 className="text-lg font-medium mb-0.5">{cli.nombre}</h1>
            <p className="text-sm mb-5" style={{ color: C.inkMuted }}>{cli.razonSocial}</p>

            <div className="grid grid-cols-2 gap-5 mb-6">
              <div className="rounded p-4" style={{ background: C.surface, border: `1px solid ${C.border}` }}>
                <div className="text-sm font-medium mb-3">Datos generales</div>
                <div className="flex flex-col gap-1.5 text-sm">
                  <span><span style={{ color: C.inkMuted }}>Contacto: </span>{cli.contacto}</span>
                  <span><span style={{ color: C.inkMuted }}>Teléfono: </span>{cli.telefono}</span>
                  <span><span style={{ color: C.inkMuted }}>Correo: </span>{cli.correo}</span>
                </div>
              </div>
              <div className="rounded p-4" style={{ background: C.surface, border: `1px solid ${C.border}` }}>
                <div className="text-sm font-medium mb-2">Crédito</div>
                <div className="text-xs mb-1.5" style={{ color: C.inkMuted }}>{money(cli.usado)} usado de {money(cli.limite)}</div>
                <div className="h-1.5 rounded-full" style={{ background: C.border }}>
                  <div className="h-1.5 rounded-full" style={{ width: Math.min(100, (cli.usado / cli.limite) * 100) + "%", background: cli.usado > cli.limite * 0.9 ? C.red : C.accent }} />
                </div>
              </div>
            </div>

            <div className="rounded mb-6" style={{ background: C.surface, border: `1px solid ${C.border}` }}>
              <div className="px-4 py-2 text-xs font-medium" style={{ borderBottom: `1px solid ${C.border}`, color: C.inkMuted }}>Cotizaciones</div>
              {cotDeCliente(cli.id).map((c, i) => (
                <div key={c.folio} className="flex items-center justify-between px-4 py-2.5 text-sm" style={{ borderTop: i ? `1px solid ${C.border}` : "none" }}>
                  <div className="flex flex-col">
                    <Folio>{c.folio}</Folio>
                    <span className="text-xs" style={{ color: C.inkMuted }}>{c.producto} × {c.cantidad}</span>
                  </div>
                  <span className="text-xs" style={{ color: c.convertida ? C.green : C.inkMuted }}>{c.convertida ? "Convertida a OC" : "Sin convertir"}</span>
                </div>
              ))}
            </div>

            <div className="rounded" style={{ background: C.surface, border: `1px solid ${C.border}` }}>
              <div className="px-4 py-2 text-xs font-medium" style={{ borderBottom: `1px solid ${C.border}`, color: C.inkMuted }}>Órdenes de compra — en qué parte del proceso van</div>
              {ordenesDeCliente(cli.id).length === 0 && <div className="px-4 py-3 text-sm" style={{ color: C.inkMuted }}>Aún no tiene OC registradas.</div>}
              {ordenesDeCliente(cli.id).map((o, i) => (
                <button key={o.folio} onClick={() => { setScreen("ordenes"); setSelectedOrden(o.folio); }} className="w-full flex items-center justify-between px-4 py-2.5 text-left" style={{ borderTop: i ? `1px solid ${C.border}` : "none" }}>
                  <div className="flex flex-col">
                    <Folio>{o.folio}</Folio>
                    <span className="text-xs" style={{ color: C.inkMuted }}>{o.producto} × {o.cantidad}</span>
                  </div>
                  <StatusPill estatus={o.estatus} />
                </button>
              ))}
            </div>
          </div>
        )}

        {screen === "cotizaciones" && (
          <div>
            <h1 className="text-lg font-medium mb-1">Cotizaciones</h1>
            <p className="text-sm mb-5" style={{ color: C.inkMuted }}>Cuando el cliente acepta, se convierte en orden de compra.</p>
            <div className="rounded" style={{ background: C.surface, border: `1px solid ${C.border}` }}>
              {cotizaciones.map((c, i) => (
                <div key={c.folio} className="flex items-center justify-between px-4 py-3" style={{ borderTop: i ? `1px solid ${C.border}` : "none" }}>
                  <div className="flex flex-col gap-0.5">
                    <Folio>{c.folio}</Folio>
                    <span className="text-sm">{clienteDe(c.clienteId).nombre} — {c.producto} × {c.cantidad}</span>
                    <span className="text-xs" style={{ color: C.inkMuted }}>{c.fecha}</span>
                  </div>
                  <div className="flex items-center gap-4">
                    <span className="text-sm font-mono">{money(c.total)}</span>
                    {c.convertida ? (
                      <span className="text-xs" style={{ color: C.inkMuted }}>Ya convertida</span>
                    ) : (
                      <button onClick={() => convertirCotizacion(c)} className="flex items-center gap-1 text-xs font-medium px-3 py-1.5 rounded" style={{ background: C.accent, color: "#fff" }}>
                        <Plus size={14} /> Convertir a OC
                      </button>
                    )}
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}

        {screen === "ordenes" && !orden && (
          <div>
            <h1 className="text-lg font-medium mb-1">Órdenes de compra</h1>
            <p className="text-sm mb-5" style={{ color: C.inkMuted }}>Cada OC enlaza cotización, requisición de material y almacén.</p>
            <div className="rounded" style={{ background: C.surface, border: `1px solid ${C.border}` }}>
              {ordenes.map((o, i) => (
                <button key={o.folio} onClick={() => setSelectedOrden(o.folio)} className="w-full flex items-center justify-between px-4 py-3 text-left" style={{ borderTop: i ? `1px solid ${C.border}` : "none" }}>
                  <div className="flex flex-col gap-0.5">
                    <Folio>{o.folio}</Folio>
                    <span className="text-sm">{clienteDe(o.clienteId).nombre} — {o.producto} × {o.cantidad}</span>
                  </div>
                  <div className="flex items-center gap-3">
                    <EntregaBadge diasRestantes={o.diasRestantes} estatus={o.estatus} />
                    <StatusPill estatus={o.estatus} />
                    <ChevronRight size={16} color={C.inkMuted} />
                  </div>
                </button>
              ))}
            </div>
          </div>
        )}

        {screen === "ordenes" && orden && (
          <div>
            <button onClick={() => setSelectedOrden(null)} className="flex items-center gap-1 text-sm mb-4" style={{ color: C.inkMuted }}>
              <ArrowLeft size={14} /> Volver a órdenes
            </button>
            <div className="flex items-start justify-between mb-1">
              <div>
                <div className="flex items-center gap-2 mb-1">
                  <Folio>{orden.folio}</Folio>
                  <StatusPill estatus={orden.estatus} />
                </div>
                <h1 className="text-lg font-medium">{cliente.nombre} — {orden.producto} × {orden.cantidad}</h1>
              </div>
              <span className="text-lg font-mono">{money(orden.total)}</span>
            </div>
            {orden.folioProduccion && (
              <p className="text-sm mb-2" style={{ color: C.inkMuted }}>Folio de producción: <Folio>{orden.folioProduccion}</Folio></p>
            )}
            <div className="flex items-center gap-2 mb-5">
              <span className="text-sm" style={{ color: C.inkMuted }}>Entrega comprometida: {orden.fechaCompromiso}</span>
              <EntregaBadge diasRestantes={orden.diasRestantes} estatus={orden.estatus} />
            </div>

            {orden.costoEstimado != null && (
              <div className="rounded p-4 mb-5" style={{ background: C.surface, border: `1px solid ${C.border}` }}>
                <div className="text-sm font-medium mb-2">Costeo de material</div>
                <div className="text-xs mb-3" style={{ color: C.inkMuted }}>Solo material — no incluye mano de obra ni gastos indirectos.</div>
                <div className="grid grid-cols-3 gap-4 text-sm">
                  <div><div className="text-xs" style={{ color: C.inkMuted }}>Venta</div><div className="font-mono">{money(orden.total)}</div></div>
                  <div><div className="text-xs" style={{ color: C.inkMuted }}>Material — cotizado</div><div className="font-mono">{money(orden.costoEstimado)}</div></div>
                  <div>
                    <div className="text-xs" style={{ color: C.inkMuted }}>{orden.costoReal != null ? "Material — real" : "Margen bruto estimado"}</div>
                    <div className="font-mono" style={{ color: orden.costoReal != null && orden.costoReal > orden.costoEstimado ? C.red : C.ink }}>
                      {orden.costoReal != null ? money(orden.costoReal) : money(orden.total - orden.costoEstimado)}
                    </div>
                  </div>
                </div>
                {orden.costoReal != null && orden.costoReal !== orden.costoEstimado && (
                  <div className="flex items-center gap-1.5 text-xs mt-2" style={{ color: orden.costoReal > orden.costoEstimado ? C.red : C.green }}>
                    <AlertTriangle size={13} /> Margen bruto real {money(orden.total - orden.costoReal)}, {orden.costoReal > orden.costoEstimado ? "por debajo" : "por arriba"} de lo cotizado
                  </div>
                )}
              </div>
            )}

            <div className="grid grid-cols-2 gap-5 mb-5">
              <div className="rounded p-4" style={{ background: C.surface, border: `1px solid ${C.border}` }}>
                <div className="text-sm font-medium mb-2">Crédito del cliente</div>
                <div className="text-xs mb-1.5" style={{ color: C.inkMuted }}>{money(cliente.usado)} usado de {money(cliente.limite)}</div>
                <div className="h-1.5 rounded-full mb-2" style={{ background: C.border }}>
                  <div className="h-1.5 rounded-full" style={{ width: Math.min(100, (cliente.usado / cliente.limite) * 100) + "%", background: excedeCredito ? C.red : C.accent }} />
                </div>
                {excedeCredito && (
                  <div className="flex items-center gap-1.5 text-xs" style={{ color: C.red }}>
                    <AlertTriangle size={13} /> Esta OC excede el crédito disponible
                  </div>
                )}
              </div>

              <div className="rounded p-4" style={{ background: C.surface, border: `1px solid ${C.border}` }}>
                <div className="text-sm font-medium mb-2">Requisición de material</div>
                {orden.folioProduccion ? (
                  faltantes.length ? (
                    <div className="text-xs" style={{ color: C.red }}>Faltan {faltantes.length} material(es) — ver detalle abajo</div>
                  ) : (
                    <div className="flex items-center gap-1.5 text-xs" style={{ color: C.green }}><CheckCircle2 size={13} /> Stock suficiente</div>
                  )
                ) : (
                  <div className="text-xs" style={{ color: C.inkMuted }}>Se calcula al aprobar la orden</div>
                )}
              </div>
            </div>

            {orden.folioProduccion && (
              <div className="rounded mb-5" style={{ background: C.surface, border: `1px solid ${C.border}` }}>
                <div className="px-4 py-2 text-xs font-medium" style={{ borderBottom: `1px solid ${C.border}`, color: C.inkMuted }}>Material requerido vs. inventario</div>
                {req.map((r, i) => (
                  <div key={r.id} className="flex items-center justify-between px-4 py-2 text-sm" style={{ borderTop: i ? `1px solid ${C.border}` : "none" }}>
                    <span>{r.nombre}</span>
                    <span className="font-mono text-xs" style={{ color: r.falta > 0 ? C.red : C.inkMuted }}>
                      {r.disponible} / {r.requerido} {r.unidad} {r.falta > 0 ? `· falta ${r.falta}` : ""}
                    </span>
                  </div>
                ))}
              </div>
            )}

            <div className="flex gap-3 mb-6">
              {orden.estatus === "Pendiente de aprobar" && (
                <BotonAccion
                  rolesPermitidos={excedeCredito ? ["Gerencia"] : ["Ventas", "Gerencia"]}
                  rolActual={currentUser.rol} color={C.accent}
                  label={excedeCredito ? "Aprobar orden (excede crédito)" : "Aprobar orden"}
                  onClick={() => aprobarOrden(orden.folio)}
                />
              )}
              {orden.estatus === "Compra a proveedor en curso" && !compras.some((c) => c.ordenFolio === orden.folio) && (
                <BotonAccion rolesPermitidos={["Compras", "Gerencia"]} rolActual={currentUser.rol} color={C.amber} label="Generar compra a proveedor" onClick={() => generarCompra(orden.folio)} />
              )}
              {orden.estatus === "Compra a proveedor en curso" && compras.some((c) => c.ordenFolio === orden.folio) && (
                <span className="text-sm self-center" style={{ color: C.inkMuted }}>Esperando entrada de material — ver Compra a proveedor</span>
              )}
              {orden.estatus === "Lista para producción" && (
                <BotonAccion rolesPermitidos={["Almacén", "Gerencia"]} rolActual={currentUser.rol} color={C.green} label="Registrar salida de almacén" onClick={() => registrarSalida(orden.folio)} />
              )}
              {orden.estatus === "Surtida" && (
                <span className="flex items-center gap-1.5 text-sm" style={{ color: C.green }}><CheckCircle2 size={15} /> Orden surtida</span>
              )}
            </div>

            <div className="text-sm font-medium mb-2">Historial</div>
            <div className="flex flex-col gap-3">
              {orden.historial.map((h, i) => (
                <div key={i} className="flex gap-3 text-sm">
                  <span className="font-mono text-xs shrink-0 pt-0.5" style={{ color: C.inkMuted, width: 90 }}>{h.t}</span>
                  <span>{h.ev}</span>
                </div>
              ))}
            </div>
          </div>
        )}

        {screen === "compras" && (
          <div>
            <h1 className="text-lg font-medium mb-1">Compra a proveedor</h1>
            <p className="text-sm mb-5" style={{ color: C.inkMuted }}>Se genera cuando la requisición detecta material faltante.</p>
            <div className="rounded" style={{ background: C.surface, border: `1px solid ${C.border}` }}>
              {compras.map((c, i) => {
                const prov = c.proveedorId ? proveedorDe(c.proveedorId) : null;
                return (
                  <div key={c.folio} className="flex items-center justify-between px-4 py-3" style={{ borderTop: i ? `1px solid ${C.border}` : "none" }}>
                    <div className="flex flex-col gap-0.5">
                      <div className="flex items-center gap-2">
                        <Folio>{c.folio}</Folio>
                        <span className="text-xs" style={{ color: C.inkMuted }}>ligada a {c.ordenFolio}</span>
                      </div>
                      <span className="text-sm">{prov ? prov.nombre : "Sin proveedor asignado"}</span>
                      <span className="text-xs" style={{ color: C.inkMuted }}>
                        {c.materiales.map((m) => `${materialDe(m.id)?.nombre} × ${m.cant} — ${money(m.costoUnitario)} c/u`).join(" · ")}
                        {prov ? ` · entrega en ${prov.tiempoEntregaDias} días` : ""}
                      </span>
                    </div>
                    <div className="flex items-center gap-4">
                      <StatusPill estatus={c.estatus} />
                      {c.estatus === "Pendiente" && (
                        <BotonAccion rolesPermitidos={["Almacén", "Gerencia"]} rolActual={currentUser.rol} color={C.accent} label="Registrar entrada" compact onClick={() => recibirCompra(c.folio)} />
                      )}
                    </div>
                  </div>
                );
              })}
            </div>
          </div>
        )}

        {screen === "proveedores" && (
          <div>
            <h1 className="text-lg font-medium mb-1">Proveedores</h1>
            <p className="text-sm mb-5" style={{ color: C.inkMuted }}>A quién le compramos cada material y en cuánto tiempo entrega.</p>
            <div className="rounded" style={{ background: C.surface, border: `1px solid ${C.border}` }}>
              {PROVEEDORES.map((p, i) => (
                <div key={p.id} className="px-4 py-3" style={{ borderTop: i ? `1px solid ${C.border}` : "none" }}>
                  <div className="flex items-center justify-between mb-1">
                    <span className="text-sm font-medium">{p.nombre}</span>
                    <span className="text-xs font-mono" style={{ color: C.inkMuted }}>entrega en {p.tiempoEntregaDias} días · {p.condicionesPago}</span>
                  </div>
                  <div className="text-xs" style={{ color: C.inkMuted }}>{p.contacto} · {p.telefono}</div>
                  <div className="text-xs mt-1" style={{ color: C.inkMuted }}>Surte: {p.materiales.map((id) => materialDe(id)?.nombre).join(", ")}</div>
                </div>
              ))}
            </div>
          </div>
        )}

        {screen === "almacen" && (
          <div>
            <h1 className="text-lg font-medium mb-1">Almacén</h1>
            <p className="text-sm mb-5" style={{ color: C.inkMuted }}>Existencias y bitácora de entradas y salidas.</p>

            <div className="rounded mb-6" style={{ background: C.surface, border: `1px solid ${C.border}` }}>
              <div className="px-4 py-2 text-xs font-medium" style={{ borderBottom: `1px solid ${C.border}`, color: C.inkMuted }}>Existencias</div>
              {materiales.map((m, i) => {
                const Icon = ICONOS_MATERIAL[m.icono] || Package;
                return (
                  <div key={m.id} className="flex items-center justify-between px-4 py-2.5 text-sm" style={{ borderTop: i ? `1px solid ${C.border}` : "none" }}>
                    <div className="flex items-center gap-2.5">
                      <div className="flex items-center justify-center rounded" style={{ width: 28, height: 28, background: C.accentSoft, color: C.accent }}>
                        <Icon size={15} />
                      </div>
                      <span>{m.nombre}</span>
                    </div>
                    <span className="font-mono text-xs" style={{ color: m.stock === 0 ? C.red : C.inkMuted }}>{m.stock} {m.unidad}</span>
                  </div>
                );
              })}
            </div>

            <div className="rounded p-4 mb-6" style={{ background: C.surface, border: `1px solid ${C.border}` }}>
              <div className="text-sm font-medium mb-3">Registrar devolución</div>
              <div className="flex flex-wrap gap-2 items-end">
                <select value={devForm.tipo} onChange={(e) => setDevForm({ ...devForm, tipo: e.target.value })} className="text-sm px-2 py-1.5 rounded" style={{ border: `1px solid ${C.border}`, background: C.surface }}>
                  <option>Entrada devolución interna</option>
                  <option>Entrada devolución de cliente</option>
                  <option>Salida devolución a proveedor</option>
                </select>
                <select value={devForm.materialId} onChange={(e) => setDevForm({ ...devForm, materialId: e.target.value })} className="text-sm px-2 py-1.5 rounded" style={{ border: `1px solid ${C.border}`, background: C.surface }}>
                  {materiales.map((m) => <option key={m.id} value={m.id}>{m.nombre}</option>)}
                </select>
                <input type="number" min="1" value={devForm.cantidad} onChange={(e) => setDevForm({ ...devForm, cantidad: Number(e.target.value) })} className="text-sm px-2 py-1.5 rounded w-20" style={{ border: `1px solid ${C.border}` }} />
                <input placeholder="Referencia (folio)" value={devForm.ref} onChange={(e) => setDevForm({ ...devForm, ref: e.target.value })} className="text-sm px-2 py-1.5 rounded w-40" style={{ border: `1px solid ${C.border}` }} />
                <BotonAccion rolesPermitidos={["Almacén", "Gerencia"]} rolActual={currentUser.rol} color={C.accent} label="Registrar" compact onClick={registrarDevolucion} />
              </div>
            </div>

            <div className="rounded" style={{ background: C.surface, border: `1px solid ${C.border}` }}>
              <div className="px-4 py-2 text-xs font-medium" style={{ borderBottom: `1px solid ${C.border}`, color: C.inkMuted }}>Bitácora de movimientos</div>
              {movimientos.map((m, i) => (
                <div key={i} className="flex items-center justify-between px-4 py-2.5 text-sm" style={{ borderTop: i ? `1px solid ${C.border}` : "none" }}>
                  <div className="flex items-center gap-3">
                    <span className="font-mono text-xs shrink-0" style={{ color: C.inkMuted, width: 130 }}>{m.tipo}</span>
                    <span>{m.material}</span>
                  </div>
                  <div className="flex items-center gap-4">
                    <span className="text-xs" style={{ color: C.inkMuted }}>{m.ref}</span>
                    <span className="font-mono text-xs">{m.cantidad}</span>
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}

        {screen === "trazabilidad" && (
          <div>
            <h1 className="text-lg font-medium mb-1">Trazabilidad</h1>
            <p className="text-sm mb-5" style={{ color: C.inkMuted }}>El recorrido completo de una orden, de cotización a almacén.</p>
            <select value={selectedTraza} onChange={(e) => setSelectedTraza(e.target.value)} className="text-sm px-3 py-2 rounded mb-6" style={{ border: `1px solid ${C.border}`, background: C.surface }}>
              {ordenes.map((o) => <option key={o.folio} value={o.folio}>{o.folio} — {clienteDe(o.clienteId).nombre}</option>)}
            </select>

            {trazaOrden && (
              <div className="flex flex-col">
                {trazaOrden.historial.map((h, i) => (
                  <div key={i} className="flex gap-3">
                    <div className="flex flex-col items-center">
                      <div style={{ width: 8, height: 8, background: C.accent }} />
                      {i < trazaOrden.historial.length - 1 && <div style={{ width: 1, flex: 1, background: C.border, minHeight: 28 }} />}
                    </div>
                    <div className="pb-5">
                      <div className="text-xs font-mono mb-0.5" style={{ color: C.inkMuted }}>{h.t}</div>
                      <div className="text-sm">{h.ev}</div>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>
        )}
      </main>
    </div>
  );
}
