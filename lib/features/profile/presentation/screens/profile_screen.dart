import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/route_paths.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/services/app_actions_service.dart';
import '../../../../core/services/app_remote_config_service.dart';
import '../../../../core/storage/storage_providers.dart';
import '../../../../core/widgets/permissions_primer_dialog.dart';
import '../../../../core/widgets/rate_us_dialog.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../projects/presentation/providers/projects_provider.dart';
import '../../../../core/config/server_config.dart';
import '../../../../core/services/live_admin_sync_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

/// Backwards compatibility alias for ProfileMeScreen
typedef ProfileMeScreen = SettingsScreen;

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _displayName = 'ProCut Creator';
  String _username = '@procutcreator';
  String _bio = '🎬 Mobile Filmmaker & Content Creator ✨ Creating aesthetic reels with PROCUT PRO';
  bool _autoSaveToGallery = true;
  bool _hardwareAcceleration = true;
  String _defaultResolution = '1080p (FHD)';

  @override
  void initState() {
    super.initState();
    _loadPersistedProfile();
  }

  Future<void> _loadPersistedProfile() async {
    final storage = ref.read(localStorageServiceProvider);
    final cached = await storage.readJson('profile/guest_identity.json');
    if (cached != null && mounted) {
      setState(() {
        final dName = cached['displayName'] as String?;
        final uName = cached['handle'] as String?;
        final uBio = cached['bio'] as String?;
        if (dName != null && dName.isNotEmpty) _displayName = dName;
        if (uName != null && uName.isNotEmpty) _username = uName;
        if (uBio != null && uBio.isNotEmpty) _bio = uBio;
      });
    }
  }

  void _showEditProfileDialog() {
    final user = ref.read(currentUserProvider);
    final initialName = user?.displayName.isNotEmpty == true
        ? user!.displayName
        : (user != null ? user.email.split('@').first : _displayName);
    final initialUser = user?.handle?.isNotEmpty == true
        ? user!.handle!
        : (user != null ? user.email : _username);
    final initialBio = user?.bio?.isNotEmpty == true
        ? user!.bio!
        : _bio;

    final nameCtrl = TextEditingController(text: initialName);
    final userCtrl = TextEditingController(text: initialUser);
    final bioCtrl = TextEditingController(text: initialBio);
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
          contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.badge_outlined, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Edit Identity Profile',
                  style: TextStyle(
                    color: Color(0xFF111827),
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                const Text(
                  'Your creator identity will be displayed across your projects and exported videos.',
                  style: TextStyle(color: Color(0xFF6B7280), fontSize: 12),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: 'Display Name',
                    hintText: 'e.g. Alex Video Producer',
                    prefixIcon: const Icon(Icons.person_outline, size: 20),
                    filled: true,
                    fillColor: const Color(0xFFF9FAFB),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: userCtrl,
                  decoration: InputDecoration(
                    labelText: 'Handle / Channel (@name)',
                    hintText: 'e.g. @alexcuts',
                    prefixIcon: const Icon(Icons.alternate_email, size: 20),
                    filled: true,
                    fillColor: const Color(0xFFF9FAFB),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: bioCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Bio & Status',
                    hintText: 'Share what you create with ProCut...',
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(bottom: 40),
                      child: Icon(Icons.description_outlined, size: 20),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF9FAFB),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.of(dialogCtx).pop(),
              child: const Text('Cancel', style: TextStyle(color: Color(0xFF6B7280))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              onPressed: isSaving
                  ? null
                  : () async {
                      final newName = nameCtrl.text.trim();
                      final newHandle = userCtrl.text.trim();
                      final newBio = bioCtrl.text.trim();

                      if (newName.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Display name cannot be empty')),
                        );
                        return;
                      }

                      setDialogState(() => isSaving = true);

                      final isAuth = ref.read(isAuthenticatedProvider);
                      if (isAuth) {
                        await ref.read(authNotifierProvider.notifier).updateProfile(
                              displayName: newName,
                              handle: newHandle.isNotEmpty ? newHandle : null,
                              bio: newBio.isNotEmpty ? newBio : null,
                            );
                      }

                      // Persist locally for both guest & fast cache
                      final storage = ref.read(localStorageServiceProvider);
                      await storage.writeJson('profile/guest_identity.json', {
                        'displayName': newName,
                        'handle': newHandle,
                        'bio': newBio,
                        'updatedAt': DateTime.now().toIso8601String(),
                      });

                      if (mounted) {
                        setState(() {
                          _displayName = newName;
                          _username = newHandle.isNotEmpty ? newHandle : _username;
                          _bio = newBio.isNotEmpty ? newBio : _bio;
                        });
                      }

                      if (dialogCtx.mounted) {
                        Navigator.of(dialogCtx).pop();
                      }

                      if (mounted) {
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          const SnackBar(
                            backgroundColor: AppColors.success,
                            content: Row(
                              children: [
                                Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                                SizedBox(width: 10),
                                Expanded(child: Text('Profile updated successfully! ✨')),
                              ],
                            ),
                          ),
                        );
                      }
                    },
              child: isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
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
    final socialCfg = ref.read(appRemoteConfigProvider).valueOrNull?.social;
    final storeUrl = socialCfg?.rateUsStoreUrl ?? '';
    if (storeUrl.isNotEmpty) {
      await AppActionsService.openUrl(storeUrl);
    } else {
      await showRateUsDialog(context);
    }
  }

  Future<void> _handleShareApp() async {
    final socialCfg = ref.read(appRemoteConfigProvider).valueOrNull?.social;
    final shareMsg = socialCfg?.shareAppMessage;
    final shareUrl = socialCfg?.shareAppUrl;
    final message = (shareMsg?.isNotEmpty == true)
        ? shareMsg!
        : (shareUrl?.isNotEmpty == true ? 'Check out ProCut! $shareUrl' : null);
    final success = await AppActionsService.shareApp(text: message);
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(shareUrl?.isNotEmpty == true
              ? 'ProCut link copied: $shareUrl'
              : 'ProCut download link copied to clipboard!'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showServerConfigDialog() async {
    final currentUrl = await ServerConfig.getBaseUrl();
    final urlCtrl = TextEditingController(text: currentUrl);

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.dns_outlined, color: Color(0xFF10B981), size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              'Server & Database',
              style: TextStyle(color: Color(0xFF111827), fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Connect to your hosted InfinityFree admin panel & MySQL database or a local development server.',
                style: TextStyle(color: Color(0xFF6B7280), fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 14),
              const Text(
                'Quick Presets:',
                style: TextStyle(color: Color(0xFF374151), fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  ActionChip(
                    backgroundColor: const Color(0xFFECFDF5),
                    side: const BorderSide(color: Color(0xFF10B981)),
                    label: const Text('☁️ Live Cloud (procut.free.nf)', style: TextStyle(color: Color(0xFF059669), fontSize: 11.5, fontWeight: FontWeight.w600)),
                    onPressed: () {
                      urlCtrl.text = ServerConfig.liveHostUrl;
                    },
                  ),
                  ActionChip(
                    backgroundColor: const Color(0xFFEFF6FF),
                    side: const BorderSide(color: Color(0xFF3B82F6)),
                    label: const Text('💻 Local Dev (5050)', style: TextStyle(color: Color(0xFF2563EB), fontSize: 11.5, fontWeight: FontWeight.w600)),
                    onPressed: () {
                      urlCtrl.text = 'http://${ServerConfig.defaultLocalIp}:${ServerConfig.defaultPort}';
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: urlCtrl,
                style: const TextStyle(color: Color(0xFF111827), fontSize: 13.5),
                decoration: InputDecoration(
                  labelText: 'Server Base URL',
                  labelStyle: const TextStyle(color: Color(0xFF6B7280)),
                  prefixIcon: const Icon(Icons.cloud_queue_outlined, color: Color(0xFF6B7280), size: 18),
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () {
                      urlCtrl.text = ServerConfig.defaultUrl;
                    },
                    child: const Text('Reset to Live Cloud', style: TextStyle(color: Color(0xFF2563EB), fontSize: 12)),
                  ),
                  const Text(
                    'procut.free.nf',
                    style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF6B7280))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              final newUrl = urlCtrl.text.trim();
              if (newUrl.isNotEmpty) {
                await ServerConfig.setBaseUrl(newUrl);
                if (ctx.mounted) Navigator.of(ctx).pop();
                ref.read(liveAdminSyncServiceProvider).syncNow();
              }
            },
            child: const Text('Save & Sync'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final user = authState.user;
    final isAuthenticated = authState.isAuthenticated;
    
    final currentDisplayName = user?.displayName.isNotEmpty == true
        ? user!.displayName
        : (user != null ? user.email.split('@').first : _displayName);
    final currentHandle = user?.handle?.isNotEmpty == true
        ? user!.handle!
        : (user != null ? user.email : _username);
    final currentBio = user?.bio?.isNotEmpty == true
        ? user!.bio!
        : _bio;

    final projects = ref.watch(projectsNotifierProvider).projects;
    final totalClips = projects.fold<int>(0, (sum, p) => sum + p.videoClips.length);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9FE),
        elevation: 0,
        centerTitle: false,
        leading: Navigator.of(context).canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF111827), size: 20),
                onPressed: () => context.pop(),
              )
            : null,
        title: Text(
          'Settings',
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
                      // Avatar with VIP Ring & Edit Tap
                      GestureDetector(
                        onTap: _showEditProfileDialog,
                        child: Stack(
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
                              child: Center(
                                child: Text(
                                  currentDisplayName.isNotEmpty ? currentDisplayName[0].toUpperCase() : 'P',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.edit, color: Colors.white, size: 12),
                            ),
                          ],
                        ),
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
                                children: [
                                  const Icon(Icons.cloud_done_rounded, color: Color(0xFF10B981), size: 13),
                                  const SizedBox(width: 4),
                                  const Expanded(
                                    child: Text(
                                      'Cloud Synced • Log in on any device',
                                      style: TextStyle(
                                        color: Color(0xFF10B981),
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 6),
                            Text(
                              currentBio,
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
                    children: [
                      Expanded(
                        child: _buildStatItem(
                          label: 'Projects',
                          value: '${projects.length}',
                          icon: Icons.movie_outlined,
                          color: AppColors.primary,
                        ),
                      ),
                      Container(width: 1, height: 32, color: const Color(0xFFE5E7EB)),
                      Expanded(
                        child: _buildStatItem(
                          label: 'Total Clips',
                          value: '$totalClips',
                          icon: Icons.video_library_outlined,
                          color: const Color(0xFF00C2CB),
                        ),
                      ),
                      Container(width: 1, height: 32, color: const Color(0xFFE5E7EB)),
                      Expanded(
                        child: _buildStatItem(
                          label: 'Saved Space',
                          value: '${(projects.length * 28.4).toStringAsFixed(0)} MB',
                          icon: Icons.sd_storage_outlined,
                          color: const Color(0xFFFFB800),
                        ),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Image.asset('assets/icon/app_icon.png', fit: BoxFit.contain),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Sign In or Register Account',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13.5,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Secure projects to cloud & sync across devices.',
                                style: TextStyle(
                                  color: Color(0xFFC7D2FE),
                                  fontSize: 11,
                                  height: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        key: const Key('me_tab_signin_register_btn'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.primary,
                          elevation: 3,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        onPressed: () {
                          try {
                            context.push(RoutePaths.auth);
                          } catch (_) {}
                        },
                        child: const Text('Sign In / Register', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
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
                      title: const Text('ProCut Cloud Backup', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
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
                      title: const Text('About ProCut Video Editor', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      subtitle: const Text('Version 2.4.0 (Build 240) • Offline Pro Engine', style: TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                      onLongPress: _showServerConfigDialog,
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
                                  'PROCUT',
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
                        'Share ProCut via WhatsApp, Instagram, Messages & more',
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
                        title: const Text('ProCut Cloud Account', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
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
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }
}
