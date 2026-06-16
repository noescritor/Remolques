-- 1. Crear la tabla notas_simples
CREATE TABLE public.notas_simples (
  id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
  organizacion_id UUID NOT NULL REFERENCES public.organizaciones(id) ON DELETE CASCADE,
  folio SERIAL,
  cliente_nombre TEXT NOT NULL,
  items JSONB NOT NULL DEFAULT '[]'::jsonb,
  total NUMERIC(12,2) NOT NULL DEFAULT 0.00,
  estado_taller TEXT NOT NULL CHECK (estado_taller IN ('Pendiente', 'En Proceso', 'Listo', 'Entregado')) DEFAULT 'Pendiente',
  urgencia TEXT NOT NULL CHECK (urgencia IN ('Baja', 'Media', 'Alta', 'Urgente')) DEFAULT 'Media',
  fecha_entrega TIMESTAMPTZ,
  creado_por_nombre TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- 2. Habilitar Row Level Security (RLS)
ALTER TABLE public.notas_simples ENABLE ROW LEVEL SECURITY;

-- 3. Crear políticas RLS para tenant SaaS
CREATE POLICY "s_notas_simples" ON public.notas_simples 
FOR ALL TO authenticated 
USING (organizacion_id IN (SELECT organizacion_id FROM perfiles_organizacion WHERE usuario_id = auth.uid())) 
WITH CHECK (organizacion_id IN (SELECT organizacion_id FROM perfiles_organizacion WHERE usuario_id = auth.uid()));

-- 4. Crear índice para organizacion_id
CREATE INDEX idx_notas_simples_org ON public.notas_simples(organizacion_id);

-- 5. Actualizar los módulos de organizaciones existentes y el valor por defecto de la columna
ALTER TABLE public.organizaciones 
ALTER COLUMN modulos SET DEFAULT '{"cotizaciones": true, "clientes": true, "productos": true, "calculadora": true, "inventario": true, "notas": true}'::jsonb;

-- Actualizar organizaciones existentes para que hereden "notas": true manteniendo sus otros módulos
UPDATE public.organizaciones 
SET modulos = COALESCE(modulos, '{"cotizaciones": true, "clientes": true, "productos": true, "calculadora": true, "inventario": true}'::jsonb) || '{"notas": true}'::jsonb;
