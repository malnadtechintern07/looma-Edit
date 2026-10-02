import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/services/app_remote_config_service.dart';

/// Privacy Policy screen — content is fetched live from the admin panel via
/// [appRemoteConfigProvider]. Admin sets [privacy_policy_content] in
/// Settings → Support & Legal; it reaches the app via /api/app/config → legal.
class PrivacyPolicyScreen extends ConsumerStatefulWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  ConsumerState<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends ConsumerState<PrivacyPolicyScreen> {
  @override
  void initState() {
    super.initState();
    // Always fetch fresh config from admin panel when entering Privacy Policy screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.invalidate(appRemoteConfigProvider);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final configAsync = ref.watch(appRemoteConfigProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9FE),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          key: const Key('privacy_policy_back_button'),
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Color(0xFF111827), size: 20),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.pop();
            }
          },
        ),
        title: Text(
          'Privacy Policy',
          style: AppTypography.titleLarge.copyWith(
            color: const Color(0xFF111827),
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Refresh from Admin',
            icon: const Icon(Icons.refresh_rounded,
                color: Color(0xFF111827), size: 20),
            onPressed: () {
              ref.invalidate(appRemoteConfigProvider);
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: configAsync.when(
        loading: () => const _LoadingView(),
        error: (e, _) =>
            _ErrorView(onRetry: () => ref.invalidate(appRemoteConfigProvider)),
        data: (config) {
          final remoteContent = config.legal.privacyPolicyContent.trim();
          final content = remoteContent.isNotEmpty ? remoteContent : _defaultPrivacyPolicy;
          final companyName = config.legal.aboutCompanyName.isNotEmpty
              ? config.legal.aboutCompanyName
              : 'ProCut Studio';
          final copyright = config.legal.copyrightText.isNotEmpty
              ? config.legal.copyrightText
              : '© ${DateTime.now().year} $companyName';

          if (content.isEmpty) {
            return _EmptyContentView(companyName: companyName);
          }

          return _ContentView(
            content: content,
            companyName: companyName,
            copyright: copyright,
            supportEmail: config.support.email.isNotEmpty
                ? config.support.email
                : 'support@procut.app',
            onRefresh: () async {
              ref.invalidate(appRemoteConfigProvider);
              await ref.read(appRemoteConfigProvider.future);
            },
          );
        },
      ),
    );
  }
}

const String _defaultPrivacyPolicy = '''
PROCut PRIVACY COMMITMENT
Your media belongs to you. ProCut is engineered with a strict offline-first architecture: your source videos, voiceovers, photos, and project timelines are processed directly on your device and never uploaded to public clouds without your explicit direction.

1. OFFLINE-FIRST PROCESSING & MEDIA STORAGE
All video trimming, timeline slicing, multi-track layering, filter rendering, and audio ducking take place strictly within your mobile device's native hardware. ProCut does not transmit your source video clips, photos, or voiceover recordings to our servers for processing.

2. DEVICE PERMISSIONS & PURPOSE
• Photos, Media & Storage: Required solely to import video clips into your editing timeline and export rendered MP4 videos into your camera roll (DCIM/Movies).
• Microphone: Requested only when you intentionally record a custom voiceover track in the audio timeline.
• Camera: Used only if you choose to record new footage directly inside the media picker.
• Notifications: Used to notify you when background video rendering or cloud backup is completed.
We never access, index, or scan any files, photos, or audio recordings outside of what you explicitly select for your project.

3. OPTIONAL CLOUD SYNC & ACCOUNT DATA
If you register for a ProCut Cloud account, we store your account email, securely hashed password, and project metadata. When you choose to back up a project, your project JSON draft is transmitted over TLS 1.3 encryption and stored in a private storage vault accessible only by your authenticated session.

4. CACHE & TEMPORARY VIDEO FRAGMENTS
During video playback, preview thumbnails and audio waveform caches are saved in your app temporary sandbox for stutter-free performance. You can purge this cache anytime in the app settings under "Clear Temporary Cache" without losing any saved project drafts.

5. ZERO ADVERTISING & NO THIRD-PARTY DATA SELLING
ProCut contains no advertising tracking SDKs, no behavioral trackers, and no third-party data brokers. We never sell, rent, or monetize your creative media, exported clips, email addresses, or personal information under any circumstance.

6. USER RIGHTS & COMPLETE DATA DELETION
You retain full ownership of your content. You have the right to export your data, clear all cloud backups, or delete your ProCut account and associated data entirely at any time. Deleting a cloud project immediately purges its files from our cloud storage servers.

7. POLICY UPDATES & CONTACT
We may occasionally update this Privacy Policy to reflect app enhancements or legal requirements. Any modifications will be updated directly in this app.
For questions, data requests, or privacy inquiries, please contact our support team at support@procut.app.
''';

// ─── Loading ─────────────────────────────────────────────────────────────────

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(strokeWidth: 2.5),
          SizedBox(height: 16),
          Text(
            'Loading Privacy Policy…',
            style: TextStyle(color: Color(0xFF6B7280), fontSize: 14),
          ),
        ],
      ),
    );
  }
}

// ─── Error ────────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.wifi_off_rounded,
                  color: Color(0xFFEF4444), size: 36),
            ),
            const SizedBox(height: 20),
            const Text(
              'Could not load Privacy Policy',
              style: TextStyle(
                color: Color(0xFF111827),
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Check your internet connection and try again.',
              style:
                  TextStyle(color: Color(0xFF6B7280), fontSize: 13, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Empty (admin hasn't set content yet) ─────────────────────────────────────

class _EmptyContentView extends StatelessWidget {
  final String companyName;
  const _EmptyContentView({required this.companyName});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.shield_outlined,
                  color: AppColors.primary, size: 38),
            ),
            const SizedBox(height: 20),
            const Text(
              'Privacy Policy Coming Soon',
              style: TextStyle(
                color: Color(0xFF111827),
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              '$companyName is committed to protecting your privacy. '
              'Our full Privacy Policy will be available here shortly.',
              style: const TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 13,
                height: 1.55,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Main content view ────────────────────────────────────────────────────────

class _ContentView extends StatelessWidget {
  final String content;
  final String companyName;
  final String copyright;
  final String supportEmail;
  final Future<void> Function() onRefresh;

  const _ContentView({
    required this.content,
    required this.companyName,
    required this.copyright,
    required this.supportEmail,
    required this.onRefresh,
  });

  void _copyEmail(BuildContext context, String email) {
    Clipboard.setData(ClipboardData(text: email));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Email copied: $email'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Split content at blank lines into readable paragraphs
    final paragraphs = content
        .split(RegExp(r'\n\s*\n'))
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.primary,
      backgroundColor: Colors.white,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Hero header ────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF084298), Color(0xFF0D6EFD)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.28),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.verified_user_rounded,
                      color: Colors.white, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$companyName Privacy Policy',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 3),
                      const Text(
                        'Content managed live from Admin Panel.',
                        style: TextStyle(
                          color: Color(0xCCFFFFFF),
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Policy body ────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFECEEF5)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x06000000),
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.shield_rounded,
                        color: AppColors.primary, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Privacy Policy',
                      style: TextStyle(
                        color: Color(0xFF111827),
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24, color: Color(0xFFECEEF5)),
                ...paragraphs.map(
                  (para) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Text(
                      para,
                      style: const TextStyle(
                        color: Color(0xFF374151),
                        fontSize: 13.5,
                        height: 1.65,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Contact email card ─────────────────────────────────────────
          if (supportEmail.isNotEmpty) ...[
            InkWell(
              key: const Key('privacy_copy_email_tile'),
              onTap: () => _copyEmail(context, supportEmail),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFECEEF5)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.mail_lock_rounded,
                          color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Privacy Inquiries',
                            style: TextStyle(
                              color: Color(0xFF374151),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            supportEmail,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.copy_rounded,
                        color: AppColors.primary, size: 18),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // ── Copyright footer ───────────────────────────────────────────
          Center(
            child: Text(
              copyright,
              style: const TextStyle(
                color: Color(0xFF9CA3AF),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 8),
          const Center(
            child: Text(
              'Managed live from Admin Panel · ProCut',
              style: TextStyle(color: Color(0xFFD1D5DB), fontSize: 11),
            ),
          ),
        ],
      ),
    ),
    );
  }
}
