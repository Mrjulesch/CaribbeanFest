import { ReportTable } from '../report-table';

/** Escapa un valor para CSV (RFC 4180): comillas dobles si contiene , " o salto. */
export function csvEscape(value: string | number): string {
  const s = String(value);
  if (/[",\n\r]/.test(s)) {
    return `"${s.replace(/"/g, '""')}"`;
  }
  return s;
}

/** Serializa una tabla de reporte a CSV. Puro y testeable. */
export function toCsv(table: ReportTable): string {
  const lines: string[] = [];
  lines.push(table.headers.map(csvEscape).join(','));
  for (const row of table.rows) {
    lines.push(row.map(csvEscape).join(','));
  }
  return lines.join('\r\n');
}
