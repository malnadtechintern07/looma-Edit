import 'dart:convert';
import 'package:procut/core/constants/app_constants.dart';
import 'package:procut/core/storage/local_storage_service.dart';
import 'package:procut/core/utils/id_generator.dart';
import 'package:procut/features/projects/data/models/project_model.dart';
import 'package:procut/features/projects/domain/entities/project_entity.dart';
import 'package:procut/features/projects/domain/entities/sync_status_type.dart';

abstract class ProjectLocalDataSource {
  String? get activeUserId;
  void setActiveUserId(String? userId);
  Future<List<ProjectEntity>> getProjects();
  Future<ProjectEntity?> getProjectById(String id);
  Future<void> saveProject(ProjectEntity project);
  Future<void> updateProject(ProjectEntity project);
  Future<ProjectEntity> duplicateProject(String id);
  Future<void> deleteProject(String id);
  Future<void> claimGuestProjects(String userId);
}

class ProjectLocalDataSourceImpl implements ProjectLocalDataSource {
  final LocalStorageService storageService;
  @override
  String? activeUserId;

  @override
  void setActiveUserId(String? userId) {
    activeUserId = userId;
  }

  ProjectLocalDataSourceImpl({
    required this.storageService,
    this.activeUserId,
  });

  String get _userDir => (activeUserId != null && activeUserId!.trim().isNotEmpty)
      ? '${AppConstants.projectsDirectory}/users/${activeUserId!.trim()}'
      : AppConstants.projectsDirectory;

  String _getProjectPath(String id) => '$_userDir/project_$id.json';

  String get _catalogFile => (activeUserId != null && activeUserId!.trim().isNotEmpty)
      ? '$_userDir/projects_catalog.json'
      : AppConstants.projectsCatalogFile;

  String get _seededFlag => (activeUserId != null && activeUserId!.trim().isNotEmpty)
      ? 'app_seeded_${activeUserId!.trim()}.flag'
      : 'app_seeded.flag';

  @override
  Future<List<ProjectEntity>> getProjects() async {
    final catalogRaw = await storageService.readString(_catalogFile);
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

    // Auto-discover project files stored in the active user's projects directory
    final diskFiles = await storageService.listProjectFiles(directoryPrefix: _userDir);
    for (final filePath in diskFiles) {
      if ((activeUserId == null || activeUserId!.trim().isEmpty) && filePath.contains('/users/')) {
        continue;
      }
      final fileName = filePath.split('/').last;
      if (fileName.startsWith('project_') && fileName.endsWith('.json')) {
        final id = fileName.substring('project_'.length, fileName.length - '.json'.length);
        if (id.isNotEmpty) {
          projectIds.add(id);
        }
      }
    }

    // When in user workspace, check for existing projects claimed or legacy root projects
    if (activeUserId != null && activeUserId!.trim().isNotEmpty && projectIds.isEmpty) {
      // Check legacy root directory for projects assigned specifically to this user
      final rootFiles = await storageService.listProjectFiles(directoryPrefix: AppConstants.projectsDirectory);
      for (final filePath in rootFiles) {
        if (filePath.contains('/users/')) continue;
        final fileName = filePath.split('/').last;
        if (fileName.startsWith('project_') && fileName.endsWith('.json')) {
          final rawMap = await storageService.readJson(filePath);
          if (rawMap != null) {
            try {
              final p = ProjectModel.fromJson(rawMap);
              if (p.userId == activeUserId) {
                // Move to user directory
                await saveProject(p);
                projectIds.add(p.id);
                await storageService.deleteFile(filePath);
              }
            } catch (_) {}
          }
        }
      }
    }

    // Do not seed dummy sample projects; before login and new users start completely clean.
    projectIds.removeWhere((id) => id == 'sample-tokyo-vlog' || id == 'sample-cinematic-trailer');
    final seededFlag = await storageService.readString(_seededFlag);
    if (seededFlag == null) {
      await storageService.writeString(_seededFlag, 'true');
    }

    final loadedProjects = await Future.wait(
      projectIds.map((id) => getProjectById(id)),
    );
    final List<ProjectEntity> results = loadedProjects.whereType<ProjectEntity>().toList();

    results.sort((a, b) {
      final cmp = b.updatedAt.compareTo(a.updatedAt);
      if (cmp != 0) return cmp;
      final createCmp = b.createdAt.compareTo(a.createdAt);
      if (createCmp != 0) return createCmp;
      return b.id.compareTo(a.id);
    });

    // Always keep catalog strictly in sync with sorted valid project files
    final sortedIds = results.map((p) => p.id).toList();
    await storageService.writeString(_catalogFile, jsonEncode(sortedIds));

    return results;
  }

  @override
  Future<ProjectEntity?> getProjectById(String id) async {
    var jsonMap = await storageService.readJson(_getProjectPath(id));
    if (jsonMap == null && activeUserId != null && activeUserId!.trim().isNotEmpty) {
      // Fallback check in root directory
      jsonMap = await storageService.readJson('${AppConstants.projectsDirectory}/project_$id.json');
    }
    if (jsonMap == null) return null;
    return ProjectModel.fromJson(jsonMap);
  }

  @override
  Future<void> saveProject(ProjectEntity project) async {
    final projectToSave = (activeUserId != null && activeUserId!.trim().isNotEmpty && project.userId == null)
        ? project.copyWith(userId: activeUserId)
        : project;

    final path = _getProjectPath(projectToSave.id);
    await storageService.writeJson(path, ProjectModel.toJson(projectToSave));

    // Update catalog
    final catalogRaw = await storageService.readString(_catalogFile);
    List<String> projectIds = [];
    if (catalogRaw != null && catalogRaw.isNotEmpty) {
      try {
        final decoded = jsonDecode(catalogRaw) as List<dynamic>;
        projectIds = decoded.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
      } catch (_) {}
    }
    projectIds.remove(projectToSave.id);
    projectIds.insert(0, projectToSave.id);
    await storageService.writeString(_catalogFile, jsonEncode(projectIds));
    await storageService.writeString(_seededFlag, 'true');
  }

  @override
  Future<void> updateProject(ProjectEntity project) async {
    await saveProject(project);
  }

  @override
  Future<ProjectEntity> duplicateProject(String id) async {
    final original = await getProjectById(id);
    if (original == null) {
      throw Exception('Cannot duplicate non-existent project $id');
    }

    final newId = IdGenerator.generate();
    final duplicated = original.copyWith(
      id: newId,
      title: '${original.title} (Copy)',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      syncStatus: SyncStatusType.localOnly,
      userId: activeUserId ?? original.userId,
    );

    await saveProject(duplicated);
    return duplicated;
  }

  @override
  Future<void> deleteProject(String id) async {
    await storageService.deleteFile(_getProjectPath(id));
    if (activeUserId != null && activeUserId!.trim().isNotEmpty) {
      await storageService.deleteFile('${AppConstants.projectsDirectory}/project_$id.json');
    }

    final catalogRaw = await storageService.readString(_catalogFile);
    if (catalogRaw != null && catalogRaw.isNotEmpty) {
      try {
        final decoded = jsonDecode(catalogRaw) as List<dynamic>;
        final projectIds = decoded.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
        projectIds.remove(id);
        await storageService.writeString(_catalogFile, jsonEncode(projectIds));
      } catch (_) {}
    }
  }

  @override
  Future<void> claimGuestProjects(String userId) async {
    final cleanUid = userId.trim();
    if (cleanUid.isEmpty) return;
    activeUserId = cleanUid;

    final rootFiles = await storageService.listProjectFiles(directoryPrefix: AppConstants.projectsDirectory);
    final List<String> claimedIds = [];

    for (final filePath in rootFiles) {
      if (filePath.contains('/users/')) continue;
      final fileName = filePath.split('/').last;
      if (fileName.startsWith('project_') && fileName.endsWith('.json')) {
        final rawMap = await storageService.readJson(filePath);
        if (rawMap != null) {
          try {
            final p = ProjectModel.fromJson(rawMap);
            if (p.id == 'sample-tokyo-vlog' || p.id == 'sample-cinematic-trailer') {
              await storageService.deleteFile(filePath);
              continue;
            }
            if (p.userId == null || p.userId == cleanUid) {
              final claimed = p.copyWith(userId: cleanUid);
              final userPath = '${AppConstants.projectsDirectory}/users/$cleanUid/project_${claimed.id}.json';
              await storageService.writeJson(userPath, ProjectModel.toJson(claimed));

              final userCatFile = '${AppConstants.projectsDirectory}/users/$cleanUid/projects_catalog.json';
              final userCatRaw = await storageService.readString(userCatFile);
              final List<String> userCat = [];
              if (userCatRaw != null && userCatRaw.isNotEmpty) {
                try {
                  userCat.addAll((jsonDecode(userCatRaw) as List<dynamic>).map((e) => e.toString().trim()));
                } catch (_) {}
              }
              if (!userCat.contains(claimed.id)) {
                userCat.insert(0, claimed.id);
                await storageService.writeString(userCatFile, jsonEncode(userCat));
              }

              // Remove from root guest directory so other users do not claim it
              await storageService.deleteFile(filePath);
              claimedIds.add(claimed.id);
            }
          } catch (_) {}
        }
      }
    }

    if (claimedIds.isNotEmpty) {
      final rootCatRaw = await storageService.readString(AppConstants.projectsCatalogFile);
      if (rootCatRaw != null && rootCatRaw.isNotEmpty) {
        try {
          final decoded = jsonDecode(rootCatRaw) as List<dynamic>;
          final updatedRoot = decoded.map((e) => e.toString().trim()).where((id) => !claimedIds.contains(id)).toList();
          await storageService.writeString(AppConstants.projectsCatalogFile, jsonEncode(updatedRoot));
        } catch (_) {}
      }
    }
  }
}

