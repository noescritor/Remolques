/**
 * Pruebas reales contra PostgreSQL para el módulo de Calidad (Parte 1).
 *
 * Uso:
 *   1. Crear base desechable desde plantilla con la migración aplicada:
 *      createdb -h localhost -p 54331 -U tester -T remolques test_calidad_c1
 *      psql -h localhost -p 54331 -U tester -d test_calidad_c1 -v ON_ERROR_STOP=1 -f supabase/migrations/20261121_01_calidad.sql
 *   2. Ejecutar:
 *      node scripts/test_calidad_pg.cjs
 *   Variables opcionales: PGHOST, PGPORT, PGUSER, PGPASSWORD, PGDATABASE.
 */
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const { Pool } = require('pg');

const pool = new Pool({
  host: process.env.PGHOST || 'localhost',
  port: Number(process.env.PGPORT || 54331),
  user: process.env.PGUSER || 'tester',
  password: process.env.PGPASSWORD || 'tester',
  database: process.env.PGDATABASE || 'test_calidad_c1',
});

async function main() {
  const { rows: [orgA] } = await pool.query('SELECT id FROM organizaciones LIMIT 1');
  const orgAId = orgA.id;

  const { rows: [orgB] } = await pool.query(
    `INSERT INTO organizaciones (nombre) VALUES ('Org Aislada Calidad Test') RETURNING id`
  );
  const orgBId = orgB.id;
  await pool.query('SELECT sembrar_calidad_plantillas($1)', [orgBId]);

  console.log('1. Verificando que re-sembrar no pisa plantilla editada por usuario...');
  const { rows: [platCt] } = await pool.query(
    `SELECT cp.id FROM calidad_plantillas cp
     JOIN lineas_producto lp ON lp.id = cp.linea_producto_id
     WHERE cp.organizacion_id = $1 AND lp.clave = 'plataforma' AND cp.formato = 'control_total' AND cp.estado = 'activa'`,
    [orgAId]
  );
  const { rows: [v2IdRow] } = await pool.query('SELECT nueva_version_plantilla($1, $2) AS id', [orgAId, platCt.id]);
  const v2Id = v2IdRow.id;
  await pool.query(
    `SELECT guardar_plantilla_calidad($1, $2, $3::jsonb)`,
    [
      orgAId,
      v2Id,
      JSON.stringify({
        nombre: 'Control Total Editado Usuario',
        grupos: [{ orden: 1, nombre: 'Grupo Custom', items: [{ orden: 1, numero: 1, texto: 'Punto custom' }] }],
      }),
    ]
  );
  await pool.query('SELECT publicar_plantilla($1, $2)', [orgAId, v2Id]);
  await pool.query('SELECT sembrar_calidad_plantillas($1)', [orgAId]);
  const { rows: [activaDespues] } = await pool.query(
    `SELECT id, nombre, estado FROM calidad_plantillas WHERE id = $1`,
    [v2Id]
  );
  assert.equal(activaDespues.estado, 'activa');
  assert.equal(activaDespues.nombre, 'Control Total Editado Usuario');
  await pool.query('SELECT publicar_plantilla($1, $2)', [orgAId, platCt.id]);
  console.log('   OK: re-semilla respeta ediciones del usuario y publicar archiva la anterior.');

  console.log('2. Verificando NO_EDITABLE, duplicar a Dolly y eliminar borrador...');
  await assert.rejects(
    () => pool.query(`SELECT guardar_plantilla_calidad($1, $2, '{"nombre":"X"}'::jsonb)`, [orgAId, platCt.id]),
    /NO_EDITABLE/
  );
  const { rows: [dupRow] } = await pool.query(
    `SELECT duplicar_plantilla($1, $2, 'dolly', 'control_total', 'Control Total Dolly (copia)') AS id`,
    [orgAId, platCt.id]
  );
  const dupDollyId = dupRow.id;
  const { rows: [{ cnt: cntDupItems }] } = await pool.query(
    'SELECT COUNT(*)::int AS cnt FROM calidad_plantilla_items WHERE plantilla_id = $1',
    [dupDollyId]
  );
  assert.equal(cntDupItems, 116);
  await pool.query('SELECT eliminar_plantilla_borrador($1, $2)', [orgAId, dupDollyId]);
  console.log('   OK: NO_EDITABLE, duplicar_plantilla (116 items) y eliminar_plantilla_borrador.');

  console.log('3. Verificando SIN_PLANTILLA, folios consecutivos, YA_EXISTE, evaluado_por NULL y rechazo de borrador/archivada...');
  const { rows: [lineaPlat] } = await pool.query(
    `SELECT id FROM lineas_producto WHERE organizacion_id = $1 AND clave = 'plataforma'`,
    [orgAId]
  );
  const { rows: [lineaGond] } = await pool.query(
    `SELECT id FROM lineas_producto WHERE organizacion_id = $1 AND clave = 'gondola'`,
    [orgAId]
  );
  const { rows: [ordPlat] } = await pool.query(
    `INSERT INTO ordenes_trabajo (organizacion_id, linea_producto_id, nomenclatura_id, etiqueta, modelo, estado, origen)
     VALUES ($1, $2, 'NOM-CAL-PLAT', 'EQ-CAL-PLAT', 'Plataforma 40 ft', 'En Producción', 'manual') RETURNING id`,
    [orgAId, lineaPlat.id]
  );
  const { rows: [ordGond] } = await pool.query(
    `INSERT INTO ordenes_trabajo (organizacion_id, linea_producto_id, nomenclatura_id, etiqueta, modelo, estado, origen)
     VALUES ($1, $2, 'NOM-CAL-GOND', 'EQ-CAL-GOND', 'Góndola 45 m3', 'En Producción', 'manual') RETURNING id`,
    [orgAId, lineaGond.id]
  );

  await assert.rejects(
    () => pool.query(`SELECT crear_inspeccion_calidad($1, $2, 'control_total', NULL, NULL)`, [orgAId, ordGond.id]),
    /SIN_PLANTILLA/
  );

  // Obs. 2: p_plantilla en borrador o archivada debe fallar con PLANTILLA_NO_ENCONTRADA
  const { rows: [borrPlat] } = await pool.query(
    `SELECT nueva_version_plantilla($1, $2) AS id`,
    [orgAId, platCt.id]
  );
  await assert.rejects(
    () => pool.query(`SELECT crear_inspeccion_calidad($1, $2, 'control_total', $3, NULL)`, [orgAId, ordPlat.id, borrPlat.id]),
    /PLANTILLA_NO_ENCONTRADA/
  );
  // v2Id quedó archivada al restaurar platCt.id
  await assert.rejects(
    () => pool.query(`SELECT crear_inspeccion_calidad($1, $2, 'control_total', $3, NULL)`, [orgAId, ordPlat.id, v2Id]),
    /PLANTILLA_NO_ENCONTRADA/
  );
  await pool.query('SELECT eliminar_plantilla_borrador($1, $2)', [orgAId, borrPlat.id]);

  const { rows: [insp1Row] } = await pool.query(
    `SELECT crear_inspeccion_calidad($1, $2, 'entrega', NULL, NULL) AS id`,
    [orgAId, ordPlat.id]
  );
  const insp1Id = insp1Row.id;
  const { rows: [insp1Data] } = await pool.query(
    'SELECT folio, intento, plantilla_id, evaluado_por FROM orden_calidad_inspecciones WHERE id = $1',
    [insp1Id]
  );
  assert.equal(insp1Data.folio, 'CE-000001');
  assert.equal(insp1Data.intento, 1);
  assert.equal(insp1Data.evaluado_por, null);

  await assert.rejects(
    () => pool.query(`SELECT crear_inspeccion_calidad($1, $2, 'entrega', NULL, NULL)`, [orgAId, ordPlat.id]),
    /YA_EXISTE/
  );
  console.log('   OK: borrador/archivada rechazados, evaluado_por = NULL, folios y YA_EXISTE.');

  console.log('4. Verificando unidad fuera de rango (UNIDAD_INVALIDA), lote y resumen 2 unidades (57x2=114)...');
  const { rows: itemsPlatEnt } = await pool.query(
    'SELECT id FROM calidad_plantilla_items WHERE plantilla_id = $1 ORDER BY numero LIMIT 3',
    [insp1Data.plantilla_id]
  );

  // Obs. 1: unidad 3 en plantilla de 2 unidades y unidad 0 deben lanzar UNIDAD_INVALIDA
  await assert.rejects(
    () => pool.query(
      `SELECT guardar_resultados_calidad($1, $2, $3::jsonb, NULL)`,
      [orgAId, insp1Id, JSON.stringify([{ item_id: itemsPlatEnt[0].id, unidad: 3, resultado: 'conforme' }])]
    ),
    /UNIDAD_INVALIDA/
  );
  await assert.rejects(
    () => pool.query(
      `SELECT guardar_resultados_calidad($1, $2, $3::jsonb, NULL)`,
      [orgAId, insp1Id, JSON.stringify([{ item_id: itemsPlatEnt[0].id, unidad: 0, resultado: 'conforme' }])]
    ),
    /UNIDAD_INVALIDA/
  );

  await pool.query(
    `SELECT guardar_resultados_calidad($1, $2, $3::jsonb, NULL)`,
    [
      orgAId,
      insp1Id,
      JSON.stringify([
        { item_id: itemsPlatEnt[0].id, unidad: 1, resultado: 'conforme', colaborador: 'Juan' },
        { item_id: itemsPlatEnt[0].id, unidad: 2, resultado: 'no_conforme', colaborador: 'Juan', observaciones: 'Detalle soldadura' },
        { item_id: itemsPlatEnt[1].id, unidad: 1, resultado: 'no_aplica' },
      ]),
    ]
  );
  await pool.query(
    `SELECT guardar_resultados_calidad($1, $2, $3::jsonb, NULL)`,
    [orgAId, insp1Id, JSON.stringify([{ item_id: itemsPlatEnt[1].id, unidad: 1, resultado: null }])]
  );

  const { rows: [resumen1] } = await pool.query(
    `SELECT * FROM resumen_calidad_ordenes($1) WHERE inspeccion_id = $2`,
    [orgAId, insp1Id]
  );
  assert.equal(resumen1.total_esperados, 114);
  assert.equal(resumen1.capturados, 2);
  assert.equal(resumen1.conformes, 1);
  assert.equal(resumen1.no_conformes, 1);
  assert.equal(resumen1.pendientes, 112);
  console.log('   OK: UNIDAD_INVALIDA en unidad 0 y 3; resumen = 114 esperados, 2 capturados.');

  console.log('5. Verificando Cama baja (tipo_equipo = 05 asignado a línea plataforma)...');
  const { rows: [ordCamaBaja] } = await pool.query(
    `INSERT INTO ordenes_trabajo (organizacion_id, linea_producto_id, nomenclatura_id, etiqueta, modelo, tipo_equipo, estado, origen)
     VALUES ($1, $2, 'NOM-CAL-CB', 'EQ-CAL-CB', 'Cama baja 3 ejes', '05', 'En Producción', 'manual') RETURNING id`,
    [orgAId, lineaPlat.id]
  );
  const { rows: [inspCbEnt] } = await pool.query(
    `SELECT crear_inspeccion_calidad($1, $2, 'entrega', NULL, NULL) AS id`,
    [orgAId, ordCamaBaja.id]
  );
  const { rows: [cbPl] } = await pool.query(
    `SELECT lp.clave AS linea_clave, cp.nombre
     FROM orden_calidad_inspecciones oci
     JOIN calidad_plantillas cp ON cp.id = oci.plantilla_id
     JOIN lineas_producto lp ON lp.id = cp.linea_producto_id
     WHERE oci.id = $1`,
    [inspCbEnt.id]
  );
  assert.equal(cbPl.linea_clave, 'cama_baja');

  // En control_total no existe plantilla para cama_baja → cae a plataforma
  const { rows: [inspCbCt] } = await pool.query(
    `SELECT crear_inspeccion_calidad($1, $2, 'control_total', NULL, NULL) AS id`,
    [orgAId, ordCamaBaja.id]
  );
  const { rows: [cbCtPl] } = await pool.query(
    `SELECT lp.clave AS linea_clave
     FROM orden_calidad_inspecciones oci
     JOIN calidad_plantillas cp ON cp.id = oci.plantilla_id
     JOIN lineas_producto lp ON lp.id = cp.linea_producto_id
     WHERE oci.id = $1`,
    [inspCbCt.id]
  );
  assert.equal(cbCtPl.linea_clave, 'plataforma');
  console.log('   OK: tipo_equipo 05 recibe plantilla cama_baja en entrega y cae a plataforma en control_total.');

  console.log('6. Verificando cerrar_inspeccion_calidad con bloquea_liberacion=false y true...');
  const { rows: [cerrRes] } = await pool.query(
    `SELECT cerrar_inspeccion_calidad($1, $2, 'Inspector 1', NULL, NULL) AS res`,
    [orgAId, insp1Id]
  );
  assert.equal(cerrRes.res.estado, 'cerrada');
  assert.equal(cerrRes.res.advertencias.no_conformes, 1);
  assert.equal(cerrRes.res.advertencias.pendientes, 112);

  await assert.rejects(
    () => pool.query(`SELECT guardar_resultados_calidad($1, $2, '[]'::jsonb, NULL)`, [orgAId, insp1Id]),
    /INSPECCION_CERRADA/
  );

  const { rows: [platEntAct] } = await pool.query(
    `SELECT plantilla_id FROM orden_calidad_inspecciones WHERE id = $1`,
    [insp1Id]
  );
  const { rows: [insp2Row] } = await pool.query(
    `SELECT crear_inspeccion_calidad($1, $2, 'entrega', NULL, NULL) AS id`,
    [orgAId, ordPlat.id]
  );
  const { rows: [insp2Data] } = await pool.query(
    'SELECT folio, intento FROM orden_calidad_inspecciones WHERE id = $1',
    [insp2Row.id]
  );
  assert.equal(insp2Data.folio, 'CE-000003');
  assert.equal(insp2Data.intento, 2);

  const { rows: [vEnt2] } = await pool.query('SELECT nueva_version_plantilla($1, $2) AS id', [orgAId, platEntAct.plantilla_id]);
  await pool.query(
    `UPDATE calidad_plantillas SET config = jsonb_set(config, '{bloquea_liberacion}', 'true'::jsonb) WHERE id = $1`,
    [vEnt2.id]
  );
  await pool.query('SELECT publicar_plantilla($1, $2)', [orgAId, vEnt2.id]);
  const { rows: [insp1After] } = await pool.query('SELECT plantilla_id FROM orden_calidad_inspecciones WHERE id = $1', [insp1Id]);
  assert.equal(insp1After.plantilla_id, platEntAct.plantilla_id);

  const { rows: [ordPlat2] } = await pool.query(
    `INSERT INTO ordenes_trabajo (organizacion_id, linea_producto_id, nomenclatura_id, etiqueta, modelo, estado, origen)
     VALUES ($1, $2, 'NOM-CAL-PLAT-2', 'EQ-CAL-PLAT-2', 'Plataforma 40 ft', 'En Producción', 'manual') RETURNING id`,
    [orgAId, lineaPlat.id]
  );
  const { rows: [inspBloq] } = await pool.query(
    `SELECT crear_inspeccion_calidad($1, $2, 'entrega', NULL, NULL) AS id`,
    [orgAId, ordPlat2.id]
  );
  const { rows: [itemV2] } = await pool.query(
    'SELECT id FROM calidad_plantilla_items WHERE plantilla_id = $1 LIMIT 1',
    [vEnt2.id]
  );
  await pool.query(
    `SELECT guardar_resultados_calidad($1, $2, $3::jsonb, NULL)`,
    [orgAId, inspBloq.id, JSON.stringify([{ item_id: itemV2.id, unidad: 1, resultado: 'no_conforme' }])]
  );
  await assert.rejects(
    () => pool.query(`SELECT cerrar_inspeccion_calidad($1, $2, 'Sup', NULL, NULL)`, [orgAId, inspBloq.id]),
    /BLOQUEADA_POR_NO_CONFORMES/
  );
  await pool.query('SELECT publicar_plantilla($1, $2)', [orgAId, platEntAct.plantilla_id]);
  console.log('   OK: bloquea_liberacion=false avisa, true bloquea, e inspecciones viejas conservan su plantilla.');

  console.log('7. Verificando aislamiento entre organizaciones y permisos authenticated...');
  await assert.rejects(
    () => pool.query('SELECT publicar_plantilla($1, $2)', [orgBId, platCt.id]),
    /PLANTILLA_NO_ENCONTRADA/
  );
  await assert.rejects(
    () => pool.query(`SELECT crear_inspeccion_calidad($1, $2, 'entrega', NULL, NULL)`, [orgBId, ordPlat.id]),
    /ORDEN_NO_ENCONTRADA/
  );
  const clientAuth = await pool.connect();
  try {
    await clientAuth.query('SET ROLE authenticated');
    await assert.rejects(
      () => clientAuth.query('SELECT sembrar_calidad_plantillas($1)', [orgAId]),
      /permission denied/
    );
  } finally {
    await clientAuth.query('RESET ROLE');
    clientAuth.release();
  }
  console.log('   OK: aislamiento entre organizaciones y REVOKE a authenticated.');

  console.log('8. Verificando CONCURRENCIA REAL contra Postgres (dos conexiones simultáneas)...');
  const { rows: [ordConc] } = await pool.query(
    `INSERT INTO ordenes_trabajo (organizacion_id, linea_producto_id, nomenclatura_id, etiqueta, modelo, estado, origen)
     VALUES ($1, $2, 'NOM-CAL-CONC', 'EQ-CAL-CONC', 'Plataforma 40 ft', 'En Producción', 'manual') RETURNING id`,
    [orgAId, lineaPlat.id]
  );
  const c1 = await pool.connect();
  const c2 = await pool.connect();
  try {
    const resConc = await Promise.allSettled([
      c1.query(`SELECT crear_inspeccion_calidad($1, $2, 'entrega', NULL, NULL)`, [orgAId, ordConc.id]),
      c2.query(`SELECT crear_inspeccion_calidad($1, $2, 'entrega', NULL, NULL)`, [orgAId, ordConc.id]),
    ]);
    assert.equal(resConc.filter((r) => r.status === 'fulfilled').length, 1);
    assert.equal(resConc.filter((r) => r.status === 'rejected').length, 1);
    assert.match(resConc.find((r) => r.status === 'rejected').reason.message, /YA_EXISTE/);

    const { rows: [d1] } = await pool.query('SELECT nueva_version_plantilla($1, $2) AS id', [orgAId, platCt.id]);
    const { rows: [d2] } = await pool.query('SELECT nueva_version_plantilla($1, $2) AS id', [orgAId, platCt.id]);
    const resPub = await Promise.allSettled([
      c1.query('SELECT publicar_plantilla($1, $2)', [orgAId, d1.id]),
      c2.query('SELECT publicar_plantilla($1, $2)', [orgAId, d2.id]),
    ]);
    assert.equal(resPub.filter((r) => r.status === 'fulfilled').length, 2);
    const { rows: [{ cnt: cntActivas }] } = await pool.query(
      `SELECT COUNT(*)::int AS cnt FROM calidad_plantillas WHERE organizacion_id = $1 AND linea_producto_id = $2 AND formato = 'control_total' AND estado = 'activa'`,
      [orgAId, lineaPlat.id]
    );
    assert.equal(cntActivas, 1);
    await pool.query('SELECT publicar_plantilla($1, $2)', [orgAId, platCt.id]);
  } finally {
    c1.release();
    c2.release();
  }
  console.log('   OK: concurrencia real en crear_inspeccion y publicar_plantilla.');

  console.log('9. Prueba de mutación propia (romper unicidad y verificar detección)...');
  const verifierSql = fs.readFileSync(path.join(__dirname, 'verificar_calidad.sql'), 'utf8');
  const mutClient = await pool.connect();
  try {
    await mutClient.query('BEGIN');
    await mutClient.query('DROP INDEX uq_calidad_plantilla_activa');
    await mutClient.query(`UPDATE calidad_plantillas SET estado = 'activa' WHERE id = $1`, [v2Id]);
    const { rows: [verMut] } = await mutClient.query(verifierSql);
    assert.equal(verMut.una_activa_por_linea_fmt_ok, false);
    assert.equal(verMut.todo_ok, false);
    await mutClient.query('ROLLBACK');
  } finally {
    mutClient.release();
  }
  console.log('   OK: mutación detectada (una_activa_por_linea_fmt_ok = false, todo_ok = false).');

  await pool.end();
  console.log('\nTODAS LAS PRUEBAS POSTGRES DE CALIDAD C1 PASARON (9/9).');
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
