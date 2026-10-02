import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
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
    // Safely refresh config from admin panel when entering Privacy Policy screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        try {
          ref.invalidate(appRemoteConfigProvider);
        } catch (_) {}
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // If not wrapped in ProviderScope (e.g. some isolated unit tests), fallback safely
    AsyncValue<dynamic> configAsync;
    try {
      configAsync = ref.watch(appRemoteConfigProvider);
    } catch (_) {
      configAsync = AsyncValue.data(null);
    }

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
              try {
                ref.invalidate(appRemoteConfigProvider);
              } catch (_) {}
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: configAsync.when(
        loading: () => _ContentView(
          content: _defaultPrivacyPolicy,
          companyName: 'PusherHub',
          copyright: '© ${DateTime.now().year} PusherHub · Harsha',
          supportEmail: 'harsha.malnadtech@gmail.com',
          onRefresh: () async {
            try {
              ref.invalidate(appRemoteConfigProvider);
              await ref.read(appRemoteConfigProvider.future);
            } catch (_) {}
          },
        ),
        error: (e, _) => _ContentView(
          content: _defaultPrivacyPolicy,
          companyName: 'PusherHub',
          copyright: '© ${DateTime.now().year} PusherHub · Harsha',
          supportEmail: 'harsha.malnadtech@gmail.com',
          onRefresh: () async {
            try {
              ref.invalidate(appRemoteConfigProvider);
              await ref.read(appRemoteConfigProvider.future);
            } catch (_) {}
          },
        ),
        data: (config) {
          final remoteContent = config != null
              ? (config.legal?.privacyPolicyContent as String? ?? '').trim()
              : '';
          final content =
              remoteContent.isNotEmpty ? remoteContent : _defaultPrivacyPolicy;
          final companyName = (config != null
                  ? (config.legal?.aboutCompanyName as String? ?? '')
                  : '')
              .trim();
          final effectiveCompanyName =
              companyName.isNotEmpty ? companyName : 'PusherHub';
          final copyright = (config != null
                  ? (config.legal?.copyrightText as String? ?? '')
                  : '')
              .trim();
          final effectiveCopyright = copyright.isNotEmpty
              ? copyright
              : '© ${DateTime.now().year} $effectiveCompanyName · Harsha';

          return _ContentView(
            content: content,
            companyName: effectiveCompanyName,
            copyright: effectiveCopyright,
            supportEmail: 'harsha.malnadtech@gmail.com',
            onRefresh: () async {
              try {
                ref.invalidate(appRemoteConfigProvider);
                await ref.read(appRemoteConfigProvider.future);
              } catch (_) {}
            },
          );
        },
      ),
    );
  }
}

class _ThirdPartyServiceItem {
  final String name;
  final String url;
  final IconData icon;
  final Color color;
  final bool isPusherHub;
  final String description;

  const _ThirdPartyServiceItem({
    required this.name,
    required this.url,
    required this.icon,
    required this.color,
    this.isPusherHub = false,
    required this.description,
  });
}

const List<_ThirdPartyServiceItem> _kThirdPartyServices = [
  _ThirdPartyServiceItem(
    name: 'Google Play Services',
    url: 'https://policies.google.com/privacy',
    icon: Icons.shop_rounded,
    color: Color(0xFF0F9D58),
    description: 'Android platform authentication, safety and location services.',
  ),
  _ThirdPartyServiceItem(
    name: 'AdMob',
    url: 'https://support.google.com/admob/answer/6128543?hl=en',
    icon: Icons.ads_click_rounded,
    color: Color(0xFFEA4335),
    description: 'Ad personalization, impression measurement and analytics.',
  ),
  _ThirdPartyServiceItem(
    name: 'Google Analytics for Firebase',
    url: 'https://firebase.google.com/policies/analytics',
    icon: Icons.analytics_rounded,
    color: Color(0xFFFF8F00),
    description: 'Usage analytics, user engagement and in-app event tracking.',
  ),
  _ThirdPartyServiceItem(
    name: 'Firebase Crashlytics',
    url: 'https://firebase.google.com/support/privacy',
    icon: Icons.bug_report_rounded,
    color: Color(0xFFFFCA28),
    description: 'Real-time crash diagnostics, error logs and app stability.',
  ),
  _ThirdPartyServiceItem(
    name: 'Facebook',
    url: 'https://www.facebook.com/about/privacy/update/printable',
    icon: Icons.facebook_rounded,
    color: Color(0xFF1877F2),
    description: 'Attribution, audience insights and developer tools.',
  ),
  _ThirdPartyServiceItem(
    name: 'PusherHub',
    url: '',
    icon: Icons.notifications_active_rounded,
    color: Color(0xFF0D6EFD),
    isPusherHub: true,
    description: 'Push notifications & real-time messaging engine (DPDP Act, 2023).',
  ),
];

const String _defaultPrivacyPolicy = '''Privacy Policy
Last updated 28 September 2026

The app does use third-party services that may collect information used to identify you.
Link to the privacy policy of third-party service providers used by the app
• Google Play Services
• AdMob
• Google Analytics for Firebase
• Firebase Crashlytics
• Facebook
• PusherHub

This policy explains what personal data PusherHub collects, why, and what you can do about it. It covers the hosted PusherHub service at this website — the website, the dashboard, the REST API and the SDKs. It doesn't cover copies of PusherHub that other people host on their own servers.

PusherHub is operated by Harsha ("we", "us"), who is responsible for your personal data under India's Digital Personal Data Protection Act, 2023.

Two kinds of data
Your account data is about you, as a PusherHub customer. We decide how it's used, and this policy explains how.
Your app users' data is about the people who use the apps you connect to PusherHub. You decide what's collected and why; we store and process it only to deliver your notifications and messages, on your instructions. If you're one of those app users, the app's own privacy policy applies, and the app's developer is the right person to contact first.

What we collect about you
Account details — your name, email address and password. Passwords are stored only as a secure hash; we can't see them.
Google sign-in — if you sign in with Google, we receive your name, email address, Google account ID and profile picture. We don't get your Google password or access to anything else in your Google account.
Sign-in records — when you last signed in, and the IP address used to ask for a sign-in or password-reset code. The codes themselves are stored only as a hash and deleted once they expire.
Payments — the plan you bought, the amount, the date and status, and the Razorpay order and payment IDs. Your card, UPI or bank details go straight to Razorpay; we never receive or store them.
What you set up in PusherHub — your apps, the Firebase service account you connect, API keys, notifications, templates, segments, topics, in-app messages and webhook addresses. Firebase service accounts and API secret keys are stored encrypted.
Server logs — like most websites, our servers record requests (IP address, time, page and browser) for security and troubleshooting.

What PusherHub stores about your app users
When your app registers a device with PusherHub, through our SDK or API, we store:
the device's Firebase messaging token, platform, brand and model, app version, language and timezone;
whether the user has allowed notifications, and when the device was last active;
a user ID, only if your app sends one;
an approximate location — country, state and city — worked out from the device's IP address. The IP address itself isn't stored with the device;
what happened to each notification and in-app message: delivered, opened, clicked, shown or dismissed.

How we use data
To run the Service: sign you in, send your notifications and messages, and show your analytics.
To apply your plan's limits and features, and to process your payments.
To email you sign-in codes, password-reset codes, and important messages about your account or the Service.
To keep PusherHub secure: block abuse, limit repeated sign-in attempts and investigate problems.
To meet our legal, tax and accounting obligations.
We don't sell personal data, we don't show ads, and we don't use your app users' data for any purpose of our own.

Cookies
We only use the cookies the site needs to work:
a session cookie that keeps you signed in;
a security token (XSRF-TOKEN) that protects forms against cross-site request forgery;
a "remember me" cookie, only if you tick that box when you sign in.
We don't use analytics or advertising cookies. Some pages load services from other companies, which may set their own cookies or see your IP address: fonts from Google Fonts on our public pages, Google Sign-In on the sign-in page, and Razorpay Checkout when you pay.

Who we share data with
We share personal data only with the service providers that help us run PusherHub, and only what they need:
Google (Firebase Cloud Messaging) — to deliver push notifications, through the Firebase project you connect;
Google (Sign-In) — if you choose to sign in with Google;
Razorpay — to process payments;
our hosting provider, which runs the servers PusherHub is on, and our email provider, which delivers sign-in and reset codes.
We may also disclose data where the law requires it — for example, a valid order from a court or government authority — or where it's needed to protect the rights, property or safety of our users or the public. Some providers, such as Google, may process data outside India under their own privacy and security commitments.

How long we keep data
Account data — for as long as you have an account. When you ask us to delete your account, we delete your account data together with the apps, devices and messages in it.
Payment records — for as long as Indian tax and accounting law requires, even after your account is deleted.
Sign-in and reset codes — deleted once they expire.
App users' devices — removed after they've been inactive for the period set for each app, or when you delete the app.
Delivery and engagement records — kept while your account exists, so your analytics keep working.
Server logs — kept only as long as they're needed for security and troubleshooting.

How we protect data
Passwords and sign-in codes are hashed. Firebase service accounts and API secret keys are encrypted. Each customer can see only their own apps and data, and sign-in attempts are rate-limited. No system is perfectly secure, but if a breach affects your personal data, we'll tell you and the authorities as the law requires.

Your rights
Under India's Digital Personal Data Protection Act, 2023, you can:
ask for a summary of the personal data we hold about you and how we use it;
ask us to correct, complete or update it;
ask us to delete it, unless the law requires us to keep it;
withdraw your consent — which may mean closing your account;
nominate someone to exercise these rights for you if you die or can't act yourself;
raise a grievance with us and, if you're not satisfied with our answer, complain to the Data Protection Board of India.
You can change your password at any time with Forgot password? on the sign-in page. For anything else, contact our Grievance Officer below.

Children
PusherHub is a service for businesses and developers, and isn't meant for anyone under 18. If you believe a child has created an account, contact us and we'll delete it.

Changes to this policy
When we change this policy, we update the date at the top. If a change is significant, we'll tell you by email or in the dashboard before it takes effect.

Contact and Grievance Officer
For questions, requests or complaints about your personal data:
Grievance Officer: Harsha
Email: harsha.malnadtech@gmail.com
We'll acknowledge your request and respond within the time limits set by Indian law.''';

// ─── Main Content View ───────────────────────────────────────────────────────

class _ContentView extends StatefulWidget {
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

  @override
  State<_ContentView> createState() => _ContentViewState();
}

class _ContentViewState extends State<_ContentView> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _pusherHubKey = GlobalKey();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _copyEmail(BuildContext context, String email) {
    Clipboard.setData(ClipboardData(text: email));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Privacy contact email copied to clipboard: $email'),
        duration: const Duration(seconds: 2),
        backgroundColor: const Color(0xFF1E293B),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _launchExternalPolicy(BuildContext context, _ThirdPartyServiceItem provider) async {
    final uri = Uri.tryParse(provider.url);
    if (uri != null) {
      try {
        final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (!launched && context.mounted) {
          _showProviderFallbackDialog(context, provider);
        }
      } catch (_) {
        if (context.mounted) {
          _showProviderFallbackDialog(context, provider);
        }
      }
    }
  }

  void _showProviderFallbackDialog(BuildContext context, _ThirdPartyServiceItem provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(provider.icon, color: provider.color, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                provider.name,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              provider.description,
              style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
            ),
            const SizedBox(height: 12),
            const Text(
              'Official Privacy Policy URL:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 4),
            SelectableText(
              provider.url,
              style: const TextStyle(fontSize: 12, color: Color(0xFF0D6EFD)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: provider.url));
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Copied link: ${provider.name}'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            icon: const Icon(Icons.copy_rounded, size: 16),
            label: const Text('Copy Link'),
          ),
        ],
      ),
    );
  }

  Widget _buildThirdPartyServicesCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
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
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D6EFD).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.hub_rounded, color: Color(0xFF0D6EFD), size: 18),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Third-Party Services',
                  style: TextStyle(
                    color: Color(0xFF0F172A),
                    fontWeight: FontWeight.w700,
                    fontSize: 14.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'The app does use third-party services that may collect information used to identify you.',
            style: TextStyle(
              color: Color(0xFF475569),
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Link to the privacy policy of third-party service providers used by the app',
            style: TextStyle(
              color: Color(0xFF1E293B),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          ..._kThirdPartyServices.map((provider) => _buildProviderRow(context, provider)),
        ],
      ),
    );
  }

  Widget _buildProviderRow(BuildContext context, _ThirdPartyServiceItem provider) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () {
        if (provider.isPusherHub) {
          Scrollable.ensureVisible(
            _pusherHubKey.currentContext ?? context,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        } else {
          _launchExternalPolicy(context, provider);
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              '• ',
              style: TextStyle(
                color: Color(0xFF0D6EFD),
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            Expanded(
              child: Text(
                provider.name,
                style: TextStyle(
                  color: const Color(0xFF1D4ED8),
                  fontSize: 14,
                  fontWeight: provider.isPusherHub ? FontWeight.w800 : FontWeight.w600,
                  decoration: TextDecoration.underline,
                  decorationColor: const Color(0xFF1D4ED8).withValues(alpha: 0.4),
                ),
              ),
            ),
            if (provider.isPusherHub)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D6EFD).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF0D6EFD).withValues(alpha: 0.25)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.shield_rounded, size: 12, color: Color(0xFF0D6EFD)),
                    SizedBox(width: 4),
                    Text(
                      'PusherHub Policy',
                      style: TextStyle(
                        color: Color(0xFF0D6EFD),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              )
            else
              const Icon(
                Icons.open_in_new_rounded,
                color: Color(0xFF94A3B8),
                size: 15,
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final parsed = _parsePolicy(widget.content, widget.supportEmail);

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      color: AppColors.primary,
      backgroundColor: Colors.white,
      child: SingleChildScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Hero Header ──────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF0D6EFD)],
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.shield_rounded,
                            color: Colors.white, size: 26),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.25)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.verified_rounded,
                                color: Color(0xFF6EE7B7), size: 14),
                            SizedBox(width: 5),
                            Text(
                              'DPDP Act, 2023',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Privacy Policy',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 22,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    parsed.lastUpdated.isNotEmpty
                        ? parsed.lastUpdated
                        : 'Last updated 28 September 2026',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Third-Party Services Card ────────────────────────────────
            _buildThirdPartyServicesCard(context),

            // ── Scope & Regulatory Authority Card ────────────────────────
            Container(
              key: _pusherHubKey,
              child: parsed.preamble.isNotEmpty
                  ? Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x06000000),
                            blurRadius: 8,
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
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0D6EFD).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.info_outline_rounded,
                                    color: Color(0xFF0D6EFD), size: 18),
                              ),
                              const SizedBox(width: 10),
                              const Text(
                                'Scope & Regulatory Authority',
                                style: TextStyle(
                                  color: Color(0xFF0F172A),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 22, color: Color(0xFFF1F5F9)),
                          ...parsed.preamble.map(
                            (p) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                p,
                                style: const TextStyle(
                                  color: Color(0xFF334155),
                                  fontSize: 13.5,
                                  height: 1.6,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),

            // ── Structured Policy Sections ───────────────────────────────
            ...parsed.sections.map((section) => _buildSectionCard(section)),

            // ── Dedicated Grievance Officer & Contact Card ───────────────
            _buildGrievanceOfficerCard(context, parsed),

            const SizedBox(height: 24),

            // ── Copyright footer ─────────────────────────────────────────
            Center(
              child: Text(
                widget.copyright,
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 6),
            const Center(
              child: Text(
                'India\'s Digital Personal Data Protection Act, 2023 Compliant',
                style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(_SectionData section) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: section.iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(section.icon, color: section.iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  section.title,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontWeight: FontWeight.w800,
                    fontSize: 15.5,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 22, color: Color(0xFFF1F5F9)),

          // Body text / introductory lines
          if (section.leadText != null && section.leadText!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                section.leadText!,
                style: const TextStyle(
                  color: Color(0xFF475569),
                  fontSize: 13.5,
                  height: 1.6,
                ),
              ),
            ),

          // Items list
          ...section.items.map((item) => _buildListItem(item)),

          // Highlight Callout (e.g. Zero-Selling Assurance)
          if (section.calloutText != null && section.calloutText!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.verified_rounded,
                      color: Color(0xFF16A34A), size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      section.calloutText!,
                      style: const TextStyle(
                        color: Color(0xFF166534),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildListItem(_ItemData item) {
    if (item.prefix.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 11),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 6, right: 10),
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: Color(0xFF0D6EFD),
                shape: BoxShape.circle,
              ),
            ),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(
                    color: Color(0xFF334155),
                    fontSize: 13.2,
                    height: 1.58,
                  ),
                  children: [
                    TextSpan(
                      text: '${item.prefix} — ',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    TextSpan(text: item.body),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6, right: 10),
            width: 5,
            height: 5,
            decoration: const BoxDecoration(
              color: Color(0xFF64748B),
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              item.body,
              style: const TextStyle(
                color: Color(0xFF334155),
                fontSize: 13.2,
                height: 1.58,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrievanceOfficerCard(
      BuildContext context, _ParsedPolicy policy) {
    final officerName =
        policy.grievanceOfficer.isNotEmpty ? policy.grievanceOfficer : 'Harsha';
    final officerEmail = policy.grievanceEmail.isNotEmpty
        ? policy.grievanceEmail
        : 'harsha.malnadtech@gmail.com';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFBFDBFE), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D6EFD).withValues(alpha: 0.06),
            blurRadius: 14,
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
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0D6EFD), Color(0xFF0284C7)],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    officerName.isNotEmpty
                        ? officerName.substring(0, 1).toUpperCase()
                        : 'H',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Contact and Grievance Officer',
                      style: TextStyle(
                        color: Color(0xFF0F172A),
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Grievance Officer: $officerName',
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 24, color: Color(0xFFE2E8F0)),
          const Text(
            'For questions, requests or complaints about your personal data:',
            style: TextStyle(
              color: Color(0xFF475569),
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 14),

          // Interactive copy email tile
          InkWell(
            key: const Key('privacy_copy_email_tile'),
            onTap: () => _copyEmail(context, officerEmail),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFCBD5E1)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D6EFD).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.mail_lock_rounded,
                        color: Color(0xFF0D6EFD), size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Direct Grievance Channel',
                          style: TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          officerEmail,
                          style: const TextStyle(
                            color: Color(0xFF0D6EFD),
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Tooltip(
                    message: 'Copy Email',
                    child: Icon(Icons.copy_rounded,
                        color: Color(0xFF0D6EFD), size: 18),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.schedule_rounded,
                  color: Color(0xFF10B981), size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'We\'ll acknowledge your request and respond within the time limits set by Indian law.',
                  style: TextStyle(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.75),
                    fontSize: 12,
                    height: 1.45,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Data Structures & Parser ────────────────────────────────────────────────

class _ParsedPolicy {
  final String lastUpdated;
  final List<String> preamble;
  final List<_SectionData> sections;
  final String grievanceOfficer;
  final String grievanceEmail;

  _ParsedPolicy({
    required this.lastUpdated,
    required this.preamble,
    required this.sections,
    required this.grievanceOfficer,
    required this.grievanceEmail,
  });
}

class _SectionData {
  final String title;
  final IconData icon;
  final Color iconColor;
  final String? leadText;
  final List<_ItemData> items;
  final String? calloutText;

  _SectionData({
    required this.title,
    required this.icon,
    required this.iconColor,
    this.leadText,
    required this.items,
    this.calloutText,
  });
}

class _ItemData {
  final String prefix;
  final String body;

  _ItemData({required this.prefix, required this.body});
}

_ParsedPolicy _parsePolicy(String raw, String fallbackEmail) {
  final lines = raw
      .split('\n')
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty)
      .toList();

  String lastUpdated = '';
  final List<String> preamble = [];
  final List<_SectionData> sections = [];
  String grievanceOfficer = 'Harsha';
  String grievanceEmail = fallbackEmail;

  // Known section titles
  final knownSectionTitles = <String, (IconData, Color)>{
    'Two kinds of data': (Icons.pie_chart_outline_rounded, const Color(0xFF0D6EFD)),
    'What we collect about you': (Icons.person_pin_circle_outlined, const Color(0xFF0284C7)),
    'What PusherHub stores about your app users': (Icons.devices_other_rounded, const Color(0xFF8B5CF6)),
    'How we use data': (Icons.bolt_rounded, const Color(0xFF10B981)),
    'Cookies': (Icons.cookie_outlined, const Color(0xFFF59E0B)),
    'Who we share data with': (Icons.share_outlined, const Color(0xFFEC4899)),
    'How long we keep data': (Icons.hourglass_bottom_rounded, const Color(0xFF6366F1)),
    'How we protect data': (Icons.lock_outline_rounded, const Color(0xFF06B6D4)),
    'Your rights': (Icons.gavel_rounded, const Color(0xFF10B981)),
    'Children': (Icons.child_care_rounded, const Color(0xFFEF4444)),
    'Changes to this policy': (Icons.history_toggle_off_rounded, const Color(0xFF64748B)),
    'Contact and Grievance Officer': (Icons.contact_mail_rounded, const Color(0xFF0D6EFD)),
  };

  int idx = 0;
  while (idx < lines.length) {
    final line = lines[idx];

    if (line.toLowerCase().startsWith('privacy policy')) {
      idx++;
      continue;
    }

    if (line.toLowerCase().startsWith('last updated')) {
      lastUpdated = line;
      idx++;
      continue;
    }

    // Check if this line is a section heading
    String? matchedTitle;
    IconData matchedIcon = Icons.shield_outlined;
    Color matchedColor = const Color(0xFF0D6EFD);

    for (final entry in knownSectionTitles.entries) {
      if (line.toLowerCase() == entry.key.toLowerCase()) {
        matchedTitle = entry.key;
        matchedIcon = entry.value.$1;
        matchedColor = entry.value.$2;
        break;
      }
    }

    if (matchedTitle != null) {
      // Collect items for this section until next section or EOF
      idx++;
      String? leadText;
      final List<_ItemData> items = [];
      String? calloutText;

      while (idx < lines.length) {
        final currentLine = lines[idx];

        // Is next line a section header?
        bool isNextHeader = false;
        for (final entry in knownSectionTitles.keys) {
          if (currentLine.toLowerCase() == entry.toLowerCase()) {
            isNextHeader = true;
            break;
          }
        }
        if (isNextHeader) break;

        // Check for grievance officer details
        if (currentLine.toLowerCase().startsWith('grievance officer:')) {
          grievanceOfficer = currentLine.split(':').last.trim();
          idx++;
          continue;
        }
        if (currentLine.toLowerCase().startsWith('email:')) {
          final extracted = currentLine.split(':').last.trim();
          if (extracted.contains('@')) {
            grievanceEmail = extracted;
          }
          idx++;
          continue;
        }

        // Check for callout line
        if (currentLine.toLowerCase().contains("we don't sell personal data")) {
          calloutText = currentLine;
          idx++;
          continue;
        }

        // Check for "lead text" (e.g. "When your app registers...", "Under India's Digital Personal...")
        if (currentLine.endsWith(':') && items.isEmpty && leadText == null) {
          leadText = currentLine;
          idx++;
          continue;
        }

        // Parse key-value item with em-dash or en-dash or hyphen
        if (currentLine.contains(' — ')) {
          final parts = currentLine.split(' — ');
          items.add(_ItemData(prefix: parts[0].trim(), body: parts.sublist(1).join(' — ').trim()));
        } else if (currentLine.contains(' - ') && !currentLine.startsWith('- ')) {
          final parts = currentLine.split(' - ');
          items.add(_ItemData(prefix: parts[0].trim(), body: parts.sublist(1).join(' - ').trim()));
        } else {
          // Regular item or paragraph
          String body = currentLine;
          if (body.startsWith('• ') || body.startsWith('- ')) {
            body = body.substring(2).trim();
          }
          items.add(_ItemData(prefix: '', body: body));
        }

        idx++;
      }

      if (matchedTitle != 'Contact and Grievance Officer') {
        sections.add(
          _SectionData(
            title: matchedTitle,
            icon: matchedIcon,
            iconColor: matchedColor,
            leadText: leadText,
            items: items,
            calloutText: calloutText,
          ),
        );
      }
    } else {
      // Part of preamble (filter third-party provider bullet lines so they are cleanly rendered in the dedicated card)
      final lower = line.toLowerCase();
      if (!lower.startsWith('the app does use third-party') &&
          !lower.startsWith('link to the privacy policy of third-party') &&
          !lower.startsWith('• google play') &&
          !lower.startsWith('• admob') &&
          !lower.startsWith('• google analytics') &&
          !lower.startsWith('• firebase') &&
          !lower.startsWith('• facebook') &&
          !lower.startsWith('• pusherhub') &&
          !lower.startsWith('• one signal')) {
        preamble.add(line);
      }
      idx++;
    }
  }

  return _ParsedPolicy(
    lastUpdated: lastUpdated,
    preamble: preamble,
    sections: sections,
    grievanceOfficer: grievanceOfficer,
    grievanceEmail: grievanceEmail,
  );
}
