import { useState, useEffect, useRef } from 'react';
import { Button } from '../ui/button';
import { Input } from '../ui/input';
import { Label } from '../ui/label';
import { Textarea } from '../ui/textarea';
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '../ui/card';
import { Alert, AlertDescription } from '../ui/alert';
import { Save, Settings, Upload, Trash2, Image as ImageIcon, Sun, Moon, Loader2 } from 'lucide-react';
import { Ajustes } from '../../types';
import {
  validarArchivoLogo,
  sanearSvg,
  calcularDimensionesLogo,
  calcularTamanoDataUrl,
  ANCHO_MAX_NORMALIZADO,
  ANCHO_REDUCIDO_NORMALIZADO,
  TAMANO_MAX_PNG_BYTES,
  decidirLogoEncabezado
} from '../../utils/logo';

interface AjustesFormProps {
  ajustes: Ajustes;
  onActualizarAjustes: (ajustes: Partial<Ajustes>) => void;
}

export function AjustesForm({ ajustes, onActualizarAjustes }: AjustesFormProps) {
  const [formData, setFormData] = useState(ajustes);
  const [guardado, setGuardado] = useState(false);
  const [errores, setErrores] = useState<string[]>([]);
  const [procesandoLogo, setProcesandoLogo] = useState<'logo' | 'logo_claro' | null>(null);
  const [errorLogo, setErrorLogo] = useState<string | null>(null);

  const inputLogoOscuroRef = useRef<HTMLInputElement>(null);
  const inputLogoClaroRef = useRef<HTMLInputElement>(null);

  const procesarArchivo = async (file: File, destino: 'logo' | 'logo_claro') => {
    setErrorLogo(null);
    setProcesandoLogo(destino);
    try {
      const validacion = validarArchivoLogo({ name: file.name, size: file.size, type: file.type });
      if (!validacion.valido) {
        throw new Error(validacion.error);
      }

      const isSvg = file.type === 'image/svg+xml' || file.name.toLowerCase().endsWith('.svg');
      let imgSource = '';
      let naturalW = 0;
      let naturalH = 0;

      if (isSvg) {
        const text = await file.text();
        const saneado = sanearSvg(text);
        if (!saneado.valido) {
          throw new Error(saneado.error);
        }

        const vbMatch = text.match(/viewBox\s*=\s*["']\s*([0-9.]+)\s+([0-9.]+)\s+([0-9.]+)\s+([0-9.]+)\s*["']/i);
        if (vbMatch) {
          naturalW = parseFloat(vbMatch[3]);
          naturalH = parseFloat(vbMatch[4]);
        } else {
          const wMatch = text.match(/width\s*=\s*["']\s*([0-9.]+)[a-z%]*\s*["']/i);
          const hMatch = text.match(/height\s*=\s*["']\s*([0-9.]+)[a-z%]*\s*["']/i);
          if (wMatch && hMatch) {
            naturalW = parseFloat(wMatch[1]);
            naturalH = parseFloat(hMatch[1]);
          }
        }

        const blob = new Blob([text], { type: 'image/svg+xml;charset=utf-8' });
        imgSource = URL.createObjectURL(blob);
      } else {
        imgSource = await new Promise<string>((resolve, reject) => {
          const reader = new FileReader();
          reader.onload = () => resolve(reader.result as string);
          reader.onerror = () => reject(new Error('Error al leer el archivo en el navegador'));
          reader.readAsDataURL(file);
        });
      }

      const img = await new Promise<HTMLImageElement>((resolve, reject) => {
        const i = new Image();
        i.onload = () => resolve(i);
        i.onerror = () => reject(new Error('No se pudo renderizar la imagen'));
        i.src = imgSource;
      });

      if (isSvg && imgSource.startsWith('blob:')) {
        URL.revokeObjectURL(imgSource);
      }

      const origWidth = naturalW > 0 ? naturalW : img.naturalWidth || img.width || 1200;
      const origHeight = naturalH > 0 ? naturalH : img.naturalHeight || img.height || 300;

      // Paso 1: Escalar a máximo 1200 px de ancho sin agrandar
      const dim1200 = calcularDimensionesLogo(origWidth, origHeight, ANCHO_MAX_NORMALIZADO);
      let canvas = document.createElement('canvas');
      canvas.width = dim1200.width;
      canvas.height = dim1200.height;
      let ctx = canvas.getContext('2d');
      if (!ctx) throw new Error('No fue posible inicializar el lienzo gráfico');
      ctx.clearRect(0, 0, canvas.width, canvas.height);
      ctx.drawImage(img, 0, 0, canvas.width, canvas.height);

      let dataUrl = canvas.toDataURL('image/png');
      let tamanoBytes = calcularTamanoDataUrl(dataUrl);

      // Paso 2: Si excede 400 KB, reintentar a 800 px
      if (tamanoBytes > TAMANO_MAX_PNG_BYTES) {
        const dim800 = calcularDimensionesLogo(origWidth, origHeight, ANCHO_REDUCIDO_NORMALIZADO);
        canvas = document.createElement('canvas');
        canvas.width = dim800.width;
        canvas.height = dim800.height;
        ctx = canvas.getContext('2d');
        if (!ctx) throw new Error('No fue posible inicializar el lienzo gráfico');
        ctx.clearRect(0, 0, canvas.width, canvas.height);
        ctx.drawImage(img, 0, 0, canvas.width, canvas.height);

        dataUrl = canvas.toDataURL('image/png');
        tamanoBytes = calcularTamanoDataUrl(dataUrl);

        if (tamanoBytes > TAMANO_MAX_PNG_BYTES) {
          throw new Error(`La imagen optimizada pesa ${(tamanoBytes / 1024).toFixed(0)} KB y supera el límite de 400 KB. Intenta con una imagen de menor complejidad o resolución.`);
        }
      }

      setFormData(prev => ({ ...prev, [destino]: dataUrl }));
    } catch (err: any) {
      setErrorLogo(err?.message || 'Error al procesar el archivo');
    } finally {
      setProcesandoLogo(null);
    }
  };

  useEffect(() => {
    setFormData(ajustes);
  }, [ajustes]);

  const validarFormulario = (): string[] => {
    const errores = [];
    
    if (formData.iva_por_defecto < 0 || formData.iva_por_defecto > 0.5) {
      errores.push('La tasa de IVA debe estar entre 0 y 0.5');
    }
    
    if (formData.validez_por_defecto <= 0) {
      errores.push('La validez por defecto debe ser mayor a 0 días');
    }
    
    if (formData.offset_folio < 1) {
      errores.push('El offset de folio debe ser al menos 1');
    }
    
    return errores;
  };

  const manejarGuardar = () => {
    const erroresValidacion = validarFormulario();
    if (erroresValidacion.length > 0) {
      setErrores(erroresValidacion);
      return;
    }
    
    setErrores([]);
    onActualizarAjustes(formData);
    setGuardado(true);
    
    // Ocultar mensaje después de 3 segundos
    setTimeout(() => setGuardado(false), 3000);
  };

  if (!formData) {
    return (
      <div className="flex justify-center items-center py-20 min-h-[50vh]">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-accent-blue" />
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center gap-4">
        <Settings className="h-6 w-6" />
        <h1>Configuración del Sistema</h1>
      </div>

      {guardado && (
        <Alert>
          <AlertDescription>
            Los ajustes se han guardado correctamente.
          </AlertDescription>
        </Alert>
      )}

      {errores.length > 0 && (
        <Alert>
          <AlertDescription>
            <ul className="list-disc list-inside">
              {errores.map((error, index) => (
                <li key={index}>{error}</li>
              ))}
            </ul>
          </AlertDescription>
        </Alert>
      )}

      
      <Card>
        <CardHeader>
          <CardTitle>Apariencia</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="flex items-center justify-between md:justify-start md:space-x-8">
            <div className="space-y-1">
              <Label>Tema de la Interfaz</Label>
              <p className="text-sm text-muted-foreground">Alternar entre el modo oscuro y claro</p>
            </div>
            <select
              className="flex h-10 w-48 rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-ring focus:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-50"
              value={localStorage.getItem('theme') || 'dark'}
              onChange={(e) => {
                const val = e.target.value;
                localStorage.setItem('theme', val);
                if (val === 'light') {
                  document.documentElement.classList.remove('dark');
                } else {
                  document.documentElement.classList.add('dark');
                }
                // Simular guardado para forzar re-render si es necesario
                setGuardado(true);
                setTimeout(() => setGuardado(false), 2000);
              }}
            >
              <option value="dark" className="bg-background text-foreground">🌙 Modo Oscuro</option>
              <option value="light" className="bg-background text-foreground">☀️ Modo Claro</option>
            </select>
          </div>
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>Configuración de Cotizaciones</CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <Label>IVA por Defecto</Label>
              <Input
                type="number"
                value={formData.iva_por_defecto}
                onChange={(e) => setFormData(prev => ({ ...prev, iva_por_defecto: parseFloat(e.target.value) || 0 }))}
                min="0"
                max="0.5"
                step="0.01"
                placeholder="0.16"
              />
              <p className="text-sm text-gray-500 mt-1">
                Tasa de IVA que se aplicará por defecto a nuevos productos y conceptos
              </p>
            </div>

            <div>
              <Label>Validez por Defecto (días)</Label>
              <Input
                type="number"
                value={formData.validez_por_defecto}
                onChange={(e) => setFormData(prev => ({ ...prev, validez_por_defecto: parseInt(e.target.value) || 0 }))}
                min="1"
                placeholder="30"
              />
              <p className="text-sm text-gray-500 mt-1">
                Días de validez que tendrán las cotizaciones por defecto
              </p>
            </div>
          </div>

          <div>
            <Label>Nota por Defecto</Label>
            <Textarea
              value={formData.nota_por_defecto}
              onChange={(e) => setFormData(prev => ({ ...prev, nota_por_defecto: e.target.value }))}
              placeholder="Texto que aparecerá por defecto en las nuevas cotizaciones..."
              rows={4}
            />
            <p className="text-sm text-gray-500 mt-1">
              Puedes usar {'{validez_dias}'} para incluir automáticamente los días de validez
            </p>
          </div>
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>Configuración de Folios</CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <Label>Prefijo de Folio</Label>
              <Input
                value={formData.prefijo_folio}
                onChange={(e) => setFormData(prev => ({ ...prev, prefijo_folio: e.target.value }))}
                placeholder="COT-"
              />
              <p className="text-sm text-gray-500 mt-1">
                Texto que aparecerá antes del año y número consecutivo
              </p>
            </div>

            <div>
              <Label>Offset de Folio</Label>
              <Input
                type="number"
                value={formData.offset_folio}
                onChange={(e) => setFormData(prev => ({ ...prev, offset_folio: parseInt(e.target.value) || 1 }))}
                min="1"
                placeholder="1"
              />
              <p className="text-sm text-gray-500 mt-1">
                Número inicial para la numeración consecutiva
              </p>
            </div>
          </div>

          <div className="p-4 bg-blue-50 rounded-md">
            <h4 className="font-medium text-blue-900">Vista Previa del Folio</h4>
            <p className="text-blue-700 mt-1">
              Ejemplo: {formData.prefijo_folio}{new Date().getFullYear()}-{(formData.offset_folio || 0).toString().padStart(5, '0')}
            </p>
          </div>
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>Información de la Empresa</CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <Label>Nombre de la Empresa</Label>
              <Input
                value={formData.nombre_empresa || ''}
                onChange={(e) => setFormData(prev => ({ ...prev, nombre_empresa: e.target.value }))}
                placeholder="IDEALLY"
              />
              <p className="text-sm text-gray-500 mt-1">
                Nombre que aparecerá en los documentos PDF
              </p>
            </div>

            <div>
              <Label>Tagline</Label>
              <Input
                value={formData.tagline || ''}
                onChange={(e) => setFormData(prev => ({ ...prev, tagline: e.target.value }))}
                placeholder="Arte . Diseño . Ingeniería"
              />
              <p className="text-sm text-gray-500 mt-1">
                Lema o descripción breve de la empresa
              </p>
            </div>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <Label>Dirección</Label>
              <Input
                value={formData.direccion || ''}
                onChange={(e) => setFormData(prev => ({ ...prev, direccion: e.target.value }))}
                placeholder="Retorno Pascual Mendoza 27, Puebla, Pue. 72260"
              />
            </div>

            <div>
              <Label>Teléfono</Label>
              <Input
                value={formData.telefono || ''}
                onChange={(e) => setFormData(prev => ({ ...prev, telefono: e.target.value }))}
                placeholder="+52 22 1120 2976"
              />
            </div>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <Label>Email de Contacto</Label>
              <Input
                type="email"
                value={formData.email || ''}
                onChange={(e) => setFormData(prev => ({ ...prev, email: e.target.value }))}
                placeholder="ventas@ideally.com.mx"
              />
              <p className="text-sm text-gray-500 mt-1">
                Email que aparecerá en tus cotizaciones y documentos
              </p>
            </div>

            <div>
              <Label>Sitio Web</Label>
              <Input
                value={formData.sitio_web || ''}
                onChange={(e) => setFormData(prev => ({ ...prev, sitio_web: e.target.value }))}
                placeholder="www.ideally.com.mx"
              />
            </div>
          </div>

          <div>
            <Label>Cuenta Bancaria</Label>
            <Input
              value={formData.cuenta_bancaria || ''}
              onChange={(e) => setFormData(prev => ({ ...prev, cuenta_bancaria: e.target.value }))}
              placeholder="Cuenta: 123456789 - Banco XYZ"
            />
            <p className="text-sm text-gray-500 mt-1">
              Información de cuenta bancaria para transferencias
            </p>
          </div>
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <div className="flex items-center gap-2">
            <ImageIcon className="h-5 w-5 text-primary" />
            <CardTitle>Logo de la Empresa</CardTitle>
          </div>
          <CardDescription>
            Sube el logo de tu marca para el encabezado de las cotizaciones (vista previa, PDF y portal del cliente). Formatos soportados: SVG, PNG, JPG y WebP (hasta 2 MB).
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-6">
          <div className="text-xs bg-muted/50 p-3 rounded-lg border border-border/50 text-muted-foreground flex items-start gap-2">
            <span className="font-semibold text-primary">💡 Consejo:</span>
            <span>
              Si tu logo es blanco, súbelo en <em>"Logo para fondo oscuro"</em>; si es de color o negro, usa <em>"Logo para fondo claro"</em>. Todo archivo se normaliza automáticamente en tu navegador a PNG transparente optimizado (≤ 400 KB).
            </span>
          </div>

          {errorLogo && (
            <Alert>
              <AlertDescription className="text-destructive font-medium">{errorLogo}</AlertDescription>
            </Alert>
          )}

          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            {/* Logo para fondo oscuro */}
            <div className="flex flex-col justify-between p-4 rounded-lg border border-border bg-card space-y-4">
              <div className="space-y-1">
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-1.5 font-medium text-sm">
                    <Moon className="h-4 w-4 text-primary" />
                    <span>Logo para fondo oscuro</span>
                  </div>
                  <span className="text-[11px] text-primary font-semibold uppercase tracking-wider bg-primary/10 px-2 py-0.5 rounded">
                    Principal
                  </span>
                </div>
                <p className="text-xs text-muted-foreground">
                  Usado en el encabezado negro del PDF Moodboard y en el portal del cliente.
                </p>
              </div>

              {/* Caja de vista previa sobre fondo oscuro */}
              <div className="min-h-[100px] bg-black rounded-md p-4 flex items-center justify-center border border-border/40 relative overflow-hidden">
                {formData.logo ? (
                  <img
                    src={formData.logo}
                    alt={formData.nombre_empresa || 'Logo oscuro'}
                    className="max-h-[50px] max-w-full object-contain"
                  />
                ) : (
                  <div className="text-center text-zinc-500 text-xs">
                    <ImageIcon className="h-6 w-6 mx-auto mb-1 opacity-40 text-white" />
                    <span>Sin logo cargado</span>
                  </div>
                )}
                {procesandoLogo === 'logo' && (
                  <div className="absolute inset-0 bg-black/70 flex items-center justify-center text-white text-xs gap-2">
                    <Loader2 className="h-4 w-4 animate-spin text-primary" />
                    <span>Optimizando imagen…</span>
                  </div>
                )}
              </div>

              {/* Acciones */}
              <div className="flex items-center justify-between pt-1 gap-2">
                <input
                  type="file"
                  ref={inputLogoOscuroRef}
                  className="hidden"
                  accept=".svg,.png,.jpg,.jpeg,.webp"
                  onChange={(e) => {
                    const f = e.target.files?.[0];
                    if (f) procesarArchivo(f, 'logo');
                    e.target.value = '';
                  }}
                />
                <Button
                  type="button"
                  variant="outline"
                  size="sm"
                  onClick={() => inputLogoOscuroRef.current?.click()}
                  disabled={procesandoLogo !== null}
                  className="flex items-center gap-1.5 text-xs"
                >
                  <Upload className="h-3.5 w-3.5" />
                  {formData.logo ? 'Cambiar logo' : 'Subir logo oscuro'}
                </Button>

                {formData.logo && (
                  <div className="flex items-center gap-2">
                    <span className="text-[11px] text-muted-foreground font-mono">
                      {(calcularTamanoDataUrl(formData.logo) / 1024).toFixed(0)} KB
                    </span>
                    <Button
                      type="button"
                      variant="ghost"
                      size="sm"
                      onClick={() => setFormData(prev => ({ ...prev, logo: undefined }))}
                      className="text-destructive hover:text-destructive h-8 px-2"
                      title="Quitar logo para fondo oscuro"
                    >
                      <Trash2 className="h-3.5 w-3.5" />
                    </Button>
                  </div>
                )}
              </div>
            </div>

            {/* Logo para fondo claro */}
            <div className="flex flex-col justify-between p-4 rounded-lg border border-border bg-card space-y-4">
              <div className="space-y-1">
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-1.5 font-medium text-sm">
                    <Sun className="h-4 w-4 text-primary" />
                    <span>Logo para fondo claro</span>
                  </div>
                  <span className="text-[11px] text-muted-foreground font-semibold uppercase tracking-wider bg-muted px-2 py-0.5 rounded">
                    Opcional
                  </span>
                </div>
                <p className="text-xs text-muted-foreground">
                  Usado en plantillas con encabezado blanco (Compacta, Leolca, Moderna).
                </p>
              </div>

              {/* Caja de vista previa sobre fondo claro */}
              <div className="min-h-[100px] bg-white rounded-md p-4 flex items-center justify-center border border-border/40 relative overflow-hidden">
                {formData.logo_claro ? (
                  <img
                    src={formData.logo_claro}
                    alt={formData.nombre_empresa || 'Logo claro'}
                    className="max-h-[50px] max-w-full object-contain"
                  />
                ) : (
                  <div className="text-center text-gray-400 text-xs">
                    <ImageIcon className="h-6 w-6 mx-auto mb-1 opacity-40 text-black" />
                    <span>Sin logo claro (se adaptará el logo principal)</span>
                  </div>
                )}
                {procesandoLogo === 'logo_claro' && (
                  <div className="absolute inset-0 bg-white/70 flex items-center justify-center text-gray-900 text-xs gap-2">
                    <Loader2 className="h-4 w-4 animate-spin text-primary" />
                    <span>Optimizando imagen…</span>
                  </div>
                )}
              </div>

              {/* Acciones */}
              <div className="flex items-center justify-between pt-1 gap-2">
                <input
                  type="file"
                  ref={inputLogoClaroRef}
                  className="hidden"
                  accept=".svg,.png,.jpg,.jpeg,.webp"
                  onChange={(e) => {
                    const f = e.target.files?.[0];
                    if (f) procesarArchivo(f, 'logo_claro');
                    e.target.value = '';
                  }}
                />
                <Button
                  type="button"
                  variant="outline"
                  size="sm"
                  onClick={() => inputLogoClaroRef.current?.click()}
                  disabled={procesandoLogo !== null}
                  className="flex items-center gap-1.5 text-xs"
                >
                  <Upload className="h-3.5 w-3.5" />
                  {formData.logo_claro ? 'Cambiar logo' : 'Subir logo claro'}
                </Button>

                {formData.logo_claro && (
                  <div className="flex items-center gap-2">
                    <span className="text-[11px] text-muted-foreground font-mono">
                      {(calcularTamanoDataUrl(formData.logo_claro) / 1024).toFixed(0)} KB
                    </span>
                    <Button
                      type="button"
                      variant="ghost"
                      size="sm"
                      onClick={() => setFormData(prev => ({ ...prev, logo_claro: undefined }))}
                      className="text-destructive hover:text-destructive h-8 px-2"
                      title="Quitar logo para fondo claro"
                    >
                      <Trash2 className="h-3.5 w-3.5" />
                    </Button>
                  </div>
                )}
              </div>
            </div>
          </div>

          {/* Interruptor mostrar nombre */}
          <div className="flex items-center space-x-3 p-3.5 bg-muted/30 rounded-lg border border-border/50">
            <input
              id="logo_mostrar_nombre"
              type="checkbox"
              className="h-4 w-4 rounded border-border text-primary focus:ring-primary cursor-pointer"
              checked={Boolean(formData.logo_mostrar_nombre)}
              onChange={(e) => setFormData(prev => ({ ...prev, logo_mostrar_nombre: e.target.checked }))}
            />
            <div className="space-y-0.5">
              <Label htmlFor="logo_mostrar_nombre" className="cursor-pointer font-medium text-sm">
                Mostrar el nombre de la empresa junto al logo
              </Label>
              <p className="text-xs text-muted-foreground">
                Por defecto está desactivado cuando hay logo, mostrando el logo en sustitución del nombre.
              </p>
            </div>
          </div>

          {/* Vistas previas en plantillas */}
          <div className="space-y-4 pt-2 border-t border-border/50">
            <div>
              <h4 className="font-medium text-sm text-foreground">Vista previa del encabezado</h4>
              <p className="text-xs text-muted-foreground">
                Cómo se verá la marca de tu empresa según la plantilla seleccionada para la cotización.
              </p>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              {/* Preview oscuro */}
              <div className="space-y-1.5">
                <span className="text-[11px] font-semibold uppercase tracking-wider text-muted-foreground flex items-center gap-1.5">
                  <Moon className="h-3 w-3 text-primary" />
                  Encabezado oscuro (Moodboard / Portal)
                </span>
                <div className="bg-black text-white p-3.5 rounded-lg flex items-center justify-between border border-border/40 overflow-hidden shadow-sm">
                  <div className="flex items-center gap-3">
                    {decidirLogoEncabezado(formData, 'oscuro').url ? (
                      <img
                        src={decidirLogoEncabezado(formData, 'oscuro').url}
                        alt="Logo"
                        style={{ height: 32, maxWidth: 140, objectFit: 'contain' }}
                      />
                    ) : null}
                    {decidirLogoEncabezado(formData, 'oscuro').mostrarNombre && (
                      <div>
                        <p className="font-bold text-xs leading-tight text-white">{formData.nombre_empresa || 'IDEALLY'}</p>
                        <p className="text-[10px] text-white/50">{formData.tagline || 'Arte . Diseño . Ingeniería'}</p>
                      </div>
                    )}
                  </div>
                  <div className="text-right text-[10px] text-white/40">
                    <p>Cotización COT-2026-0001</p>
                    <p>{formData.email || 'contacto@empresa.com'}</p>
                  </div>
                </div>
              </div>

              {/* Preview claro */}
              <div className="space-y-1.5">
                <span className="text-[11px] font-semibold uppercase tracking-wider text-muted-foreground flex items-center gap-1.5">
                  <Sun className="h-3 w-3 text-primary" />
                  Encabezado claro (Compacta / Leolca / Moderna)
                </span>
                <div className="bg-white text-gray-900 p-3.5 rounded-lg flex items-center justify-between border border-border overflow-hidden shadow-sm">
                  <div className="flex items-center gap-3">
                    {decidirLogoEncabezado(formData, 'claro').url ? (
                      <div className={decidirLogoEncabezado(formData, 'claro').usarContenedorNegro ? "p-1.5 bg-black rounded inline-flex items-center justify-center" : "inline-flex items-center"}>
                        <img
                          src={decidirLogoEncabezado(formData, 'claro').url}
                          alt="Logo"
                          style={{ height: 32, maxWidth: 140, objectFit: 'contain' }}
                        />
                      </div>
                    ) : null}
                    {decidirLogoEncabezado(formData, 'claro').mostrarNombre && (
                      <div>
                        <p className="font-bold text-xs text-gray-900 leading-tight">{formData.nombre_empresa || 'IDEALLY'}</p>
                        <p className="text-[10px] text-gray-500">{formData.tagline || 'Arte . Diseño . Ingeniería'}</p>
                      </div>
                    )}
                  </div>
                  <div className="text-right text-[10px] text-gray-500">
                    <p className="font-semibold text-gray-700">Cotización COT-2026-0001</p>
                    <p>{formData.email || 'contacto@empresa.com'}</p>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>Configuración de Emails</CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <div>
            <Label>Email de Envío</Label>
            <Input
              type="email"
              value={formData.email_envio || ''}
              onChange={(e) => setFormData(prev => ({ ...prev, email_envio: e.target.value }))}
              placeholder="ventas@ideally.com.mx"
            />
            <p className="text-sm text-gray-500 mt-1">
              Email desde el que se enviarán las cotizaciones por correo electrónico
            </p>
          </div>

          <div className="p-4 bg-amber-50 rounded-md border border-amber-200">
            <h4 className="font-medium text-amber-900">⚠️ Importante: Verificación de Dominio</h4>
            <div className="mt-2 text-sm text-amber-800 space-y-2">
              <p>
                Para enviar emails desde tu propio dominio (ej: ventas@ideally.com.mx), 
                primero debes <strong>verificar tu dominio en Resend</strong>.
              </p>
              <p>
                Si no verificas tu dominio, los emails se enviarán desde <code className="bg-amber-100 px-1 py-0.5 rounded">onboarding@resend.dev</code>
              </p>
              <p className="mt-3">
                <strong>Pasos para verificar tu dominio:</strong>
              </p>
              <ol className="list-decimal list-inside space-y-1 ml-2">
                <li>Ve a <a href="https://resend.com/domains" target="_blank" rel="noopener noreferrer" className="underline text-amber-900 hover:text-amber-950">resend.com/domains</a></li>
                <li>Agrega tu dominio (ej: ideally.com.mx)</li>
                <li>Configura los registros DNS (SPF, DKIM, DMARC)</li>
                <li>Espera a que se verifique (puede tardar hasta 48 horas)</li>
                <li>Ingresa tu email verificado en el campo de arriba</li>
              </ol>
              <p className="mt-3">
                📖 Lee el archivo <code className="bg-amber-100 px-1 py-0.5 rounded">CONFIGURACION_EMAIL.md</code> para instrucciones detalladas
              </p>
            </div>
          </div>
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>Textos del Resumen de Servicios</CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <div>
            <Label>Título de la Sección</Label>
            <Input
              value={formData.resumen_servicios?.titulo || 'RESUMEN DE SERVICIOS'}
              onChange={(e) => setFormData(prev => ({ 
                ...prev, 
                resumen_servicios: { 
                  ...prev.resumen_servicios, 
                  titulo: e.target.value 
                } 
              }))}
              placeholder="RESUMEN DE SERVICIOS"
            />
          </div>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div>
              <Label>Texto Pago Único</Label>
              <Input
                value={formData.resumen_servicios?.pago_unico || 'Servicio de pago único'}
                onChange={(e) => setFormData(prev => ({ 
                  ...prev, 
                  resumen_servicios: { 
                    ...prev.resumen_servicios, 
                    pago_unico: e.target.value 
                  } 
                }))}
                placeholder="Servicio de pago único"
              />
            </div>

            <div>
              <Label>Texto Suscripción</Label>
              <Input
                value={formData.resumen_servicios?.suscripcion || 'Servicio de suscripción'}
                onChange={(e) => setFormData(prev => ({ 
                  ...prev, 
                  resumen_servicios: { 
                    ...prev.resumen_servicios, 
                    suscripcion: e.target.value 
                  } 
                }))}
                placeholder="Servicio de suscripción"
              />
            </div>

            <div>
              <Label>Texto Híbrido</Label>
              <Input
                value={formData.resumen_servicios?.hibrido || 'Servicio híbrido'}
                onChange={(e) => setFormData(prev => ({ 
                  ...prev, 
                  resumen_servicios: { 
                    ...prev.resumen_servicios, 
                    hibrido: e.target.value 
                  } 
                }))}
                placeholder="Servicio híbrido"
              />
            </div>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <Label>Texto Setup Completo</Label>
              <Input
                value={formData.resumen_servicios?.setup_completo || 'Incluye setup completo'}
                onChange={(e) => setFormData(prev => ({ 
                  ...prev, 
                  resumen_servicios: { 
                    ...prev.resumen_servicios, 
                    setup_completo: e.target.value 
                  } 
                }))}
                placeholder="Incluye setup completo"
              />
            </div>

            <div>
              <Label>Texto Setup Inicial</Label>
              <Input
                value={formData.resumen_servicios?.setup_inicial || 'Incluye setup inicial'}
                onChange={(e) => setFormData(prev => ({ 
                  ...prev, 
                  resumen_servicios: { 
                    ...prev.resumen_servicios, 
                    setup_inicial: e.target.value 
                  } 
                }))}
                placeholder="Incluye setup inicial"
              />
            </div>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <Label>Etiqueta Periodo</Label>
              <Input
                value={formData.resumen_servicios?.periodo_label || 'Periodo:'}
                onChange={(e) => setFormData(prev => ({ 
                  ...prev, 
                  resumen_servicios: { 
                    ...prev.resumen_servicios, 
                    periodo_label: e.target.value 
                  } 
                }))}
                placeholder="Periodo:"
              />
            </div>

            <div>
              <Label>Etiqueta Meses Contratados</Label>
              <Input
                value={formData.resumen_servicios?.meses_contratados_label || 'Meses contratados:'}
                onChange={(e) => setFormData(prev => ({ 
                  ...prev, 
                  resumen_servicios: { 
                    ...prev.resumen_servicios, 
                    meses_contratados_label: e.target.value 
                  } 
                }))}
                placeholder="Meses contratados:"
              />
            </div>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <Label>Etiqueta Permanencia Mínima</Label>
              <Input
                value={formData.resumen_servicios?.permanencia_minima_label || 'Permanencia mínima:'}
                onChange={(e) => setFormData(prev => ({ 
                  ...prev, 
                  resumen_servicios: { 
                    ...prev.resumen_servicios, 
                    permanencia_minima_label: e.target.value 
                  } 
                }))}
                placeholder="Permanencia mínima:"
              />
            </div>

            <div>
              <Label>Etiqueta Base Asientos</Label>
              <Input
                value={formData.resumen_servicios?.base_asientos_label || 'Base:'}
                onChange={(e) => setFormData(prev => ({ 
                  ...prev, 
                  resumen_servicios: { 
                    ...prev.resumen_servicios, 
                    base_asientos_label: e.target.value 
                  } 
                }))}
                placeholder="Base:"
              />
            </div>
          </div>

          <div>
            <Label>Etiqueta Asientos Adicionales</Label>
            <Input
              value={formData.resumen_servicios?.asientos_adicionales_label || 'Asientos adicionales:'}
              onChange={(e) => setFormData(prev => ({ 
                ...prev, 
                resumen_servicios: { 
                  ...prev.resumen_servicios, 
                  asientos_adicionales_label: e.target.value 
                } 
              }))}
              placeholder="Asientos adicionales:"
            />
          </div>

          <div className="p-4 bg-blue-50 rounded-md">
            <h4 className="font-medium text-blue-900">Vista Previa</h4>
            <p className="text-blue-700 mt-1">
              {formData.resumen_servicios?.titulo || 'RESUMEN DE SERVICIOS'}
            </p>
            <div className="mt-2 text-sm text-blue-600">
              <p>• {formData.resumen_servicios?.pago_unico || 'Servicio de pago único'}</p>
              <p>• {formData.resumen_servicios?.setup_completo || 'Incluye setup completo'}</p>
            </div>
          </div>
        </CardContent>
      </Card>

      <div className="flex justify-end">
        <Button onClick={manejarGuardar}>
          <Save className="mr-2 h-4 w-4" />
          Guardar Ajustes
        </Button>
      </div>
    </div>
  );
}