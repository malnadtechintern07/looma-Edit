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

  test('Check all presets on procut.free.nf', () async {
    final seedRes = await ApiClient.get(
      Uri.parse('http://procut.free.nf/database/seed_ai_presets.php'),
      timeout: const Duration(seconds: 25),
    );
    print('SEED_RESPONSE_STATUS: ${seedRes.statusCode}');
    print('SEED_RESPONSE_BODY: ${seedRes.body.length > 300 ? seedRes.body.substring(0, 300) : seedRes.body}');

    final res = await ApiClient.get(
      Uri.parse('http://procut.free.nf/api/ai/presets'),
      timeout: const Duration(seconds: 10),
    );
    final json = res.json as Map<String, dynamic>;
    final presets = json['presets'] as List<dynamic>;
    print('TOTAL_PRESETS_FROM_API: ${presets.length}');
    print('PHOTO_COUNT_FROM_API: ${json['photoCount']}');
    print('VIDEO_COUNT_FROM_API: ${json['videoCount']}');
    print('FIRST 3:');
    for (int i = 0; i < 3 && i < presets.length; i++) {
      print('  ${presets[i]['id']}: ${presets[i]['title']} (${presets[i]['created_at']})');
    }
    print('LAST 3:');
    for (int i = presets.length - 3; i >= 0 && i < presets.length; i++) {
      print('  ${presets[i]['id']}: ${presets[i]['title']} (${presets[i]['created_at']})');
    }
  });
}
