import '../../domain/entities/user.dart';

class AuthResponseModel {
  final int uid;
  final String name;
  final String login;
  final String sessionId;

  const AuthResponseModel({
    required this.uid,
    required this.name,
    required this.login,
    required this.sessionId,
  });

  factory AuthResponseModel.fromJson(
    Map<String, dynamic> json,
    String sessionId,
  ) {
    return AuthResponseModel(
      uid: json['uid'] as int,
      name: json['name'] as String? ?? '',
      login: json['username'] as String? ?? json['login'] as String? ?? '',
      sessionId: sessionId.isNotEmpty
          ? sessionId
          : (json['session_id'] as String? ?? ''),
    );
  }

  User toEntity() => User(id: uid, name: name, login: login);
}
