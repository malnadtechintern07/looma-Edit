import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:procut/core/services/app_remote_config_service.dart';
import 'package:procut/core/storage/local_storage_service.dart';
import 'package:procut/core/storage/storage_providers.dart';
import 'package:procut/features/asset_store/presentation/screens/template_feed_screen.dart';
import 'package:procut/features/profile/presentation/screens/profile_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Template Asset Resolver Tests', () {
    test('Maps server media URLs to bundled demo assets properly', () {
      expect(
        TemplateFeedScreen.resolveDemoAsset('/media/templates/alps_sunrise.mp4'),
        'assets/demo/alps_sunrise.mp4',
      );
      expect(
        TemplateFeedScreen.resolveDemoAsset('http://192.168.31.251:5050/media/templates/tokyo_shinjuku.mp4'),
        'assets/demo/tokyo_shinjuku.mp4',
      );
      expect(
        TemplateFeedScreen.resolveDemoAsset('http://10.0.2.2:5050/media/templates/tropical_beat.wav'),
        'assets/demo/tropical_beat.wav',
      );
      expect(
        TemplateFeedScreen.resolveDemoAsset('/media/templates/tmpl-golden-hour.jpg'),
        'assets/demo/tmpl-golden-hour.jpg',
      );
      expect(
        TemplateFeedScreen.resolveDemoAsset('custom_unknown_file.mp4'),
        isNull,
      );
    });
  });

  group('Screen Layout & Overflow Regression Tests', () {
    const screenSizes = [
      Size(320, 568), // iPhone SE 1st gen / small Android
      Size(360, 640), // Standard Android phone (user device size)
      Size(390, 844), // iPhone 14
      Size(428, 926), // Large phone
    ];

    for (final size in screenSizes) {
      testWidgets('TemplateFeedScreen Top Bar does not overflow on ${size.width}x${size.height}', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final storageService = LocalStorageService();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              localStorageServiceProvider.overrideWithValue(storageService),
            ],
            child: const MaterialApp(
              home: TemplateFeedScreen(),
            ),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Must not trigger any RenderFlex overflow exception
        expect(tester.takeException(), isNull);
        expect(find.text('Templates'), findsOneWidget);
        expect(find.text('25 Categories'), findsOneWidget);
      });

      testWidgets('SettingsScreen Live Admin Panel watermark row does not overflow on ${size.width}x${size.height}', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final storageService = LocalStorageService();

        const mockRemoteConfig = AppRemoteConfig(
          appName: 'ProCut',
          watermark: RemoteWatermarkConfig(
            enabledFree: true,
            text: 'PROCUT PRO FILMMAKER',
            opacity: 0.8,
            position: 'bottomRight',
          ),
          banners: [
            RemoteBannerModel(
              id: 1,
              title: 'Summer Sale',
              subtitle: '50% Off',
              badgeText: 'SALE',
              buttonText: 'Claim',
              actionRoute: '/sale',
              gradientStart: '#FF0000',
              gradientEnd: '#00FF00',
              placement: 'home_top',
            ),
            RemoteBannerModel(
              id: 2,
              title: 'New Features',
              subtitle: 'Check them out',
              badgeText: 'NEW',
              buttonText: 'Explore',
              actionRoute: '/features',
              gradientStart: '#0000FF',
              gradientEnd: '#FFFF00',
              placement: 'home_top',
            ),
          ],
          features: [
            RemoteFeatureModel(featureKey: 'f1', name: 'Feature 1', iconName: 'cut', displayOrder: 1, isEnabled: true, isPro: false),
            RemoteFeatureModel(featureKey: 'f2', name: 'Feature 2', iconName: 'cut', displayOrder: 2, isEnabled: true, isPro: false),
            RemoteFeatureModel(featureKey: 'f3', name: 'Feature 3', iconName: 'cut', displayOrder: 3, isEnabled: true, isPro: false),
            RemoteFeatureModel(featureKey: 'f4', name: 'Feature 4', iconName: 'cut', displayOrder: 4, isEnabled: true, isPro: false),
            RemoteFeatureModel(featureKey: 'f5', name: 'Feature 5', iconName: 'cut', displayOrder: 5, isEnabled: true, isPro: false),
            RemoteFeatureModel(featureKey: 'f6', name: 'Feature 6', iconName: 'cut', displayOrder: 6, isEnabled: true, isPro: false),
            RemoteFeatureModel(featureKey: 'f7', name: 'Feature 7', iconName: 'cut', displayOrder: 7, isEnabled: true, isPro: false),
            RemoteFeatureModel(featureKey: 'f8', name: 'Feature 8', iconName: 'cut', displayOrder: 8, isEnabled: true, isPro: false),
            RemoteFeatureModel(featureKey: 'f9', name: 'Feature 9', iconName: 'cut', displayOrder: 9, isEnabled: true, isPro: false),
            RemoteFeatureModel(featureKey: 'f10', name: 'Feature 10', iconName: 'cut', displayOrder: 10, isEnabled: true, isPro: false),
            RemoteFeatureModel(featureKey: 'f11', name: 'Feature 11', iconName: 'cut', displayOrder: 11, isEnabled: true, isPro: false),
          ],
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              localStorageServiceProvider.overrideWithValue(storageService),
              appRemoteConfigProvider.overrideWith((ref) async => mockRemoteConfig),
            ],
            child: const MaterialApp(
              home: SettingsScreen(),
            ),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Must not trigger any RenderFlex overflow exception
        expect(tester.takeException(), isNull);
        expect(find.text('Settings'), findsOneWidget);
      });
    }
  });
}
