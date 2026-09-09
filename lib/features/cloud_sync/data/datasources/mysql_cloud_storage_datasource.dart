import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:procut/core/config/server_config.dart';
import 'package:procut/core/storage/local_storage_service.dart';
import 'package:procut/features/projects/data/models/project_model.dart';
import 'package:procut/features/projects/domain/entities/project_entity.dart';
import 'package:procut/features/projects/domain/entities/sync_status_type.dart';
import '../../domain/entities/cloud_backup_record.dart';
import 'cloud_storage_datasource.dart';

/// Dedicated MySQL Cloud Project Storage Provider connecting to ProCut's backend server.
class MySqlCloudStorageDataSource implements CloudStorageDataSource {
  final LocalStorageService localStorageService;
  final HttpClient? _customHttpClient;

  MySqlCloudStorageDataSource({
    required this.localStorageService,
    HttpClient? httpClient,
  }) : _customHttpClient = httpClient;

  HttpClient _createHttpClient() {
    final custom = _customHttpClient;
    if (custom != null) return custom;
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 8);
    return client;
  }

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
    final List<ProjectEntity> projects = [];
    final baseUrl = await ServerConfig.getBaseUrl();
    final client = _createHttpClient();

    try {
      final uri = Uri.parse('$baseUrl/api/projects?userId=${Uri.encodeComponent(userId)}');
      final request = await client.getUrl(uri);
      request.headers.set('Accept', 'application/json');

      final response = await request.close();
      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        final decoded = jsonDecode(body);
        if (decoded is Map<String, dynamic> && decoded['projects'] is List) {
          final list = decoded['projects'] as List;
          for (final item in list) {
            if (item is Map<String, dynamic>) {
              try {
                final project = ProjectModel.fromJson(item).copyWith(
                  syncStatus: SyncStatusType.synced,
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
      await response.drain();
    } catch (e) {
      debugPrint('MySqlCloudStorageDataSource.getCloudProjects server fetch error: $e');
    } finally {
      if (_customHttpClient == null) client.close();
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
    final syncedProject = project.copyWith(
      syncStatus: SyncStatusType.synced,
      updatedAt: now,
    );

    final projectJson = ProjectModel.toJson(syncedProject);
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
    final client = _createHttpClient();
    try {
      final uri = Uri.parse('$baseUrl/api/projects/backup');
      final request = await client.postUrl(uri);
      request.headers.set('Content-Type', 'application/json');
      final payload = jsonEncode({
        'userId': userId,
        'userEmail': project.userEmail ?? '',
        'project': projectJson,
      });
      request.add(utf8.encode(payload));

      final response = await request.close();
      await response.drain();
    } catch (e) {
      debugPrint('MySqlCloudStorageDataSource.backupProject server upload error: $e');
    } finally {
      if (_customHttpClient == null) client.close();
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
    final client = _createHttpClient();
    try {
      final uri = Uri.parse('$baseUrl/api/projects/$projectId?userId=${Uri.encodeComponent(userId)}');
      final request = await client.deleteUrl(uri);
      final response = await request.close();
      await response.drain();
    } catch (e) {
      debugPrint('MySqlCloudStorageDataSource.deleteCloudProject server error: $e');
    } finally {
      if (_customHttpClient == null) client.close();
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
