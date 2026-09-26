import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/app_config.dart';
import '../error/exceptions.dart';
import 'interceptors/auth_interceptor.dart';
import 'session_expired_notifier.dart';

class ApiClient {
  late final Dio _dio;

  ApiClient({FlutterSecureStorage? storage, SessionExpiredNotifier? sessionExpired}) {
    final sec = storage ?? const FlutterSecureStorage();
    final expiredNotifier = sessionExpired ?? SessionExpiredNotifier();
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.baseUrl,
        connectTimeout: AppConfig.connectTimeout,
        receiveTimeout: AppConfig.receiveTimeout,
        contentType: 'application/json',
        extra: kIsWeb ? {'withCredentials': true} : {},
      ),
    )..interceptors.addAll([
        AuthInterceptor(sec, expiredNotifier),
        if (!AppConfig.isProduction)
          LogInterceptor(requestBody: true, responseBody: true),
      ]);
  }

  Dio get dio => _dio;

  /// Memanggil method Odoo JSON-RPC lewat /web/dataset/call_kw.
  Future<dynamic> callKw({
    required String model,
    required String method,
    required List args,
    Map<String, dynamic> kwargs = const {},
  }) async {
    try {
      final response = await _dio.post(
        '/web/dataset/call_kw',
        data: {
          'jsonrpc': '2.0',
          'method': 'call',
          'params': {
            'model': model,
            'method': method,
            'args': args,
            'kwargs': kwargs,
          },
        },
      );
      final body = response.data as Map<String, dynamic>;
      if (body.containsKey('error')) {
        final err = body['error'] as Map;
        throw ServerException(message: err['data']?['message'] ?? err['message'] ?? 'Unknown error');
      }
      return body['result'];
    } on DioException catch (e) {
      throw NetworkException(message: e.message ?? 'Network error');
    }
  }
}
