import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum LoomaPermissionType {
  camera,
  photosAndVideos,
  microphone,
  notifications,
  location,
}

class PermissionDetail {
  final LoomaPermissionType type;
  final String title;
  final String description;
  final IconData icon;
  final Color accentColor;
  final bool isRequired;

  const PermissionDetail({
    required this.type,
    required this.title,
    required this.description,
    required this.icon,
    required this.accentColor,
    this.isRequired = true,
  });
}

class PermissionService {
  static final PermissionService _instance = PermissionService._internal();
  factory PermissionService() => _instance;
  PermissionService._internal();

  static const String _keySeenPrimer = 'has_seen_permission_primer_v1';

  /// For automated widget tests to opt into verifying first-launch dialog behavior
  static bool forceAutoShowInTests = false;

  /// Check whether the user has already seen the first-time permissions intro dialog
  Future<bool> hasSeenPermissionPrimer() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_keySeenPrimer) ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Mark the first-time permission intro dialog as seen so it does not repeat
  Future<void> markPermissionPrimerSeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keySeenPrimer, true);
    } catch (_) {}
  }

  /// Reset the primer flag (useful for testing and reset settings)
  Future<void> resetPermissionPrimer() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keySeenPrimer);
    } catch (_) {}
  }

  /// Detailed catalog of all permissions requested by Looma
  List<PermissionDetail> getRequestedPermissions() {
    return const [
      PermissionDetail(
        type: LoomaPermissionType.camera,
        title: 'Camera',
        description: 'Capture live video footage and photos directly into your project timeline.',
        icon: Icons.videocam_rounded,
        accentColor: Color(0xFF00C2CB),
        isRequired: true,
      ),
      PermissionDetail(
        type: LoomaPermissionType.photosAndVideos,
        title: 'Photos & Videos',
        description: 'Import clips from your device gallery and save exported 4K / HD videos to camera roll.',
        icon: Icons.photo_library_rounded,
        accentColor: Color(0xFF06B6D4),
        isRequired: true,
      ),
      PermissionDetail(
        type: LoomaPermissionType.microphone,
        title: 'Microphone',
        description: 'Record voiceovers, commentary, and narration onto timeline audio tracks.',
        icon: Icons.mic_rounded,
        accentColor: Color(0xFF10B981),
        isRequired: true,
      ),
      PermissionDetail(
        type: LoomaPermissionType.notifications,
        title: 'Notifications',
        description: 'Alert you when long video exports, render batches, and cloud sync are finished.',
        icon: Icons.notifications_active_rounded,
        accentColor: Color(0xFFFFB800),
        isRequired: false,
      ),
      PermissionDetail(
        type: LoomaPermissionType.location,
        title: 'Location (Optional)',
        description: 'Optionally add geotags, city location stickers, and metadata to your travel videos.',
        icon: Icons.location_on_rounded,
        accentColor: Color(0xFF8B5CF6),
        isRequired: false,
      ),
    ];
  }
}
