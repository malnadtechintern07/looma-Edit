import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../domain/entities/media_item_entity.dart';
import '../../domain/services/device_media_service.dart';

class MediaPickerModal extends StatefulWidget {
  final String title;
  final String actionLabel;
  final Function(List<MediaItemEntity> selectedMedia) onMediaSelected;

  const MediaPickerModal({
    super.key,
    this.title = 'Select media',
    this.actionLabel = 'Add',
    required this.onMediaSelected,
  });

  @override
  State<MediaPickerModal> createState() => _MediaPickerModalState();
}

enum _PickerTopTab { albums, spaces, library }
enum _PickerSubTab { videos, photos }
enum _PickerBottomNav { addMedia, scriptToVideo }

class _MediaPickerModalState extends State<MediaPickerModal> {
  final DeviceMediaService _mediaService = DeviceMediaService();

  _PickerTopTab _activeTopTab = _PickerTopTab.albums;
  _PickerSubTab _activeSubTab = _PickerSubTab.videos;
  _PickerBottomNav _activeBottomNav = _PickerBottomNav.addMedia;

  String _selectedAlbum = 'All Media';
  bool _isHdEnabled = true;
  bool _isLoading = false;

  final List<MediaItemEntity> _selectedItems = [];
  final List<MediaItemEntity> _deviceMediaList = [];

  // Preset demo stock media matching the exact look in Image 1
  final List<MediaItemEntity> _demoMediaList = [
    const MediaItemEntity(
      path: 'assets/branding/demo_vid1.mp4',
      name: 'Office Room Walkthrough',
      type: MediaType.video,
      durationMs: 49000, // 00:49
    ),
    const MediaItemEntity(
      path: 'assets/branding/demo_vid2.mp4',
      name: 'Temple Courtyard Ceremony',
      type: MediaType.video,
      durationMs: 104000, // 01:44
    ),
    const MediaItemEntity(
      path: 'assets/branding/demo_vid3.mp4',
      name: 'Studio Setup & Intro',
      type: MediaType.video,
      durationMs: 35000, // 00:35
    ),
    const MediaItemEntity(
      path: 'assets/branding/demo_vid4.mp4',
      name: 'Friends Selfie Vlog',
      type: MediaType.video,
      durationMs: 6000, // 00:06
    ),
    const MediaItemEntity(
      path: 'assets/branding/demo_vid5.mp4',
      name: 'Desktop Screencast',
      type: MediaType.video,
      durationMs: 11000, // 00:11
    ),
    const MediaItemEntity(
      path: 'assets/branding/demo_vid6.mp4',
      name: 'Night City Lights',
      type: MediaType.video,
      durationMs: 88000, // 01:28
    ),
    const MediaItemEntity(
      path: 'assets/branding/demo_vid7.mp4',
      name: 'Ocean Waves & Sunset',
      type: MediaType.video,
      durationMs: 17000, // 00:17
    ),
    const MediaItemEntity(
      path: 'assets/branding/demo_vid8.mp4',
      name: 'Eyes Dramatic Close-up',
      type: MediaType.video,
      durationMs: 13000, // 00:13
    ),
    const MediaItemEntity(
      path: 'assets/branding/demo_vid9.mp4',
      name: 'Nature Horizon Panorama',
      type: MediaType.video,
      durationMs: 3000, // 00:03
    ),
    const MediaItemEntity(
      path: 'assets/branding/demo_vid10.mp4',
      name: 'Portrait Window Light',
      type: MediaType.video,
      durationMs: 3000, // 00:03
    ),
    const MediaItemEntity(
      path: 'assets/branding/demo_vid11.mp4',
      name: 'Fashion Studio Pose',
      type: MediaType.video,
      durationMs: 3000, // 00:03
    ),
    const MediaItemEntity(
      path: 'assets/branding/demo_photo1.jpg',
      name: 'Creative Portrait',
      type: MediaType.photo,
      durationMs: 4000,
    ),
    const MediaItemEntity(
      path: 'assets/branding/demo_photo2.jpg',
      name: 'City Skyline',
      type: MediaType.photo,
      durationMs: 4000,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadDeviceMedia();
  }

  Future<void> _loadDeviceMedia() async {
    // Initial fetch from device gallery in background
    try {
      final videos = await _mediaService.pickVideosFromDevice();
      if (mounted && videos.isNotEmpty) {
        setState(() {
          _deviceMediaList.addAll(videos);
        });
      }
    } catch (_) {}
  }

  void _toggleSelection(MediaItemEntity item) {
    setState(() {
      final index = _selectedItems.indexWhere((i) => i.path == item.path);
      if (index >= 0) {
        _selectedItems.removeAt(index);
      } else {
        _selectedItems.add(item);
      }
    });
  }

  Future<void> _pickFromGalleryExplicitly() async {
    setState(() => _isLoading = true);
    final picked = _activeSubTab == _PickerSubTab.videos
        ? await _mediaService.pickVideosFromDevice()
        : await _mediaService.pickPhotosFromDevice();

    if (mounted) {
      setState(() {
        _isLoading = false;
        for (final m in picked) {
          if (!_deviceMediaList.any((e) => e.path == m.path)) {
            _deviceMediaList.insert(0, m);
          }
          if (!_selectedItems.any((e) => e.path == m.path)) {
            _selectedItems.add(m);
          }
        }
      });
    }
  }

  Future<void> _captureCamera() async {
    setState(() => _isLoading = true);
    final item = _activeSubTab == _PickerSubTab.videos
        ? await _mediaService.captureVideoWithCamera()
        : await _mediaService.capturePhotoWithCamera();

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (item != null) {
          _deviceMediaList.insert(0, item);
          _selectedItems.add(item);
        }
      });
    }
  }

  void _showAlbumSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161822),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final albums = [
          {'name': 'All Media', 'icon': Icons.perm_media, 'count': '248'},
          {'name': 'Videos', 'icon': Icons.videocam, 'count': '86'},
          {'name': 'Photos', 'icon': Icons.photo, 'count': '162'},
          {'name': 'Camera', 'icon': Icons.camera_alt, 'count': '94'},
          {'name': 'Downloads', 'icon': Icons.download_done, 'count': '42'},
          {'name': 'WhatsApp', 'icon': Icons.chat, 'count': '58'},
          {'name': 'Screenshots', 'icon': Icons.screenshot, 'count': '25'},
        ];

        return Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Select Album',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const Divider(color: Colors.white12),
              ...albums.map((alb) {
                final isSelected = _selectedAlbum == alb['name'];
                return ListTile(
                  leading: Icon(
                    alb['icon'] as IconData,
                    color: isSelected ? const Color(0xFF00C2CB) : Colors.white70,
                  ),
                  title: Text(
                    alb['name'] as String,
                    style: TextStyle(
                      color: isSelected ? const Color(0xFF00C2CB) : Colors.white,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  trailing: Text(
                    alb['count'] as String,
                    style: const TextStyle(color: Colors.white38, fontSize: 13),
                  ),
                  onTap: () {
                    setState(() => _selectedAlbum = alb['name'] as String);
                    Navigator.of(ctx).pop();
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  void _showScriptToVideoDialog() {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1C24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF00C2CB).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.auto_stories, color: Color(0xFF00C2CB), size: 20),
            ),
            const SizedBox(width: 10),
            const Text('Script to Video AI', style: TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter a story or prompt. Looma AI will generate cinematic storyboard clips for your timeline.',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: textController,
              maxLines: 4,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'e.g. A fast-paced travel vlog exploring Tokyo neon night street...',
                hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                filled: true,
                fillColor: const Color(0xFF262934),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              // Generate script clips and add to project
              final generatedClips = [
                MediaItemEntity(
                  path: 'assets/branding/demo_vid1.mp4',
                  name: 'AI Scene: ${textController.text.isNotEmpty ? textController.text.split(" ").take(3).join(" ") : "Intro Scene"}',
                  type: MediaType.video,
                  durationMs: 6000,
                ),
                const MediaItemEntity(
                  path: 'assets/branding/demo_vid7.mp4',
                  name: 'AI Scene: Cinematic Atmosphere',
                  type: MediaType.video,
                  durationMs: 7000,
                ),
              ];
              widget.onMediaSelected(generatedClips);
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00C2CB),
              foregroundColor: Colors.black,
            ),
            child: const Text('Generate & Add', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  List<MediaItemEntity> _getDisplayMediaList() {
    final all = [..._deviceMediaList, ..._demoMediaList];
    if (_activeSubTab == _PickerSubTab.videos) {
      return all.where((m) => m.type == MediaType.video).toList();
    } else {
      return all.where((m) => m.type == MediaType.photo).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaList = _getDisplayMediaList();
    final selectedCount = _selectedItems.length;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        bottom: true,
        child: Column(
          children: [
            // 1. Top Bar: [✕]   [ Albums ⌄ ]  [ Spaces • ]  [ Library ]
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              color: Colors.black,
              child: Row(
                children: [
                  // Close Button (✕)
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 24),
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  ),

                  // Top Centered Tabs (Albums ⌄ | Spaces • | Library)
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Albums Dropdown Pill (Rounded dark pill with white text & down icon)
                            InkWell(
                              onTap: _showAlbumSelector,
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E2028),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _selectedAlbum,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(width: 3),
                                    Container(
                                      padding: const EdgeInsets.all(1),
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.keyboard_arrow_down, color: Colors.black, size: 12),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),

                            // Spaces Tab with Amber/Yellow Dot
                            InkWell(
                              onTap: () => setState(() => _activeTopTab = _PickerTopTab.spaces),
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Text(
                                      'Spaces',
                                      style: TextStyle(
                                        color: _activeTopTab == _PickerTopTab.spaces ? Colors.white : const Color(0xFF8E95A5),
                                        fontSize: 14,
                                        fontWeight: _activeTopTab == _PickerTopTab.spaces ? FontWeight.bold : FontWeight.w500,
                                      ),
                                    ),
                                    // Amber Dot
                                    Positioned(
                                      top: -2,
                                      right: -6,
                                      child: Container(
                                        width: 5,
                                        height: 5,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFFFB800),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),

                            // Library Tab
                            InkWell(
                              onTap: () => setState(() => _activeTopTab = _PickerTopTab.library),
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                                child: Text(
                                  'Library',
                                  style: TextStyle(
                                    color: _activeTopTab == _PickerTopTab.library ? Colors.white : const Color(0xFF8E95A5),
                                    fontSize: 14,
                                    fontWeight: _activeTopTab == _PickerTopTab.library ? FontWeight.bold : FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 36),
                ],
              ),
            ),

            // 2. Sub Tabs: [ Videos ] (Cyan Indicator) | [ Photos ]
            Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              color: Colors.black,
              child: Row(
                children: [
                  // Videos Sub-tab
                  GestureDetector(
                    onTap: () => setState(() => _activeSubTab = _PickerSubTab.videos),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Videos',
                            style: TextStyle(
                              color: _activeSubTab == _PickerSubTab.videos ? const Color(0xFF00C2CB) : const Color(0xFF8E95A5),
                              fontSize: 14.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            height: 2.5,
                            width: 52,
                            decoration: BoxDecoration(
                              color: _activeSubTab == _PickerSubTab.videos ? const Color(0xFF00C2CB) : Colors.transparent,
                              borderRadius: BorderRadius.circular(1.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Photos Sub-tab
                  GestureDetector(
                    onTap: () => setState(() => _activeSubTab = _PickerSubTab.photos),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Photos',
                            style: TextStyle(
                              color: _activeSubTab == _PickerSubTab.photos ? const Color(0xFF00C2CB) : const Color(0xFF8E95A5),
                              fontSize: 14.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            height: 2.5,
                            width: 52,
                            decoration: BoxDecoration(
                              color: _activeSubTab == _PickerSubTab.photos ? const Color(0xFF00C2CB) : Colors.transparent,
                              borderRadius: BorderRadius.circular(1.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),

                  // Quick gallery picker action icon
                  IconButton(
                    icon: const Icon(Icons.add_photo_alternate_outlined, color: Colors.white70, size: 20),
                    tooltip: 'Import from Device',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    onPressed: _pickFromGalleryExplicitly,
                  ),
                  IconButton(
                    icon: const Icon(Icons.camera_alt_outlined, color: Colors.white70, size: 20),
                    tooltip: 'Capture Camera',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    onPressed: _captureCamera,
                  ),
                ],
              ),
            ),

            const Divider(color: Color(0xFF181A22), height: 1),

            // 3. 3-Column Square Media Grid (CapCut style)
            Expanded(
              child: Stack(
                children: [
                  GridView.builder(
                    padding: const EdgeInsets.all(1.5),
                    physics: const BouncingScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 1.5,
                      mainAxisSpacing: 1.5,
                      childAspectRatio: 1.0,
                    ),
                    itemCount: mediaList.length,
                    itemBuilder: (context, index) {
                      final item = mediaList[index];
                      final isSelected = _selectedItems.any((i) => i.path == item.path);
                      final selectedIndex = _selectedItems.indexWhere((i) => i.path == item.path);

                      return _buildMediaGridTile(
                        item: item,
                        isSelected: isSelected,
                        selectedIndex: selectedIndex >= 0 ? selectedIndex + 1 : null,
                        onTap: () => _toggleSelection(item),
                      );
                    },
                  ),

                  if (_isLoading)
                    Container(
                      color: Colors.black45,
                      child: const Center(
                        child: CircularProgressIndicator(color: Color(0xFF00C2CB)),
                      ),
                    ),
                ],
              ),
            ),

            // 4. Bottom Floating Option Row: [ ○ HD ]   [ Add / Add (1) ]
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.black,
              child: Row(
                children: [
                  const Spacer(),

                  // HD Toggle Radio Button
                  GestureDetector(
                    onTap: () => setState(() => _isHdEnabled = !_isHdEnabled),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _isHdEnabled ? const Color(0xFF00C2CB) : Colors.white38,
                              width: 1.5,
                            ),
                          ),
                          child: _isHdEnabled
                              ? Center(
                                  child: Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF00C2CB),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'HD',
                          style: TextStyle(
                            color: _isHdEnabled ? Colors.white : Colors.white60,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Teal Rounded "Add" Button
                  ElevatedButton(
                    onPressed: selectedCount > 0
                        ? () {
                            widget.onMediaSelected(_selectedItems);
                            Navigator.of(context).pop();
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00838F),
                      disabledBackgroundColor: const Color(0xFF1E282D),
                      foregroundColor: Colors.white,
                      disabledForegroundColor: Colors.white30,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 9),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      selectedCount > 0 ? '${widget.actionLabel} ($selectedCount)' : widget.actionLabel,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),

            // 5. Fixed Bottom Navigation Bar: [ 🖼 Add media ]  [ 🔤 Script to video ]
            Container(
              decoration: const BoxDecoration(
                color: Colors.black,
                border: Border(top: BorderSide(color: Color(0xFF1A1C24))),
              ),
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  // Add media (Active)
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _activeBottomNav = _PickerBottomNav.addMedia),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.image_outlined,
                                size: 18,
                                color: _activeBottomNav == _PickerBottomNav.addMedia
                                    ? Colors.white
                                    : const Color(0xFF8E95A5),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Add media',
                                style: TextStyle(
                                  color: _activeBottomNav == _PickerBottomNav.addMedia
                                      ? Colors.white
                                      : const Color(0xFF8E95A5),
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Container(
                            height: 2,
                            width: 24,
                            decoration: BoxDecoration(
                              color: _activeBottomNav == _PickerBottomNav.addMedia
                                  ? const Color(0xFF00C2CB)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Script to video
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        setState(() => _activeBottomNav = _PickerBottomNav.scriptToVideo);
                        _showScriptToVideoDialog();
                      },
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.text_fields, size: 18, color: Color(0xFF8E95A5)),
                              SizedBox(width: 6),
                              Text(
                                'Script to video',
                                style: TextStyle(
                                  color: Color(0xFF8E95A5),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 6),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaGridTile({
    required MediaItemEntity item,
    required bool isSelected,
    required int? selectedIndex,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: () => _openMediaPreview(item),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Thumbnail Image, Real Device Video Frame, or Synthetic Dynamic Pattern
          _buildThumbnailImage(item),

          // 2. Subtle Dark Vignette / Gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withValues(alpha: 0.08),
                  Colors.black.withValues(alpha: 0.65),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              border: isSelected
                  ? Border.all(color: const Color(0xFF00C2CB), width: 2.5)
                  : null,
            ),
          ),

          // 3. Selection Check Circle (Top Right)
          Positioned(
            top: 6,
            right: 6,
            child: GestureDetector(
              onTap: onTap,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? const Color(0xFF00C2CB) : Colors.black38,
                  border: Border.all(
                    color: isSelected ? const Color(0xFF00C2CB) : Colors.white.withValues(alpha: 0.85),
                    width: 1.5,
                  ),
                ),
                child: isSelected
                    ? Center(
                        child: Text(
                          selectedIndex != null ? '$selectedIndex' : '✓',
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    : null,
              ),
            ),
          ),

          // 4. Quick Preview Eye Button (Top Left)
          Positioned(
            top: 6,
            left: 6,
            child: GestureDetector(
              onTap: () => _openMediaPreview(item),
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white24, width: 1),
                ),
                child: const Icon(Icons.remove_red_eye_outlined, color: Colors.white70, size: 12),
              ),
            ),
          ),

          // 5. Duration Badge (Bottom Right)
          if (item.type == MediaType.video)
            Positioned(
              bottom: 6,
              right: 6,
              child: Text(
                _formatTimecodeDuration(item.durationMs),
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'monospace',
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(color: Colors.black, blurRadius: 4, offset: Offset(1, 1)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _openMediaPreview(MediaItemEntity item) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => _MediaPreviewModalDialog(
        item: item,
        isSelected: _selectedItems.any((i) => i.path == item.path),
        onToggleSelect: () {
          _toggleSelection(item);
          Navigator.of(ctx).pop();
        },
      ),
    );
  }

  String _formatTimecodeDuration(int durationMs) {
    final totalSec = (durationMs / 1000).round();
    final mins = (totalSec ~/ 60).toString().padLeft(2, '0');
    final secs = (totalSec % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  Widget _buildThumbnailImage(MediaItemEntity item) {
    if (item.type == MediaType.video) {
      if (item.path.startsWith('assets/')) {
        return _AssetVideoThumbnail(assetPath: item.path, fallback: _buildFallbackThumbnail(item));
      } else if (File(item.path).existsSync()) {
        return _DeviceVideoThumbnail(filePath: item.path, fallback: _buildFallbackThumbnail(item));
      }
    } else {
      if (item.path.startsWith('assets/')) {
        return Image.asset(
          item.path,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _buildFallbackThumbnail(item),
        );
      } else if (File(item.path).existsSync()) {
        return Image.file(
          File(item.path),
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _buildFallbackThumbnail(item),
        );
      }
    }
    return _buildFallbackThumbnail(item);
  }

  Widget _buildFallbackThumbnail(MediaItemEntity item) {
    final hash = item.name.hashCode.abs();
    final palettes = [
      [const Color(0xFF1F1C2C), const Color(0xFF928DAB)],
      [const Color(0xFF141E30), const Color(0xFF243B55)],
      [const Color(0xFF200122), const Color(0xFF6F0000)],
      [const Color(0xFF0F2027), const Color(0xFF2C5364)],
      [const Color(0xFF2C3E50), const Color(0xFF4CA1AF)],
      [const Color(0xFF1D2671), const Color(0xFFC33764)],
    ];
    final selectedPalette = palettes[hash % palettes.length];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: selectedPalette,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          item.type == MediaType.video ? Icons.videocam : Icons.photo,
          color: Colors.white24,
          size: 28,
        ),
      ),
    );
  }
}

/// Lightweight video thumbnail generator for device video files
class _DeviceVideoThumbnail extends StatefulWidget {
  final String filePath;
  final Widget fallback;

  const _DeviceVideoThumbnail({required this.filePath, required this.fallback});

  @override
  State<_DeviceVideoThumbnail> createState() => _DeviceVideoThumbnailState();
}

class _DeviceVideoThumbnailState extends State<_DeviceVideoThumbnail> {
  VideoPlayerController? _controller;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initThumbnail();
  }

  Future<void> _initThumbnail() async {
    try {
      final file = File(widget.filePath);
      if (!file.existsSync()) return;
      final controller = VideoPlayerController.file(file);
      await controller.initialize();
      if (mounted) {
        setState(() {
          _controller = controller;
          _initialized = true;
        });
      } else {
        await controller.dispose();
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_initialized && _controller != null) {
      return FittedBox(
        fit: BoxFit.cover,
        clipBehavior: Clip.hardEdge,
        child: SizedBox(
          width: _controller!.value.size.width,
          height: _controller!.value.size.height,
          child: VideoPlayer(_controller!),
        ),
      );
    }
    return widget.fallback;
  }
}

/// Lightweight video thumbnail generator for asset videos
class _AssetVideoThumbnail extends StatefulWidget {
  final String assetPath;
  final Widget fallback;

  const _AssetVideoThumbnail({required this.assetPath, required this.fallback});

  @override
  State<_AssetVideoThumbnail> createState() => _AssetVideoThumbnailState();
}

class _AssetVideoThumbnailState extends State<_AssetVideoThumbnail> {
  VideoPlayerController? _controller;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initThumbnail();
  }

  Future<void> _initThumbnail() async {
    try {
      final controller = VideoPlayerController.asset(widget.assetPath);
      await controller.initialize();
      if (mounted) {
        setState(() {
          _controller = controller;
          _initialized = true;
        });
      } else {
        await controller.dispose();
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_initialized && _controller != null) {
      return FittedBox(
        fit: BoxFit.cover,
        clipBehavior: Clip.hardEdge,
        child: SizedBox(
          width: _controller!.value.size.width,
          height: _controller!.value.size.height,
          child: VideoPlayer(_controller!),
        ),
      );
    }
    return widget.fallback;
  }
}

/// Full interactive video & photo preview dialog
class _MediaPreviewModalDialog extends StatefulWidget {
  final MediaItemEntity item;
  final bool isSelected;
  final VoidCallback onToggleSelect;

  const _MediaPreviewModalDialog({
    required this.item,
    required this.isSelected,
    required this.onToggleSelect,
  });

  @override
  State<_MediaPreviewModalDialog> createState() => _MediaPreviewModalDialogState();
}

class _MediaPreviewModalDialogState extends State<_MediaPreviewModalDialog> {
  VideoPlayerController? _videoController;
  bool _isPlaying = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    if (widget.item.type == MediaType.video) {
      _initVideo();
    }
  }

  Future<void> _initVideo() async {
    try {
      final path = widget.item.path;
      VideoPlayerController controller;
      if (path.startsWith('assets/')) {
        controller = VideoPlayerController.asset(path);
      } else if (File(path).existsSync()) {
        controller = VideoPlayerController.file(File(path));
      } else {
        return;
      }

      await controller.initialize();
      controller.setLooping(true);
      await controller.play();
      if (mounted) {
        setState(() {
          _videoController = controller;
          _isInitialized = true;
          _isPlaying = true;
        });
      } else {
        await controller.dispose();
      }
    } catch (e) {
      debugPrint('Media preview init error: $e');
    }
  }

  @override
  void dispose() {
    _videoController?.pause();
    _videoController?.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    if (_videoController == null) return;
    if (_videoController!.value.isPlaying) {
      _videoController!.pause();
      setState(() => _isPlaying = false);
    } else {
      _videoController!.play();
      setState(() => _isPlaying = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF10121A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white12),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.item.name,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                ],
              ),
            ),

            // Media Preview Frame
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(
                color: Colors.black,
                child: widget.item.type == MediaType.video
                    ? (_isInitialized && _videoController != null
                        ? GestureDetector(
                            onTap: _togglePlayPause,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Center(
                                  child: AspectRatio(
                                    aspectRatio: _videoController!.value.aspectRatio,
                                    child: VideoPlayer(_videoController!),
                                  ),
                                ),
                                if (!_isPlaying)
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: const BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.play_arrow, color: Colors.white, size: 36),
                                  ),
                              ],
                            ),
                          )
                        : const Center(
                            child: CircularProgressIndicator(color: Color(0xFF00C2CB)),
                          ))
                    : (widget.item.path.startsWith('assets/')
                        ? Image.asset(widget.item.path, fit: BoxFit.contain)
                        : (File(widget.item.path).existsSync()
                            ? Image.file(File(widget.item.path), fit: BoxFit.contain)
                            : const Center(child: Icon(Icons.photo, color: Colors.white30, size: 48)))),
              ),
            ),

            // Bottom Actions: [ Select / Deselect & Add ]
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Text(
                    '${(widget.item.durationMs / 1000).toStringAsFixed(1)}s',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: widget.onToggleSelect,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.isSelected ? const Color(0xFFFF5252) : const Color(0xFF00838F),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    ),
                    child: Text(
                      widget.isSelected ? 'Remove from Selection' : 'Select Media',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
