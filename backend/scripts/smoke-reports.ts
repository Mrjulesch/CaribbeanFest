import { toCsv } from '../src/modules/reports/formatters/csv.formatter';
import { toExcel } from '../src/modules/reports/formatters/excel.formatter';
import { toPdf } from '../src/modules/reports/formatters/pdf.formatter';

const table = {
  title: 'Tabla de posiciones',
  headers: ['#', 'Equipo', 'Pts'],
  rows: [
    [1, 'Tiburones', 3],
    [2, 'Huracanes', 0],
  ],
};

(async () => {
  const csv = Buffer.from(toCsv(table));
  const xlsx = await toExcel(table);
  const pdf = await toPdf(table);
  console.log('CSV  bytes:', csv.length, '| 1ª línea:', toCsv(table).split('\r\n')[0]);
  console.log('XLSX bytes:', xlsx.length, '| magic:', xlsx.subarray(0, 2).toString(), '(PK = zip/xlsx OK)');
  console.log('PDF  bytes:', pdf.length, '| magic:', pdf.subarray(0, 5).toString(), '(%PDF OK)');
})();
