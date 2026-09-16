import { Document, Page, Text, View, StyleSheet, Font } from '@react-pdf/renderer';
import { Presupuesto, Cliente } from '../../types';

const styles = StyleSheet.create({
  page: {
    padding: 24,
    fontSize: 8,
    fontFamily: 'Helvetica',
    backgroundColor: '#ffffff'
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    borderBottomWidth: 1.5,
    borderBottomColor: '#c7cdd6',
    paddingBottom: 10,
    marginBottom: 10
  },
  headerCol: {
    width: '45%'
  },
  fieldRow: {
    flexDirection: 'row',
    marginBottom: 4
  },
  label: {
    fontWeight: 'bold',
    marginRight: 4,
    fontFamily: 'Helvetica-Bold'
  },
  folio: {
    fontSize: 12,
    fontWeight: 'bold',
    color: '#3a6ea5',
    marginBottom: 4,
    fontFamily: 'Helvetica-Bold'
  },
  concepto: {
    backgroundColor: '#dce9f5',
    borderWidth: 1,
    borderColor: '#c7cdd6',
    borderRadius: 4,
    padding: 8,
    marginBottom: 14,
    lineHeight: 1.4
  },
  grid: {
    flexDirection: 'row',
    justifyContent: 'space-between'
  },
  col: {
    width: '48.5%'
  },
  block: {
    borderWidth: 1,
    borderColor: '#c7cdd6',
    borderRadius: 4,
    marginBottom: 12,
    overflow: 'hidden'
  },
  blockHeader: {
    padding: 4,
    fontSize: 8,
    fontFamily: 'Helvetica-Bold',
    textTransform: 'uppercase',
    borderBottomWidth: 1,
    borderBottomColor: '#c7cdd6'
  },
  bgBlue: { backgroundColor: '#253347', color: 'white' },
  bgGreen: { backgroundColor: '#223a2c', color: 'white' },
  bgTeal: { backgroundColor: '#1f3a38', color: 'white' },
  bgGray: { backgroundColor: '#2a303a', color: 'white' },
  tableRow: {
    flexDirection: 'row',
    borderBottomWidth: 1,
    borderBottomColor: '#e4e7eb',
    paddingVertical: 3,
    paddingHorizontal: 4
  },
  tableHeader: {
    backgroundColor: '#f8fafc',
    fontFamily: 'Helvetica-Bold'
  },
  colPzas: { width: '15%' },
  colMat: { width: '55%' },
  colCu: { width: '15%', textAlign: 'right', color: '#5b6472' },
  colImp: { width: '15%', textAlign: 'right', color: '#5b6472' },
  tableTotal: {
    flexDirection: 'row',
    borderTopWidth: 1,
    borderTopColor: '#c7cdd6',
    paddingVertical: 4,
    paddingHorizontal: 4,
    backgroundColor: '#f1f5f9',
    fontFamily: 'Helvetica-Bold'
  },
  grandTotals: {
    marginTop: 10,
    borderWidth: 1,
    borderColor: '#c7cdd6',
    borderRadius: 4
  },
  grandRow: {
    flexDirection: 'row',
    padding: 6
  },
  grandLabel: {
    width: '70%',
    fontFamily: 'Helvetica-Bold',
    fontSize: 9
  },
  grandValue: {
    width: '30%',
    textAlign: 'right',
    fontFamily: 'Helvetica-Bold',
    fontSize: 9
  }
});

interface Props {
  presupuesto: Presupuesto;
  cliente?: Cliente;
}

export function PresupuestoPDF({ presupuesto, cliente }: Props) {
  const d = presupuesto.datos;

  const renderTable = (titulo: string, sec: any, bg: any) => (
    <View style={styles.block}>
      <View style={[styles.blockHeader, bg]}>
        <Text>{titulo}</Text>
      </View>
      <View style={[styles.tableRow, styles.tableHeader]}>
        <Text style={styles.colPzas}>PZAS</Text>
        <Text style={styles.colMat}>MATERIAL</Text>
        <Text style={styles.colCu}>$ C/U</Text>
        <Text style={styles.colImp}>IMPORTE</Text>
      </View>
      {sec.items.filter((i:any) => i.material.trim() !== '' || i.importe > 0).map((item: any, idx: number) => (
        <View key={idx} style={styles.tableRow}>
          <Text style={styles.colPzas}>{item.pzas}</Text>
          <Text style={styles.colMat}>{item.material}</Text>
          <Text style={styles.colCu}>{item.cu > 0 ? \`\$\${item.cu.toLocaleString()}\` : ''}</Text>
          <Text style={styles.colImp}>{item.importe > 0 ? \`\$\${item.importe.toLocaleString(undefined, { minimumFractionDigits: 2 })}\` : ''}</Text>
        </View>
      ))}
      <View style={styles.tableTotal}>
        <Text style={{ width: '85%', textAlign: 'right', paddingRight: 10 }}>TOTAL</Text>
        <Text style={{ width: '15%', textAlign: 'right' }}>\${(sec.total || 0).toLocaleString(undefined, { minimumFractionDigits: 2 })}</Text>
      </View>
    </View>
  );

  const nombreCliente = cliente ? (cliente.nombre_comercial || cliente.razon_social) : 'A QUIEN CORRESPONDA';

  return (
    <Document>
      <Page size="LETTER" style={styles.page}>
        <View style={styles.header}>
          <View style={styles.headerCol}>
            <View style={styles.fieldRow}>
              <Text style={styles.label}>FECHA:</Text>
              <Text>{new Date(presupuesto.fecha).toLocaleDateString()}</Text>
            </View>
            <View style={styles.fieldRow}>
              <Text style={styles.label}>CLIENTE:</Text>
              <Text>{nombreCliente}</Text>
            </View>
          </View>
          <View style={[styles.headerCol, { alignItems: 'flex-end' }]}>
            <Text style={styles.folio}>{presupuesto.nomenclatura_id || presupuesto.folio}</Text>
            <View style={styles.fieldRow}>
              <Text style={styles.label}>NO. FOLIO:</Text>
              <Text>{presupuesto.folio}</Text>
            </View>
          </View>
        </View>

        {presupuesto.concepto && (
          <View style={styles.concepto}>
            <Text style={[styles.label, { marginBottom: 4 }]}>CONCEPTO:</Text>
            <Text>{presupuesto.concepto}</Text>
          </View>
        )}

        <View style={styles.grid}>
          <View style={styles.col}>
            {renderTable('Acero', d.acero, styles.bgBlue)}
            {renderTable('Pirámide', d.piramide, styles.bgBlue)}
            {renderTable('Truckzone', d.truckzone, styles.bgBlue)}
          </View>
          <View style={styles.col}>
            {renderTable('Otros', d.otros, styles.bgGreen)}
            {renderTable('Piso', d.piso, styles.bgGreen)}
            {renderTable('Extras', d.extras, styles.bgTeal)}
            {renderTable('Rines y Llantas', d.rines, styles.bgTeal)}
            {renderTable('Mano de Obra', d.manoobra, styles.bgGreen)}
            {renderTable('Adicionales', d.adicionales, styles.bgGray)}
            {renderTable('Gastos Indirectos', d.indirectos, styles.bgGray)}
          </View>
        </View>

        <View style={styles.grandTotals}>
          <View style={[styles.grandRow, { backgroundColor: '#f1f5f9', borderBottomWidth: 1, borderBottomColor: '#c7cdd6' }]}>
            <Text style={styles.grandLabel}>TOTAL (COSTO):</Text>
            <Text style={styles.grandValue}>\${(presupuesto.total_costo || 0).toLocaleString(undefined, { minimumFractionDigits: 2 })}</Text>
          </View>
          <View style={[styles.grandRow, { backgroundColor: '#dce9f5' }]}>
            <Text style={[styles.grandLabel, { fontSize: 11 }]}>PRECIO DE VENTA:</Text>
            <Text style={[styles.grandValue, { fontSize: 11 }]}>\${(presupuesto.precio_venta || 0).toLocaleString(undefined, { minimumFractionDigits: 2 })}</Text>
          </View>
        </View>
      </Page>
    </Document>
  );
}
