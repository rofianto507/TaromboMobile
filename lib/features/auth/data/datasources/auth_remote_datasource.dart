import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
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

  /// Login/registrasi otomatis via akun Google. Token dari Google dikirim ke
  /// /tarombo/mobile/google_login (lihat controllers/mobile_auth.py di modul
  /// Odoo) yang memvalidasinya lewat mekanisme auth_oauth bawaan Odoo lalu
  /// membuat sesi. Endpoint itu cuma balas {'success','uid'} (bukan bentuk
  /// lengkap seperti /web/session/authenticate) — jadi begitu sesi jadi,
  /// kita ambil info lengkap (name/username) lewat get_session_info standar
  /// Odoo, dipanggil lewat _api.dio yang otomatis melampirkan cookie session
  /// yang baru saja disimpan di bawah.
  Future<AuthResponseModel> loginWithGoogle() async {
    try {
      final googleUser = await GoogleSignIn(scopes: const ['email']).signIn();
      if (googleUser == null) {
        throw AuthException(message: 'Login Google dibatalkan.');
      }
      final accessToken = (await googleUser.authentication).accessToken;
      if (accessToken == null) {
        throw AuthException(message: 'Gagal mendapatkan token dari Google.');
      }

      final response = await _api.dio.post(
        AppConstants.googleLoginPath,
        data: {
          'jsonrpc': '2.0',
          'method': 'call',
          'params': {'access_token': accessToken},
        },
      );
      final body = response.data as Map<String, dynamic>;
      if (body.containsKey('error')) {
        throw AuthException(message: 'Login Google gagal. Coba lagi.');
      }
      final result = body['result'] as Map<String, dynamic>;
      if (result['success'] != true) {
        throw AuthException(message: result['error'] as String? ?? 'Login Google gagal.');
      }

      final String sessionId;
      if (kIsWeb) {
        sessionId = result['uid'].toString();
      } else {
        sessionId = _parseSessionId(response.headers['set-cookie']) ?? '';
        if (sessionId.isEmpty) {
          throw AuthException(message: 'Sesi tidak valid. Silakan coba lagi.');
        }
      }
      // Simpan token sesi DULU, supaya AuthInterceptor otomatis melampirkan
      // cookie yang baru ini pada panggilan get_session_info berikut.
      await _storage.write(key: AppConstants.tokenKey, value: sessionId);

      final infoResponse = await _api.dio.post(
        AppConstants.sessionInfoPath,
        data: {'jsonrpc': '2.0', 'method': 'call', 'params': {}},
      );
      final info = (infoResponse.data as Map<String, dynamic>)['result'] as Map<String, dynamic>;

      await Future.wait([
        _storage.write(key: AppConstants.userIdKey, value: info['uid'].toString()),
        _storage.write(key: AppConstants.nameKey, value: info['name'] as String? ?? ''),
        _storage.write(key: AppConstants.loginKey,
            value: info['username'] as String? ?? info['login'] as String? ?? ''),
      ]);

      return AuthResponseModel.fromJson(info, sessionId);
    } on DioException catch (e) {
      throw NetworkException(message: e.message ?? 'Network error');
    }
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
    }
    try {
      // Non-fatal: kalau user tidak pernah login via Google, ini no-op.
      await GoogleSignIn().signOut();
    } catch (_) {}
    await _storage.deleteAll();
  }
}
