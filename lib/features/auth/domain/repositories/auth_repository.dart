import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<UserEntity> register({
    required String email,
    required String password,
    required String displayName,
  });

  Future<UserEntity> login({
    required String email,
    required String password,
    required bool rememberMe,
  });

  Future<void> forgotPassword({
    required String email,
    required String newPassword,
  });

  Future<void> logout();

  Future<UserEntity?> getCurrentUser();

  Future<UserEntity?> restoreSession();

  Future<void> syncLocalAccountsToCloud();

  Future<UserEntity> updateProfile({
    required String displayName,
    String? handle,
    String? bio,
    String? avatarUrl,
  });
}
