import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:procut/core/config/server_config.dart';
import 'package:procut/core/services/app_remote_config_service.dart';
import 'package:procut/features/ai_photo_edit/data/ai_photo_presets_data.dart';
import 'package:procut/features/ai_video_edit/data/ai_video_presets_data.dart';

void main() {
  group('Admin Panel & Backend Integration Tests', () {
    const String testServerUrl = 'http://127.0.0.1:5050';

    test('1. PHP + MariaDB Server Health Diagnostics are reachable and responsive', () async {
      final isAlive = await ServerConfig.isReachable(testServerUrl);
      expect(isAlive, isTrue, reason: 'PHP dev server should be running on port 5050');

      final health = await ServerConfig.checkHealthDetails();
      expect(health, isNotNull);
      expect(health!['status'], equals('ok'));
      expect(health['databaseConnected'], isTrue, reason: 'MariaDB procut_db must be connected');
      expect(health['latencyMs'], isA<int>());
    });

    test('2. Live Remote Config fetches dynamic banners, features, watermark, and support from Admin Panel', () async {
      final config = await AppRemoteConfigService().fetchConfig();
      expect(config, isNotNull);

      // Watermark validation
      expect(config.watermark.text, isNotEmpty);
      expect(config.watermark.opacity, greaterThanOrEqualTo(0.0));
      expect(config.watermark.opacity, lessThanOrEqualTo(1.0));
      expect(config.watermark.position, isNotEmpty);

      // Banners validation
      expect(config.banners, isNotEmpty);
      for (final banner in config.banners) {
        expect(banner.id, isA<int>());
        expect(banner.title, isNotEmpty);
        expect(banner.subtitle, isNotEmpty);
      }

      // Features validation with harmonized title/name and is_pro
      expect(config.features, isNotEmpty);
      for (final feature in config.features) {
        expect(feature.name, isNotEmpty);
        expect(feature.featureKey, isNotEmpty);
        expect(feature.iconName, isNotEmpty);
      }

      // Support contact info validation
      expect(config.support.email, isNotEmpty);
      expect(config.support.website, isNotEmpty);
      expect(config.support.hours, isNotEmpty);
    });

    test('3. AI Photo Presets are dynamically loaded from server with proper category extraction', () async {
      final presets = await AiPhotoPresetsData.fetchServerPresets();
      expect(presets, isNotEmpty);

      final categories = AiPhotoPresetsData.categories;
      expect(categories, isNotEmpty);
      expect(categories.contains('All'), isTrue);

      for (final p in presets) {
        expect(p.id, isNotEmpty);
        expect(p.title, isNotEmpty);
        expect(p.prompt, isNotEmpty);
        expect(p.referenceImagePath, isNotEmpty);
        expect(
          p.referenceImagePath.startsWith('http://') ||
              p.referenceImagePath.startsWith('https://') ||
              p.referenceImagePath.startsWith('assets/'),
          isTrue,
        );
      }
    });

    test('4. AI Video Presets are dynamically loaded from server with proper category extraction', () async {
      final presets = await AiVideoPresetsData.fetchServerPresets();
      expect(presets, isNotEmpty);

      final categories = AiVideoPresetsData.categories;
      expect(categories, isNotEmpty);
      expect(categories.contains('All'), isTrue);

      for (final p in presets) {
        expect(p.id, isNotEmpty);
        expect(p.title, isNotEmpty);
        expect(p.prompt, isNotEmpty);
        expect(p.videoAssetPath, isNotEmpty);
        expect(
          p.videoAssetPath.startsWith('http://') ||
              p.videoAssetPath.startsWith('https://') ||
              p.videoAssetPath.startsWith('assets/'),
          isTrue,
        );
      }
    });

    test('5. Support Ticket submission sends data to server and generates a valid ticket ID', () async {
      final uri = Uri.parse('$testServerUrl/api/app/support-ticket');
      final client = HttpClient()..connectionTimeout = const Duration(seconds: 5);
      final req = await client.postUrl(uri);
      req.headers.set('Content-Type', 'application/json');
      req.write(jsonEncode({
        'email': 'creator@example.com',
        'subject': 'Integration Test Ticket',
        'message': 'Testing real-time admin sync and activity logging',
        'category': 'Bug Report',
        'diagnostics': 'Test Engine v2.4.0',
      }));
      final res = await req.close();
      expect(res.statusCode, isIn([200, 201]));

      final body = await res.transform(const SystemEncoding().decoder).join();
      final json = jsonDecode(body) as Map<String, dynamic>;
      expect(json['success'], isTrue);
      expect(json['ticket_id'], isNotNull);
      final ticketId = json['ticket_id'] as String;
      expect(ticketId.startsWith('TKT-') || ticketId.startsWith('#LMA-'), isTrue);
      client.close();
    });

    test('6. RemoteBannerModel hex color parsing works for admin-configured gradient strings', () {
      const banner = RemoteBannerModel(
        id: 1,
        title: 'Promo',
        subtitle: 'Sub',
        badgeText: 'VIP',
        buttonText: 'Open',
        actionRoute: '/templates',
        gradientStart: '#FF5733',
        gradientEnd: '#33FF57',
        placement: 'home_top',
      );
      final startColor = banner.startColor;
      final endColor = banner.endColor;
      expect(startColor.toARGB32(), equals(0xFFFF5733));
      expect(endColor.toARGB32(), equals(0xFF33FF57));
    });
  });
}
