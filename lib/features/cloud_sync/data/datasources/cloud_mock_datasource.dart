import '../../domain/entities/cloud_backup_record.dart';
import '../../domain/entities/user_account_entity.dart';

abstract class CloudMockDataSource {
  Future<UserAccountEntity> getProfile();
  Future<List<CloudBackupRecord>> getBackups();
  Future<void> backup(String projectId);
  Future<void> syncAll();
}

class CloudMockDataSourceImpl implements CloudMockDataSource {
  final List<CloudBackupRecord> _records = [
    CloudBackupRecord(
      projectId: 'sample-tokyo-vlog',
      projectTitle: 'Tokyo Night Cyberpunk Reel',
      fileSizeBytes: 42 * 1024 * 1024,
      backedUpAt: DateTime.now().subtract(const Duration(hours: 1)),
      cloudChecksum: 'sha256_e8910b2f',
    ),
    CloudBackupRecord(
      projectId: 'sample-cinematic-trailer',
      projectTitle: 'Cinematic Mountain Drone',
      fileSizeBytes: 128 * 1024 * 1024,
      backedUpAt: DateTime.now().subtract(const Duration(days: 1)),
      cloudChecksum: 'sha256_a1240b99',
    ),
  ];

  @override
  Future<UserAccountEntity> getProfile() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return UserAccountEntity(
      id: 'usr_looma_creator',
      displayName: 'Alex Rivers',
      email: 'alex.creator@looma.app',
      avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb',
      memberSince: DateTime.now().subtract(const Duration(days: 180)),
    );
  }

  @override
  Future<List<CloudBackupRecord>> getBackups() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return List.unmodifiable(_records);
  }

  @override
  Future<void> backup(String projectId) async {
    await Future.delayed(const Duration(milliseconds: 600));
    _records.insert(
      0,
      CloudBackupRecord(
        projectId: projectId,
        projectTitle: 'Project Snapshot ($projectId)',
        fileSizeBytes: 35 * 1024 * 1024,
        backedUpAt: DateTime.now(),
        cloudChecksum: 'sha256_new_${DateTime.now().millisecondsSinceEpoch}',
      ),
    );
  }

  @override
  Future<void> syncAll() async {
    await Future.delayed(const Duration(milliseconds: 1200));
  }
}
