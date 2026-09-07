/// Configuration settings for Bunny.net Edge Storage
class BunnyStorageConfig {
  final String storageZoneName;
  final String accessKey;
  final String storageEndpoint;
  final String? cdnHostname;
  final bool isEnabled;

  const BunnyStorageConfig({
    required this.storageZoneName,
    required this.accessKey,
    this.storageEndpoint = 'storage.bunnycdn.com',
    this.cdnHostname,
    this.isEnabled = true,
  });

  /// Default configuration for LOOMA Cloud Storage on Bunny.net
  factory BunnyStorageConfig.defaultConfig() => const BunnyStorageConfig(
        storageZoneName: 'looma-storage',
        accessKey: 'bny_live_looma_storage_key_default',
        storageEndpoint: 'storage.bunnycdn.com',
        cdnHostname: 'looma.b-cdn.net',
        isEnabled: true,
      );

  bool get hasValidCredentials =>
      storageZoneName.trim().isNotEmpty && accessKey.trim().isNotEmpty;

  /// Regional endpoints available on Bunny.net Edge Storage
  static const Map<String, String> availableRegions = {
    'Global / Falkenstein (Default)': 'storage.bunnycdn.com',
    'United Kingdom (London)': 'uk.storage.bunnycdn.com',
    'US East (New York)': 'ny.storage.bunnycdn.com',
    'US West (Los Angeles)': 'la.storage.bunnycdn.com',
    'Asia (Singapore)': 'sg.storage.bunnycdn.com',
    'Oceania (Sydney)': 'syd.storage.bunnycdn.com',
    'Europe (Stockholm)': 'se.storage.bunnycdn.com',
    'South America (Brazil)': 'br.storage.bunnycdn.com',
    'Africa (Johannesburg)': 'jh.storage.bunnycdn.com',
  };

  BunnyStorageConfig copyWith({
    String? storageZoneName,
    String? accessKey,
    String? storageEndpoint,
    String? cdnHostname,
    bool? isEnabled,
  }) {
    return BunnyStorageConfig(
      storageZoneName: storageZoneName ?? this.storageZoneName,
      accessKey: accessKey ?? this.accessKey,
      storageEndpoint: storageEndpoint ?? this.storageEndpoint,
      cdnHostname: cdnHostname ?? this.cdnHostname,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }

  Map<String, dynamic> toJson() => {
        'storageZoneName': storageZoneName,
        'accessKey': accessKey,
        'storageEndpoint': storageEndpoint,
        if (cdnHostname != null) 'cdnHostname': cdnHostname,
        'isEnabled': isEnabled,
      };

  factory BunnyStorageConfig.fromJson(Map<String, dynamic> json) =>
      BunnyStorageConfig(
        storageZoneName: (json['storageZoneName'] as String?) ?? 'looma-storage',
        accessKey: (json['accessKey'] as String?) ?? '',
        storageEndpoint:
            (json['storageEndpoint'] as String?) ?? 'storage.bunnycdn.com',
        cdnHostname: json['cdnHostname'] as String?,
        isEnabled: (json['isEnabled'] as bool?) ?? true,
      );
}
