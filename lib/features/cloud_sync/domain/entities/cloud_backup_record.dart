import 'package:flutter/foundation.dart';

@immutable
class CloudBackupRecord {
  final String projectId;
  final String projectTitle;
  final int fileSizeBytes;
  final DateTime backedUpAt;
  final String cloudChecksum;

  const CloudBackupRecord({
    required this.projectId,
    required this.projectTitle,
    required this.fileSizeBytes,
    required this.backedUpAt,
    required this.cloudChecksum,
  });

  Map<String, dynamic> toJson() => {
        'projectId': projectId,
        'projectTitle': projectTitle,
        'fileSizeBytes': fileSizeBytes,
        'backedUpAt': backedUpAt.toIso8601String(),
        'cloudChecksum': cloudChecksum,
      };

  factory CloudBackupRecord.fromJson(Map<String, dynamic> json) => CloudBackupRecord(
        projectId: json['projectId'] as String? ?? '',
        projectTitle: json['projectTitle'] as String? ?? '',
        fileSizeBytes: (json['fileSizeBytes'] as num?)?.toInt() ?? 0,
        backedUpAt: json['backedUpAt'] != null
            ? DateTime.tryParse(json['backedUpAt'] as String) ?? DateTime.now()
            : DateTime.now(),
        cloudChecksum: json['cloudChecksum'] as String? ?? '',
      );

  String get formattedSize =>
      '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

