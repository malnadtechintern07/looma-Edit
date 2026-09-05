import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../app/router/route_paths.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/looma_button.dart';
import '../../../../core/widgets/looma_card.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/cloud_backup_record.dart';
import '../providers/cloud_sync_provider.dart';

class CloudSyncScreen extends ConsumerWidget {
  const CloudSyncScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final isAuthenticated = authState.isAuthenticated;
    final profileAsync = ref.watch(userProfileFutureProvider);
    final backupsAsync = ref.watch(cloudBackupsFutureProvider);
    final syncState = ref.watch(syncNotifierProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0C0D12),
      appBar: AppBar(
        backgroundColor: const Color(0xFF14151E),
        elevation: 0,
        title: Row(
          children: [
            const Icon(Icons.cloud_sync, color: Color(0xFF5B4DFB), size: 22),
            const SizedBox(width: 8),
            Text(
              'Cloud Backup & Sync',
              style: AppTypography.titleLarge.copyWith(color: Colors.white),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Auth Status Banner (if not authenticated)
            if (!isAuthenticated) ...[
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF20174D), Color(0xFF14152A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFF5B4DFB).withValues(alpha: 0.5)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF5B4DFB).withValues(alpha: 0.2),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF5B4DFB),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.cloud_upload_outlined, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Enable Private Cloud Storage',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Sign in with your Looma account to automatically back up your timeline, clips, filters, stickers, and edits securely to the cloud.',
                      style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13, height: 1.4),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5B4DFB),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(Icons.login, size: 18),
                        label: const Text('Sign In or Register', style: TextStyle(fontWeight: FontWeight.bold)),
                        onPressed: () => context.push(RoutePaths.auth),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // 2. Sync Error Banner (if any)
            if (syncState.errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF35121B),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF8E1B32)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Color(0xFFFF4E64), size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        syncState.errorMessage!,
                        style: const TextStyle(color: Color(0xFFFFCCD3), fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // 3. User Account Profile Card
            profileAsync.when(
              data: (profile) => LoomaCard(
                backgroundColor: const Color(0xFF161822),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: const Color(0xFF5B4DFB),
                      child: Text(
                        profile.displayName.isNotEmpty
                            ? profile.displayName.substring(0, profile.displayName.length >= 2 ? 2 : 1).toUpperCase()
                            : 'LC',
                        style: AppTypography.titleLarge.copyWith(color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  profile.displayName,
                                  style: AppTypography.titleMedium.copyWith(color: Colors.white),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              StatusBadge(
                                text: profile.isProMember ? 'PRO' : 'FREE',
                                color: profile.isProMember ? const Color(0xFFFFB800) : const Color(0xFF6B7280),
                                textColor: profile.isProMember ? const Color(0xFF111827) : Colors.white,
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            profile.email,
                            style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isAuthenticated
                                ? 'Member since ${DateFormat('MMM yyyy').format(profile.memberSince)}'
                                : 'Local Guest Mode',
                            style: const TextStyle(color: Color(0xFF6B7280), fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    if (isAuthenticated)
                      IconButton(
                        icon: const Icon(Icons.logout, color: Color(0xFF9CA3AF), size: 20),
                        tooltip: 'Sign Out',
                        onPressed: () => _confirmSignOut(context, ref),
                      ),
                  ],
                ),
              ),
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
              error: (e, _) => Text('Error loading profile: $e', style: const TextStyle(color: Colors.white)),
            ),
            const SizedBox(height: 16),

            // 4. Cloud Storage Quota & Sync Trigger Card
            profileAsync.when(
              data: (profile) => LoomaCard(
                backgroundColor: const Color(0xFF161822),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Cloud Storage Quota',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        Text(
                          '${profile.formattedUsedStorage} / ${profile.formattedTotalStorage}',
                          style: const TextStyle(color: Color(0xFF00D2D3), fontWeight: FontWeight.w600, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: profile.usagePercentage > 0.01 ? profile.usagePercentage : 0.02,
                        minHeight: 8,
                        backgroundColor: const Color(0xFF262938),
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF5B4DFB)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${(profile.usagePercentage * 100).toStringAsFixed(1)}% used',
                          style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 11),
                        ),
                        Row(
                          children: const [
                            Icon(Icons.shield_outlined, size: 12, color: Color(0xFF10B981)),
                            SizedBox(width: 4),
                            Text(
                              'Private & Encrypted',
                              style: TextStyle(color: Color(0xFF10B981), fontSize: 11),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    LoomaButton(
                      label: syncState.isSyncing ? 'Synchronizing...' : 'Sync All Projects Now',
                      icon: Icons.sync,
                      isLoading: syncState.isSyncing,
                      isFullWidth: true,
                      onPressed: isAuthenticated
                          ? () async {
                              final ok = await ref.read(syncNotifierProvider.notifier).triggerSync();
                              if (ok && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    backgroundColor: AppColors.success,
                                    content: Text('All projects synchronized with Looma Cloud!'),
                                  ),
                                );
                              }
                            }
                          : () => context.push(RoutePaths.auth),
                    ),
                  ],
                ),
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 24),

            // 5. Cloud Project Backups List
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Cloud Project Backups',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                if (isAuthenticated)
                  TextButton(
                    onPressed: () => ref.read(syncNotifierProvider.notifier).triggerSync(),
                    child: const Text('Refresh', style: TextStyle(color: Color(0xFF5B4DFB), fontSize: 13)),
                  ),
              ],
            ),
            const SizedBox(height: 10),

            backupsAsync.when(
              data: (backups) {
                if (backups.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFF14151E),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF262838)),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.cloud_done_outlined, size: 42, color: Color(0xFF4B5563)),
                        const SizedBox(height: 12),
                        const Text(
                          'No Cloud Backups Yet',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Tap "Sync All Projects Now" or sync individual projects from My Projects.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: backups.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final b = backups[index];
                    return LoomaCard(
                      backgroundColor: const Color(0xFF161822),
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.cloud_done, color: AppColors.success, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  b.projectTitle,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${b.formattedSize} • Backed up ${DateFormat('MMM d, h:mm a').format(b.backedUpAt)}',
                                  style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.download, size: 20, color: Color(0xFF00D2D3)),
                            tooltip: 'Restore from Cloud',
                            onPressed: () async {
                              final ok = await ref
                                  .read(syncNotifierProvider.notifier)
                                  .restoreProject(b.projectId);
                              if (ok && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    backgroundColor: AppColors.success,
                                    content: Text('Restored snapshot for "${b.projectTitle}"'),
                                  ),
                                );
                              }
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFEF4444)),
                            tooltip: 'Delete Cloud Backup',
                            onPressed: () => _confirmDeleteCloudBackup(context, ref, b),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
              error: (e, _) => Text('Error loading backups: $e', style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmSignOut(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161822),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Sign Out?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text(
          'Your local projects will remain safe on this device. You can sign back in anytime to access your cloud backups.',
          style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF9CA3AF))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref.read(authNotifierProvider.notifier).logout();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Signed out successfully')),
                );
              }
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteCloudBackup(
    BuildContext context,
    WidgetRef ref,
    CloudBackupRecord backup,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161822),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Cloud Backup?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          'Are you sure you want to permanently delete the cloud backup for "${backup.projectTitle}"? Your local copy on this device will not be deleted.',
          style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF9CA3AF))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              final ok = await ref
                  .read(syncNotifierProvider.notifier)
                  .deleteCloudBackup(backup.projectId);
              if (ok && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: AppColors.success,
                    content: Text('Deleted cloud backup for "${backup.projectTitle}"'),
                  ),
                );
              }
            },
            child: const Text('Delete Cloud Backup'),
          ),
        ],
      ),
    );
  }
}
