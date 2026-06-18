import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/repositories.dart';
import '../../models/models.dart';
import '../../widgets/app_scaffold.dart';

/// Categoría con dos pestañas: Calendario/Resultados y Tabla de posiciones.
class CategoryScreen extends ConsumerWidget {
  const CategoryScreen({super.key, required this.categoryId});
  final String categoryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: AppScaffold(
        title: 'Categoría',
        showBack: true,
        bottom: const TabBar(
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: [
            Tab(text: 'Partidos', icon: Icon(Icons.sports_volleyball)),
            Tab(text: 'Posiciones', icon: Icon(Icons.leaderboard)),
          ],
        ),
        body: TabBarView(children: [
          _MatchesTab(categoryId: categoryId),
          _StandingsTab(categoryId: categoryId),
        ]),
      ),
    );
  }
}

class _MatchesTab extends ConsumerWidget {
  const _MatchesTab({required this.categoryId});
  final String categoryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matches = ref.watch(matchesProvider(categoryId));
    final df = DateFormat('d MMM HH:mm', 'es');

    return matches.when(
      loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
      error: (e, _) => const Center(
          child: Text('Error al cargar partidos', style: TextStyle(color: Colors.white))),
      data: (list) => RefreshIndicator(
        onRefresh: () async => ref.invalidate(matchesProvider(categoryId)),
        child: ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: list.length,
          itemBuilder: (_, i) {
            final m = list[i];
            return Card(
              child: ListTile(
                title: Text('${m.homeTeam?.name ?? "?"}  vs  ${m.awayTeam?.name ?? "?"}'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(m.scheduledAt != null ? df.format(m.scheduledAt!) : 'Por programar'),
                    if (m.court != null)
                      Row(children: [
                        const Icon(Icons.place, size: 14, color: Colors.blueGrey),
                        const SizedBox(width: 2),
                        Expanded(child: Text(m.court!.label, style: const TextStyle(fontSize: 12, color: Colors.blueGrey))),
                      ]),
                  ],
                ),
                isThreeLine: m.court != null,
                trailing: _StatusChip(match: m),
                onTap: () => context.go('/match/${m.id}'),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.match});
  final Match match;

  @override
  Widget build(BuildContext context) {
    if (match.isFinished) {
      return Chip(
        label: Text('${match.homeSetsWon}-${match.awaySetsWon}'),
        backgroundColor: Colors.grey.shade200,
      );
    }
    if (match.isLive) {
      return Chip(
        avatar: const Icon(Icons.circle, color: Colors.red, size: 12),
        label: Text('${match.homeSetsWon}-${match.awaySetsWon} EN VIVO'),
        backgroundColor: Colors.red.shade50,
      );
    }
    return const Chip(label: Text('Programado'));
  }
}

class _StandingsTab extends ConsumerWidget {
  const _StandingsTab({required this.categoryId});
  final String categoryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final standings = ref.watch(standingsProvider(categoryId));

    return standings.when(
      loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
      error: (e, _) => const Center(
          child: Text('Error al cargar la tabla', style: TextStyle(color: Colors.white))),
      data: (rows) => SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Card(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
            DataColumn(label: Text('#')),
            DataColumn(label: Text('Equipo')),
            DataColumn(label: Text('PJ'), numeric: true),
            DataColumn(label: Text('PG'), numeric: true),
            DataColumn(label: Text('PP'), numeric: true),
            DataColumn(label: Text('Sets'), numeric: true),
            DataColumn(label: Text('Pts'), numeric: true),
          ],
          rows: rows
              .map((s) => DataRow(cells: [
                    DataCell(Text('${s.rank ?? "-"}')),
                    DataCell(Text(s.teamName)),
                    DataCell(Text('${s.played}')),
                    DataCell(Text('${s.won}')),
                    DataCell(Text('${s.lost}')),
                    DataCell(Text('${s.setsFor}-${s.setsAgainst}')),
                    DataCell(Text('${s.points}', style: const TextStyle(fontWeight: FontWeight.bold))),
                  ]))
              .toList(),
            ),
          ),
        ),
      ),
    );
  }
}
