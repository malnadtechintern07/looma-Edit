import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/route_paths.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/services/app_remote_config_service.dart';

/// Comprehensive static & interactive About Screen for ProCut Video Editor
class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  static const String appName = 'ProCut Video Editor';
  static const String appVersion = '2.4.0';
  static const String buildNumber = '240';
  static const String defaultCompany = 'ProCut Studio & Malnad Tech';
  static const String defaultSupportEmail = 'support@procut.app';
  static const String websiteUrl = 'procut.free.nf';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final remoteConfig = ref.watch(appRemoteConfigProvider).valueOrNull;
    final companyName = (remoteConfig?.legal.aboutCompanyName.isNotEmpty ?? false)
        ? remoteConfig!.legal.aboutCompanyName
        : defaultCompany;
    final supportEmail = (remoteConfig?.support.email.isNotEmpty ?? false)
        ? remoteConfig!.support.email
        : defaultSupportEmail;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9FE),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          key: const Key('about_back_button'),
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF111827), size: 20),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.pop();
            }
          },
        ),
        title: Text(
          'About ProCut',
          style: AppTypography.titleLarge.copyWith(
            color: const Color(0xFF111827),
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            key: const Key('about_share_button'),
            icon: const Icon(Icons.share_outlined, color: Color(0xFF111827), size: 22),
            tooltip: 'Share App',
            onPressed: () => _showShareSheet(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 48),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── 1. Hero Brand Header ──────────────────────────────────────────
            _buildHeroHeader(context),
            const SizedBox(height: 20),

            // ── 2. About ProCut Overview ──────────────────────────────────────
            _buildSectionHeader('About ProCut', Icons.info_outline_rounded),
            const SizedBox(height: 10),
            _buildAboutStoryCard(companyName),
            const SizedBox(height: 24),

            // ── 3. Core Engine Highlights ─────────────────────────────────────
            _buildSectionHeader('Core Engine Capabilities', Icons.auto_awesome_rounded),
            const SizedBox(height: 10),
            _buildFeatureHighlights(),
            const SizedBox(height: 24),

            // ── 4. Technical Specs & Environment ──────────────────────────────
            _buildSectionHeader('Technical Specifications', Icons.memory_rounded),
            const SizedBox(height: 10),
            _buildSpecsCard(),
            const SizedBox(height: 24),

            // ── 5. Creator Studio & Support ───────────────────────────────────
            _buildSectionHeader('Developer & Studio', Icons.business_rounded),
            const SizedBox(height: 10),
            _buildStudioInfoCard(context, companyName, supportEmail),
            const SizedBox(height: 24),

            // ── 6. Legal, Licenses & Quick Links ──────────────────────────────
            _buildSectionHeader('Legal & Resources', Icons.gavel_rounded),
            const SizedBox(height: 10),
            _buildLegalLinksCard(context),
            const SizedBox(height: 32),

            // ── 7. Footer & Copyright ─────────────────────────────────────────
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  // ── 1. Hero Header Widget ──────────────────────────────────────────────────
  Widget _buildHeroHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0A2540),
            Color(0xFF0F172A),
            Color(0xFF1E293B),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0A2540).withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // App Icon with glowing border
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0D6EFD), Color(0xFF00C2CB), Color(0xFFFFB800)],
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0D6EFD).withValues(alpha: 0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.asset(
                'assets/icon/app_icon.png',
                width: 76,
                height: 76,
                errorBuilder: (ctx, err, stack) => Container(
                  width: 76,
                  height: 76,
                  color: AppColors.primary,
                  child: const Icon(Icons.movie_creation_rounded, color: Colors.white, size: 40),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // App Title
          const Text(
            'PROCut',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Pro Mobile Video Editor & Creative Studio',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 14),

          // Version & Status Badges
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildBadge(
                label: 'v$appVersion (Build $buildNumber)',
                icon: Icons.verified_rounded,
                bgColor: Colors.white.withValues(alpha: 0.1),
                textColor: Colors.white,
              ),
              _buildBadge(
                label: '64-BIT OFFLINE ENGINE',
                icon: Icons.bolt_rounded,
                bgColor: const Color(0xFF10B981).withValues(alpha: 0.2),
                textColor: const Color(0xFF34D399),
              ),
              _buildBadge(
                label: 'PRODUCTION STABLE',
                icon: Icons.shield_rounded,
                bgColor: const Color(0xFF00C2CB).withValues(alpha: 0.2),
                textColor: const Color(0xFF38BDF8),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadge({
    required String label,
    required IconData icon,
    required Color bgColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: textColor.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: textColor),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: textColor,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  // ── 2. About Story Card ───────────────────────────────────────────────────
  Widget _buildAboutStoryCard(String companyName) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFECEEF5)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.rocket_launch_rounded, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Our Mission & Vision',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'ProCut was engineered to empower mobile creators, filmmakers, YouTubers, and social storytellers with a studio-grade editing environment right on their smartphone.\n\n'
            'Featuring a desktop-class multi-track timeline, keyframe animation, 80+ visual filters, AI photo enhance, and hardware-accelerated 4K 60fps export — ProCut delivers uncompromising creative performance without requiring expensive cloud subscriptions or internet connectivity.',
            style: TextStyle(
              fontSize: 13.5,
              color: Color(0xFF4B5563),
              height: 1.55,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.lock_outline_rounded, size: 18, color: Color(0xFF0F172A)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Offline-First: All video fragments and project files are processed 100% on your local hardware.',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF334155),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── 3. Core Engine Highlights ─────────────────────────────────────────────
  Widget _buildFeatureHighlights() {
    final features = [
      _FeatureItem(
        icon: Icons.view_timeline_rounded,
        color: const Color(0xFF0D6EFD),
        title: 'Multi-Track Timeline',
        desc: 'Up to 4 video tracks, audio mixing, magnetic snapping, and precision frame-by-frame trimming.',
      ),
      _FeatureItem(
        icon: Icons.electric_bolt_rounded,
        color: const Color(0xFF10B981),
        title: 'Hardware 4K Export',
        desc: 'Export UHD 4K at up to 60 FPS utilizing native GPU hardware blitting and multi-threaded rendering.',
      ),
      _FeatureItem(
        icon: Icons.auto_fix_high_rounded,
        color: const Color(0xFF8B5CF6),
        title: 'AI Creative Studio',
        desc: 'AI portrait enhancements, style transformations, smart object isolation, and visual presets.',
      ),
      _FeatureItem(
        icon: Icons.palette_rounded,
        color: const Color(0xFFF59E0B),
        title: '80+ Cinema FX & LUTs',
        desc: 'Cinematic color grading LUTs, glitch, RGB split, retro VHS, optical zoom, and dissolve transitions.',
      ),
      _FeatureItem(
        icon: Icons.music_note_rounded,
        color: const Color(0xFFEC4899),
        title: 'Royalty-Free Audio Suite',
        desc: 'Curated music library, sound effects, multi-band audio equalizer, and voiceover recording.',
      ),
      _FeatureItem(
        icon: Icons.cloud_done_rounded,
        color: const Color(0xFF00C2CB),
        title: 'Cloud Backup & Sync',
        desc: 'Optional encrypted project cloud backup to sync work seamlessly across mobile devices.',
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFECEEF5)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: features.length,
        separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFF3F4F6)),
        itemBuilder: (ctx, index) {
          final f = features[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: f.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(f.icon, color: f.color, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        f.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        f.desc,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── 4. Technical Specs Card ───────────────────────────────────────────────
  Widget _buildSpecsCard() {
    final specs = [
      {'label': 'App Version', 'value': '$appVersion (Build $buildNumber)'},
      {'label': 'Render Pipeline', 'value': 'Skia / Impeller Hardware Blit'},
      {'label': 'Architecture', 'value': 'ARM64 Multi-threaded Engine'},
      {'label': 'Supported Video Codecs', 'value': 'H.264 / AVC, H.265 / HEVC'},
      {'label': 'Supported Audio Codecs', 'value': 'AAC-LC, PCM WAV, MP3'},
      {'label': 'Export Resolutions', 'value': '720p HD, 1080p FHD, 4K UHD'},
      {'label': 'Frame Rates Supported', 'value': '24, 25, 30, 50, 60 FPS'},
      {'label': 'Aspect Ratios', 'value': '9:16, 16:9, 1:1, 4:5, 2.35:1'},
      {'label': 'Storage Engine', 'value': 'High-performance SQLite & Temp RAM buffer'},
      {'label': 'Operating Systems', 'value': 'Android 8.0+ & iOS 14.0+'},
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFECEEF5)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          for (int i = 0; i < specs.length; i++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    specs[i]['label']!,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4B5563),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      specs[i]['value']!,
                      textAlign: TextAlign.end,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (i < specs.length - 1)
              const Divider(height: 1, color: Color(0xFFF3F4F6)),
          ],
        ],
      ),
    );
  }

  // ── 5. Studio & Support Info Card ─────────────────────────────────────────
  Widget _buildStudioInfoCard(BuildContext context, String companyName, String supportEmail) {
    return Material(
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
            leading: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFF0D6EFD).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.domain_rounded, color: Color(0xFF0D6EFD), size: 20),
            ),
            title: const Text('Developer / Studio', style: TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
            subtitle: Text(
              companyName,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF3F4F6)),
          ListTile(
            leading: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.alternate_email_rounded, color: Color(0xFF10B981), size: 20),
            ),
            title: const Text('Official Creator Support', style: TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
            subtitle: Text(
              supportEmail,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.copy_rounded, size: 18, color: Color(0xFF6B7280)),
              tooltip: 'Copy Email',
              onPressed: () {
                Clipboard.setData(ClipboardData(text: supportEmail));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Copied $supportEmail to clipboard'),
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF3F4F6)),
          ListTile(
            leading: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFF00C2CB).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.language_rounded, color: Color(0xFF00C2CB), size: 20),
            ),
            title: const Text('Official Web Portal', style: TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
            subtitle: const Text(
              websiteUrl,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
            ),
            trailing: const Icon(Icons.open_in_new_rounded, size: 18, color: Color(0xFF6B7280)),
            onTap: () {
              Clipboard.setData(const ClipboardData(text: 'http://procut.free.nf'));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Website URL copied to clipboard'),
                  behavior: SnackBarBehavior.floating,
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
    ),
  );
}

  // ── 6. Legal & Quick Links Card ───────────────────────────────────────────
  Widget _buildLegalLinksCard(BuildContext context) {
    return Material(
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
            key: const Key('about_privacy_policy_tile'),
            leading: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF084298).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.privacy_tip_outlined, color: Color(0xFF084298), size: 20),
            ),
            title: const Text('Privacy Policy', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            subtitle: const Text('Zero ad tracking & private local storage', style: TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
            trailing: const Icon(Icons.chevron_right, color: Color(0xFF9CA3AF)),
            onTap: () => context.push(RoutePaths.privacyPolicy),
          ),
          const Divider(height: 1, color: Color(0xFFF3F4F6)),
          ListTile(
            key: const Key('about_help_center_tile'),
            leading: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.help_outline_rounded, color: Color(0xFF10B981), size: 20),
            ),
            title: const Text('Help Center & User Guides', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            subtitle: const Text('Tutorials on multi-track editing & effects', style: TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
            trailing: const Icon(Icons.chevron_right, color: Color(0xFF9CA3AF)),
            onTap: () => context.push(RoutePaths.helpCenter),
          ),
          const Divider(height: 1, color: Color(0xFFF3F4F6)),
          ListTile(
            key: const Key('about_contact_support_tile'),
            leading: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFFF3B5C).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.headset_mic_outlined, color: Color(0xFFFF3B5C), size: 20),
            ),
            title: const Text('Contact Support & Feedback', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            subtitle: const Text('Report bugs or suggest new timeline features', style: TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
            trailing: const Icon(Icons.chevron_right, color: Color(0xFF9CA3AF)),
            onTap: () => context.push(RoutePaths.contactSupport),
          ),
          const Divider(height: 1, color: Color(0xFFF3F4F6)),
          ListTile(
            key: const Key('about_licenses_tile'),
            leading: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.description_outlined, color: Color(0xFFF59E0B), size: 20),
            ),
            title: const Text('Open Source Licenses', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            subtitle: const Text('Third-party software libraries & credits', style: TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
            trailing: const Icon(Icons.chevron_right, color: Color(0xFF9CA3AF)),
            onTap: () {
              showLicensePage(
                context: context,
                applicationName: appName,
                applicationVersion: 'v$appVersion',
                applicationIcon: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    'assets/icon/app_icon.png',
                    width: 48,
                    height: 48,
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.movie_creation_rounded, size: 48),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    ),
  );
}

  // ── 7. Footer & Copyright ─────────────────────────────────────────────────
  Widget _buildFooter() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Crafted with ',
              style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
            ),
            const Icon(Icons.favorite, size: 14, color: Color(0xFFFF3B5C)),
            const Text(
              ' for creators worldwide',
              style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          '© 2026 ProCut Studio. All rights reserved.',
          style: TextStyle(
            fontSize: 11,
            color: Color(0xFF9CA3AF),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF4B5563)),
        const SizedBox(width: 8),
        Text(
          title,
          style: AppTypography.titleMedium.copyWith(
            color: const Color(0xFF111827),
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ],
    );
  }

  void _showShareSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Share ProCut Video Editor',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
              ),
              const SizedBox(height: 8),
              const Text(
                'Spread the word and invite other video creators to experience multi-track editing on mobile.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.copy_rounded, color: AppColors.primary),
                ),
                title: const Text('Copy ProCut App Link', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('http://procut.free.nf'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  Clipboard.setData(const ClipboardData(
                    text: 'Create stunning 4K videos on mobile with ProCut Video Editor! Download now: http://procut.free.nf',
                  ));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('ProCut share link copied to clipboard!'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureItem {
  final IconData icon;
  final Color color;
  final String title;
  final String desc;

  const _FeatureItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.desc,
  });
}
