/**
 * Script generador de la migración para el Sub-bloque 2R-10:
 * Matracas hasta 20 piezas y varios sistemas retráctiles por equipo.
 * 
 * Uso: node scripts/generar_matracas_retractiles_sql.cjs
 */
const fs = require('fs');
const path = require('path');

// Constantes nombradas del generador
const WINCHES_FIJA = 20; // Cantidad máxima de matracas/winches fijas
const MATRACAS_CANTIDAD_DEFECTO = 12; // Cantidad base por defecto en matracas cuando no se indica
const RETRACTIL_POR_EJE = 1; // Supuesto pendiente de confirmar con el dueño: hasta 1 sistema retráctil por eje
const RETRACTIL_CANTIDAD_DEFECTO = 1; // Cantidad por defecto de retráctil (1 sistema)
const RINES_POR_EJE = 4; // Rines por eje (4 piezas por eje: 8 en 2 ejes, 12 en 3 ejes)
const LLANTAS_POR_EJE = 4; // Llantas por eje (4 piezas por eje: 8 en 2 ejes, 12 en 3 ejes)

const sql = `-- Migración 20261020_01_matracas_retractiles.sql
-- Sub-bloque 2R-10: Matracas hasta 20 piezas y varios sistemas retráctiles por equipo
-- 1. 'matracas': regla = {"max_total":{"fija":${WINCHES_FIJA}},"cantidad_defecto":${MATRACAS_CANTIDAD_DEFECTO}}, cantidad = 'Hasta ${WINCHES_FIJA} piezas fijas'
-- 2. 'retractil': seleccion = 'multiple_con_cantidad', regla = {"max_total":{"por_eje":${RETRACTIL_POR_EJE}},"cantidad_defecto":${RETRACTIL_CANTIDAD_DEFECTO}}
-- 3. 'rines' y 'llantas': explicitan cantidad_defecto = 'max' en regla
-- 4. Idempotente con guardias de coherencia (RAISE EXCEPTION si algún grupo no existe exactamente 1 vez por org)
-- 5. Notas exactas: 'import-2r10'

BEGIN;

DO $$
DECLARE
    r_org RECORD;
    v_count_rines int;
    v_count_llantas int;
    v_count_matracas int;
    v_count_retractil int;
BEGIN
    FOR r_org IN SELECT id FROM organizaciones LOOP
        -- Verificar que cada grupo exista exactamente una vez en la organización
        SELECT count(*) INTO v_count_rines 
        FROM grupos_configuracion 
        WHERE organizacion_id = r_org.id AND clave = 'rines';

        SELECT count(*) INTO v_count_llantas 
        FROM grupos_configuracion 
        WHERE organizacion_id = r_org.id AND clave = 'llantas';

        SELECT count(*) INTO v_count_matracas 
        FROM grupos_configuracion 
        WHERE organizacion_id = r_org.id AND clave = 'matracas';

        SELECT count(*) INTO v_count_retractil 
        FROM grupos_configuracion 
        WHERE organizacion_id = r_org.id AND clave = 'retractil';

        IF v_count_rines <> 1 THEN
            RAISE EXCEPTION 'Org %: grupo "rines" encontrado % veces (se esperaba 1)', r_org.id, v_count_rines;
        END IF;
        IF v_count_llantas <> 1 THEN
            RAISE EXCEPTION 'Org %: grupo "llantas" encontrado % veces (se esperaba 1)', r_org.id, v_count_llantas;
        END IF;
        IF v_count_matracas <> 1 THEN
            RAISE EXCEPTION 'Org %: grupo "matracas" encontrado % veces (se esperaba 1)', r_org.id, v_count_matracas;
        END IF;
        IF v_count_retractil <> 1 THEN
            RAISE EXCEPTION 'Org %: grupo "retractil" encontrado % veces (se esperaba 1)', r_org.id, v_count_retractil;
        END IF;

        -- Actualizar grupo rines: seleccion multiple_con_cantidad, max_total por eje (${RINES_POR_EJE}), cantidad_defecto 'max'
        UPDATE grupos_configuracion
        SET seleccion = 'multiple_con_cantidad',
            regla = jsonb_build_object('max_total', jsonb_build_object('por_eje', ${RINES_POR_EJE}), 'cantidad_defecto', 'max'),
            cantidad = '${RINES_POR_EJE} por eje (8 en 2 ejes, 12 en 3 ejes)',
            notas = 'import-2r10'
        WHERE organizacion_id = r_org.id AND clave = 'rines';

        -- Actualizar grupo llantas: seleccion multiple_con_cantidad, max_total por eje (${LLANTAS_POR_EJE}), cantidad_defecto 'max'
        UPDATE grupos_configuracion
        SET seleccion = 'multiple_con_cantidad',
            regla = jsonb_build_object('max_total', jsonb_build_object('por_eje', ${LLANTAS_POR_EJE}), 'cantidad_defecto', 'max'),
            cantidad = '${LLANTAS_POR_EJE} por eje (8 en 2 ejes, 12 en 3 ejes)',
            notas = 'import-2r10'
        WHERE organizacion_id = r_org.id AND clave = 'llantas';

        -- Actualizar grupo matracas: seleccion multiple_con_cantidad, max_total fija (${WINCHES_FIJA}), cantidad_defecto ${MATRACAS_CANTIDAD_DEFECTO}
        UPDATE grupos_configuracion
        SET seleccion = 'multiple_con_cantidad',
            regla = jsonb_build_object('max_total', jsonb_build_object('fija', ${WINCHES_FIJA}), 'cantidad_defecto', ${MATRACAS_CANTIDAD_DEFECTO}),
            cantidad = 'Hasta ${WINCHES_FIJA} piezas fijas',
            unidad_precio = 'pieza',
            notas = 'import-2r10'
        WHERE organizacion_id = r_org.id AND clave = 'matracas';

        -- Actualizar grupo retractil: seleccion multiple_con_cantidad, max_total por eje (${RETRACTIL_POR_EJE}), cantidad_defecto ${RETRACTIL_CANTIDAD_DEFECTO}
        UPDATE grupos_configuracion
        SET seleccion = 'multiple_con_cantidad',
            regla = jsonb_build_object('max_total', jsonb_build_object('por_eje', ${RETRACTIL_POR_EJE}), 'cantidad_defecto', ${RETRACTIL_CANTIDAD_DEFECTO}),
            cantidad = '${RETRACTIL_POR_EJE} por eje (hasta 2 en 2 ejes, 3 en 3 ejes)',
            unidad_precio = 'pieza',
            notas = 'import-2r10'
        WHERE organizacion_id = r_org.id AND clave = 'retractil';

    END LOOP;
END $$;

COMMIT;
`;

const outputPath = path.join(__dirname, '..', 'supabase', 'migrations', '20261020_01_matracas_retractiles.sql');
fs.writeFileSync(outputPath, sql, 'utf8');
console.log('Migración generada con éxito en:', outputPath);
