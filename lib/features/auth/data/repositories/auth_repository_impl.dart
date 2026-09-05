import 'package:looma/core/utils/id_generator.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/services/password_hasher.dart';
import '../datasources/auth_local_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthLocalDataSource localDataSource;
  UserEntity? _currentUser;

  AuthRepositoryImpl({required this.localDataSource});

  @override
  Future<UserEntity?> getCurrentUser() async {
    if (_currentUser != null) return _currentUser;
    return await restoreSession();
  }

  @override
  Future<UserEntity> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanName = displayName.trim();

    _validateEmail(cleanEmail);
    _validatePassword(password);

    if (cleanName.isEmpty) {
      throw Exception('Please enter your name or creator handle');
    }

    final existing = await localDataSource.getAccountByEmail(cleanEmail);
    if (existing != null) {
      throw Exception('An account with this email already exists. Please log in.');
    }

    final salt = PasswordHasher.generateSalt();
    final hash = PasswordHasher.hashPassword(password, salt);
    final now = DateTime.now();
    final userId = 'usr_${IdGenerator.generate()}';

    final newUser = UserEntity(
      id: userId,
      email: cleanEmail,
      displayName: cleanName,
      isPro: true,
      createdAt: now,
      lastLoginAt: now,
    );

    final accountMap = {
      ...newUser.toJson(),
      'passwordHash': hash,
      'salt': salt,
    };

    await localDataSource.saveAccount(accountMap);
    await localDataSource.saveSession(userId, true);
    _currentUser = newUser;
    return newUser;
  }

  @override
  Future<UserEntity> login({
    required String email,
    required String password,
    required bool rememberMe,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    _validateEmail(cleanEmail);

    final account = await localDataSource.getAccountByEmail(cleanEmail);
    if (account == null) {
      throw Exception('No account found with this email. Please register.');
    }

    final salt = account['salt'] as String?;
    final expectedHash = account['passwordHash'] as String?;

    if (salt == null || expectedHash == null) {
      throw Exception('Corrupted account credentials. Please reset password.');
    }

    final isValid = PasswordHasher.verifyPassword(password, salt, expectedHash);
    if (!isValid) {
      throw Exception('Incorrect password. Please try again or reset your password.');
    }

    final user = UserEntity.fromJson(account).copyWith(
      lastLoginAt: DateTime.now(),
    );

    // Update last login
    await localDataSource.updateAccount({
      ...account,
      'lastLoginAt': user.lastLoginAt.toIso8601String(),
    });

    await localDataSource.saveSession(user.id, rememberMe);
    _currentUser = user;
    return user;
  }

  @override
  Future<void> forgotPassword({
    required String email,
    required String newPassword,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    _validateEmail(cleanEmail);
    _validatePassword(newPassword);

    final account = await localDataSource.getAccountByEmail(cleanEmail);
    if (account == null) {
      throw Exception('No account found with this email address.');
    }

    final newSalt = PasswordHasher.generateSalt();
    final newHash = PasswordHasher.hashPassword(newPassword, newSalt);

    final updated = {
      ...account,
      'passwordHash': newHash,
      'salt': newSalt,
    };

    await localDataSource.updateAccount(updated);
  }

  @override
  Future<void> logout() async {
    _currentUser = null;
    await localDataSource.clearSession();
  }

  @override
  Future<UserEntity?> restoreSession() async {
    final activeId = await localDataSource.getActiveSessionUserId();
    if (activeId == null) {
      _currentUser = null;
      return null;
    }

    final account = await localDataSource.getAccountById(activeId);
    if (account == null) {
      _currentUser = null;
      await localDataSource.clearSession();
      return null;
    }

    _currentUser = UserEntity.fromJson(account);
    return _currentUser;
  }

  void _validateEmail(String email) {
    if (email.isEmpty) {
      throw Exception('Email address is required');
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      throw Exception('Please enter a valid email address');
    }
  }

  void _validatePassword(String password) {
    if (password.length < 6) {
      throw Exception('Password must be at least 6 characters');
    }
  }
}
