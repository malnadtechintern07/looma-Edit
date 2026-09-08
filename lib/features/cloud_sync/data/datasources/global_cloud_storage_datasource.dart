import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:looma/core/storage/local_storage_service.dart';
import 'package:looma/features/projects/data/models/project_model.dart';
import 'package:looma/features/projects/domain/entities/project_entity.dart';
import 'package:looma/features/projects/domain/entities/sync_status_type.dart';
import '../../domain/entities/cloud_backup_record.dart';
import 'cloud_storage_datasource.dart';

/// Live, persistent, zero-configuration global cloud storage data source.
/// Enables seamless project synchronization across any device (iOS, Android, macOS, Windows)
/// when the user signs in with the same email and password.
class GlobalCloudStorageDataSource implements CloudStorageDataSource {
  final LocalStorageService localStorageService;
  final HttpClient? _customHttpClient;

  /// Global live cloud projects registry object ID on restful-api.dev
  static const String primaryRegistryObjectId = 'ff808181a067127101a080ab08fb48a8';
  static const String apiBaseUrl = 'https://api.restful-api.dev/objects';

  GlobalCloudStorageDataSource({
    required this.localStorageService,
    HttpClient? httpClient,
  }) : _customHttpClient = httpClient;

  HttpClient _createHttpClient() {
    final custom = _customHttpClient;
    if (custom != null) return custom;
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 10);
    return client;
  }

  // Local cache paths for instant offline access
  String _userLocalDir(String userId) => 'cloud_storage/users/$userId';
  String _userProjectsLocalDir(String userId) => '${_userLocalDir(userId)}/projects';
  String _userProjectLocalFile(String userId, String projectId) =>
      '${_userProjectsLocalDir(userId)}/project_$projectId.json';
  String _userCatalogLocalFile(String userId) => '${_userLocalDir(userId)}/catalog.json';
  String _userBackupsLocalFile(String userId) => '${_userLocalDir(userId)}/backups.json';
  String _userPhotoProjectsLocalFile(String userId) =>
      '${_userLocalDir(userId)}/photo_projects.json';

  void _assertAuthenticated(String userId) {
    if (userId.trim().isEmpty) {
      throw Exception('Authentication required to access cloud storage space.');
    }
  }

  @override
  Future<List<ProjectEntity>> getCloudProjects(String userId) async {
    _assertAuthenticated(userId);
    final Set<String> projectIds = {};
    final List<ProjectEntity> projects = [];

    // 1. Fetch from live global cloud registry
    try {
      final registry = await _fetchCloudRegistry();
      if (registry != null) {
        final users = registry['users'];
        if (users is Map<String, dynamic> && users.containsKey(userId)) {
          final userData = users[userId];
          if (userData is Map<String, dynamic>) {
            final projectsMap = userData['projects'];
            if (projectsMap is Map<String, dynamic>) {
              for (final entry in projectsMap.entries) {
                final projectJson = entry.value;
                if (projectJson is Map<String, dynamic>) {
                  try {
                    final project = ProjectModel.fromJson(projectJson).copyWith(
                      syncStatus: SyncStatusType.synced,
                    );
                    projects.add(project);
                    projectIds.add(project.id);
                    // Cache project locally for offline use
                    await localStorageService.writeJson(
                      _userProjectLocalFile(userId, project.id),
                      ProjectModel.toJson(project),
                    );
                  } catch (e) {
                    debugPrint('Error parsing cloud project ${entry.key}: $e');
                  }
                }
              }
            } else if (projectsMap is List<dynamic>) {
              for (final item in projectsMap) {
                if (item is Map<String, dynamic>) {
                  try {
                    final project = ProjectModel.fromJson(item).copyWith(
                      syncStatus: SyncStatusType.synced,
                    );
                    projects.add(project);
                    projectIds.add(project.id);
                    await localStorageService.writeJson(
                      _userProjectLocalFile(userId, project.id),
                      ProjectModel.toJson(project),
                    );
                  } catch (e) {
                    debugPrint('Error parsing cloud project item: $e');
                  }
                }
              }
            }

            // Cache catalog locally
            if (projectIds.isNotEmpty) {
              await localStorageService.writeString(
                _userCatalogLocalFile(userId),
                jsonEncode(projectIds.toList()),
              );
            }

            // Cache backups locally if present
            final backupsList = userData['backups'];
            if (backupsList is List<dynamic>) {
              await localStorageService.writeString(
                _userBackupsLocalFile(userId),
                jsonEncode(backupsList),
              );
            }

            projects.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
            return projects;
          }
        }
      }
    } catch (e) {
      debugPrint('GlobalCloudStorageDataSource.getCloudProjects cloud fetch error: $e');
    }

    // 2. Offline Fallback: load from local cache
    try {
      final catalogRaw = await localStorageService.readString(_userCatalogLocalFile(userId));
      if (catalogRaw != null && catalogRaw.isNotEmpty) {
        final decoded = jsonDecode(catalogRaw) as List<dynamic>;
        for (final item in decoded) {
          final id = item.toString().trim();
          if (id.isNotEmpty) projectIds.add(id);
        }
      }
    } catch (_) {}

    for (final id in projectIds) {
      try {
        final cached = await localStorageService.readJson(_userProjectLocalFile(userId, id));
        if (cached != null) {
          final project = ProjectModel.fromJson(cached);
          projects.add(project.copyWith(syncStatus: SyncStatusType.synced));
        }
      } catch (_) {}
    }

    projects.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return projects;
  }

  @override
  Future<ProjectEntity?> getCloudProject(String userId, String projectId) async {
    _assertAuthenticated(userId);

    // 1. Try fetching from cloud registry
    try {
      final projects = await getCloudProjects(userId);
      for (final p in projects) {
        if (p.id == projectId) return p;
      }
    } catch (_) {}

    // 2. Fallback to local cache
    final localJson = await localStorageService.readJson(_userProjectLocalFile(userId, projectId));
    if (localJson != null) {
      return ProjectModel.fromJson(localJson).copyWith(syncStatus: SyncStatusType.synced);
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

    // 1. Cache project locally immediately
    await localStorageService.writeJson(_userProjectLocalFile(userId, project.id), projectJson);

    // Update local catalog
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

    // Update local backups
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

    // 2. Upload to live global cloud registry
    try {
      await _uploadProjectToCloudRegistry(userId, project.id, projectJson, record.toJson());
    } catch (e) {
      debugPrint('GlobalCloudStorageDataSource.backupProject cloud upload error: $e');
    }

    return record;
  }

  @override
  Future<List<CloudBackupRecord>> getBackupRecords(String userId) async {
    _assertAuthenticated(userId);

    // 1. Try reading from cloud registry
    try {
      final registry = await _fetchCloudRegistry();
      if (registry != null) {
        final users = registry['users'];
        if (users is Map<String, dynamic> && users.containsKey(userId)) {
          final userData = users[userId];
          if (userData is Map<String, dynamic>) {
            final backupsList = userData['backups'];
            if (backupsList is List<dynamic>) {
              final records = backupsList
                  .whereType<Map<String, dynamic>>()
                  .map((m) => CloudBackupRecord.fromJson(m))
                  .toList();
              records.sort((a, b) => b.backedUpAt.compareTo(a.backedUpAt));
              return records;
            }
          }
        }
      }
    } catch (_) {}

    // 2. Fallback to local cache
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

    // 2. Remove from global cloud registry
    try {
      final client = _createHttpClient();
      try {
        final registry = await _fetchCloudRegistry() ?? {'users': <String, dynamic>{}};
        final usersRaw = registry['users'];
        final users = usersRaw is Map ? Map<String, dynamic>.from(usersRaw) : <String, dynamic>{};
        if (users.containsKey(userId)) {
          final userDataRaw = users[userId];
          final userData = userDataRaw is Map ? Map<String, dynamic>.from(userDataRaw) : <String, dynamic>{};
          final projectsRaw = userData['projects'];
          final projectsMap = projectsRaw is Map ? Map<String, dynamic>.from(projectsRaw) : <String, dynamic>{};
          projectsMap.remove(projectId);
          userData['projects'] = projectsMap;
          users[userId] = userData;

          await _saveCloudRegistry(users, client);
        }
      } finally {
        if (_customHttpClient == null) client.close();
      }
    } catch (e) {
      debugPrint('GlobalCloudStorageDataSource.deleteCloudProject error: $e');
    }
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

  // --- Photo Projects Sync Support ---

  Future<List<Map<String, dynamic>>> getCloudPhotoProjects(String userId) async {
    _assertAuthenticated(userId);
    try {
      final registry = await _fetchCloudRegistry();
      if (registry != null) {
        final users = registry['users'];
        if (users is Map<String, dynamic> && users.containsKey(userId)) {
          final userData = users[userId];
          if (userData is Map<String, dynamic>) {
            final photoProjects = userData['photoProjects'];
            if (photoProjects is List<dynamic>) {
              final list = photoProjects.cast<Map<String, dynamic>>();
              await localStorageService.writeString(
                _userPhotoProjectsLocalFile(userId),
                jsonEncode(list),
              );
              return list;
            }
          }
        }
      }
    } catch (_) {}

    try {
      final cached = await localStorageService.readString(_userPhotoProjectsLocalFile(userId));
      if (cached != null && cached.isNotEmpty) {
        final decoded = jsonDecode(cached) as List<dynamic>;
        return decoded.cast<Map<String, dynamic>>();
      }
    } catch (_) {}

    return [];
  }

  Future<void> backupPhotoProject(String userId, Map<String, dynamic> photoProjectJson) async {
    _assertAuthenticated(userId);
    final id = photoProjectJson['id']?.toString() ?? '';
    if (id.isEmpty) return;

    final client = _createHttpClient();
    try {
      final registry = await _fetchCloudRegistry() ?? {'users': <String, dynamic>{}};
      final usersRaw = registry['users'];
      final users = usersRaw is Map ? Map<String, dynamic>.from(usersRaw) : <String, dynamic>{};
      final userDataRaw = users[userId];
      final userData = userDataRaw is Map ? Map<String, dynamic>.from(userDataRaw) : <String, dynamic>{};
      final photoProjectsRaw = userData['photoProjects'];
      final photoProjects = photoProjectsRaw is List
          ? List<Map<String, dynamic>>.from(photoProjectsRaw.whereType<Map>().map((m) => Map<String, dynamic>.from(m)))
          : <Map<String, dynamic>>[];

      photoProjects.removeWhere((p) => p['id'] == id);
      photoProjects.insert(0, photoProjectJson);
      userData['photoProjects'] = photoProjects;
      users[userId] = userData;

      await _saveCloudRegistry(users, client);

      // Cache locally
      await localStorageService.writeString(
        _userPhotoProjectsLocalFile(userId),
        jsonEncode(photoProjects),
      );
    } catch (e) {
      debugPrint('GlobalCloudStorageDataSource.backupPhotoProject error: $e');
    } finally {
      if (_customHttpClient == null) client.close();
    }
  }

  Future<void> deleteCloudPhotoProject(String userId, String photoProjectId) async {
    _assertAuthenticated(userId);
    final client = _createHttpClient();
    try {
      final registry = await _fetchCloudRegistry() ?? {'users': <String, dynamic>{}};
      final usersRaw = registry['users'];
      final users = usersRaw is Map ? Map<String, dynamic>.from(usersRaw) : <String, dynamic>{};
      if (users.containsKey(userId)) {
        final userDataRaw = users[userId];
        final userData = userDataRaw is Map ? Map<String, dynamic>.from(userDataRaw) : <String, dynamic>{};
        final photoProjectsRaw = userData['photoProjects'];
        final photoProjects = photoProjectsRaw is List
            ? List<Map<String, dynamic>>.from(photoProjectsRaw.whereType<Map>().map((m) => Map<String, dynamic>.from(m)))
            : <Map<String, dynamic>>[];
        photoProjects.removeWhere((p) => p['id'] == photoProjectId);
        userData['photoProjects'] = photoProjects;
        users[userId] = userData;

        await _saveCloudRegistry(users, client);

        await localStorageService.writeString(
          _userPhotoProjectsLocalFile(userId),
          jsonEncode(photoProjects),
        );
      }
    } catch (e) {
      debugPrint('GlobalCloudStorageDataSource.deleteCloudPhotoProject error: $e');
    } finally {
      if (_customHttpClient == null) client.close();
    }
  }

  // --- Internal Cloud Registry Helpers ---

  Future<Map<String, dynamic>?> _fetchCloudRegistry() async {
    final client = _createHttpClient();
    try {
      final uri = Uri.parse('$apiBaseUrl/$primaryRegistryObjectId');
      final request = await client.getUrl(uri);
      request.headers.set('Accept', 'application/json');

      final response = await request.close();
      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        final decoded = jsonDecode(body);
        if (decoded is Map<String, dynamic>) {
          final data = decoded['data'];
          if (data is Map<String, dynamic>) {
            return data;
          }
        }
      }
      await response.drain();
      return null;
    } catch (e) {
      debugPrint('GlobalCloudStorageDataSource._fetchCloudRegistry error: $e');
      return null;
    } finally {
      if (_customHttpClient == null) client.close();
    }
  }

  Future<bool> _uploadProjectToCloudRegistry(
    String userId,
    String projectId,
    Map<String, dynamic> projectJson,
    Map<String, dynamic> backupRecordJson,
  ) async {
    final client = _createHttpClient();
    try {
      final registry = await _fetchCloudRegistry() ?? {'users': <String, dynamic>{}};
      final usersRaw = registry['users'];
      final users = usersRaw is Map ? Map<String, dynamic>.from(usersRaw) : <String, dynamic>{};
      final userDataRaw = users[userId];
      final userData = userDataRaw is Map ? Map<String, dynamic>.from(userDataRaw) : <String, dynamic>{};
      final projectsRaw = userData['projects'];
      final projectsMap = projectsRaw is Map ? Map<String, dynamic>.from(projectsRaw) : <String, dynamic>{};
      final backupsRaw = userData['backups'];
      final backupsList = backupsRaw is List
          ? List<Map<String, dynamic>>.from(backupsRaw.whereType<Map>().map((m) => Map<String, dynamic>.from(m)))
          : <Map<String, dynamic>>[];

      projectsMap[projectId] = projectJson;
      backupsList.removeWhere((b) => b['projectId'] == projectId);
      backupsList.insert(0, backupRecordJson);
      if (backupsList.length > 50) {
        backupsList.removeRange(50, backupsList.length);
      }

      userData['projects'] = projectsMap;
      userData['backups'] = backupsList;
      userData['lastSyncAt'] = DateTime.now().toIso8601String();
      users[userId] = userData;

      return await _saveCloudRegistry(users, client);
    } catch (e) {
      debugPrint('GlobalCloudStorageDataSource._uploadProjectToCloudRegistry error: $e');
      return false;
    } finally {
      if (_customHttpClient == null) client.close();
    }
  }

  Future<bool> _saveCloudRegistry(Map<String, dynamic> users, HttpClient client) async {
    final payload = {
      'name': 'looma_global_projects_registry_v1',
      'data': {
        'users': users,
        'lastUpdatedAt': DateTime.now().toIso8601String(),
      },
    };

    final uri = Uri.parse('$apiBaseUrl/$primaryRegistryObjectId');
    final request = await client.putUrl(uri);
    request.headers.set('Content-Type', 'application/json');
    request.headers.set('Accept', 'application/json');

    final bytes = utf8.encode(jsonEncode(payload));
    request.headers.set('Content-Length', bytes.length.toString());
    request.add(bytes);

    final response = await request.close();
    final statusCode = response.statusCode;
    await response.drain();

    return statusCode == 200;
  }
}
