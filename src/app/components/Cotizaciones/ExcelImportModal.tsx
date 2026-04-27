import { useState, useRef } from 'react';
import * as XLSX from 'xlsx';
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '../ui/dialog';
import { Button } from '../ui/button';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '../ui/select';
import { Alert, AlertDescription } from '../ui/alert';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '../ui/table';
import { Upload, FileSpreadsheet, CheckCircle, AlertCircle } from 'lucide-react';
import { ItemCotizacion } from '../../types';
import { formatearMoneda } from '../../utils/calculations';

interface ExcelImportModalProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  onImportar: (items: Omit<ItemCotizacion, 'id' | 'posicion'>[]) => void;
}

type ColumnMap = {
  descripcion: string;
  cantidad: string;
  precio_unitario: string;
  unidad: string;
};

const UNSET = '__unset__';

export function ExcelImportModal({ open, onOpenChange, onImportar }: ExcelImportModalProps) {
  const inputRef = useRef<HTMLInputElement>(null);
  const [headers, setHeaders] = useState<string[]>([]);
  const [rows, setRows] = useState<string[][]>([]);
  const [columnMap, setColumnMap] = useState<ColumnMap>({ descripcion: UNSET, cantidad: UNSET, precio_unitario: UNSET, unidad: UNSET });
  const [error, setError] = useState<string | null>(null);
  const [fileName, setFileName] = useState<string | null>(null);

  const reset = () => {
    setHeaders([]);
    setRows([]);
    setColumnMap({ descripcion: UNSET, cantidad: UNSET, precio_unitario: UNSET, unidad: UNSET });
    setError(null);
    setFileName(null);
    if (inputRef.current) inputRef.current.value = '';
  };

  const handleFile = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;
    setFileName(file.name);
    setError(null);

    const reader = new FileReader();
    reader.onload = (evt) => {
      try {
        const data = new Uint8Array(evt.target?.result as ArrayBuffer);
        const workbook = XLSX.read(data, { type: 'array' });
        const sheet = workbook.Sheets[workbook.SheetNames[0]];
        const json: string[][] = XLSX.utils.sheet_to_json(sheet, { header: 1, defval: '' });

        if (json.length < 2) {
          setError('El archivo debe tener al menos una fila de encabezados y una de datos.');
          return;
        }

        const rawHeaders = (json[0] as string[]).map(h => String(h).trim());
        setHeaders(rawHeaders);
        setRows(json.slice(1).filter(row => row.some(c => String(c).trim() !== '')) as string[][]);

        // Auto-detect columns by common Spanish names
        const auto: Partial<ColumnMap> = {};
        rawHeaders.forEach((h, i) => {
          const lower = h.toLowerCase();
          if (!auto.descripcion && /descripci|concepto|servicio|nombre/.test(lower)) auto.descripcion = String(i);
          if (!auto.cantidad && /cantidad|qty|cant/.test(lower)) auto.cantidad = String(i);
          if (!auto.precio_unitario && /precio|costo|cost|unit/.test(lower)) auto.precio_unitario = String(i);
          if (!auto.unidad && /unidad|unit|um/.test(lower)) auto.unidad = String(i);
        });
        setColumnMap(prev => ({ ...prev, ...auto }));
      } catch {
        setError('No se pudo leer el archivo. Asegúrate de que sea un .xlsx o .xls válido.');
      }
    };
    reader.readAsArrayBuffer(file);
  };

  const preview = rows.slice(0, 5).map(row => ({
    descripcion: columnMap.descripcion !== UNSET ? String(row[Number(columnMap.descripcion)] ?? '') : '',
    cantidad: columnMap.cantidad !== UNSET ? Number(row[Number(columnMap.cantidad)]) || 1 : 1,
    precio: columnMap.precio_unitario !== UNSET ? Number(String(row[Number(columnMap.precio_unitario)]).replace(/[,$]/g, '')) || 0 : 0,
    unidad: columnMap.unidad !== UNSET ? String(row[Number(columnMap.unidad)] ?? 'pz') || 'pz' : 'pz',
  }));

  const canImport = columnMap.descripcion !== UNSET && rows.length > 0;

  const handleImportar = () => {
    const allItems: Omit<ItemCotizacion, 'id' | 'posicion'>[] = rows
      .map(row => ({
        descripcion: String(row[Number(columnMap.descripcion)] ?? '').trim(),
        cantidad: columnMap.cantidad !== UNSET ? Number(row[Number(columnMap.cantidad)]) || 1 : 1,
        precio_unitario: columnMap.precio_unitario !== UNSET ? Number(String(row[Number(columnMap.precio_unitario)]).replace(/[,$]/g, '')) || 0 : 0,
        unidad: columnMap.unidad !== UNSET ? String(row[Number(columnMap.unidad)] ?? 'pz').trim() || 'pz' : 'pz',
        iva_item: 0,
        total_item: 0,
      }))
      .filter(item => item.descripcion !== '');

    onImportar(allItems);
    reset();
    onOpenChange(false);
  };

  return (
    <Dialog open={open} onOpenChange={(v) => { if (!v) reset(); onOpenChange(v); }}>
      <DialogContent className="max-w-2xl">
        <DialogHeader>
          <DialogTitle>Importar Conceptos desde Excel</DialogTitle>
          <DialogDescription>
            Sube un archivo .xlsx o .xls. Mapea las columnas y confirma para agregar los conceptos al editor.
          </DialogDescription>
        </DialogHeader>

        <div className="space-y-4">
          {/* Zona de carga */}
          <div
            className="border-2 border-dashed rounded-lg p-6 text-center cursor-pointer hover:border-blue-400 hover:bg-blue-50 transition-colors"
            onClick={() => inputRef.current?.click()}
          >
            <input ref={inputRef} type="file" accept=".xlsx,.xls,.csv" className="hidden" onChange={handleFile} />
            {fileName ? (
              <div className="flex items-center justify-center gap-3 text-green-700">
                <FileSpreadsheet className="w-8 h-8" />
                <div>
                  <p className="font-medium">{fileName}</p>
                  <p className="text-sm text-gray-500">{rows.length} filas detectadas</p>
                </div>
                <CheckCircle className="w-5 h-5" />
              </div>
            ) : (
              <div className="text-gray-500">
                <Upload className="w-10 h-10 mx-auto mb-2 opacity-40" />
                <p className="font-medium">Haz clic para seleccionar el archivo</p>
                <p className="text-sm mt-1">.xlsx, .xls</p>
              </div>
            )}
          </div>

          {error && (
            <Alert variant="destructive">
              <AlertCircle className="h-4 w-4" />
              <AlertDescription>{error}</AlertDescription>
            </Alert>
          )}

          {/* Mapeo de columnas */}
          {headers.length > 0 && (
            <div className="space-y-3">
              <p className="text-sm font-medium text-gray-700">Mapeo de columnas</p>
              <div className="grid grid-cols-2 gap-3">
                {([
                  { key: 'descripcion', label: 'Descripción *', required: true },
                  { key: 'cantidad', label: 'Cantidad' },
                  { key: 'precio_unitario', label: 'Precio Unitario' },
                  { key: 'unidad', label: 'Unidad' },
                ] as { key: keyof ColumnMap; label: string; required?: boolean }[]).map(({ key, label, required }) => (
                  <div key={key}>
                    <label className="text-xs text-gray-500 mb-1 block">{label}</label>
                    <Select
                      value={columnMap[key]}
                      onValueChange={v => setColumnMap(prev => ({ ...prev, [key]: v }))}
                    >
                      <SelectTrigger className="h-8 text-sm">
                        <SelectValue placeholder={required ? 'Seleccionar *' : 'No usar'} />
                      </SelectTrigger>
                      <SelectContent>
                        {!required && <SelectItem value={UNSET}>— No usar —</SelectItem>}
                        {headers.map((h, i) => (
                          <SelectItem key={i} value={String(i)}>{h}</SelectItem>
                        ))}
                      </SelectContent>
                    </Select>
                  </div>
                ))}
              </div>
            </div>
          )}

          {/* Preview */}
          {preview.length > 0 && columnMap.descripcion !== UNSET && (
            <div>
              <p className="text-xs font-medium text-gray-500 mb-1">Vista previa (primeros {preview.length} de {rows.length})</p>
              <div className="rounded-md border overflow-x-auto">
                <Table>
                  <TableHeader>
                    <TableRow>
                      <TableHead>Descripción</TableHead>
                      <TableHead className="w-16">Cant.</TableHead>
                      <TableHead className="w-20">Unidad</TableHead>
                      <TableHead className="w-24 text-right">Precio</TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {preview.map((row, i) => (
                      <TableRow key={i}>
                        <TableCell className="text-sm">{row.descripcion || <span className="text-gray-400 italic">vacío</span>}</TableCell>
                        <TableCell className="text-sm">{row.cantidad}</TableCell>
                        <TableCell className="text-sm">{row.unidad}</TableCell>
                        <TableCell className="text-sm text-right">{formatearMoneda(row.precio)}</TableCell>
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
              </div>
              {rows.length > 5 && (
                <p className="text-xs text-gray-400 mt-1">…y {rows.length - 5} filas más</p>
              )}
            </div>
          )}
        </div>

        <DialogFooter>
          <Button variant="outline" onClick={() => { reset(); onOpenChange(false); }}>Cancelar</Button>
          <Button onClick={handleImportar} disabled={!canImport} className="bg-green-600 hover:bg-green-700">
            Importar {rows.length > 0 ? `${rows.filter(r => r[Number(columnMap.descripcion)]?.toString().trim()).length} conceptos` : ''}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
