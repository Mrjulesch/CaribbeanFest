import PDFDocument from 'pdfkit';
import { ReportTable } from '../report-table';

/** Renderiza una tabla de reporte a PDF (título + cabecera + filas con zebra). */
export function toPdf(table: ReportTable): Promise<Buffer> {
  return new Promise((resolve, reject) => {
    const doc = new PDFDocument({ size: 'A4', margin: 40 });
    const chunks: Buffer[] = [];
    doc.on('data', (c) => chunks.push(c as Buffer));
    doc.on('end', () => resolve(Buffer.concat(chunks)));
    doc.on('error', reject);

    // Encabezado
    doc.fontSize(18).fillColor('#0066CC').text('Caribbean Fest', { continued: false });
    doc.moveDown(0.2);
    doc.fontSize(14).fillColor('#000').text(table.title);
    doc.moveDown(0.5);
    doc.fontSize(8).fillColor('#666').text(`Generado: ${new Date().toLocaleString('es')}`);
    doc.moveDown(0.8);

    const startX = doc.page.margins.left;
    const usableW = doc.page.width - doc.page.margins.left - doc.page.margins.right;
    const colW = usableW / table.headers.length;
    const rowH = 20;
    let y = doc.y;

    const drawRow = (cells: (string | number)[], opts: { bold?: boolean; fill?: string }) => {
      if (y + rowH > doc.page.height - doc.page.margins.bottom) {
        doc.addPage();
        y = doc.page.margins.top;
      }
      if (opts.fill) {
        doc.rect(startX, y, usableW, rowH).fill(opts.fill);
      }
      doc.fillColor('#000').fontSize(9);
      doc.font(opts.bold ? 'Helvetica-Bold' : 'Helvetica');
      cells.forEach((c, i) => {
        doc.text(String(c), startX + i * colW + 4, y + 6, { width: colW - 8, ellipsis: true });
      });
      y += rowH;
    };

    drawRow(table.headers, { bold: true, fill: '#E6F0FA' });
    table.rows.forEach((row, i) => drawRow(row, { fill: i % 2 === 1 ? '#F7F7F7' : undefined }));

    doc.end();
  });
}
