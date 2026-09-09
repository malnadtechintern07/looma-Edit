import 'package:procut/features/auth/domain/repositories/auth_repository.dart';
import 'package:procut/features/projects/data/datasources/project_local_datasource.dart';
import 'package:procut/features/projects/domain/entities/project_entity.dart';
import 'package:procut/features/projects/domain/entities/sync_status_type.dart';
import '../../domain/entities/cloud_backup_record.dart';
import '../../domain/entities/user_account_entity.dart';
import '../../domain/repositories/cloud_sync_repository.dart';
import '../datasources/cloud_storage_datasource.dart';

class CloudSyncRepositoryImpl implements CloudSyncRepository {
  final CloudStorageDataSource cloudDataSource;
  final ProjectLocalDataSource projectLocalDataSource;
  final AuthRepository authRepository;

  CloudSyncRepositoryImpl({
    required this.cloudDataSource,
    required this.projectLocalDataSource,
    required this.authRepository,
  });

  @override
  Future<UserAccountEntity> getUserProfile() async {
    final user = await authRepository.getCurrentUser();
    if (user != null) {
      final usage = await cloudDataSource.calculateUserStorageUsage(user.id);
      return UserAccountEntity(
        id: user.id,
        displayName: user.displayName,
        email: user.email,
        avatarUrl: user.avatarUrl ?? '',
        memberSince: user.createdAt,
        usedCloudStorageBytes: usage,
        totalCloudStorageBytes: 15 * 1024 * 1024 * 1024,
        isProMember: user.isPro,
      );
    }

    return UserAccountEntity(
      id: 'guest',
      displayName: 'Guest Creator',
      email: 'Sign in to enable Cloud Backup',
      avatarUrl: '',
      memberSince: DateTime.now(),
      usedCloudStorageBytes: 0,
      totalCloudStorageBytes: 15 * 1024 * 1024 * 1024,
      isProMember: false,
    );
  }

  @override
  Future<List<CloudBackupRecord>> getCloudBackups() async {
    final user = await authRepository.getCurrentUser();
    if (user == null) return [];
    return await cloudDataSource.getBackupRecords(user.id);
  }

  @override
  Future<List<ProjectEntity>> getCloudProjects() async {
    final user = await authRepository.getCurrentUser();
    if (user == null) return [];
    return await cloudDataSource.getCloudProjects(user.id);
  }

  @override
  Future<void> backupProject(String projectId) async {
    final user = await authRepository.getCurrentUser();
    if (user == null) {
      throw Exception('Please sign in to back up projects to ProCut Cloud');
    }
    projectLocalDataSource.setActiveUserId(user.id);

    final localProject = await projectLocalDataSource.getProjectById(projectId);
    if (localProject == null) {
      throw Exception('Local project not found for backup: $projectId');
    }

    final projectWithUser = localProject.copyWith(
      userId: user.id,
      userEmail: user.email,
      syncStatus: SyncStatusType.syncing,
    );

    try {
      // Set syncing status
      await projectLocalDataSource.saveProject(projectWithUser);

      // Perform cloud backup
      await cloudDataSource.backupProject(user.id, projectWithUser);

      // Update local project status to synced (preserve user's edit timestamp)
      await projectLocalDataSource.saveProject(
        projectWithUser.copyWith(
          syncStatus: SyncStatusType.synced,
        ),
      );
    } catch (e) {
      // Mark as error, but NEVER delete the local project
      await projectLocalDataSource.saveProject(
        projectWithUser.copyWith(syncStatus: SyncStatusType.error),
      );
      rethrow;
    }
  }

  @override
  Future<void> syncAllProjects() async {
    final user = await authRepository.getCurrentUser();
    if (user == null) {
      throw Exception('Please sign in to sync with ProCut Cloud');
    }
    projectLocalDataSource.setActiveUserId(user.id);

    // 0. Claim any unassigned guest projects on this device for the user
    await projectLocalDataSource.claimGuestProjects(user.id);

    // 1. Fetch cloud projects for this user FIRST
    final cloudProjects = await cloudDataSource.getCloudProjects(user.id);
    final cloudProjectMap = {for (final p in cloudProjects) p.id: p};

    // 2. Download any cloud projects that don't exist locally into local storage
    for (final cloud in cloudProjects) {
      final existingLocal = await projectLocalDataSource.getProjectById(cloud.id);
      if (existingLocal == null) {
        await projectLocalDataSource.saveProject(
          cloud.copyWith(
            syncStatus: SyncStatusType.synced,
            userId: user.id,
            userEmail: user.email,
          ),
        );
      }
    }

    // 3. Get all local projects for this user
    final localProjects = await projectLocalDataSource.getProjects();

    // 4. Reconcile local and cloud projects
    for (final local in localProjects) {
      // Skip projects belonging to another user
      if (local.userId != null && local.userId != user.id) continue;

      final cloud = cloudProjectMap[local.id];
      if (cloud != null && cloud.updatedAt.isAfter(local.updatedAt)) {
        // Cloud is newer: update local copy with cloud data
        await projectLocalDataSource.saveProject(
          cloud.copyWith(
            syncStatus: SyncStatusType.synced,
            userId: user.id,
            userEmail: user.email,
          ),
        );
      } else if (cloud == null || local.updatedAt.isAfter(cloud.updatedAt)) {
        // Local is newer or not yet in cloud: upload to cloud
        try {
          final localWithUser = local.copyWith(userId: user.id, userEmail: user.email);
          await cloudDataSource.backupProject(user.id, localWithUser);
          await projectLocalDataSource.saveProject(
            localWithUser.copyWith(syncStatus: SyncStatusType.synced),
          );
        } catch (_) {
          await projectLocalDataSource.saveProject(
            local.copyWith(syncStatus: SyncStatusType.error),
          );
        }
      } else {
        // Both are in sync
        if (local.syncStatus != SyncStatusType.synced || local.userId != user.id) {
          await projectLocalDataSource.saveProject(
            local.copyWith(syncStatus: SyncStatusType.synced, userId: user.id, userEmail: user.email),
          );
        }
      }
    }
  }

  @override
  Future<ProjectEntity?> restoreProject(String projectId) async {
    final user = await authRepository.getCurrentUser();
    if (user == null) {
      throw Exception('Please sign in to restore cloud projects');
    }
    projectLocalDataSource.setActiveUserId(user.id);

    final cloudProject = await cloudDataSource.getCloudProject(user.id, projectId);
    if (cloudProject != null) {
      await projectLocalDataSource.saveProject(cloudProject);
      return cloudProject;
    }
    return null;
  }

  @override
  Future<void> deleteCloudProject(String projectId) async {
    final user = await authRepository.getCurrentUser();
    if (user == null) {
      throw Exception('Please sign in to manage cloud projects');
    }
    projectLocalDataSource.setActiveUserId(user.id);

    await cloudDataSource.deleteCloudProject(user.id, projectId);

    // Update local project status to localOnly if it exists locally
    final local = await projectLocalDataSource.getProjectById(projectId);
    if (local != null) {
      await projectLocalDataSource.saveProject(
        local.copyWith(syncStatus: SyncStatusType.localOnly),
      );
    }
  }
}
