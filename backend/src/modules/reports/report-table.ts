/** Estructura genérica de un reporte tabular. Todos los formateadores la consumen. */
export interface ReportTable {
  title: string;
  headers: string[];
  rows: (string | number)[][];
}

export type ReportFormat = 'csv' | 'xlsx' | 'pdf';

export interface RenderedReport {
  buffer: Buffer;
  contentType: string;
  filename: string;
}
