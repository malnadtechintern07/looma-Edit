import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:procut/core/storage/local_storage_service.dart';
import 'package:procut/core/storage/storage_providers.dart';
import 'package:procut/features/auth/presentation/providers/auth_provider.dart';
import 'package:procut/features/projects/presentation/providers/projects_provider.dart';
import '../../data/datasources/bunny_cloud_storage_datasource.dart';
import '../../data/datasources/cloud_storage_datasource.dart';
import '../../data/datasources/composite_cloud_storage_datasource.dart';
import '../../data/datasources/global_cloud_storage_datasource.dart';
import '../../data/datasources/mysql_cloud_storage_datasource.dart';
import '../../data/datasources/ntfy_cloud_storage_datasource.dart';
import '../../data/repositories/cloud_sync_repository_impl.dart';
import '../../domain/entities/bunny_storage_config.dart';
import '../../domain/entities/cloud_backup_record.dart';
import '../../domain/entities/user_account_entity.dart';
import '../../domain/repositories/cloud_sync_repository.dart';

class BunnyStorageConfigNotifier extends StateNotifier<BunnyStorageConfig> {
  final LocalStorageService _storage;
  static const String _configKey = 'bunny_storage_config.json';

  BunnyStorageConfigNotifier(this._storage)
      : super(BunnyStorageConfig.defaultConfig()) {
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    try {
      final jsonMap = await _storage.readJson(_configKey);
      if (jsonMap != null) {
        state = BunnyStorageConfig.fromJson(jsonMap);
      }
    } catch (_) {}
  }

  Future<void> updateConfig(BunnyStorageConfig newConfig) async {
    state = newConfig;
    try {
      await _storage.writeJson(_configKey, newConfig.toJson());
    } catch (_) {}
  }
}

final bunnyStorageConfigProvider =
    StateNotifierProvider<BunnyStorageConfigNotifier, BunnyStorageConfig>((ref) {
  final storage = ref.watch(localStorageServiceProvider);
  return BunnyStorageConfigNotifier(storage);
});

final mysqlCloudStorageDataSourceProvider = Provider<MySqlCloudStorageDataSource>((ref) {
  final storage = ref.watch(localStorageServiceProvider);
  return MySqlCloudStorageDataSource(localStorageService: storage);
});

final ntfyCloudStorageDataSourceProvider = Provider<NtfyCloudStorageDataSource>((ref) {
  final storage = ref.watch(localStorageServiceProvider);
  return NtfyCloudStorageDataSource(localStorageService: storage);
});

final globalCloudStorageDataSourceProvider = Provider<GlobalCloudStorageDataSource>((ref) {
  final storage = ref.watch(localStorageServiceProvider);
  return GlobalCloudStorageDataSource(localStorageService: storage);
});

final cloudStorageDataSourceProvider = Provider<CloudStorageDataSource>((ref) {
  final storage = ref.watch(localStorageServiceProvider);
  final bunnyConfig = ref.watch(bunnyStorageConfigProvider);
  final mysqlDs = ref.watch(mysqlCloudStorageDataSourceProvider);
  final ntfyDs = ref.watch(ntfyCloudStorageDataSourceProvider);
  final globalDs = ref.watch(globalCloudStorageDataSourceProvider);
  final bunnyDs = BunnyCloudStorageDataSource(
    localStorageService: storage,
    config: bunnyConfig,
  );
  return CompositeCloudStorageDataSource(
    dataSources: [mysqlDs, ntfyDs, globalDs, bunnyDs],
  );
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
    if (!mounted) return false;
    state = state.copyWith(
      isSyncing: true,
      statusMessage: 'Synchronizing with ProCut Cloud...',
      clearError: true,
    );
    try {
      await _repository.syncAllProjects();
      if (!mounted) return true;
      _ref.invalidate(cloudBackupsFutureProvider);
      _ref.invalidate(userProfileFutureProvider);
      await _ref.read(projectsNotifierProvider.notifier).loadProjects();
      if (!mounted) return true;
      state = state.copyWith(
        isSyncing: false,
        statusMessage: 'Sync completed successfully',
      );
      return true;
    } catch (e) {
      if (!mounted) return false;
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
    if (!mounted) return false;
    state = state.copyWith(
      isSyncing: true,
      activeProjectId: projectId,
      statusMessage: 'Syncing project...',
      clearError: true,
    );
    try {
      await _repository.backupProject(projectId);
      if (!mounted) return true;
      _ref.invalidate(cloudBackupsFutureProvider);
      _ref.invalidate(userProfileFutureProvider);
      await _ref.read(projectsNotifierProvider.notifier).loadProjects();
      if (!mounted) return true;
      state = state.copyWith(
        isSyncing: false,
        activeProjectId: null,
        statusMessage: 'Project synced',
      );
      return true;
    } catch (e) {
      if (!mounted) return false;
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
    if (!mounted) return false;
    state = state.copyWith(isSyncing: true, statusMessage: 'Restoring project...');
    try {
      await _repository.restoreProject(projectId);
      if (!mounted) return true;
      await _ref.read(projectsNotifierProvider.notifier).loadProjects();
      if (!mounted) return true;
      _ref.invalidate(cloudBackupsFutureProvider);
      state = state.copyWith(isSyncing: false, statusMessage: 'Project restored');
      return true;
    } catch (e) {
      if (!mounted) return false;
      final msg = e.toString().replaceFirst('Exception: ', '');
      state = state.copyWith(isSyncing: false, errorMessage: msg);
      return false;
    }
  }

  Future<bool> deleteCloudBackup(String projectId) async {
    try {
      await _repository.deleteCloudProject(projectId);
      if (!mounted) return true;
      _ref.invalidate(cloudBackupsFutureProvider);
      _ref.invalidate(userProfileFutureProvider);
      await _ref.read(projectsNotifierProvider.notifier).loadProjects();
      return true;
    } catch (e) {
      if (!mounted) return false;
      final msg = e.toString().replaceFirst('Exception: ', '');
      state = state.copyWith(errorMessage: msg);
      return false;
    }
  }
}

final syncNotifierProvider = StateNotifierProvider<SyncNotifier, SyncState>((ref) {
  return SyncNotifier(ref.watch(cloudSyncRepositoryProvider), ref);
});

/// Automatically tracks project changes and backs them up to the cloud if authenticated.
final projectAutoSyncProvider = Provider<void>((ref) {
  final repo = ref.watch(cloudSyncRepositoryProvider);
  final auth = ref.watch(authNotifierProvider);

  ref.listen<ProjectsState>(projectsNotifierProvider, (previous, next) {
    if (!auth.isAuthenticated || auth.user == null) return;
    if (ref.read(syncNotifierProvider).isSyncing) return;
    if (previous == null) return;

    // Detect created or updated projects
    for (final project in next.projects) {
      final prevMatch = previous.projects.where((p) => p.id == project.id).firstOrNull;
      if (prevMatch == null || project.updatedAt.isAfter(prevMatch.updatedAt)) {
        repo.backupProject(project.id).catchError((_) {});
      }
    }

    // Detect deleted projects
    for (final prevProj in previous.projects) {
      final stillExists = next.projects.any((p) => p.id == prevProj.id);
      if (!stillExists) {
        repo.deleteCloudProject(prevProj.id).catchError((_) {});
      }
    }
  });
});
