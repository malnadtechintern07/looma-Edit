import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:procut/core/config/server_config.dart';
import 'package:procut/core/network/api_client.dart';
import 'package:procut/core/storage/local_storage_service.dart';
import 'package:procut/core/storage/storage_providers.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────
Color _parseHex(String? hex, Color fallback) {
  if (hex == null || hex.isEmpty) return fallback;
  try {
    final clean = hex.replaceAll('0x', '').replaceAll('#', '');
    final padded = clean.length == 6 ? 'FF$clean' : clean;
    return Color(int.parse(padded, radix: 16));
  } catch (_) {
    return fallback;
  }
}

bool _parseBool(dynamic v, {bool fallback = false}) {
  if (v == null) return fallback;
  if (v is bool) return v;
  if (v == 1 || v == '1' || v == 'true') return true;
  return fallback;
}

// ─────────────────────────────────────────────────────────────────────────────
// Branding
// ─────────────────────────────────────────────────────────────────────────────
class RemoteBrandingConfig {
  final String appName;
  final String logoUrl;
  final String splashMessage;
  final String splashBgColor;
  final bool announcementEnabled;
  final String announcementTitle;
  final String announcementMessage;

  const RemoteBrandingConfig({
    this.appName = 'ProCut',
    this.logoUrl = '',
    this.splashMessage = 'Welcome to ProCut',
    this.splashBgColor = '0xFF084298',
    this.announcementEnabled = false,
    this.announcementTitle = '',
    this.announcementMessage = '',
  });

  factory RemoteBrandingConfig.fromJson(Map<String, dynamic> j) {
    return RemoteBrandingConfig(
      appName: j['appName'] as String? ?? 'ProCut',
      logoUrl: j['logoUrl'] as String? ?? '',
      splashMessage: j['splashMessage'] as String? ?? 'Welcome to ProCut',
      splashBgColor: j['splashBgColor'] as String? ?? '0xFF084298',
      announcementEnabled: _parseBool(j['announcementEnabled']),
      announcementTitle: j['announcementTitle'] as String? ?? '',
      announcementMessage: j['announcementMessage'] as String? ?? '',
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Theme & Colors
// ─────────────────────────────────────────────────────────────────────────────
class RemoteThemeConfig {
  final String mode; // light | dark | custom
  final Color primaryColor;
  final Color secondaryColor;
  final Color accentColor;
  final Color backgroundColor;
  final Color surfaceColor;
  final Color textPrimaryColor;
  final Color textSecondaryColor;

  const RemoteThemeConfig({
    this.mode = 'light',
    this.primaryColor = const Color(0xFF0D6EFD),
    this.secondaryColor = const Color(0xFF00C2CB),
    this.accentColor = const Color(0xFFFFB800),
    this.backgroundColor = const Color(0xFFF8F9FE),
    this.surfaceColor = const Color(0xFFFFFFFF),
    this.textPrimaryColor = const Color(0xFF111827),
    this.textSecondaryColor = const Color(0xFF6B7280),
  });

  factory RemoteThemeConfig.fromJson(Map<String, dynamic> j) {
    return RemoteThemeConfig(
      mode: j['mode'] as String? ?? 'light',
      primaryColor: _parseHex(j['primaryColor'] as String?, const Color(0xFF0D6EFD)),
      secondaryColor: _parseHex(j['secondaryColor'] as String?, const Color(0xFF00C2CB)),
      accentColor: _parseHex(j['accentColor'] as String?, const Color(0xFFFFB800)),
      backgroundColor: _parseHex(j['backgroundColor'] as String?, const Color(0xFFF8F9FE)),
      surfaceColor: _parseHex(j['surfaceColor'] as String?, const Color(0xFFFFFFFF)),
      textPrimaryColor: _parseHex(j['textPrimaryColor'] as String?, const Color(0xFF111827)),
      textSecondaryColor: _parseHex(j['textSecondaryColor'] as String?, const Color(0xFF6B7280)),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Navigation
// ─────────────────────────────────────────────────────────────────────────────
class RemoteNavConfig {
  final List<String> tabsOrder;
  final String homeTitle;
  final bool homeEnabled;
  final String projectsTitle;
  final bool projectsEnabled;
  final String templatesTitle;
  final bool templatesEnabled;
  final String meTitle;
  final bool meEnabled;

  const RemoteNavConfig({
    this.tabsOrder = const ['home', 'projects', 'templates', 'me'],
    this.homeTitle = 'Home',
    this.homeEnabled = true,
    this.projectsTitle = 'Projects',
    this.projectsEnabled = true,
    this.templatesTitle = 'Templates',
    this.templatesEnabled = true,
    this.meTitle = 'Me',
    this.meEnabled = true,
  });

  factory RemoteNavConfig.fromJson(Map<String, dynamic> j) {
    final rawOrder = j['tabsOrder'];
    List<String> order;
    if (rawOrder is List) {
      order = rawOrder.map((e) => e.toString()).toList();
    } else if (rawOrder is String) {
      order = rawOrder.split(',').map((e) => e.trim()).toList();
    } else {
      order = const ['home', 'projects', 'templates', 'me'];
    }
    return RemoteNavConfig(
      tabsOrder: order,
      homeTitle: j['homeTitle'] as String? ?? 'Home',
      homeEnabled: _parseBool(j['homeEnabled'], fallback: true),
      projectsTitle: j['projectsTitle'] as String? ?? 'Projects',
      projectsEnabled: _parseBool(j['projectsEnabled'], fallback: true),
      templatesTitle: j['templatesTitle'] as String? ?? 'Templates',
      templatesEnabled: _parseBool(j['templatesEnabled'], fallback: true),
      meTitle: j['meTitle'] as String? ?? 'Me',
      meEnabled: _parseBool(j['meEnabled'], fallback: true),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Home Layout
// ─────────────────────────────────────────────────────────────────────────────
class RemoteHomeLayout {
  final bool heroHeaderEnabled;
  final bool bannerEnabled;
  final bool quickToolsEnabled;
  final bool recentProjectsEnabled;
  final bool templatePreviewEnabled;
  final bool ratioFilterEnabled;

  const RemoteHomeLayout({
    this.heroHeaderEnabled = true,
    this.bannerEnabled = true,
    this.quickToolsEnabled = true,
    this.recentProjectsEnabled = true,
    this.templatePreviewEnabled = true,
    this.ratioFilterEnabled = true,
  });

  factory RemoteHomeLayout.fromJson(Map<String, dynamic> j) {
    return RemoteHomeLayout(
      heroHeaderEnabled: _parseBool(j['heroHeaderEnabled'], fallback: true),
      bannerEnabled: _parseBool(j['bannerEnabled'], fallback: true),
      quickToolsEnabled: _parseBool(j['quickToolsEnabled'], fallback: true),
      recentProjectsEnabled: _parseBool(j['recentProjectsEnabled'], fallback: true),
      templatePreviewEnabled: _parseBool(j['templatePreviewEnabled'], fallback: true),
      ratioFilterEnabled: _parseBool(j['ratioFilterEnabled'], fallback: true),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Editor Tool
// ─────────────────────────────────────────────────────────────────────────────
class RemoteEditorTool {
  final String key;
  final String label;
  final String iconName;
  final bool enabled;
  final int order;

  const RemoteEditorTool({
    required this.key,
    required this.label,
    this.iconName = 'auto_awesome',
    this.enabled = true,
    this.order = 99,
  });

  factory RemoteEditorTool.fromJson(Map<String, dynamic> j) {
    return RemoteEditorTool(
      key: j['key'] as String? ?? '',
      label: j['label'] as String? ?? '',
      iconName: j['icon'] as String? ?? 'auto_awesome',
      enabled: _parseBool(j['enabled'], fallback: true),
      order: j['order'] is int ? j['order'] as int : int.tryParse(j['order'].toString()) ?? 99,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Watermark
// ─────────────────────────────────────────────────────────────────────────────
class RemoteWatermarkConfig {
  final bool enabledFree;
  final String text;
  final String logoUrl;
  final String position;
  final double size;
  final double opacity;

  const RemoteWatermarkConfig({
    this.enabledFree = true,
    this.text = 'PROCUT',
    this.logoUrl = '',
    this.position = 'bottomRight',
    this.size = 0.8,
    this.opacity = 0.8,
  });

  factory RemoteWatermarkConfig.fromJson(Map<String, dynamic> j) {
    return RemoteWatermarkConfig(
      enabledFree: _parseBool(j['enabledFree'], fallback: true),
      text: j['text'] as String? ?? 'PROCUT',
      logoUrl: j['logoUrl'] as String? ?? '',
      position: j['position'] as String? ?? 'bottomRight',
      size: (j['size'] as num?)?.toDouble() ?? 0.8,
      opacity: (j['opacity'] as num?)?.toDouble() ?? 0.8,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Support & Contact
// ─────────────────────────────────────────────────────────────────────────────
class RemoteSupportConfig {
  final String email;
  final String phone;
  final String whatsapp;
  final String website;
  final String helpCenterUrl;
  final String hours;

  const RemoteSupportConfig({
    this.email = 'support@procut.app',
    this.phone = '',
    this.whatsapp = '',
    this.website = 'https://procut.app',
    this.helpCenterUrl = '',
    this.hours = '24/7 Creator Support',
  });

  factory RemoteSupportConfig.fromJson(Map<String, dynamic> j) {
    return RemoteSupportConfig(
      email: j['email'] as String? ?? 'support@procut.app',
      phone: j['phone'] as String? ?? '',
      whatsapp: j['whatsapp'] as String? ?? '',
      website: j['website'] as String? ?? 'https://procut.app',
      helpCenterUrl: j['helpCenterUrl'] as String? ?? '',
      hours: j['hours'] as String? ?? '24/7 Creator Support',
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Legal
// ─────────────────────────────────────────────────────────────────────────────
class RemoteLegalConfig {
  final String privacyPolicyContent;
  final String termsConditionsContent;
  final String aboutDescription;
  final String aboutCompanyName;
  final String copyrightText;

  const RemoteLegalConfig({
    this.privacyPolicyContent = '',
    this.termsConditionsContent = '',
    this.aboutDescription = 'Pro Mobile Video Editor.',
    this.aboutCompanyName = 'ProCut Studio',
    this.copyrightText = '© 2025 ProCut Studio.',
  });

  factory RemoteLegalConfig.fromJson(Map<String, dynamic> j) {
    return RemoteLegalConfig(
      privacyPolicyContent: j['privacyPolicyContent'] as String? ?? '',
      termsConditionsContent: j['termsConditionsContent'] as String? ?? '',
      aboutDescription: j['aboutDescription'] as String? ?? 'Pro Mobile Video Editor.',
      aboutCompanyName: j['aboutCompanyName'] as String? ?? 'ProCut Studio',
      copyrightText: j['copyrightText'] as String? ?? '© 2025 ProCut Studio.',
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Social & Growth
// ─────────────────────────────────────────────────────────────────────────────
class RemoteSocialConfig {
  final String instagramUrl;
  final String youtubeUrl;
  final String twitterUrl;
  final String tiktokUrl;
  final String discordUrl;
  final bool rateUsEnabled;
  final String rateUsStoreUrl;
  final bool shareAppEnabled;
  final String shareAppMessage;
  final String shareAppUrl;

  const RemoteSocialConfig({
    this.instagramUrl = '',
    this.youtubeUrl = '',
    this.twitterUrl = '',
    this.tiktokUrl = '',
    this.discordUrl = '',
    this.rateUsEnabled = true,
    this.rateUsStoreUrl = 'https://play.google.com/store',
    this.shareAppEnabled = true,
    this.shareAppMessage = 'Check out ProCut!',
    this.shareAppUrl = 'https://procut.app',
  });

  factory RemoteSocialConfig.fromJson(Map<String, dynamic> j) {
    return RemoteSocialConfig(
      instagramUrl: j['instagramUrl'] as String? ?? '',
      youtubeUrl: j['youtubeUrl'] as String? ?? '',
      twitterUrl: j['twitterUrl'] as String? ?? '',
      tiktokUrl: j['tiktokUrl'] as String? ?? '',
      discordUrl: j['discordUrl'] as String? ?? '',
      rateUsEnabled: _parseBool(j['rateUsEnabled'], fallback: true),
      rateUsStoreUrl: j['rateUsStoreUrl'] as String? ?? 'https://play.google.com/store',
      shareAppEnabled: _parseBool(j['shareAppEnabled'], fallback: true),
      shareAppMessage: j['shareAppMessage'] as String? ?? 'Check out ProCut!',
      shareAppUrl: j['shareAppUrl'] as String? ?? 'https://procut.app',
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Versioning & Update
// ─────────────────────────────────────────────────────────────────────────────
class RemoteVersioningConfig {
  final String appVersion;
  final String minAppVersion;
  final bool forceUpdate;
  final String updateDialogTitle;
  final String updateDialogMessage;
  final String updateStoreUrl;

  const RemoteVersioningConfig({
    this.appVersion = '1.0.0',
    this.minAppVersion = '1.0.0',
    this.forceUpdate = false,
    this.updateDialogTitle = 'Update Available',
    this.updateDialogMessage = 'Please update ProCut to the latest version.',
    this.updateStoreUrl = 'https://play.google.com/store',
  });

  factory RemoteVersioningConfig.fromJson(Map<String, dynamic> j) {
    return RemoteVersioningConfig(
      appVersion: j['appVersion'] as String? ?? '1.0.0',
      minAppVersion: j['minAppVersion'] as String? ?? '1.0.0',
      forceUpdate: _parseBool(j['forceUpdate']),
      updateDialogTitle: j['updateDialogTitle'] as String? ?? 'Update Available',
      updateDialogMessage: j['updateDialogMessage'] as String? ?? 'Please update ProCut.',
      updateStoreUrl: j['updateStoreUrl'] as String? ?? 'https://play.google.com/store',
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Legacy Banner (kept for compatibility)
// ─────────────────────────────────────────────────────────────────────────────
class RemoteBannerModel {
  final int id;
  final String title;
  final String subtitle;
  final String badgeText;
  final String buttonText;
  final String actionRoute;
  final String gradientStart;
  final String gradientEnd;
  final String placement;
  final String? imageUrl;

  const RemoteBannerModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.badgeText,
    required this.buttonText,
    required this.actionRoute,
    required this.gradientStart,
    required this.gradientEnd,
    required this.placement,
    this.imageUrl,
  });

  Color get startColor => _parseHex(gradientStart, const Color(0xFF084298));
  Color get endColor => _parseHex(gradientEnd, const Color(0xFF0D6EFD));

  factory RemoteBannerModel.fromJson(Map<String, dynamic> json) {
    return RemoteBannerModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      badgeText: json['badge_text'] as String? ?? 'NEW',
      buttonText: json['button_text'] as String? ?? 'Explore',
      actionRoute: json['action_route'] as String? ?? '/auth',
      gradientStart: json['gradient_start'] as String? ?? '0xFF084298',
      gradientEnd: json['gradient_end'] as String? ?? '0xFF0D6EFD',
      placement: json['placement'] as String? ?? 'home_top',
      imageUrl: json['image_url'] as String?,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Legacy Home Section (kept for compatibility)
// ─────────────────────────────────────────────────────────────────────────────
class RemoteHomeSectionModel {
  final String sectionKey;
  final String title;
  final String subtitle;
  final int displayOrder;
  final bool isEnabled;

  const RemoteHomeSectionModel({
    required this.sectionKey,
    required this.title,
    required this.subtitle,
    required this.displayOrder,
    required this.isEnabled,
  });

  factory RemoteHomeSectionModel.fromJson(Map<String, dynamic> json) {
    return RemoteHomeSectionModel(
      sectionKey: json['section_key'] as String? ?? '',
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      displayOrder: json['display_order'] is int
          ? json['display_order']
          : int.tryParse(json['display_order'].toString()) ?? 0,
      isEnabled: json['is_enabled'] == 1 || json['is_enabled'] == true || json['is_enabled'] == '1',
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Legacy Feature (kept for compatibility with QuickActionBanner)
// ─────────────────────────────────────────────────────────────────────────────
class RemoteFeatureModel {
  final String featureKey;
  final String name;
  final String iconName;
  final int displayOrder;
  final bool isEnabled;
  final bool isPro;
  final String? badgeText;
  final String? actionRoute;

  const RemoteFeatureModel({
    required this.featureKey,
    required this.name,
    required this.iconName,
    required this.displayOrder,
    required this.isEnabled,
    required this.isPro,
    this.badgeText,
    this.actionRoute,
  });

  factory RemoteFeatureModel.fromJson(Map<String, dynamic> json) {
    final rawName = (json['name'] as String? ?? json['title'] as String? ?? '').trim();
    final isProVal = json['is_pro'] == 1 || json['is_pro'] == true || json['is_pro'] == '1' ||
                     json['is_pro_only'] == 1 || json['is_pro_only'] == true || json['is_pro_only'] == '1';

    return RemoteFeatureModel(
      featureKey: json['feature_key'] as String? ?? '',
      name: rawName,
      iconName: json['icon_name'] as String? ?? 'auto_awesome_outlined',
      displayOrder: json['display_order'] is int
          ? json['display_order']
          : int.tryParse(json['display_order'].toString()) ?? 0,
      isEnabled: json['is_enabled'] == 1 || json['is_enabled'] == true || json['is_enabled'] == '1',
      isPro: isProVal,
      badgeText: json['badge_text'] as String?,
      actionRoute: json['action_route'] as String?,
    );
  }

  IconData get iconData {
    switch (iconName) {
      case 'movie_creation_outlined':
      case 'movie_creation':
        return Icons.movie_creation_outlined;
      case 'video_library_outlined':
      case 'video_library':
        return Icons.video_library_outlined;
      case 'face_retouching_natural_outlined':
      case 'face_retouching':
        return Icons.face_retouching_natural_outlined;
      case 'photo_filter_outlined':
      case 'photo_filter':
        return Icons.photo_filter_outlined;
      case 'camera_alt_outlined':
      case 'camera_alt':
        return Icons.camera_alt_outlined;
      case 'closed_caption_outlined':
      case 'closed_caption':
        return Icons.closed_caption_outlined;
      case 'person_pin_circle_outlined':
      case 'person_pin':
        return Icons.person_pin_circle_outlined;
      case 'cloud_outlined':
      case 'cloud':
        return Icons.cloud_outlined;
      case 'cut':
      case 'content_cut':
        return Icons.content_cut;
      case 'music_note':
        return Icons.music_note;
      case 'text_fields':
        return Icons.text_fields;
      case 'auto_awesome':
      default:
        return Icons.auto_awesome_outlined;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Master AppRemoteConfig
// ─────────────────────────────────────────────────────────────────────────────
class AppRemoteConfig {
  // Domain configs
  final RemoteBrandingConfig branding;
  final RemoteThemeConfig theme;
  final RemoteNavConfig navigation;
  final RemoteHomeLayout homeLayout;
  final List<RemoteEditorTool> videoEditorTools;
  final List<RemoteEditorTool> photoEditorTools;
  final RemoteWatermarkConfig watermark;
  final RemoteSupportConfig support;
  final RemoteLegalConfig legal;
  final RemoteSocialConfig social;
  final RemoteVersioningConfig versioning;

  // Maintenance
  final bool maintenanceMode;
  final String maintenanceTitle;
  final String maintenanceMessage;

  // Legacy fields (existing code compatibility)
  final String appName;
  final String appVersion;
  final bool watermarkEnabledFree;
  final String watermarkText;
  final String watermarkPosition;
  final List<RemoteBannerModel> banners;
  final List<RemoteHomeSectionModel> homeSections;
  final List<RemoteFeatureModel> features;

  const AppRemoteConfig({
    this.branding = const RemoteBrandingConfig(),
    this.theme = const RemoteThemeConfig(),
    this.navigation = const RemoteNavConfig(),
    this.homeLayout = const RemoteHomeLayout(),
    this.videoEditorTools = const [],
    this.photoEditorTools = const [],
    this.watermark = const RemoteWatermarkConfig(),
    this.support = const RemoteSupportConfig(),
    this.legal = const RemoteLegalConfig(),
    this.social = const RemoteSocialConfig(),
    this.versioning = const RemoteVersioningConfig(),
    this.maintenanceMode = false,
    this.maintenanceTitle = 'Scheduled Maintenance',
    this.maintenanceMessage = '',
    // Legacy
    this.appName = 'ProCut',
    this.appVersion = '1.0.0',
    this.watermarkEnabledFree = true,
    this.watermarkText = 'PROCUT',
    this.watermarkPosition = 'bottomRight',
    this.banners = const [],
    this.homeSections = const [],
    this.features = const [],
  });

  factory AppRemoteConfig.fromJson(
    Map<String, dynamic> configJson,
    Map<String, dynamic>? contentJson,
  ) {
    // Domain objects
    final brandingRaw = configJson['branding'] as Map<String, dynamic>? ?? {};
    final themeRaw    = configJson['theme'] as Map<String, dynamic>? ?? {};
    final navRaw      = configJson['navigation'] as Map<String, dynamic>? ?? {};
    final homeRaw     = configJson['homeLayout'] as Map<String, dynamic>? ?? {};
    final watermarkRaw= configJson['watermark'] as Map<String, dynamic>? ?? {};
    final supportRaw  = configJson['support'] as Map<String, dynamic>? ?? {};
    final legalRaw    = configJson['legal'] as Map<String, dynamic>? ?? {};
    final socialRaw   = configJson['social'] as Map<String, dynamic>? ?? {};
    final versionRaw  = configJson['versioning'] as Map<String, dynamic>? ?? {};
    final maintRaw    = configJson['maintenance'] as Map<String, dynamic>? ?? {};

    // Video & Photo editor tools
    List<RemoteEditorTool> parsedVideoTools = [];
    List<RemoteEditorTool> parsedPhotoTools = [];
    final videoRaw = configJson['videoEditorTools'] as List<dynamic>?;
    final photoRaw = configJson['photoEditorTools'] as List<dynamic>?;
    if (videoRaw != null) {
      parsedVideoTools = videoRaw
          .whereType<Map<String, dynamic>>()
          .map(RemoteEditorTool.fromJson)
          .toList()
        ..sort((a, b) => a.order.compareTo(b.order));
    }
    if (photoRaw != null) {
      parsedPhotoTools = photoRaw
          .whereType<Map<String, dynamic>>()
          .map(RemoteEditorTool.fromJson)
          .toList()
        ..sort((a, b) => a.order.compareTo(b.order));
    }

    // Legacy banners / features from content endpoint
    final bannersRaw  = (contentJson?['banners'] as List<dynamic>?) ?? [];
    final featuresRaw = (contentJson?['features'] as List<dynamic>?) ?? [];
    // Legacy home sections from config endpoint
    final sectionsRaw = configJson['homeSections'] as List<dynamic>? ?? [];

    final watermarkCfg = RemoteWatermarkConfig.fromJson(watermarkRaw);

    return AppRemoteConfig(
      branding: RemoteBrandingConfig.fromJson(brandingRaw),
      theme: RemoteThemeConfig.fromJson(themeRaw),
      navigation: RemoteNavConfig.fromJson(navRaw),
      homeLayout: RemoteHomeLayout.fromJson(homeRaw),
      videoEditorTools: parsedVideoTools,
      photoEditorTools: parsedPhotoTools,
      watermark: watermarkCfg,
      support: RemoteSupportConfig.fromJson(supportRaw),
      legal: RemoteLegalConfig.fromJson(legalRaw),
      social: RemoteSocialConfig.fromJson(socialRaw),
      versioning: RemoteVersioningConfig.fromJson(versionRaw),
      maintenanceMode: _parseBool(maintRaw['enabled']) || _parseBool(configJson['maintenanceMode']),
      maintenanceTitle: maintRaw['title'] as String? ?? 'Scheduled Maintenance',
      maintenanceMessage: maintRaw['message'] as String? ??
          configJson['maintenanceMessage'] as String? ??
          '',
      // Legacy compat
      appName: brandingRaw['appName'] as String? ?? configJson['appName'] as String? ?? 'ProCut',
      appVersion: versionRaw['appVersion'] as String? ?? configJson['appVersion'] as String? ?? '1.0.0',
      watermarkEnabledFree: watermarkCfg.enabledFree,
      watermarkText: watermarkCfg.text,
      watermarkPosition: watermarkCfg.position,
      banners: bannersRaw
          .whereType<Map<String, dynamic>>()
          .map(RemoteBannerModel.fromJson)
          .toList(),
      homeSections: sectionsRaw
          .whereType<Map<String, dynamic>>()
          .map(RemoteHomeSectionModel.fromJson)
          .toList(),
      features: featuresRaw
          .whereType<Map<String, dynamic>>()
          .map(RemoteFeatureModel.fromJson)
          .toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Service
// ─────────────────────────────────────────────────────────────────────────────
class AppRemoteConfigService {
  final LocalStorageService? localStorageService;

  AppRemoteConfigService({this.localStorageService});

  static const String _cacheKey = 'app_remote_config_cache.json';

  Future<AppRemoteConfig> fetchConfig() async {
    final baseUrl = await ServerConfig.getBaseUrl();

    try {
      // 1. Fetch config
      final configUri = Uri.parse('$baseUrl/api/app/config');
      final configRes = await ApiClient.get(configUri, timeout: const Duration(seconds: 8));
      if (configRes.isOk && configRes.json is Map) {
        final outerJson = configRes.json as Map<String, dynamic>;
        // Server wraps in {success, data} or returns flat
        final configJson = outerJson['data'] is Map<String, dynamic>
            ? outerJson['data'] as Map<String, dynamic>
            : outerJson;

        // 2. Fetch content (banners, features, templates)
        Map<String, dynamic>? contentJson;
        try {
          final contentUri = Uri.parse('$baseUrl/api/app/content');
          final contentRes = await ApiClient.get(contentUri, timeout: const Duration(seconds: 8));
          if (contentRes.isOk && contentRes.json is Map) {
            final outer = contentRes.json as Map<String, dynamic>;
            contentJson = outer['data'] is Map<String, dynamic>
                ? outer['data'] as Map<String, dynamic>
                : outer;
          }
        } catch (_) {}

        final config = AppRemoteConfig.fromJson(configJson, contentJson);

        // Cache locally for offline startup
        if (localStorageService != null) {
          await localStorageService!.writeJson(_cacheKey, {
            'config': configJson,
            'content': contentJson,
          });
        }

        return config;
      }
    } catch (e) {
      debugPrint('AppRemoteConfigService: unable to reach server: $e');
    }

    // Offline cache fallback
    if (localStorageService != null) {
      try {
        final cached = await localStorageService!.readJson(_cacheKey);
        if (cached != null) {
          final configJson = cached['config'] as Map<String, dynamic>? ?? {};
          final contentJson = cached['content'] as Map<String, dynamic>?;
          return AppRemoteConfig.fromJson(configJson, contentJson);
        }
      } catch (_) {}
    }

    return const AppRemoteConfig();
  }
}

final appRemoteConfigServiceProvider = Provider<AppRemoteConfigService>((ref) {
  final storage = ref.watch(localStorageServiceProvider);
  return AppRemoteConfigService(localStorageService: storage);
});

final appRemoteConfigProvider = FutureProvider.autoDispose<AppRemoteConfig>((ref) async {
  final service = ref.watch(appRemoteConfigServiceProvider);
  return await service.fetchConfig();
});
