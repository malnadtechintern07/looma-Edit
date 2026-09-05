import 'package:looma/features/projects/domain/entities/project_entity.dart';
import '../entities/cloud_backup_record.dart';
import '../entities/user_account_entity.dart';

abstract class CloudSyncRepository {
  Future<UserAccountEntity> getUserProfile();
  Future<List<CloudBackupRecord>> getCloudBackups();
  Future<List<ProjectEntity>> getCloudProjects();
  Future<void> backupProject(String projectId);
  Future<void> syncAllProjects();
  Future<ProjectEntity?> restoreProject(String projectId);
  Future<void> deleteCloudProject(String projectId);
}
