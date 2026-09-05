import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:looma/core/storage/storage_providers.dart';
import 'package:looma/features/auth/presentation/providers/auth_provider.dart';
import 'package:looma/features/projects/presentation/providers/projects_provider.dart';
import '../../data/datasources/cloud_storage_datasource.dart';
import '../../data/repositories/cloud_sync_repository_impl.dart';
import '../../domain/entities/cloud_backup_record.dart';
import '../../domain/entities/user_account_entity.dart';
import '../../domain/repositories/cloud_sync_repository.dart';

final cloudStorageDataSourceProvider = Provider<CloudStorageDataSource>((ref) {
  final storage = ref.watch(localStorageServiceProvider);
  return CloudStorageDataSourceImpl(storageService: storage);
});

final cloudSyncRepositoryProvider = Provider<CloudSyncRepository>((ref) {
  final cloudDs = ref.watch(cloudStorageDataSourceProvider);
  final localDs = ref.watch(projectLocalDataSourceProvider);
  final authRepo = ref.watch(authRepositoryProvider);
  return CloudSyncRepositoryImpl(
    cloudDataSource: cloudDs,
    projectLocalDataSource: localDs,
    authRepository: authRepo,
  );
});

final userProfileFutureProvider = FutureProvider<UserAccountEntity>((ref) async {
  // Re-fetch whenever auth state changes
  ref.watch(authNotifierProvider);
  return await ref.watch(cloudSyncRepositoryProvider).getUserProfile();
});

final cloudBackupsFutureProvider = FutureProvider<List<CloudBackupRecord>>((ref) async {
  ref.watch(authNotifierProvider);
  return await ref.watch(cloudSyncRepositoryProvider).getCloudBackups();
});

class SyncState {
  final bool isSyncing;
  final String? activeProjectId;
  final String? statusMessage;
  final String? errorMessage;

  const SyncState({
    this.isSyncing = false,
    this.activeProjectId,
    this.statusMessage,
    this.errorMessage,
  });

  SyncState copyWith({
    bool? isSyncing,
    String? activeProjectId,
    String? statusMessage,
    String? errorMessage,
    bool clearError = false,
  }) {
    return SyncState(
      isSyncing: isSyncing ?? this.isSyncing,
      activeProjectId: activeProjectId ?? this.activeProjectId,
      statusMessage: statusMessage ?? this.statusMessage,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class SyncNotifier extends StateNotifier<SyncState> {
  final CloudSyncRepository _repository;
  final Ref _ref;

  SyncNotifier(this._repository, this._ref) : super(const SyncState());

  Future<bool> triggerSync() async {
    state = state.copyWith(
      isSyncing: true,
      statusMessage: 'Synchronizing with Looma Cloud...',
      clearError: true,
    );
    try {
      await _repository.syncAllProjects();
      _ref.invalidate(cloudBackupsFutureProvider);
      _ref.invalidate(userProfileFutureProvider);
      await _ref.read(projectsNotifierProvider.notifier).loadProjects();
      state = state.copyWith(
        isSyncing: false,
        statusMessage: 'Sync completed successfully',
      );
      return true;
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      state = state.copyWith(
        isSyncing: false,
        errorMessage: msg,
        statusMessage: 'Sync failed',
      );
      return false;
    }
  }

  Future<bool> syncSingleProject(String projectId) async {
    state = state.copyWith(
      isSyncing: true,
      activeProjectId: projectId,
      statusMessage: 'Syncing project...',
      clearError: true,
    );
    try {
      await _repository.backupProject(projectId);
      _ref.invalidate(cloudBackupsFutureProvider);
      _ref.invalidate(userProfileFutureProvider);
      await _ref.read(projectsNotifierProvider.notifier).loadProjects();
      state = state.copyWith(
        isSyncing: false,
        activeProjectId: null,
        statusMessage: 'Project synced',
      );
      return true;
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      state = state.copyWith(
        isSyncing: false,
        activeProjectId: null,
        errorMessage: msg,
      );
      return false;
    }
  }

  Future<bool> restoreProject(String projectId) async {
    state = state.copyWith(isSyncing: true, statusMessage: 'Restoring project...');
    try {
      await _repository.restoreProject(projectId);
      await _ref.read(projectsNotifierProvider.notifier).loadProjects();
      _ref.invalidate(cloudBackupsFutureProvider);
      state = state.copyWith(isSyncing: false, statusMessage: 'Project restored');
      return true;
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      state = state.copyWith(isSyncing: false, errorMessage: msg);
      return false;
    }
  }

  Future<bool> deleteCloudBackup(String projectId) async {
    try {
      await _repository.deleteCloudProject(projectId);
      _ref.invalidate(cloudBackupsFutureProvider);
      _ref.invalidate(userProfileFutureProvider);
      await _ref.read(projectsNotifierProvider.notifier).loadProjects();
      return true;
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      state = state.copyWith(errorMessage: msg);
      return false;
    }
  }
}

final syncNotifierProvider = StateNotifierProvider<SyncNotifier, SyncState>((ref) {
  return SyncNotifier(ref.watch(cloudSyncRepositoryProvider), ref);
});
