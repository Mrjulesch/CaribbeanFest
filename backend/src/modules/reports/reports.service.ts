import { BadRequestException, Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { StandingsService } from '../standings/standings.service';
import { StatsService } from '../stats/stats.service';
import { ReportFormat, ReportTable, RenderedReport } from './report-table';
import { toCsv } from './formatters/csv.formatter';
import { toExcel } from './formatters/excel.formatter';
import { toPdf } from './formatters/pdf.formatter';

export type ReportKind = 'standings' | 'results' | 'teams' | 'players' | 'stats';

@Injectable()
export class ReportsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly standings: StandingsService,
    private readonly stats: StatsService,
  ) {}

  /** Punto de entrada: arma la tabla del reporte y la renderiza al formato pedido. */
  async generate(kind: ReportKind, categoryId: string, format: ReportFormat): Promise<RenderedReport> {
    const table = await this.buildTable(kind, categoryId);
    return this.render(table, format, `${kind}-${categoryId}`);
  }

  private async buildTable(kind: ReportKind, categoryId: string): Promise<ReportTable> {
    switch (kind) {
      case 'standings':
        return this.standingsTable(categoryId);
      case 'results':
        return this.resultsTable(categoryId);
      case 'teams':
        return this.teamsTable(categoryId);
      case 'players':
        return this.playersTable(categoryId);
      case 'stats':
        return this.statsTable(categoryId);
    }
  }

  private async standingsTable(categoryId: string): Promise<ReportTable> {
    const rows = await this.standings.forCategory(categoryId);
    return {
      title: 'Tabla de posiciones',
      headers: ['#', 'Equipo', 'PJ', 'PG', 'PP', 'Pts', 'SF', 'SC', 'Dif'],
      rows: rows.map((s, i) => [
        s.rank ?? i + 1,
        s.team.name,
        s.played,
        s.won,
        s.lost,
        s.points,
        s.setsFor,
        s.setsAgainst,
        s.setsFor - s.setsAgainst,
      ]),
    };
  }

  private async resultsTable(categoryId: string): Promise<ReportTable> {
    const matches = await this.prisma.match.findMany({
      where: { categoryId },
      include: {
        homeTeam: { select: { name: true } },
        awayTeam: { select: { name: true } },
        court: { select: { name: true } },
      },
      orderBy: { scheduledAt: 'asc' },
    });
    return {
      title: 'Resultados y calendario',
      headers: ['Fecha', 'Local', 'Visitante', 'Sets', 'Cancha', 'Estado'],
      rows: matches.map((m) => [
        m.scheduledAt ? new Date(m.scheduledAt).toLocaleString('es') : '—',
        m.homeTeam?.name ?? '?',
        m.awayTeam?.name ?? '?',
        `${m.homeSetsWon}-${m.awaySetsWon}`,
        m.court?.name ?? '—',
        m.status,
      ]),
    };
  }

  private async teamsTable(categoryId: string): Promise<ReportTable> {
    const teams = await this.prisma.team.findMany({
      where: { categoryId },
      include: { club: { select: { name: true, city: true, country: true } }, _count: { select: { players: true } } },
      orderBy: { name: 'asc' },
    });
    return {
      title: 'Equipos inscritos',
      headers: ['Equipo', 'Club', 'Ciudad', 'País', 'Entrenador', 'Jugadores'],
      rows: teams.map((t) => [
        t.name,
        t.club.name,
        t.club.city ?? '—',
        t.club.country ?? '—',
        t.coachName ?? '—',
        t._count.players,
      ]),
    };
  }

  private async playersTable(categoryId: string): Promise<ReportTable> {
    const players = await this.prisma.player.findMany({
      where: { team: { categoryId } },
      include: { team: { select: { name: true } } },
      orderBy: [{ team: { name: 'asc' } }, { jerseyNumber: 'asc' }],
    });
    return {
      title: 'Jugadores',
      headers: ['Nombre', 'Equipo', 'Dorsal', 'Posición', 'Estatura', 'Documento'],
      rows: players.map((p) => [
        p.fullName,
        p.team.name,
        p.jerseyNumber ?? '—',
        p.position ?? '—',
        p.heightCm ? `${p.heightCm} cm` : '—',
        p.document ?? '—',
      ]),
    };
  }

  private async statsTable(categoryId: string): Promise<ReportTable> {
    const stats = await this.stats.playerStats(categoryId);
    return {
      title: 'Estadísticas por jugador',
      headers: ['Jugador', 'Equipo', 'Pts', 'Ataques', 'Bloqueos', 'Aces', 'Errores', 'MVP'],
      rows: stats.map((s) => [
        s.playerName ?? '—',
        s.teamName ?? '—',
        s.points,
        s.attacks,
        s.blocks,
        s.aces,
        s.errors,
        s.mvpScore,
      ]),
    };
  }

  private async render(table: ReportTable, format: ReportFormat, slug: string): Promise<RenderedReport> {
    switch (format) {
      case 'csv':
        return {
          buffer: Buffer.from('﻿' + toCsv(table), 'utf8'), // BOM para acentos en Excel
          contentType: 'text/csv; charset=utf-8',
          filename: `${slug}.csv`,
        };
      case 'xlsx':
        return {
          buffer: await toExcel(table),
          contentType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
          filename: `${slug}.xlsx`,
        };
      case 'pdf':
        return {
          buffer: await toPdf(table),
          contentType: 'application/pdf',
          filename: `${slug}.pdf`,
        };
      default:
        throw new BadRequestException('Formato no soportado (csv | xlsx | pdf)');
    }
  }
}
