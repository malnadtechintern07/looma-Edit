import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Admin Panel Favicon & App Logo Tests', () {
    const serverBases = [
      'server',
      'procut_backend_infinityfree',
    ];

    test('Favicon and Touch Icon files exist in server and infinityfree roots', () {
      for (final base in serverBases) {
        final icoFile = File('$base/favicon.ico');
        expect(icoFile.existsSync(), isTrue, reason: '$base/favicon.ico must exist');
        expect(icoFile.lengthSync(), greaterThan(1000), reason: 'Favicon should be valid ICO');

        final png16 = File('$base/favicon-16x16.png');
        expect(png16.existsSync(), isTrue, reason: '$base/favicon-16x16.png must exist');

        final png32 = File('$base/favicon-32x32.png');
        expect(png32.existsSync(), isTrue, reason: '$base/favicon-32x32.png must exist');

        final appleTouch = File('$base/apple-touch-icon.png');
        expect(appleTouch.existsSync(), isTrue, reason: '$base/apple-touch-icon.png must exist');

        final manifest = File('$base/site.webmanifest');
        expect(manifest.existsSync(), isTrue, reason: '$base/site.webmanifest must exist');
      }
    });

    test('Favicon files exist in admin subdirectories', () {
      for (final base in serverBases) {
        final adminIco = File('$base/admin/favicon.ico');
        expect(adminIco.existsSync(), isTrue, reason: '$base/admin/favicon.ico must exist');

        final adminPng32 = File('$base/admin/favicon-32x32.png');
        expect(adminPng32.existsSync(), isTrue, reason: '$base/admin/favicon-32x32.png must exist');

        final adminAppIcon = File('$base/admin/assets/icon/app_icon.png');
        expect(adminAppIcon.existsSync(), isTrue, reason: '$base/admin/assets/icon/app_icon.png must exist');
      }
    });

    test('admin/includes/header.php contains favicon and touch icon links', () {
      for (final base in serverBases) {
        final headerFile = File('$base/admin/includes/header.php');
        expect(headerFile.existsSync(), isTrue);
        final content = headerFile.readAsStringSync();

        expect(content, contains('rel="icon"'));
        expect(content, contains('favicon.ico'));
        expect(content, contains('favicon-32x32.png'));
        expect(content, contains('apple-touch-icon.png'));
        expect(content, contains('site.webmanifest'));
      }
    });

    test('admin/login.php contains favicon links and app logo image', () {
      for (final base in serverBases) {
        final loginFile = File('$base/admin/login.php');
        expect(loginFile.existsSync(), isTrue);
        final content = loginFile.readAsStringSync();

        expect(content, contains('rel="icon"'));
        expect(content, contains('favicon.ico'));
        expect(content, contains('favicon-32x32.png'));
        expect(content, contains('apple-touch-icon.png'));
        expect(content, contains('alt="ProCut Logo"'));
      }
    });

    test('admin/forgot-password.php contains favicon links and app logo image', () {
      for (final base in serverBases) {
        final fpFile = File('$base/admin/forgot-password.php');
        expect(fpFile.existsSync(), isTrue);
        final content = fpFile.readAsStringSync();

        expect(content, contains('rel="icon"'));
        expect(content, contains('favicon.ico'));
        expect(content, contains('favicon-32x32.png'));
        expect(content, contains('apple-touch-icon.png'));
        expect(content, contains('alt="ProCut Logo"'));
      }
    });

    test('admin/includes/sidebar.php displays app logo image in brand header', () {
      for (final base in serverBases) {
        final sidebarFile = File('$base/admin/includes/sidebar.php');
        expect(sidebarFile.existsSync(), isTrue);
        final content = sidebarFile.readAsStringSync();

        expect(content, contains('alt="ProCut Logo"'));
        expect(content, contains('favicon-32x32.png'));
      }
    });

    test('router.php defines webmanifest mime type for PWA/favicons', () {
      for (final base in serverBases) {
        final routerFile = File('$base/router.php');
        expect(routerFile.existsSync(), isTrue);
        final content = routerFile.readAsStringSync();

        expect(content, contains("'webmanifest' => 'application/manifest+json'"));
      }
    });
  });
}
