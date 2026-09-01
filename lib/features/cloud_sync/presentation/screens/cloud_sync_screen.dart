import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/looma_button.dart';
import '../../../../core/widgets/looma_card.dart';
import '../../../../core/widgets/status_badge.dart';
import '../providers/cloud_sync_provider.dart';

class CloudSyncScreen extends ConsumerWidget {
  const CloudSyncScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileFutureProvider);
    final backupsAsync = ref.watch(cloudBackupsFutureProvider);
    final isSyncing = ref.watch(syncNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.cloud_sync, color: AppColors.secondary, size: 22),
            const SizedBox(width: 8),
            Text('Cloud Backup & Profile', style: AppTypography.titleLarge),
          ],
        ),
      ),
      body: profileAsync.when(
        data: (profile) => SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Profile Card
              LoomaCard(
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: AppColors.primary,
                      child: Text(
                        profile.displayName.substring(0, 2).toUpperCase(),
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
                              Text(profile.displayName, style: AppTypography.titleMedium),
                              const SizedBox(width: 8),
                              const StatusBadge(
                                text: 'PRO',
                                color: AppColors.accent,
                                textColor: Colors.white,
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(profile.email, style: AppTypography.bodySmall),
                          const SizedBox(height: 4),
                          Text(
                            'Member since ${DateFormat('MMM yyyy').format(profile.memberSince)}',
                            style: AppTypography.labelSmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Cloud Storage Quota Card
              LoomaCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Cloud Storage', style: AppTypography.titleSmall),
                        Text(
                          '${profile.formattedUsedStorage} / ${profile.formattedTotalStorage}',
                          style: AppTypography.labelLarge.copyWith(color: AppColors.secondaryLight),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: profile.usagePercentage,
                        minHeight: 10,
                        backgroundColor: AppColors.surfaceLight,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.secondary),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${(profile.usagePercentage * 100).toInt()}% used',
                          style: AppTypography.labelSmall,
                        ),
                        Text(
                          'Offline Cache: Enabled',
                          style: AppTypography.labelSmall.copyWith(color: AppColors.success),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    LoomaButton(
                      label: isSyncing ? 'Syncing...' : 'Sync All Projects Now',
                      icon: Icons.sync,
                      isLoading: isSyncing,
                      isFullWidth: true,
                      onPressed: () {
                        ref.read(syncNotifierProvider.notifier).triggerSync();
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Backups History
              Text('Cloud Project Backups', style: AppTypography.titleMedium),
              const SizedBox(height: 12),

              backupsAsync.when(
                data: (backups) => ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: backups.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final b = backups[index];
                    return LoomaCard(
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
                                Text(b.projectTitle, style: AppTypography.titleSmall),
                                const SizedBox(height: 2),
                                Text(
                                  '${b.formattedSize} • Backed up ${DateFormat('MMM d, h:mm a').format(b.backedUpAt)}',
                                  style: AppTypography.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.restore, size: 20, color: AppColors.textSecondary),
                            tooltip: 'Restore from Cloud',
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Restored snapshot for "${b.projectTitle}"')),
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
                loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                error: (e, _) => Text('Error loading backups: $e'),
              ),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
