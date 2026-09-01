import '../entities/cloud_backup_record.dart';
import '../entities/user_account_entity.dart';

abstract class CloudSyncRepository {
  Future<UserAccountEntity> getUserProfile();
  Future<List<CloudBackupRecord>> getCloudBackups();
  Future<void> backupProject(String projectId);
  Future<void> syncAllProjects();
  Future<void> restoreProject(String projectId);
}
