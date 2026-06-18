import { toCsv, csvEscape } from './formatters/csv.formatter';
import { ReportTable } from './report-table';

describe('csv.formatter', () => {
  it('escapa valores con comas, comillas y saltos de línea', () => {
    expect(csvEscape('simple')).toBe('simple');
    expect(csvEscape('a,b')).toBe('"a,b"');
    expect(csvEscape('dice "hola"')).toBe('"dice ""hola"""');
    expect(csvEscape(42)).toBe('42');
  });

  it('serializa una tabla a CSV con cabecera y filas', () => {
    const table: ReportTable = {
      title: 'Posiciones',
      headers: ['#', 'Equipo', 'Pts'],
      rows: [
        [1, 'Tiburones', 3],
        [2, 'Club, S.A.', 0],
      ],
    };
    const csv = toCsv(table);
    const lines = csv.split('\r\n');
    expect(lines[0]).toBe('#,Equipo,Pts');
    expect(lines[1]).toBe('1,Tiburones,3');
    expect(lines[2]).toBe('2,"Club, S.A.",0'); // coma escapada
  });
});
