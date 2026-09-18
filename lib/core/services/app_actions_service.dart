import 'dart:io';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/server_config.dart';
import '../firebase/firebase_service.dart';

/// Service for native app actions: Google Play Store rating, in-app rating storage & native share sheet
class AppActionsService {
  static const MethodChannel _channel = MethodChannel('procut/app_actions');
  static const String procutPackageName = 'com.procut.app';
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

  /// Share prompt name and web link so anyone can view the prompt name, download ProCut app, and copy the full prompt.
  static Future<bool> shareAiPromptLink({
    required String title,
    required String presetId,
    String? category,
    String? prompt,
    String? referenceImageUrl,
  }) async {
    String baseUrl = ServerConfig.defaultUrl;
    try {
      baseUrl = await ServerConfig.getBaseUrl();
    } catch (_) {}

    final queryParams = <String, String>{
      'id': presetId,
      'title': title,
      if (category != null && category.isNotEmpty) 'cat': category,
      if (referenceImageUrl != null && referenceImageUrl.isNotEmpty) 'img': referenceImageUrl,
    };
    final uri = Uri.parse('$baseUrl/prompt.php').replace(queryParameters: queryParams);
    final link = uri.toString();

    // Track share in Firebase Analytics
    FirebaseService.analytics.logPromptShare(
      promptTitle: title,
      promptType: 'photo_link',
    );

    final text = '✨ Check out "$title" AI Photo Style on ProCut!\n\n'
        'View prompt & download ProCut app to copy in 8K:\n'
        '$link\n\n'
        '📲 Download ProCut: $playStoreWebUrl';

    try {
      if (Platform.isAndroid) {
        final res = await _channel.invokeMethod<bool>('shareApp', {
          'text': text,
          'subject': 'ProCut AI: $title',
          'title': 'Share Prompt Link via',
        });
        return res ?? true;
      } else {
        await Clipboard.setData(ClipboardData(text: text));
        return true;
      }
    } catch (_) {
      try {
        await Clipboard.setData(ClipboardData(text: text));
      } catch (_) {}
      return false;
    }
  }

  /// Open phone's native share sheet targeting ChatGPT, Gemini, and installed AI apps with the AI prompt
  static Future<bool> shareAiPrompt({
    required String prompt,
    String? title,
    String? category,
  }) async {
    final prefix = category != null && category.isNotEmpty ? '[$category AI Prompt]\n\n' : '';
    final fullText = '$prefix$prompt\n\n— Generated with ProCut AI ($playStoreWebUrl)';
    
    // Always copy prompt to clipboard first for convenience
    try {
      await Clipboard.setData(ClipboardData(text: prompt));
      FirebaseService.analytics.logPromptCopy(
        promptTitle: title ?? 'AI Prompt',
        promptType: category ?? 'photo',
      );
    } catch (_) {}

    FirebaseService.analytics.logPromptShare(
      promptTitle: title ?? 'AI Prompt',
      promptType: category ?? 'photo',
    );

    try {
      if (Platform.isAndroid) {
        final res = await _channel.invokeMethod<bool>('shareApp', {
          'text': fullText,
          'subject': title ?? 'ProCut AI Prompt',
          'title': 'Share Prompt to AI (ChatGPT, Gemini, Claude)',
        });
        return res ?? true;
      } else {
        return true;
      }
    } catch (_) {
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

  /// Open any URL using the native Android ACTION_VIEW intent, with clipboard fallback.
  static Future<bool> openUrl(String url) async {
    if (url.isEmpty) return false;
    try {
      if (Platform.isAndroid) {
        final res = await _channel.invokeMethod<bool>('openUrl', {'url': url});
        return res ?? true;
      } else {
        return false;
      }
    } catch (_) {
      return false;
    }
  }
}
