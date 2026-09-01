import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/utils/timecode_formatter.dart';
import '../../../../core/widgets/looma_button.dart';
import '../../domain/entities/media_item_entity.dart';
import '../../domain/services/device_media_service.dart';

class MediaPickerModal extends StatefulWidget {
  final String title;
  final String actionLabel;
  final Function(List<MediaItemEntity> selectedMedia) onMediaSelected;

  const MediaPickerModal({
    super.key,
    this.title = 'Select Photos & Videos',
    this.actionLabel = 'Create Project',
    required this.onMediaSelected,
  });

  @override
  State<MediaPickerModal> createState() => _MediaPickerModalState();
}

class _MediaPickerModalState extends State<MediaPickerModal> {
  final DeviceMediaService _mediaService = DeviceMediaService();
  final List<MediaItemEntity> _selectedItems = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Automatically trigger device gallery picker on open
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pickDeviceMedia();
    });
  }

  void _toggleSelection(MediaItemEntity item) {
    setState(() {
      if (_selectedItems.any((i) => i.path == item.path)) {
        _selectedItems.removeWhere((i) => i.path == item.path);
      } else {
        _selectedItems.add(item);
      }
    });
  }

  Future<void> _pickDeviceMedia() async {
    setState(() => _isLoading = true);
    final media = await _mediaService.pickVideosFromDevice();
    if (mounted) {
      setState(() {
        _isLoading = false;
        for (final m in media) {
          if (!_selectedItems.any((i) => i.path == m.path)) {
            _selectedItems.add(m);
          }
        }
      });
      if (media.isNotEmpty && _selectedItems.length == media.length) {
        // If user picked directly from gallery, auto-confirm
        widget.onMediaSelected(_selectedItems);
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _pickDevicePhotos() async {
    setState(() => _isLoading = true);
    final photos = await _mediaService.pickPhotosFromDevice();
    if (mounted) {
      setState(() {
        _isLoading = false;
        for (final p in photos) {
          if (!_selectedItems.any((i) => i.path == p.path)) {
            _selectedItems.add(p);
          }
        }
      });
    }
  }

  Future<void> _captureCameraVideo() async {
    setState(() => _isLoading = true);
    final video = await _mediaService.captureVideoWithCamera();
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (video != null) {
          _selectedItems.add(video);
        }
      });
    }
  }

  Future<void> _captureCameraPhoto() async {
    setState(() => _isLoading = true);
    final photo = await _mediaService.capturePhotoWithCamera();
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (photo != null) {
          _selectedItems.add(photo);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.80,
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.photo_library, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.title,
                  style: AppTypography.titleMedium.copyWith(color: const Color(0xFF111827), fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Color(0xFF6B7280)),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Source Quick Buttons
          Row(
            children: [
              Expanded(
                child: _buildSourceButton(
                  icon: Icons.photo_library,
                  label: 'Gallery (Photos & Videos)',
                  color: const Color(0xFF5B4DFB),
                  onTap: _pickDeviceMedia,
                ),
              ),
              const SizedBox(width: 8),
              _buildSourceButton(
                icon: Icons.photo,
                label: 'Photos',
                color: const Color(0xFF00C2CB),
                onTap: _pickDevicePhotos,
              ),
              const SizedBox(width: 8),
              _buildSourceButton(
                icon: Icons.videocam,
                label: 'Video',
                color: const Color(0xFFFF3B5C),
                onTap: _captureCameraVideo,
              ),
              const SizedBox(width: 8),
              _buildSourceButton(
                icon: Icons.camera_alt,
                label: 'Photo',
                color: const Color(0xFFFFB800),
                onTap: _captureCameraPhoto,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Picked Media Grid or Empty State
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _selectedItems.isEmpty
                    ? Center(
                        child: InkWell(
                          onTap: _pickDeviceMedia,
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8F9FE),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFECEEF5)),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF5B4DFB).withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.add_photo_alternate_outlined,
                                    size: 40,
                                    color: Color(0xFF5B4DFB),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                const Text(
                                  'Open Phone Gallery',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF111827),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Tap here to choose your photos and videos',
                                  style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    : GridView.builder(
                        itemCount: _selectedItems.length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          childAspectRatio: 1.0,
                        ),
                        itemBuilder: (context, index) {
                          final item = _selectedItems[index];
                          final isSelected = _selectedItems.any((i) => i.path == item.path);

                          return InkWell(
                            onTap: () => _toggleSelection(item),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected ? AppColors.primary : AppColors.surfaceBorder,
                                  width: isSelected ? 2.5 : 1.0,
                                ),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: Stack(
                                children: [
                                  // Real Image Thumbnail Preview
                                  Positioned.fill(
                                    child: _buildTileThumbnail(item),
                                  ),

                                  // Dark tint overlay for text readability
                                  Positioned.fill(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.black.withValues(alpha: 0.2),
                                            Colors.black.withValues(alpha: 0.75),
                                          ],
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                        ),
                                      ),
                                    ),
                                  ),

                                  // Play Icon or Photo Badge
                                  Center(
                                    child: Icon(
                                      item.type == MediaType.video
                                          ? Icons.play_circle_fill
                                          : Icons.photo_camera,
                                      color: Colors.white.withValues(alpha: 0.85),
                                      size: 28,
                                    ),
                                  ),

                                  // File Title Label
                                  Positioned(
                                    bottom: 4,
                                    left: 4,
                                    right: 48,
                                    child: Text(
                                      item.name,
                                      style: AppTypography.labelSmall.copyWith(
                                        fontSize: 8,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),

                                  // Duration or Photo Badge
                                  Positioned(
                                    bottom: 4,
                                    right: 4,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(alpha: 0.75),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        item.type == MediaType.video
                                            ? TimecodeFormatter.formatHumanDuration(item.durationMs)
                                            : 'PHOTO',
                                        style: AppTypography.labelSmall.copyWith(fontSize: 8),
                                      ),
                                    ),
                                  ),

                                  // Selection Checkmark Badge
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isSelected ? AppColors.primary : Colors.black45,
                                        border: Border.all(color: Colors.white, width: 1),
                                      ),
                                      child: Icon(
                                        isSelected ? Icons.check : Icons.add,
                                        size: 12,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
          const SizedBox(height: 16),

          // Submit CTA Button
          if (_selectedItems.isNotEmpty)
            LoomaButton(
              label: '${widget.actionLabel} (${_selectedItems.length})',
              icon: Icons.check,
              isFullWidth: true,
              onPressed: () {
                widget.onMediaSelected(_selectedItems);
                Navigator.of(context).pop();
              },
            ),
        ],
      ),
    );
  }

  Widget _buildSourceButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: AppTypography.labelSmall.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTileThumbnail(MediaItemEntity item) {
    if (item.path.startsWith('assets/')) {
      return Image.asset(
        item.path,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _buildTileFallback(item),
      );
    } else if (File(item.path).existsSync()) {
      return Image.file(
        File(item.path),
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _buildTileFallback(item),
      );
    }
    return _buildTileFallback(item);
  }

  Widget _buildTileFallback(MediaItemEntity item) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            item.type == MediaType.video ? const Color(0xFF1E3A8A) : const Color(0xFF831843),
            AppColors.surfaceElevated,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }
}
