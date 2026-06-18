import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'config.dart';
import 'token_storage.dart';

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

/// Cliente HTTP central. Adjunta el JWT automáticamente y, ante un 401, intenta
/// refrescar el token una vez antes de propagar el error.
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(ref.read(tokenStorageProvider));
});

class ApiClient {
  ApiClient(this._tokens) {
    _dio = Dio(BaseOptions(
      baseUrl: AppConfig.restBase,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _tokens.accessToken;
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (e, handler) async {
        if (e.response?.statusCode == 401 && !_retried) {
          _retried = true;
          final refreshed = await _refresh();
          if (refreshed) {
            final clone = await _dio.fetch(e.requestOptions);
            return handler.resolve(clone);
          }
        }
        handler.next(e);
      },
    ));
  }

  late final Dio _dio;
  final TokenStorage _tokens;
  bool _retried = false;

  Dio get raw => _dio;

  Future<bool> _refresh() async {
    final refresh = await _tokens.refreshToken;
    if (refresh == null) return false;
    try {
      final res = await Dio(BaseOptions(baseUrl: AppConfig.restBase))
          .post('/auth/refresh', data: {'refreshToken': refresh});
      await _tokens.save(
        access: res.data['accessToken'] as String,
        refresh: res.data['refreshToken'] as String,
      );
      return true;
    } catch (_) {
      await _tokens.clear();
      return false;
    }
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) async {
    final res = await _dio.get(path, queryParameters: query);
    return res.data;
  }

  Future<dynamic> post(String path, {Object? data}) async {
    final res = await _dio.post(path, data: data);
    return res.data;
  }
}
