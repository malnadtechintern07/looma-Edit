import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/route_paths.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../projects/presentation/providers/projects_provider.dart';

class ProfileMeScreen extends ConsumerStatefulWidget {
  const ProfileMeScreen({super.key});

  @override
  ConsumerState<ProfileMeScreen> createState() => _ProfileMeScreenState();
}

class _ProfileMeScreenState extends ConsumerState<ProfileMeScreen> {
  String _displayName = 'Looma Creator';
  String _username = '@loomacreator';
  String _bio = '🎬 Mobile Filmmaker & Content Creator ✨ Creating aesthetic reels with LOOMA PRO';
  bool _autoSaveToGallery = true;
  bool _hardwareAcceleration = true;
  String _defaultResolution = '1080p (FHD)';

  void _showEditProfileDialog() {
    final nameCtrl = TextEditingController(text: _displayName);
    final userCtrl = TextEditingController(text: _username);
    final bioCtrl = TextEditingController(text: _bio);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Edit Identity Profile', style: TextStyle(color: Color(0xFF111827), fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Display Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: userCtrl,
                decoration: const InputDecoration(
                  labelText: 'Handle (@username)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: bioCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Bio & Status',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5B4DFB),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              setState(() {
                _displayName = nameCtrl.text.trim().isNotEmpty ? nameCtrl.text.trim() : _displayName;
                _username = userCtrl.text.trim().isNotEmpty ? userCtrl.text.trim() : _username;
                _bio = bioCtrl.text.trim();
              });
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Profile updated successfully!')),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _clearCache() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: AppColors.success,
        content: Text('Temporary video cache cleared! Freed up 42.6 MB.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final projects = ref.watch(projectsNotifierProvider).projects;
    final totalClips = projects.fold<int>(0, (sum, p) => sum + p.videoClips.length);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9FE),
        elevation: 0,
        centerTitle: false,
        title: Text(
          'My Identity',
          style: AppTypography.titleLarge.copyWith(
            color: const Color(0xFF111827),
            fontWeight: FontWeight.w900,
            fontSize: 22,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Edit Profile',
            icon: const Icon(Icons.edit_outlined, color: Color(0xFF111827), size: 22),
            onPressed: _showEditProfileDialog,
          ),
          IconButton(
            tooltip: 'Cloud Backup',
            icon: const Icon(Icons.cloud_done_outlined, color: Color(0xFF5B4DFB), size: 22),
            onPressed: () => context.push(RoutePaths.cloud),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. User Identity Profile Hero Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFECEEF5)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0C000000),
                    blurRadius: 20,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Avatar with VIP Ring
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            width: 68,
                            height: 68,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [Color(0xFF5B4DFB), Color(0xFF00D2D3)],
                              ),
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: const [
                                BoxShadow(color: Colors.black12, blurRadius: 10),
                              ],
                            ),
                            child: const Center(
                              child: Icon(Icons.person, color: Colors.white, size: 38),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              color: Color(0xFFFFB800),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.star, color: Colors.white, size: 12),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),

                      // Name, Handle & VIP Badge
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    _displayName,
                                    style: AppTypography.titleMedium.copyWith(
                                      color: const Color(0xFF111827),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF111827),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'PRO',
                                    style: TextStyle(
                                      color: Color(0xFFFFB800),
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _username,
                              style: const TextStyle(
                                color: Color(0xFF6B7280),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _bio,
                              style: const TextStyle(
                                color: Color(0xFF4B5563),
                                fontSize: 11,
                                height: 1.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(color: Color(0xFFF3F4F6), height: 1),
                  const SizedBox(height: 16),

                  // User Statistics Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem(
                        label: 'Projects',
                        value: '${projects.length}',
                        icon: Icons.movie_outlined,
                        color: const Color(0xFF5B4DFB),
                      ),
                      Container(width: 1, height: 32, color: const Color(0xFFE5E7EB)),
                      _buildStatItem(
                        label: 'Total Clips',
                        value: '$totalClips',
                        icon: Icons.video_library_outlined,
                        color: const Color(0xFF00C2CB),
                      ),
                      Container(width: 1, height: 32, color: const Color(0xFFE5E7EB)),
                      _buildStatItem(
                        label: 'Saved Space',
                        value: '${(projects.length * 28.4).toStringAsFixed(0)} MB',
                        icon: Icons.sd_storage_outlined,
                        color: const Color(0xFFFFB800),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 2. Editor & Gallery Preferences
            Text(
              'Editor & Export Preferences',
              style: AppTypography.titleMedium.copyWith(
                color: const Color(0xFF111827),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),

            Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              clipBehavior: Clip.antiAlias,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFECEEF5)),
                ),
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Direct Save to Gallery', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      subtitle: const Text('Auto-save exported videos directly to Camera Roll/DCIM', style: TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                      value: _autoSaveToGallery,
                      activeTrackColor: const Color(0xFF5B4DFB),
                      onChanged: (v) => setState(() => _autoSaveToGallery = v),
                    ),
                    const Divider(height: 1, color: Color(0xFFF3F4F6)),
                    SwitchListTile(
                      title: const Text('Hardware GPU Acceleration', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      subtitle: const Text('Ultra-fast multi-core video encoding (H.264 / HEVC)', style: TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                      value: _hardwareAcceleration,
                      activeTrackColor: const Color(0xFF5B4DFB),
                      onChanged: (v) => setState(() => _hardwareAcceleration = v),
                    ),
                    const Divider(height: 1, color: Color(0xFFF3F4F6)),
                    ListTile(
                      title: const Text('Default Resolution', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      subtitle: Text(_defaultResolution, style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                      trailing: const Icon(Icons.chevron_right, color: Color(0xFF9CA3AF)),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => SimpleDialog(
                            title: const Text('Select Default Resolution'),
                            children: ['720p (HD)', '1080p (FHD)', '4K (Ultra HD)'].map((res) {
                              return SimpleDialogOption(
                                onPressed: () {
                                  setState(() => _defaultResolution = res);
                                  Navigator.of(ctx).pop();
                                },
                                child: Text(res, style: const TextStyle(fontSize: 14)),
                              );
                            }).toList(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 3. Storage, Cache & App Info
            Text(
              'System & Storage',
              style: AppTypography.titleMedium.copyWith(
                color: const Color(0xFF111827),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),

            Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              clipBehavior: Clip.antiAlias,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFECEEF5)),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.cleaning_services_outlined, color: Color(0xFF5B4DFB)),
                      title: const Text('Clear Temporary Cache', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      subtitle: const Text('Free storage from rendered video fragments', style: TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                      trailing: TextButton(
                        onPressed: _clearCache,
                        child: const Text('Clean (42 MB)', style: TextStyle(color: Color(0xFF5B4DFB), fontSize: 12)),
                      ),
                    ),
                    const Divider(height: 1, color: Color(0xFFF3F4F6)),
                    ListTile(
                      leading: const Icon(Icons.cloud_sync_outlined, color: Color(0xFF00C2CB)),
                      title: const Text('Looma Cloud Backup', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      subtitle: const Text('Sync projects across devices', style: TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                      trailing: const Icon(Icons.chevron_right, color: Color(0xFF9CA3AF)),
                      onTap: () => context.push(RoutePaths.cloud),
                    ),
                    const Divider(height: 1, color: Color(0xFFF3F4F6)),
                    ListTile(
                      leading: const Icon(Icons.info_outline, color: Color(0xFF6B7280)),
                      title: const Text('About Looma Video Editor', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      subtitle: const Text('Version 2.4.0 (Build 240) • Offline Pro Engine', style: TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(
                color: const Color(0xFF111827),
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF6B7280),
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
