import 'package:looma/core/utils/id_generator.dart';
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

    final existingLocal = await localDataSource.getAccountByEmail(cleanEmail);
    if (existingLocal != null) {
      throw Exception('An account with this email already exists. Please log in.');
    }

    // Check cloud storage to prevent duplicate registrations across devices
    if (remoteDataSource != null) {
      final existingRemote = await remoteDataSource!.getAccountByEmail(cleanEmail);
      if (existingRemote != null) {
        await localDataSource.saveAccount(existingRemote);
        throw Exception('An account with this email already exists. Please log in.');
      }
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

    // Save locally on this device
    await localDataSource.saveAccount(accountMap);

    // Sync to cloud storage so user can log in on all devices
    if (remoteDataSource != null) {
      await remoteDataSource!.saveAccount(accountMap);
    }

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

    // 1. Look up account in local storage first
    var account = await localDataSource.getAccountByEmail(cleanEmail);

    // 2. If not found on this device, fetch from cloud remote
    if (account == null && remoteDataSource != null) {
      account = await remoteDataSource!.getAccountByEmail(cleanEmail);
      if (account != null) {
        // Sync down to local storage on this device
        await localDataSource.saveAccount(account);
      }
    }

    if (account == null) {
      throw Exception('No account found with this email. Please register.');
    }

    var salt = account['salt'] as String?;
    var expectedHash = account['passwordHash'] as String?;

    if (salt == null || expectedHash == null) {
      throw Exception('Corrupted account credentials. Please reset password.');
    }

    var isValid = PasswordHasher.verifyPassword(password, salt, expectedHash);

    // 3. If password failed locally, check cloud remote in case password was changed from another device
    if (!isValid && remoteDataSource != null) {
      final remoteAccount = await remoteDataSource!.getAccountByEmail(cleanEmail);
      if (remoteAccount != null) {
        final remoteSalt = remoteAccount['salt'] as String?;
        final remoteHash = remoteAccount['passwordHash'] as String?;
        if (remoteSalt != null && remoteHash != null) {
          final remoteValid = PasswordHasher.verifyPassword(password, remoteSalt, remoteHash);
          if (remoteValid) {
            account = remoteAccount;
            salt = remoteSalt;
            expectedHash = remoteHash;
            isValid = true;
            await localDataSource.updateAccount(account);
          }
        }
      }
    }

    if (!isValid) {
      throw Exception('Incorrect password. Please try again or reset your password.');
    }

    final user = UserEntity.fromJson(account).copyWith(
      lastLoginAt: DateTime.now(),
    );

    final updatedAccount = {
      ...account,
      'lastLoginAt': user.lastLoginAt.toIso8601String(),
    };

    // Update last login locally and in the cloud
    await localDataSource.updateAccount(updatedAccount);
    if (remoteDataSource != null) {
      await remoteDataSource!.updateAccount(updatedAccount);
    }

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

    var account = await localDataSource.getAccountByEmail(cleanEmail);
    if (account == null && remoteDataSource != null) {
      account = await remoteDataSource!.getAccountByEmail(cleanEmail);
    }

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
    if (remoteDataSource != null) {
      await remoteDataSource!.updateAccount(updated);
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
