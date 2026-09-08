import 'package:looma/features/projects/domain/entities/project_entity.dart';
import '../../domain/entities/cloud_backup_record.dart';
import 'cloud_storage_datasource.dart';

/// Composite cloud storage data source that orchestrates multiple cloud storage providers:
/// Primary: Zero-configuration live GlobalCloudStorageDataSource (instant multi-device sync)
/// Secondary: Optional Bunny.net Edge Storage datasource
class CompositeCloudStorageDataSource implements CloudStorageDataSource {
  final CloudStorageDataSource primary;
  final CloudStorageDataSource? secondary;

  CompositeCloudStorageDataSource({
    required this.primary,
    this.secondary,
  });

  @override
  Future<List<ProjectEntity>> getCloudProjects(String userId) async {
    // 1. Fetch from primary zero-config global cloud
    final primaryProjects = await primary.getCloudProjects(userId);
    if (primaryProjects.isNotEmpty) {
      return primaryProjects;
    }

    // 2. Check secondary if configured and primary had none
    if (secondary != null) {
      try {
        final secondaryProjects = await secondary!.getCloudProjects(userId);
        if (secondaryProjects.isNotEmpty) {
          // Re-sync found secondary projects into primary for subsequent fast loads
          for (final p in secondaryProjects) {
            primary.backupProject(userId, p).catchError((_) => CloudBackupRecord(
                  projectId: p.id,
                  projectTitle: p.title,
                  fileSizeBytes: 0,
                  backedUpAt: DateTime.now(),
                  cloudChecksum: '',
                ));
          }
          return secondaryProjects;
        }
      } catch (_) {}
    }

    return primaryProjects;
  }

  @override
  Future<ProjectEntity?> getCloudProject(String userId, String projectId) async {
    final primaryProject = await primary.getCloudProject(userId, projectId);
    if (primaryProject != null) return primaryProject;

    if (secondary != null) {
      try {
        return await secondary!.getCloudProject(userId, projectId);
      } catch (_) {}
    }
    return null;
  }

  @override
  Future<CloudBackupRecord> backupProject(String userId, ProjectEntity project) async {
    final record = await primary.backupProject(userId, project);

    if (secondary != null) {
      try {
        await secondary!.backupProject(userId, project);
      } catch (_) {}
    }

    return record;
  }

  @override
  Future<List<CloudBackupRecord>> getBackupRecords(String userId) async {
    final primaryRecords = await primary.getBackupRecords(userId);
    if (primaryRecords.isNotEmpty) return primaryRecords;

    if (secondary != null) {
      try {
        final secRecords = await secondary!.getBackupRecords(userId);
        if (secRecords.isNotEmpty) return secRecords;
      } catch (_) {}
    }

    return primaryRecords;
  }

  @override
  Future<void> deleteCloudProject(String userId, String projectId) async {
    await primary.deleteCloudProject(userId, projectId);
    if (secondary != null) {
      try {
        await secondary!.deleteCloudProject(userId, projectId);
      } catch (_) {}
    }
  }

  @override
  Future<int> calculateUserStorageUsage(String userId) async {
    return await primary.calculateUserStorageUsage(userId);
  }
}
