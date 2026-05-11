import type { CSSProperties } from 'react';
import type { Cotizacion, Cliente, Producto, Ajustes } from '../../types';
import {
  formatearMoneda,
  formatearFecha,
  calcularTotalesCotizacionServiciosAware,
  totalItemServicio,
} from '../../utils/calculations';

// ─── Design tokens ────────────────────────────────────────────────────────────
const PURPLE = '#6351D3';

/** DM Mono — labels, numbers, codes */
const m = (sz: number, op?: number): CSSProperties => ({
  fontFamily: "'DM Mono', 'Courier New', monospace",
  fontSize: sz,
  fontWeight: 500,
  letterSpacing: '0.08em',
  lineHeight: 1.2,
  ...(op !== undefined ? { color: `rgba(0,0,0,${op})` } : {}),
});

/** DM Sans — headings, body text */
const s = (sz: number, w: 400 | 500 | 700 = 400, op?: number): CSSProperties => ({
  fontFamily: "'DM Sans', 'Helvetica Neue', Arial, sans-serif",
  fontSize: sz,
  fontWeight: w,
  lineHeight: 1.3,
  ...(op !== undefined ? { color: `rgba(0,0,0,${op})` } : {}),
});

// ─── Sub-components ───────────────────────────────────────────────────────────

function Divider({ opacity = 0.1, height = 1 }: { opacity?: number; height?: number }) {
  return <div style={{ height, background: `rgba(0,0,0,${opacity})`, flexShrink: 0 }} />;
}

function AccentLine() {
  return <div style={{ height: 4, background: PURPLE, flexShrink: 0 }} />;
}

function PageHeader({
  empresa,
  tagline,
  ajustes,
  compact = false,
  folio,
}: {
  empresa: string;
  tagline: string;
  ajustes: Ajustes;
  compact?: boolean;
  folio?: string;
}) {
  if (compact) {
    return (
      <header
        style={{
          background: '#000',
          padding: '18px 40px',
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
          flexShrink: 0,
        }}
      >
        <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
          <div style={{ width: 22, height: 22, background: 'rgba(255,255,255,0.12)', borderRadius: 3 }} />
          <span style={{ ...s(15, 700), color: '#fff' }}>{empresa}</span>
        </div>
        <span style={{ ...m(9, 1), color: 'rgba(255,255,255,0.4)' }}>
          Cotización {folio}
        </span>
      </header>
    );
  }

  return (
    <header
      style={{
        background: '#000',
        padding: '26px 40px',
        display: 'flex',
        justifyContent: 'space-between',
        alignItems: 'center',
        flexShrink: 0,
      }}
    >
      {/* Brand */}
      <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
          <div style={{ width: 26, height: 26, background: 'rgba(255,255,255,0.12)', borderRadius: 3 }} />
          <span style={{ ...s(17, 700), color: '#fff' }}>{empresa}</span>
        </div>
        <span style={{ ...m(9, 1), color: 'rgba(255,255,255,0.45)', textTransform: 'none' }}>
          {tagline}
        </span>
      </div>

      {/* Contact */}
      <div style={{ display: 'flex', flexDirection: 'column', gap: 3, alignItems: 'flex-end' }}>
        {[ajustes.direccion, ajustes.email, ajustes.telefono, ajustes.sitio_web]
          .filter(Boolean)
          .map((line, i) => (
            <span key={i} style={{ ...m(8, 1), color: 'rgba(255,255,255,0.5)' }}>
              {line}
            </span>
          ))}
      </div>
    </header>
  );
}

function PageFooter({
  empresa,
  sitio,
  page,
  total,
  hoy,
}: {
  empresa: string;
  sitio: string;
  page: string;
  total: number;
  hoy: string;
}) {
  return (
    <footer
      style={{
        height: 41,
        borderTop: '1px solid rgba(0,0,0,0.1)',
        display: 'flex',
        justifyContent: 'space-between',
        alignItems: 'center',
        padding: '0 24px',
        flexShrink: 0,
        background: '#fff',
      }}
    >
      <span style={{ ...s(8, 700) }}>{sitio || empresa}</span>
      <div style={{ display: 'flex', gap: 16, alignItems: 'center' }}>
        <span style={{ ...m(8, 1), color: 'rgba(0,0,0,0.3)' }}>Generada el {hoy}</span>
        <span style={{ ...m(8, 1), color: 'rgba(0,0,0,0.25)' }}>{page}</span>
      </div>
      <span style={{ ...s(8, 700, 0.3) }}>{empresa}</span>
    </footer>
  );
}

// ─── Badge de estado ──────────────────────────────────────────────────────────
const estadoBadgeMap: Record<string, { bg: string; color: string }> = {
  Borrador: { bg: 'rgba(0,0,0,0.06)', color: 'rgba(0,0,0,0.5)' },
  Enviada:  { bg: '#dbeafe', color: '#1d4ed8' },
  Aprobada: { bg: '#dcfce7', color: '#166534' },
  Cancelada:{ bg: '#fee2e2', color: '#991b1b' },
  Pagada:   { bg: '#dcfce7', color: '#166534' },
};

// ─── Props ────────────────────────────────────────────────────────────────────
interface PDFTemplateMoodboardProps {
  cotizacion: Cotizacion;
  cliente?: Cliente | null;
  productos: Producto[];
  ajustes: Ajustes;
}

// ─── Main component ───────────────────────────────────────────────────────────
export function PDFTemplateMoodboard({
  cotizacion,
  cliente,
  productos,
  ajustes,
}: PDFTemplateMoodboardProps) {
  // Product lookup map
  const idx = productos.reduce<Record<string, Producto>>((acc, p) => {
    if (p?.id) acc[p.id] = p;
    return acc;
  }, {});

  const totales = calcularTotalesCotizacionServiciosAware(
    cotizacion.items ?? [],
    idx,
    ajustes.iva_por_defecto,
    cotizacion.con_factura !== false,
  );

  const empresa = ajustes.nombre_empresa || 'ideally.';
  const tagline = ajustes.tagline || 'Arte · Diseño · Ingeniería';
  const hoy = formatearFecha(new Date().toISOString());
  const badge = estadoBadgeMap[cotizacion.estado] ?? estadoBadgeMap.Borrador;

  const items = cotizacion.items ?? [];

  // Pre-compute per-row totals
  const itemTotals = items.map((item) => {
    const produto = item.producto_id ? idx[item.producto_id] : undefined;
    const esServicio = produto?.tipo === 'servicio' && !!produto.servicio;

    if (esServicio && produto.servicio) {
      const calc = totalItemServicio(
        item,
        produto,
        cotizacion.con_factura !== false ? ajustes.iva_por_defecto : 0,
      );
      const plan = produto.servicio;
      let precioDisplay = '';
      if (plan.modo === 'unico')       precioDisplay = formatearMoneda(plan.setup_precio ?? 0);
      else if (plan.modo === 'suscripcion') precioDisplay = `${formatearMoneda(plan.recur_precio ?? 0)}/${plan.periodo}`;
      else precioDisplay = `${formatearMoneda(plan.setup_precio ?? 0)} + ${formatearMoneda(plan.recur_precio ?? 0)}/mes`;
      return { total: calc.total, precioDisplay, esServicio: true, produto };
    }

    const base = (item.cantidad ?? 0) * (item.precio_unitario ?? 0);
    const totalConIva = cotizacion.con_factura !== false
      ? base * (1 + ajustes.iva_por_defecto)
      : base;
    return {
      total: totalConIva,
      precioDisplay: formatearMoneda(item.precio_unitario ?? 0),
      esServicio: false,
      produto,
    };
  });

  const srvItems = items.filter((_, i) => itemTotals[i].esServicio);

  // ─── PAGE 1 ────────────────────────────────────────────────────────────────
  const page1: CSSProperties = {
    width: 794,
    minHeight: 1123,
    display: 'flex',
    flexDirection: 'column',
    background: '#fff',
    boxSizing: 'border-box',
  };

  // ─── PAGE 2 ────────────────────────────────────────────────────────────────
  const page2: CSSProperties = {
    ...page1,
    breakBefore: 'page',
    pageBreakBefore: 'always',
  };

  return (
    <div id="pdf-content" style={{ fontFamily: "'DM Sans', sans-serif", color: '#000', background: '#fff' }}>

      {/* ══════════════════════ PAGE 1 ══════════════════════ */}
      <div style={page1}>
        <PageHeader empresa={empresa} tagline={tagline} ajustes={ajustes} />
        <AccentLine />

        {/* Content */}
        <div style={{ flex: 1, padding: '36px 40px 28px', display: 'flex', flexDirection: 'column', gap: 24 }}>

          {/* ── CLIENT INFO + QUOTE META ── */}
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', gap: 24 }}>

            {/* Bill To */}
            <div style={{ display: 'flex', flexDirection: 'column', gap: 5 }}>
              <span style={{ ...m(9, 0.4), textTransform: 'uppercase' }}>Facturar a</span>
              <span style={{ ...s(15, 700) }}>{cliente?.nombre_razon_social || 'Cliente'}</span>
              {cliente?.nombre_contacto && (
                <span style={{ ...s(10, 400, 0.6) }}>Atención: {cliente.nombre_contacto}</span>
              )}
              {(cliente?.ciudad || cliente?.estado) && (
                <span style={{ ...s(10, 400, 0.6) }}>
                  {[cliente.ciudad, cliente.estado].filter(Boolean).join(', ')}
                </span>
              )}
              {cliente?.correo && (
                <span style={{ ...s(10, 500), color: PURPLE }}>{cliente.correo}</span>
              )}
              {cliente?.telefono && (
                <span style={{ ...s(10, 400, 0.5) }}>{cliente.telefono}</span>
              )}
            </div>

            {/* Quote Meta */}
            <div style={{ display: 'flex', flexDirection: 'column', gap: 10, alignItems: 'flex-end' }}>
              <span style={{ ...m(9, 0.4), textTransform: 'uppercase' }}>Cotización</span>
              <div style={{ display: 'flex', gap: 20, alignItems: 'flex-start' }}>
                {/* Número */}
                <div style={{ display: 'flex', flexDirection: 'column', gap: 4, alignItems: 'flex-start' }}>
                  <span style={{ ...s(9, 400, 0.45) }}>Número</span>
                  <span style={{ ...m(12, 1), color: PURPLE }}>{cotizacion.folio}</span>
                </div>
                {/* Fecha */}
                <div style={{ display: 'flex', flexDirection: 'column', gap: 4 }}>
                  <span style={{ ...s(9, 400, 0.45) }}>Fecha</span>
                  <span style={{ ...s(12, 500) }}>{formatearFecha(cotizacion.fecha)}</span>
                </div>
                {/* Vigencia */}
                <div style={{ display: 'flex', flexDirection: 'column', gap: 4 }}>
                  <span style={{ ...s(9, 400, 0.45) }}>Vigencia</span>
                  <span style={{ ...s(12, 500) }}>{cotizacion.validez_dias} días</span>
                </div>
                {/* Estado */}
                <div style={{ display: 'flex', flexDirection: 'column', gap: 4 }}>
                  <span style={{ ...s(9, 400, 0.45) }}>Estado</span>
                  <span
                    style={{
                      ...m(8, 1),
                      background: badge.bg,
                      color: badge.color,
                      padding: '4px 8px',
                      borderRadius: 4,
                      textTransform: 'uppercase',
                    }}
                  >
                    {cotizacion.estado}
                  </span>
                </div>
              </div>
            </div>
          </div>

          {/* Descripción del proyecto (si existe) */}
          {cotizacion.descripcion && (
            <div
              style={{
                padding: '12px 16px',
                background: 'rgba(99,81,211,0.05)',
                borderLeft: `3px solid ${PURPLE}`,
                borderRadius: '0 4px 4px 0',
              }}
            >
              <span style={{ ...s(9, 700, 0.7) }}>Proyecto: </span>
              <span style={{ ...s(9, 400, 0.6) }}>{cotizacion.descripcion}</span>
            </div>
          )}

          <Divider />

          {/* ── SERVICES TABLE ── */}
          <div style={{ display: 'flex', flexDirection: 'column' }}>

            {/* Table header row */}
            <div
              style={{
                display: 'flex',
                justifyContent: 'space-between',
                alignItems: 'flex-end',
                paddingBottom: 12,
              }}
            >
              <div style={{ display: 'flex', flexDirection: 'column', gap: 4, flex: 1 }}>
                <span style={{ ...s(14, 700) }}>Servicios / Productos</span>
                <span style={{ ...m(8, 0.35), textTransform: 'uppercase' }}>Descripción</span>
              </div>
              <div style={{ display: 'flex', gap: 16 }}>
                {['Cant.', 'Precio Unit.', 'Total'].map((col) => (
                  <span
                    key={col}
                    style={{ ...m(8, 0.35), minWidth: 72, textAlign: 'right', textTransform: 'uppercase' }}
                  >
                    {col}
                  </span>
                ))}
              </div>
            </div>

            {/* Strong header separator */}
            <Divider opacity={0.88} height={2} />

            {/* Rows */}
            {items.map((item, i) => {
              const { total, precioDisplay, esServicio, produto } = itemTotals[i];
              const isLast = i === items.length - 1;

              return (
                <div key={item.id ?? i}>
                  <div
                    style={{
                      display: 'flex',
                      alignItems: 'center',
                      padding: '13px 0',
                      gap: 12,
                    }}
                  >
                    {/* Purple dot */}
                    <div
                      style={{ width: 3, height: 3, background: PURPLE, flexShrink: 0, marginTop: 2 }}
                    />

                    {/* Description block */}
                    <div style={{ flex: 1, display: 'flex', flexDirection: 'column', gap: 3 }}>
                      <span style={{ ...s(13, 700) }}>
                        {produto?.nombre || item.descripcion}
                      </span>
                      {produto?.descripcion && (
                        <span style={{ ...s(10, 400, 0.5) }}>{produto.descripcion}</span>
                      )}
                      {esServicio && (
                        <span style={{ ...s(9, 400, 0.4) }}>
                          {item.meses_cobrados ? `• ${item.meses_cobrados} mes(es)` : ''}
                          {item.incluir_setup ? ' • Setup incluido' : ''}
                          {item.asientos_extra ? ` • ${item.asientos_extra} asientos extra` : ''}
                        </span>
                      )}
                    </div>

                    {/* Pricing columns */}
                    <div style={{ display: 'flex', gap: 16, alignItems: 'center' }}>
                      <span style={{ ...s(10, 400, 0.6), minWidth: 72, textAlign: 'right' }}>
                        {item.cantidad} {item.unidad}
                      </span>
                      <span style={{ ...m(9, 0.55), minWidth: 84, textAlign: 'right' }}>
                        {precioDisplay}
                      </span>
                      <span style={{ ...m(12, 1), minWidth: 84, textAlign: 'right' }}>
                        {formatearMoneda(total)}
                      </span>
                    </div>
                  </div>

                  {!isLast && <Divider opacity={0.08} />}
                </div>
              );
            })}
          </div>

          {/* ── RESUMEN DE SERVICIOS ── */}
          {srvItems.length > 0 && (
            <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
              {/* Purple separator + label */}
              <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
                <div style={{ height: 2, background: `${PURPLE}cc` }} />
                <span style={{ ...s(13, 700) }}>Resumen de Servicios</span>
              </div>

              {/* Cards row */}
              <div style={{ display: 'flex', gap: 20 }}>
                {srvItems.map((item, i) => {
                  const produto = item.producto_id ? idx[item.producto_id] : undefined;
                  const srv = produto?.servicio;
                  if (!srv) return null;

                  return (
                    <div
                      key={i}
                      style={{
                        flex: 1,
                        display: 'flex',
                        flexDirection: 'column',
                        gap: 6,
                        paddingTop: 12,
                      }}
                    >
                      <div style={{ height: 3, background: PURPLE }} />
                      <span style={{ ...s(10, 700) }}>{produto?.nombre || item.descripcion}</span>

                      {srv.modo === 'unico' && (
                        <>
                          <span style={{ ...s(9, 400, 0.55) }}>• Pago único</span>
                          <span style={{ ...s(9, 400, 0.55) }}>• Incluye setup completo</span>
                        </>
                      )}
                      {srv.modo === 'suscripcion' && (
                        <>
                          <span style={{ ...s(9, 400, 0.55) }}>• Servicio de suscripción</span>
                          <span style={{ ...s(9, 400, 0.55) }}>• Periodo: {srv.periodo}</span>
                          <span style={{ ...s(9, 400, 0.55) }}>• Meses contratados: {item.meses_cobrados || 1}</span>
                          {(srv.min_meses ?? 0) > 1 && (
                            <span style={{ ...s(9, 400, 0.55) }}>• Permanencia mínima: {srv.min_meses} meses</span>
                          )}
                        </>
                      )}
                      {srv.modo === 'hibrido' && (
                        <>
                          <span style={{ ...s(9, 400, 0.55) }}>• Servicio híbrido</span>
                          {item.incluir_setup && <span style={{ ...s(9, 400, 0.55) }}>• Incluye setup inicial</span>}
                          <span style={{ ...s(9, 400, 0.55) }}>• Suscripción {srv.periodo}</span>
                          <span style={{ ...s(9, 400, 0.55) }}>• Meses: {item.meses_cobrados || 1}</span>
                        </>
                      )}
                    </div>
                  );
                })}
              </div>
            </div>
          )}
        </div>

        <PageFooter
          empresa={empresa}
          sitio={ajustes.sitio_web || ''}
          page="1 / 2"
          total={totales.total}
          hoy={hoy}
        />
      </div>

      {/* ══════════════════════ PAGE 2 ══════════════════════ */}
      <div style={page2}>
        <PageHeader
          empresa={empresa}
          tagline={tagline}
          ajustes={ajustes}
          compact
          folio={cotizacion.folio}
        />
        <AccentLine />

        {/* HERO — Total display */}
        <div
          style={{
            background: '#000',
            padding: '32px 40px',
            display: 'flex',
            flexDirection: 'column',
            gap: 8,
            flexShrink: 0,
          }}
        >
          <span style={{ ...m(11, 1), color: 'rgba(255,255,255,0.4)', textTransform: 'uppercase' }}>
            Total de la Cotización
          </span>
          <span
            style={{
              fontFamily: "'DM Sans', 'Helvetica Neue', Arial, sans-serif",
              fontSize: 72,
              fontWeight: 700,
              color: '#fff',
              letterSpacing: '-0.04em',
              lineHeight: 1,
            }}
          >
            {formatearMoneda(totales.total)}
          </span>
          <span style={{ ...m(9, 1), color: 'rgba(255,255,255,0.35)', textTransform: 'none' }}>
            MXN · {cotizacion.con_factura !== false ? 'IVA incluido' : 'IVA no incluido'}
          </span>
        </div>

        {/* Content page 2 */}
        <div style={{ flex: 1, padding: '32px 40px', display: 'flex', flexDirection: 'column', gap: 24 }}>

          {/* ── DESGLOSE ── */}
          <div style={{ display: 'flex', flexDirection: 'column' }}>
            <span style={{ ...s(14, 700), marginBottom: 10 }}>Desglose</span>
            <Divider />

            {items.map((item, i) => {
              const { total, produto } = itemTotals[i];
              return (
                <div key={item.id ?? i}>
                  <div
                    style={{
                      display: 'flex',
                      justifyContent: 'space-between',
                      alignItems: 'center',
                      padding: '11px 0',
                    }}
                  >
                    <span style={{ ...s(11, 400, 0.7) }}>{produto?.nombre || item.descripcion}</span>
                    <span style={{ ...m(13, 1) }}>{formatearMoneda(total)}</span>
                  </div>
                  <Divider opacity={0.06} />
                </div>
              );
            })}

            {/* Totals block */}
            <Divider opacity={0.88} height={2} />
            <div style={{ display: 'flex', justifyContent: 'space-between', padding: '11px 0' }}>
              <span style={{ ...m(9, 0.7), textTransform: 'uppercase' }}>Subtotal</span>
              <span style={{ ...m(11) }}>{formatearMoneda(totales.subtotal)}</span>
            </div>
            {totales.iva > 0 && (
              <div style={{ display: 'flex', justifyContent: 'space-between', padding: '4px 0 11px' }}>
                <span style={{ ...m(9, 0.5), textTransform: 'uppercase' }}>
                  IVA ({(ajustes.iva_por_defecto * 100).toFixed(0)}%)
                </span>
                <span style={{ ...m(11, 0.65) }}>{formatearMoneda(totales.iva)}</span>
              </div>
            )}
            <Divider />
            <div style={{ display: 'flex', justifyContent: 'space-between', padding: '11px 0' }}>
              <span style={{ ...m(10, 1), fontWeight: 700, textTransform: 'uppercase' }}>Total a Pagar</span>
              <span style={{ ...m(14, 1), color: PURPLE, fontWeight: 700 }}>
                {formatearMoneda(totales.total)}
              </span>
            </div>
          </div>

          <Divider />

          {/* ── TÉRMINOS ── */}
          <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
            <span style={{ ...s(13, 700) }}>Términos y Condiciones</span>
            {cotizacion.nota ? (
              cotizacion.nota.split('\n').map((line, i) => (
                <span key={i} style={{ ...s(9, 400, 0.55) }}>{line}</span>
              ))
            ) : (
              <>
                <span style={{ ...s(9, 400, 0.55) }}>
                  • Vigencia de la cotización: {cotizacion.validez_dias} días naturales a partir de la fecha de emisión.
                </span>
                <span style={{ ...s(9, 400, 0.55) }}>
                  • Los precios están expresados en pesos mexicanos (MXN)
                  {cotizacion.con_factura !== false ? ' e IVA incluido.' : ' e IVA no incluido.'}
                </span>
                <span style={{ ...s(9, 400, 0.55) }}>
                  • El inicio del proyecto está sujeto a la confirmación de pago del anticipo del 50%.
                </span>
                <span style={{ ...s(9, 400, 0.55) }}>
                  • Cualquier trabajo fuera del alcance descrito será cotizado por separado.
                </span>
              </>
            )}
          </div>

          <Divider />

          {/* ── MÉTODOS DE PAGO ── */}
          <div style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
            <span style={{ ...s(13, 700) }}>Métodos de Pago</span>
            <div style={{ display: 'flex', gap: 16 }}>
              {[
                {
                  title: 'Transferencia Bancaria',
                  lines: ajustes.cuenta_bancaria
                    ? ['BBVA México', ajustes.cuenta_bancaria]
                    : ['BBVA México', 'Solicitar datos al equipo'],
                },
                {
                  title: 'Tarjeta de Crédito/Débito',
                  lines: ['Visa / Mastercard', 'Link de pago por email'],
                },
                {
                  title: 'Efectivo',
                  lines: [ajustes.direccion || 'En oficina', 'Previa cita'],
                },
              ].map((card) => (
                <div
                  key={card.title}
                  style={{
                    flex: 1,
                    background: 'rgba(0,0,0,0.04)',
                    borderRadius: 4,
                    padding: '14px 18px',
                    display: 'flex',
                    flexDirection: 'column',
                    gap: 7,
                  }}
                >
                  <span style={{ ...s(10, 700) }}>{card.title}</span>
                  {card.lines.map((l, i) => (
                    <span key={i} style={{ ...m(8, 0.5) }}>{l}</span>
                  ))}
                </div>
              ))}
            </div>
          </div>

          {/* ── THANK YOU ── */}
          <div
            style={{
              background: 'rgba(0,0,0,0.03)',
              borderRadius: 8,
              padding: '18px 28px',
              display: 'flex',
              flexDirection: 'column',
              gap: 8,
            }}
          >
            <div style={{ height: 3, background: PURPLE, borderRadius: 2 }} />
            <span style={{ ...s(14, 700) }}>¡Gracias por la confianza!</span>
            <span style={{ ...s(10, 400, 0.6) }}>
              Estamos listos para arrancar. Para confirmar, escríbenos a{' '}
              <span style={{ color: PURPLE }}>{ajustes.email || 'ventas@ideally.com.mx'}</span>
            </span>
          </div>
        </div>

        <PageFooter
          empresa={empresa}
          sitio={ajustes.sitio_web || ''}
          page="2 / 2"
          total={totales.total}
          hoy={hoy}
        />
      </div>
    </div>
  );
}
