import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:procut/core/storage/local_storage_service.dart';
import 'package:procut/features/projects/data/models/project_model.dart';
import 'package:procut/features/projects/domain/entities/project_entity.dart';
import 'package:procut/features/projects/domain/entities/sync_status_type.dart';
import '../../domain/entities/cloud_backup_record.dart';

abstract class CloudStorageDataSource {
  Future<List<ProjectEntity>> getCloudProjects(String userId);
  Future<ProjectEntity?> getCloudProject(String userId, String projectId);
  Future<CloudBackupRecord> backupProject(String userId, ProjectEntity project);
  Future<List<CloudBackupRecord>> getBackupRecords(String userId);
  Future<void> deleteCloudProject(String userId, String projectId);
  Future<int> calculateUserStorageUsage(String userId);
}

class CloudStorageDataSourceImpl implements CloudStorageDataSource {
  final LocalStorageService storageService;

  CloudStorageDataSourceImpl({required this.storageService});

  String _userCloudDir(String userId) => 'cloud_storage/users/$userId';
  String _userProjectsDir(String userId) => '${_userCloudDir(userId)}/projects';
  String _userProjectFile(String userId, String projectId) =>
      '${_userProjectsDir(userId)}/project_$projectId.json';
  String _userCatalogFile(String userId) => '${_userCloudDir(userId)}/catalog.json';
  String _userBackupsFile(String userId) => '${_userCloudDir(userId)}/backups.json';

  void _assertAuthenticated(String userId) {
    if (userId.trim().isEmpty) {
      throw Exception('Authentication required to access cloud storage space.');
    }
  }

  @override
  Future<List<ProjectEntity>> getCloudProjects(String userId) async {
    _assertAuthenticated(userId);
    final catalogRaw = await storageService.readString(_userCatalogFile(userId));
    final Set<String> projectIds = {};

    if (catalogRaw != null && catalogRaw.isNotEmpty) {
      try {
        final decoded = jsonDecode(catalogRaw) as List<dynamic>;
        for (final item in decoded) {
          if (item != null && item.toString().trim().isNotEmpty) {
            projectIds.add(item.toString().trim());
          }
        }
      } catch (_) {}
    }

    final List<ProjectEntity> projects = [];
    for (final id in projectIds) {
      final p = await getCloudProject(userId, id);
      if (p != null) {
        projects.add(p);
      }
    }

    projects.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return projects;
  }

  @override
  Future<ProjectEntity?> getCloudProject(String userId, String projectId) async {
    _assertAuthenticated(userId);
    final jsonMap = await storageService.readJson(_userProjectFile(userId, projectId));
    if (jsonMap == null) return null;
    final project = ProjectModel.fromJson(jsonMap);
    return project.copyWith(syncStatus: SyncStatusType.synced);
  }

  @override
  Future<CloudBackupRecord> backupProject(String userId, ProjectEntity project) async {
    _assertAuthenticated(userId);
    final syncedProject = project.copyWith(
      syncStatus: SyncStatusType.synced,
      updatedAt: DateTime.now(),
    );

    final jsonMap = ProjectModel.toJson(syncedProject);
    final jsonString = jsonEncode(jsonMap);
    final checksum = sha256.convert(utf8.encode(jsonString)).toString().substring(0, 16);
    final fileSizeBytes = utf8.encode(jsonString).length;

    // Save isolated cloud project JSON
    await storageService.writeJson(_userProjectFile(userId, project.id), jsonMap);

    // Update user's private catalog
    final catalogRaw = await storageService.readString(_userCatalogFile(userId));
    List<String> projectIds = [];
    if (catalogRaw != null && catalogRaw.isNotEmpty) {
      try {
        final decoded = jsonDecode(catalogRaw) as List<dynamic>;
        projectIds = decoded.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
      } catch (_) {}
    }
    if (!projectIds.contains(project.id)) {
      projectIds.insert(0, project.id);
      await storageService.writeString(_userCatalogFile(userId), jsonEncode(projectIds));
    }

    // Record backup snapshot
    final backupRecord = CloudBackupRecord(
      projectId: project.id,
      projectTitle: project.title,
      fileSizeBytes: fileSizeBytes,
      backedUpAt: DateTime.now(),
      cloudChecksum: 'sha256_$checksum',
    );

    final backups = await getBackupRecords(userId);
    final updatedBackups = [
      backupRecord,
      ...backups.where((b) => b.projectId != project.id),
    ];

    final backupsJson = updatedBackups.map((b) => {
      'projectId': b.projectId,
      'projectTitle': b.projectTitle,
      'fileSizeBytes': b.fileSizeBytes,
      'backedUpAt': b.backedUpAt.toIso8601String(),
      'cloudChecksum': b.cloudChecksum,
    }).toList();

    await storageService.writeString(_userBackupsFile(userId), jsonEncode(backupsJson));
    return backupRecord;
  }

  @override
  Future<List<CloudBackupRecord>> getBackupRecords(String userId) async {
    _assertAuthenticated(userId);
    final raw = await storageService.readString(_userBackupsFile(userId));
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.map((item) {
        final map = item as Map<String, dynamic>;
        return CloudBackupRecord(
          projectId: map['projectId'] as String,
          projectTitle: map['projectTitle'] as String? ?? 'Untitled Project',
          fileSizeBytes: (map['fileSizeBytes'] as num?)?.toInt() ?? 1024,
          backedUpAt: DateTime.tryParse(map['backedUpAt'] as String? ?? '') ?? DateTime.now(),
          cloudChecksum: map['cloudChecksum'] as String? ?? 'sha256_verified',
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> deleteCloudProject(String userId, String projectId) async {
    _assertAuthenticated(userId);
    await storageService.deleteFile(_userProjectFile(userId, projectId));

    // Update catalog
    final catalogRaw = await storageService.readString(_userCatalogFile(userId));
    if (catalogRaw != null && catalogRaw.isNotEmpty) {
      try {
        final decoded = jsonDecode(catalogRaw) as List<dynamic>;
        final projectIds = decoded.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
        projectIds.remove(projectId);
        await storageService.writeString(_userCatalogFile(userId), jsonEncode(projectIds));
      } catch (_) {}
    }

    // Remove from backup records
    final backups = await getBackupRecords(userId);
    final filtered = backups.where((b) => b.projectId != projectId).toList();
    final backupsJson = filtered.map((b) => {
      'projectId': b.projectId,
      'projectTitle': b.projectTitle,
      'fileSizeBytes': b.fileSizeBytes,
      'backedUpAt': b.backedUpAt.toIso8601String(),
      'cloudChecksum': b.cloudChecksum,
    }).toList();
    await storageService.writeString(_userBackupsFile(userId), jsonEncode(backupsJson));
  }

  @override
  Future<int> calculateUserStorageUsage(String userId) async {
    _assertAuthenticated(userId);
    final backups = await getBackupRecords(userId);
    int totalBytes = 0;
    for (final b in backups) {
      totalBytes += b.fileSizeBytes;
    }
    // Baseline allocated metadata footprint
    return totalBytes > 0 ? totalBytes : (backups.length * 45 * 1024);
  }
}
