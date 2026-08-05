import 'package:sport_flutter/data/datasources/auth_remote_data_source.dart';
import 'package:sport_flutter/domain/entities/user.dart';
import 'package:sport_flutter/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl({required this.remoteDataSource});

  @override
  Future<String> login(String username, String password) {
    return remoteDataSource.login(username, password);
  }

  @override
  Future<void> register(
    String username,
    String email,
    String password,
    String verificationCode,
    String invitationCode,
  ) {
    return remoteDataSource.register(
      username,
      email,
      password,
      verificationCode,
      invitationCode,
    );
  }

  @override
  Future<void> sendVerificationCode(String email) {
    return remoteDataSource.sendVerificationCode(email);
  }

  @override
  Future<void> sendPasswordResetCode(String email) {
    return remoteDataSource.sendPasswordResetCode(email);
  }

  @override
  Future<void> resetPassword(String email, String code, String newPassword) {
    return remoteDataSource.resetPassword(email, code, newPassword);
  }

  @override
  Future<void> forgotPasswordSendCode(String username, String email) {
    return remoteDataSource.forgotPasswordSendCode(username, email);
  }

  @override
  Future<void> forgotPasswordReset(
    String username,
    String email,
    String code,
    String newPassword,
  ) {
    return remoteDataSource.forgotPasswordReset(
      username,
      email,
      code,
      newPassword,
    );
  }

  @override
  Future<User> getUserProfile() {
    return remoteDataSource.getUserProfile();
  }

  @override
  Future<User> updateProfile({
    String? username,
    String? avatarUrl,
    String? bio,
  }) {
    return remoteDataSource.updateProfile(
      username: username,
      avatarUrl: avatarUrl,
      bio: bio,
    );
  }

  @override
  Future<void> deleteAccount() {
    return remoteDataSource.deleteAccount();
  }

  @override
  Future<bool> checkUsername(String username) {
    return remoteDataSource.checkUsername(username);
  }
}
