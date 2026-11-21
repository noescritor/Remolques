-- Migración idempotente: Módulo de Calidad (Parte 1 de 2: datos, plantillas semilla y funciones)
-- Fecha: 2026-11-21
-- Sigue patrón de 20261112_01_tablero_orden_fases.sql: RLS solo lectura, escrituras SECURITY DEFINER (service_role).

BEGIN;

-- 1. Tablas de Calidad

CREATE TABLE IF NOT EXISTS calidad_plantillas (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    organizacion_id uuid NOT NULL REFERENCES organizaciones(id) ON DELETE CASCADE,
    linea_producto_id uuid NOT NULL REFERENCES lineas_producto(id),
    formato text NOT NULL CHECK (formato IN ('control_total', 'entrega')),
    nombre text NOT NULL,
    version integer NOT NULL DEFAULT 1 CHECK (version >= 1),
    estado text NOT NULL DEFAULT 'borrador' CHECK (estado IN ('borrador', 'activa', 'archivada')),
    revision_formato text,
    fecha_revision_formato date,
    config jsonb NOT NULL DEFAULT '{"unidades":["Única"],"etiquetas_resultado":{"conforme":"√","no_conforme":"X"},"bloquea_liberacion":false}'::jsonb,
    origen text NOT NULL DEFAULT 'editor' CHECK (origen IN ('semilla', 'editor')),
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT uq_calidad_plantillas_org_linea_fmt_ver UNIQUE (organizacion_id, linea_producto_id, formato, version)
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_calidad_plantilla_activa
    ON calidad_plantillas (organizacion_id, linea_producto_id, formato)
    WHERE estado = 'activa';

CREATE INDEX IF NOT EXISTS idx_calidad_plantillas_org
    ON calidad_plantillas (organizacion_id, linea_producto_id, formato);

CREATE TABLE IF NOT EXISTS calidad_plantilla_grupos (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    organizacion_id uuid NOT NULL REFERENCES organizaciones(id) ON DELETE CASCADE,
    plantilla_id uuid NOT NULL REFERENCES calidad_plantillas(id) ON DELETE CASCADE,
    orden integer NOT NULL,
    nombre text NOT NULL,
    numero_original text,
    fase_orden integer NULL,
    fase_confirmada boolean NOT NULL DEFAULT true,
    CONSTRAINT uq_calidad_plantilla_grupos_orden UNIQUE (plantilla_id, orden)
);

CREATE INDEX IF NOT EXISTS idx_calidad_grupos_org_plantilla
    ON calidad_plantilla_grupos (organizacion_id, plantilla_id);

CREATE TABLE IF NOT EXISTS calidad_plantilla_items (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    organizacion_id uuid NOT NULL REFERENCES organizaciones(id) ON DELETE CASCADE,
    plantilla_id uuid NOT NULL REFERENCES calidad_plantillas(id) ON DELETE CASCADE,
    grupo_id uuid NOT NULL REFERENCES calidad_plantilla_grupos(id) ON DELETE CASCADE,
    orden integer NOT NULL,
    numero integer NOT NULL,
    texto text NOT NULL,
    aplica_si text NULL,
    CONSTRAINT uq_calidad_plantilla_items_orden UNIQUE (grupo_id, orden)
);

CREATE INDEX IF NOT EXISTS idx_calidad_items_org_plantilla
    ON calidad_plantilla_items (organizacion_id, plantilla_id);

CREATE TABLE IF NOT EXISTS orden_calidad_inspecciones (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    organizacion_id uuid NOT NULL REFERENCES organizaciones(id) ON DELETE CASCADE,
    orden_trabajo_id uuid NOT NULL REFERENCES ordenes_trabajo(id) ON DELETE CASCADE,
    plantilla_id uuid NOT NULL REFERENCES calidad_plantillas(id) ON DELETE RESTRICT,
    formato text NOT NULL CHECK (formato IN ('control_total', 'entrega')),
    folio text NOT NULL,
    intento integer NOT NULL DEFAULT 1 CHECK (intento >= 1),
    estado text NOT NULL DEFAULT 'en_proceso' CHECK (estado IN ('en_proceso', 'cerrada')),
    evaluado_por text,
    fecha_inicio date,
    fecha_liberacion date,
    liberado_por text,
    nota text,
    actualizado_por uuid,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT uq_orden_calidad_intento UNIQUE (orden_trabajo_id, formato, intento),
    CONSTRAINT uq_orden_calidad_org_folio UNIQUE (organizacion_id, folio)
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_orden_calidad_en_proceso
    ON orden_calidad_inspecciones (orden_trabajo_id, formato)
    WHERE estado = 'en_proceso';

CREATE INDEX IF NOT EXISTS idx_orden_calidad_org
    ON orden_calidad_inspecciones (organizacion_id, orden_trabajo_id, formato);

CREATE TABLE IF NOT EXISTS orden_calidad_resultados (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    organizacion_id uuid NOT NULL REFERENCES organizaciones(id) ON DELETE CASCADE,
    inspeccion_id uuid NOT NULL REFERENCES orden_calidad_inspecciones(id) ON DELETE CASCADE,
    item_id uuid NOT NULL REFERENCES calidad_plantilla_items(id) ON DELETE RESTRICT,
    unidad integer NOT NULL DEFAULT 1 CHECK (unidad >= 1),
    resultado text NOT NULL CHECK (resultado IN ('conforme', 'no_conforme', 'no_aplica')),
    operario_id uuid NULL REFERENCES operarios(id) ON DELETE SET NULL,
    colaborador text,
    fecha_inspeccion date,
    observaciones text,
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT uq_orden_calidad_resultado_unidad UNIQUE (inspeccion_id, item_id, unidad)
);

CREATE INDEX IF NOT EXISTS idx_orden_calidad_res_org
    ON orden_calidad_resultados (organizacion_id, inspeccion_id);

CREATE TABLE IF NOT EXISTS calidad_folios (
    organizacion_id uuid NOT NULL REFERENCES organizaciones(id) ON DELETE CASCADE,
    formato text NOT NULL CHECK (formato IN ('control_total', 'entrega')),
    ultimo integer NOT NULL DEFAULT 0,
    PRIMARY KEY (organizacion_id, formato)
);

-- 2. RLS: Solo lectura para authenticated con get_current_org_id()

ALTER TABLE calidad_plantillas ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS calidad_plantillas_select ON calidad_plantillas;
CREATE POLICY calidad_plantillas_select ON calidad_plantillas FOR SELECT TO authenticated
    USING (organizacion_id = get_current_org_id());
GRANT SELECT ON calidad_plantillas TO authenticated;

ALTER TABLE calidad_plantilla_grupos ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS calidad_plantilla_grupos_select ON calidad_plantilla_grupos;
CREATE POLICY calidad_plantilla_grupos_select ON calidad_plantilla_grupos FOR SELECT TO authenticated
    USING (organizacion_id = get_current_org_id());
GRANT SELECT ON calidad_plantilla_grupos TO authenticated;

ALTER TABLE calidad_plantilla_items ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS calidad_plantilla_items_select ON calidad_plantilla_items;
CREATE POLICY calidad_plantilla_items_select ON calidad_plantilla_items FOR SELECT TO authenticated
    USING (organizacion_id = get_current_org_id());
GRANT SELECT ON calidad_plantilla_items TO authenticated;

ALTER TABLE orden_calidad_inspecciones ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS orden_calidad_inspecciones_select ON orden_calidad_inspecciones;
CREATE POLICY orden_calidad_inspecciones_select ON orden_calidad_inspecciones FOR SELECT TO authenticated
    USING (organizacion_id = get_current_org_id());
GRANT SELECT ON orden_calidad_inspecciones TO authenticated;

ALTER TABLE orden_calidad_resultados ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS orden_calidad_resultados_select ON orden_calidad_resultados;
CREATE POLICY orden_calidad_resultados_select ON orden_calidad_resultados FOR SELECT TO authenticated
    USING (organizacion_id = get_current_org_id());
GRANT SELECT ON orden_calidad_resultados TO authenticated;

ALTER TABLE calidad_folios ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS calidad_folios_select ON calidad_folios;
CREATE POLICY calidad_folios_select ON calidad_folios FOR SELECT TO authenticated
    USING (organizacion_id = get_current_org_id());
GRANT SELECT ON calidad_folios TO authenticated;

-- 3. Funciones SECURITY DEFINER

CREATE OR REPLACE FUNCTION sembrar_calidad_plantillas(p_org uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_seed jsonb := '[{"formato":"control_total","linea":"plataforma","nombre":"Control de calidad total — Plataforma","unidades":["Única"],"etiquetas_resultado":{"conforme":"√","no_conforme":"X"},"grupos":[{"orden":1,"nombre":"Corte de almas","numero_original":"1","fase_orden":1,"fase_confirmada":true,"items":[{"orden":1,"numero":1,"texto":"Corte de almas","aplica_si":null},{"orden":2,"numero":2,"texto":"Barrenado de IPR","aplica_si":null}]},{"orden":2,"nombre":"Ensambre de baras","numero_original":"2","fase_orden":3,"fase_confirmada":true,"items":[{"orden":1,"numero":3,"texto":"Alineacion de solera respecto a alma","aplica_si":null},{"orden":2,"numero":4,"texto":"Soldadura con bugo de Bara 1","aplica_si":null},{"orden":3,"numero":5,"texto":"Soldadura con bugo de Bara 2","aplica_si":null}]},{"orden":3,"nombre":"Ensamble de chasis","numero_original":"3","fase_orden":2,"fase_confirmada":false,"items":[{"orden":1,"numero":6,"texto":"Colocacion de Botones","aplica_si":null},{"orden":2,"numero":7,"texto":"Colocacion de Puentes Internos","aplica_si":null},{"orden":3,"numero":8,"texto":"Colocacion de Puentes de Suspensión","aplica_si":null},{"orden":4,"numero":9,"texto":"Colocacion de Puentes de la Quinta","aplica_si":null},{"orden":5,"numero":10,"texto":"Colocacion de Borda Delantera","aplica_si":null},{"orden":6,"numero":11,"texto":"Colocacion de Borda Trasera","aplica_si":null},{"orden":7,"numero":12,"texto":"Colocacion de Plancha para la Quinta","aplica_si":null},{"orden":8,"numero":13,"texto":"Sub-ensamble de Refuerso interno del Jalon","aplica_si":null},{"orden":9,"numero":14,"texto":"Colocacion del Jalon","aplica_si":null},{"orden":10,"numero":15,"texto":"Colocacion de Atizadores internos","aplica_si":null},{"orden":11,"numero":16,"texto":"Colocacion de Atizadores externos","aplica_si":null},{"orden":12,"numero":17,"texto":"Colocacion del Perno Rey (Con su respectiva tapa)","aplica_si":null}]},{"orden":4,"nombre":"Ensamble de cargadores","numero_original":"4","fase_orden":4,"fase_confirmada":true,"items":[{"orden":1,"numero":18,"texto":"Alineación de baras","aplica_si":null},{"orden":2,"numero":19,"texto":"Colocación de Cargadores tipo IPR","aplica_si":null},{"orden":3,"numero":20,"texto":"Colocación de Bordas Laterales (Canal tipo \"U\" de 15Kg)","aplica_si":null},{"orden":4,"numero":21,"texto":"Colocación de Esquineros Frontales","aplica_si":null},{"orden":5,"numero":22,"texto":"Colocación de Esquineros Traseros","aplica_si":null},{"orden":6,"numero":23,"texto":"Colocación de Buchacas","aplica_si":null},{"orden":7,"numero":24,"texto":"Colocación de Tubos laterales","aplica_si":null},{"orden":8,"numero":25,"texto":"Colocación de Aletas","aplica_si":null},{"orden":9,"numero":26,"texto":"Sub-ensamble de Porta Estribo","aplica_si":null}]},{"orden":5,"nombre":"Resoldado","numero_original":"5","fase_orden":5,"fase_confirmada":false,"items":[{"orden":1,"numero":27,"texto":"Colocación de Riel logístico","aplica_si":null},{"orden":2,"numero":28,"texto":"Colocación de Ganchos para lona","aplica_si":null},{"orden":3,"numero":29,"texto":"Colocación de Bases para Tanques","aplica_si":null},{"orden":4,"numero":30,"texto":"Colocacion de Bases para Patines","aplica_si":null},{"orden":5,"numero":31,"texto":"Colocacion de Base para Manitas","aplica_si":null},{"orden":6,"numero":32,"texto":"Colocacion de Base para Perchas","aplica_si":null},{"orden":7,"numero":33,"texto":"Colocacion de Bases para Platos","aplica_si":null},{"orden":8,"numero":34,"texto":"Colocacion de Base para Valvula del ABS","aplica_si":null},{"orden":9,"numero":35,"texto":"Colocación de Base para Foco del ABS","aplica_si":null},{"orden":10,"numero":36,"texto":"Colocacion de Plafones ovalados","aplica_si":null},{"orden":11,"numero":37,"texto":"Colocacion de Perchas y Platos","aplica_si":null},{"orden":12,"numero":38,"texto":"Colocacion de Solera para Esquineros","aplica_si":null},{"orden":13,"numero":39,"texto":"Colocacion de Cartabones para Jalon","aplica_si":null},{"orden":14,"numero":40,"texto":"Colocacion de \"U\" para Cadenas","aplica_si":null},{"orden":15,"numero":41,"texto":"Colocacion del Porta Placas","aplica_si":null},{"orden":16,"numero":42,"texto":"Resoldado general de todos los componentes","aplica_si":null}]},{"orden":6,"nombre":"Terminados","numero_original":"6","fase_orden":6,"fase_confirmada":true,"items":[{"orden":1,"numero":43,"texto":"Colocacion de Estribo","aplica_si":null},{"orden":2,"numero":44,"texto":"Colocacion de Cincho","aplica_si":null},{"orden":3,"numero":45,"texto":"Instalacion de Patines con componentes","aplica_si":null},{"orden":4,"numero":46,"texto":"Instalacion de Frente (Concha o Burro)","aplica_si":null},{"orden":5,"numero":47,"texto":"Colocacion de Caja de Herramientas","aplica_si":null},{"orden":6,"numero":48,"texto":"Instalacion de Porta llantas con componentes","aplica_si":null},{"orden":7,"numero":49,"texto":"Instalacion de Ejes","aplica_si":null},{"orden":8,"numero":50,"texto":"Torqueado de perchas","aplica_si":null},{"orden":9,"numero":51,"texto":"Colocacion de Porta loderas","aplica_si":null},{"orden":10,"numero":52,"texto":"Colocacion de Plafones laterales (en caso de llevarlos)","aplica_si":"en caso de llevarlos"},{"orden":11,"numero":53,"texto":"Colocacion de Plafones en Estribo (en caso de llevarlos)","aplica_si":"en caso de llevarlos"},{"orden":12,"numero":54,"texto":"Colocacion de Pestañas","aplica_si":null},{"orden":13,"numero":55,"texto":"Colocacion de Banderolas","aplica_si":null},{"orden":14,"numero":56,"texto":"Colocacion de Sistema Retractil con componentes","aplica_si":null},{"orden":15,"numero":57,"texto":"Colocacion de Base para Valvula Ponchadora","aplica_si":null},{"orden":16,"numero":58,"texto":"Colocacion de Base para Valvula Niveladora","aplica_si":null},{"orden":17,"numero":59,"texto":"Colocacion de Cajas Auxiliares (en caso de llevarla)","aplica_si":"en caso de llevarla"},{"orden":18,"numero":60,"texto":"Instalacion de Canastilla o Polinera (en caso de llevarla)","aplica_si":"en caso de llevarla"},{"orden":19,"numero":61,"texto":"Instalacion de Bicicleteros (en caso de llevarlo)","aplica_si":"en caso de llevarlo"},{"orden":20,"numero":62,"texto":"Alineacion de Ejes","aplica_si":null}]},{"orden":7,"nombre":"Escoreado","numero_original":"7","fase_orden":7,"fase_confirmada":true,"items":[{"orden":1,"numero":63,"texto":"Escoreado del Frente de la unidad","aplica_si":null},{"orden":2,"numero":64,"texto":"Escoreado de Bordas laterales y Buchacas","aplica_si":null},{"orden":3,"numero":65,"texto":"Escoreado de Cargadores","aplica_si":null},{"orden":4,"numero":66,"texto":"Escoreado de Patines","aplica_si":null},{"orden":5,"numero":67,"texto":"Escoreado de Aletones","aplica_si":null},{"orden":6,"numero":68,"texto":"Escoreado de Almas","aplica_si":null},{"orden":7,"numero":69,"texto":"Escoreado de Caja","aplica_si":null},{"orden":8,"numero":70,"texto":"Escoreado del Porta Llantas","aplica_si":null},{"orden":9,"numero":71,"texto":"Escoreado en Suspensión","aplica_si":null},{"orden":10,"numero":72,"texto":"Escoreado de Porta Loderas","aplica_si":null},{"orden":11,"numero":73,"texto":"Escoreado del Estribo","aplica_si":null},{"orden":12,"numero":74,"texto":"Escoreado del Jalon","aplica_si":null},{"orden":13,"numero":75,"texto":"Escoreado de Puentes Internos","aplica_si":null}]},{"orden":8,"nombre":"Lavado","numero_original":"8","fase_orden":7,"fase_confirmada":true,"items":[{"orden":1,"numero":76,"texto":"Lavado del Frente de la unidad","aplica_si":null},{"orden":2,"numero":77,"texto":"Lavado del Lateral Derecho","aplica_si":null},{"orden":3,"numero":78,"texto":"Lavado del Lateral Izquierdo","aplica_si":null},{"orden":4,"numero":79,"texto":"Lavado de la parte Posterior de la unidad","aplica_si":null},{"orden":5,"numero":80,"texto":"Lavado Interno de chasis","aplica_si":null}]},{"orden":9,"nombre":"Praimer","numero_original":"9","fase_orden":8,"fase_confirmada":true,"items":[{"orden":1,"numero":81,"texto":"Aplicación de praimer parte Frontal de la unidad","aplica_si":null},{"orden":2,"numero":82,"texto":"Aplicación de praimer lateral Derecho","aplica_si":null},{"orden":3,"numero":83,"texto":"Aplicación de praimer lateral Izquierdo","aplica_si":null},{"orden":4,"numero":84,"texto":"Aplicación de praimer parte Posterior de la unidad","aplica_si":null},{"orden":5,"numero":85,"texto":"Aplicación de praimer interna del chasis","aplica_si":null}]},{"orden":10,"nombre":"Pintura","numero_original":"11","fase_orden":9,"fase_confirmada":true,"items":[{"orden":1,"numero":86,"texto":"Aplicación de pintura parte Frontal de la unidad","aplica_si":null},{"orden":2,"numero":87,"texto":"Aplicación de pintura lateral Derecho","aplica_si":null},{"orden":3,"numero":88,"texto":"Aplicación de pintura lateral Izquierdo","aplica_si":null},{"orden":4,"numero":89,"texto":"Aplicación de pintura parte Posterior de la unidad","aplica_si":null},{"orden":5,"numero":90,"texto":"Aplicación de pintura interna del chasis","aplica_si":null}]},{"orden":11,"nombre":"Sistema neumatico","numero_original":"12","fase_orden":11,"fase_confirmada":true,"items":[{"orden":1,"numero":91,"texto":"Colocación de bolsas de aire","aplica_si":null},{"orden":2,"numero":92,"texto":"Colocación de Amortiguadores","aplica_si":null},{"orden":3,"numero":93,"texto":"Colocación de conexión de chambers","aplica_si":null},{"orden":4,"numero":94,"texto":"Colocación de conexión de Modulo ABS","aplica_si":null},{"orden":5,"numero":95,"texto":"Colocación de conexión de valvula niveladora","aplica_si":null},{"orden":6,"numero":96,"texto":"Colocación de conexión de valvula protectora","aplica_si":null},{"orden":7,"numero":97,"texto":"Colocación de conexión de valvula ponchadora","aplica_si":null},{"orden":8,"numero":98,"texto":"Colocación de conexión de kit de 1° retractil","aplica_si":null},{"orden":9,"numero":99,"texto":"Colocación de conexión de kit de 2° retractil","aplica_si":null},{"orden":10,"numero":100,"texto":"Colocación de \"Manita azul de servicio\" y \"Manita roja de emergencia, en parte frontal","aplica_si":null},{"orden":11,"numero":101,"texto":"Colocación de \"Manita azul de servicio\" y \"Manita roja de emergencia, en parte trasera","aplica_si":null},{"orden":12,"numero":102,"texto":"Instalacion de Gancho de arrastre","aplica_si":null},{"orden":13,"numero":103,"texto":"Calibracion de balatas","aplica_si":null}]},{"orden":12,"nombre":"Sistema electrico","numero_original":"12","fase_orden":10,"fase_confirmada":true,"items":[{"orden":1,"numero":104,"texto":"Plafones laterales Derechos (1 Ambar de 2\", 1 Rojo de 2\", 2 Ovalados Ambar).","aplica_si":null},{"orden":2,"numero":105,"texto":"Cuartos","aplica_si":null},{"orden":3,"numero":106,"texto":"Direccionales","aplica_si":null},{"orden":4,"numero":107,"texto":"Stop","aplica_si":null},{"orden":5,"numero":108,"texto":"Indicador de ABS","aplica_si":null},{"orden":6,"numero":109,"texto":"3 Marias","aplica_si":null},{"orden":7,"numero":110,"texto":"Plafones laterales Auxiliares","aplica_si":null},{"orden":8,"numero":111,"texto":"Plafones laterales Izquierdos (1 Ambar de 2\", 1 Rojo de 2\", 2 Ovalados Ambar).","aplica_si":null},{"orden":9,"numero":112,"texto":"Plafones en Estribo","aplica_si":null}]},{"orden":13,"nombre":"Piso","numero_original":"13","fase_orden":12,"fase_confirmada":true,"items":[{"orden":1,"numero":113,"texto":"Instalacion de Piso.","aplica_si":null},{"orden":2,"numero":114,"texto":"Instalacion de Rotulado","aplica_si":null},{"orden":3,"numero":115,"texto":"Instalacion de Reflejante.","aplica_si":null},{"orden":4,"numero":116,"texto":"Colocacion de Rines y Llantas.","aplica_si":null}]}]},{"formato":"entrega","linea":"plataforma","nombre":"Calidad de entrega — Plataforma","unidades":["Plana 1","Plana 2"],"etiquetas_resultado":{"conforme":"√","no_conforme":"X"},"grupos":[{"orden":1,"nombre":"PARTE FRONTAL DE LA UNIDAD","numero_original":null,"fase_orden":null,"fase_confirmada":true,"items":[{"orden":1,"numero":1,"texto":"CALCOMANIA \" LEOLCA\" Y LEON PARTE SUPERIOR CENTRADA.","aplica_si":null},{"orden":2,"numero":2,"texto":"CUARTOS FRONTALES IZQUIERDO & DERECHO \"AMBAR\".","aplica_si":null},{"orden":3,"numero":3,"texto":"MANITA AZUL DE SERVICIO Y MANITA ROJA DE EMERGENCIA.","aplica_si":null},{"orden":4,"numero":4,"texto":"SOQUET HEMBRA DE 7 POLOS.","aplica_si":null},{"orden":5,"numero":5,"texto":"CALCAMONIA HECHO EN MEXICO.","aplica_si":null},{"orden":6,"numero":6,"texto":"GANCHOS PARA LONA","aplica_si":null},{"orden":7,"numero":7,"texto":"PINTURA EN BUEN ESTADO.","aplica_si":null}]},{"orden":2,"nombre":"PARTE IZQUIERDA DE LA UNIDAD","numero_original":null,"fase_orden":null,"fase_confirmada":true,"items":[{"orden":1,"numero":8,"texto":"CINTA REFLEJANTE.","aplica_si":null},{"orden":2,"numero":9,"texto":"MANIVELA DE PATINES.","aplica_si":null},{"orden":3,"numero":10,"texto":"UN JUEGO DE PATINES Y TORNILLERIA GRADO 5.","aplica_si":null},{"orden":4,"numero":11,"texto":"SEGUNDO JUEGO DE PATINES EN BUEN ESTADO (SI LLEVA).","aplica_si":"SI LLEVA"},{"orden":5,"numero":12,"texto":"PLAFONERAS OVALADAS.","aplica_si":null},{"orden":6,"numero":13,"texto":"CALCOMANIA \"LEOLCA\" PARTE CENTRAL DEL EQUIPO.","aplica_si":null},{"orden":7,"numero":14,"texto":"SISTEMA RETRACTIL 1ER. EJE (EN CASO DE LLEVARLO).","aplica_si":"EN CASO DE LLEVARLO"},{"orden":8,"numero":15,"texto":"SISTEMA RETRACTIL 2o. EJE (EN CASO DE LLEVARLO).","aplica_si":"EN CASO DE LLEVARLO"},{"orden":9,"numero":16,"texto":"LLANTAS EN BUEN ESTADO Y ACEITE EN MASAS.","aplica_si":null},{"orden":10,"numero":17,"texto":"TORQUE TORNILLO DE PERCHA (CAPADOS).","aplica_si":null},{"orden":11,"numero":18,"texto":"PINTURA EN BUEN ESTADO","aplica_si":null},{"orden":12,"numero":19,"texto":"RIEL LOGISTICO CON LAS MATRACAS SOLICITADAS.","aplica_si":null},{"orden":13,"numero":20,"texto":"GANCHOS PARA LONA","aplica_si":null},{"orden":14,"numero":21,"texto":"CAJA DE HERRAMIENTAS","aplica_si":null},{"orden":15,"numero":22,"texto":"INDICACIONES DE ABS \"BENDIX\".","aplica_si":null},{"orden":16,"numero":23,"texto":"PLAFONES LATERALES (EN CASO DE LLEVARLOS).","aplica_si":"EN CASO DE LLEVARLOS"},{"orden":17,"numero":24,"texto":"BICICLETERO (EN CASO DE LLEVARLO).","aplica_si":"EN CASO DE LLEVARLO"},{"orden":18,"numero":25,"texto":"CANASTILLA O POLINERA (EN CASO DE LLEVARLA).","aplica_si":"EN CASO DE LLEVARLA"}]},{"orden":3,"nombre":"PARTE TRASERA DE LA UNIDAD","numero_original":null,"fase_orden":null,"fase_confirmada":true,"items":[{"orden":1,"numero":26,"texto":"LODERAS EN BUEN ESTADO","aplica_si":null},{"orden":2,"numero":27,"texto":"CUARTOS TRASEROS 3 PLAFONES IZQUIERDOS & 3 DERECHOS ROJOS.","aplica_si":null},{"orden":3,"numero":28,"texto":"CINTA REFLEJANTE EN ESTRIBO Y BORDA.","aplica_si":null},{"orden":4,"numero":29,"texto":"GANCHO DE ARRASTRE Y APRIETE DE TORNILLERIA GRADO 8","aplica_si":null},{"orden":5,"numero":30,"texto":"SOCKET HEMBRA DE 7 POLOS","aplica_si":null},{"orden":6,"numero":31,"texto":"MANITA DE SERVICIO & EMERGENCIA CON LLAVE","aplica_si":null},{"orden":7,"numero":32,"texto":"REVICION DE PISO.","aplica_si":null},{"orden":8,"numero":33,"texto":"PINTURA EN BUEN ESTADO.","aplica_si":null},{"orden":9,"numero":34,"texto":"DOS TOPES DE GOMA","aplica_si":null},{"orden":10,"numero":35,"texto":"DIRECCIONALES.","aplica_si":null},{"orden":11,"numero":36,"texto":"CUARTOS TRASEROS ROJOS.","aplica_si":null},{"orden":12,"numero":37,"texto":"BANDEROLAS.","aplica_si":null},{"orden":13,"numero":38,"texto":"CALCOMANIA ECHO EN MEXICO Y LEON EN EL JALON.","aplica_si":null},{"orden":14,"numero":39,"texto":"FUNCIONAMIENTO DE VALVULA PONCHADORA.","aplica_si":null},{"orden":15,"numero":40,"texto":"GANCHOS PARA LONA","aplica_si":null},{"orden":16,"numero":41,"texto":"TORNILLOS DEL PORTA PLACAS.","aplica_si":null},{"orden":17,"numero":42,"texto":"PRECAUCION DOBLE SEMI REMOLQUE (EN CASO DE LLEVARLO)","aplica_si":"EN CASO DE LLEVARLO"},{"orden":18,"numero":43,"texto":"PLAFONERAS EN ESTRIBO (EN CASO DE LLEVARLOS).","aplica_si":"EN CASO DE LLEVARLOS"}]},{"orden":4,"nombre":"PARTE DERECHA DE LA UNIDAD","numero_original":null,"fase_orden":null,"fase_confirmada":true,"items":[{"orden":1,"numero":44,"texto":"PLACA Y NUMERO SERIE.","aplica_si":null},{"orden":2,"numero":45,"texto":"CINTA REFLEJANTE.","aplica_si":null},{"orden":3,"numero":46,"texto":"UN JUEGO DE PATINES Y TORNILLERIA GRADO 5","aplica_si":null},{"orden":4,"numero":47,"texto":"SEGUNDO JUEGO DE PATINES EN BUEN ESTADO (SI LLEVA)","aplica_si":"SI LLEVA"},{"orden":5,"numero":48,"texto":"PLAFONERAS OVALADAS.","aplica_si":null},{"orden":6,"numero":49,"texto":"CALCOMANIA \"LEOLCA\" PARTE CENTRAL LADO DERECHO","aplica_si":null},{"orden":7,"numero":50,"texto":"LLANTAS EN BUEN ESTADO Y ACEITE EN MASAS.","aplica_si":null},{"orden":8,"numero":51,"texto":"PINTURA EN BUEN ESTADO","aplica_si":null},{"orden":9,"numero":52,"texto":"TORQUE TORNILLO DE PERCHA (CAPADOS).","aplica_si":null},{"orden":10,"numero":53,"texto":"CAJA DE HERRAMIENTAS","aplica_si":null},{"orden":11,"numero":54,"texto":"TORNILLO DEL PORTA LLANTAS.","aplica_si":null},{"orden":12,"numero":55,"texto":"GANCHOS PARA LONA","aplica_si":null},{"orden":13,"numero":56,"texto":"PLAFONES LATERALES (EN CASO DE LLEVARLOS).","aplica_si":"EN CASO DE LLEVARLOS"},{"orden":14,"numero":57,"texto":"BICICLETERO (EN CASO DE LLEVARLO).","aplica_si":"EN CASO DE LLEVARLO"}]}]},{"formato":"entrega","linea":"gondola","nombre":"Calidad de entrega — Góndola","unidades":["Unidad 1","Unidad 2"],"etiquetas_resultado":{"conforme":"√","no_conforme":"X"},"grupos":[{"orden":1,"nombre":"PARTE FRONTAL DE LA UNIDAD","numero_original":null,"fase_orden":null,"fase_confirmada":true,"items":[{"orden":1,"numero":1,"texto":"LEYENDA: \"HECHO EN MEXICO\" PARTE INFERIOR LADO DERECHO DE BORDA","aplica_si":null},{"orden":2,"numero":2,"texto":"CONEXIÓN HEMBRA PARA GATO","aplica_si":null},{"orden":3,"numero":3,"texto":"MANITA AZUL DE SERVICIO & MANITA ROJA DE EMERGENCIA","aplica_si":null},{"orden":4,"numero":4,"texto":"SOQUET HEMBRA 7 POLOS","aplica_si":null},{"orden":5,"numero":5,"texto":"TORNILLOS DEL PERNO SUPERIOR","aplica_si":null},{"orden":6,"numero":6,"texto":"GANCHOS PARA LONAS","aplica_si":null},{"orden":7,"numero":7,"texto":"PINTURA EN BUEN ESTADO","aplica_si":null}]},{"orden":2,"nombre":"PARTE IZQUIERDA DE LA UNIDAD","numero_original":null,"fase_orden":null,"fase_confirmada":true,"items":[{"orden":1,"numero":8,"texto":"CINTA REFLEJANTE","aplica_si":null},{"orden":2,"numero":9,"texto":"PLAFONES EN CADA CARGADOR","aplica_si":null},{"orden":3,"numero":10,"texto":"MANIVELA DE PATINES EN BUEN ESTADO","aplica_si":null},{"orden":4,"numero":11,"texto":"UN JUEGO DE PATINES Y TORNILLERIA GRADO 5","aplica_si":null},{"orden":5,"numero":12,"texto":"SEGUNDO JUEGO DE PATINES Y TORNILLERIA GRADO 5 (EN CASO DE LLEVARLO)","aplica_si":"EN CASO DE LLEVARLO"},{"orden":6,"numero":13,"texto":"LEYENDA: \"LEOLCA\" PARTE CENTRAL DE CHASIS","aplica_si":null},{"orden":7,"numero":14,"texto":"LLANTAS EN BUEN ESTADO Y TORQUE DE TUERCAS","aplica_si":null},{"orden":8,"numero":15,"texto":"TORQUE DE PERCHAS Y TORNILLOS CAPADOS.","aplica_si":null},{"orden":9,"numero":16,"texto":"GANCHOS PARA LONAS","aplica_si":null},{"orden":10,"numero":17,"texto":"INDICADOR DE ABS \"BENDIX\" Y PLAFON AMBAR","aplica_si":null},{"orden":11,"numero":18,"texto":"PINTURA EN BUEN ESTADO","aplica_si":null},{"orden":12,"numero":19,"texto":"SISTEMA RETRACTIL 1ER. EJE (EN CASO DE LLEVARLO)","aplica_si":"EN CASO DE LLEVARLO"},{"orden":13,"numero":20,"texto":"SISTEMA RETRACTIL 2O. EJE (EN CASO DE LLEVARLO)","aplica_si":"EN CASO DE LLEVARLO"},{"orden":14,"numero":21,"texto":"FUNCIONAMIENTO DE VALVULA PONCHADORA","aplica_si":null},{"orden":15,"numero":22,"texto":"TORNILLO DEL PERNO POSTERIOR","aplica_si":null},{"orden":16,"numero":23,"texto":"REVICION DEL CHAMBER","aplica_si":null}]},{"orden":3,"nombre":"PARTE TRASERA DE LA UNIDAD","numero_original":null,"fase_orden":null,"fase_confirmada":true,"items":[{"orden":1,"numero":24,"texto":"LODERAS EN BUEN ESTADO","aplica_si":null},{"orden":2,"numero":25,"texto":"CUARTOS TRASEROS 3 PLAFONES IZQUIERDOS & 3 PLAFONES DERECHOS.","aplica_si":null},{"orden":3,"numero":26,"texto":"CINTA REFLEJANTE.","aplica_si":null},{"orden":4,"numero":27,"texto":"GANCHO DE ARRASTRE Y APRIETE DE TORNILLERIA GRADO 8","aplica_si":null},{"orden":5,"numero":28,"texto":"SOQUET HEMBRA 7 POLOS","aplica_si":null},{"orden":6,"numero":29,"texto":"MANITA AZUL DE SERVICIO & MANITA ROJA DE EMERGENCIA","aplica_si":null},{"orden":7,"numero":30,"texto":"CONEXIÓN HEMBRA COSTADO DERECHO DE BORDA (EN CASO DE LLEVARLO)","aplica_si":"EN CASO DE LLEVARLO"},{"orden":8,"numero":31,"texto":"DIRECCIONALES.","aplica_si":null},{"orden":9,"numero":32,"texto":"CUARTOS TRASEROS ROJOS.","aplica_si":null},{"orden":10,"numero":33,"texto":"SEGUROS DE PUERTA","aplica_si":null},{"orden":11,"numero":34,"texto":"TORNILLOS DEL PORTA PLACAS.","aplica_si":null},{"orden":12,"numero":35,"texto":"FUNCIONAMIENTO DE GANCHOS DE PUERTA","aplica_si":null},{"orden":13,"numero":36,"texto":"TORNILLOS DE PUERTA","aplica_si":null},{"orden":14,"numero":37,"texto":"\"U\" DEL JALON","aplica_si":null},{"orden":15,"numero":38,"texto":"PASO DE CABLEADO Y MANGUERAS ADECUADO","aplica_si":null},{"orden":16,"numero":39,"texto":"PINTURA EN BUEN ESTADO","aplica_si":null}]},{"orden":4,"nombre":"PARTE DERECHA DE LA UNIDAD","numero_original":null,"fase_orden":null,"fase_confirmada":true,"items":[{"orden":1,"numero":40,"texto":"CINTA REFLEJANTE","aplica_si":null},{"orden":2,"numero":41,"texto":"PLACA Y NUMERO SERIE.","aplica_si":null},{"orden":3,"numero":42,"texto":"PLAFONES EN CADA CARGADOR","aplica_si":null},{"orden":4,"numero":43,"texto":"UN JUEGO DE PATINES Y TORNILLERIA GRADO 5","aplica_si":null},{"orden":5,"numero":44,"texto":"SEGUNDO JUEGO DE PATINES Y TORNILLERIA GRADO 5 (EN CASO DE LLEVARLO)","aplica_si":"EN CASO DE LLEVARLO"},{"orden":6,"numero":45,"texto":"LEYENDA: \"LEOLCA\" PARTE CENTRAL DE CHASIS","aplica_si":null},{"orden":7,"numero":46,"texto":"LLANTAS EN BUEN ESTADO Y TORQUE DE TUERCAS","aplica_si":null},{"orden":8,"numero":47,"texto":"TORQUE DE PERCHAS Y TORNILLOS CAPADOS.","aplica_si":null},{"orden":9,"numero":48,"texto":"GANCHOS PARA LONAS","aplica_si":null},{"orden":10,"numero":49,"texto":"PINTURA EN BUEN ESTADO","aplica_si":null},{"orden":11,"numero":50,"texto":"TORNILLO DEL PERNO POSTERIOR","aplica_si":null},{"orden":12,"numero":51,"texto":"REVICION DEL CHAMBER","aplica_si":null},{"orden":13,"numero":52,"texto":"TORNILLO DEL PORTA LLANTAS","aplica_si":null}]}]},{"formato":"entrega","linea":"dolly","nombre":"Calidad de entrega — Dolly","unidades":["Única"],"etiquetas_resultado":{"conforme":"Sí","no_conforme":"No"},"grupos":[{"orden":1,"nombre":"PARTE FRONTAL DE LA UNIDAD","numero_original":null,"fase_orden":null,"fase_confirmada":true,"items":[{"orden":1,"numero":1,"texto":"GATA DE LANZA CON BUCHACA.","aplica_si":null},{"orden":2,"numero":2,"texto":"CADENA O CHICOTE CON GANCHO DE SEGURIDAD.","aplica_si":null},{"orden":3,"numero":3,"texto":"TORNILLOS DE DONA GRADO 8.","aplica_si":null},{"orden":4,"numero":4,"texto":"SISTEMA DE RETRACTIL.","aplica_si":null},{"orden":5,"numero":5,"texto":"CONEXIÓN A TIERRA DE LANZA.","aplica_si":null},{"orden":6,"numero":6,"texto":"MANGUERA ROJA CON MANITAS (2).","aplica_si":null},{"orden":7,"numero":7,"texto":"MANGUERA AZUL CON MANITAS (2).","aplica_si":null},{"orden":8,"numero":8,"texto":"CALCOMANIA \"ECHO EN MEXICO\".","aplica_si":null},{"orden":9,"numero":9,"texto":"CABLE PERMACOIL.","aplica_si":null},{"orden":10,"numero":10,"texto":"MACHO ARMADO.","aplica_si":null},{"orden":11,"numero":11,"texto":"CINTA REFLEJANTE.","aplica_si":null},{"orden":12,"numero":12,"texto":"PINTURA EN BUEN ESTADO.","aplica_si":null}]},{"orden":2,"nombre":"PARTE IZQUIERDA DE LA UNIDAD","numero_original":null,"fase_orden":null,"fase_confirmada":true,"items":[{"orden":1,"numero":13,"texto":"INDICADOR DE ABS \"BENDIX\".","aplica_si":null},{"orden":2,"numero":14,"texto":"LLANTAS EN BUEN ESTADO Y ACEITE EN MASAS.","aplica_si":null},{"orden":3,"numero":15,"texto":"TORQUE DE TORNILLOS DE PERCHAS (CAPADOS).","aplica_si":null},{"orden":4,"numero":16,"texto":"TORNILLOS DE QUINTA RUEDA GRADO 8.","aplica_si":null},{"orden":5,"numero":17,"texto":"PINTURA EN BUEN ESTADO.","aplica_si":null}]},{"orden":3,"nombre":"PARTE TRASERA DE LA UNIDAD","numero_original":null,"fase_orden":null,"fase_confirmada":true,"items":[{"orden":1,"numero":18,"texto":"LODERAS EN BUEN ESTADO.","aplica_si":null},{"orden":2,"numero":19,"texto":"CUARTOS TRASEROS 3 PLAFONES IZQUIERDOS Y 3 DERECHOS ROJOS.","aplica_si":null},{"orden":3,"numero":20,"texto":"DIRECCIONALES.","aplica_si":null},{"orden":4,"numero":21,"texto":"TORNILLOS DEL PORTA LODERAS.","aplica_si":null},{"orden":5,"numero":22,"texto":"PINTURA EN BUEN ESTADO.","aplica_si":null}]},{"orden":4,"nombre":"PARTE DERECHA DE LA UNIDAD","numero_original":null,"fase_orden":null,"fase_confirmada":true,"items":[{"orden":1,"numero":23,"texto":"PLACA Y NUMERO DE SERIE.","aplica_si":null},{"orden":2,"numero":24,"texto":"LLANTAS EN BUEN ESTADO Y ACEITE EN MASAS.","aplica_si":null},{"orden":3,"numero":25,"texto":"TORQUE DE TORNILLOS DE PERCHAS (CAPADOS).","aplica_si":null},{"orden":4,"numero":26,"texto":"TORNILLOS DE QUINTA RUEDA GRADO 8.","aplica_si":null},{"orden":5,"numero":27,"texto":"CONEXIÓN A TIERRA DE QUINTA RUEDA.","aplica_si":null},{"orden":6,"numero":28,"texto":"PINTURA EN BUEN ESTADO.","aplica_si":null}]}]},{"formato":"entrega","linea":"cama_baja","nombre":"Calidad de entrega — Cama baja","unidades":["Única"],"etiquetas_resultado":{"conforme":"√","no_conforme":"X"},"grupos":[{"orden":1,"nombre":"PARTE FRONTAL DE LA UNIDAD","numero_original":null,"fase_orden":null,"fase_confirmada":true,"items":[{"orden":1,"numero":1,"texto":"CUARTOS FRONTALES IZQUIERDO & DERECHO \"AMBAR\".","aplica_si":null},{"orden":2,"numero":2,"texto":"MANITA AZUL DE SERVICIO Y MANITA ROJA DE EMERGENCIA.","aplica_si":null},{"orden":3,"numero":3,"texto":"SOQUET HEMBRA DE 7 POLOS.","aplica_si":null},{"orden":4,"numero":4,"texto":"CALCAMONIA HECHO EN MEXICO.","aplica_si":null},{"orden":5,"numero":5,"texto":"GANCHOS PARA LONA","aplica_si":null},{"orden":6,"numero":6,"texto":"CAJA DE HERRAMIENTAS (EN CASO DE LLEVARLA).","aplica_si":"EN CASO DE LLEVARLA"},{"orden":7,"numero":7,"texto":"PINTURA EN BUEN ESTADO.","aplica_si":null}]},{"orden":2,"nombre":"PARTE IZQUIERDA DE LA UNIDAD","numero_original":null,"fase_orden":null,"fase_confirmada":true,"items":[{"orden":1,"numero":8,"texto":"CINTA REFLEJANTE.","aplica_si":null},{"orden":2,"numero":9,"texto":"MANIVELA DE PATINES.","aplica_si":null},{"orden":3,"numero":10,"texto":"UN JUEGO DE PATINES Y TORNILLERIA GRADO 5.","aplica_si":null},{"orden":4,"numero":11,"texto":"PLAFONERAS LATERALES.","aplica_si":null},{"orden":5,"numero":12,"texto":"CALCOMANIA \"LEOLCA\" PARTE CENTRAL DEL EQUIPO.","aplica_si":null},{"orden":6,"numero":13,"texto":"SISTEMA RETRACTIL 1ER. EJE (EN CASO DE LLEVARLO).","aplica_si":"EN CASO DE LLEVARLO"},{"orden":7,"numero":14,"texto":"SISTEMA RETRACTIL 2o. EJE (EN CASO DE LLEVARLO).","aplica_si":"EN CASO DE LLEVARLO"},{"orden":8,"numero":15,"texto":"LLANTAS EN BUEN ESTADO Y ACEITE EN MASAS.","aplica_si":null},{"orden":9,"numero":16,"texto":"TORQUE TORNILLO DE PERCHA (CAPADOS).","aplica_si":null},{"orden":10,"numero":17,"texto":"PINTURA EN BUEN ESTADO","aplica_si":null},{"orden":11,"numero":18,"texto":"RIEL LOGISTICO CON LAS MATRACAS SOLICITADAS.","aplica_si":null},{"orden":12,"numero":19,"texto":"FUNCIONAMIENTO DE VALVULA PONCHADORA.","aplica_si":null},{"orden":13,"numero":20,"texto":"GANCHOS PARA LONA","aplica_si":null},{"orden":14,"numero":21,"texto":"INDICACIONES DE ABS \"BENDIX\".","aplica_si":null}]},{"orden":3,"nombre":"PARTE TRASERA DE LA UNIDAD","numero_original":null,"fase_orden":null,"fase_confirmada":true,"items":[{"orden":1,"numero":22,"texto":"CUARTOS TRASEROS 3 PLAFONES IZQUIERDOS & 3 DERECHOS ROJOS.","aplica_si":null},{"orden":2,"numero":23,"texto":"CINTA REFLEJANTE EN ESTRIBO Y BORDA.","aplica_si":null},{"orden":3,"numero":24,"texto":"REVICION DE PISO.","aplica_si":null},{"orden":4,"numero":25,"texto":"PINTURA EN BUEN ESTADO.","aplica_si":null},{"orden":5,"numero":26,"texto":"DIRECCIONALES.","aplica_si":null},{"orden":6,"numero":27,"texto":"CUARTOS TRASEROS ROJOS.","aplica_si":null},{"orden":7,"numero":28,"texto":"TORNILLOS DEL PORTA PLACAS.","aplica_si":null},{"orden":8,"numero":29,"texto":"FUNCIONAMIENTO DE RAMPAS","aplica_si":null}]},{"orden":4,"nombre":"PARTE DERECHA DE LA UNIDAD","numero_original":null,"fase_orden":null,"fase_confirmada":true,"items":[{"orden":1,"numero":30,"texto":"PLACA Y NUMERO SERIE.","aplica_si":null},{"orden":2,"numero":31,"texto":"CINTA REFLEJANTE.","aplica_si":null},{"orden":3,"numero":32,"texto":"UN JUEGO DE PATINES Y TORNILLERIA GRADO 5","aplica_si":null},{"orden":4,"numero":33,"texto":"PLAFONERAS LATERALES.","aplica_si":null},{"orden":5,"numero":34,"texto":"CALCOMANIA \"LEOLCA\" PARTE CENTRAL LADO DERECHO","aplica_si":null},{"orden":6,"numero":35,"texto":"LLANTAS EN BUEN ESTADO Y ACEITE EN MASAS.","aplica_si":null},{"orden":7,"numero":36,"texto":"PINTURA EN BUEN ESTADO","aplica_si":null},{"orden":8,"numero":37,"texto":"TORQUE TORNILLO DE PERCHA (CAPADOS).","aplica_si":null},{"orden":9,"numero":38,"texto":"PORTA LLANTAS. (EN CASO DE LLEVARLO).","aplica_si":"EN CASO DE LLEVARLO"},{"orden":10,"numero":39,"texto":"GANCHOS PARA LONA","aplica_si":null}]}]}]'::jsonb;
    v_pl jsonb;
    v_gr jsonb;
    v_it jsonb;
    v_linea_id uuid;
    v_plantilla_id uuid;
    v_grupo_id uuid;
    v_tiene_activa boolean;
    v_version integer;
BEGIN
    -- Asegurar líneas base del tablero (plataforma, gondola, dolly, traila)
    PERFORM sembrar_tablero_produccion(p_org);

    -- Asegurar línea adicional cama_baja para plantilla de entrega
    INSERT INTO lineas_producto (organizacion_id, clave, nombre)
    VALUES (p_org, 'cama_baja', 'Cama baja')
    ON CONFLICT (organizacion_id, clave) DO NOTHING;

    FOR v_pl IN SELECT * FROM jsonb_array_elements(v_seed) LOOP
        SELECT id INTO v_linea_id
        FROM lineas_producto
        WHERE organizacion_id = p_org AND clave = (v_pl->>'linea');

        IF v_linea_id IS NULL THEN
            RAISE EXCEPTION 'LINEA_NO_ENCONTRADA: %', v_pl->>'linea';
        END IF;

        -- Solo crear si no existe ya una plantilla origen='semilla' para (org, linea, formato)
        IF EXISTS (
            SELECT 1 FROM calidad_plantillas
            WHERE organizacion_id = p_org
              AND linea_producto_id = v_linea_id
              AND formato = (v_pl->>'formato')
              AND origen = 'semilla'
        ) THEN
            CONTINUE;
        END IF;

        SELECT EXISTS (
            SELECT 1 FROM calidad_plantillas
            WHERE organizacion_id = p_org
              AND linea_producto_id = v_linea_id
              AND formato = (v_pl->>'formato')
              AND estado = 'activa'
        ) INTO v_tiene_activa;

        SELECT COALESCE(MAX(version), 0) + 1 INTO v_version
        FROM calidad_plantillas
        WHERE organizacion_id = p_org
          AND linea_producto_id = v_linea_id
          AND formato = (v_pl->>'formato');

        INSERT INTO calidad_plantillas (
            organizacion_id, linea_producto_id, formato, nombre, version, estado,
            config, origen
        ) VALUES (
            p_org,
            v_linea_id,
            v_pl->>'formato',
            v_pl->>'nombre',
            v_version,
            CASE WHEN v_tiene_activa THEN 'archivada' ELSE 'activa' END,
            jsonb_build_object(
                'unidades', COALESCE(v_pl->'unidades', '["Única"]'::jsonb),
                'etiquetas_resultado', COALESCE(v_pl->'etiquetas_resultado', '{"conforme":"√","no_conforme":"X"}'::jsonb),
                'bloquea_liberacion', false
            ),
            'semilla'
        ) RETURNING id INTO v_plantilla_id;

        FOR v_gr IN SELECT * FROM jsonb_array_elements(v_pl->'grupos') LOOP
            INSERT INTO calidad_plantilla_grupos (
                organizacion_id, plantilla_id, orden, nombre, numero_original, fase_orden, fase_confirmada
            ) VALUES (
                p_org,
                v_plantilla_id,
                (v_gr->>'orden')::integer,
                v_gr->>'nombre',
                v_gr->>'numero_original',
                NULLIF(v_gr->>'fase_orden', '')::integer,
                COALESCE((v_gr->>'fase_confirmada')::boolean, true)
            ) RETURNING id INTO v_grupo_id;

            FOR v_it IN SELECT * FROM jsonb_array_elements(v_gr->'items') LOOP
                INSERT INTO calidad_plantilla_items (
                    organizacion_id, plantilla_id, grupo_id, orden, numero, texto, aplica_si
                ) VALUES (
                    p_org,
                    v_plantilla_id,
                    v_grupo_id,
                    (v_it->>'orden')::integer,
                    (v_it->>'numero')::integer,
                    v_it->>'texto',
                    v_it->>'aplica_si'
                );
            END LOOP;
        END LOOP;
    END LOOP;
END;
$$;

REVOKE ALL ON FUNCTION sembrar_calidad_plantillas(uuid) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION sembrar_calidad_plantillas(uuid) TO service_role;

CREATE OR REPLACE FUNCTION guardar_plantilla_calidad(
    p_org uuid,
    p_id uuid,
    p_payload jsonb
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_estado text;
    v_gr jsonb;
    v_it jsonb;
    v_grupo_id uuid;
    v_gr_orden integer := 0;
    v_it_orden integer := 0;
BEGIN
    SELECT estado INTO v_estado
    FROM calidad_plantillas
    WHERE id = p_id AND organizacion_id = p_org
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'PLANTILLA_NO_ENCONTRADA';
    END IF;

    IF v_estado <> 'borrador' THEN
        RAISE EXCEPTION 'NO_EDITABLE: Solo se pueden editar plantillas en borrador';
    END IF;

    UPDATE calidad_plantillas
    SET
        nombre = COALESCE(NULLIF(trim(p_payload->>'nombre'), ''), nombre),
        revision_formato = CASE WHEN p_payload ? 'revision_formato' THEN NULLIF(trim(p_payload->>'revision_formato'), '') ELSE revision_formato END,
        fecha_revision_formato = CASE WHEN p_payload ? 'fecha_revision_formato' THEN NULLIF(trim(p_payload->>'fecha_revision_formato'), '')::date ELSE fecha_revision_formato END,
        config = CASE WHEN p_payload ? 'config' AND p_payload->'config' IS NOT NULL THEN p_payload->'config' ELSE config END,
        updated_at = now()
    WHERE id = p_id AND organizacion_id = p_org;

    IF p_payload ? 'grupos' THEN
        DELETE FROM calidad_plantilla_grupos
        WHERE plantilla_id = p_id AND organizacion_id = p_org;

        v_gr_orden := 0;
        FOR v_gr IN SELECT * FROM jsonb_array_elements(COALESCE(p_payload->'grupos', '[]'::jsonb)) LOOP
            v_gr_orden := v_gr_orden + 1;
            INSERT INTO calidad_plantilla_grupos (
                organizacion_id, plantilla_id, orden, nombre, numero_original, fase_orden, fase_confirmada
            ) VALUES (
                p_org,
                p_id,
                COALESCE(NULLIF(v_gr->>'orden', '')::integer, v_gr_orden),
                v_gr->>'nombre',
                v_gr->>'numero_original',
                NULLIF(v_gr->>'fase_orden', '')::integer,
                COALESCE((v_gr->>'fase_confirmada')::boolean, true)
            ) RETURNING id INTO v_grupo_id;

            v_it_orden := 0;
            FOR v_it IN SELECT * FROM jsonb_array_elements(COALESCE(v_gr->'items', '[]'::jsonb)) LOOP
                v_it_orden := v_it_orden + 1;
                INSERT INTO calidad_plantilla_items (
                    organizacion_id, plantilla_id, grupo_id, orden, numero, texto, aplica_si
                ) VALUES (
                    p_org,
                    p_id,
                    v_grupo_id,
                    COALESCE(NULLIF(v_it->>'orden', '')::integer, v_it_orden),
                    COALESCE(NULLIF(v_it->>'numero', '')::integer, v_it_orden),
                    v_it->>'texto',
                    NULLIF(trim(COALESCE(v_it->>'aplica_si', '')), '')
                );
            END LOOP;
        END LOOP;
    END IF;

    RETURN p_id;
END;
$$;

REVOKE ALL ON FUNCTION guardar_plantilla_calidad(uuid, uuid, jsonb) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION guardar_plantilla_calidad(uuid, uuid, jsonb) TO service_role;

CREATE OR REPLACE FUNCTION duplicar_plantilla(
    p_org uuid,
    p_id uuid,
    p_linea_clave text,
    p_formato text,
    p_nombre text DEFAULT NULL
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_orig calidad_plantillas%ROWTYPE;
    v_linea_id uuid;
    v_version integer;
    v_new_id uuid;
    v_gr RECORD;
    v_new_grupo_id uuid;
BEGIN
    IF p_formato NOT IN ('control_total', 'entrega') THEN
        RAISE EXCEPTION 'FORMATO_INVALIDO: %', p_formato;
    END IF;

    SELECT * INTO v_orig
    FROM calidad_plantillas
    WHERE id = p_id AND organizacion_id = p_org;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'PLANTILLA_NO_ENCONTRADA';
    END IF;

    SELECT id INTO v_linea_id
    FROM lineas_producto
    WHERE organizacion_id = p_org AND clave = lower(trim(p_linea_clave));

    IF v_linea_id IS NULL THEN
        RAISE EXCEPTION 'LINEA_NO_ENCONTRADA: %', p_linea_clave;
    END IF;

    SELECT COALESCE(MAX(version), 0) + 1 INTO v_version
    FROM calidad_plantillas
    WHERE organizacion_id = p_org
      AND linea_producto_id = v_linea_id
      AND formato = p_formato;

    INSERT INTO calidad_plantillas (
        organizacion_id, linea_producto_id, formato, nombre, version, estado,
        revision_formato, fecha_revision_formato, config, origen
    ) VALUES (
        p_org,
        v_linea_id,
        p_formato,
        COALESCE(NULLIF(trim(p_nombre), ''), v_orig.nombre || ' (copia)'),
        v_version,
        'borrador',
        v_orig.revision_formato,
        v_orig.fecha_revision_formato,
        v_orig.config,
        'editor'
    ) RETURNING id INTO v_new_id;

    FOR v_gr IN
        SELECT * FROM calidad_plantilla_grupos
        WHERE plantilla_id = p_id AND organizacion_id = p_org
        ORDER BY orden
    LOOP
        INSERT INTO calidad_plantilla_grupos (
            organizacion_id, plantilla_id, orden, nombre, numero_original, fase_orden, fase_confirmada
        ) VALUES (
            p_org, v_new_id, v_gr.orden, v_gr.nombre, v_gr.numero_original, v_gr.fase_orden, v_gr.fase_confirmada
        ) RETURNING id INTO v_new_grupo_id;

        INSERT INTO calidad_plantilla_items (
            organizacion_id, plantilla_id, grupo_id, orden, numero, texto, aplica_si
        )
        SELECT p_org, v_new_id, v_new_grupo_id, orden, numero, texto, aplica_si
        FROM calidad_plantilla_items
        WHERE grupo_id = v_gr.id AND organizacion_id = p_org
        ORDER BY orden;
    END LOOP;

    RETURN v_new_id;
END;
$$;

REVOKE ALL ON FUNCTION duplicar_plantilla(uuid, uuid, text, text, text) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION duplicar_plantilla(uuid, uuid, text, text, text) TO service_role;

CREATE OR REPLACE FUNCTION nueva_version_plantilla(
    p_org uuid,
    p_id uuid
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_orig RECORD;
    v_linea_clave text;
BEGIN
    SELECT cp.*, lp.clave AS linea_clave INTO v_orig
    FROM calidad_plantillas cp
    JOIN lineas_producto lp ON lp.id = cp.linea_producto_id
    WHERE cp.id = p_id AND cp.organizacion_id = p_org;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'PLANTILLA_NO_ENCONTRADA';
    END IF;

    RETURN duplicar_plantilla(p_org, p_id, v_orig.linea_clave, v_orig.formato, v_orig.nombre);
END;
$$;

REVOKE ALL ON FUNCTION nueva_version_plantilla(uuid, uuid) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION nueva_version_plantilla(uuid, uuid) TO service_role;

CREATE OR REPLACE FUNCTION publicar_plantilla(
    p_org uuid,
    p_id uuid
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_pl calidad_plantillas%ROWTYPE;
    v_grupos integer;
    v_items integer;
BEGIN
    SELECT * INTO v_pl
    FROM calidad_plantillas
    WHERE id = p_id AND organizacion_id = p_org;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'PLANTILLA_NO_ENCONTRADA';
    END IF;

    -- Lock transaccional por (org, linea, formato) para evitar carrera entre dos publicaciones
    PERFORM pg_advisory_xact_lock(hashtext(p_org::text || ':' || v_pl.linea_producto_id::text || ':' || v_pl.formato));

    SELECT COUNT(*) INTO v_grupos FROM calidad_plantilla_grupos WHERE plantilla_id = p_id AND organizacion_id = p_org;
    SELECT COUNT(*) INTO v_items FROM calidad_plantilla_items WHERE plantilla_id = p_id AND organizacion_id = p_org;

    IF v_grupos < 1 OR v_items < 1 THEN
        RAISE EXCEPTION 'PLANTILLA_VACIA: La plantilla debe tener al menos un grupo y un punto para publicarse';
    END IF;

    UPDATE calidad_plantillas
    SET estado = 'archivada', updated_at = now()
    WHERE organizacion_id = p_org
      AND linea_producto_id = v_pl.linea_producto_id
      AND formato = v_pl.formato
      AND estado = 'activa'
      AND id <> p_id;

    UPDATE calidad_plantillas
    SET estado = 'activa', updated_at = now()
    WHERE id = p_id AND organizacion_id = p_org;

    RETURN p_id;
END;
$$;

REVOKE ALL ON FUNCTION publicar_plantilla(uuid, uuid) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION publicar_plantilla(uuid, uuid) TO service_role;

CREATE OR REPLACE FUNCTION eliminar_plantilla_borrador(
    p_org uuid,
    p_id uuid
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_estado text;
BEGIN
    SELECT estado INTO v_estado
    FROM calidad_plantillas
    WHERE id = p_id AND organizacion_id = p_org
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'PLANTILLA_NO_ENCONTRADA';
    END IF;

    IF v_estado <> 'borrador' THEN
        RAISE EXCEPTION 'NO_EDITABLE: Solo se pueden eliminar plantillas en borrador';
    END IF;

    IF EXISTS (SELECT 1 FROM orden_calidad_inspecciones WHERE plantilla_id = p_id) THEN
        RAISE EXCEPTION 'TIENE_INSPECCIONES: No se puede eliminar una plantilla con inspecciones asociadas';
    END IF;

    DELETE FROM calidad_plantillas WHERE id = p_id AND organizacion_id = p_org;
END;
$$;

REVOKE ALL ON FUNCTION eliminar_plantilla_borrador(uuid, uuid) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION eliminar_plantilla_borrador(uuid, uuid) TO service_role;

CREATE OR REPLACE FUNCTION crear_inspeccion_calidad(
    p_org uuid,
    p_orden uuid,
    p_formato text,
    p_plantilla uuid DEFAULT NULL,
    p_usuario uuid DEFAULT NULL
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_orden RECORD;
    v_existente_id uuid;
    v_plantilla_id uuid;
    v_intento integer;
    v_seq integer;
    v_folio text;
    v_new_id uuid;
BEGIN
    IF p_formato NOT IN ('control_total', 'entrega') THEN
        RAISE EXCEPTION 'FORMATO_INVALIDO: %', p_formato;
    END IF;

    -- Lock de fila en ordenes_trabajo para serializar creaciones concurrentes
    SELECT id, linea_producto_id, tipo_equipo, modelo, etiqueta INTO v_orden
    FROM ordenes_trabajo
    WHERE id = p_orden AND organizacion_id = p_org
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'ORDEN_NO_ENCONTRADA';
    END IF;

    SELECT id INTO v_existente_id
    FROM orden_calidad_inspecciones
    WHERE orden_trabajo_id = p_orden
      AND formato = p_formato
      AND estado = 'en_proceso';

    IF v_existente_id IS NOT NULL THEN
        RAISE EXCEPTION 'YA_EXISTE:%', v_existente_id;
    END IF;

    IF p_plantilla IS NOT NULL THEN
        SELECT id INTO v_plantilla_id
        FROM calidad_plantillas
        WHERE id = p_plantilla
          AND organizacion_id = p_org
          AND formato = p_formato
          AND estado = 'activa';
        IF v_plantilla_id IS NULL THEN
            RAISE EXCEPTION 'PLANTILLA_NO_ENCONTRADA';
        END IF;
    ELSE
        -- Si la orden es Cama baja (tipo_equipo '05' o descripción/etiqueta), priorizar plantilla activa de cama_baja
        IF trim(COALESCE(v_orden.tipo_equipo, '')) = '05'
           OR lower(COALESCE(v_orden.modelo, '') || ' ' || COALESCE(v_orden.etiqueta, '')) ~ 'cama\s*baja' THEN
            SELECT cp.id INTO v_plantilla_id
            FROM calidad_plantillas cp
            JOIN lineas_producto lp ON lp.id = cp.linea_producto_id
            WHERE cp.organizacion_id = p_org
              AND lp.organizacion_id = p_org
              AND lp.clave = 'cama_baja'
              AND cp.formato = p_formato
              AND cp.estado = 'activa'
            LIMIT 1;
        END IF;

        IF v_plantilla_id IS NULL THEN
            SELECT id INTO v_plantilla_id
            FROM calidad_plantillas
            WHERE organizacion_id = p_org
              AND linea_producto_id = v_orden.linea_producto_id
              AND formato = p_formato
              AND estado = 'activa';
        END IF;

        IF v_plantilla_id IS NULL THEN
            RAISE EXCEPTION 'SIN_PLANTILLA: No hay plantilla activa para esta línea y formato. Créala en Calidad → Plantillas';
        END IF;
    END IF;

    SELECT COALESCE(MAX(intento), 0) + 1 INTO v_intento
    FROM orden_calidad_inspecciones
    WHERE orden_trabajo_id = p_orden AND formato = p_formato;

    INSERT INTO calidad_folios (organizacion_id, formato, ultimo)
    VALUES (p_org, p_formato, 1)
    ON CONFLICT (organizacion_id, formato)
    DO UPDATE SET ultimo = calidad_folios.ultimo + 1
    RETURNING ultimo INTO v_seq;

    v_folio := (CASE WHEN p_formato = 'control_total' THEN 'CCT-' ELSE 'CE-' END) || lpad(v_seq::text, 6, '0');

    INSERT INTO orden_calidad_inspecciones (
        organizacion_id, orden_trabajo_id, plantilla_id, formato, folio,
        intento, estado, evaluado_por, fecha_inicio, actualizado_por
    ) VALUES (
        p_org, p_orden, v_plantilla_id, p_formato, v_folio,
        v_intento, 'en_proceso', NULL, CURRENT_DATE, p_usuario
    ) RETURNING id INTO v_new_id;

    RETURN v_new_id;
END;
$$;

REVOKE ALL ON FUNCTION crear_inspeccion_calidad(uuid, uuid, text, uuid, uuid) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION crear_inspeccion_calidad(uuid, uuid, text, uuid, uuid) TO service_role;

CREATE OR REPLACE FUNCTION guardar_resultados_calidad(
    p_org uuid,
    p_inspeccion uuid,
    p_resultados jsonb,
    p_usuario uuid DEFAULT NULL
)
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_insp orden_calidad_inspecciones%ROWTYPE;
    v_elem jsonb;
    v_item_id uuid;
    v_unidad integer;
    v_resultado text;
    v_operario_id uuid;
    v_colaborador text;
    v_fecha date;
    v_obs text;
    v_max_unidades integer;
    v_procesados integer := 0;
BEGIN
    SELECT * INTO v_insp
    FROM orden_calidad_inspecciones
    WHERE id = p_inspeccion AND organizacion_id = p_org
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'INSPECCION_NO_ENCONTRADA';
    END IF;

    IF v_insp.estado <> 'en_proceso' THEN
        RAISE EXCEPTION 'INSPECCION_CERRADA: La inspección ya está cerrada y no admite cambios';
    END IF;

    SELECT GREATEST(1, COALESCE(jsonb_array_length(config->'unidades'), 1)) INTO v_max_unidades
    FROM calidad_plantillas
    WHERE id = v_insp.plantilla_id;

    FOR v_elem IN SELECT * FROM jsonb_array_elements(COALESCE(p_resultados, '[]'::jsonb)) LOOP
        v_item_id := (v_elem->>'item_id')::uuid;
        v_unidad := COALESCE(NULLIF(v_elem->>'unidad', '')::integer, 1);
        v_resultado := NULLIF(trim(COALESCE(v_elem->>'resultado', '')), '');

        IF v_unidad < 1 OR v_unidad > v_max_unidades THEN
            RAISE EXCEPTION 'UNIDAD_INVALIDA: La unidad % está fuera de rango (1..%)', v_unidad, v_max_unidades;
        END IF;

        IF NOT EXISTS (
            SELECT 1 FROM calidad_plantilla_items
            WHERE id = v_item_id AND plantilla_id = v_insp.plantilla_id AND organizacion_id = p_org
        ) THEN
            RAISE EXCEPTION 'ITEM_INVALIDO: %', v_item_id;
        END IF;

        IF v_resultado IS NULL THEN
            DELETE FROM orden_calidad_resultados
            WHERE inspeccion_id = p_inspeccion AND item_id = v_item_id AND unidad = v_unidad;
        ELSE
            IF v_resultado NOT IN ('conforme', 'no_conforme', 'no_aplica') THEN
                RAISE EXCEPTION 'RESULTADO_INVALIDO: %', v_resultado;
            END IF;

            v_operario_id := NULLIF(trim(COALESCE(v_elem->>'operario_id', '')), '')::uuid;
            v_colaborador := NULLIF(trim(COALESCE(v_elem->>'colaborador', '')), '');
            v_fecha := NULLIF(trim(COALESCE(v_elem->>'fecha_inspeccion', '')), '')::date;
            v_obs := NULLIF(trim(COALESCE(v_elem->>'observaciones', '')), '');

            IF v_operario_id IS NOT NULL THEN
                SELECT nombre INTO v_colaborador
                FROM operarios
                WHERE id = v_operario_id AND organizacion_id = p_org;
                IF NOT FOUND THEN
                    RAISE EXCEPTION 'OPERARIO_NO_ENCONTRADO';
                END IF;
                v_colaborador := COALESCE(NULLIF(trim(COALESCE(v_elem->>'colaborador', '')), ''), v_colaborador);
            END IF;

            INSERT INTO orden_calidad_resultados (
                organizacion_id, inspeccion_id, item_id, unidad, resultado,
                operario_id, colaborador, fecha_inspeccion, observaciones, updated_at
            ) VALUES (
                p_org, p_inspeccion, v_item_id, v_unidad, v_resultado,
                v_operario_id, v_colaborador, COALESCE(v_fecha, CURRENT_DATE), v_obs, now()
            )
            ON CONFLICT (inspeccion_id, item_id, unidad)
            DO UPDATE SET
                resultado = EXCLUDED.resultado,
                operario_id = EXCLUDED.operario_id,
                colaborador = EXCLUDED.colaborador,
                fecha_inspeccion = EXCLUDED.fecha_inspeccion,
                observaciones = EXCLUDED.observaciones,
                updated_at = now();
        END IF;

        v_procesados := v_procesados + 1;
    END LOOP;

    UPDATE orden_calidad_inspecciones
    SET updated_at = now(), actualizado_por = p_usuario
    WHERE id = p_inspeccion AND organizacion_id = p_org;

    RETURN v_procesados;
END;
$$;

REVOKE ALL ON FUNCTION guardar_resultados_calidad(uuid, uuid, jsonb, uuid) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION guardar_resultados_calidad(uuid, uuid, jsonb, uuid) TO service_role;

CREATE OR REPLACE FUNCTION cerrar_inspeccion_calidad(
    p_org uuid,
    p_inspeccion uuid,
    p_liberado_por text DEFAULT NULL,
    p_fecha_liberacion date DEFAULT NULL,
    p_usuario uuid DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_insp orden_calidad_inspecciones%ROWTYPE;
    v_config jsonb;
    v_unidades integer;
    v_total_items integer;
    v_total_esperados integer;
    v_capturados integer;
    v_no_conformes integer;
    v_pendientes integer;
    v_bloquea boolean;
BEGIN
    SELECT * INTO v_insp
    FROM orden_calidad_inspecciones
    WHERE id = p_inspeccion AND organizacion_id = p_org
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'INSPECCION_NO_ENCONTRADA';
    END IF;

    IF v_insp.estado = 'cerrada' THEN
        RAISE EXCEPTION 'YA_CERRADA';
    END IF;

    SELECT config INTO v_config
    FROM calidad_plantillas
    WHERE id = v_insp.plantilla_id;

    v_unidades := GREATEST(1, COALESCE(jsonb_array_length(v_config->'unidades'), 1));
    v_bloquea := COALESCE((v_config->>'bloquea_liberacion')::boolean, false);

    SELECT COUNT(*) INTO v_total_items
    FROM calidad_plantilla_items
    WHERE plantilla_id = v_insp.plantilla_id;

    v_total_esperados := v_total_items * v_unidades;

    SELECT
        COUNT(*),
        COUNT(*) FILTER (WHERE resultado = 'no_conforme')
    INTO v_capturados, v_no_conformes
    FROM orden_calidad_resultados
    WHERE inspeccion_id = p_inspeccion
      AND unidad BETWEEN 1 AND v_unidades;

    v_pendientes := GREATEST(0, v_total_esperados - v_capturados);

    IF v_bloquea AND v_no_conformes > 0 THEN
        RAISE EXCEPTION 'BLOQUEADA_POR_NO_CONFORMES: Hay % puntos no conformes y la plantilla bloquea la liberación', v_no_conformes;
    END IF;

    UPDATE orden_calidad_inspecciones
    SET
        estado = 'cerrada',
        liberado_por = COALESCE(NULLIF(trim(p_liberado_por), ''), liberado_por),
        fecha_liberacion = COALESCE(p_fecha_liberacion, CURRENT_DATE),
        updated_at = now(),
        actualizado_por = p_usuario
    WHERE id = p_inspeccion AND organizacion_id = p_org;

    RETURN jsonb_build_object(
        'id', p_inspeccion,
        'estado', 'cerrada',
        'advertencias', jsonb_build_object(
            'pendientes', v_pendientes,
            'no_conformes', v_no_conformes
        )
    );
END;
$$;

REVOKE ALL ON FUNCTION cerrar_inspeccion_calidad(uuid, uuid, text, date, uuid) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION cerrar_inspeccion_calidad(uuid, uuid, text, date, uuid) TO service_role;

CREATE OR REPLACE FUNCTION reabrir_inspeccion_calidad(
    p_org uuid,
    p_inspeccion uuid,
    p_usuario uuid DEFAULT NULL
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_insp orden_calidad_inspecciones%ROWTYPE;
BEGIN
    SELECT * INTO v_insp
    FROM orden_calidad_inspecciones
    WHERE id = p_inspeccion AND organizacion_id = p_org
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'INSPECCION_NO_ENCONTRADA';
    END IF;

    IF v_insp.estado <> 'cerrada' THEN
        RETURN p_inspeccion;
    END IF;

    IF EXISTS (
        SELECT 1 FROM orden_calidad_inspecciones
        WHERE orden_trabajo_id = v_insp.orden_trabajo_id
          AND formato = v_insp.formato
          AND estado = 'en_proceso'
          AND id <> p_inspeccion
    ) THEN
        RAISE EXCEPTION 'YA_EXISTE: Ya hay una inspección en proceso para esta orden y formato';
    END IF;

    UPDATE orden_calidad_inspecciones
    SET
        estado = 'en_proceso',
        fecha_liberacion = NULL,
        updated_at = now(),
        actualizado_por = p_usuario
    WHERE id = p_inspeccion AND organizacion_id = p_org;

    RETURN p_inspeccion;
END;
$$;

REVOKE ALL ON FUNCTION reabrir_inspeccion_calidad(uuid, uuid, uuid) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION reabrir_inspeccion_calidad(uuid, uuid, uuid) TO service_role;

CREATE OR REPLACE FUNCTION resumen_calidad_ordenes(p_org uuid)
RETURNS TABLE (
    orden_trabajo_id uuid,
    inspeccion_id uuid,
    formato text,
    folio text,
    intento integer,
    estado text,
    total_esperados integer,
    capturados integer,
    conformes integer,
    no_conformes integer,
    no_aplica integer,
    pendientes integer
)
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
    WITH ultimas AS (
        SELECT DISTINCT ON (i.orden_trabajo_id, i.formato)
            i.id,
            i.orden_trabajo_id,
            i.plantilla_id,
            i.formato,
            i.folio,
            i.intento,
            i.estado,
            GREATEST(1, COALESCE(jsonb_array_length(p.config->'unidades'), 1)) AS num_unidades
        FROM orden_calidad_inspecciones i
        JOIN calidad_plantillas p ON p.id = i.plantilla_id
        WHERE i.organizacion_id = p_org
        ORDER BY i.orden_trabajo_id, i.formato, i.intento DESC
    ),
    conteo_items AS (
        SELECT plantilla_id, COUNT(*)::integer AS num_items
        FROM calidad_plantilla_items
        WHERE organizacion_id = p_org
        GROUP BY plantilla_id
    ),
    conteo_res AS (
        SELECT
            r.inspeccion_id,
            COUNT(*)::integer AS capturados,
            COUNT(*) FILTER (WHERE r.resultado = 'conforme')::integer AS conformes,
            COUNT(*) FILTER (WHERE r.resultado = 'no_conforme')::integer AS no_conformes,
            COUNT(*) FILTER (WHERE r.resultado = 'no_aplica')::integer AS no_aplica
        FROM orden_calidad_resultados r
        JOIN ultimas u ON u.id = r.inspeccion_id
        WHERE r.organizacion_id = p_org
          AND r.unidad BETWEEN 1 AND u.num_unidades
        GROUP BY r.inspeccion_id
    )
    SELECT
        u.orden_trabajo_id,
        u.id AS inspeccion_id,
        u.formato,
        u.folio,
        u.intento,
        u.estado,
        (COALESCE(ci.num_items, 0) * u.num_unidades)::integer AS total_esperados,
        COALESCE(cr.capturados, 0)::integer AS capturados,
        COALESCE(cr.conformes, 0)::integer AS conformes,
        COALESCE(cr.no_conformes, 0)::integer AS no_conformes,
        COALESCE(cr.no_aplica, 0)::integer AS no_aplica,
        GREATEST(0, (COALESCE(ci.num_items, 0) * u.num_unidades) - COALESCE(cr.capturados, 0))::integer AS pendientes
    FROM ultimas u
    LEFT JOIN conteo_items ci ON ci.plantilla_id = u.plantilla_id
    LEFT JOIN conteo_res cr ON cr.inspeccion_id = u.id;
$$;

REVOKE ALL ON FUNCTION resumen_calidad_ordenes(uuid) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION resumen_calidad_ordenes(uuid) TO service_role;

CREATE OR REPLACE FUNCTION crear_plantilla_borrador(
    p_org uuid,
    p_linea_clave text,
    p_formato text,
    p_nombre text
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_linea_id uuid;
    v_version integer;
    v_new_id uuid;
BEGIN
    IF p_formato NOT IN ('control_total', 'entrega') THEN
        RAISE EXCEPTION 'FORMATO_INVALIDO: %', p_formato;
    END IF;

    IF NULLIF(trim(COALESCE(p_nombre, '')), '') IS NULL THEN
        RAISE EXCEPTION 'NOMBRE_REQUERIDO: El nombre de la plantilla es obligatorio';
    END IF;

    SELECT id INTO v_linea_id
    FROM lineas_producto
    WHERE organizacion_id = p_org AND clave = lower(trim(p_linea_clave));

    IF v_linea_id IS NULL THEN
        RAISE EXCEPTION 'LINEA_NO_ENCONTRADA: %', p_linea_clave;
    END IF;

    SELECT COALESCE(MAX(version), 0) + 1 INTO v_version
    FROM calidad_plantillas
    WHERE organizacion_id = p_org
      AND linea_producto_id = v_linea_id
      AND formato = p_formato;

    INSERT INTO calidad_plantillas (
        organizacion_id, linea_producto_id, formato, nombre, version, estado, origen
    ) VALUES (
        p_org, v_linea_id, p_formato, trim(p_nombre), v_version, 'borrador', 'editor'
    ) RETURNING id INTO v_new_id;

    RETURN v_new_id;
END;
$$;

REVOKE ALL ON FUNCTION crear_plantilla_borrador(uuid, text, text, text) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION crear_plantilla_borrador(uuid, text, text, text) TO service_role;

CREATE OR REPLACE FUNCTION actualizar_encabezado_inspeccion(
    p_org uuid,
    p_inspeccion uuid,
    p_payload jsonb,
    p_usuario uuid DEFAULT NULL
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_estado text;
BEGIN
    SELECT estado INTO v_estado
    FROM orden_calidad_inspecciones
    WHERE id = p_inspeccion AND organizacion_id = p_org
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'INSPECCION_NO_ENCONTRADA';
    END IF;

    IF v_estado <> 'en_proceso' THEN
        RAISE EXCEPTION 'INSPECCION_CERRADA: La inspección ya está cerrada y no admite cambios';
    END IF;

    UPDATE orden_calidad_inspecciones
    SET
        evaluado_por = CASE WHEN p_payload ? 'evaluado_por' THEN NULLIF(trim(COALESCE(p_payload->>'evaluado_por', '')), '') ELSE evaluado_por END,
        fecha_inicio = CASE WHEN p_payload ? 'fecha_inicio' THEN NULLIF(trim(COALESCE(p_payload->>'fecha_inicio', '')), '')::date ELSE fecha_inicio END,
        liberado_por = CASE WHEN p_payload ? 'liberado_por' THEN NULLIF(trim(COALESCE(p_payload->>'liberado_por', '')), '') ELSE liberado_por END,
        nota = CASE WHEN p_payload ? 'nota' THEN NULLIF(trim(COALESCE(p_payload->>'nota', '')), '') ELSE nota END,
        updated_at = now(),
        actualizado_por = p_usuario
    WHERE id = p_inspeccion AND organizacion_id = p_org;

    RETURN p_inspeccion;
END;
$$;

REVOKE ALL ON FUNCTION actualizar_encabezado_inspeccion(uuid, uuid, jsonb, uuid) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION actualizar_encabezado_inspeccion(uuid, uuid, jsonb, uuid) TO service_role;

-- 4. Sembrar plantillas iniciales para todas las organizaciones existentes
DO $$
DECLARE
    r_org RECORD;
BEGIN
    FOR r_org IN SELECT id FROM organizaciones LOOP
        PERFORM sembrar_calidad_plantillas(r_org.id);
    END LOOP;
END $$;

COMMIT;
