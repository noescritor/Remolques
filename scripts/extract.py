import sys, json, openpyxl

def status_from_text(txt):
    if txt is None:
        return None
    t = str(txt).strip().upper()
    if t.startswith("PROCESO"):
        return "en_proceso"
    if t.startswith("PAUSA"):
        return "pausada"
    if t.startswith("INCOMPLETO"):
        return "incompleta"
    if t.startswith("ESPERA"):
        return "en_espera"
    if t.startswith('"COMPLET') or t.startswith("COMPLET"):
        return "completada"
    return "pendiente"


def extract_sheet(ws, header_row, first_data_row, last_data_row, client_col=1,
                   fecha_ini_col=None, fecha_fin_col=None, phase_cols=None, extra_col=None):
    phase_cols = [c for c in phase_cols if ws.cell(row=header_row, column=c).value not in (None, "")]
    headers = {c: str(ws.cell(row=header_row, column=c).value).strip() for c in phase_cols}

    orders = []
    for r in range(first_data_row, last_data_row + 1):
        cliente = ws.cell(row=r, column=client_col).value
        if cliente is None or str(cliente).strip() == "":
            continue
        cliente = str(cliente).strip()

        fecha_ini = ws.cell(row=r, column=fecha_ini_col).value if fecha_ini_col else None
        fecha_fin = ws.cell(row=r, column=fecha_fin_col).value if fecha_fin_col else None

        fase_actual = None
        fase_idx = None
        estado_texto = None
        estado = None
        
        for i, c in enumerate(phase_cols):
            cell = ws.cell(row=r, column=c)
            if cell.value is not None and str(cell.value).strip() != "":
                fase_actual = headers[c]
                fase_idx = i
                estado_texto = str(cell.value).strip()
                estado = status_from_text(cell.value)
                break

        material = None
        if extra_col:
            v = ws.cell(row=r, column=extra_col).value
            if v is not None and str(v).strip() not in ("", " "):
                material = str(v).strip()

        orders.append({
            "cliente": cliente,
            "fecha_inicio": str(fecha_ini) if fecha_ini else None,
            "fecha_fin_estimada": str(fecha_fin) if fecha_fin else None,
            "fase_actual": fase_actual,
            "fase_actual_idx": fase_idx,
            "total_fases": len(phase_cols),
            "estado": estado,
            "estado_texto": estado_texto,
            "material_faltante": material,
        })
    return {"fases": [headers[c] for c in phase_cols], "ordenes": orders}


def extract_file(path):
    wb = openpyxl.load_workbook(path, data_only=True)
    data = {"_fecha_interna": str(wb["PLATAFORMA"]["C3"].value or "")}

    ws = wb["PLATAFORMA"]
    data["PLATAFORMA"] = extract_sheet(
        ws, header_row=7, first_data_row=8, last_data_row=ws.max_row,
        client_col=1, fecha_ini_col=2, fecha_fin_col=3,
        phase_cols=list(range(4, 16)), extra_col=16)

    ws = wb["GONDOLA"]
    split_row = next((r for r in range(8, ws.max_row + 1)
                       if ws.cell(row=r, column=1).value
                       and "ENSAMBLE DE TINA" in str(ws.cell(row=r, column=1).value).upper()), None)
    chasis_last = split_row - 2 if split_row else ws.max_row
    data["GONDOLA_CHASIS"] = extract_sheet(
        ws, header_row=7, first_data_row=8, last_data_row=chasis_last,
        client_col=1, fecha_ini_col=2, fecha_fin_col=3,
        phase_cols=list(range(4, 16)), extra_col=16)
    if split_row:
        th = split_row + 1
        data["GONDOLA_TINA"] = extract_sheet(
            ws, header_row=th, first_data_row=th + 2, last_data_row=ws.max_row,
            client_col=1, phase_cols=list(range(2, 15)), extra_col=15)
    else:
        data["GONDOLA_TINA"] = {"fases": [], "ordenes": []}

    ws = wb["DOLLY"]
    data["DOLLY"] = extract_sheet(
        ws, header_row=7, first_data_row=8, last_data_row=ws.max_row,
        client_col=1, fecha_ini_col=2, fecha_fin_col=3,
        phase_cols=list(range(4, 14)), extra_col=14)

    ws = wb["TRAILA"]
    data["TRAILA"] = extract_sheet(
        ws, header_row=7, first_data_row=8, last_data_row=ws.max_row,
        client_col=1, fecha_ini_col=2, fecha_fin_col=3,
        phase_cols=list(range(4, 15)), extra_col=15)

    return data


if __name__ == "__main__":
    out = {}
    for path in sys.argv[1:]:
        out[path] = extract_file(path)
    
    # Save to json file for easy upload via API
    with open("kanban_seed.json", "w", encoding="utf-8") as f:
        json.dump(out, f, ensure_ascii=False, indent=2)
    print("Kanban seed generated at kanban_seed.json")
