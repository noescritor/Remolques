export interface ContactoCliente {
  id: string;
  nombre: string;
  departamento?: string;
  puesto?: string;
  telefono?: string;
  correo?: string;
}

export interface Cliente {
  id: string;
  nombre_razon_social: string;
  nombre_contacto?: string;
  telefono?: string;
  correo?: string;
  direccion?: string;
  ciudad?: string;
  estado?: string;
  codigo_postal?: string;
  pais: string;
  tipo_pago_preferido: 'Transferencia' | 'Tarjeta' | 'Efectivo' | 'PayPal' | 'Crédito 30 días';
  contactos?: ContactoCliente[];
}

export type ProductoTipo = 'bien' | 'servicio';
export type PeriodoCobro = 'mensual' | 'trimestral' | 'semestral' | 'anual';
export type ServicioModo = 'unico' | 'suscripcion' | 'hibrido';

export interface ServicioPlan {
  modo: ServicioModo;
  setup_precio?: number;
  setup_costo?: number;
  recur_precio?: number;
  recur_costo?: number;
  periodo?: PeriodoCobro;
  min_meses?: number;
  por_asiento?: boolean;
  asientos_incluidos?: number;
  precio_por_asiento?: number;
}

export interface Producto {
  id: string;
  tipo: ProductoTipo;
  nombre: string;
  descripcion?: string;
  unidad: string;
  precio_unitario?: number;
  costo?: number;
  tasa_iva: number;
  servicio?: ServicioPlan;
}

export interface ItemCotizacion {
  id: string;
  producto_id?: string;
  posicion: number;
  cantidad: number;
  unidad: string;
  descripcion: string;
  numero_proyecto?: string;
  precio_unitario?: number;
  costo_unitario?: number;
  incluir_setup?: boolean;
  meses_cobrados?: number;
  asientos_extra?: number;
  iva_item: number;
  total_item: number;
}

export interface CostosIndirectos {
  mano_obra?: number;
  insumos_dtf?: number;
  empaque?: number;
  mermas?: number;
  envio?: number;
  otros?: number;
}

export interface ComisionesPago {
  porcentaje?: number;
  fijo?: number;
}

export interface Cotizacion {
  id: string;
  folio: string;
  cliente_id: string;
  cliente?: Cliente;
  fecha: string;
  validez_dias: number;
  estado: 'Borrador' | 'Enviada' | 'Aprobada' | 'Cancelada' | 'Pagada';
  con_factura: boolean;
  descripcion?: string;
  subtotal: number;
  iva: number;
  total: number;
  nota?: string;
  items: ItemCotizacion[];
  // Nuevos campos para análisis de costos
  costos_indirectos?: CostosIndirectos;
  comisiones_pago?: ComisionesPago;
  // Fase 2: Gestión de Versiones
  version?: number;
  cotizacion_padre_id?: string;
  // Fase 3: Portal de cliente y firma digital
  token_publico?: string;
  token_expira_en?: string;
  firma_imagen?: string;
  firma_nombre?: string;
  firma_fecha?: string;
  firma_ip?: string;
  comentario_cliente?: string;
}

export interface Pago {
  id: string;
  cotizacion_id: string;
  tipo_pago: 'Transferencia' | 'Tarjeta' | 'Efectivo' | 'PayPal' | 'Crédito 30 días';
  referencia?: string;
  monto: number;
  fecha: string;
}

export interface Ajustes {
  iva_por_defecto: number;
  validez_por_defecto: number;
  nota_por_defecto: string;
  prefijo_folio: string;
  offset_folio: number;
  // Información de la empresa
  nombre_empresa?: string;
  tagline?: string;
  direccion?: string;
  telefono?: string;
  email?: string;
  sitio_web?: string;
  cuenta_bancaria?: string;
  // Configuración de emails
  email_envio?: string; // Email desde el que se enviarán las cotizaciones (debe estar verificado en Resend)
  // Textos personalizables del resumen de servicios
  resumen_servicios?: {
    titulo?: string;
    pago_unico?: string;
    suscripcion?: string;
    hibrido?: string;
    setup_completo?: string;
    setup_inicial?: string;
    periodo_label?: string;
    meses_contratados_label?: string;
    permanencia_minima_label?: string;
    base_asientos_label?: string;
    asientos_adicionales_label?: string;
  };
}

// Fase 2.1 — Plantillas de cotización
export interface Plantilla {
  id: string;
  nombre: string;
  descripcion?: string;
  items: ItemCotizacion[];
  nota?: string;
  con_factura?: boolean;
  created_at?: string;
}

// Fase 2.3 — Historial de precios
export interface HistorialPrecio {
  id: string;
  producto_id: string;
  precio_anterior: number;
  precio_nuevo: number;
  fecha: string;
}

export type EstadoCotizacion = 'Borrador' | 'Enviada' | 'Aprobada' | 'Cancelada' | 'Pagada';

export const TRANSICIONES_ESTADO: Record<EstadoCotizacion, EstadoCotizacion[]> = {
  'Borrador': ['Enviada', 'Cancelada'],
  'Enviada': ['Aprobada', 'Cancelada'],
  'Aprobada': ['Pagada', 'Cancelada'],
  'Cancelada': [],
  'Pagada': []
};

// ─── Gestión de Equipo SaaS ───────────────────────────────────────────

export interface PerfilOrganizacion {
  id: string;
  organizacion_id: string;
  usuario_id: string;
  rol: 'propietario' | 'admin' | 'usuario';
  created_at: string;
  email?: string; // Provisto por la Edge Function
}

export interface InvitacionEquipo {
  id: string;
  organizacion_id: string;
  email: string;
  rol: 'propietario' | 'admin' | 'usuario';
  invitado_por?: string;
  created_at: string;
}
