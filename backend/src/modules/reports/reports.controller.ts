import { BadRequestException, Controller, Get, Param, Query, StreamableFile } from '@nestjs/common';
import { Role } from '@prisma/client';
import { ReportsService, ReportKind } from './reports.service';
import { ReportFormat } from './report-table';
import { Roles } from '../../common/decorators/roles.decorator';

const KINDS: ReportKind[] = ['standings', 'results', 'teams', 'players', 'stats'];
const FORMATS: ReportFormat[] = ['csv', 'xlsx', 'pdf'];

@Controller('reports')
export class ReportsController {
  constructor(private readonly reports: ReportsService) {}

  /**
   * Descarga un reporte de una categoría.
   *   GET /reports/category/:categoryId/standings?format=pdf
   * kinds: standings | results | teams | players | stats
   * format: csv | xlsx | pdf
   */
  @Roles(Role.ADMIN)
  @Get('category/:categoryId/:kind')
  async report(
    @Param('categoryId') categoryId: string,
    @Param('kind') kind: string,
    @Query('format') format = 'pdf',
  ): Promise<StreamableFile> {
    if (!KINDS.includes(kind as ReportKind)) {
      throw new BadRequestException(`Reporte inválido. Opciones: ${KINDS.join(', ')}`);
    }
    if (!FORMATS.includes(format as ReportFormat)) {
      throw new BadRequestException(`Formato inválido. Opciones: ${FORMATS.join(', ')}`);
    }

    const r = await this.reports.generate(kind as ReportKind, categoryId, format as ReportFormat);
    return new StreamableFile(r.buffer, {
      type: r.contentType,
      disposition: `attachment; filename="${r.filename}"`,
    });
  }
}
