import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/storage/local_storage_service.dart';
import '../entities/media_item_entity.dart';
import 'device_media_service.dart';

/// Manages recently added and imported media items for Looma.
/// Persists recently picked media, auto-discovers exported videos,
/// and aggregates project media clips so they appear in the media picker.
class RecentMediaService {
  static final RecentMediaService _instance = RecentMediaService._internal();
  factory RecentMediaService() => _instance;
  RecentMediaService._internal();

  static const String catalogFileName = 'recent_media_catalog.json';
  static const int maxRecentItems = 100;

  final LocalStorageService _storage = LocalStorageService();
  final DeviceMediaService _deviceMediaService = DeviceMediaService();

  List<MediaItemEntity>? _memoryCache;
  bool _hasScannedThisSession = false;

  /// Get recent media items, optionally filtered by MediaType (video/photo).
  /// Sorted from most recently added to oldest.
  Future<List<MediaItemEntity>> getRecentMedia({
    MediaType? type,
    bool autoScan = true,
  }) async {
    if (_memoryCache == null) {
      await _loadFromStorage();
    }

    if (autoScan && !_hasScannedThisSession) {
      _hasScannedThisSession = true;
      if (_memoryCache != null && _memoryCache!.isNotEmpty) {
        // Run background scan so picker opens immediately without stalling
        scanAndMergeDiscoveredMedia();
      } else {
        await scanAndMergeDiscoveredMedia();
      }
    }

    final items = List<MediaItemEntity>.from(_memoryCache ?? []);

    // Filter valid files (keep file paths that exist, asset paths, or content URIs)
    final validItems = items.where((item) {
      if (item.path.startsWith('assets/') ||
          item.path.startsWith('content://') ||
          item.path.startsWith('http://') ||
          item.path.startsWith('https://')) {
        return true;
      }
      try {
        final clean = item.path.startsWith('file://') ? item.path.substring(7) : item.path;
        return File(clean).existsSync();
      } catch (_) {
        return false;
      }
    }).toList();

    // Sort descending by addedAt
    validItems.sort((a, b) {
      final timeA = a.addedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final timeB = b.addedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return timeB.compareTo(timeA);
    });

    if (type != null) {
      return validItems.where((i) => i.type == type).toList();
    }

    return validItems;
  }

  /// Add new media items to the top of the recent catalog
  Future<void> addRecentMedia(List<MediaItemEntity> newItems) async {
    if (newItems.isEmpty) return;
    if (_memoryCache == null) {
      await _loadFromStorage();
    }

    final now = DateTime.now();
    final updatedList = List<MediaItemEntity>.from(_memoryCache ?? []);

    for (final item in newItems) {
      // Remove existing item with same path to avoid duplicates
      updatedList.removeWhere((e) => e.path == item.path);

      // Create with current timestamp if not set
      final timestamped = MediaItemEntity(
        path: item.path,
        name: item.name,
        type: item.type,
        durationMs: item.durationMs,
        thumbnailPath: item.thumbnailPath,
        fileSizeBytes: item.fileSizeBytes,
        addedAt: item.addedAt ?? now,
      );

      updatedList.insert(0, timestamped);
    }

    // Limit to max items
    if (updatedList.length > maxRecentItems) {
      updatedList.removeRange(maxRecentItems, updatedList.length);
    }

    _memoryCache = updatedList;
    await _saveToStorage();
  }

  /// Add a single media item
  Future<void> addRecentMediaSingle(MediaItemEntity item) async {
    await addRecentMedia([item]);
  }

  /// Remove a media item by path
  Future<void> removeRecentMedia(String path) async {
    if (_memoryCache == null) {
      await _loadFromStorage();
    }
    _memoryCache?.removeWhere((e) => e.path == path);
    await _saveToStorage();
  }

  /// Clear the catalog (mainly for unit tests / reset)
  Future<void> clearRecentMedia() async {
    _memoryCache = [];
    _hasScannedThisSession = false;
    await _storage.deleteFile(catalogFileName);
  }

  /// Scan export directories and saved projects to discover user videos/photos
  Future<void> scanAndMergeDiscoveredMedia() async {
    final discovered = <MediaItemEntity>[];

    // 1. Scan exported videos
    try {
      final exportItems = await _scanExportDirectories();
      discovered.addAll(exportItems);
    } catch (e) {
      debugPrint('RecentMediaService scan exports error: $e');
    }

    // 2. Scan saved projects for user media clips
    try {
      final projectItems = await _scanSavedProjects();
      discovered.addAll(projectItems);
    } catch (e) {
      debugPrint('RecentMediaService scan projects error: $e');
    }

    if (discovered.isNotEmpty) {
      await addRecentMedia(discovered);
    }
  }

  /// Scan device export folders for exported MP4 videos
  Future<List<MediaItemEntity>> _scanExportDirectories() async {
    final results = <MediaItemEntity>[];
    final directoriesToCheck = <Directory>[];

    try {
      final docsDir = await getApplicationDocumentsDirectory();
      directoriesToCheck.add(Directory('${docsDir.path}/exports'));
      directoriesToCheck.add(Directory('${docsDir.path}/${AppConstants.exportDirectory}'));
    } catch (_) {}

    try {
      final tempDir = Directory.systemTemp;
      directoriesToCheck.add(Directory('${tempDir.path}/looma_exports'));
      directoriesToCheck.add(Directory('${tempDir.path}/${AppConstants.exportDirectory}'));
    } catch (_) {}

    try {
      if (Platform.isAndroid) {
        directoriesToCheck.add(Directory('/storage/emulated/0/DCIM/Camera'));
        directoriesToCheck.add(Directory('/storage/emulated/0/Movies'));
        directoriesToCheck.add(Directory('/storage/emulated/0/Download'));
      }
    } catch (_) {}

    for (final dir in directoriesToCheck) {
      try {
        if (!dir.existsSync()) continue;
        final entries = dir.listSync();
        for (final entry in entries) {
          if (entry is File) {
            final lower = entry.path.toLowerCase();
            final isVideo = lower.endsWith('.mp4') || lower.endsWith('.mov') || lower.endsWith('.m4v');
            if (isVideo) {
              final fileName = entry.uri.pathSegments.isNotEmpty
                  ? entry.uri.pathSegments.last
                  : 'Exported Video';

              DateTime modifiedTime = DateTime.now();
              int fileBytes = 0;
              try {
                final stat = entry.statSync();
                modifiedTime = stat.modified;
                fileBytes = stat.size;
              } catch (_) {}

              // Extract duration asynchronously or default to reasonable fallback
              int durationMs = 5000;
              try {
                durationMs = await _deviceMediaService.getVideoDurationMs(entry.path);
              } catch (_) {}

              results.add(
                MediaItemEntity(
                  path: entry.path,
                  name: fileName,
                  type: MediaType.video,
                  durationMs: durationMs,
                  fileSizeBytes: fileBytes,
                  addedAt: modifiedTime,
                ),
              );
            }
          }
        }
      } catch (_) {}
    }

    return results;
  }

  /// Scan saved projects to find media clips previously used by the user
  Future<List<MediaItemEntity>> _scanSavedProjects() async {
    final results = <MediaItemEntity>[];
    try {
      final projectFiles = await _storage.listProjectFiles();
      for (final relativePath in projectFiles) {
        try {
          final jsonMap = await _storage.readJson(relativePath);
          if (jsonMap == null) continue;

          final clips = jsonMap['videoClips'];
          if (clips is List) {
            for (final clipData in clips) {
              if (clipData is Map) {
                final mediaPath = clipData['mediaPath'] as String?;
                final name = (clipData['name'] as String?) ?? 'Project Clip';
                final isPhoto = (clipData['isPhoto'] as bool?) ?? false;
                final durationMs = (clipData['sourceDurationMs'] as num?)?.toInt() ?? 5000;

                if (mediaPath != null && mediaPath.isNotEmpty) {
                  // Verify that file exists if local disk file
                  bool exists = true;
                  if (!mediaPath.startsWith('assets/')) {
                    try {
                      exists = File(mediaPath).existsSync();
                    } catch (_) {
                      exists = false;
                    }
                  }

                  if (exists) {
                    DateTime modified = DateTime.now();
                    try {
                      if (!mediaPath.startsWith('assets/')) {
                        modified = File(mediaPath).statSync().modified;
                      }
                    } catch (_) {}

                    results.add(
                      MediaItemEntity(
                        path: mediaPath,
                        name: name,
                        type: isPhoto ? MediaType.photo : MediaType.video,
                        durationMs: durationMs,
                        addedAt: modified,
                      ),
                    );
                  }
                }
              }
            }
          }
        } catch (_) {}
      }
    } catch (_) {}

    return results;
  }

  Future<void> _loadFromStorage() async {
    try {
      final raw = await _storage.readString(catalogFileName);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          _memoryCache = decoded
              .whereType<Map<String, dynamic>>()
              .map((j) => MediaItemEntity.fromJson(j))
              .toList();
          return;
        }
      }
    } catch (e) {
      debugPrint('RecentMediaService load error: $e');
    }
    _memoryCache = [];
  }

  Future<void> _saveToStorage() async {
    try {
      final list = _memoryCache ?? [];
      final encoded = jsonEncode(list.map((e) => e.toJson()).toList());
      await _storage.writeString(catalogFileName, encoded);
    } catch (e) {
      debugPrint('RecentMediaService save error: $e');
    }
  }
}
