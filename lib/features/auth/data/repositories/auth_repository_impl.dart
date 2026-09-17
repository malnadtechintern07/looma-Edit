import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/services/password_hasher.dart';
import '../datasources/auth_local_datasource.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthLocalDataSource localDataSource;
  final AuthRemoteDataSource? remoteDataSource;
  UserEntity? _currentUser;

  AuthRepositoryImpl({
    required this.localDataSource,
    this.remoteDataSource,
  });

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

    // Server-authoritative registration: password is securely hashed with bcrypt on the server
    if (remoteDataSource != null) {
      try {
        final serverUserMap = await remoteDataSource!.register(cleanEmail, password, cleanName);
        await localDataSource.saveAccount(serverUserMap);
        final user = UserEntity.fromJson(serverUserMap);
        await localDataSource.saveSession(user.id, true);
        _currentUser = user;
        return user;
      } catch (e) {
        // If server returned specific error, rethrow directly
        final errText = e.toString().replaceFirst('Exception: ', '');
        if (!errText.contains('Unable to reach') && !errText.contains('Cannot connect')) {
          rethrow;
        }
      }
    }

    // Fallback if server is temporarily unreachable offline
    final existingLocal = await localDataSource.getAccountByEmail(cleanEmail);
    if (existingLocal != null) {
      final localSalt = existingLocal['salt'] as String?;
      final localHash = existingLocal['passwordHash'] as String?;
      if (localSalt != null && localHash != null && PasswordHasher.verifyPassword(password, localSalt, localHash)) {
        await localDataSource.saveSession(existingLocal['id'] as String, true);
        _currentUser = UserEntity.fromJson(existingLocal);
        return _currentUser!;
      }
      throw Exception('An account with this email already exists. Please log in.');
    }

    final salt = PasswordHasher.generateSalt();
    final hash = PasswordHasher.hashPassword(password, salt);
    final now = DateTime.now();
    final emailHash = sha256.convert(utf8.encode(cleanEmail)).toString();
    final userId = 'usr_${emailHash.substring(0, 16)}';

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
      'password': password,
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

    // 1. Server-authoritative login first: supports cross-device sign-in and bcrypt verification
    if (remoteDataSource != null) {
      try {
        final serverUser = await remoteDataSource!.login(cleanEmail, password);
        if (serverUser != null) {
          await localDataSource.saveAccount(serverUser);
          final user = UserEntity.fromJson(serverUser).copyWith(lastLoginAt: DateTime.now());
          final updatedAccount = {...serverUser, 'lastLoginAt': user.lastLoginAt.toIso8601String()};
          await localDataSource.updateAccount(updatedAccount);
          await localDataSource.saveSession(user.id, rememberMe);
          _currentUser = user;
          return user;
        }
      } catch (e) {
        final errorText = e.toString().replaceFirst('Exception: ', '');
        // If it's an offline connectivity error, fallback to offline local cache check
        final isNetworkError = errorText.contains('Unable to reach') ||
            errorText.contains('Cannot connect') ||
            errorText.contains('SocketException') ||
            errorText.contains('connection timeout');

        if (!isNetworkError) {
          rethrow;
        }
      }
    }

    // 2. Offline fallback if device cannot reach the server
    final account = await localDataSource.getAccountByEmail(cleanEmail);
    if (account != null) {
      final salt = account['salt'] as String?;
      final expectedHash = account['passwordHash'] as String?;

      if (salt != null && expectedHash != null) {
        final isValid = PasswordHasher.verifyPassword(password, salt, expectedHash);
        if (isValid) {
          final user = UserEntity.fromJson(account).copyWith(lastLoginAt: DateTime.now());
          final updatedAccount = {...account, 'lastLoginAt': user.lastLoginAt.toIso8601String()};
          await localDataSource.updateAccount(updatedAccount);
          await localDataSource.saveSession(user.id, rememberMe);
          _currentUser = user;
          return user;
        }
      }
      throw Exception('Incorrect password. Please try again.');
    }

    throw Exception('No account found with this email. Please create an account first.');
  }

  @override
  Future<void> forgotPassword({
    required String email,
    required String newPassword,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    _validateEmail(cleanEmail);
    _validatePassword(newPassword);

    if (remoteDataSource != null) {
      try {
        await remoteDataSource!.forgotPassword(cleanEmail, newPassword);
      } catch (e) {
        rethrow;
      }
    }

    var account = await localDataSource.getAccountByEmail(cleanEmail);
    if (account != null) {
      final newSalt = PasswordHasher.generateSalt();
      final newHash = PasswordHasher.hashPassword(newPassword, newSalt);
      final updated = {
        ...account,
        'passwordHash': newHash,
        'salt': newSalt,
      };
      await localDataSource.updateAccount(updated);
    }
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

    var account = await localDataSource.getAccountById(activeId);
    if (account == null && remoteDataSource != null) {
      account = await remoteDataSource!.getAccountById(activeId);
      if (account != null) {
        await localDataSource.saveAccount(account);
      }
    }

    if (account == null) {
      _currentUser = null;
      await localDataSource.clearSession();
      return null;
    }

    _currentUser = UserEntity.fromJson(account);
    return _currentUser;
  }

  @override
  Future<void> syncLocalAccountsToCloud() async {
    if (remoteDataSource == null) return;
    try {
      final localAccounts = await localDataSource.getAccounts();
      for (final acc in localAccounts) {
        final email = (acc['email'] as String? ?? '').trim().toLowerCase();
        if (email.isNotEmpty) {
          await remoteDataSource!.saveAccount(acc);
        }
      }
    } catch (_) {}
  }

  @override
  Future<UserEntity> updateProfile({
    required String displayName,
    String? handle,
    String? bio,
    String? avatarUrl,
  }) async {
    final cleanName = displayName.trim();
    if (cleanName.isEmpty) {
      throw Exception('Display name cannot be empty');
    }

    if (_currentUser != null) {
      final updatedUser = _currentUser!.copyWith(
        displayName: cleanName,
        handle: handle?.trim(),
        bio: bio?.trim(),
        avatarUrl: avatarUrl,
      );

      final existingAccount = await localDataSource.getAccountById(updatedUser.id) ?? {};
      final updatedAccount = {
        ...existingAccount,
        ...updatedUser.toJson(),
      };

      await localDataSource.updateAccount(updatedAccount);

      if (remoteDataSource != null) {
        await remoteDataSource!.updateAccount(updatedAccount).catchError((_) => false);
      }

      _currentUser = updatedUser;
      return updatedUser;
    } else {
      final guestUser = UserEntity(
        id: 'guest_user',
        email: 'guest@procut.app',
        displayName: cleanName,
        handle: handle?.trim(),
        bio: bio?.trim(),
        avatarUrl: avatarUrl,
        isPro: false,
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
      );
      _currentUser = guestUser;
      return guestUser;
    }
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
