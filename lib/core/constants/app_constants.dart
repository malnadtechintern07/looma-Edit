/// Application-wide constants for LOOMA Video Editor
abstract class AppConstants {
  static const String appName = 'LOOMA';
  static const String appTagline = 'Pro Offline Video Creation';
  static const String appVersion = '1.0.0';

  // Storage Keys
  static const String projectsCatalogFile = 'projects_catalog.json';
  static const String projectsDirectory = 'looma_projects';
  static const String cacheDirectory = 'looma_cache';
  static const String exportDirectory = 'looma_exports';
  static const String userAccountFile = 'user_profile.json';

  // Timeline & Editing Defaults
  static const int defaultFps = 30;
  static const int defaultProjectDurationMs = 15000; // 15 seconds default
  static const int minClipDurationMs = 500; // 0.5s minimum clip
  static const int maxProjectDurationMs = 3600000; // 1 hour max
  static const double minSpeed = 0.25;
  static const double maxSpeed = 4.0;
  static const double defaultVolume = 1.0;
  static const int defaultTransitionDurationMs = 500;

  // UI Layouts
  static const double timelineTrackHeight = 60.0;
  static const double timelineRulerHeight = 28.0;
  static const double playheadWidth = 2.0;
  static const double defaultPixelsPerSecond = 50.0;
}
