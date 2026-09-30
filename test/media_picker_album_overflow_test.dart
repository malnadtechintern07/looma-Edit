import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:procut/core/storage/local_storage_service.dart';
import 'package:procut/features/media_picker/presentation/widgets/media_picker_modal.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalStorageService().init();
  });

  for (final size in [
    const Size(320, 568),
    const Size(360, 640),
    const Size(390, 844),
    const Size(428, 926),
  ]) {
    testWidgets('Select Album bottom sheet in MediaPickerModal does not overflow on ${size.width}x${size.height}',
        (WidgetTester tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

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

      // Verify no overflow during initial MediaPickerModal render
      expect(tester.takeException(), isNull);

      // Tap on the Albums Dropdown button
      final albumDropdown = find.byKey(const Key('picker_album_selector_button'));
      expect(albumDropdown, findsOneWidget);
      await tester.tap(albumDropdown);
      await tester.pumpAndSettle();

      // Verify "Select Album" header and album options appear
      expect(find.text('Select Album'), findsOneWidget);
      expect(find.widgetWithText(ListTile, 'Device Gallery (Open Directly)'), findsOneWidget);
      expect(find.widgetWithText(ListTile, 'All Media'), findsOneWidget);

      // Verify no overflow exception was thrown when opening the album bottom sheet
      expect(tester.takeException(), isNull);
    });
  }
}
