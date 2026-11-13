# Contrato de API — Tablero de Producción (Matriz de Fases)

Documento de especificación de interfaz y contrato HTTP para el Tablero de Producción (Bloque 1 de 2: Datos y Backend). Este contrato define la forma exacta de los endpoints utilizados por el frontend en el Bloque 2, con ejemplos extraídos directamente de la base de datos PostgreSQL real.

---

## 1. `GET /produccion/matriz?linea=<clave>`

Obtiene la matriz completa de producción para una línea determinada (`plataforma`, `gondola`, `dolly`, `traila`). Excluye equipos en estado `Liberado`.

- **Método**: `GET`
- **Query Params**:
  - `linea`: `string` (opcional, valor por defecto: `'plataforma'`).
- **Autenticación**: Header `Authorization: Bearer <token>`.
- **Códigos de respuesta**:
  - `200 OK`: Éxito.
  - `404 Not Found`: Línea de producto no encontrada.

### Resolución de campos del cliente y etiqueta
- `cliente_nombre`: Se extrae de `clientes.nombre_razon_social` (con respaldo en `nombre_contacto`). Si la orden es manual sin cliente, toma la `etiqueta` asignada; si no tiene etiqueta, muestra `"Inventario"`.
- `etiqueta`: Se calcula mediante la función pura `calcularEtiquetaVisible`. Si un cliente tiene múltiples órdenes en la línea (incluidas las que ya fueron `Liberado`), numera secuencialmente `"Cliente #1"`, `"Cliente #2"`, etc. por fecha de creación (`created_at`).

### Ejemplo de Respuesta JSON Real (`200 OK`)

```json
{
  "linea": {
    "id": "0dde45b1-cfd1-4b15-87b5-ed5ea229f9c0",
    "clave": "plataforma",
    "nombre": "Plataforma"
  },
  "fases": [
    {
      "id": "c71d9ab7-4a2e-46ce-a5bc-79296965b2b7",
      "orden": 1,
      "nombre": "Corte",
      "grupo": "principal",
      "requiere_grupo": null,
      "duracion_dias": 2
    },
    {
      "id": "5a711e23-af3b-4d66-bbe6-3b014fa5df0a",
      "orden": 2,
      "nombre": "Dispositivo",
      "grupo": "principal",
      "requiere_grupo": null,
      "duracion_dias": 2
    },
    {
      "id": "0edeca4e-973b-4b7c-83d0-c9f2e0e912a7",
      "orden": 3,
      "nombre": "Armado de baras",
      "grupo": "principal",
      "requiere_grupo": null,
      "duracion_dias": 2
    }
  ],
  "filas": [
    {
      "orden_id": "27c73db7-9c66-485e-9b64-6342d7e043de",
      "etiqueta": "Transportes del Norte S.A.",
      "cliente_nombre": "Transportes del Norte S.A.",
      "cotizacion_folio": "COT-2026-0001",
      "modelo": "Plataforma 40FT",
      "tipo_equipo": "Plataforma 40FT",
      "origen": "cotizacion",
      "fecha_compromiso": null,
      "fecha_inicio": "2026-11-13T00:27:00.245Z",
      "material_faltante": null,
      "estado": "En Producción",
      "estado_kanban": "en_proceso",
      "semaforo": "en_tiempo",
      "avance": {
        "terminadas": 1,
        "total": 12
      },
      "tina": null,
      "celdas": {
        "c71d9ab7-4a2e-46ce-a5bc-79296965b2b7": {
          "estado": "terminada",
          "fecha_propuesta": "2026-11-14",
          "fecha_fin": "2026-11-13T00:35:21.160Z",
          "nota": "Corte concluido"
        },
        "5a711e23-af3b-4d66-bbe6-3b014fa5df0a": {
          "estado": "pendiente",
          "fecha_propuesta": null,
          "fecha_fin": null,
          "nota": null
        }
      }
    }
  ],
  "resumen": {
    "en_planta": 2,
    "atrasados": 0,
    "con_material": 0,
    "con_pausa": 0,
    "wip_por_fase": {
      "c71d9ab7-4a2e-46ce-a5bc-79296965b2b7": 1,
      "5a711e23-af3b-4d66-bbe6-3b014fa5df0a": 0
    }
  }
}
```

*Nota para Góndola*: En góndolas, `tina` es un objeto `{ "terminadas": n, "total": 10 }` en vez de `null`.

---

## 2. `POST /produccion/ordenes`

Crea una orden de trabajo manual ("Nuevo equipo en planta") sin requerir cotización previa. Exige `cliente_id` o `etiqueta`.

- **Método**: `POST`
- **Body**: `application/json`
- **Códigos de respuesta**:
  - `201 Created`: Orden creada exitosamente con sus 10, 11, 12 o 22 fases vinculadas.
  - `400 Bad Request`: Si falta tanto `cliente_id` como `etiqueta`, o datos inválidos.

### Ejemplo de Petición JSON

```json
{
  "linea": "plataforma",
  "tipo_equipo": "01",
  "modelo": "Plataforma 40 ft 2 ejes",
  "etiqueta": "Plana Stock Noviembre",
  "fecha_compromiso": "2026-12-20",
  "caracteristicas": {
    "observaciones": "Equipo para piso de venta"
  }
}
```

### Ejemplo de Respuesta JSON Real (`201 Created`)

```json
{
  "ok": true,
  "orden": {
    "id": "e6a1005a-f10e-436f-b258-005691ea4512",
    "organizacion_id": "00000000-0000-0000-0000-000000000001",
    "cotizacion_id": null,
    "cliente_id": null,
    "etiqueta": "Plana Stock Noviembre",
    "origen": "manual",
    "linea_producto_id": "0dde45b1-cfd1-4b15-87b5-ed5ea229f9c0",
    "tipo_equipo": "01",
    "modelo": "Plataforma 40 ft 2 ejes",
    "nomenclatura_id": "43-INV011126-1",
    "fecha_compromiso": "2026-12-20",
    "fecha_inicio": null,
    "fecha_fin": null,
    "material_faltante": null,
    "estado": "Pendiente",
    "estado_kanban": "pendiente",
    "fase_actual_id": null,
    "caracteristicas": {
      "observaciones": "Equipo para piso de venta"
    },
    "created_at": "2026-11-13T00:30:00.000Z"
  }
}
```

---

## 3. `PUT /produccion/ordenes/:id/fases/:faseId`

Actualiza el estado de una fase para una orden específica ejecutando la función PostgreSQL `actualizar_fase_orden`.

- **Método**: `PUT`
- **Path Params**:
  - `id`: UUID de la orden de trabajo.
  - `faseId`: UUID de la fase de producción.
- **Body**: `application/json`
  - `estado`: `'pendiente' | 'en_proceso' | 'incompleta' | 'pausada' | 'terminada'` (requerido).
  - `fecha_propuesta`: `'YYYY-MM-DD'` (opcional; si se reabre una fase terminada o se pasa a `en_proceso` sin fecha, se calcula automáticamente como `hoy + duracion_dias`).
  - `nota`: `string` (opcional).
- **Códigos de respuesta**:
  - `200 OK`: Fase actualizada y derivados de orden recalculados.
  - `400 Bad Request`: Estado inválido.
  - `404 Not Found`: Orden o fase no encontrada.
  - `409 Conflict`: La fase no pertenece a la línea de la orden.

### Ejemplo de Petición JSON

```json
{
  "estado": "en_proceso",
  "fecha_propuesta": "2026-11-16",
  "nota": "Iniciando corte de solera"
}
```

### Ejemplo de Respuesta JSON Real (`200 OK`)

```json
{
  "ok": true,
  "fase": {
    "id": "e7d3dba6-e465-44a8-a510-2a0972747364",
    "orden_trabajo_id": "27c73db7-9c66-485e-9b64-6342d7e043de",
    "fase_id": "c71d9ab7-4a2e-46ce-a5bc-79296965b2b7",
    "estado": "terminada",
    "fecha_propuesta": "2026-11-14",
    "fecha_inicio": "2026-11-13T00:27:00.245Z",
    "fecha_fin": "2026-11-13T00:35:21.160Z",
    "nota": "Corte concluido",
    "actualizado_por": "00000000-0000-0000-0000-000000000001",
    "created_at": "2026-11-13T00:27:00.245Z",
    "updated_at": "2026-11-13T00:35:21.160Z"
  },
  "orden": {
    "id": "27c73db7-9c66-485e-9b64-6342d7e043de",
    "estado": "En Producción",
    "estado_kanban": "pendiente",
    "fase_actual_id": null,
    "fecha_inicio": "2026-11-13T00:27:00.245Z",
    "fecha_fin": null
  },
  "avisos": []
}
```

*Nota para subprocesos*: Si una fase con `requiere_grupo = 'tina'` se marca como terminada pero la tina no está al 100%, la respuesta incluye el aviso:
`"avisos": ["La tina va 8/10"]`.

---

## 4. `PUT /produccion/ordenes/:id/planeacion`

Actualiza campos de planeación con **lista blanca estricta**: solo permite `fecha_compromiso`, `etiqueta` y `material_faltante`. No modifica `estado_kanban` ni `fase_actual_id`.

- **Método**: `PUT`
- **Body**: `application/json`
- **Códigos de respuesta**:
  - `200 OK`: Éxito.
  - `400 Bad Request`: Si se envían campos no permitidos (ej. `estado_kanban`, `estado`, `fase_actual_id`).
  - `404 Not Found`: Orden no encontrada.

### Ejemplo de Petición JSON

```json
{
  "fecha_compromiso": "2026-12-18",
  "etiqueta": "Plana Urgente Cliente A",
  "material_faltante": "Faltan 4 rines Unimount"
}
```

### Ejemplo de Respuesta JSON Real (`200 OK`)

```json
{
  "ok": true,
  "orden": {
    "id": "27c73db7-9c66-485e-9b64-6342d7e043de",
    "fecha_compromiso": "2026-12-18",
    "etiqueta": "Plana Urgente Cliente A",
    "material_faltante": "Faltan 4 rines Unimount"
  }
}
```

---

## 5. `PUT /produccion/ordenes/:id/material` (Alias)

Alias retrocompatible que actualiza exclusivamente `material_faltante` utilizando la misma lógica de `actualizarPlaneacionMotor`.

- **Método**: `PUT`
- **Body**:
  ```json
  {
    "material_faltante": "Falta pintura epóxica"
  }
  ```
- **Respuesta**:
  ```json
  {
    "success": true,
    "orden": { "id": "...", "material_faltante": "Falta pintura epóxica" }
  }
  ```

---

## 6. `GET /produccion/ordenes/:id/historial`

Consulta la bitácora de cambios de fases para una orden de trabajo, ordenada de más reciente a más antiguo por `fecha_cambio`.

- **Método**: `GET`
- **Códigos de respuesta**:
  - `200 OK`: Éxito.
  - `404 Not Found`: Orden no encontrada.

### Resolución de campos en el historial
- `fecha_cambio`: Timestamp real de la columna `historial_fases.fecha_cambio`.
- `created_at`: Alias retrocompatible devuelto con el mismo valor de `fecha_cambio`.
- `usuario_id`: UUID del usuario autenticado que ejecutó la acción (o `null`).
- `usuario`: Retorna el `usuario_id` como texto o `"Sistema"` si es nulo, dado que en la arquitectura actual `perfiles_organizacion` no almacena nombres propios de usuario.

### Ejemplo de Respuesta JSON Real (`200 OK`)

```json
{
  "ok": true,
  "historial": [
    {
      "id": "5e3f3351-a509-42da-93e1-6ae680cbb256",
      "fase_id": "c71d9ab7-4a2e-46ce-a5bc-79296965b2b7",
      "fase_nombre": "Corte",
      "fase_grupo": "principal",
      "fase_orden": 1,
      "estado_anterior": "en_proceso",
      "estado_nuevo": "terminada",
      "fecha_propuesta": "2026-11-14",
      "nota": "Corte concluido",
      "usuario": "00000000-0000-0000-0000-000000000001",
      "usuario_id": "00000000-0000-0000-0000-000000000001",
      "fecha_cambio": "2026-11-13T00:35:21.160Z",
      "created_at": "2026-11-13T00:35:21.160Z"
    }
  ]
}
```

---

## 7. `PUT /produccion/ordenes/:id/mover`

Compatibilidad con el Kanban actual: mueve la orden pasando la fase destino a `en_proceso`. Rechaza mover a `pendientes`.

- **Método**: `PUT`
- **Body**:
  ```json
  {
    "fase_actual_id": "5a711e23-af3b-4d66-bbe6-3b014fa5df0a"
  }
  ```
- **Códigos de respuesta**:
  - `200 OK`: Éxito.
  - `400 Bad Request`: Si `fase_actual_id` es `"pendientes"` o `"pendiente"`.

---

## 8. `POST /produccion/sembrar`

Siembra o repara las 4 líneas (`plataforma`, `gondola`, `dolly`, `traila`) y las 55 fases canónicas para la organización del usuario autenticado. Es idempotente y no sobreescribe duraciones editadas previamente ni reactiva fases desactivadas manualmente por administradores.

- **Método**: `POST`
- **Permisos**: Requiere rol `admin` o `propietario`.
- **Códigos de respuesta**:
  - `200 OK`: Semilla ejecutada.
  - `403 Forbidden`: Si el usuario no tiene rol administrativo.

### Ejemplo de Respuesta JSON Real (`200 OK`)

```json
{
  "ok": true,
  "resultado": {
    "lineas": 4,
    "fases": 55
  }
}
```
