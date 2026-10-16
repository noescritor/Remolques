-- Migración 20261016_01_catalogo_costos.sql
-- Sub-bloque 2R-7: Catálogo de costos administrable
-- 1. Agrega producto_id y costo_desde_producto a opcion_costos
-- 2. Crea tabla costos_historial con RLS
-- 3. Liga opciones de llantas a sus productos correspondientes sin modificar costos

BEGIN;

-- 1. Columnas en opcion_costos
ALTER TABLE opcion_costos 
  ADD COLUMN IF NOT EXISTS producto_id text REFERENCES productos(id) ON DELETE SET NULL;

ALTER TABLE opcion_costos 
  ADD COLUMN IF NOT EXISTS costo_desde_producto boolean NOT NULL DEFAULT false;

COMMENT ON COLUMN opcion_costos.producto_id IS 'Producto de inventario o materia prima ligado a esta opcion';
COMMENT ON COLUMN opcion_costos.costo_desde_producto IS 'Si es true, el motor de costeo toma el costo vigente de productos en vez de costo_unitario';

CREATE INDEX IF NOT EXISTS idx_opcion_costos_producto_id ON opcion_costos(producto_id);

-- 2. Tabla costos_historial
CREATE TABLE IF NOT EXISTS costos_historial (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    organizacion_id uuid NOT NULL REFERENCES organizaciones(id) ON DELETE CASCADE,
    tabla text NOT NULL CHECK (tabla IN ('opcion_costos','costos_modelo','procesos_manufactura','parametros_costeo')),
    registro_id text NOT NULL,
    concepto text,
    campo text NOT NULL,
    valor_anterior text,
    valor_nuevo text,
    usuario_id uuid,
    creado_en timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE costos_historial ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "org_costos_historial_policy" ON costos_historial;
CREATE POLICY "org_costos_historial_policy" ON costos_historial FOR ALL USING (organizacion_id = get_current_org_id());

CREATE INDEX IF NOT EXISTS idx_costos_historial_org_creado ON costos_historial(organizacion_id, creado_en DESC);

-- 3. Ligas iniciales sin cambiar ningún costo
DO $$
DECLARE
    r_org RECORD;
    v_opt_key text;
    v_prod_name text;
    v_prod_id text;
    v_prod_count int;
    v_pares text[][] := ARRAY[
        ['cerex', 'LLANTAS CEREX'],
        ['bf_goodrich', 'LLANTAS BF GOODRICH'],
        ['eudemon', 'LLANTAS EUDEMON'],
        ['amulet', 'LLANTAS AMULET'],
        ['chinas', 'LLANTAS CHINAS'],
        ['royal_black', 'LLANTAS ROYAL BLACK'],
        ['valiant', 'LLANTAS VALIANT'],
        ['firestone', 'LLANTAS FIRESTONE']
    ];
    i int;
BEGIN
    FOR r_org IN SELECT id FROM organizaciones LOOP
        FOR i IN 1..array_length(v_pares, 1) LOOP
            v_opt_key := v_pares[i][1];
            v_prod_name := v_pares[i][2];

            -- Buscar producto por nombre exacto (case-insensitive)
            SELECT count(*) INTO v_prod_count
            FROM productos
            WHERE organizacion_id = r_org.id
              AND UPPER(TRIM(nombre)) = UPPER(TRIM(v_prod_name))
              AND (tipo_item = 'materia_prima' OR tipo_item IS NULL);

            IF v_prod_count = 1 THEN
                SELECT id INTO v_prod_id
                FROM productos
                WHERE organizacion_id = r_org.id
                  AND UPPER(TRIM(nombre)) = UPPER(TRIM(v_prod_name))
                  AND (tipo_item = 'materia_prima' OR tipo_item IS NULL)
                LIMIT 1;

                -- Actualizar opcion_costos para los 3 tipos de modelo
                UPDATE opcion_costos oc
                SET producto_id = v_prod_id
                FROM opciones_configuracion o
                JOIN grupos_configuracion g ON o.grupo_id = g.id
                WHERE oc.opcion_id = o.id
                  AND oc.organizacion_id = r_org.id
                  AND g.clave = 'llantas'
                  AND o.clave = v_opt_key
                  AND oc.tipo_modelo IN ('plataforma', 'dolly', 'gondola');
            ELSE
                RAISE NOTICE 'Org %: producto "%" para opcion "%" encontrado % veces (se omite liga)',
                    r_org.id, v_prod_name, v_opt_key, v_prod_count;
            END IF;
        END LOOP;
    END LOOP;
END $$;

COMMIT;
