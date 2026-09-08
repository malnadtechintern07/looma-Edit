abstract class RoutePaths {
  static const String home = '/';
  static const String editor = '/editor/:projectId';
  static const String photoEditor = '/photo-editor';
  static const String store = '/store';
  static const String cloud = '/cloud';
  static const String export = '/export/:projectId';
  static const String auth = '/auth';
  static const String privacyPolicy = '/privacy-policy';
  static const String helpCenter = '/help-center';
  static const String contactSupport = '/contact-support';

  /// Helper to format dynamic route paths
  static String editorPath(String projectId) => '/editor/$projectId';
  static String photoEditorPath(String projectId) => '/photo-editor/$projectId';
  static String exportPath(String projectId) => '/export/$projectId';
}
