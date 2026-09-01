import '../../domain/entities/cloud_backup_record.dart';
import '../../domain/entities/user_account_entity.dart';
import '../../domain/repositories/cloud_sync_repository.dart';
import '../datasources/cloud_mock_datasource.dart';

class CloudSyncRepositoryImpl implements CloudSyncRepository {
  final CloudMockDataSource dataSource;

  CloudSyncRepositoryImpl({required this.dataSource});

  @override
  Future<UserAccountEntity> getUserProfile() async {
    return await dataSource.getProfile();
  }

  @override
  Future<List<CloudBackupRecord>> getCloudBackups() async {
    return await dataSource.getBackups();
  }

  @override
  Future<void> backupProject(String projectId) async {
    await dataSource.backup(projectId);
  }

  @override
  Future<void> syncAllProjects() async {
    await dataSource.syncAll();
  }

  @override
  Future<void> restoreProject(String projectId) async {
    await Future.delayed(const Duration(milliseconds: 500));
  }
}
