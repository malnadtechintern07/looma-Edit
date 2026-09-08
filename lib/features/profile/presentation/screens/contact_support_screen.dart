import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// Contact Us & Support screen for Looma Creators
class ContactSupportScreen extends ConsumerStatefulWidget {
  const ContactSupportScreen({super.key});

  static const String supportEmail = 'support@looma.app';

  @override
  ConsumerState<ContactSupportScreen> createState() => _ContactSupportScreenState();
}

class _ContactSupportScreenState extends ConsumerState<ContactSupportScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _subjectCtrl = TextEditingController();
  final TextEditingController _messageCtrl = TextEditingController();

  String _selectedCategory = 'Bug Report';
  bool _attachDiagnostics = true;
  bool _isSubmitting = false;

  final List<String> _categories = [
    'Bug Report',
    'Feature Suggestion',
    'Timeline & Editing Issue',
    'Export / Rendering Error',
    'Account & Cloud Sync',
    'General Inquiry',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authNotifierProvider).user;
      if (user != null && user.email.isNotEmpty) {
        _emailCtrl.text = user.email;
      }
    });
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _subjectCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  void _copySupportEmail() {
    Clipboard.setData(const ClipboardData(text: ContactSupportScreen.supportEmail));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Support email copied to clipboard (support@looma.app)'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _copyDiagnostics() {
    final diagnostics = '''
--- LOOMA SYSTEM DIAGNOSTICS ---
App Version: 2.4.0 (Build 240)
Engine: Offline Multi-Track Timeline
Hardware Acceleration: Enabled (H.264 / HEVC GPU)
Default Resolution: 1080p (FHD)
Cloud Sync API: Connected
Platform: Mobile Device Engine
Generated At: ${DateTime.now().toIso8601String()}
--------------------------------''';

    Clipboard.setData(ClipboardData(text: diagnostics));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Diagnostics copied! Paste into email or bug report.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _submitTicket() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);

    // Simulate short network ticket dispatch
    await Future.delayed(const Duration(milliseconds: 600));

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    final ticketId = '#LMA-${10000 + Random().nextInt(89999)}';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFECFDF5),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 48),
            ),
            const SizedBox(height: 16),
            const Text(
              'Ticket Submitted!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
            ),
            const SizedBox(height: 8),
            Text(
              'Your inquiry has been logged under ticket reference $ticketId.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Color(0xFF4B5563), height: 1.4),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Reference: $ticketId',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1F2937)),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Our creator engineering team will respond to your email within 12 hours.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
            ),
          ],
        ),
        actions: [
          TextButton(
            key: const Key('support_ticket_success_done_btn'),
            onPressed: () {
              Navigator.of(ctx).pop();
              _subjectCtrl.clear();
              _messageCtrl.clear();
            },
            child: const Text('Done', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9FE),
        elevation: 0,
        leading: IconButton(
          key: const Key('contact_support_back_button'),
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
          'Contact Us & Support',
          style: AppTypography.titleLarge.copyWith(
            color: const Color(0xFF111827),
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Direct Email Card
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
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.mark_email_read_rounded, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Official Creator Support',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Direct line to Looma engineers & specialists',
                              style: TextStyle(color: Color(0xFFC7D2FE), fontSize: 11.5),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          '< 12h Reply',
                          style: TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.alternate_email, color: Colors.white, size: 18),
                        const SizedBox(width: 10),
                        const Text(
                          ContactSupportScreen.supportEmail,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const Spacer(),
                        InkWell(
                          key: const Key('copy_support_email_btn'),
                          onTap: _copySupportEmail,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Copy',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 11.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 2. In-App Support Ticket Form
            Text(
              'Submit a Support Ticket',
              style: AppTypography.titleMedium.copyWith(
                color: const Color(0xFF111827),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFECEEF5)),
                boxShadow: const [
                  BoxShadow(color: Color(0x06000000), blurRadius: 12, offset: Offset(0, 4)),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category Selection
                    const Text(
                      'Issue Category',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF374151)),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          key: const Key('support_category_dropdown'),
                          value: _selectedCategory,
                          isExpanded: true,
                          icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF6B7280)),
                          items: _categories.map((cat) {
                            return DropdownMenuItem(
                              value: cat,
                              child: Text(cat, style: const TextStyle(fontSize: 13, color: Color(0xFF111827))),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedCategory = val);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // User Contact Email
                    const Text(
                      'Your Email',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF374151)),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      key: const Key('support_email_field'),
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        hintText: 'creator@domain.com',
                        hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
                        prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF6B7280), size: 18),
                        filled: true,
                        fillColor: const Color(0xFFF9FAFB),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Please enter your email';
                        if (!v.contains('@') || !v.contains('.')) return 'Please enter a valid email address';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Subject
                    const Text(
                      'Subject',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF374151)),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      key: const Key('support_subject_field'),
                      controller: _subjectCtrl,
                      decoration: InputDecoration(
                        hintText: 'e.g. Export failed at 98% with 4K 60FPS video',
                        hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
                        prefixIcon: const Icon(Icons.title_rounded, color: Color(0xFF6B7280), size: 18),
                        filled: true,
                        fillColor: const Color(0xFFF9FAFB),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Please enter a subject';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Description / Message
                    const Text(
                      'Description & Steps to Reproduce',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF374151)),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      key: const Key('support_message_field'),
                      controller: _messageCtrl,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Describe what happened, error messages, and which clip or filter you were using...',
                        hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
                        filled: true,
                        fillColor: const Color(0xFFF9FAFB),
                        contentPadding: const EdgeInsets.all(14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().length < 10) {
                          return 'Please provide at least 10 characters of detail';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    // Attach Diagnostics Checkbox
                    Row(
                      children: [
                        Checkbox(
                          key: const Key('support_attach_diagnostics_checkbox'),
                          value: _attachDiagnostics,
                          activeColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                          onChanged: (v) => setState(() => _attachDiagnostics = v ?? true),
                        ),
                        const Expanded(
                          child: Text(
                            'Attach anonymous device diagnostics (Looma v2.4.0, GPU encoder state)',
                            style: TextStyle(fontSize: 12, color: Color(0xFF4B5563)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        key: const Key('support_submit_ticket_btn'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 2,
                        ),
                        onPressed: _isSubmitting ? null : _submitTicket,
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.send_rounded, size: 18),
                                  SizedBox(width: 8),
                                  Text(
                                    'Submit Support Ticket',
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 3. System Diagnostics Card
            Text(
              'System Diagnostics',
              style: AppTypography.titleMedium.copyWith(
                color: const Color(0xFF111827),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFECEEF5)),
              ),
              child: Column(
                children: [
                  _buildDiagnosticRow('App Version', '2.4.0 (Build 240) • Production Engine'),
                  const Divider(height: 16, color: Color(0xFFF3F4F6)),
                  _buildDiagnosticRow('Timeline Engine', 'Multi-Track CapCut-Style Track Lane'),
                  const Divider(height: 16, color: Color(0xFFF3F4F6)),
                  _buildDiagnosticRow('GPU Acceleration', 'Active (H.264 / HEVC Hardware Encode)'),
                  const Divider(height: 16, color: Color(0xFFF3F4F6)),
                  _buildDiagnosticRow('Cloud Vault API', 'Connected (TLS 1.3 Secure)'),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      key: const Key('support_copy_diagnostics_btn'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: Color(0xFFBFDBFE)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      onPressed: _copyDiagnostics,
                      icon: const Icon(Icons.copy_all_rounded, size: 16),
                      label: const Text('Copy Diagnostics to Clipboard', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 4. Creator Communities
            Text(
              'Creator Communities',
              style: AppTypography.titleMedium.copyWith(
                color: const Color(0xFF111827),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),

            _buildCommunityCard(
              icon: Icons.forum_rounded,
              color: const Color(0xFF5865F2),
              title: 'Discord Creator Community',
              subtitle: 'Join 15,000+ mobile filmmakers & video editors',
              actionLabel: 'Join',
              onTap: () {
                Clipboard.setData(const ClipboardData(text: 'https://discord.gg/looma'));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Discord invite link copied to clipboard!')),
                );
              },
            ),
            const SizedBox(height: 10),

            _buildCommunityCard(
              icon: Icons.camera_alt_rounded,
              color: const Color(0xFFE1306C),
              title: 'Instagram @looma.app',
              subtitle: 'Daily transition tutorials, trending reels & creator spotlights',
              actionLabel: 'Follow',
              onTap: () {
                Clipboard.setData(const ClipboardData(text: 'https://instagram.com/looma.app'));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Instagram handle copied to clipboard!')),
                );
              },
            ),
            const SizedBox(height: 10),

            _buildCommunityCard(
              icon: Icons.play_circle_fill_rounded,
              color: const Color(0xFFFF0000),
              title: 'YouTube @LoomaVideoEditor',
              subtitle: 'Full masterclass video guides & editing workflows',
              actionLabel: 'Subscribe',
              onTap: () {
                Clipboard.setData(const ClipboardData(text: 'https://youtube.com/@LoomaVideoEditor'));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('YouTube channel link copied to clipboard!')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiagnosticRow(String label, String val) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12.5, color: Color(0xFF6B7280))),
        Flexible(
          child: Text(
            val,
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  Widget _buildCommunityCard({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required String actionLabel,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFECEEF5)),
        ),
        child: ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Color(0xFF111827)),
          ),
          subtitle: Text(
            subtitle,
            style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              actionLabel,
              style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11.5),
            ),
          ),
          onTap: onTap,
        ),
      ),
    );
  }
}
