import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:looma/features/media_picker/domain/entities/media_item_entity.dart';

class DeviceMediaService {
  final ImagePicker _imagePicker = ImagePicker();

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

  /// Pick one or more videos from device storage
  Future<List<MediaItemEntity>> pickVideosFromDevice() async {
    try {
      final List<XFile> files = await _imagePicker.pickMultipleMedia();
      if (files.isNotEmpty) {
        return files.map((f) {
          final isVideo = f.path.toLowerCase().endsWith('.mp4') ||
              f.path.toLowerCase().endsWith('.mov') ||
              f.path.toLowerCase().endsWith('.mkv') ||
              f.path.toLowerCase().endsWith('.webm') ||
              f.mimeType?.startsWith('video') == true;
          return MediaItemEntity(
            path: f.path,
            name: f.name,
            type: isVideo ? MediaType.video : MediaType.photo,
            durationMs: isVideo ? 6000 : 4000,
          );
        }).toList();
      }
    } catch (_) {
      try {
        final xfile = await _imagePicker.pickVideo(source: ImageSource.gallery);
        if (xfile != null) {
          return [
            MediaItemEntity(
              path: xfile.path,
              name: xfile.name,
              type: MediaType.video,
              durationMs: 6000,
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

  /// Capture video with device camera
  Future<MediaItemEntity?> captureVideoWithCamera() async {
    try {
      final xfile = await _imagePicker.pickVideo(source: ImageSource.camera);
      if (xfile != null) {
        return MediaItemEntity(
          path: xfile.path,
          name: 'Camera Recording (${DateTime.now().second}s)',
          type: MediaType.video,
          durationMs: 6000,
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
        path: 'assets/demo/tokyo_shinjuku.mp4',
        name: 'Tokyo Neon Crossing',
        type: MediaType.video,
        durationMs: 5000,
      ),
      MediaItemEntity(
        path: 'assets/demo/alps_sunrise.mp4',
        name: 'Alps Mountain Fog',
        type: MediaType.video,
        durationMs: 6000,
      ),
      MediaItemEntity(
        path: 'assets/demo/cyberpunk_arcade.mp4',
        name: 'Cyberpunk Retro Arcade',
        type: MediaType.video,
        durationMs: 4500,
      ),
      MediaItemEntity(
        path: 'assets/demo/sunset_beach.jpg',
        name: 'Golden Sunset Waves',
        type: MediaType.photo,
        durationMs: 4000,
      ),
      MediaItemEntity(
        path: 'assets/demo/coffee_art.jpg',
        name: 'Barista Latte Art',
        type: MediaType.photo,
        durationMs: 4000,
      ),
      MediaItemEntity(
        path: 'assets/demo/urban_skate.mp4',
        name: 'Urban Sunset Skate',
        type: MediaType.video,
        durationMs: 5500,
      ),
    ];
  }
}
