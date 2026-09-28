import '../entities/user.dart';

abstract class AuthRepository {
  Future<User> login({required String username, required String password});
  Future<User> loginWithGoogle();
  Future<void> logout();
  Future<User?> getCurrentUser();
}
