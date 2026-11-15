-- Migración: Despiece de GONDOLA 2 EJES 45 M3 y GONDOLA 3 EJES 45 M3 (solo datos, sin mover precios)
-- Fecha: 2026-11-14
-- Propósito:
--   1. Alta de 11 materiales en productos con costo 0.00 y precio 0.00:
--      (ROLLO DE SOLIDO, DISCO DE CORTE 14, ESPARRAGO DE 1", TUERCA ESTANDAR 1",
--       TORNILLO 1 X 2 1/2 GRADO 8, TUERCA DE SEGURIDAD 1", CODO 3/8 +1,
--       TORNILLO 3/8 X 1 1/4 GRADO 8, AMORTIGUADOR GRC85938,
--       CAMARA DE SUSPENSION GOOD YEAR R14-232, ABRAZADERAS HJ).
--   2. Cargar 156 renglones a receta_base (seccion NULL, escala 'fija'):
--      - 98 renglones en GONDOLA 2 EJES 45 M3 (58 comunes + 40 de aire).
--      - 58 renglones en GONDOLA 3 EJES 45 M3 (58 comunes; aire queda por confirmar).
--   3. Cargar 9 componentes en opcion_componentes para suspensión hj_alta (HJ tipo Low alta):
--      - Escala por_eje, paso 'PASO 5', fase 'paso_5'.
--   4. Asignación condicional de fase_id si fases_despiece existe.
-- Reglas duras:
--   - Idempotente (dos pasadas con ON_ERROR_STOP=1 sin duplicados).
--   - Llave de idempotencia = (modelo_id, material_id, uso).
--   - Sin saltos silenciosos: valida existencia de todo material con RAISE EXCEPTION.
--   - Cero impacto en precios ni costos (seccion NULL, costo 0.00, acero de góndolas intacto).
--   - Sin UUIDs fijos de organización en código.

BEGIN;

DO $$
DECLARE
    v_org_id uuid;
    v_mod_2ejes uuid;
    v_mod_3ejes uuid;
    v_opc_hj_alta uuid;
    v_faltante text;
BEGIN
    -- 0. Resolver ID de organización y modelos
    SELECT id INTO v_org_id FROM public.organizaciones LIMIT 1;
    IF v_org_id IS NULL THEN
        RAISE EXCEPTION 'No se encontró ninguna organización en la base de datos.';
    END IF;

    SELECT id INTO v_mod_2ejes
    FROM public.modelos
    WHERE tipo = 'gondola' AND num_ejes = 2 AND organizacion_id = v_org_id
    LIMIT 1;
    IF v_mod_2ejes IS NULL THEN
        RAISE EXCEPTION 'No se encontró el modelo de GONDOLA 2 EJES 45 M3.';
    END IF;

    SELECT id INTO v_mod_3ejes
    FROM public.modelos
    WHERE tipo = 'gondola' AND num_ejes = 3 AND organizacion_id = v_org_id
    LIMIT 1;
    IF v_mod_3ejes IS NULL THEN
        RAISE EXCEPTION 'No se encontró el modelo de GONDOLA 3 EJES 45 M3.';
    END IF;

    SELECT o.id INTO v_opc_hj_alta
    FROM public.opciones_configuracion o
    JOIN public.grupos_configuracion g ON g.id = o.grupo_id
    WHERE g.clave = 'suspension' AND o.clave = 'hj_alta' AND o.organizacion_id = v_org_id
    LIMIT 1;
    IF v_opc_hj_alta IS NULL THEN
        RAISE EXCEPTION 'No se encontró la opción de configuración suspension/hj_alta.';
    END IF;

    -- =========================================================================
    -- 1. Alta de 11 materiales nuevos (costo 0.00, precio 0.00)
    -- =========================================================================
    INSERT INTO public.productos (nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, organizacion_id)
    SELECT v.nombre, 'bien', 'materia_prima', v.unidad, 0.00, 0.00, v.descripcion, v_org_id
    FROM (VALUES
        ('ROLLO DE SOLIDO', 'PZA', 'TINA'),
        ('DISCO DE CORTE 14', 'PZA', 'Receta base'),
        ('ESPARRAGO DE 1"', 'PZA', 'PUERTA DE LA GONDOLA'),
        ('TUERCA ESTANDAR 1"', 'PZA', 'PUERTA DE LA GONDOLA'),
        ('TORNILLO 1 X 2 1/2 GRADO 8', 'PZA', 'PUERTA DE LA GONDOLA'),
        ('TUERCA DE SEGURIDAD 1"', 'PZA', 'PUERTA DE LA GONDOLA'),
        ('CODO 3/8 +1', 'PZA', 'Receta base'),
        ('TORNILLO 3/8 X 1 1/4 GRADO 8', 'PZA', 'KIT DE TANQUE DE AIRE'),
        ('AMORTIGUADOR GRC85938', 'PZA', 'HJ tipo Low alta'),
        ('CAMARA DE SUSPENSION GOOD YEAR R14-232', 'PZA', 'HJ tipo Low alta'),
        ('ABRAZADERAS HJ', 'PZA', 'HJ tipo Low alta')
    ) AS v(nombre, unidad, descripcion)
    WHERE NOT EXISTS (
        SELECT 1 FROM public.productos p WHERE p.nombre = v.nombre AND p.organizacion_id = v_org_id
    );

    -- =========================================================================
    -- 2. Receta base de Góndolas (98 definiciones: 58 ambas, 40 solo 2 ejes)
    -- =========================================================================
    CREATE TEMP TABLE tmp_gondola_receta (
        modelo_scope text,
        paso text,
        fase_clave text,
        material_nombre text,
        cantidad numeric,
        uso text,
        condicion jsonb,
        notas text
    ) ON COMMIT DROP;

    INSERT INTO tmp_gondola_receta (modelo_scope, paso, fase_clave, material_nombre, cantidad, uso, condicion, notas)
    VALUES
        ('ambas', 'PASO 1', 'paso_1', 'CONSUMIBLE 65', 1, NULL, NULL, 'Paso provisional: el manual de la góndola no trae paso para este renglón (queda en Paso 1 como cae hoy); Leolca confirma.'),
        ('ambas', 'PASO 1', 'paso_1', 'DISCO DE DESBASTE 9', 2, NULL, NULL, 'Paso provisional: el manual de la góndola no trae paso para este renglón (queda en Paso 1 como cae hoy); Leolca confirma.'),
        ('ambas', 'PASO 1', 'paso_1', 'ROLLO DE MICROALAMBRE', 3, 'CHASIS', NULL, 'Paso provisional: el manual de la góndola no trae paso para este renglón (queda en Paso 1 como cae hoy); Leolca confirma.'),
        ('ambas', 'PASO 1', 'paso_1', 'ROLLO DE SOLIDO', 4, 'TINA', NULL, 'Paso provisional: el manual de la góndola no trae paso para este renglón (queda en Paso 1 como cae hoy); Leolca confirma.'),
        ('ambas', 'PASO 1', 'paso_1', 'DISCO DE CORTE 7', 5, NULL, NULL, 'Paso provisional: el manual de la góndola no trae paso para este renglón (queda en Paso 1 como cae hoy); Leolca confirma.'),
        ('ambas', 'PASO 1', 'paso_1', 'OXIGENO', 7, NULL, NULL, 'Paso provisional: el manual de la góndola no trae paso para este renglón (queda en Paso 1 como cae hoy); Leolca confirma.'),
        ('ambas', 'PASO 1', 'paso_1', 'DISCO LAMINADO 7', 5, NULL, NULL, 'Paso provisional: el manual de la góndola no trae paso para este renglón (queda en Paso 1 como cae hoy); Leolca confirma.'),
        ('ambas', 'PASO 1', 'paso_1', 'DISCO DE CORTE 14', 2, NULL, NULL, 'Paso provisional: el manual de la góndola no trae paso para este renglón (queda en Paso 1 como cae hoy); Leolca confirma. No existe ''DISCO DE CORTE 14'' (solo el de 7).'),
        ('ambas', 'PASO 1', 'paso_1', 'CO2', 8, 'ARMADO (1) + TINA (7)', NULL, 'El manual trae CO2 dos veces (1 y 7): se carga un renglón con 8. Paso provisional: el manual de la góndola no trae paso para este renglón (queda en Paso 1 como cae hoy); Leolca confirma.'),
        ('ambas', 'PASO 3', 'paso_3', 'PERNO REY 3/8', 1, NULL, NULL, 'Paso 3 porque la descripción de esa fase menciona el perno rey; provisional. El sistema ya cobra ''KIT DE PERNOS'' $13,000 (acero) y ''Perno rey Holland'' $1,200 (otros): ver pregunta de posible cobro doble.'),
        ('ambas', 'PASO 1', 'paso_1', 'ESPARRAGO DE 1"', 1, 'PUERTA DE LA GONDOLA', NULL, 'Paso provisional: el manual de la góndola no trae paso para este renglón (queda en Paso 1 como cae hoy); Leolca confirma.'),
        ('ambas', 'PASO 1', 'paso_1', 'TUERCA ESTANDAR 1"', 4, 'PUERTA DE LA GONDOLA', NULL, 'Paso provisional: el manual de la góndola no trae paso para este renglón (queda en Paso 1 como cae hoy); Leolca confirma.'),
        ('ambas', 'PASO 1', 'paso_1', 'TORNILLO 1 X 2 1/2 GRADO 8', 2, 'PUERTA DE LA GONDOLA', NULL, 'Paso provisional: el manual de la góndola no trae paso para este renglón (queda en Paso 1 como cae hoy); Leolca confirma.'),
        ('ambas', 'PASO 1', 'paso_1', 'TUERCA DE SEGURIDAD 1"', 2, 'PUERTA DE LA GONDOLA', NULL, 'Paso provisional: el manual de la góndola no trae paso para este renglón (queda en Paso 1 como cae hoy); Leolca confirma.'),
        ('ambas', 'PASO 6', 'paso_6', 'TORNILLO 5/8 X 1 1/2 GRADO 5', 44, '2 PARES DE PATINES', NULL, 'El manual dice 44 y el concepto del sistema (''Kit de tornillería para patines'' ×44) también; la lista de tornillería (nota 55) dice 30. Se carga 44; Leolca confirma.'),
        ('ambas', 'PASO 6', 'paso_6', 'TUERCA ESTANDAR 5/8 GRADO 5', 44, '2 PARES DE PATINES', NULL, 'Idem tornillo: manual y concepto 44, lista 30.'),
        ('ambas', 'LIMPIEZA', 'paso_7', 'LIJA #80', 2, NULL, NULL, NULL),
        ('ambas', 'LIMPIEZA', 'paso_7', 'CARDA 5/8 DE 3"', 1, NULL, NULL, NULL),
        ('ambas', 'LIMPIEZA', 'paso_7', 'DISCO LAMINADO 4 1/2', 1, NULL, NULL, NULL),
        ('ambas', 'LIMPIEZA', 'paso_7', 'FOSFATO', 1, NULL, NULL, NULL),
        ('2_ejes', 'AIRE', 'paso_9', 'REDUCCION 3/4 * 1/2', 1, NULL, NULL, 'Manual y kit de aire de Leolca coinciden'),
        ('2_ejes', 'AIRE', 'paso_9', 'REDUCCION 3/8 * 1/4', 3, NULL, NULL, 'Manual y kit de aire de Leolca coinciden'),
        ('2_ejes', 'AIRE', 'paso_9', 'NIPLE 1/4', 1, NULL, NULL, 'Manual y kit de aire de Leolca coinciden'),
        ('2_ejes', 'AIRE', 'paso_9', 'TAPON 3/4', 1, NULL, NULL, 'Manual y kit de aire de Leolca coinciden'),
        ('2_ejes', 'AIRE', 'paso_9', 'TAPON 1/2', 1, NULL, NULL, 'Manual y kit de aire de Leolca coinciden'),
        ('2_ejes', 'AIRE', 'paso_9', 'TAPON 1/8', 2, NULL, NULL, 'Manual y kit de aire de Leolca coinciden'),
        ('2_ejes', 'AIRE', 'paso_9', 'TE UNIO 3/8', 2, NULL, NULL, 'Manual y kit de aire de Leolca coinciden'),
        ('2_ejes', 'AIRE', 'paso_9', 'TE LATERAL 3/8*1/4', 8, NULL, NULL, 'Manual y kit de aire de Leolca coinciden'),
        ('2_ejes', 'AIRE', 'paso_9', 'TE CENTRO 3/8*1/4', 2, NULL, NULL, 'Manual y kit de aire de Leolca coinciden'),
        ('2_ejes', 'AIRE', 'paso_9', 'RECTA 3/8*1/4', 6, NULL, NULL, 'Manual y kit de aire de Leolca coinciden'),
        ('2_ejes', 'AIRE', 'paso_9', 'CODO 3/8*1/4', 14, NULL, NULL, 'Manual y kit de aire de Leolca coinciden'),
        ('2_ejes', 'AIRE', 'paso_9', 'CODO 3/8 +1', 2, NULL, '{"todas":[{"op":"!=","campo":"gancho","valor":"sin_gancho"}]}'::jsonb, 'Manual y kit de aire de Leolca coinciden · solo si lleva gancho (misma condición que plataformas)'),
        ('2_ejes', 'AIRE', 'paso_9', 'CODO 1/2', 2, NULL, NULL, 'Manual y kit de aire de Leolca coinciden'),
        ('2_ejes', 'AIRE', 'paso_9', 'ADAPTADOR 3/8', 8, NULL, NULL, 'Manual y kit de aire de Leolca coinciden'),
        ('2_ejes', 'AIRE', 'paso_9', 'MACHO 3/8', 8, NULL, NULL, 'Manual y kit de aire de Leolca coinciden'),
        ('2_ejes', 'AIRE', 'paso_9', 'HEMBRA 3/8', 8, NULL, NULL, 'Manual y kit de aire de Leolca coinciden'),
        ('2_ejes', 'AIRE', 'paso_9', 'KIT DE ABS 2 EJES BENDIX', 1, NULL, NULL, 'Manual y kit de aire de Leolca coinciden'),
        ('2_ejes', 'AIRE', 'paso_9', 'VALVULA PROTECTORA', 1, NULL, NULL, 'Manual y kit de aire de Leolca coinciden'),
        ('2_ejes', 'AIRE', 'paso_9', 'VALVULA NIVELADORA', 1, NULL, NULL, 'Manual y kit de aire de Leolca coinciden'),
        ('2_ejes', 'AIRE', 'paso_9', 'VALVULA PALANQUETA', 2, NULL, NULL, 'Manual y kit de aire de Leolca coinciden'),
        ('2_ejes', 'AIRE', 'paso_9', 'VARILLA NIVELADORA', 1, NULL, NULL, 'Manual y kit de aire de Leolca coinciden'),
        ('2_ejes', 'AIRE', 'paso_9', 'VALVULA RETRACTIL SEALCO', 1, NULL, NULL, 'Manual y kit de aire de Leolca coinciden'),
        ('2_ejes', 'AIRE', 'paso_9', 'MANITA AZUL C/LLAVE', 1, NULL, '{"todas":[{"op":"!=","campo":"gancho","valor":"sin_gancho"}]}'::jsonb, 'Manual y kit de aire de Leolca coinciden · solo si lleva gancho (misma condición que plataformas)'),
        ('2_ejes', 'AIRE', 'paso_9', 'MANITA ROJA C/LLAVE', 1, NULL, '{"todas":[{"op":"!=","campo":"gancho","valor":"sin_gancho"}]}'::jsonb, 'Manual y kit de aire de Leolca coinciden · solo si lleva gancho (misma condición que plataformas)'),
        ('2_ejes', 'AIRE', 'paso_9', 'MANITA AZUL S/LLAVE', 1, NULL, NULL, 'Manual y kit de aire de Leolca coinciden'),
        ('2_ejes', 'AIRE', 'paso_9', 'MANITA ROJA S/LLAVE', 1, NULL, NULL, 'Manual y kit de aire de Leolca coinciden'),
        ('2_ejes', 'AIRE', 'paso_9', 'ESPARRAGO', 2, NULL, NULL, 'Manual y kit de aire de Leolca coinciden'),
        ('2_ejes', 'AIRE', 'paso_9', 'TEFLON DE 13 METROS', 2, NULL, NULL, 'Manual y kit de aire de Leolca coinciden'),
        ('2_ejes', 'AIRE', 'paso_9', 'INCERTO 3/8', 20, NULL, NULL, 'Manual y kit de aire de Leolca coinciden'),
        ('2_ejes', 'AIRE', 'paso_9', 'INCERTO 1/2', 2, NULL, NULL, 'Manual y kit de aire de Leolca coinciden'),
        ('2_ejes', 'AIRE', 'paso_9', 'MANGUERA AZUL 3/8', 38, NULL, NULL, 'Solo en el manual'),
        ('2_ejes', 'AIRE', 'paso_9', 'MANGUERA ROJA 3/8', 13, NULL, NULL, 'Solo en el manual'),
        ('2_ejes', 'AIRE', 'paso_9', 'MANGUERA CHAMBER 3/8', 9, NULL, NULL, 'Solo en el manual'),
        ('2_ejes', 'AIRE', 'paso_9', 'TORNILLO 3/8 X 1 1/4 GRADO 8', 8, 'KIT DE TANQUE DE AIRE', NULL, 'Manual y kit de aire de Leolca coinciden'),
        ('2_ejes', 'AIRE', 'paso_9', 'TUERCA DE SEGURIDAD 3/8', 8, 'KIT DE TANQUE DE AIRE', NULL, 'Manual y kit de aire de Leolca coinciden'),
        ('2_ejes', 'AIRE', 'paso_9', 'RONDANA PLANA 3/8', 8, 'KIT DE TANQUE DE AIRE', NULL, 'Manual y kit de aire de Leolca coinciden'),
        ('2_ejes', 'AIRE', 'paso_9', 'TORNILLO 5/16 X 5 GRADO 8', 2, 'KIT DE TORNILLOS DE ABS', NULL, 'Manual y kit de aire de Leolca coinciden'),
        ('2_ejes', 'AIRE', 'paso_9', 'RONDANA PLANA 5/16', 4, 'KIT DE TORNILLOS DE ABS', NULL, 'Manual y kit de aire de Leolca coinciden'),
        ('2_ejes', 'AIRE', 'paso_9', 'TUERCA DE SEGURIDAD 5/16', 2, 'KIT DE TORNILLOS DE ABS', NULL, 'Manual y kit de aire de Leolca coinciden'),
        ('2_ejes', 'AIRE', 'paso_9', 'TANQUE DE AIRE DE PLANA', 2, NULL, NULL, 'Solo en el manual'),
        ('ambas', 'AIRE', 'paso_9', 'TORNILLO 3/4 X 3 1/2 GRADO 8', 2, 'KIT DE GANCHO', '{"todas":[{"op":"!=","campo":"gancho","valor":"sin_gancho"}]}'::jsonb, 'Kit de gancho: idéntico al que ya tienen las plataformas (misma cantidad y condición)'),
        ('ambas', 'AIRE', 'paso_9', 'TORNILLO 3/4 X 2 1/2 GRADO 8', 6, 'KIT DE GANCHO', '{"todas":[{"op":"!=","campo":"gancho","valor":"sin_gancho"}]}'::jsonb, 'Kit de gancho: idéntico al que ya tienen las plataformas (misma cantidad y condición)'),
        ('ambas', 'AIRE', 'paso_9', 'TUERCA GRIPCO 3/4', 8, 'KIT DE GANCHO', '{"todas":[{"op":"!=","campo":"gancho","valor":"sin_gancho"}]}'::jsonb, 'Kit de gancho: idéntico al que ya tienen las plataformas (misma cantidad y condición)'),
        ('ambas', 'AIRE', 'paso_9', 'RONDANA AUTOMOTRIZ 3/4', 2, 'KIT DE GANCHO', '{"todas":[{"op":"!=","campo":"gancho","valor":"sin_gancho"}]}'::jsonb, 'Kit de gancho: idéntico al que ya tienen las plataformas (misma cantidad y condición)'),
        ('ambas', 'LUZ', 'paso_10', 'HEMBRA 7 POLOS', 2, NULL, NULL, 'Solo en el manual de la góndola (sin kit de luz propio para comparar)'),
        ('ambas', 'LUZ', 'paso_10', 'TORNILLO 1/4 X 1 GALVANIZADO', 2, 'HEMBRAS Y PLAFON ABS', NULL, 'Solo en el manual de la góndola (sin kit de luz propio para comparar)'),
        ('ambas', 'LUZ', 'paso_10', 'RONDANA PLANA 5/16', 2, 'HEMBRAS Y PLAFON ABS', NULL, 'Solo en el manual de la góndola (sin kit de luz propio para comparar)'),
        ('ambas', 'LUZ', 'paso_10', 'TUERCA ESTANDAR 1/4', 2, 'HEMBRAS Y PLAFON ABS', NULL, 'Solo en el manual de la góndola (sin kit de luz propio para comparar)'),
        ('ambas', 'LUZ', 'paso_10', 'CABLE AZUL CAL,12', 15.9, NULL, NULL, 'Solo en el manual de la góndola (sin kit de luz propio para comparar)'),
        ('ambas', 'LUZ', 'paso_10', 'CABLE ROJO CAL,12', 17.3, NULL, NULL, 'Solo en el manual de la góndola (sin kit de luz propio para comparar)'),
        ('ambas', 'LUZ', 'paso_10', 'CABLE AMARILLO CAL,12', 22, NULL, NULL, 'Solo en el manual de la góndola (sin kit de luz propio para comparar)'),
        ('ambas', 'LUZ', 'paso_10', 'CABLE VERDE CAL,12', 22, NULL, NULL, 'Solo en el manual de la góndola (sin kit de luz propio para comparar)'),
        ('ambas', 'LUZ', 'paso_10', 'CABLE CAFE CAL,12', 28.5, NULL, NULL, 'Solo en el manual de la góndola (sin kit de luz propio para comparar)'),
        ('ambas', 'LUZ', 'paso_10', 'CABLE NEGRO CAL,12', 15.9, NULL, NULL, 'Solo en el manual de la góndola (sin kit de luz propio para comparar)'),
        ('ambas', 'LUZ', 'paso_10', 'CORRUGADO 1/2', 14.5, NULL, NULL, 'Solo en el manual de la góndola (sin kit de luz propio para comparar)'),
        ('ambas', 'LUZ', 'paso_10', 'CORRUGADO 3/8', 2.8, NULL, NULL, 'Solo en el manual de la góndola (sin kit de luz propio para comparar)'),
        ('ambas', 'LUZ', 'paso_10', 'CORRUGADO 1/4', 21.8, NULL, NULL, 'Solo en el manual de la góndola (sin kit de luz propio para comparar)'),
        ('ambas', 'LUZ', 'paso_10', 'TERMINAL 3/16', 19, 'PLAFONES PRINCIPALES', NULL, 'Solo en el manual de la góndola (sin kit de luz propio para comparar)'),
        ('ambas', 'LUZ', 'paso_10', 'TERMINAL 1/4', 2, 'HEMBRAS', NULL, 'Solo en el manual de la góndola (sin kit de luz propio para comparar)'),
        ('ambas', 'LUZ', 'paso_10', 'REMACHE 3/16 X 5/8', 51, NULL, NULL, 'Solo en el manual de la góndola (sin kit de luz propio para comparar)'),
        ('ambas', 'LUZ', 'paso_10', 'CINTA DE AISLAR', 1, NULL, NULL, 'Solo en el manual de la góndola (sin kit de luz propio para comparar)'),
        ('ambas', 'LUZ', 'paso_10', 'PLAFON ROJO 4', 6, NULL, NULL, 'Solo en el manual de la góndola (sin kit de luz propio para comparar)'),
        ('ambas', 'LUZ', 'paso_10', 'PLAFON ROJO 2', 3, NULL, NULL, 'Solo en el manual de la góndola (sin kit de luz propio para comparar)'),
        ('ambas', 'LUZ', 'paso_10', 'PLAFON AMBAR 2', 10, NULL, NULL, 'Solo en el manual de la góndola (sin kit de luz propio para comparar)'),
        ('ambas', 'TERMINADO', 'paso_12', 'LODERA BLANCA O NEGRA', 2, NULL, NULL, NULL),
        ('ambas', 'TERMINADO', 'paso_12', 'FLEJE', 2, NULL, NULL, NULL),
        ('ambas', 'TERMINADO', 'paso_12', 'TORNILLO 1/4 X 1 ACERO INOXIDABLE', 8, 'TORNILLERIA DE LODERA', NULL, NULL),
        ('ambas', 'TERMINADO', 'paso_12', 'TUERCA DE SEGURIDAD 1/4', 8, 'TORNILLERIA DE LODERA', NULL, NULL),
        ('ambas', 'TERMINADO', 'paso_12', 'WINCHES', 2, NULL, NULL, NULL),
        ('ambas', 'TERMINADO', 'paso_12', 'KIT DE ROTULACION', 1, NULL, NULL, NULL),
        ('ambas', 'TERMINADO', 'paso_12', 'CINTA REFLEJANTE', 1, NULL, NULL, NULL),
        ('ambas', 'TERMINADO', 'paso_12', 'PLACA DE NIP', 1, NULL, NULL, NULL),
        ('ambas', 'TERMINADO', 'paso_12', 'TORNILLO 1/4 X 1 ACERO INOXIDABLE', 4, 'TORNILLERIA DE PORTA PLACA', NULL, NULL),
        ('ambas', 'TERMINADO', 'paso_12', 'TUERCA DE SEGURIDAD 1/4', 4, 'TORNILLERIA DE PORTA PLACA', NULL, NULL),
        ('ambas', 'EXTRAS', 'extras', 'TORNILLO 3/4 X 6 GRADO 8', 2, 'AMORTIGUADOR DE ALTA', '{"todas":[{"op":"in","campo":"suspension","valor":["alta_hendrickson","alta_fleet_master","hj_alta"]}]}'::jsonb, 'Igual que en plataformas y dolly'),
        ('ambas', 'EXTRAS', 'extras', 'TUERCA DE SEGURIDAD 3/4', 4, 'AMORTIGUADOR DE ALTA', '{"todas":[{"op":"in","campo":"suspension","valor":["alta_hendrickson","alta_fleet_master","hj_alta"]}]}'::jsonb, 'Igual que en plataformas y dolly'),
        ('ambas', 'EXTRAS', 'extras', 'TORNILLO 3/4 X 3 1/2 GRADO 8', 2, 'AMORTIGUADOR DE ALTA', '{"todas":[{"op":"in","campo":"suspension","valor":["alta_hendrickson","alta_fleet_master","hj_alta"]}]}'::jsonb, 'Igual que en plataformas y dolly'),
        ('ambas', 'EXTRAS', 'extras', 'RONDANA AUTOMOTRIZ 3/4', 4, 'AMORTIGUADOR DE ALTA', '{"todas":[{"op":"in","campo":"suspension","valor":["alta_hendrickson","alta_fleet_master","hj_alta"]}]}'::jsonb, 'Igual que en plataformas y dolly');

    -- Validación anti-salto silencioso: confirmar que todos los materiales existan en catálogo
    SELECT t.material_nombre INTO v_faltante
    FROM tmp_gondola_receta t
    LEFT JOIN public.productos p ON p.nombre = t.material_nombre AND p.organizacion_id = v_org_id
    WHERE p.id IS NULL
    LIMIT 1;
    IF v_faltante IS NOT NULL THEN
        RAISE EXCEPTION 'Material "%" requerido en receta base no existe en catálogo de productos.', v_faltante;
    END IF;

    -- Cargar en GONDOLA 2 EJES 45 M3 (ambas + 2_ejes = 98 renglones)
    INSERT INTO public.receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    SELECT
        v_mod_2ejes,
        p.id,
        t.cantidad,
        'fija',
        t.paso,
        t.uso,
        NULL,
        t.condicion,
        t.notas
    FROM tmp_gondola_receta t
    JOIN public.productos p ON p.nombre = t.material_nombre AND p.organizacion_id = v_org_id
    WHERE NOT EXISTS (
        SELECT 1 FROM public.receta_base rb
        WHERE rb.modelo_id = v_mod_2ejes
          AND rb.material_id = p.id
          AND coalesce(rb.uso, '') = coalesce(t.uso, '')
    );

    UPDATE public.receta_base rb
    SET cantidad = t.cantidad,
        escala = 'fija',
        paso = t.paso,
        seccion = NULL,
        condicion = t.condicion,
        notas = t.notas
    FROM tmp_gondola_receta t
    JOIN public.productos p ON p.nombre = t.material_nombre AND p.organizacion_id = v_org_id
    WHERE rb.modelo_id = v_mod_2ejes
      AND rb.material_id = p.id
      AND coalesce(rb.uso, '') = coalesce(t.uso, '')
      AND rb.seccion IS NULL;

    -- Cargar en GONDOLA 3 EJES 45 M3 (solo ambas = 58 renglones)
    INSERT INTO public.receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    SELECT
        v_mod_3ejes,
        p.id,
        t.cantidad,
        'fija',
        t.paso,
        t.uso,
        NULL,
        t.condicion,
        t.notas
    FROM tmp_gondola_receta t
    JOIN public.productos p ON p.nombre = t.material_nombre AND p.organizacion_id = v_org_id
    WHERE t.modelo_scope = 'ambas'
      AND NOT EXISTS (
        SELECT 1 FROM public.receta_base rb
        WHERE rb.modelo_id = v_mod_3ejes
          AND rb.material_id = p.id
          AND coalesce(rb.uso, '') = coalesce(t.uso, '')
    );

    UPDATE public.receta_base rb
    SET cantidad = t.cantidad,
        escala = 'fija',
        paso = t.paso,
        seccion = NULL,
        condicion = t.condicion,
        notas = t.notas
    FROM tmp_gondola_receta t
    JOIN public.productos p ON p.nombre = t.material_nombre AND p.organizacion_id = v_org_id
    WHERE t.modelo_scope = 'ambas'
      AND rb.modelo_id = v_mod_3ejes
      AND rb.material_id = p.id
      AND coalesce(rb.uso, '') = coalesce(t.uso, '')
      AND rb.seccion IS NULL;

    -- =========================================================================
    -- 3. Componentes de la opción suspension/hj_alta (9 componentes)
    -- =========================================================================
    CREATE TEMP TABLE tmp_hj_alta_comp (
        material_nombre text,
        cantidad numeric,
        escala text,
        rol text,
        paso text,
        fase_clave text,
        notas text
    ) ON COMMIT DROP;

    INSERT INTO tmp_hj_alta_comp (material_nombre, cantidad, escala, rol, paso, fase_clave, notas)
    VALUES
        ('PIERNAS IZQUIERDA Y DERECHA', 1, 'por_eje', 'componente', 'PASO 5', 'paso_5', 'Manual 2 por suspensión de 2 ejes = 1 por eje (mismo patrón que alta_hendrickson).'),
        ('PLATOS IZQUIERDO Y DERECHO', 1, 'por_eje', 'componente', 'PASO 5', 'paso_5', 'Manual 2 por suspensión de 2 ejes = 1 por eje (mismo patrón que alta_hendrickson).'),
        ('AMORTIGUADOR GRC85938', 1, 'por_eje', 'componente', 'PASO 5', 'paso_5', 'Manual 2 por suspensión de 2 ejes = 1 por eje (mismo patrón que alta_hendrickson).'),
        ('AMORTIGUADOR MONRROE 65512', 0, 'por_eje', 'sustituto', 'PASO 5', 'paso_5', 'Manual 2 por suspensión de 2 ejes = 0 por eje (mismo patrón que alta_hendrickson). Sustituto: cantidad 0.'),
        ('CAMARA DE SUSPENSION GOOD YEAR R14-232', 1, 'por_eje', 'componente', 'PASO 5', 'paso_5', 'Manual 2 por suspensión de 2 ejes = 1 por eje (mismo patrón que alta_hendrickson).'),
        ('RONDANAS CENTRICAS HENDRICKSON', 1, 'por_eje', 'componente', 'PASO 5', 'paso_5', 'Manual 2 por suspensión de 2 ejes = 1 por eje (mismo patrón que alta_hendrickson).'),
        ('RONDANAS EXCENTRICAS HENDRICKSON', 1, 'por_eje', 'componente', 'PASO 5', 'paso_5', 'Manual 2 por suspensión de 2 ejes = 1 por eje (mismo patrón que alta_hendrickson).'),
        ('BUJE TRIFUNCIONAL CON TORNILLO', 1, 'por_eje', 'componente', 'PASO 5', 'paso_5', 'Manual 2 por suspensión de 2 ejes = 1 por eje (mismo patrón que alta_hendrickson).'),
        ('ABRAZADERAS HJ', 2, 'por_eje', 'componente', 'PASO 5', 'paso_5', 'Manual 4 por suspensión de 2 ejes = 2 por eje (mismo patrón que alta_hendrickson).');

    -- Validación anti-salto silencioso para componentes
    SELECT t.material_nombre INTO v_faltante
    FROM tmp_hj_alta_comp t
    LEFT JOIN public.productos p ON p.nombre = t.material_nombre AND p.organizacion_id = v_org_id
    WHERE p.id IS NULL
    LIMIT 1;
    IF v_faltante IS NOT NULL THEN
        RAISE EXCEPTION 'Material "%" requerido en componentes de hj_alta no existe en catálogo.', v_faltante;
    END IF;

    INSERT INTO public.opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, uso, seccion, condicion, notas)
    SELECT
        v_opc_hj_alta,
        p.id,
        t.cantidad,
        t.escala,
        t.rol,
        t.paso,
        NULL,
        NULL,
        NULL,
        t.notas
    FROM tmp_hj_alta_comp t
    JOIN public.productos p ON p.nombre = t.material_nombre AND p.organizacion_id = v_org_id
    WHERE NOT EXISTS (
        SELECT 1 FROM public.opcion_componentes oc
        WHERE oc.opcion_id = v_opc_hj_alta
          AND oc.material_id = p.id
    );

    UPDATE public.opcion_componentes oc
    SET cantidad = t.cantidad,
        escala = t.escala,
        rol = t.rol,
        paso = t.paso,
        uso = NULL,
        seccion = NULL,
        condicion = NULL,
        notas = t.notas
    FROM tmp_hj_alta_comp t
    JOIN public.productos p ON p.nombre = t.material_nombre AND p.organizacion_id = v_org_id
    WHERE oc.opcion_id = v_opc_hj_alta
      AND oc.material_id = p.id;

    -- =========================================================================
    -- 4. Asignación de fase_id (condicional si fases_despiece existe en la base)
    -- =========================================================================
    IF to_regclass('public.fases_despiece') IS NOT NULL THEN
        -- Actualizar receta_base de ambas góndolas vinculando con fases_despiece (y equivalencias si aplica)
        EXECUTE '
            UPDATE public.receta_base rb
            SET fase_id = coalesce(fd.id, fe.fase_id)
            FROM tmp_gondola_receta t
            JOIN public.productos p ON p.nombre = t.material_nombre AND p.organizacion_id = $1
            LEFT JOIN public.fases_despiece fd ON fd.clave = t.fase_clave AND fd.organizacion_id = $1
            LEFT JOIN public.fases_despiece_equivalencias fe ON fe.paso_legacy = t.paso AND fe.organizacion_id = $1
            WHERE rb.modelo_id IN ($2, $3)
              AND rb.material_id = p.id
              AND coalesce(rb.uso, '''') = coalesce(t.uso, '''')
              AND rb.seccion IS NULL
              AND (rb.fase_id IS NULL OR rb.fase_id != coalesce(fd.id, fe.fase_id));
        ' USING v_org_id, v_mod_2ejes, v_mod_3ejes;

        -- Actualizar componentes de hj_alta vinculando con fases_despiece (y equivalencias)
        EXECUTE '
            UPDATE public.opcion_componentes oc
            SET fase_id = coalesce(fd.id, fe.fase_id)
            FROM tmp_hj_alta_comp t
            JOIN public.productos p ON p.nombre = t.material_nombre AND p.organizacion_id = $1
            LEFT JOIN public.fases_despiece fd ON fd.clave = t.fase_clave AND fd.organizacion_id = $1
            LEFT JOIN public.fases_despiece_equivalencias fe ON fe.paso_legacy = t.paso AND fe.organizacion_id = $1
            WHERE oc.opcion_id = $2
              AND oc.material_id = p.id
              AND (oc.fase_id IS NULL OR oc.fase_id != coalesce(fd.id, fe.fase_id));
        ' USING v_org_id, v_opc_hj_alta;
    END IF;

END $$;

COMMIT;
