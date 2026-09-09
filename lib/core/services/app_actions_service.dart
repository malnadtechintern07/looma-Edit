import 'dart:io';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for native app actions: Google Play Store rating, in-app rating storage & native share sheet
class AppActionsService {
  static const MethodChannel _channel = MethodChannel('procut/app_actions');
  static const String procutPackageName = 'com.procut.app.procut';
  static const String loomaPackageName = procutPackageName;
  static const String playStoreWebUrl = 'https://play.google.com/store/apps/details?id=$procutPackageName';

  static const String prefUserRating = 'procut_user_rating';
  static const String prefHasRated = 'procut_has_rated';
  static const String prefHasShownFirstExportRating = 'procut_has_shown_first_export_rating';
  static const String prefRatedAt = 'procut_rated_at';

  /// Save user rating (1-5), mark as rated, and mark first-export rating as completed
  static Future<void> saveUserRating(int rating) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(prefUserRating, rating);
      await prefs.setBool(prefHasRated, true);
      await prefs.setString(prefRatedAt, DateTime.now().toIso8601String());
      await prefs.setBool(prefHasShownFirstExportRating, true);
    } catch (_) {}
  }

  /// Retrieve saved rating (or null if not rated yet)
  static Future<int?> getSavedRating() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(prefUserRating) ?? prefs.getInt('looma_user_rating');
    } catch (_) {
      return null;
    }
  }

  /// Check if the first-export rating popup has already been shown/submitted
  static Future<bool> hasShownFirstExportRating() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasShown = prefs.getBool(prefHasShownFirstExportRating) ?? prefs.getBool('looma_has_shown_first_export_rating') ?? false;
      final hasRated = prefs.getBool(prefHasRated) ?? prefs.getBool('looma_has_rated') ?? false;
      return hasShown || hasRated;
    } catch (_) {
      return false;
    }
  }

  /// Mark first-export rating popup as shown so it will never show again
  static Future<void> markFirstExportRatingShown() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(prefHasShownFirstExportRating, true);
    } catch (_) {}
  }

  /// Open ProCut's Google Play Store listing directly so the user can submit a rating/review
  static Future<bool> openPlayStore({String packageName = procutPackageName}) async {
    try {
      if (Platform.isAndroid) {
        final res = await _channel.invokeMethod<bool>('openPlayStore', {
          'packageName': packageName,
        });
        return res ?? true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Open phone's native share sheet to share ProCut via WhatsApp, Instagram, Messages, Gmail, etc.
  static Future<bool> shareApp({
    String? text,
    String? subject,
    String? chooserTitle,
  }) async {
    final shareText = text ??
        'Create cinematic videos, aesthetic reels & edits with ProCut Video Editor! 🎬✨ Download on Google Play: $playStoreWebUrl';
    try {
      if (Platform.isAndroid) {
        final res = await _channel.invokeMethod<bool>('shareApp', {
          'text': shareText,
          'subject': subject ?? 'ProCut Video Editor',
          'title': chooserTitle ?? 'Share ProCut via',
        });
        return res ?? true;
      } else {
        // Fallback for non-Android platforms (e.g. desktop/unit tests)
        await Clipboard.setData(ClipboardData(text: shareText));
        return true;
      }
    } catch (_) {
      try {
        await Clipboard.setData(ClipboardData(text: shareText));
      } catch (_) {}
      return false;
    }
  }

  /// Share an exported image file using native share sheet or copy path to clipboard
  static Future<bool> shareImageFile(String filePath, {String? text}) async {
    final msg = text ?? 'Check out this photo I edited with ProCut Photo Editor! ✨📸 $playStoreWebUrl';
    try {
      if (Platform.isAndroid) {
        final res = await _channel.invokeMethod<bool>('shareApp', {
          'text': '$msg\n$filePath',
          'subject': 'ProCut Photo Creation',
          'title': 'Share Edited Photo via',
        });
        if (res == true) return true;
      }
    } catch (_) {}
    try {
      await Clipboard.setData(ClipboardData(text: filePath));
      return true;
    } catch (_) {
      return false;
    }
  }
}
