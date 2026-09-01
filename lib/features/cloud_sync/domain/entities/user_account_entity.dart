import 'package:flutter/foundation.dart';

@immutable
class UserAccountEntity {
  final String id;
  final String displayName;
  final String email;
  final String avatarUrl;
  final int totalCloudStorageBytes;
  final int usedCloudStorageBytes;
  final bool isProMember;
  final DateTime memberSince;

  const UserAccountEntity({
    required this.id,
    required this.displayName,
    required this.email,
    required this.avatarUrl,
    this.totalCloudStorageBytes = 15 * 1024 * 1024 * 1024, // 15 GB
    this.usedCloudStorageBytes = 3420 * 1024 * 1024, // ~3.4 GB
    this.isProMember = true,
    required this.memberSince,
  });

  double get usagePercentage =>
      totalCloudStorageBytes > 0 ? (usedCloudStorageBytes / totalCloudStorageBytes) : 0.0;

  String get formattedUsedStorage =>
      '${(usedCloudStorageBytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';

  String get formattedTotalStorage =>
      '${(totalCloudStorageBytes / (1024 * 1024 * 1024)).toStringAsFixed(0)} GB';
}
