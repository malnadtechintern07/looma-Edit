import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:procut/core/network/api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    HttpOverrides.global = null;
    SharedPreferences.setMockInitialValues({});
  });

  group('ApiClient InfinityFree Live Connectivity Tests', () {
    test('ApiClient successfully queries live server health on procut.free.nf', () async {
      final res = await ApiClient.get(
        Uri.parse('http://procut.free.nf/api/health'),
        timeout: const Duration(seconds: 10),
      );

      expect(res.isOk, isTrue, reason: 'Expected HTTP 200 OK but got ${res.statusCode}: ${res.body}');
      final json = res.json as Map<String, dynamic>?;
      expect(json, isNotNull);
      expect(json!['success'], isTrue);
      expect(json['service'], 'ProCut Backend Server');
      expect(json['database'], contains('MySQL'));
    });

    test('ApiClient successfully queries live templates from procut.free.nf', () async {
      final res = await ApiClient.get(
        Uri.parse('http://procut.free.nf/api/templates'),
        timeout: const Duration(seconds: 10),
      );

      expect(res.isOk, isTrue);
      final json = res.json as Map<String, dynamic>?;
      expect(json, isNotNull);
      expect(json!['success'], isTrue);
      final templates = json['templates'] as List<dynamic>?;
      expect(templates, isNotNull);
      expect(templates!.length, greaterThanOrEqualTo(30));
    });

    test('ApiClient successfully queries app config from procut.free.nf', () async {
      final res = await ApiClient.get(
        Uri.parse('http://procut.free.nf/api/app/config'),
        timeout: const Duration(seconds: 10),
      );

      expect(res.isOk, isTrue);
      final json = res.json as Map<String, dynamic>?;
      expect(json, isNotNull);
      expect(json!['success'], isTrue);
      expect(json['appName'], 'ProCut');
    });

    test('ApiClient successfully queries AI photo and video presets from procut.free.nf', () async {
      final photoRes = await ApiClient.get(
        Uri.parse('http://procut.free.nf/api/ai/presets?type=photo'),
        timeout: const Duration(seconds: 10),
      );
      expect(photoRes.isOk, isTrue);
      final photoJson = photoRes.json as Map<String, dynamic>?;
      expect(photoJson?['success'], isTrue);
      expect((photoJson?['presets'] as List).length, greaterThan(0));

      final videoRes = await ApiClient.get(
        Uri.parse('http://procut.free.nf/api/ai/presets?type=video'),
        timeout: const Duration(seconds: 10),
      );
      expect(videoRes.isOk, isTrue);
      final videoJson = videoRes.json as Map<String, dynamic>?;
      expect(videoJson?['success'], isTrue);
      expect((videoJson?['presets'] as List).length, greaterThan(0));
    });
  });
}
