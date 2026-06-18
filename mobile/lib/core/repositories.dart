import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_client.dart';
import '../models/models.dart';

/// Lista pública de torneos publicados.
final tournamentsProvider = FutureProvider<List<Tournament>>((ref) async {
  final data = await ref.read(apiClientProvider).get('/tournaments') as List;
  return data.map((t) => Tournament.fromJson(t as Map<String, dynamic>)).toList();
});

/// Admin: TODOS los torneos, incluidos borradores (no publicados).
final adminTournamentsProvider = FutureProvider<List<Tournament>>((ref) async {
  final data = await ref.read(apiClientProvider).get('/tournaments/all') as List;
  return data.map((t) => Tournament.fromJson(t as Map<String, dynamic>)).toList();
});

/// Detalle de un torneo (incluye categorías y sedes).
final tournamentProvider = FutureProvider.family<Tournament, String>((ref, id) async {
  final data = await ref.read(apiClientProvider).get('/tournaments/$id') as Map<String, dynamic>;
  return Tournament.fromJson(data);
});

/// Partidos de una categoría (calendario + resultados).
final matchesProvider = FutureProvider.family<List<Match>, String>((ref, categoryId) async {
  final data = await ref.read(apiClientProvider).get('/matches', query: {'categoryId': categoryId}) as List;
  return data.map((m) => Match.fromJson(m as Map<String, dynamic>)).toList();
});

/// Tabla de posiciones de una categoría.
final standingsProvider = FutureProvider.family<List<Standing>, String>((ref, categoryId) async {
  final data = await ref.read(apiClientProvider).get('/standings/category/$categoryId') as List;
  return data.map((s) => Standing.fromJson(s as Map<String, dynamic>)).toList();
});

/// Equipos de una categoría (para gestión admin y consulta pública).
final teamsByCategoryProvider = FutureProvider.family<List<TeamRef>, String>((ref, categoryId) async {
  final data = await ref.read(apiClientProvider).get('/teams', query: {'categoryId': categoryId}) as List;
  return data.map((t) => TeamRef.fromJson(t as Map<String, dynamic>)).toList();
});

/// Admin: lista de árbitros (perfiles). autoDispose → siempre datos frescos al entrar.
final refereesProvider = FutureProvider.autoDispose<List<RefereeRef>>((ref) async {
  final data = await ref.read(apiClientProvider).get('/referees') as List;
  return data.map((r) => RefereeRef.fromJson(r as Map<String, dynamic>)).toList();
});

/// Admin: árbitros asignados a un partido (nombres).
final matchAssignmentsProvider = FutureProvider.family<List<String>, String>((ref, matchId) async {
  final data = await ref.read(apiClientProvider).get('/referees/matches/$matchId') as List;
  return data
      .map((a) => (a['referee']?['user']?['fullName'] as String?) ?? 'Árbitro')
      .toList();
});

/// Admin: inscripciones por estado (PENDING/ACCEPTED/REJECTED). autoDispose → fresco.
final registrationsProvider = FutureProvider.autoDispose.family<List<dynamic>, String>((ref, status) async {
  final data = await ref.read(apiClientProvider).get('/registrations', query: {'status': status}) as List;
  return data;
});

/// Partidos asignados al árbitro autenticado.
final assignedMatchesProvider = FutureProvider<List<Match>>((ref) async {
  final data = await ref.read(apiClientProvider).get('/matches/assigned/me') as List;
  return data.map((m) => Match.fromJson(m as Map<String, dynamic>)).toList();
});
