import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:looma/core/storage/local_storage_service.dart';
import 'package:looma/features/media_picker/domain/entities/media_item_entity.dart';
import 'package:looma/features/media_picker/domain/services/recent_media_service.dart';
import 'package:looma/features/media_picker/presentation/widgets/media_picker_modal.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalStorageService().init();
    await RecentMediaService().clearRecentMedia();
  });

  group('RecentMediaService Tests', () {
    test('addRecentMedia stores items sorted by newest first', () async {
      final service = RecentMediaService();
      await service.clearRecentMedia();

      final itemOld = MediaItemEntity(
        path: 'assets/branding/demo_vid1.mp4',
        name: 'Old Video',
        type: MediaType.video,
        durationMs: 10000,
        addedAt: DateTime(2026, 1, 1),
      );

      final itemNew = MediaItemEntity(
        path: 'assets/branding/demo_vid2.mp4',
        name: 'New Video',
        type: MediaType.video,
        durationMs: 20000,
        addedAt: DateTime(2026, 9, 1),
      );

      await service.addRecentMedia([itemOld, itemNew]);

      final recents = await service.getRecentMedia(autoScan: false);
      expect(recents.length, 2);
      expect(recents.first.name, 'New Video');
      expect(recents.last.name, 'Old Video');
    });

    test('getRecentMedia filters by MediaType accurately', () async {
      final service = RecentMediaService();
      await service.clearRecentMedia();

      await service.addRecentMedia([
        const MediaItemEntity(
          path: 'assets/branding/demo_vid1.mp4',
          name: 'Video Clip',
          type: MediaType.video,
        ),
        const MediaItemEntity(
          path: 'assets/branding/demo_photo1.jpg',
          name: 'Photo Snap',
          type: MediaType.photo,
        ),
      ]);

      final videos = await service.getRecentMedia(type: MediaType.video, autoScan: false);
      final photos = await service.getRecentMedia(type: MediaType.photo, autoScan: false);

      expect(videos.length, 1);
      expect(videos.first.name, 'Video Clip');
      expect(photos.length, 1);
      expect(photos.first.name, 'Photo Snap');
    });

    test('addRecentMedia deduplicates by path and brings latest to top', () async {
      final service = RecentMediaService();
      await service.clearRecentMedia();

      const item1 = MediaItemEntity(
        path: 'assets/branding/demo_vid1.mp4',
        name: 'Clip 1',
        type: MediaType.video,
      );
      const item2 = MediaItemEntity(
        path: 'assets/branding/demo_vid2.mp4',
        name: 'Clip 2',
        type: MediaType.video,
      );

      await service.addRecentMedia([item1, item2]);
      // Re-add item1 with updated name
      final item1Updated = MediaItemEntity(
        path: 'assets/branding/demo_vid1.mp4',
        name: 'Clip 1 Updated',
        type: MediaType.video,
        addedAt: DateTime.now(),
      );
      await service.addRecentMediaSingle(item1Updated);

      final recents = await service.getRecentMedia(autoScan: false);
      expect(recents.length, 2);
      expect(recents.first.name, 'Clip 1 Updated');
    });
  });

  group('MediaPickerModal UI & Gallery Selection Tests', () {
    testWidgets('Renders Tile 0 "+ Open Gallery" in the media grid', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MediaPickerModal(
              onMediaSelected: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Tile 0 "+ Open Gallery" exists in the grid
      final openGalleryTile = find.byKey(const Key('picker_open_gallery_tile'));
      expect(openGalleryTile, findsOneWidget);
      expect(find.descendant(of: openGalleryTile, matching: find.text('Open Gallery')), findsOneWidget);
      expect(find.descendant(of: openGalleryTile, matching: find.text('Device Videos')), findsOneWidget);
    });

    testWidgets('Renders prominent "Open Gallery" button in header sub-tabs row', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MediaPickerModal(
              onMediaSelected: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final headerButton = find.byKey(const Key('picker_header_open_gallery_button'));
      expect(headerButton, findsOneWidget);
      expect(find.descendant(of: headerButton, matching: find.text('Open Gallery')), findsOneWidget);
    });

    testWidgets('Switching to Photos tab updates Tile 0 subtitle to "Device Photos"', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MediaPickerModal(
              onMediaSelected: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Switch to Photos
      final photosTab = find.text('Photos');
      expect(photosTab, findsOneWidget);
      await tester.tap(photosTab);
      await tester.pumpAndSettle();

      final openGalleryTile = find.byKey(const Key('picker_open_gallery_tile'));
      expect(find.descendant(of: openGalleryTile, matching: find.text('Device Photos')), findsOneWidget);
    });

    testWidgets('Media selection updates counter and Add button invokes callback', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      List<MediaItemEntity> selectedResult = [];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MediaPickerModal(
              actionLabel: 'Add',
              onMediaSelected: (items) {
                selectedResult = items;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find first selectable media tile in grid (item 1, right after open gallery tile)
      final firstTile = find.byKey(const ValueKey('media_tile_assets/branding/demo_vid1.mp4'));
      expect(firstTile, findsOneWidget);

      // Tap on the first media item to select it
      await tester.tap(firstTile);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Add button should now show "Add (1)"
      expect(find.text('Add (1)'), findsOneWidget);

      // Tap Add (1)
      await tester.tap(find.text('Add (1)'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(selectedResult.length, 1);
    });


    testWidgets('Album selector contains "Device Gallery (Open Directly)"', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MediaPickerModal(
              onMediaSelected: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Recent dropdown pill
      final albumPill = find.text('Recent');
      expect(albumPill, findsOneWidget);
      await tester.tap(albumPill);
      await tester.pumpAndSettle();

      // Verify "Device Gallery (Open Directly)" is present in the album modal
      expect(find.text('Device Gallery (Open Directly)'), findsOneWidget);
    });
  });
}
