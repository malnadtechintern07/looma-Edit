import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:procut/core/config/server_config.dart';
import 'package:procut/core/services/app_remote_config_service.dart';
import 'package:procut/features/asset_store/data/datasources/asset_store_datasource.dart';
import 'package:procut/features/ai_photo_edit/data/ai_photo_presets_data.dart';
import 'package:procut/features/ai_video_edit/data/ai_video_presets_data.dart';
import 'package:procut/features/auth/data/datasources/mysql_auth_remote_datasource.dart';
import 'package:procut/core/storage/local_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    HttpOverrides.global = null;
    SharedPreferences.setMockInitialValues({});
  });

  group('Live Admin Panel & Mobile App Synchronization End-to-End Tests', () {
    test('ServerConfig defaults to live host http://procut.free.nf and is healthy', () async {
      final baseUrl = await ServerConfig.getBaseUrl(forceRefresh: true);
      expect(baseUrl, equals('http://procut.free.nf'));

      final health = await ServerConfig.checkHealthDetails();
      expect(health, isNotNull);
      expect(health!['status'], equals('ok'));
      expect(health['databaseConnected'], isTrue);
      expect(health['users'] ?? health['counts']?['users'], isNotNull);
    });

    test('AppRemoteConfigService fetches live remote config & content from procut.free.nf', () async {
      final service = AppRemoteConfigService();
      final config = await service.fetchConfig();

      expect(config, isNotNull);
      expect(config.appName, isNotEmpty);
    });

    test('AssetStoreDataSource loads templates directly from live procut.free.nf', () async {
      final ds = AssetStoreDataSourceImpl();
      final templates = await ds.getTemplates();

      expect(templates, isNotEmpty);
      expect(templates.length, greaterThanOrEqualTo(20));
      // Verify URLs are resolved with base URL
      final hasServerUrl = templates.any((t) => t.previewImageUrl?.startsWith('http') == true);
      expect(hasServerUrl, isTrue);
    });

    test('AI Photo & Video Presets fetch dynamically from live procut.free.nf', () async {
      final photoPresets = await AiPhotoPresetsData.fetchServerPresets();
      expect(photoPresets, isNotEmpty);

      final videoPresets = await AiVideoPresetsData.fetchServerPresets();
      expect(videoPresets, isNotEmpty);
    });

    test('MySqlAuthRemoteDataSource queries live MySQL auth without bot challenge error', () async {
      final storage = LocalStorageService();
      final authDs = MySqlAuthRemoteDataSource(localStorageService: storage);

      final exists = await authDs.checkEmailExists('admin@procut.app');
      expect(exists, isA<bool>());
    });
  });
}
