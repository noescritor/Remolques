import React, { useState, useEffect, useRef } from 'react';
import { 
  ClipboardList, 
  Plus, 
  Search, 
  Trash2, 
  Play, 
  Check, 
  Download, 
  Calendar, 
  Clock, 
  User, 
  FileText, 
  X, 
  MessageSquare, 
  Printer 
} from 'lucide-react';
import { NotaSimple, ItemNotaSimple, Producto } from '../../types';
import { Button } from '../ui/button';
import { Input } from '../ui/input';
import { Label } from '../ui/label';
import { Badge } from '../ui/badge';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter } from '../ui/dialog';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '../ui/tabs';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '../ui/table';

interface NotasManagerProps {
  notasList: NotaSimple[];
  productos?: Producto[];
  loading: boolean;
  onCrearNota: (nota: Omit<NotaSimple, 'id' | 'folio'>) => Promise<any>;
  onActualizarNota: (id: string, updates: Partial<NotaSimple>) => Promise<any>;
  onEliminarNota: (id: string) => Promise<any>;
  session?: any;
  ajustes?: any;
}

export const NotasManager: React.FC<NotasManagerProps> = ({
  notasList = [],
  productos = [],
  loading,
  onCrearNota,
  onActualizarNota,
  onEliminarNota,
  session,
  ajustes
}) => {
  const [activeTab, setActiveTab] = useState('taller');
  const [isNewModalOpen, setIsNewModalOpen] = useState(false);
  const [isTicketModalOpen, setIsTicketModalOpen] = useState(false);
  const [selectedNota, setSelectedNota] = useState<NotaSimple | null>(null);
  const [searchQuery, setSearchQuery] = useState('');
  const [filterUrgencia, setFilterUrgencia] = useState('Todas');
  const [filterEstado, setFilterEstado] = useState('Todas');
  const [activeItemSuggestIndex, setActiveItemSuggestIndex] = useState<number | null>(null);
  const [formatType, setFormatType] = useState<'ticket' | 'nota'>('nota');

  // Form states for new note
  const [clienteNombre, setClienteNombre] = useState('');
  const [urgencia, setUrgencia] = useState<'Baja' | 'Media' | 'Alta' | 'Urgente'>('Media');
  const [fechaEntrega, setFechaEntrega] = useState('');
  const [vendedorNombre, setVendedorNombre] = useState(session?.user?.user_metadata?.nombre || '');
  const [items, setItems] = useState<ItemNotaSimple[]>([{ concepto: '', cantidad: 1, precio: 0, total: 0 }]);

  const [canvasNode, setCanvasNode] = useState<HTMLCanvasElement | null>(null);

  // Sync session name if available
  useEffect(() => {
    if (session?.user?.user_metadata?.nombre) {
      setVendedorNombre(session.user.user_metadata.nombre);
    }
  }, [session]);

  // Handle Canvas Drawing when selectedNota, formatType or modal changes
  useEffect(() => {
    if (isTicketModalOpen && selectedNota && canvasNode) {
      if (formatType === 'nota') {
        drawNotaNegocio(canvasNode, selectedNota);
      } else {
        drawTicket(canvasNode, selectedNota);
      }
    }
  }, [isTicketModalOpen, selectedNota, formatType, canvasNode]);

  const handleAddItem = () => {
    setItems([...items, { concepto: '', cantidad: 1, precio: 0, total: 0 }]);
  };

  const handleRemoveItem = (index: number) => {
    if (items.length === 1) return;
    const newItems = items.filter((_, i) => i !== index);
    setItems(newItems);
  };

  const handleItemChange = (index: number, field: keyof ItemNotaSimple, value: any) => {
    const newItems = [...items];
    const item = newItems[index];

    if (field === 'cantidad') {
      item.cantidad = Number(value);
    } else if (field === 'precio') {
      item.precio = Number(value);
    } else {
      item[field] = value as never;
    }

    item.total = item.cantidad * item.precio;
    setItems(newItems);
  };

  const calculateTotal = () => {
    return items.reduce((sum, item) => sum + item.total, 0);
  };

  const handleSaveNota = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!clienteNombre.trim()) return;

    const filteredItems = items.filter(item => item.concepto.trim() !== '');
    if (filteredItems.length === 0) return;

    const total = filteredItems.reduce((sum, item) => sum + item.total, 0);

    try {
      const notaData = {
        cliente_nombre: clienteNombre,
        urgencia,
        fecha_entrega: fechaEntrega ? new Date(fechaEntrega).toISOString() : undefined,
        creado_por_nombre: vendedorNombre || 'Vendedor',
        items: filteredItems,
        total,
        estado_taller: 'Pendiente' as const
      };

      const result = await onCrearNota(notaData);
      setIsNewModalOpen(false);
      
      // Clear form
      setClienteNombre('');
      setUrgencia('Media');
      setFechaEntrega('');
      setItems([{ concepto: '', cantidad: 1, precio: 0, total: 0 }]);

      // Automatically open the ticket modal for the new note
      if (result) {
        setSelectedNota(result);
        setIsTicketModalOpen(true);
      }
    } catch (err) {
      // toast is already shown inside the hook
    }
  };

  const handleAdvanceStatus = async (nota: NotaSimple) => {
    let nextStatus: 'Pendiente' | 'En Proceso' | 'Listo' | 'Entregado' = 'Pendiente';
    if (nota.estado_taller === 'Pendiente') nextStatus = 'En Proceso';
    else if (nota.estado_taller === 'En Proceso') nextStatus = 'Listo';
    else if (nota.estado_taller === 'Listo') nextStatus = 'Entregado';

    if (nota.id) {
      await onActualizarNota(nota.id, { estado_taller: nextStatus });
    }
  };

  const drawNotaNegocio = (canvas: HTMLCanvasElement, nota: NotaSimple) => {
    const ctx = canvas.getContext('2d');
    if (!ctx) return;

    const itemsList = Array.isArray(nota.items) ? nota.items : [];
    const N = itemsList.length;
    const rowHeight = 48;
    const tableRowsCount = Math.max(3, N);
    const heightOffset = (tableRowsCount - 3) * rowHeight;
    
    canvas.width = 1240;
    canvas.height = 872 + heightOffset;

    // Background
    ctx.fillStyle = '#F7F7F7';
    ctx.fillRect(0, 0, canvas.width, canvas.height);

    // Rounded rectangle helper
    const drawRoundedRect = (c: CanvasRenderingContext2D, x: number, y: number, w: number, h: number, r: number) => {
      c.beginPath();
      c.moveTo(x + r, y);
      c.lineTo(x + w - r, y);
      c.quadraticCurveTo(x + w, y, x + w, y + r);
      c.lineTo(x + w, y + h - r);
      c.quadraticCurveTo(x + w, y + h, x + w - r, y + h);
      c.lineTo(x + r, y + h);
      c.quadraticCurveTo(x, y + h, x, y + h - r);
      c.lineTo(x, y + r);
      c.quadraticCurveTo(x, y, x + r, y);
      c.closePath();
    };

    // Main Card
    ctx.fillStyle = '#FFFFFF';
    drawRoundedRect(ctx, 40, 40, 1160, 807 + heightOffset, 16);
    ctx.fill();
    ctx.strokeStyle = 'rgba(0, 0, 0, 0.06)';
    ctx.lineWidth = 1;
    ctx.stroke();

    // Header Band
    ctx.fillStyle = '#6351D3';
    drawRoundedRect(ctx, 40, 40, 1160, 80, 16);
    ctx.fill();
    ctx.fillRect(40, 96, 1160, 24); // fill bottom fix

    // Reset baseline for absolute positioning
    ctx.textBaseline = 'top';

    // Title
    ctx.fillStyle = '#FFFFFF';
    ctx.font = 'bold 24px "DM Sans", sans-serif';
    ctx.fillText(ajustes?.nombre_empresa?.toUpperCase() || 'IDEALLY', 64, 64);

    // Note Number
    ctx.fillStyle = 'rgba(255, 255, 255, 0.6)';
    ctx.font = '500 14px "DM Mono", monospace';
    ctx.fillText(`NOTA # ${String(nota.folio || '').padStart(5, '0')}`, 64, 96);

    // Date Label
    ctx.font = '500 11px "DM Mono", monospace';
    ctx.fillText('FECHA EMISIÓN', 1000, 64);

    // Date Value
    ctx.fillStyle = '#FFFFFF';
    ctx.font = 'bold 18px "DM Sans", sans-serif';
    const fechaStr = nota.created_at ? new Date(nota.created_at).toLocaleDateString('es-MX') : new Date().toLocaleDateString('es-MX');
    ctx.fillText(fechaStr, 1000, 80);

    // Parties Label
    ctx.fillStyle = 'rgba(0, 0, 0, 0.45)';
    ctx.font = '500 11px "DM Mono", monospace';
    ctx.fillText('INFORMACIÓN DE LAS PARTES', 64, 144);

    // Separator
    ctx.fillStyle = 'rgba(0, 0, 0, 0.08)';
    ctx.fillRect(64, 168, 1112, 1);

    // Seller Card
    ctx.fillStyle = '#F7F7F7';
    drawRoundedRect(ctx, 64, 176, 480, 120, 12);
    ctx.fill();

    ctx.fillStyle = '#6351D3';
    drawRoundedRect(ctx, 64, 176, 4, 120, 2);
    ctx.fill();

    ctx.fillStyle = '#6351D3';
    ctx.font = '500 11px "DM Mono", monospace';
    ctx.fillText('EMISOR / VENDEDOR', 80, 184);

    ctx.fillStyle = '#000000';
    ctx.font = 'bold 18px "DM Sans", sans-serif';
    ctx.fillText(nota.creado_por_nombre || 'Vendedor', 80, 208);

    ctx.fillStyle = 'rgba(0, 0, 0, 0.6)';
    ctx.font = '400 14px "DM Sans", sans-serif';
    ctx.fillText(ajustes?.tagline || 'Arte . Diseño . Ingeniería', 80, 240);

    // Buyer Card
    ctx.fillStyle = '#F7F7F7';
    drawRoundedRect(ctx, 572, 176, 480, 120, 12);
    ctx.fill();

    ctx.fillStyle = '#29B9CD';
    drawRoundedRect(ctx, 572, 176, 4, 120, 2);
    ctx.fill();

    ctx.fillStyle = '#29B9CD';
    ctx.font = '500 11px "DM Mono", monospace';
    ctx.fillText('RECEPTOR / CLIENTE', 588, 184);

    ctx.fillStyle = '#000000';
    ctx.font = 'bold 18px "DM Sans", sans-serif';
    ctx.fillText(nota.cliente_nombre, 588, 208);

    ctx.fillStyle = 'rgba(0, 0, 0, 0.6)';
    ctx.font = '400 14px "DM Sans", sans-serif';
    ctx.fillText('Cliente Particular', 588, 240);

    // Products Label
    ctx.fillStyle = 'rgba(0, 0, 0, 0.45)';
    ctx.font = '500 11px "DM Mono", monospace';
    ctx.fillText('DETALLE DE PRODUCTOS Y CONCEPTOS', 64, 320);

    // Separator
    ctx.fillStyle = 'rgba(0, 0, 0, 0.08)';
    ctx.fillRect(64, 344, 1112, 1);

    // Table Header BG
    ctx.fillStyle = 'rgba(99, 81, 211, 0.06)';
    drawRoundedRect(ctx, 64, 352, 1112, 32, 8);
    ctx.fill();

    // Table Headers
    ctx.fillStyle = 'rgba(0, 0, 0, 0.45)';
    ctx.font = '500 11px "DM Mono", monospace';
    ctx.fillText('DESCRIPCIÓN DEL CONCEPTO', 80, 360);
    ctx.fillText('CANT', 728, 360);
    ctx.fillText('PRECIO UNITARIO', 808, 360);
    ctx.fillText('TOTAL', 992, 360);

    // Render items
    itemsList.forEach((item, idx) => {
      const rowY = 400 + idx * rowHeight;
      if (idx % 2 === 1) {
        ctx.fillStyle = 'rgba(99, 81, 211, 0.03)';
        drawRoundedRect(ctx, 64, rowY - 8, 1112, 32, 4);
        ctx.fill();
      }

      ctx.fillStyle = '#000000';
      ctx.font = '400 14px "DM Sans", sans-serif';
      ctx.fillText(item.concepto, 80, rowY);

      ctx.font = '500 14px "DM Sans", sans-serif';
      ctx.fillText(String(item.cantidad), 728, rowY);

      ctx.font = '500 14px "DM Mono", monospace';
      ctx.fillText(`$${item.precio.toFixed(2)}`, 808, rowY);
      ctx.fillText(`$${item.total.toFixed(2)}`, 992, rowY);

      ctx.fillStyle = 'rgba(0, 0, 0, 0.08)';
      ctx.fillRect(64, rowY + 32, 1112, 1);
    });

    // Total separator line
    ctx.fillStyle = 'rgba(99, 81, 211, 0.15)';
    ctx.fillRect(64, 528 + heightOffset, 1112, 2);

    // Subtotal and IVA
    const subtotal = nota.total / 1.16;
    const iva = nota.total - subtotal;

    ctx.fillStyle = 'rgba(0, 0, 0, 0.6)';
    ctx.font = '400 14px "DM Sans", sans-serif';
    ctx.fillText('Subtotal', 808, 544 + heightOffset);

    ctx.font = '500 14px "DM Mono", monospace';
    ctx.fillText(`$${subtotal.toFixed(2)}`, 992, 544 + heightOffset);

    ctx.fillStyle = 'rgba(0, 0, 0, 0.6)';
    ctx.font = '400 14px "DM Sans", sans-serif';
    ctx.fillText('IVA (16%)', 808, 576 + heightOffset);

    ctx.font = '500 14px "DM Mono", monospace';
    ctx.fillText(`$${iva.toFixed(2)}`, 992, 576 + heightOffset);

    // Total Badge
    ctx.fillStyle = '#6351D3';
    drawRoundedRect(ctx, 784, 608 + heightOffset, 368, 48, 8);
    ctx.fill();

    ctx.fillStyle = 'rgba(255, 255, 255, 0.7)';
    ctx.font = '500 11px "DM Mono", monospace';
    ctx.fillText('TOTAL', 808, 622 + heightOffset);

    ctx.fillStyle = '#FFFFFF';
    ctx.font = 'bold 24px "DM Sans", sans-serif';
    ctx.fillText(`$${nota.total.toFixed(2)}`, 900, 616 + heightOffset);

    // Delivery Card
    ctx.fillStyle = 'rgba(255, 182, 72, 0.12)';
    drawRoundedRect(ctx, 64, 616 + heightOffset, 264, 48, 8);
    ctx.fill();

    ctx.fillStyle = '#B87F00';
    ctx.font = '500 11px "DM Mono", monospace';
    ctx.fillText('FECHA DE ENTREGA', 80, 624 + heightOffset);

    ctx.font = 'bold 18px "DM Sans", sans-serif';
    const entregaStr = nota.fecha_entrega ? new Date(nota.fecha_entrega).toLocaleDateString('es-MX', {
      day: '2-digit',
      month: '2-digit',
      year: 'numeric'
    }) : 'Entrega Inmediata';
    ctx.fillText(entregaStr, 80, 640 + heightOffset);

    // Notes Card
    ctx.fillStyle = '#F7F7F7';
    drawRoundedRect(ctx, 64, 680 + heightOffset, 700, 120, 12);
    ctx.fill();
    ctx.strokeStyle = 'rgba(0, 0, 0, 0.06)';
    ctx.stroke();

    ctx.fillStyle = 'rgba(0, 0, 0, 0.45)';
    ctx.font = '500 11px "DM Mono", monospace';
    ctx.fillText('NOTAS Y CONDICIONES', 80, 688 + heightOffset);

    ctx.fillStyle = 'rgba(0, 0, 0, 0.7)';
    ctx.font = '400 14px "DM Sans", sans-serif';
    ctx.fillText('Esta es una nota interna de operación. Conserve este documento para reclamar su pedido.', 80, 712 + heightOffset);

    // Status Badge
    ctx.fillStyle = 'rgba(49, 209, 94, 0.15)';
    drawRoundedRect(ctx, 1020, 688 + heightOffset, 128, 32, 16);
    ctx.fill();

    ctx.fillStyle = '#1A8C3A';
    ctx.font = 'bold 11px "DM Mono", monospace';
    ctx.textAlign = 'center';
    ctx.fillText(nota.estado_taller.toUpperCase(), 1020 + 64, 696 + heightOffset);
    ctx.textAlign = 'left';

    // Separator
    ctx.fillStyle = 'rgba(0, 0, 0, 0.08)';
    ctx.fillRect(64, 808 + heightOffset, 1112, 1);

    // Legal Footer
    ctx.fillStyle = 'rgba(0, 0, 0, 0.35)';
    ctx.font = '500 11px "DM Mono", monospace';
    ctx.fillText('ESTA ES UNA NOTA DE OPERACIÓN DE TALLER Y NO CONSTITUYE UN COMPROBANTE FISCAL.', 64, 816 + heightOffset);

    // Page Number
    ctx.fillText('PÁGINA 1/1', 1080, 816 + heightOffset);
  };

  const drawTicket = (canvas: HTMLCanvasElement, nota: NotaSimple) => {
    const ctx = canvas.getContext('2d');
    if (!ctx) return;

    const itemsList = Array.isArray(nota.items) ? nota.items : [];
    const height = 400 + (itemsList.length * 30);
    canvas.height = height;

    // Reset Canvas Styles
    ctx.fillStyle = '#FFFFFF';
    ctx.fillRect(0, 0, canvas.width, canvas.height);

    ctx.fillStyle = '#000000';
    ctx.textAlign = 'center';

    // Header: Company details
    const nombreEmpresa = ajustes?.nombre_empresa || 'IDEALLY';
    const tagline = ajustes?.tagline || 'Arte . Diseño . Ingeniería';
    const direccion = ajustes?.direccion || 'Retorno Pascual Mendoza 27, Puebla, Pue. 72260';
    const telefono = ajustes?.telefono || '+52 22 1120 2976';
    const web = ajustes?.sitio_web || 'www.ideally.com.mx';

    ctx.font = 'bold 22px Courier New';
    ctx.fillText(nombreEmpresa.toUpperCase(), canvas.width / 2, 45);

    ctx.font = '12px Courier New';
    ctx.fillText(tagline, canvas.width / 2, 65);
    
    // Wrap address if it's too long
    ctx.font = '10px Courier New';
    const addressWords = direccion.split(' ');
    let line = '';
    let yPos = 85;
    for (let n = 0; n < addressWords.length; n++) {
      let testLine = line + addressWords[n] + ' ';
      if (testLine.length > 35 && n > 0) {
        ctx.fillText(line, canvas.width / 2, yPos);
        line = addressWords[n] + ' ';
        yPos += 15;
      } else {
        line = testLine;
      }
    }
    ctx.fillText(line, canvas.width / 2, yPos);
    yPos += 15;

    ctx.fillText(`Tel: ${telefono}`, canvas.width / 2, yPos);
    yPos += 15;
    ctx.fillText(web, canvas.width / 2, yPos);
    yPos += 15;

    // Divider
    ctx.font = '12px Courier New';
    ctx.fillText('----------------------------------------', canvas.width / 2, yPos);
    yPos += 20;

    // Ticket info
    ctx.textAlign = 'left';
    ctx.font = 'bold 14px Courier New';
    ctx.fillText(`FOLIO TICKET: #${String(nota.folio || '').padStart(5, '0')}`, 20, yPos);
    yPos += 20;

    ctx.font = '11px Courier New';
    const fechaStr = nota.created_at ? new Date(nota.created_at).toLocaleString('es-MX') : new Date().toLocaleString('es-MX');
    ctx.fillText(`Fecha: ${fechaStr}`, 20, yPos);
    yPos += 18;

    ctx.fillText(`Cliente: ${nota.cliente_nombre}`, 20, yPos);
    yPos += 18;

    ctx.fillText(`Vendedor: ${nota.creado_por_nombre}`, 20, yPos);
    yPos += 18;

    if (nota.fecha_entrega) {
      const entregaStr = new Date(nota.fecha_entrega).toLocaleString('es-MX');
      ctx.fillText(`Entrega: ${entregaStr}`, 20, yPos);
      yPos += 18;
    }

    // Divider
    ctx.textAlign = 'center';
    ctx.fillText('----------------------------------------', canvas.width / 2, yPos);
    yPos += 20;

    // Table headers
    ctx.textAlign = 'left';
    ctx.font = 'bold 11px Courier New';
    ctx.fillText('CONCEPTO', 20, yPos);
    ctx.textAlign = 'right';
    ctx.fillText('CANT x PRECIO', 280, yPos);
    ctx.fillText('IMPORTE', 380, yPos);
    yPos += 18;

    // Items
    ctx.font = '11px Courier New';
    itemsList.forEach((item) => {
      ctx.textAlign = 'left';
      // Truncate concept if needed
      const conceptoTrunc = item.concepto.length > 20 ? item.concepto.slice(0, 18) + '..' : item.concepto;
      ctx.fillText(conceptoTrunc, 20, yPos);

      ctx.textAlign = 'right';
      ctx.fillText(`${item.cantidad} x $${item.precio.toFixed(0)}`, 280, yPos);
      ctx.fillText(`$${item.total.toFixed(2)}`, 380, yPos);
      yPos += 22;
    });

    // Divider
    ctx.textAlign = 'center';
    ctx.fillText('----------------------------------------', canvas.width / 2, yPos);
    yPos += 20;

    // Total
    ctx.textAlign = 'left';
    ctx.font = 'bold 14px Courier New';
    ctx.fillText('TOTAL A PAGAR:', 20, yPos);
    ctx.textAlign = 'right';
    ctx.fillText(`$${nota.total.toFixed(2)}`, 380, yPos);
    yPos += 30;

    // Urgencia / Estado
    ctx.textAlign = 'center';
    ctx.font = 'bold 11px Courier New';
    ctx.fillText(`URGENCIA: ${nota.urgencia.toUpperCase()}`, canvas.width / 2, yPos);
    yPos += 15;
    ctx.fillText(`ESTADO TALLER: ${nota.estado_taller.toUpperCase()}`, canvas.width / 2, yPos);
    yPos += 25;

    // Footer
    ctx.font = 'italic 10px Courier New';
    ctx.fillText('¡Gracias por su compra!', canvas.width / 2, yPos);
    yPos += 15;
    ctx.fillText('Este ticket no es un comprobante fiscal.', canvas.width / 2, yPos);
  };

  const handleDownloadTicket = () => {
    if (!canvasNode || !selectedNota) return;

    const dataUrl = canvasNode.toDataURL('image/png');
    const link = document.createElement('a');
    const prefix = formatType === 'nota' ? 'Nota' : 'Ticket';
    link.download = `${prefix}_${String(selectedNota.folio || '').padStart(5, '0')}_${selectedNota.cliente_nombre.replace(/\s+/g, '_')}.png`;
    link.href = dataUrl;
    link.click();
  };

  const handleSendWhatsApp = () => {
    if (!selectedNota) return;

    const folioStr = String(selectedNota.folio || '').padStart(5, '0');
    const itemsList = Array.isArray(selectedNota.items) ? selectedNota.items : [];
    
    let mensaje = `📝 *Nota de Venta #${folioStr}*\n`;
    mensaje += `👤 *Cliente:* ${selectedNota.cliente_nombre}\n`;
    
    if (selectedNota.fecha_entrega) {
      const fecha = new Date(selectedNota.fecha_entrega).toLocaleString('es-MX', {
        day: '2-digit',
        month: '2-digit',
        year: 'numeric',
        hour: '2-digit',
        minute: '2-digit'
      });
      mensaje += `📅 *Entrega:* ${fecha}\n`;
    }
    
    mensaje += `⚡ *Urgencia:* ${selectedNota.urgencia}\n`;
    mensaje += `---------------------------\n`;
    
    itemsList.forEach((item) => {
      mensaje += `▪️ ${item.cantidad}x ${item.concepto} ($${item.precio}) = *$${item.total}*\n`;
    });
    
    mensaje += `---------------------------\n`;
    mensaje += `💵 *Total:* *$${selectedNota.total.toFixed(2)}*\n\n`;
    mensaje += `¡Gracias por tu preferencia! 🙌`;

    const url = `https://api.whatsapp.com/send?text=${encodeURIComponent(mensaje)}`;
    window.open(url, '_blank');
  };

  const handlePrint = () => {
    if (!canvasNode || !selectedNota) return;
    const dataUrl = canvasNode.toDataURL('image/png');
    
    const printWindow = window.open('', '_blank');
    if (printWindow) {
      printWindow.document.write(`
        <html>
          <head>
            <title>Imprimir Ticket #${selectedNota.folio}</title>
            <style>
              body {
                margin: 0;
                display: flex;
                justify-content: center;
                align-items: flex-start;
                background-color: white;
              }
              img {
                max-width: 100%;
                height: auto;
              }
              @media print {
                body {
                  margin: 0;
                }
                img {
                  width: 80mm; /* standard thermal printer width */
                }
              }
            </style>
          </head>
          <body onload="window.print(); window.close();">
            <img src="${dataUrl}" />
          </body>
        </html>
      `);
      printWindow.document.close();
    }
  };

  // Filter notes
  const notesActive = notasList.filter(n => n.estado_taller !== 'Entregado');
  const notesHistory = notasList;

  const getFilteredNotes = (list: NotaSimple[]) => {
    return list.filter(nota => {
      const matchesSearch = 
        nota.cliente_nombre.toLowerCase().includes(searchQuery.toLowerCase()) ||
        String(nota.folio || '').includes(searchQuery) ||
        (Array.isArray(nota.items) && nota.items.some(it => it.concepto.toLowerCase().includes(searchQuery.toLowerCase())));

      const matchesUrgencia = filterUrgencia === 'Todas' || nota.urgencia === filterUrgencia;
      const matchesEstado = filterEstado === 'Todas' || nota.estado_taller === filterEstado;

      return matchesSearch && matchesUrgencia && matchesEstado;
    });
  };

  const getUrgencyBorder = (urgency: string) => {
    switch (urgency) {
      case 'Urgente': return 'border-l-4 border-l-red-500 border-white/[0.06]';
      case 'Alta': return 'border-l-4 border-l-orange-500 border-white/[0.06]';
      case 'Media': return 'border-l-4 border-l-blue-500 border-white/[0.06]';
      case 'Baja': return 'border-l-4 border-l-gray-500 border-white/[0.06]';
      default: return 'border-white/[0.06]';
    }
  };

  const getUrgencyBadgeColor = (urgency: string) => {
    switch (urgency) {
      case 'Urgente': return 'bg-red-500/10 text-red-400 border border-red-500/20';
      case 'Alta': return 'bg-orange-500/10 text-orange-400 border border-orange-500/20';
      case 'Media': return 'bg-blue-500/10 text-blue-400 border border-blue-500/20';
      case 'Baja': return 'bg-zinc-500/10 text-zinc-400 border border-zinc-500/20';
      default: return 'bg-zinc-500/10 text-zinc-400 border border-zinc-500/20';
    }
  };

  const getEstadoBadgeColor = (estado: string) => {
    switch (estado) {
      case 'Pendiente': return 'bg-yellow-500/10 text-yellow-400 border border-yellow-500/20';
      case 'En Proceso': return 'bg-purple-500/10 text-purple-400 border border-purple-500/20';
      case 'Listo': return 'bg-green-500/10 text-green-400 border border-green-500/20';
      case 'Entregado': return 'bg-blue-500/10 text-blue-400 border border-blue-500/20';
      default: return 'bg-zinc-500/10 text-zinc-400 border border-zinc-500/20';
    }
  };

  const activeFiltered = getFilteredNotes(notesActive);
  const historyFiltered = getFilteredNotes(notesHistory);

  // Group active notes by state
  const colPendiente = activeFiltered.filter(n => n.estado_taller === 'Pendiente');
  const colProceso = activeFiltered.filter(n => n.estado_taller === 'En Proceso');
  const colListo = activeFiltered.filter(n => n.estado_taller === 'Listo');

  return (
    <div className="space-y-6 max-w-7xl mx-auto">
      {/* Header */}
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
        <div>
          <h1 className="text-2xl font-bold text-white flex items-center gap-2">
            <ClipboardList className="h-6 w-6 text-accent-blue" />
            Notas Rápidas y Taller
          </h1>
          <p className="text-sm text-muted-foreground mt-1">
            Crea notas rápidas para clientes al instante y supervisa las tareas activas en el taller.
          </p>
        </div>
        <Button 
          onClick={() => setIsNewModalOpen(true)} 
          className="bg-accent-blue hover:bg-accent-blue/80 text-white font-medium gap-2"
        >
          <Plus className="h-5 w-5" />
          Nueva Nota
        </Button>
      </div>

      {/* Tabs Layout */}
      <Tabs value={activeTab} onValueChange={setActiveTab} className="w-full">
        <TabsList className="bg-white/[0.03] border border-white/[0.06] p-1 gap-1">
          <TabsTrigger value="taller" className="data-[state=active]:bg-white/[0.06] text-white">
            Cola de Taller
          </TabsTrigger>
          <TabsTrigger value="historial" className="data-[state=active]:bg-white/[0.06] text-white">
            Historial de Notas
          </TabsTrigger>
        </TabsList>

        {/* Tab 1: Kanban Board */}
        <TabsContent value="taller" className="mt-6">
          {loading ? (
            <div className="flex items-center justify-center py-20">
              <div className="w-8 h-8 border-4 border-accent-blue border-t-transparent rounded-full animate-spin"></div>
            </div>
          ) : (
            <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
              {/* Column: Pendiente */}
              <div className="bg-white/[0.02] border border-white/[0.04] rounded-xl p-4 flex flex-col min-h-[500px]">
                <div className="flex justify-between items-center mb-4 pb-2 border-b border-white/[0.06]">
                  <h3 className="font-semibold text-white flex items-center gap-2">
                    <span className="w-2.5 h-2.5 rounded-full bg-yellow-500"></span>
                    Pendientes
                  </h3>
                  <Badge variant="outline" className="bg-yellow-500/10 text-yellow-400 border-yellow-500/20">
                    {colPendiente.length}
                  </Badge>
                </div>
                
                <div className="flex-1 space-y-4 overflow-y-auto max-h-[600px] pr-1">
                  {colPendiente.length === 0 ? (
                    <div className="h-full flex items-center justify-center py-12 text-sm text-muted-foreground border border-dashed border-white/5 rounded-lg">
                      No hay notas pendientes
                    </div>
                  ) : (
                    colPendiente.map(nota => (
                      <div 
                        key={nota.id}
                        className={`bg-white/[0.03] hover:bg-white/[0.05] transition-all duration-200 border rounded-lg p-4 shadow-lg space-y-3 ${getUrgencyBorder(nota.urgencia)}`}
                      >
                        <div className="flex justify-between items-start">
                          <span className="text-xs font-mono text-accent-blue font-semibold">
                            #{String(nota.folio || '').padStart(5, '0')}
                          </span>
                          <Badge className={getUrgencyBadgeColor(nota.urgencia)}>
                            {nota.urgencia}
                          </Badge>
                        </div>

                        <div onClick={() => { setSelectedNota(nota); setIsTicketModalOpen(true); }} className="cursor-pointer">
                          <h4 className="font-semibold text-white truncate">{nota.cliente_nombre}</h4>
                          <ul className="text-xs text-muted-foreground mt-2 space-y-1">
                            {Array.isArray(nota.items) && nota.items.map((it, idx) => (
                              <li key={idx} className="truncate">
                                • {it.cantidad}x {it.concepto}
                              </li>
                            ))}
                          </ul>
                        </div>

                        <div className="flex flex-col gap-2 pt-2 border-t border-white/[0.06] text-[11px] text-muted-foreground">
                          {nota.fecha_entrega && (
                            <span className="flex items-center gap-1">
                              <Clock className="h-3 w-3 text-accent-blue" />
                              Entrega: {new Date(nota.fecha_entrega).toLocaleDateString()}
                            </span>
                          )}
                          <span className="flex items-center gap-1">
                            <User className="h-3 w-3" />
                            Por: {nota.creado_por_nombre}
                          </span>
                        </div>

                        <div className="flex justify-between items-center pt-2">
                          <span className="text-sm font-semibold text-white">
                            ${nota.total.toFixed(2)}
                          </span>
                          <Button 
                            size="sm" 
                            onClick={() => handleAdvanceStatus(nota)}
                            className="bg-yellow-500/10 hover:bg-yellow-500/20 text-yellow-400 text-xs px-2.5 py-1 gap-1"
                          >
                            <Play className="h-3 w-3" />
                            Comenzar
                          </Button>
                        </div>
                      </div>
                    ))
                  )}
                </div>
              </div>

              {/* Column: En Proceso */}
              <div className="bg-white/[0.02] border border-white/[0.04] rounded-xl p-4 flex flex-col min-h-[500px]">
                <div className="flex justify-between items-center mb-4 pb-2 border-b border-white/[0.06]">
                  <h3 className="font-semibold text-white flex items-center gap-2">
                    <span className="w-2.5 h-2.5 rounded-full bg-purple-500"></span>
                    En Proceso
                  </h3>
                  <Badge variant="outline" className="bg-purple-500/10 text-purple-400 border-purple-500/20">
                    {colProceso.length}
                  </Badge>
                </div>
                
                <div className="flex-1 space-y-4 overflow-y-auto max-h-[600px] pr-1">
                  {colProceso.length === 0 ? (
                    <div className="h-full flex items-center justify-center py-12 text-sm text-muted-foreground border border-dashed border-white/5 rounded-lg">
                      No hay notas en proceso
                    </div>
                  ) : (
                    colProceso.map(nota => (
                      <div 
                        key={nota.id}
                        className={`bg-white/[0.03] hover:bg-white/[0.05] transition-all duration-200 border rounded-lg p-4 shadow-lg space-y-3 ${getUrgencyBorder(nota.urgencia)}`}
                      >
                        <div className="flex justify-between items-start">
                          <span className="text-xs font-mono text-accent-blue font-semibold">
                            #{String(nota.folio || '').padStart(5, '0')}
                          </span>
                          <Badge className={getUrgencyBadgeColor(nota.urgencia)}>
                            {nota.urgencia}
                          </Badge>
                        </div>

                        <div onClick={() => { setSelectedNota(nota); setIsTicketModalOpen(true); }} className="cursor-pointer">
                          <h4 className="font-semibold text-white truncate">{nota.cliente_nombre}</h4>
                          <ul className="text-xs text-muted-foreground mt-2 space-y-1">
                            {Array.isArray(nota.items) && nota.items.map((it, idx) => (
                              <li key={idx} className="truncate">
                                • {it.cantidad}x {it.concepto}
                              </li>
                            ))}
                          </ul>
                        </div>

                        <div className="flex flex-col gap-2 pt-2 border-t border-white/[0.06] text-[11px] text-muted-foreground">
                          {nota.fecha_entrega && (
                            <span className="flex items-center gap-1">
                              <Clock className="h-3 w-3 text-accent-blue" />
                              Entrega: {new Date(nota.fecha_entrega).toLocaleDateString()}
                            </span>
                          )}
                          <span className="flex items-center gap-1">
                            <User className="h-3 w-3" />
                            Por: {nota.creado_por_nombre}
                          </span>
                        </div>

                        <div className="flex justify-between items-center pt-2">
                          <span className="text-sm font-semibold text-white">
                            ${nota.total.toFixed(2)}
                          </span>
                          <Button 
                            size="sm" 
                            onClick={() => handleAdvanceStatus(nota)}
                            className="bg-purple-500/10 hover:bg-purple-500/20 text-purple-400 text-xs px-2.5 py-1 gap-1"
                          >
                            <Check className="h-3 w-3" />
                            Terminar
                          </Button>
                        </div>
                      </div>
                    ))
                  )}
                </div>
              </div>

              {/* Column: Listo */}
              <div className="bg-white/[0.02] border border-white/[0.04] rounded-xl p-4 flex flex-col min-h-[500px]">
                <div className="flex justify-between items-center mb-4 pb-2 border-b border-white/[0.06]">
                  <h3 className="font-semibold text-white flex items-center gap-2">
                    <span className="w-2.5 h-2.5 rounded-full bg-green-500"></span>
                    Listo para Entrega
                  </h3>
                  <Badge variant="outline" className="bg-green-500/10 text-green-400 border-green-500/20">
                    {colListo.length}
                  </Badge>
                </div>
                
                <div className="flex-1 space-y-4 overflow-y-auto max-h-[600px] pr-1">
                  {colListo.length === 0 ? (
                    <div className="h-full flex items-center justify-center py-12 text-sm text-muted-foreground border border-dashed border-white/5 rounded-lg">
                      No hay notas listas para entrega
                    </div>
                  ) : (
                    colListo.map(nota => (
                      <div 
                        key={nota.id}
                        className={`bg-white/[0.03] hover:bg-white/[0.05] transition-all duration-200 border rounded-lg p-4 shadow-lg space-y-3 ${getUrgencyBorder(nota.urgencia)}`}
                      >
                        <div className="flex justify-between items-start">
                          <span className="text-xs font-mono text-accent-blue font-semibold">
                            #{String(nota.folio || '').padStart(5, '0')}
                          </span>
                          <Badge className={getUrgencyBadgeColor(nota.urgencia)}>
                            {nota.urgencia}
                          </Badge>
                        </div>

                        <div onClick={() => { setSelectedNota(nota); setIsTicketModalOpen(true); }} className="cursor-pointer">
                          <h4 className="font-semibold text-white truncate">{nota.cliente_nombre}</h4>
                          <ul className="text-xs text-muted-foreground mt-2 space-y-1">
                            {Array.isArray(nota.items) && nota.items.map((it, idx) => (
                              <li key={idx} className="truncate">
                                • {it.cantidad}x {it.concepto}
                              </li>
                            ))}
                          </ul>
                        </div>

                        <div className="flex flex-col gap-2 pt-2 border-t border-white/[0.06] text-[11px] text-muted-foreground">
                          {nota.fecha_entrega && (
                            <span className="flex items-center gap-1">
                              <Clock className="h-3 w-3 text-accent-blue" />
                              Entrega: {new Date(nota.fecha_entrega).toLocaleDateString()}
                            </span>
                          )}
                          <span className="flex items-center gap-1">
                            <User className="h-3 w-3" />
                            Por: {nota.creado_por_nombre}
                          </span>
                        </div>

                        <div className="flex justify-between items-center pt-2">
                          <span className="text-sm font-semibold text-white">
                            ${nota.total.toFixed(2)}
                          </span>
                          <Button 
                            size="sm" 
                            onClick={() => handleAdvanceStatus(nota)}
                            className="bg-green-500/10 hover:bg-green-500/20 text-green-400 text-xs px-2.5 py-1 gap-1"
                          >
                            <Check className="h-3 w-3" />
                            Entregar
                          </Button>
                        </div>
                      </div>
                    ))
                  )}
                </div>
              </div>
            </div>
          )}
        </TabsContent>

        {/* Tab 2: Full History Table */}
        <TabsContent value="historial" className="mt-6">
          <div className="bg-white/[0.03] border border-white/[0.06] rounded-xl overflow-hidden p-4 space-y-4 shadow-lg">
            {/* Filters */}
            <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
              <div className="relative col-span-2">
                <Search className="absolute left-3 top-3 h-4 w-4 text-muted-foreground" />
                <Input
                  placeholder="Buscar por cliente, folio o concepto..."
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                  className="pl-9 bg-white/[0.04] border-white/10"
                />
              </div>

              <div>
                <select
                  value={filterUrgencia}
                  onChange={(e) => setFilterUrgencia(e.target.value)}
                  className="block w-full sm:text-sm rounded-md py-2 px-3 border border-white/10 bg-white/[0.04] text-white focus:outline-none focus:ring-accent-blue focus:border-accent-blue h-10"
                >
                  <option value="Todas" className="bg-zinc-900 text-white">Todas las Urgencias</option>
                  <option value="Baja" className="bg-zinc-900 text-white">Baja</option>
                  <option value="Media" className="bg-zinc-900 text-white">Media</option>
                  <option value="Alta" className="bg-zinc-900 text-white">Alta</option>
                  <option value="Urgente" className="bg-zinc-900 text-white">Urgente</option>
                </select>
              </div>

              <div>
                <select
                  value={filterEstado}
                  onChange={(e) => setFilterEstado(e.target.value)}
                  className="block w-full sm:text-sm rounded-md py-2 px-3 border border-white/10 bg-white/[0.04] text-white focus:outline-none focus:ring-accent-blue focus:border-accent-blue h-10"
                >
                  <option value="Todas" className="bg-zinc-900 text-white">Todos los Estados</option>
                  <option value="Pendiente" className="bg-zinc-900 text-white">Pendiente</option>
                  <option value="En Proceso" className="bg-zinc-900 text-white">En Proceso</option>
                  <option value="Listo" className="bg-zinc-900 text-white">Listo</option>
                  <option value="Entregado" className="bg-zinc-900 text-white">Entregado</option>
                </select>
              </div>
            </div>

            {/* Table */}
            <div className="overflow-x-auto rounded-lg border border-white/[0.06]">
              <Table>
                <TableHeader className="bg-white/[0.01]">
                  <TableRow className="border-b border-white/[0.06] hover:bg-transparent">
                    <TableHead className="text-white font-medium py-3">Folio</TableHead>
                    <TableHead className="text-white font-medium">Cliente</TableHead>
                    <TableHead className="text-white font-medium">Conceptos</TableHead>
                    <TableHead className="text-white font-medium text-center">Urgencia</TableHead>
                    <TableHead className="text-white font-medium text-center">Estado</TableHead>
                    <TableHead className="text-white font-medium text-right">Total</TableHead>
                    <TableHead className="text-white font-medium text-center">Fecha</TableHead>
                    <TableHead className="text-white font-medium text-center">Acciones</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {loading ? (
                    <TableRow>
                      <TableCell colSpan={8} className="text-center py-10 text-muted-foreground">
                        Cargando notas...
                      </TableCell>
                    </TableRow>
                  ) : historyFiltered.length === 0 ? (
                    <TableRow>
                      <TableCell colSpan={8} className="text-center py-10 text-muted-foreground">
                        No se encontraron notas registradas.
                      </TableCell>
                    </TableRow>
                  ) : (
                    historyFiltered.map((nota) => (
                      <TableRow key={nota.id} className="border-b border-white/[0.04] hover:bg-white/[0.01] transition-colors">
                        <TableCell className="font-mono text-accent-blue font-semibold">
                          #{String(nota.folio || '').padStart(5, '0')}
                        </TableCell>
                        <TableCell className="text-white font-medium">
                          {nota.cliente_nombre}
                        </TableCell>
                        <TableCell className="text-zinc-400 text-xs max-w-[200px] truncate">
                          {Array.isArray(nota.items) && nota.items.map(i => `${i.cantidad}x ${i.concepto}`).join(', ')}
                        </TableCell>
                        <TableCell className="text-center">
                          <Badge className={getUrgencyBadgeColor(nota.urgencia)}>
                            {nota.urgencia}
                          </Badge>
                        </TableCell>
                        <TableCell className="text-center">
                          <Badge className={getEstadoBadgeColor(nota.estado_taller)}>
                            {nota.estado_taller}
                          </Badge>
                        </TableCell>
                        <TableCell className="text-right text-white font-semibold">
                          ${nota.total.toFixed(2)}
                        </TableCell>
                        <TableCell className="text-center text-xs text-zinc-400">
                          {nota.created_at ? new Date(nota.created_at).toLocaleDateString() : '-'}
                        </TableCell>
                        <TableCell className="text-center">
                          <div className="flex justify-center items-center gap-1">
                            <Button
                              size="sm"
                              variant="ghost"
                              onClick={() => { setSelectedNota(nota); setIsTicketModalOpen(true); }}
                              className="text-accent-blue hover:text-accent-blue/80 hover:bg-accent-blue/10 p-2"
                              title="Ver Ticket"
                            >
                              <FileText className="h-4.5 w-4.5" />
                            </Button>
                            <Button
                              size="sm"
                              variant="ghost"
                              onClick={() => {
                                if (confirm('¿Estás seguro de eliminar esta nota?')) {
                                  if (nota.id) onEliminarNota(nota.id);
                                }
                              }}
                              className="text-accent-red hover:text-accent-red/80 hover:bg-accent-red/10 p-2"
                              title="Eliminar Nota"
                            >
                              <Trash2 className="h-4.5 w-4.5" />
                            </Button>
                          </div>
                        </TableCell>
                      </TableRow>
                    ))
                  )}
                </TableBody>
              </Table>
            </div>
          </div>
        </TabsContent>
      </Tabs>

      {/* Modal: Nueva Nota */}
      <Dialog open={isNewModalOpen} onOpenChange={setIsNewModalOpen}>
        <DialogContent className="sm:max-w-[600px] bg-zinc-950 border border-white/10 text-white">
          <DialogHeader>
            <DialogTitle className="text-white text-lg font-bold flex items-center gap-2">
              <ClipboardList className="h-5 w-5 text-accent-blue" />
              Nueva Nota Simple
            </DialogTitle>
          </DialogHeader>

          <form onSubmit={handleSaveNota} className="space-y-4 pt-2">
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div className="space-y-1.5">
                <Label htmlFor="cliente" className="text-zinc-300">Nombre del Cliente</Label>
                <Input
                  id="cliente"
                  required
                  placeholder="Ej. Juan Pérez"
                  value={clienteNombre}
                  onChange={(e) => setClienteNombre(e.target.value)}
                  className="bg-white/[0.04] border-white/10 text-white focus:ring-accent-blue"
                />
              </div>

              <div className="space-y-1.5">
                <Label htmlFor="urgencia" className="text-zinc-300">Nivel de Urgencia</Label>
                <select
                  id="urgencia"
                  value={urgencia}
                  onChange={(e) => setUrgencia(e.target.value as any)}
                  className="block w-full sm:text-sm rounded-md py-2 px-3 border border-white/10 bg-white/[0.04] text-white focus:outline-none focus:ring-accent-blue focus:border-accent-blue h-10"
                >
                  <option value="Baja" className="bg-zinc-900 text-white">Baja</option>
                  <option value="Media" className="bg-zinc-900 text-white">Media</option>
                  <option value="Alta" className="bg-zinc-900 text-white">Alta</option>
                  <option value="Urgente" className="bg-zinc-900 text-white">Urgente</option>
                </select>
              </div>

              <div className="space-y-1.5">
                <Label htmlFor="fecha" className="text-zinc-300">Fecha Límite de Entrega</Label>
                <Input
                  id="fecha"
                  type="datetime-local"
                  value={fechaEntrega}
                  onChange={(e) => setFechaEntrega(e.target.value)}
                  className="bg-white/[0.04] border-white/10 text-white focus:ring-accent-blue h-10 block"
                />
              </div>

              <div className="space-y-1.5">
                <Label htmlFor="vendedor" className="text-zinc-300">Registrado Por</Label>
                <Input
                  id="vendedor"
                  placeholder="Vendedor"
                  value={vendedorNombre}
                  onChange={(e) => setVendedorNombre(e.target.value)}
                  className="bg-white/[0.04] border-white/10 text-white focus:ring-accent-blue"
                />
              </div>
            </div>

            {/* Conceptos List */}
            <div className="space-y-3 pt-3 border-t border-white/[0.06]">
              <div className="flex justify-between items-center">
                <h4 className="text-sm font-semibold text-white">Conceptos de Venta</h4>
                <Button 
                  type="button" 
                  size="sm" 
                  onClick={handleAddItem}
                  className="bg-accent-blue/10 hover:bg-accent-blue/20 text-accent-blue text-xs font-semibold"
                >
                  + Agregar Concepto
                </Button>
              </div>

              <div className="space-y-2 overflow-visible pr-1">
                {items.map((item, index) => (
                  <div key={index} className="flex gap-2 items-center">
                    <div className="flex-1 relative">
                      <Input
                        required={index === 0}
                        placeholder="Ej. DTF Lona Metro / Taza"
                        value={item.concepto}
                        onChange={(e) => {
                          handleItemChange(index, 'concepto', e.target.value);
                          setActiveItemSuggestIndex(index);
                        }}
                        onFocus={() => setActiveItemSuggestIndex(index)}
                        onBlur={() => setTimeout(() => setActiveItemSuggestIndex(null), 250)}
                        className="bg-white/[0.04] border-white/10 text-white text-sm w-full"
                      />
                      {activeItemSuggestIndex === index && (
                        <div className="absolute z-[100] left-0 right-0 mt-1 bg-zinc-950 border border-white/10 rounded-md shadow-2xl max-h-48 overflow-y-auto backdrop-blur-md">
                          {(productos || [])
                            .filter(p => p.nombre.toLowerCase().includes(item.concepto.toLowerCase()))
                            .slice(0, 5)
                            .map(p => (
                              <button
                                key={p.id}
                                type="button"
                                onMouseDown={() => {
                                  handleItemChange(index, 'concepto', p.nombre);
                                  handleItemChange(index, 'precio', p.precio_unitario || 0);
                                  setActiveItemSuggestIndex(null);
                                }}
                                className="w-full text-left px-3 py-2 text-xs text-white hover:bg-white/[0.06] flex justify-between items-center transition-colors border-b border-white/[0.03] last:border-0"
                              >
                                <span className="font-medium truncate mr-2">{p.nombre}</span>
                                <span className="text-accent-blue font-semibold shrink-0">${(p.precio_unitario || 0).toFixed(2)}</span>
                              </button>
                            ))}
                          {productos.filter(p => p.nombre.toLowerCase().includes(item.concepto.toLowerCase())).length === 0 && (
                            <div className="px-3 py-2 text-xs text-zinc-500 italic">No hay productos coincidentes</div>
                          )}
                        </div>
                      )}
                    </div>
                    <div className="w-20">
                      <Input
                        type="number"
                        min="1"
                        required
                        placeholder="Cant"
                        value={item.cantidad}
                        onChange={(e) => handleItemChange(index, 'cantidad', e.target.value)}
                        className="bg-white/[0.04] border-white/10 text-white text-sm"
                      />
                    </div>
                    <div className="w-24">
                      <Input
                        type="number"
                        min="0"
                        required
                        placeholder="Precio"
                        value={item.precio}
                        onChange={(e) => handleItemChange(index, 'precio', e.target.value)}
                        className="bg-white/[0.04] border-white/10 text-white text-sm"
                      />
                    </div>
                    <div className="w-24 text-right pr-2 text-sm text-white font-medium">
                      ${item.total.toFixed(2)}
                    </div>
                    <Button
                      type="button"
                      variant="ghost"
                      onClick={() => handleRemoveItem(index)}
                      disabled={items.length === 1}
                      className="text-zinc-500 hover:text-accent-red p-2"
                    >
                      <Trash2 className="h-4 w-4" />
                    </Button>
                  </div>
                ))}
              </div>
            </div>

            {/* Total Row */}
            <div className="flex justify-between items-center pt-3 border-t border-white/[0.06]">
              <span className="text-zinc-400 font-medium text-sm">Suma Total:</span>
              <span className="text-xl font-bold text-white">${calculateTotal().toFixed(2)}</span>
            </div>

            <DialogFooter className="pt-2">
              <Button 
                type="button" 
                variant="outline" 
                onClick={() => setIsNewModalOpen(false)}
                className="border-white/10 text-white hover:bg-white/5"
              >
                Cancelar
              </Button>
              <Button type="submit" className="bg-accent-blue hover:bg-accent-blue/80 text-white">
                Guardar y Ver Ticket
              </Button>
            </DialogFooter>
          </form>
        </DialogContent>
      </Dialog>

      {/* Modal: Ver Ticket */}
      <Dialog open={isTicketModalOpen} onOpenChange={setIsTicketModalOpen}>
        <DialogContent className={formatType === 'nota' ? "sm:max-w-[800px] bg-zinc-950 border border-white/10 text-white flex flex-col items-center" : "sm:max-w-[440px] bg-zinc-950 border border-white/10 text-white flex flex-col items-center"}>
          <DialogHeader className="w-full pb-2 border-b border-white/[0.06] mb-2">
            <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center w-full gap-2 pr-8">
              <DialogTitle className="text-white text-lg font-bold flex items-center gap-2">
                <FileText className="h-5 w-5 text-accent-blue" />
                Visualizador de Nota
              </DialogTitle>
              <div className="flex bg-white/[0.04] p-0.5 rounded border border-white/10 gap-0.5">
                <button
                  type="button"
                  onClick={() => setFormatType('nota')}
                  className={`px-2.5 py-1 text-[11px] font-semibold rounded transition-colors ${
                    formatType === 'nota'
                      ? 'bg-accent-blue text-white'
                      : 'text-zinc-400 hover:text-white'
                  }`}
                >
                  Nota Premium
                </button>
                <button
                  type="button"
                  onClick={() => setFormatType('ticket')}
                  className={`px-2.5 py-1 text-[11px] font-semibold rounded transition-colors ${
                    formatType === 'ticket'
                      ? 'bg-accent-blue text-white'
                      : 'text-zinc-400 hover:text-white'
                  }`}
                >
                  Ticket Térmico
                </button>
              </div>
            </div>
          </DialogHeader>

          {/* Ticket paper preview wrapper */}
          <div className="bg-zinc-900 p-6 rounded-lg border border-white/10 w-full flex justify-center items-center shadow-inner my-2">
            {/* Visual canvas representation */}
            <canvas 
              ref={setCanvasNode} 
              width={formatType === 'nota' ? 1240 : 380}
              className="border border-zinc-300 rounded shadow-md max-w-full"
              style={{ 
                display: 'block', 
                backgroundColor: '#FFFFFF',
                width: formatType === 'nota' ? '100%' : '380px'
              }}
            />
          </div>

          <DialogFooter className="w-full grid grid-cols-3 gap-2 mt-2">
            <Button 
              type="button" 
              onClick={handleSendWhatsApp}
              className="bg-[#25D366] hover:bg-[#20ba56] text-white font-medium flex items-center justify-center gap-1.5 py-2.5 rounded"
            >
              <MessageSquare className="h-4.5 w-4.5" />
              WhatsApp
            </Button>
            
            <Button 
              type="button" 
              onClick={handleDownloadTicket}
              className="bg-accent-blue hover:bg-accent-blue/80 text-white font-medium flex items-center justify-center gap-1.5 py-2.5 rounded"
            >
              <Download className="h-4.5 w-4.5" />
              Imagen
            </Button>

            <Button 
              type="button" 
              onClick={handlePrint}
              className="bg-zinc-800 hover:bg-zinc-700 border border-white/10 text-white font-medium flex items-center justify-center gap-1.5 py-2.5 rounded"
            >
              <Printer className="h-4.5 w-4.5" />
              Imprimir
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
};
