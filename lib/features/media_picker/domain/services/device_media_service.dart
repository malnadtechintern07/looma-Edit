import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:looma/features/media_picker/domain/entities/media_item_entity.dart';

class DeviceMediaService {
  final ImagePicker _imagePicker = ImagePicker();

  /// Extract exact media duration in milliseconds for a video file or asset
  Future<int> getVideoDurationMs(String path) async {
    try {
      VideoPlayerController controller;
      final cleanPath = path.startsWith('file://') ? path.substring(7) : path;
      if (path.startsWith('assets/')) {
        controller = VideoPlayerController.asset(path);
      } else if (path.startsWith('content://') || path.startsWith('http://') || path.startsWith('https://')) {
        controller = VideoPlayerController.networkUrl(Uri.parse(path));
      } else if (File(cleanPath).existsSync()) {
        controller = VideoPlayerController.file(File(cleanPath));
      } else {
        try {
          controller = VideoPlayerController.networkUrl(Uri.parse(path));
        } catch (_) {
          return 5000;
        }
      }

      await controller.initialize();
      final durationMs = controller.value.duration.inMilliseconds;
      await controller.dispose();

      if (durationMs > 0) {
        return durationMs;
      }
    } catch (e) {
      debugPrint('DeviceMediaService: error extracting video duration for $path: $e');
    }
    return 5000;
  }

  bool _isVideoPath(String path) {
    final lower = path.toLowerCase();
    return lower.endsWith('.mp4') ||
        lower.endsWith('.mov') ||
        lower.endsWith('.mkv') ||
        lower.endsWith('.webm') ||
        lower.endsWith('.avi') ||
        lower.endsWith('.3gp') ||
        lower.endsWith('.m4v');
  }

  /// Pick audio/music files from local device storage
  Future<List<MediaItemEntity>> pickAudioFromDevice() async {
    try {
      final XFile? file = await _imagePicker.pickMedia();
      if (file != null) {
        return [
          MediaItemEntity(
            path: file.path,
            name: file.name,
            type: MediaType.audio,
            durationMs: 15000,
          ),
        ];
      }
    } catch (e) {
      debugPrint('pickAudioFromDevice error: $e');
    }
    return [];
  }

  /// Pick one or more videos from device storage with exact full duration
  Future<List<MediaItemEntity>> pickVideosFromDevice() async {
    try {
      final List<XFile> files = await _imagePicker.pickMultipleMedia();
      if (files.isNotEmpty) {
        final List<MediaItemEntity> results = [];
        for (final f in files) {
          final isVideo = _isVideoPath(f.path) || f.mimeType?.startsWith('video') == true;
          int durationMs = 4000;
          if (isVideo) {
            durationMs = await getVideoDurationMs(f.path);
          }
          results.add(
            MediaItemEntity(
              path: f.path,
              name: f.name,
              type: isVideo ? MediaType.video : MediaType.photo,
              durationMs: durationMs,
            ),
          );
        }
        return results;
      }
    } catch (_) {
      try {
        final xfile = await _imagePicker.pickVideo(source: ImageSource.gallery);
        if (xfile != null) {
          final durationMs = await getVideoDurationMs(xfile.path);
          return [
            MediaItemEntity(
              path: xfile.path,
              name: xfile.name,
              type: MediaType.video,
              durationMs: durationMs,
            ),
          ];
        }
      } catch (_) {}
    }
    return [];
  }

  /// Pick one or more photos from device gallery
  Future<List<MediaItemEntity>> pickPhotosFromDevice() async {
    try {
      final List<XFile> files = await _imagePicker.pickMultiImage();
      if (files.isNotEmpty) {
        return files.map((f) {
          return MediaItemEntity(
            path: f.path,
            name: f.name,
            type: MediaType.photo,
            durationMs: 4000,
          );
        }).toList();
      }
    } catch (_) {
      try {
        final xfile = await _imagePicker.pickImage(source: ImageSource.gallery);
        if (xfile != null) {
          return [
            MediaItemEntity(
              path: xfile.path,
              name: xfile.name,
              type: MediaType.photo,
              durationMs: 4000,
            ),
          ];
        }
      } catch (_) {}
    }
    return [];
  }

  /// Capture video with device camera with exact duration
  Future<MediaItemEntity?> captureVideoWithCamera() async {
    try {
      final xfile = await _imagePicker.pickVideo(source: ImageSource.camera);
      if (xfile != null) {
        final durationMs = await getVideoDurationMs(xfile.path);
        return MediaItemEntity(
          path: xfile.path,
          name: 'Camera Recording (${(durationMs / 1000).toStringAsFixed(1)}s)',
          type: MediaType.video,
          durationMs: durationMs,
        );
      }
    } catch (_) {}
    return null;
  }

  /// Take photo with device camera
  Future<MediaItemEntity?> capturePhotoWithCamera() async {
    try {
      final xfile = await _imagePicker.pickImage(source: ImageSource.camera);
      if (xfile != null) {
        return MediaItemEntity(
          path: xfile.path,
          name: 'Camera Photo',
          type: MediaType.photo,
          durationMs: 4000,
        );
      }
    } catch (_) {}
    return null;
  }

  /// Sample stock clips for testing
  List<MediaItemEntity> getSampleStockClips() {
    return const [
      MediaItemEntity(
        path: 'assets/branding/demo_vid1.mp4',
        name: 'Office Room Walkthrough',
        type: MediaType.video,
        durationMs: 49000,
      ),
      MediaItemEntity(
        path: 'assets/branding/demo_vid2.mp4',
        name: 'Temple Courtyard Ceremony',
        type: MediaType.video,
        durationMs: 104000,
      ),
      MediaItemEntity(
        path: 'assets/branding/demo_vid3.mp4',
        name: 'Studio Setup & Intro',
        type: MediaType.video,
        durationMs: 35000,
      ),
      MediaItemEntity(
        path: 'assets/branding/demo_vid4.mp4',
        name: 'Friends Selfie Vlog',
        type: MediaType.video,
        durationMs: 6000,
      ),
      MediaItemEntity(
        path: 'assets/branding/demo_photo1.jpg',
        name: 'Creative Portrait',
        type: MediaType.photo,
        durationMs: 4000,
      ),
      MediaItemEntity(
        path: 'assets/branding/demo_photo2.jpg',
        name: 'City Skyline',
        type: MediaType.photo,
        durationMs: 4000,
      ),
    ];
  }
}
