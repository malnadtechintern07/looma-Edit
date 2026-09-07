import 'package:looma/features/auth/domain/repositories/auth_repository.dart';
import 'package:looma/features/projects/data/datasources/project_local_datasource.dart';
import 'package:looma/features/projects/domain/entities/project_entity.dart';
import 'package:looma/features/projects/domain/entities/sync_status_type.dart';
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
      throw Exception('Please sign in to back up projects to Looma Cloud');
    }

    final localProject = await projectLocalDataSource.getProjectById(projectId);
    if (localProject == null) {
      throw Exception('Local project not found for backup: $projectId');
    }

    try {
      // Set syncing status
      await projectLocalDataSource.saveProject(
        localProject.copyWith(syncStatus: SyncStatusType.syncing),
      );

      // Perform cloud backup
      await cloudDataSource.backupProject(user.id, localProject);

      // Update local project status to synced (preserve user's edit timestamp)
      await projectLocalDataSource.saveProject(
        localProject.copyWith(
          syncStatus: SyncStatusType.synced,
        ),
      );
    } catch (e) {
      // Mark as error, but NEVER delete the local project
      await projectLocalDataSource.saveProject(
        localProject.copyWith(syncStatus: SyncStatusType.error),
      );
      rethrow;
    }
  }

  @override
  Future<void> syncAllProjects() async {
    final user = await authRepository.getCurrentUser();
    if (user == null) {
      throw Exception('Please sign in to sync with Looma Cloud');
    }

    // 1. Get all local projects
    final localProjects = await projectLocalDataSource.getProjects();

    // 2. Get all cloud projects for this user
    final cloudProjects = await cloudDataSource.getCloudProjects(user.id);
    final cloudProjectMap = {for (final p in cloudProjects) p.id: p};

    // 3. Upload local projects to cloud if newer or unsynced
    for (final local in localProjects) {
      final cloud = cloudProjectMap[local.id];
      if (cloud == null || local.updatedAt.isAfter(cloud.updatedAt)) {
        try {
          await cloudDataSource.backupProject(user.id, local);
          await projectLocalDataSource.saveProject(
            local.copyWith(syncStatus: SyncStatusType.synced),
          );
        } catch (_) {
          await projectLocalDataSource.saveProject(
            local.copyWith(syncStatus: SyncStatusType.error),
          );
        }
      } else {
        // Keep synced status
        if (local.syncStatus != SyncStatusType.synced) {
          await projectLocalDataSource.saveProject(
            local.copyWith(syncStatus: SyncStatusType.synced),
          );
        }
      }
    }

    // 4. Download cloud projects that don't exist locally (restores user's cloud projects upon login)
    final localProjectIds = localProjects.map((p) => p.id).toSet();
    for (final cloud in cloudProjects) {
      if (!localProjectIds.contains(cloud.id)) {
        await projectLocalDataSource.saveProject(
          cloud.copyWith(syncStatus: SyncStatusType.synced),
        );
      }
    }
  }

  @override
  Future<ProjectEntity?> restoreProject(String projectId) async {
    final user = await authRepository.getCurrentUser();
    if (user == null) {
      throw Exception('Please sign in to restore cloud projects');
    }

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
