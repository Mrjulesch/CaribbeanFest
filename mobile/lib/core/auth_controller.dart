import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_client.dart';

class AuthUser {
  AuthUser({required this.id, required this.email, required this.role});
  final String id;
  final String email;
  final String role; // ADMIN | REFEREE | CLUB

  bool get isAdmin => role == 'ADMIN';
  bool get isReferee => role == 'REFEREE';
}

class AuthState {
  AuthState({this.user, this.loading = false, this.error});
  final AuthUser? user;
  final bool loading;
  final String? error;

  bool get isAuthenticated => user != null;

  AuthState copyWith({AuthUser? user, bool? loading, String? error, bool clearUser = false}) =>
      AuthState(
        user: clearUser ? null : (user ?? this.user),
        loading: loading ?? this.loading,
        error: error,
      );
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) => AuthController(ref));

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._ref) : super(AuthState());
  final Ref _ref;

  Future<void> login(String email, String password) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final api = _ref.read(apiClientProvider);
      final res = await api.post('/auth/login', data: {'email': email, 'password': password});
      await _ref.read(tokenStorageProvider).save(
            access: res['accessToken'] as String,
            refresh: res['refreshToken'] as String,
          );
      final u = res['user'] as Map<String, dynamic>;
      state = AuthState(
        user: AuthUser(id: u['id'] as String, email: u['email'] as String, role: u['role'] as String),
      );
    } catch (_) {
      state = state.copyWith(loading: false, error: 'Credenciales inválidas');
    }
  }

  Future<void> logout() async {
    await _ref.read(tokenStorageProvider).clear();
    state = AuthState();
  }
}
