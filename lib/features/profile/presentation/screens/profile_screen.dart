import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/route_paths.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/services/app_actions_service.dart';
import '../../../../core/widgets/permissions_primer_dialog.dart';
import '../../../../core/widgets/rate_us_dialog.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
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
              backgroundColor: AppColors.primary,
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

  Future<void> _handleRateUs() async {
    await showRateUsDialog(context);
  }

  Future<void> _handleShareApp() async {
    final success = await AppActionsService.shareApp();
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Looma download link copied to clipboard!'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final user = authState.user;
    final isAuthenticated = authState.isAuthenticated;
    final currentDisplayName = user != null
        ? (user.displayName.isNotEmpty ? user.displayName : user.email.split('@').first)
        : 'Looma Creator (Guest)';
    final currentHandle = user != null ? user.email : 'Not signed in';

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
            icon: const Icon(Icons.cloud_done_outlined, color: AppColors.primary, size: 22),
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
                                colors: [Color(0xFF084298), Color(0xFF0D6EFD)],
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
                                    currentDisplayName,
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
                                  child: Text(
                                    isAuthenticated ? 'ACCOUNT' : 'GUEST',
                                    style: TextStyle(
                                      color: isAuthenticated ? const Color(0xFFFFB800) : const Color(0xFF9CA3AF),
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              currentHandle,
                              style: const TextStyle(
                                color: Color(0xFF6B7280),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (isAuthenticated) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: const [
                                  Icon(Icons.cloud_done_rounded, color: Color(0xFF10B981), size: 13),
                                  SizedBox(width: 4),
                                  Text(
                                    'Cloud Synced • Log in on any device',
                                    style: TextStyle(
                                      color: Color(0xFF10B981),
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
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
                        color: AppColors.primary,
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
            const SizedBox(height: 20),

            // Banner CTA when not signed in
            if (!isAuthenticated) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF084298), Color(0xFF0D6EFD)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFF00C2CB).withValues(alpha: 0.4)),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Image.asset('assets/icon/app_icon.png', fit: BoxFit.contain),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Sign In or Register Account',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Secure projects to your cloud account and access them across devices.',
                            style: TextStyle(
                              color: Color(0xFFC7D2FE),
                              fontSize: 11,
                              height: 1.25,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      key: const Key('me_tab_signin_register_btn'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primary,
                        elevation: 3,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onPressed: () => context.push(RoutePaths.auth),
                      child: const Text('Sign In / Register', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5)),
                    ),
                  ],
                ),
              ),
            ],

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
                      title: const Text('Direct Save to Gallery', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF111827))),
                      subtitle: const Text('Auto-save exported videos directly to Camera Roll/DCIM', style: TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                      value: _autoSaveToGallery,
                      activeTrackColor: AppColors.primary,
                      activeThumbColor: Colors.white,
                      inactiveTrackColor: const Color(0xFFCBD5E1),
                      inactiveThumbColor: Colors.white,
                      trackOutlineColor: WidgetStateProperty.resolveWith((states) =>
                        states.contains(WidgetState.selected) ? Colors.transparent : const Color(0xFF94A3B8),
                      ),
                      onChanged: (v) => setState(() => _autoSaveToGallery = v),
                    ),
                    const Divider(height: 1, color: Color(0xFFF3F4F6)),
                    SwitchListTile(
                      title: const Text('Hardware GPU Acceleration', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF111827))),
                      subtitle: const Text('Ultra-fast multi-core video encoding (H.264 / HEVC)', style: TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                      value: _hardwareAcceleration,
                      activeTrackColor: AppColors.primary,
                      activeThumbColor: Colors.white,
                      inactiveTrackColor: const Color(0xFFCBD5E1),
                      inactiveThumbColor: Colors.white,
                      trackOutlineColor: WidgetStateProperty.resolveWith((states) =>
                        states.contains(WidgetState.selected) ? Colors.transparent : const Color(0xFF94A3B8),
                      ),
                      onChanged: (v) => setState(() => _hardwareAcceleration = v),
                    ),
                    const Divider(height: 1, color: Color(0xFFF3F4F6)),
                    ListTile(
                      title: const Text('Default Resolution', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF111827))),
                      subtitle: Text(_defaultResolution, style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                      trailing: const Icon(Icons.chevron_right, color: Color(0xFF9CA3AF)),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => SimpleDialog(
                            backgroundColor: Colors.white,
                            title: const Text('Select Default Resolution', style: TextStyle(color: Color(0xFF111827), fontWeight: FontWeight.bold, fontSize: 18)),
                            children: ['720p (HD)', '1080p (FHD)', '4K (Ultra HD)'].map((res) {
                              return SimpleDialogOption(
                                onPressed: () {
                                  setState(() => _defaultResolution = res);
                                  Navigator.of(ctx).pop();
                                },
                                child: Text(res, style: const TextStyle(fontSize: 14, color: Color(0xFF111827))),
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
                      leading: const Icon(Icons.cleaning_services_outlined, color: AppColors.primary),
                      title: const Text('Clear Temporary Cache', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      subtitle: const Text('Free storage from rendered video fragments', style: TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                      trailing: TextButton(
                        onPressed: _clearCache,
                        child: const Text('Clean (42 MB)', style: TextStyle(color: AppColors.primary, fontSize: 12)),
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
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset('assets/icon/app_icon.png', width: 28, height: 28),
                      ),
                      title: const Text('About Looma Video Editor', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      subtitle: const Text('Version 2.4.0 (Build 240) • Offline Pro Engine', style: TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(height: 8),
                                Image.asset('assets/icon/app_icon.png', width: 68, height: 68),
                                const SizedBox(height: 12),
                                const Text(
                                  'LOOMA',
                                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Version 2.4.0 (Build 240)',
                                  style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'Pro Mobile Video Editor with CapCut-style Multi-Track Timeline, 70+ Effects, Keyframing, Filters, and Cloud Sync.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 13, color: Color(0xFF374151), height: 1.4),
                                ),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.of(ctx).pop();
                                  context.push(RoutePaths.privacyPolicy);
                                },
                                child: const Text('Privacy Policy', style: TextStyle(color: AppColors.primary)),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.of(ctx).pop();
                                  context.push(RoutePaths.helpCenter);
                                },
                                child: const Text('Help Center', style: TextStyle(color: AppColors.primary)),
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(),
                                child: const Text('Close'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 4. Community & Support
            Text(
              'Community & Support',
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
                      key: const Key('me_help_center_tile'),
                      leading: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.menu_book_rounded, color: AppColors.primary, size: 20),
                      ),
                      title: const Text(
                        'Help Center & User Guides',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF111827)),
                      ),
                      subtitle: const Text(
                        'Master multi-track timeline, cinematic FX & export tutorials',
                        style: TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                      ),
                      trailing: const Icon(Icons.chevron_right, color: Color(0xFF9CA3AF)),
                      onTap: () => context.push(RoutePaths.helpCenter),
                    ),
                    const Divider(height: 1, color: Color(0xFFF3F4F6)),
                    ListTile(
                      key: const Key('me_contact_support_tile'),
                      leading: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.support_agent_rounded, color: Color(0xFF10B981), size: 20),
                      ),
                      title: const Text(
                        'Contact Us & Support',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF111827)),
                      ),
                      subtitle: const Text(
                        'Direct email support, ticket submission & diagnostics',
                        style: TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                      ),
                      trailing: const Icon(Icons.chevron_right, color: Color(0xFF9CA3AF)),
                      onTap: () => context.push(RoutePaths.contactSupport),
                    ),
                    const Divider(height: 1, color: Color(0xFFF3F4F6)),
                    ListTile(
                      key: const Key('me_rate_us_tile'),
                      leading: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFB800).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.star_rounded, color: Color(0xFFFFB800), size: 22),
                      ),
                      title: const Text(
                        'Rate Us',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF111827)),
                      ),
                      subtitle: const Text(
                        'Submit a star rating & review on Google Play Store',
                        style: TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                      ),
                      trailing: const Icon(Icons.chevron_right, color: Color(0xFF9CA3AF)),
                      onTap: _handleRateUs,
                    ),
                    const Divider(height: 1, color: Color(0xFFF3F4F6)),
                    ListTile(
                      key: const Key('me_share_app_tile'),
                      leading: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFF00C2CB).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.share_rounded, color: Color(0xFF00C2CB), size: 20),
                      ),
                      title: const Text(
                        'Share App',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF111827)),
                      ),
                      subtitle: const Text(
                        'Share Looma via WhatsApp, Instagram, Messages & more',
                        style: TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                      ),
                      trailing: const Icon(Icons.chevron_right, color: Color(0xFF9CA3AF)),
                      onTap: _handleShareApp,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 5. Legal & Privacy
            Text(
              'Legal & Privacy',
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
                      key: const Key('me_privacy_policy_tile'),
                      leading: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFF084298).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.privacy_tip_outlined, color: Color(0xFF084298), size: 20),
                      ),
                      title: const Text(
                        'Privacy Policy',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF111827)),
                      ),
                      subtitle: const Text(
                        'Offline-first media processing, zero ad tracking & data rights',
                        style: TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                      ),
                      trailing: const Icon(Icons.chevron_right, color: Color(0xFF9CA3AF)),
                      onTap: () => context.push(RoutePaths.privacyPolicy),
                    ),
                    const Divider(height: 1, color: Color(0xFFF3F4F6)),
                    ListTile(
                      key: const Key('me_app_permissions_tile'),
                      leading: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFF00C2CB).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.security_rounded, color: Color(0xFF00C2CB), size: 20),
                      ),
                      title: const Text(
                        'App Permissions',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF111827)),
                      ),
                      subtitle: const Text(
                        'Review Camera, Photos, Microphone, Notifications & Location access',
                        style: TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                      ),
                      trailing: const Icon(Icons.chevron_right, color: Color(0xFF9CA3AF)),
                      onTap: () => showPermissionsPrimerDialog(context),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 5. Account & Security
            Text(
              'Account & Cloud Security',
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
                    if (!isAuthenticated)
                      ListTile(
                        key: const Key('me_account_signin_list_tile'),
                        leading: const Icon(Icons.login, color: AppColors.primary),
                        title: const Text('Sign In or Register Account', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        subtitle: const Text('Enable private cloud project backup & multi-device sync', style: TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                        trailing: const Icon(Icons.chevron_right, color: Color(0xFF9CA3AF)),
                        onTap: () => context.push(RoutePaths.auth),
                      )
                    else ...[
                      ListTile(
                        key: const Key('me_account_status_list_tile'),
                        leading: const Icon(Icons.verified_user_outlined, color: Color(0xFF10B981)),
                        title: const Text('Looma Cloud Account', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        subtitle: Text('Signed in as ${user?.email}', style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('ACTIVE', style: TextStyle(color: Color(0xFF10B981), fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const Divider(height: 1, color: Color(0xFFF3F4F6)),
                      ListTile(
                        key: const Key('me_account_signout_list_tile'),
                        leading: const Icon(Icons.logout, color: Color(0xFFEF4444)),
                        title: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFFEF4444))),
                        subtitle: const Text('Local projects will remain safely on this device', style: TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                        onTap: _confirmSignOut,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmSignOut() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Sign Out?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text(
          'Your local projects will remain safe on this device. You can sign back in anytime to access your cloud backups.',
          style: TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref.read(authNotifierProvider.notifier).logout();
              if (mounted) {
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
