import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:procut/core/storage/local_storage_service.dart';
import 'package:procut/features/projects/data/models/project_model.dart';
import 'package:procut/features/projects/domain/entities/project_entity.dart';
import 'package:procut/features/projects/domain/entities/sync_status_type.dart';
import '../../domain/entities/bunny_storage_config.dart';
import '../../domain/entities/cloud_backup_record.dart';
import 'bunny_storage_service.dart';
import 'cloud_storage_datasource.dart';

/// Cloud storage data source communicating with Bunny.net Edge Storage
/// when user is authenticated, with local cache fallback for offline resiliency.
class BunnyCloudStorageDataSource implements CloudStorageDataSource {
  final LocalStorageService localStorageService;
  final BunnyStorageConfig config;
  final BunnyStorageService bunnyService;

  BunnyCloudStorageDataSource({
    required this.localStorageService,
    required this.config,
    BunnyStorageService? bunnyStorageService,
  }) : bunnyService = bunnyStorageService ?? BunnyStorageService(config: config);

  // Bunny.net remote paths
  String _userBunnyDir(String userId) => 'procut/users/$userId';
  String _userProjectsBunnyDir(String userId) => '${_userBunnyDir(userId)}/projects';
  String _userProjectBunnyFile(String userId, String projectId) =>
      '${_userProjectsBunnyDir(userId)}/project_$projectId.json';
  String _userCatalogBunnyFile(String userId) => '${_userBunnyDir(userId)}/catalog.json';
  String _userBackupsBunnyFile(String userId) => '${_userBunnyDir(userId)}/backups.json';

  // Local cache paths for instant offline access
  String _userLocalDir(String userId) => 'cloud_storage/users/$userId';
  String _userProjectsLocalDir(String userId) => '${_userLocalDir(userId)}/projects';
  String _userProjectLocalFile(String userId, String projectId) =>
      '${_userProjectsLocalDir(userId)}/project_$projectId.json';
  String _userCatalogLocalFile(String userId) => '${_userLocalDir(userId)}/catalog.json';
  String _userBackupsLocalFile(String userId) => '${_userLocalDir(userId)}/backups.json';

  void _assertAuthenticated(String userId) {
    if (userId.trim().isEmpty) {
      throw Exception('Authentication required to access cloud storage space.');
    }
  }

  @override
  Future<List<ProjectEntity>> getCloudProjects(String userId) async {
    _assertAuthenticated(userId);
    final Set<String> projectIds = {};

    // 1. Try fetching remote catalog from Bunny.net
    try {
      final remoteCatalog = await bunnyService.downloadFile(_userCatalogBunnyFile(userId));
      if (remoteCatalog != null && remoteCatalog.isNotEmpty) {
        final decoded = jsonDecode(remoteCatalog) as List<dynamic>;
        for (final item in decoded) {
          final id = item.toString().trim();
          if (id.isNotEmpty) projectIds.add(id);
        }
        // Cache remote catalog locally
        await localStorageService.writeString(_userCatalogLocalFile(userId), remoteCatalog);
      }
    } catch (e) {
      debugPrint('BunnyCloudStorageDataSource: download remote catalog error: $e');
    }

    // 2. If remote catalog was empty or failed, fallback to local cached catalog
    if (projectIds.isEmpty) {
      final localCatalogRaw = await localStorageService.readString(_userCatalogLocalFile(userId));
      if (localCatalogRaw != null && localCatalogRaw.isNotEmpty) {
        try {
          final decoded = jsonDecode(localCatalogRaw) as List<dynamic>;
          for (final item in decoded) {
            final id = item.toString().trim();
            if (id.isNotEmpty) projectIds.add(id);
          }
        } catch (_) {}
      }
    }

    // 3. Fetch each cloud project
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

    // 1. Try downloading from Bunny.net
    try {
      final remoteJson = await bunnyService.downloadFile(_userProjectBunnyFile(userId, projectId));
      if (remoteJson != null && remoteJson.isNotEmpty) {
        final decoded = jsonDecode(remoteJson) as Map<String, dynamic>;
        final project = ProjectModel.fromJson(decoded);

        // Update local cache
        await localStorageService.writeString(_userProjectLocalFile(userId, projectId), remoteJson);
        return project.copyWith(syncStatus: SyncStatusType.synced);
      }
    } catch (e) {
      debugPrint('BunnyCloudStorageDataSource: download project error for $projectId: $e');
    }

    // 2. Fallback to local cache if offline
    final localJson = await localStorageService.readJson(_userProjectLocalFile(userId, projectId));
    if (localJson != null) {
      final project = ProjectModel.fromJson(localJson);
      return project.copyWith(syncStatus: SyncStatusType.synced);
    }

    return null;
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
    final jsonBytes = utf8.encode(jsonString);
    final checksum = sha256.convert(jsonBytes).toString().substring(0, 16);
    final fileSizeBytes = jsonBytes.length;

    // 1. Always update local cache immediately
    await localStorageService.writeJson(_userProjectLocalFile(userId, project.id), jsonMap);

    // 2. Upload project file to Bunny.net
    try {
      await bunnyService.uploadFile(
        _userProjectBunnyFile(userId, project.id),
        jsonBytes,
        contentType: 'application/json',
      );
    } catch (e) {
      debugPrint('BunnyCloudStorageDataSource: project upload error: $e');
    }

    // 3. Update user catalog
    final catalogRaw = await localStorageService.readString(_userCatalogLocalFile(userId));
    List<String> projectIds = [];
    if (catalogRaw != null && catalogRaw.isNotEmpty) {
      try {
        final decoded = jsonDecode(catalogRaw) as List<dynamic>;
        projectIds = decoded.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
      } catch (_) {}
    }
    if (!projectIds.contains(project.id)) {
      projectIds.insert(0, project.id);
      final catalogEncoded = jsonEncode(projectIds);
      await localStorageService.writeString(_userCatalogLocalFile(userId), catalogEncoded);

      // Upload catalog to Bunny.net
      try {
        await bunnyService.uploadFile(
          _userCatalogBunnyFile(userId),
          utf8.encode(catalogEncoded),
          contentType: 'application/json',
        );
      } catch (_) {}
    }

    // 4. Create and upload backup record
    final backupRecord = CloudBackupRecord(
      projectId: project.id,
      projectTitle: project.title,
      fileSizeBytes: fileSizeBytes,
      backedUpAt: DateTime.now(),
      cloudChecksum: 'bny_$checksum',
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

    final backupsEncoded = jsonEncode(backupsJson);
    await localStorageService.writeString(_userBackupsLocalFile(userId), backupsEncoded);

    // Upload backups to Bunny.net
    try {
      await bunnyService.uploadFile(
        _userBackupsBunnyFile(userId),
        utf8.encode(backupsEncoded),
        contentType: 'application/json',
      );
    } catch (_) {}

    return backupRecord;
  }

  @override
  Future<List<CloudBackupRecord>> getBackupRecords(String userId) async {
    _assertAuthenticated(userId);

    // 1. Try downloading backups from Bunny.net
    try {
      final remoteBackups = await bunnyService.downloadFile(_userBackupsBunnyFile(userId));
      if (remoteBackups != null && remoteBackups.isNotEmpty) {
        await localStorageService.writeString(_userBackupsLocalFile(userId), remoteBackups);
        final list = jsonDecode(remoteBackups) as List<dynamic>;
        return list.map((item) {
          final map = item as Map<String, dynamic>;
          return CloudBackupRecord(
            projectId: map['projectId'] as String,
            projectTitle: map['projectTitle'] as String? ?? 'Untitled Project',
            fileSizeBytes: (map['fileSizeBytes'] as num?)?.toInt() ?? 1024,
            backedUpAt: DateTime.tryParse(map['backedUpAt'] as String? ?? '') ?? DateTime.now(),
            cloudChecksum: map['cloudChecksum'] as String? ?? 'bny_verified',
          );
        }).toList();
      }
    } catch (e) {
      debugPrint('BunnyCloudStorageDataSource: download backups error: $e');
    }

    // 2. Fallback to local cache
    final raw = await localStorageService.readString(_userBackupsLocalFile(userId));
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
          cloudChecksum: map['cloudChecksum'] as String? ?? 'bny_cached',
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> deleteCloudProject(String userId, String projectId) async {
    _assertAuthenticated(userId);

    // 1. Delete on Bunny.net
    try {
      await bunnyService.deleteFile(_userProjectBunnyFile(userId, projectId));
    } catch (e) {
      debugPrint('BunnyCloudStorageDataSource: delete remote project error: $e');
    }

    // 2. Delete locally
    await localStorageService.deleteFile(_userProjectLocalFile(userId, projectId));

    // 3. Update catalog
    final catalogRaw = await localStorageService.readString(_userCatalogLocalFile(userId));
    if (catalogRaw != null && catalogRaw.isNotEmpty) {
      try {
        final decoded = jsonDecode(catalogRaw) as List<dynamic>;
        final projectIds = decoded.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
        projectIds.remove(projectId);
        final catalogEncoded = jsonEncode(projectIds);
        await localStorageService.writeString(_userCatalogLocalFile(userId), catalogEncoded);

        // Upload updated catalog to Bunny.net
        try {
          await bunnyService.uploadFile(
            _userCatalogBunnyFile(userId),
            utf8.encode(catalogEncoded),
            contentType: 'application/json',
          );
        } catch (_) {}
      } catch (_) {}
    }

    // 4. Remove from backup records
    final backups = await getBackupRecords(userId);
    final filtered = backups.where((b) => b.projectId != projectId).toList();
    final backupsJson = filtered.map((b) => {
      'projectId': b.projectId,
      'projectTitle': b.projectTitle,
      'fileSizeBytes': b.fileSizeBytes,
      'backedUpAt': b.backedUpAt.toIso8601String(),
      'cloudChecksum': b.cloudChecksum,
    }).toList();
    final backupsEncoded = jsonEncode(backupsJson);
    await localStorageService.writeString(_userBackupsLocalFile(userId), backupsEncoded);

    // Upload updated backups to Bunny.net
    try {
      await bunnyService.uploadFile(
        _userBackupsBunnyFile(userId),
        utf8.encode(backupsEncoded),
        contentType: 'application/json',
      );
    } catch (_) {}
  }

  @override
  Future<int> calculateUserStorageUsage(String userId) async {
    _assertAuthenticated(userId);
    final backups = await getBackupRecords(userId);
    int totalBytes = 0;
    for (final b in backups) {
      totalBytes += b.fileSizeBytes;
    }
    return totalBytes > 0 ? totalBytes : (backups.length * 45 * 1024);
  }
}
