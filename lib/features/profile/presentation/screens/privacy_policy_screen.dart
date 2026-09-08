import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';

/// Comprehensive Privacy Policy screen for Looma Video Editor
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const String privacyContactEmail = 'privacy@looma.video';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9FE),
        elevation: 0,
        leading: IconButton(
          key: const Key('privacy_policy_back_button'),
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
            tooltip: 'Copy Privacy Email',
            icon: const Icon(Icons.copy_rounded, color: AppColors.primary, size: 20),
            onPressed: () => _copyEmail(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Hero Commitment Header Card
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.verified_user_rounded, color: Colors.white, size: 26),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Looma Privacy Commitment',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 17,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Effective: September 2026 • Version 2.4.0',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Your media belongs to you. Looma is engineered with a strict offline-first architecture: your videos, voiceovers, photos, and edits are processed on-device and never uploaded to public clouds without your explicit direction.',
                    style: TextStyle(
                      color: Color(0xFFE0E7FF),
                      fontSize: 13,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: const [
                      _PrivacyPill(icon: Icons.offline_bolt_rounded, label: '100% Offline Engine'),
                      _PrivacyPill(icon: Icons.block_rounded, label: 'Zero Ad Tracking'),
                      _PrivacyPill(icon: Icons.lock_rounded, label: 'End-to-End Encrypted Cloud'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            // 2. Section 1: Offline Processing & Media Handling
            _buildSectionCard(
              icon: Icons.smartphone_rounded,
              color: AppColors.primary,
              title: '1. Offline-First Processing & Media Storage',
              content:
                  'All video trimming, timeline slicing, multi-track layering, filter rendering, and audio ducking take place strictly within your mobile device’s native hardware. Looma does not transmit your source video clips, photos, or voiceover recordings to our servers for processing.',
            ),
            const SizedBox(height: 14),

            // 3. Section 2: Permissions Required
            _buildSectionCard(
              icon: Icons.vpn_key_rounded,
              color: const Color(0xFF00C2CB),
              title: '2. Device Permissions & Purpose',
              content:
                  '• Photos & Storage: Required solely to import clips into your editing timeline and export rendered MP4 videos into your camera roll (DCIM/Movies).\n'
                  '• Microphone: Requested only when you intentionally record a custom voiceover track in the audio tab.\n'
                  '• Camera (Optional): Used only if you choose to record new footage directly inside the media picker.\n\n'
                  'We do not access any files, photos, or audio recordings outside of what you explicitly select for your project.',
            ),
            const SizedBox(height: 14),

            // 4. Section 3: Cloud Synchronization & Authentication
            _buildSectionCard(
              icon: Icons.cloud_done_rounded,
              color: const Color(0xFF10B981),
              title: '3. Optional Cloud Sync & Account Data',
              content:
                  'If you register for a Looma Cloud account, we store your account email, hashed password, and project metadata securely. When you choose to back up a project, your project JSON draft is transmitted over TLS 1.3 encryption and stored in a private storage vault accessible only by your authenticated session.',
            ),
            const SizedBox(height: 14),

            // 5. Section 4: Cache & Local Temporary Files
            _buildSectionCard(
              icon: Icons.cleaning_services_rounded,
              color: const Color(0xFFFFB800),
              title: '4. Cache & Temporary Video Fragments',
              content:
                  'During video playback, preview thumbnails and audio waveform caches are saved in your app temporary sandbox for stutter-free performance. You can purge this cache anytime in the "Me" section under "Clear Temporary Cache" without losing project drafts.',
            ),
            const SizedBox(height: 14),

            // 6. Section 5: Analytics & Advertising Policy
            _buildSectionCard(
              icon: Icons.visibility_off_rounded,
              color: const Color(0xFFEC4899),
              title: '5. Zero Advertising & Third-Party Selling',
              content:
                  'Looma contains no advertising tracking SDKs, no behavioral trackers, and no third-party data brokers. We never sell, rent, or monetize your creative media, exported clips, email addresses, or personal information under any circumstance.',
            ),
            const SizedBox(height: 14),

            // 7. Section 6: Data Deletion & Your Rights
            _buildSectionCard(
              icon: Icons.delete_outline_rounded,
              color: const Color(0xFFEF4444),
              title: '6. User Rights & Complete Data Deletion',
              content:
                  'You have the full right to delete your local projects, clear all cloud backups, or delete your Looma account entirely at any time. Deleting a cloud project immediately purges its files from our cloud storage vaults.',
            ),
            const SizedBox(height: 14),

            // 8. Section 7: Contact Data Privacy Officer
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFECEEF5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.mail_lock_rounded, color: AppColors.primary, size: 22),
                      SizedBox(width: 10),
                      Text(
                        '7. Contact Data Privacy Officer',
                        style: TextStyle(
                          color: Color(0xFF111827),
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'For privacy inquiries, GDPR/CCPA data requests, or policy clarifications, contact our designated privacy team directly at:',
                    style: TextStyle(color: Color(0xFF4B5563), fontSize: 13, height: 1.45),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    key: const Key('privacy_copy_email_tile'),
                    onTap: () => _copyEmail(context),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.email_outlined, color: AppColors.primary, size: 18),
                          SizedBox(width: 10),
                          Text(
                            privacyContactEmail,
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 13.5,
                            ),
                          ),
                          Spacer(),
                          Text(
                            'Copy',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _copyEmail(BuildContext context) {
    Clipboard.setData(const ClipboardData(text: privacyContactEmail));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Privacy contact email copied to clipboard ($privacyContactEmail)'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required Color color,
    required String title,
    required String content,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: const TextStyle(
              color: Color(0xFF4B5563),
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _PrivacyPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _PrivacyPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
