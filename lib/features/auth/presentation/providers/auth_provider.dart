import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/session_expired_notifier.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';

final secureStorageProvider = Provider<FlutterSecureStorage>(
  (_) => const FlutterSecureStorage(),
);

final sessionExpiredProvider = ChangeNotifierProvider<SessionExpiredNotifier>(
  (_) => SessionExpiredNotifier(),
);

final apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(
    storage: ref.watch(secureStorageProvider),
    // read, bukan watch: ApiClient cuma perlu instance notifier-nya. Dengan
    // watch, tiap notifyListeners() membangun ulang Dio + semua provider
    // turunannya sehingga satu session expired memicu badai request.
    sessionExpired: ref.read(sessionExpiredProvider),
  ),
);

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final api     = ref.watch(apiClientProvider);
  final storage = ref.watch(secureStorageProvider);
  return AuthRepositoryImpl(AuthRemoteDatasource(api, storage), storage);
});

final authNotifierProvider =
    AsyncNotifierProvider<AuthNotifier, User?>(AuthNotifier.new);

class AuthNotifier extends AsyncNotifier<User?> {
  @override
  Future<User?> build() async {
    return ref.read(authRepositoryProvider).getCurrentUser();
  }

  Future<void> login({required String username, required String password}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).login(username: username, password: password),
    );
    if (state.valueOrNull != null) {
      ref.read(sessionExpiredProvider).reset();
    }
  }

  Future<void> loginWithGoogle() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(authRepositoryProvider).loginWithGoogle());
    if (state.valueOrNull != null) {
      ref.read(sessionExpiredProvider).reset();
    }
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = const AsyncData(null);
  }
}
