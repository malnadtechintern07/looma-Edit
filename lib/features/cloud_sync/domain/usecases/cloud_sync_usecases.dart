import '../entities/cloud_backup_record.dart';
import '../entities/user_account_entity.dart';
import '../repositories/cloud_sync_repository.dart';

class GetUserProfileUseCase {
  final CloudSyncRepository repository;
  const GetUserProfileUseCase(this.repository);

  Future<UserAccountEntity> call() => repository.getUserProfile();
}

class GetCloudBackupsUseCase {
  final CloudSyncRepository repository;
  const GetCloudBackupsUseCase(this.repository);

  Future<List<CloudBackupRecord>> call() => repository.getCloudBackups();
}

class SyncAllProjectsUseCase {
  final CloudSyncRepository repository;
  const SyncAllProjectsUseCase(this.repository);

  Future<void> call() => repository.syncAllProjects();
}

class BackupProjectUseCase {
  final CloudSyncRepository repository;
  const BackupProjectUseCase(this.repository);

  Future<void> call(String projectId) => repository.backupProject(projectId);
}
