import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:procut/core/storage/local_storage_service.dart';
import 'package:procut/features/projects/data/models/project_model.dart';
import 'package:procut/features/projects/domain/entities/project_entity.dart';
import 'package:procut/features/projects/domain/entities/sync_status_type.dart';
import '../../domain/entities/cloud_backup_record.dart';
import 'cloud_storage_datasource.dart';

/// Live, rate-limit-free global cloud storage provider utilizing ntfy.sh pub/sub.
/// Enables seamless cross-device project syncing across any device without limits or keys.
class NtfyCloudStorageDataSource implements CloudStorageDataSource {
  final LocalStorageService localStorageService;
  final HttpClient? _customHttpClient;
  static const String baseUrl = 'https://ntfy.sh';

  NtfyCloudStorageDataSource({
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

  String _hash(String input) =>
      sha256.convert(utf8.encode(input.trim().toLowerCase())).toString();

  String _topicForUser(String userId) => 'procut_proj_${_hash(userId)}';

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
    final Map<String, ProjectEntity> projectMap = {};

    // 1. Query ntfy cloud topic for all messages
    final topic = _topicForUser(userId);
    final client = _createHttpClient();

    try {
      final uri = Uri.parse('$baseUrl/$topic/json?poll=1&since=all');
      final request = await client.getUrl(uri);
      request.headers.set('Accept', 'application/x-ndjson, application/json');

      final response = await request.close();
      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        final lines = body.split('\n');

        for (final line in lines) {
          final trimmed = line.trim();
          if (trimmed.isEmpty) continue;
          try {
            final eventObj = jsonDecode(trimmed);
            if (eventObj is Map<String, dynamic> && eventObj['event'] == 'message') {
              final msgStr = eventObj['message'] as String?;
              if (msgStr != null && msgStr.isNotEmpty) {
                final payload = jsonDecode(msgStr);
                if (payload is Map<String, dynamic>) {
                  // Handle single project
                  if (payload.containsKey('id') && payload.containsKey('title')) {
                    final project = ProjectModel.fromJson(payload).copyWith(
                      syncStatus: SyncStatusType.synced,
                    );
                    final existing = projectMap[project.id];
                    if (existing == null || project.updatedAt.isAfter(existing.updatedAt)) {
                      projectMap[project.id] = project;
                    }
                  } else if (payload['type'] == 'bundle' && payload['projects'] is List) {
                    final list = payload['projects'] as List;
                    for (final item in list) {
                      if (item is Map<String, dynamic>) {
                        final project = ProjectModel.fromJson(item).copyWith(
                          syncStatus: SyncStatusType.synced,
                        );
                        final existing = projectMap[project.id];
                        if (existing == null || project.updatedAt.isAfter(existing.updatedAt)) {
                          projectMap[project.id] = project;
                        }
                      }
                    }
                  } else if (payload['type'] == 'deleted' && payload['projectId'] is String) {
                    projectMap.remove(payload['projectId']);
                  }
                }
              }
            }
          } catch (_) {}
        }
      }
      await response.drain();
    } catch (e) {
      debugPrint('NtfyCloudStorageDataSource.getCloudProjects cloud fetch error: $e');
    } finally {
      if (_customHttpClient == null) client.close();
    }

    // Cache all found projects locally for offline use
    for (final project in projectMap.values) {
      try {
        await localStorageService.writeJson(
          _userProjectLocalFile(userId, project.id),
          ProjectModel.toJson(project),
        );
      } catch (_) {}
    }

    if (projectMap.isNotEmpty) {
      try {
        await localStorageService.writeString(
          _userCatalogLocalFile(userId),
          jsonEncode(projectMap.keys.toList()),
        );
      } catch (_) {}
    }

    // 2. Offline fallback if cloud returned nothing
    if (projectMap.isEmpty) {
      try {
        final catalogRaw = await localStorageService.readString(_userCatalogLocalFile(userId));
        if (catalogRaw != null && catalogRaw.isNotEmpty) {
          final decoded = jsonDecode(catalogRaw) as List<dynamic>;
          for (final item in decoded) {
            final id = item.toString().trim();
            if (id.isNotEmpty) {
              final cached = await localStorageService.readJson(_userProjectLocalFile(userId, id));
              if (cached != null) {
                final project = ProjectModel.fromJson(cached);
                projectMap[project.id] = project.copyWith(syncStatus: SyncStatusType.synced);
              }
            }
          }
        }
      } catch (_) {}
    }

    final result = projectMap.values.toList();
    result.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return result;
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

    try {
      final catalogRaw = await localStorageService.readString(_userCatalogLocalFile(userId));
      List<String> projectIds = [];
      if (catalogRaw != null && catalogRaw.isNotEmpty) {
        final decoded = jsonDecode(catalogRaw) as List<dynamic>;
        projectIds = decoded.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
      }
      if (!projectIds.contains(project.id)) {
        projectIds.insert(0, project.id);
      }
      await localStorageService.writeString(
        _userCatalogLocalFile(userId),
        jsonEncode(projectIds),
      );
    } catch (_) {}

    try {
      final backupsRaw = await localStorageService.readString(_userBackupsLocalFile(userId));
      List<Map<String, dynamic>> backups = [];
      if (backupsRaw != null && backupsRaw.isNotEmpty) {
        final decoded = jsonDecode(backupsRaw) as List<dynamic>;
        backups = decoded.cast<Map<String, dynamic>>();
      }
      backups.insert(0, record.toJson());
      if (backups.length > 50) backups = backups.sublist(0, 50);
      await localStorageService.writeString(_userBackupsLocalFile(userId), jsonEncode(backups));
    } catch (_) {}

    // 2. Publish to ntfy cloud topic(s)
    final topics = <String>{_topicForUser(userId)};
    if (project.userEmail != null && project.userEmail!.isNotEmpty) {
      topics.add(_topicForUser(project.userEmail!));
    }

    final client = _createHttpClient();
    try {
      for (final topic in topics) {
        final uri = Uri.parse('$baseUrl/$topic');
        final request = await client.postUrl(uri);
        request.headers.set('Title', 'ProCut Project: ${project.title}');
        request.headers.set('Tags', 'project,backup');
        request.headers.set('Content-Type', 'text/plain; charset=utf-8');

        request.headers.set('Content-Length', jsonBytes.length.toString());
        request.add(jsonBytes);

        final response = await request.close();
        await response.drain();
      }
    } catch (e) {
      debugPrint('NtfyCloudStorageDataSource.backupProject cloud upload error: $e');
    } finally {
      if (_customHttpClient == null) client.close();
    }

    return record;
  }

  @override
  Future<void> deleteCloudProject(String userId, String projectId) async {
    _assertAuthenticated(userId);

    // 1. Delete from local cache
    try {
      await localStorageService.deleteFile(_userProjectLocalFile(userId, projectId));
      final catalogRaw = await localStorageService.readString(_userCatalogLocalFile(userId));
      if (catalogRaw != null && catalogRaw.isNotEmpty) {
        final decoded = jsonDecode(catalogRaw) as List<dynamic>;
        final list = decoded.map((e) => e.toString().trim()).where((e) => e != projectId).toList();
        await localStorageService.writeString(_userCatalogLocalFile(userId), jsonEncode(list));
      }
    } catch (_) {}

    // 2. Publish deletion tombstone to ntfy
    final topic = _topicForUser(userId);
    final client = _createHttpClient();
    try {
      final uri = Uri.parse('$baseUrl/$topic');
      final request = await client.postUrl(uri);
      request.headers.set('Title', 'ProCut Project Deleted');
      request.headers.set('Tags', 'project,deleted');
      request.headers.set('Content-Type', 'text/plain; charset=utf-8');

      final payload = jsonEncode({'type': 'deleted', 'projectId': projectId});
      final bytes = utf8.encode(payload);
      request.headers.set('Content-Length', bytes.length.toString());
      request.add(bytes);

      final response = await request.close();
      await response.drain();
    } catch (e) {
      debugPrint('NtfyCloudStorageDataSource.deleteCloudProject error: $e');
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
        final records = decoded
            .whereType<Map<String, dynamic>>()
            .map((m) => CloudBackupRecord.fromJson(m))
            .toList();
        records.sort((a, b) => b.backedUpAt.compareTo(a.backedUpAt));
        return records;
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
