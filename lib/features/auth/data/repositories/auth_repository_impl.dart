import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDatasource _remote;
  final FlutterSecureStorage _storage;

  AuthRepositoryImpl(this._remote, this._storage);

  @override
  Future<User> login({
    required String username,
    required String password,
  }) async {
    final model = await _remote.login(username: username, password: password);
    return model.toEntity();
  }

  @override
  Future<User> loginWithGoogle() async {
    final model = await _remote.loginWithGoogle();
    return model.toEntity();
  }

  @override
  Future<void> logout() => _remote.logout();

  @override
  Future<User?> getCurrentUser() async {
    final uid = await _storage.read(key: AppConstants.userIdKey);
    if (uid == null) return null;
    final results = await Future.wait([
      _storage.read(key: AppConstants.nameKey),
      _storage.read(key: AppConstants.loginKey),
    ]);
    return User(
      id: int.parse(uid),
      name: results[0] ?? '',
      login: results[1] ?? '',
    );
  }
}
