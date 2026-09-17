import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:procut/features/asset_store/data/datasources/asset_store_datasource.dart';

void main() {
  test('Live PHP Content API returns 8 rich working templates', () async {
    final client = HttpClient();
    final req = await client.getUrl(Uri.parse('http://localhost:5050/api/app/content'));
    final res = await req.close();
    expect(res.statusCode, equals(200));

    final body = await res.transform(utf8.decoder).join();
    final json = jsonDecode(body) as Map<String, dynamic>;
    expect(json.containsKey('templates'), isTrue);

    final templates = json['templates'] as List<dynamic>;
    expect(templates.length, greaterThanOrEqualTo(8));

    for (final tmpl in templates) {
      expect(tmpl['id'], isNotNull);
      expect(tmpl['title'], isNotEmpty);
      expect(tmpl['preview_video_url'], isNotEmpty);
      expect(tmpl['audio_url'], isNotEmpty);
      expect(tmpl['duration_ms'], greaterThan(0));
      expect(tmpl['clips_count'], greaterThan(0));
    }
    client.close();
  });

  test('AssetStoreDataSource loads templates with proper URL resolution', () async {
    final ds = AssetStoreDataSourceImpl();
    final templates = await ds.getTemplates();
    expect(templates.length, greaterThanOrEqualTo(8));

    for (final t in templates) {
      expect(t.id, isNotEmpty);
      expect(t.title, isNotEmpty);
      expect(t.previewVideoUrl, isNotNull);
      expect(t.audioPath, isNotEmpty);
    }
  });
}
