import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/cloud_mock_datasource.dart';
import '../../data/repositories/cloud_sync_repository_impl.dart';
import '../../domain/entities/cloud_backup_record.dart';
import '../../domain/entities/user_account_entity.dart';
import '../../domain/repositories/cloud_sync_repository.dart';
import '../../domain/usecases/cloud_sync_usecases.dart';

final cloudMockDataSourceProvider = Provider<CloudMockDataSource>((ref) {
  return CloudMockDataSourceImpl();
});

final cloudSyncRepositoryProvider = Provider<CloudSyncRepository>((ref) {
  final ds = ref.watch(cloudMockDataSourceProvider);
  return CloudSyncRepositoryImpl(dataSource: ds);
});

final getUserProfileUseCaseProvider = Provider<GetUserProfileUseCase>((ref) {
  return GetUserProfileUseCase(ref.watch(cloudSyncRepositoryProvider));
});

final getCloudBackupsUseCaseProvider = Provider<GetCloudBackupsUseCase>((ref) {
  return GetCloudBackupsUseCase(ref.watch(cloudSyncRepositoryProvider));
});

final syncAllProjectsUseCaseProvider = Provider<SyncAllProjectsUseCase>((ref) {
  return SyncAllProjectsUseCase(ref.watch(cloudSyncRepositoryProvider));
});

final userProfileFutureProvider = FutureProvider<UserAccountEntity>((ref) async {
  return await ref.watch(getUserProfileUseCaseProvider)();
});

final cloudBackupsFutureProvider = FutureProvider<List<CloudBackupRecord>>((ref) async {
  return await ref.watch(getCloudBackupsUseCaseProvider)();
});

class SyncNotifier extends StateNotifier<bool> {
  final SyncAllProjectsUseCase _syncUseCase;
  final Ref _ref;

  SyncNotifier(this._syncUseCase, this._ref) : super(false);

  Future<void> triggerSync() async {
    state = true;
    try {
      await _syncUseCase();
      _ref.invalidate(cloudBackupsFutureProvider);
      _ref.invalidate(userProfileFutureProvider);
    } finally {
      state = false;
    }
  }
}

final syncNotifierProvider = StateNotifierProvider<SyncNotifier, bool>((ref) {
  return SyncNotifier(ref.watch(syncAllProjectsUseCaseProvider), ref);
});
