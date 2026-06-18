import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/auth_controller.dart';
import '../features/public/tournaments_screen.dart';
import '../features/public/tournament_detail_screen.dart';
import '../features/public/category_screen.dart';
import '../features/public/live_match_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/referee/assigned_matches_screen.dart';
import '../features/referee/scoring_screen.dart';
import '../features/admin/admin_dashboard_screen.dart';
import '../features/admin/admin_manage_screen.dart';
import '../features/admin/admin_teams_screen.dart';
import '../features/admin/admin_matches_screen.dart';
import '../features/admin/admin_referees_screen.dart';
import '../features/admin/admin_registrations_screen.dart';
import '../features/public/register_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (_, __) => const TournamentsScreen()),
      GoRoute(
        path: '/tournament/:id',
        builder: (_, s) => TournamentDetailScreen(tournamentId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/category/:id',
        builder: (_, s) => CategoryScreen(categoryId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/match/:id',
        builder: (_, s) => LiveMatchScreen(matchId: s.pathParameters['id']!),
      ),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/inscripcion', builder: (_, __) => const RegisterScreen()),
      GoRoute(
        path: '/referee',
        builder: (_, __) => const RoleGuard(role: 'REFEREE', child: AssignedMatchesScreen()),
      ),
      GoRoute(
        path: '/referee/score/:id',
        builder: (_, s) =>
            RoleGuard(role: 'REFEREE', child: ScoringScreen(matchId: s.pathParameters['id']!)),
      ),
      GoRoute(
        path: '/admin',
        builder: (_, __) => const RoleGuard(role: 'ADMIN', child: AdminDashboardScreen()),
      ),
      GoRoute(
        path: '/admin/tournament/:id',
        builder: (_, s) =>
            RoleGuard(role: 'ADMIN', child: AdminManageScreen(tournamentId: s.pathParameters['id']!)),
      ),
      GoRoute(
        path: '/admin/category/:id/teams',
        builder: (_, s) =>
            RoleGuard(role: 'ADMIN', child: AdminTeamsScreen(categoryId: s.pathParameters['id']!)),
      ),
      GoRoute(
        path: '/admin/category/:id/matches',
        builder: (_, s) => RoleGuard(
          role: 'ADMIN',
          child: AdminMatchesScreen(
            categoryId: s.pathParameters['id']!,
            bestOf: int.tryParse(s.uri.queryParameters['bestOf'] ?? '5') ?? 5,
          ),
        ),
      ),
      GoRoute(
        path: '/admin/referees',
        builder: (_, __) => const RoleGuard(role: 'ADMIN', child: AdminRefereesScreen()),
      ),
      GoRoute(
        path: '/admin/registrations',
        builder: (_, __) => const RoleGuard(role: 'ADMIN', child: AdminRegistrationsScreen()),
      ),
    ],
  );
});

/// Guard de rol: si el usuario no está autenticado con el rol requerido, muestra
/// una pantalla que lo invita a iniciar sesión.
class RoleGuard extends ConsumerWidget {
  const RoleGuard({super.key, required this.role, required this.child});
  final String role;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    if (!auth.isAuthenticated || auth.user!.role != role) {
      return Scaffold(
        appBar: AppBar(title: const Text('Acceso restringido')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Necesitas iniciar sesión con el rol adecuado.'),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => context.go('/login'),
                child: const Text('Iniciar sesión'),
              ),
            ],
          ),
        ),
      );
    }
    return child;
  }
}
