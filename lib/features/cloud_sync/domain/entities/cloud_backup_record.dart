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

  String get formattedSize =>
      '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}
