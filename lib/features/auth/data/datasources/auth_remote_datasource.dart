import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../models/auth_response_model.dart';

class AuthRemoteDatasource {
  final ApiClient _api;
  final FlutterSecureStorage _storage;

  AuthRemoteDatasource(this._api, this._storage);

  Future<AuthResponseModel> login({
    required String username,
    required String password,
  }) async {
    try {
      final response = await _api.dio.post(
        AppConstants.authPath,
        data: {
          'jsonrpc': '2.0',
          'method': 'call',
          'params': {'db': AppConfig.dbName, 'login': username, 'password': password},
        },
      );
      final body = response.data as Map<String, dynamic>;
      if (body.containsKey('error')) {
        throw AuthException(message: 'Email atau password salah.');
      }
      final result = body['result'] as Map<String, dynamic>;
      if (result['uid'] == false) {
        throw AuthException(message: 'Email atau password salah.');
      }

      // Web: browser menyimpan cookie session otomatis (withCredentials).
      //   Set-Cookie header tidak bisa dibaca dari JS — pakai uid sebagai token lokal.
      // Native: baca session_id dari header Set-Cookie.
      final String sessionId;
      if (kIsWeb) {
        sessionId = result['uid'].toString();
      } else {
        sessionId = _parseSessionId(response.headers['set-cookie']) ?? '';
        if (sessionId.isEmpty) {
          throw AuthException(message: 'Sesi tidak valid. Silakan coba lagi.');
        }
      }

      await Future.wait([
        _storage.write(key: AppConstants.tokenKey,  value: sessionId),
        _storage.write(key: AppConstants.userIdKey, value: result['uid'].toString()),
        _storage.write(key: AppConstants.nameKey,   value: result['name'] as String? ?? ''),
        _storage.write(key: AppConstants.loginKey,
            value: result['username'] as String? ?? result['login'] as String? ?? ''),
      ]);

      return AuthResponseModel.fromJson(result, sessionId);
    } on DioException catch (e) {
      throw NetworkException(message: e.message ?? 'Network error');
    }
  }

  String? _parseSessionId(List<String>? cookies) {
    if (cookies == null) return null;
    for (final c in cookies) {
      final match = RegExp(r'session_id=([^;]+)').firstMatch(c);
      if (match != null) return match.group(1);
    }
    return null;
  }

  Future<void> logout() async {
    try {
      await _api.dio.post(
        AppConstants.logoutPath,
        data: {'jsonrpc': '2.0', 'method': 'call', 'params': {}},
      );
    } catch (_) {
      // Logout sisi server gagal (session expired / 404) — tidak masalah,
      // local state tetap dibersihkan di bawah.
    } finally {
      await _storage.deleteAll();
    }
  }
}
