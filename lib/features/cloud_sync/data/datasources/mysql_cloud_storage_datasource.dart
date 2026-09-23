import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:procut/core/config/server_config.dart';
import 'package:procut/core/network/api_client.dart';
import 'package:procut/core/storage/local_storage_service.dart';
import 'package:procut/features/projects/data/models/project_model.dart';
import 'package:procut/features/projects/domain/entities/project_entity.dart';
import 'package:procut/features/projects/domain/entities/sync_status_type.dart';
import '../../domain/entities/cloud_backup_record.dart';
import 'cloud_storage_datasource.dart';

/// Dedicated MySQL Cloud Project Storage Provider connecting to ProCut's backend server.
class MySqlCloudStorageDataSource implements CloudStorageDataSource {
  final LocalStorageService localStorageService;

  MySqlCloudStorageDataSource({
    required this.localStorageService,
    dynamic httpClient,
  });

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

  /// Resolves the user's email address by checking active accounts and session
  Future<String?> _resolveUserEmail(String userId, [String? explicitEmail]) async {
    if (explicitEmail != null && explicitEmail.trim().isNotEmpty) {
      return explicitEmail.trim().toLowerCase();
    }

    // 1. Try reading from auth/accounts.json
    try {
      final raw = await localStorageService.readString('auth/accounts.json');
      if (raw != null && raw.isNotEmpty) {
        final list = jsonDecode(raw) as List<dynamic>;
        for (final acc in list) {
          if (acc is Map && acc['id'] == userId) {
            final email = acc['email'] as String?;
            if (email != null && email.trim().isNotEmpty) {
              return email.trim().toLowerCase();
            }
          }
        }
      }
    } catch (_) {}

    // 2. Try reading from auth/session.json
    try {
      final session = await localStorageService.readJson('auth/session.json');
      if (session != null) {
        if (session['userId'] == userId && session['email'] != null) {
          final email = session['email'] as String?;
          if (email != null && email.trim().isNotEmpty) {
            return email.trim().toLowerCase();
          }
        }
      }
    } catch (_) {}

    return null;
  }

  @override
  Future<List<ProjectEntity>> getCloudProjects(String userId, [String? userEmail]) async {
    _assertAuthenticated(userId);
    final List<ProjectEntity> projects = [];
    final baseUrl = await ServerConfig.getBaseUrl();

    try {
      final resolvedEmail = await _resolveUserEmail(userId, userEmail);

      final queryParts = ['userId=${Uri.encodeComponent(userId)}'];
      if (resolvedEmail != null && resolvedEmail.isNotEmpty) {
        queryParts.add('userEmail=${Uri.encodeComponent(resolvedEmail)}');
      }

      final uri = Uri.parse('$baseUrl/api/projects?${queryParts.join('&')}');
      final response = await ApiClient.get(uri);
      if (response.isOk && response.json is Map) {
        final decoded = response.json as Map<String, dynamic>;
        if (decoded['projects'] is List) {
          final list = decoded['projects'] as List;
          for (final item in list) {
            if (item is Map<String, dynamic>) {
              try {
                final project = ProjectModel.fromJson(item).copyWith(
                  syncStatus: SyncStatusType.synced,
                  userId: userId,
                  userEmail: resolvedEmail ?? item['userEmail'] as String?,
                );
                projects.add(project);
                // Cache locally
                await localStorageService.writeJson(
                  _userProjectLocalFile(userId, project.id),
                  ProjectModel.toJson(project),
                );
              } catch (e) {
                debugPrint('Error parsing project from MySQL server: $e');
              }
            }
          }

          if (projects.isNotEmpty) {
            await localStorageService.writeString(
              _userCatalogLocalFile(userId),
              jsonEncode(projects.map((p) => p.id).toList()),
            );
          }

          projects.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
          return projects;
        }
      }
    } catch (e) {
      debugPrint('MySqlCloudStorageDataSource.getCloudProjects server fetch error: $e');
    }

    // Offline fallback from local cache
    try {
      final catalogRaw = await localStorageService.readString(_userCatalogLocalFile(userId));
      if (catalogRaw != null && catalogRaw.isNotEmpty) {
        final decoded = jsonDecode(catalogRaw) as List<dynamic>;
        for (final id in decoded) {
          final cached = await localStorageService.readJson(_userProjectLocalFile(userId, id.toString()));
          if (cached != null) {
            projects.add(ProjectModel.fromJson(cached).copyWith(syncStatus: SyncStatusType.synced));
          }
        }
      }
    } catch (_) {}

    projects.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return projects;
  }

  @override
  Future<ProjectEntity?> getCloudProject(String userId, String projectId) async {
    _assertAuthenticated(userId);
    final projects = await getCloudProjects(userId);
    for (final p in projects) {
      if (p.id == projectId) return p;
    }
    return null;
  }

  @override
  Future<CloudBackupRecord> backupProject(String userId, ProjectEntity project) async {
    _assertAuthenticated(userId);
    final now = DateTime.now();
    final resolvedEmail = await _resolveUserEmail(userId, project.userEmail);

    final syncedProject = project.copyWith(
      syncStatus: SyncStatusType.synced,
      userId: userId,
      userEmail: resolvedEmail ?? project.userEmail,
      updatedAt: now,
    );

    final projectJson = ProjectModel.toJson(syncedProject);
    projectJson['userId'] = userId;
    if (resolvedEmail != null && resolvedEmail.isNotEmpty) {
      projectJson['userEmail'] = resolvedEmail;
    }
    final jsonString = jsonEncode(projectJson);
    final jsonBytes = utf8.encode(jsonString);
    final checksum = sha256.convert(jsonBytes).toString().substring(0, 16);
    final fileSizeBytes = jsonBytes.length;

    final record = CloudBackupRecord(
      projectId: project.id,
      projectTitle: project.title,
      fileSizeBytes: fileSizeBytes,
      backedUpAt: now,
      cloudChecksum: checksum,
    );

    // 1. Cache locally
    await localStorageService.writeJson(_userProjectLocalFile(userId, project.id), projectJson);

    // 2. Upload to MySQL server
    final baseUrl = await ServerConfig.getBaseUrl();
    try {
      final uri = Uri.parse('$baseUrl/api/projects/backup');
      await ApiClient.post(
        uri,
        body: {
          'userId': userId,
          'userEmail': resolvedEmail ?? '',
          'project': projectJson,
        },
      );
    } catch (e) {
      debugPrint('MySqlCloudStorageDataSource.backupProject server upload error: $e');
    }

    return record;
  }

  @override
  Future<void> deleteCloudProject(String userId, String projectId) async {
    _assertAuthenticated(userId);
    // 1. Delete locally
    await localStorageService.deleteFile(_userProjectLocalFile(userId, projectId));

    // 2. Delete on MySQL server
    final baseUrl = await ServerConfig.getBaseUrl();
    try {
      final resolvedEmail = await _resolveUserEmail(userId);
      final queryParts = ['userId=${Uri.encodeComponent(userId)}'];
      if (resolvedEmail != null && resolvedEmail.isNotEmpty) {
        queryParts.add('userEmail=${Uri.encodeComponent(resolvedEmail)}');
      }

      final uri = Uri.parse('$baseUrl/api/projects/$projectId?${queryParts.join('&')}');
      await ApiClient.delete(uri);
    } catch (e) {
      debugPrint('MySqlCloudStorageDataSource.deleteCloudProject server error: $e');
    }
  }

  @override
  Future<List<CloudBackupRecord>> getBackupRecords(String userId) async {
    _assertAuthenticated(userId);
    try {
      final backupsRaw = await localStorageService.readString(_userBackupsLocalFile(userId));
      if (backupsRaw != null && backupsRaw.isNotEmpty) {
        final decoded = jsonDecode(backupsRaw) as List<dynamic>;
        return decoded
            .whereType<Map<String, dynamic>>()
            .map((m) => CloudBackupRecord.fromJson(m))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  @override
  Future<int> calculateUserStorageUsage(String userId) async {
    _assertAuthenticated(userId);
    int totalBytes = 0;
    try {
      final projects = await getCloudProjects(userId);
      for (final p in projects) {
        final jsonStr = jsonEncode(ProjectModel.toJson(p));
        totalBytes += utf8.encode(jsonStr).length;
      }
    } catch (_) {}
    return totalBytes;
  }
}
