import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/constants/app_constants.dart';

enum RegStatus { idle, loading, success, error }

class RegState {
  final RegStatus status;
  final String? error;
  final String? login;
  const RegState({this.status = RegStatus.idle, this.error, this.login});
}

class RegNotifier extends Notifier<RegState> {
  @override
  RegState build() => const RegState();

  Future<void> register({
    required String nama,
    required String email,
    required String password,
  }) async {
    state = const RegState(status: RegStatus.loading);
    try {
      final dio = Dio(BaseOptions(
        baseUrl: AppConfig.baseUrl,
        contentType: 'application/json',
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
      ));

      final response = await dio.post(
        AppConstants.registerPath,
        data: {
          'jsonrpc': '2.0',
          'method': 'call',
          'params': {'nama': nama, 'email': email, 'password': password},
        },
      );

      final body = response.data as Map<String, dynamic>;
      if (body.containsKey('error')) {
        final errData = body['error'] as Map;
        final msg = errData['data']?['message'] as String? ??
            errData['message'] as String? ??
            'Terjadi kesalahan server';
        state = RegState(status: RegStatus.error, error: msg);
        return;
      }

      final result = body['result'] as Map<String, dynamic>;
      if (result['success'] == true) {
        state = RegState(status: RegStatus.success, login: result['login'] as String?);
      } else {
        state = RegState(status: RegStatus.error, error: result['error'] as String? ?? 'Registrasi gagal');
      }
    } on DioException {
      state = const RegState(status: RegStatus.error, error: 'Koneksi gagal. Periksa jaringan Anda.');
    } catch (e) {
      state = RegState(status: RegStatus.error, error: 'Terjadi kesalahan: $e');
    }
  }

  void reset() => state = const RegState();
}

final registrationProvider = NotifierProvider<RegNotifier, RegState>(RegNotifier.new);
