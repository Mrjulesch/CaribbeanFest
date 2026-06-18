import { Workbook } from 'exceljs';
import { ReportTable } from '../report-table';

/** Genera un .xlsx con una hoja, fila de cabecera en negrita y autoajuste básico. */
export async function toExcel(table: ReportTable): Promise<Buffer> {
  const wb = new Workbook();
  wb.creator = 'Caribbean Fest';
  const ws = wb.addWorksheet(table.title.slice(0, 31)); // límite de nombre de hoja

  const header = ws.addRow(table.headers);
  header.font = { bold: true };
  header.eachCell((cell) => {
    cell.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FFE6F0FA' } };
  });

  for (const row of table.rows) ws.addRow(row);

  // Ancho de columna según el contenido más largo.
  ws.columns.forEach((col, i) => {
    const widths = [table.headers[i]?.length ?? 10, ...table.rows.map((r) => String(r[i] ?? '').length)];
    col.width = Math.min(40, Math.max(...widths) + 2);
  });

  const arrayBuffer = await wb.xlsx.writeBuffer();
  return Buffer.from(arrayBuffer);
}
