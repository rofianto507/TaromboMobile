import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../constants/app_constants.dart';
import '../session_expired_notifier.dart';

class AuthInterceptor extends Interceptor {
  final FlutterSecureStorage _storage;
  final SessionExpiredNotifier _sessionExpired;

  AuthInterceptor(this._storage, this._sessionExpired);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!kIsWeb) {
      final token = await _storage.read(key: AppConstants.tokenKey);
      if (token != null) {
        options.headers['Cookie'] = 'session_id=$token';
      }
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // Odoo mengembalikan SessionExpiredException dalam body JSON-RPC (status 200).
    final data = response.data;
    if (data is Map) {
      final name = (data['error'] as Map?)?['data']?['name'] as String? ?? '';
      if (name.endsWith('SessionExpiredException')) {
        _sessionExpired.expire();
      }
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      _sessionExpired.expire();
    }
    handler.next(err);
  }
}
