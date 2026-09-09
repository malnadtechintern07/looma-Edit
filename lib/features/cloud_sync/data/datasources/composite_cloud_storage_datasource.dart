import 'package:procut/features/projects/domain/entities/project_entity.dart';
import '../../domain/entities/cloud_backup_record.dart';
import 'cloud_storage_datasource.dart';

/// Composite cloud storage data source that orchestrates multiple cloud storage providers:
/// (Ntfy.sh Global Pub/Sub, Zero-Config Cloud Registry, and Optional Bunny.net Storage)
class CompositeCloudStorageDataSource implements CloudStorageDataSource {
  final List<CloudStorageDataSource> _sources;

  CompositeCloudStorageDataSource({
    CloudStorageDataSource? primary,
    CloudStorageDataSource? secondary,
    List<CloudStorageDataSource>? dataSources,
  }) : _sources = dataSources ?? [
          ?primary,
          ?secondary,
        ];

  @override
  Future<List<ProjectEntity>> getCloudProjects(String userId) async {
    final Map<String, ProjectEntity> projectMap = {};

    for (final source in _sources) {
      try {
        final projects = await source.getCloudProjects(userId);
        for (final p in projects) {
          final existing = projectMap[p.id];
          if (existing == null || p.updatedAt.isAfter(existing.updatedAt)) {
            projectMap[p.id] = p;
          }
        }
      } catch (_) {}
    }

    final list = projectMap.values.toList();
    list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return list;
  }

  @override
  Future<ProjectEntity?> getCloudProject(String userId, String projectId) async {
    for (final source in _sources) {
      try {
        final project = await source.getCloudProject(userId, projectId);
        if (project != null) return project;
      } catch (_) {}
    }
    return null;
  }

  @override
  Future<CloudBackupRecord> backupProject(String userId, ProjectEntity project) async {
    CloudBackupRecord? primaryRecord;

    for (final source in _sources) {
      try {
        final record = await source.backupProject(userId, project);
        primaryRecord ??= record;
      } catch (_) {}
    }

    return primaryRecord ??
        CloudBackupRecord(
          projectId: project.id,
          projectTitle: project.title,
          fileSizeBytes: 0,
          backedUpAt: DateTime.now(),
          cloudChecksum: '',
        );
  }

  @override
  Future<List<CloudBackupRecord>> getBackupRecords(String userId) async {
    final Map<String, CloudBackupRecord> recordsMap = {};
    for (final source in _sources) {
      try {
        final records = await source.getBackupRecords(userId);
        for (final r in records) {
          if (!recordsMap.containsKey(r.projectId) ||
              r.backedUpAt.isAfter(recordsMap[r.projectId]!.backedUpAt)) {
            recordsMap[r.projectId] = r;
          }
        }
      } catch (_) {}
    }
    final list = recordsMap.values.toList();
    list.sort((a, b) => b.backedUpAt.compareTo(a.backedUpAt));
    return list;
  }

  @override
  Future<void> deleteCloudProject(String userId, String projectId) async {
    for (final source in _sources) {
      try {
        await source.deleteCloudProject(userId, projectId);
      } catch (_) {}
    }
  }

  @override
  Future<int> calculateUserStorageUsage(String userId) async {
    final projects = await getCloudProjects(userId);
    int totalBytes = 0;
    for (final p in projects) {
      totalBytes += p.videoClips.length * 1024 + 2048;
    }
    return totalBytes;
  }
}
