# Contrato de API — Tablero de Producción (Matriz de Fases)

Documento de especificación de interfaz y contrato HTTP para el Tablero de Producción (Bloque 1 de 2: Datos y Backend). Este contrato define la forma exacta de los endpoints utilizados por el frontend en el Bloque 2.

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

### Ejemplo de Respuesta JSON (`200 OK`)

```json
{
  "linea": {
    "id": "48001731-f676-4428-8d06-75e388be197b",
    "clave": "plataforma",
    "nombre": "Plataforma"
  },
  "fases": [
    {
      "id": "60a1d604-bb27-4a6c-942f-87e3be9df301",
      "orden": 1,
      "nombre": "Corte",
      "grupo": "principal",
      "requiere_grupo": null,
      "duracion_dias": 2
    },
    {
      "id": "70b2e705-cc38-5b7d-053e-98f4cf0ef402",
      "orden": 2,
      "nombre": "Dispositivo",
      "grupo": "principal",
      "requiere_grupo": null,
      "duracion_dias": 2
    },
    {
      "id": "80c3f806-dd49-6c8e-164f-09a5d01fa503",
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
      "etiqueta": "Transportes Azteca #1",
      "cliente_nombre": "Transportes Azteca S.A. de C.V.",
      "cotizacion_folio": "COT-2026-0045",
      "modelo": "PLATAFORMA 3 EJES 40 FT",
      "tipo_equipo": "01",
      "origen": "cotizacion",
      "fecha_compromiso": "2026-12-15",
      "fecha_inicio": "2026-11-10T14:30:00Z",
      "material_faltante": "2 perchas traseras",
      "estado": "En Producción",
      "estado_kanban": "incompleta",
      "semaforo": "detenido",
      "avance": {
        "terminadas": 1,
        "total": 12
      },
      "tina": null,
      "celdas": {
        "60a1d604-bb27-4a6c-942f-87e3be9df301": {
          "estado": "terminada",
          "fecha_propuesta": null,
          "fecha_fin": "2026-11-11T16:00:00Z",
          "nota": null
        },
        "70b2e705-cc38-5b7d-053e-98f4cf0ef402": {
          "estado": "incompleta",
          "fecha_propuesta": "2026-11-14",
          "fecha_fin": null,
          "nota": "Falta placa de acero 3/8"
        },
        "80c3f806-dd49-6c8e-164f-09a5d01fa503": {
          "estado": "pendiente",
          "fecha_propuesta": null,
          "fecha_fin": null,
          "nota": null
        }
      }
    }
  ],
  "resumen": {
    "en_planta": 1,
    "atrasados": 0,
    "con_material": 1,
    "con_pausa": 0,
    "wip_por_fase": {
      "60a1d604-bb27-4a6c-942f-87e3be9df301": 0,
      "70b2e705-cc38-5b7d-053e-98f4cf0ef402": 0,
      "80c3f806-dd49-6c8e-164f-09a5d01fa503": 0
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
  - `201 Created`: Orden creada exitosamente con sus fases vinculadas.
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

### Ejemplo de Respuesta JSON (`201 Created`)

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
    "linea_producto_id": "48001731-f676-4428-8d06-75e388be197b",
    "tipo_equipo": "01",
    "modelo": "Plataforma 40 ft 2 ejes",
    "nomenclatura_id": "104-INV011126-1",
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
    "created_at": "2026-11-12T17:45:00.000Z"
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
  - `fecha_propuesta`: `'YYYY-MM-DD'` (opcional).
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

### Ejemplo de Respuesta JSON (`200 OK`)

```json
{
  "ok": true,
  "celda": {
    "fase_id": "60a1d604-bb27-4a6c-942f-87e3be9df301",
    "estado": "en_proceso",
    "fecha_propuesta": "2026-11-16",
    "fecha_inicio": "2026-11-12T17:48:00.000Z",
    "fecha_fin": null,
    "nota": "Iniciando corte de solera"
  },
  "orden": {
    "id": "e6a1005a-f10e-436f-b258-005691ea4512",
    "estado": "En Producción",
    "estado_kanban": "en_proceso",
    "fase_actual_id": "60a1d604-bb27-4a6c-942f-87e3be9df301",
    "fecha_inicio": "2026-11-12T17:48:00.000Z",
    "fecha_fin": null
  },
  "avisos": []
}
```

*Nota para subprocesos*: Si una fase con `requiere_grupo = 'tina'` se marca como terminada pero la tina no está al 100%, la respuesta incluye el aviso:
`"avisos": ["La tina va 8/10"]`.

---

## 4. `PUT /produccion/ordenes/:id/planeacion`

Actualiza campos de planeación con **lista blanca estricta**: solo permite `fecha_compromiso`, `etiqueta` y `material_faltante`. No modifica `estado_kanban`.

- **Método**: `PUT`
- **Body**: `application/json`
- **Códigos de respuesta**:
  - `200 OK`: Éxito.
  - `400 Bad Request`: Si se envían campos no permitidos (ej. `estado_kanban`, `estado`).
  - `404 Not Found`: Orden no encontrada.

### Ejemplo de Petición JSON

```json
{
  "fecha_compromiso": "2026-12-18",
  "etiqueta": "Plana Urgente Cliente A",
  "material_faltante": "Faltan 4 rines Unimount"
}
```

### Ejemplo de Respuesta JSON (`200 OK`)

```json
{
  "ok": true,
  "orden": {
    "id": "e6a1005a-f10e-436f-b258-005691ea4512",
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
    "orden": { ... }
  }
  ```

---

## 6. `GET /produccion/ordenes/:id/historial`

Consulta la bitácora de cambios de fases para una orden de trabajo, ordenada de más reciente a más antiguo.

- **Método**: `GET`
- **Códigos de respuesta**:
  - `200 OK`: Éxito.
  - `404 Not Found`: Orden no encontrada.

### Ejemplo de Respuesta JSON (`200 OK`)

```json
{
  "ok": true,
  "historial": [
    {
      "id": "b3e0c0a1-4321-4def-9876-000000000001",
      "fase_id": "60a1d604-bb27-4a6c-942f-87e3be9df301",
      "fase_nombre": "Corte",
      "fase_grupo": "principal",
      "fase_orden": 1,
      "estado_anterior": "pendiente",
      "estado_nuevo": "en_proceso",
      "fecha_propuesta": "2026-11-16",
      "nota": "Iniciando corte de solera",
      "usuario": "Luis Alarcón",
      "usuario_id": "98a12345-6789-4abc-def0-123456789abc",
      "created_at": "2026-11-12T17:48:00.000Z"
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
    "fase_actual_id": "70b2e705-cc38-5b7d-053e-98f4cf0ef402"
  }
  ```
- **Códigos de respuesta**:
  - `200 OK`: Éxito.
  - `400 Bad Request`: Si `fase_actual_id` es `"pendientes"` o `"pendiente"`.

---

## 8. `POST /produccion/sembrar`

Siembra o repara las 4 líneas (`plataforma`, `gondola`, `dolly`, `traila`) y las 55 fases canónicas para la organización del usuario autenticado. Es idempotente y no sobreescribe duraciones editadas previamente.

- **Método**: `POST`
- **Permisos**: Requiere rol `admin` o `propietario`.
- **Códigos de respuesta**:
  - `200 OK`: Semilla ejecutada.
  - `403 Forbidden`: Si el usuario no tiene rol administrativo.

### Ejemplo de Respuesta JSON (`200 OK`)

```json
{
  "ok": true,
  "resultado": {
    "lineas": 4,
    "fases": 55
  }
}
```
