import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:procut/features/profile/presentation/screens/contact_support_screen.dart';
import 'package:procut/features/profile/presentation/screens/help_center_screen.dart';
import 'package:procut/features/profile/presentation/screens/privacy_policy_screen.dart';
import 'package:procut/features/profile/presentation/screens/profile_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ProfileMeScreen - Privacy Policy, Help Center, and Contact Support Integration', () {
    testWidgets('ProfileMeScreen renders Help Center, Contact Us, and Privacy Policy tiles', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ProfileMeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Community & Support header and new tiles
      expect(find.text('Community & Support'), findsOneWidget);

      final helpCenterTile = find.byKey(const Key('me_help_center_tile'));
      expect(helpCenterTile, findsOneWidget);
      expect(find.text('Help Center & User Guides'), findsOneWidget);

      final contactSupportTile = find.byKey(const Key('me_contact_support_tile'));
      expect(contactSupportTile, findsOneWidget);
      expect(find.text('Contact Us & Support'), findsOneWidget);

      // Verify Legal & Privacy header and Privacy Policy tile
      expect(find.text('Legal & Privacy'), findsOneWidget);
      final privacyTile = find.byKey(const Key('me_privacy_policy_tile'));
      expect(privacyTile, findsOneWidget);
      expect(find.text('Privacy Policy'), findsOneWidget);
    });
  });

  group('PrivacyPolicyScreen Widget Tests', () {
    testWidgets('renders all privacy sections, offline-first badges, and copy email button', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PrivacyPolicyScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Title & Hero header
      expect(find.text('Privacy Policy'), findsOneWidget);
      expect(find.text('ProCut Privacy Commitment'), findsOneWidget);
      expect(find.text('100% Offline Engine'), findsOneWidget);
      expect(find.text('Zero Ad Tracking'), findsOneWidget);
      expect(find.text('End-to-End Encrypted Cloud'), findsOneWidget);

      // Key sections
      expect(find.text('1. Offline-First Processing & Media Storage'), findsOneWidget);
      expect(find.text('2. Device Permissions & Purpose'), findsOneWidget);
      expect(find.text('3. Optional Cloud Sync & Account Data'), findsOneWidget);
      expect(find.text('4. Cache & Temporary Video Fragments'), findsOneWidget);
      expect(find.text('5. Zero Advertising & Third-Party Selling'), findsOneWidget);
      expect(find.text('6. User Rights & Complete Data Deletion'), findsOneWidget);
      expect(find.text('7. Contact Data Privacy Officer'), findsOneWidget);

      // Copy email action
      final copyTile = find.byKey(const Key('privacy_copy_email_tile'));
      expect(copyTile, findsOneWidget);
      await tester.ensureVisible(copyTile);
      await tester.pumpAndSettle();
      await tester.tap(copyTile);
      await tester.pump();
      expect(find.textContaining('Privacy contact email copied to clipboard'), findsOneWidget);
    });
  });

  group('HelpCenterScreen Widget Tests', () {
    testWidgets('renders search field, category chips, guide cards, and FAQs', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HelpCenterScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Help & User Guides'), findsOneWidget);
      expect(find.byKey(const Key('help_center_search_field')), findsOneWidget);

      // Category chips
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Timeline & Editing'), findsOneWidget);
      expect(find.text('Filters & FX'), findsOneWidget);

      // Guides
      expect(find.text('Mastering the Multi-Track Timeline'), findsOneWidget);
      expect(find.text('Applying 70+ Cinematic Filters & LUTs'), findsOneWidget);

      // FAQs
      expect(find.text('Frequently Asked Questions'), findsOneWidget);
      expect(find.text('Does ProCut put a watermark on my videos?'), findsOneWidget);
    });

    testWidgets('Tapping a guide card opens the interactive GuideReaderSheet', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HelpCenterScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final timelineGuideCard = find.byKey(const Key('guide_card_timeline_editing'));
      expect(timelineGuideCard, findsOneWidget);

      await tester.tap(timelineGuideCard);
      await tester.pumpAndSettle();

      // Bottom sheet open
      expect(find.text('Step-by-Step Instructions'), findsOneWidget);
      expect(find.text('Pro Creator Tip'), findsOneWidget);
      expect(find.textContaining('Drag the red vertical playhead'), findsOneWidget);

      // Close sheet
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      expect(find.text('Step-by-Step Instructions'), findsNothing);
    });

    testWidgets('Search query filters guide articles and FAQs in real-time', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HelpCenterScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Enter search query "watermark"
      await tester.enterText(find.byKey(const Key('help_center_search_field')), 'watermark');
      await tester.pumpAndSettle();

      // FAQ should be visible
      expect(find.text('Does ProCut put a watermark on my videos?'), findsOneWidget);

      // Guides without "watermark" should be filtered out
      expect(find.text('No guides found matching query'), findsOneWidget);

      // Clear search
      await tester.enterText(find.byKey(const Key('help_center_search_field')), '');
      await tester.pumpAndSettle();

      expect(find.text('Mastering the Multi-Track Timeline'), findsOneWidget);
    });

    testWidgets('Expanding an FAQ tile shows its detailed answer', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HelpCenterScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final faqTile = find.byKey(const Key('faq_tile_0'));
      expect(faqTile, findsOneWidget);
      await tester.ensureVisible(faqTile);
      await tester.pumpAndSettle();

      await tester.tap(faqTile);
      await tester.pumpAndSettle();

      expect(
        find.textContaining('ProCut allows you to export clean, watermark-free videos'),
        findsOneWidget,
      );
    });
  });

  group('ContactSupportScreen Widget Tests', () {
    testWidgets('renders direct email card, ticket form, diagnostics card, and community links', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ContactSupportScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Contact Us & Support'), findsOneWidget);
      expect(find.text('Official Creator Support'), findsOneWidget);
      expect(find.text('support@procut.app'), findsOneWidget);

      // Support ticket form elements
      expect(find.text('Submit a Support Ticket'), findsOneWidget);
      expect(find.byKey(const Key('support_category_dropdown')), findsOneWidget);
      expect(find.byKey(const Key('support_email_field')), findsOneWidget);
      expect(find.byKey(const Key('support_subject_field')), findsOneWidget);
      expect(find.byKey(const Key('support_message_field')), findsOneWidget);
      expect(find.byKey(const Key('support_submit_ticket_btn')), findsOneWidget);

      // Diagnostics & Community
      expect(find.text('System Diagnostics'), findsOneWidget);
      expect(find.byKey(const Key('support_copy_diagnostics_btn')), findsOneWidget);
      expect(find.text('Discord Creator Community'), findsOneWidget);
      expect(find.text('Instagram @procut.app'), findsOneWidget);
      expect(find.text('YouTube @ProCutVideoEditor'), findsOneWidget);
    });

    testWidgets('Validates form and shows confirmation dialog on valid ticket submission', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ContactSupportScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final submitBtn = find.byKey(const Key('support_submit_ticket_btn'));
      await tester.ensureVisible(submitBtn);
      await tester.pumpAndSettle();

      // Submit empty form -> triggers validators
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      expect(find.text('Please enter your email'), findsOneWidget);
      expect(find.text('Please enter a subject'), findsOneWidget);
      expect(find.text('Please provide at least 10 characters of detail'), findsOneWidget);

      // Fill in valid details
      await tester.enterText(find.byKey(const Key('support_email_field')), 'creator@procut.app');
      await tester.enterText(find.byKey(const Key('support_subject_field')), 'Timeline playback issue on 4K clip');
      await tester.enterText(
        find.byKey(const Key('support_message_field')),
        'The video playback stutters when adding 4 simultaneous video tracks with chroma key enabled.',
      );
      await tester.pumpAndSettle();

      // Submit again
      await tester.tap(submitBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pumpAndSettle();

      // Confirmation dialog appears
      expect(find.text('Ticket Submitted!'), findsOneWidget);
      expect(find.textContaining('Reference: #LMA-'), findsOneWidget);

      // Tap Done
      await tester.tap(find.byKey(const Key('support_ticket_success_done_btn')));
      await tester.pumpAndSettle();

      expect(find.text('Ticket Submitted!'), findsNothing);
    });

    testWidgets('Copy diagnostics button copies text to clipboard', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ContactSupportScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final copyDiagBtn = find.byKey(const Key('support_copy_diagnostics_btn'));
      await tester.ensureVisible(copyDiagBtn);
      await tester.pumpAndSettle();

      await tester.tap(copyDiagBtn);
      await tester.pump();

      expect(find.textContaining('Diagnostics copied!'), findsOneWidget);
    });
  });
}
