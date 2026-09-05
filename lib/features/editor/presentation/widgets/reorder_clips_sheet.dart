import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/utils/timecode_formatter.dart';
import '../../domain/entities/video_clip_entity.dart';
import '../providers/editor_controller.dart';

class ReorderClipsSheet extends StatefulWidget {
  final List<VideoClipEntity> clips;
  final EditorController controller;
  final String? selectedClipId;

  const ReorderClipsSheet({
    super.key,
    required this.clips,
    required this.controller,
    this.selectedClipId,
  });

  @override
  State<ReorderClipsSheet> createState() => _ReorderClipsSheetState();
}

class _ReorderClipsSheetState extends State<ReorderClipsSheet> {
  late List<VideoClipEntity> _clips;

  @override
  void initState() {
    super.initState();
    _clips = List.from(widget.clips);
  }

  void _onReorderItem(int oldIndex, int newIndex) {
    setState(() {
      final item = _clips.removeAt(oldIndex);
      _clips.insert(newIndex, item);
    });
    widget.controller.reorderVideoClips(oldIndex, newIndex);
  }

  void _moveClip(int currentIndex, int targetIndex) {
    if (targetIndex < 0 || targetIndex >= _clips.length || currentIndex == targetIndex) return;
    setState(() {
      final item = _clips.removeAt(currentIndex);
      _clips.insert(targetIndex, item);
    });
    widget.controller.reorderVideoClips(currentIndex, targetIndex);
  }

  bool _isImage(String path) {
    final lower = path.toLowerCase();
    return lower.endsWith('.jpg') || lower.endsWith('.jpeg') || lower.endsWith('.png') || lower.endsWith('.webp');
  }

  @override
  Widget build(BuildContext context) {
    final totalDurationMs = _clips.fold<int>(0, (sum, c) => sum + c.effectiveDurationMs);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isNarrow = screenWidth < 360;
    final horizontalPadding = isNarrow ? 12.0 : 20.0;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.75,
        color: const Color(0xFF141724),
        child: Column(
          children: [
            // Top Grab Handle
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header Row
            Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.reorder, color: AppColors.primary, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Reorder Clips',
                                style: AppTypography.titleMedium.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${_clips.length} clips • ${TimecodeFormatter.formatMmSsMs(totalDurationMs)}',
                                style: const TextStyle(color: Colors.white54, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.check_circle, color: Color(0xFF00E5FF), size: 28),
                    tooltip: 'Done',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Reorder Instructions Banner
            Container(
              margin: EdgeInsets.symmetric(horizontal: horizontalPadding),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF1E2130),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.touch_app, color: Color(0xFF00E5FF), size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Drag the handle (≡) or use arrow buttons to rearrange clip order.',
                      style: TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Reorderable Clip List
            Expanded(
              child: ReorderableListView.builder(
                padding: EdgeInsets.fromLTRB(horizontalPadding, 0, horizontalPadding, 20),
                itemCount: _clips.length,
                onReorderItem: _onReorderItem,
                proxyDecorator: (child, index, animation) {
                  return Material(
                    color: Colors.transparent,
                    elevation: 6,
                    shadowColor: Colors.black54,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF262B40),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFF00E5FF), width: 2),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x6600E5FF),
                            blurRadius: 16,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: child,
                    ),
                  );
                },
                itemBuilder: (context, index) {
                  final clip = _clips[index];
                  final isFirst = index == 0;
                  final isLast = index == _clips.length - 1;
                  final isSelected = clip.id == widget.selectedClipId;

                  return Container(
                    key: ValueKey(clip.id),
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF23283E) : const Color(0xFF1E2130),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : Colors.white10,
                        width: isSelected ? 1.5 : 1.0,
                      ),
                    ),
                    child: ListTile(
                      contentPadding: EdgeInsets.symmetric(horizontal: isNarrow ? 6 : 8, vertical: 2),
                      minLeadingWidth: 0,
                      horizontalTitleGap: isNarrow ? 6 : 8,
                      // 1. Position Number & Thumbnail
                      leading: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primary : const Color(0xFF2B3148),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isSelected ? const Color(0xFF00E5FF) : Colors.white24,
                                width: 1,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '#${index + 1}',
                              style: TextStyle(
                                color: isSelected ? Colors.black : Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 9,
                              ),
                            ),
                          ),
                          SizedBox(width: isNarrow ? 5 : 8),
                          // Thumbnail box
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              width: 40,
                              height: 40,
                              color: const Color(0xFF273147),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  if (clip.mediaPath.startsWith('assets/'))
                                    Image.asset(clip.mediaPath, fit: BoxFit.cover, errorBuilder: (_, _, _) => const Icon(Icons.movie, size: 18, color: Colors.white30))
                                  else if (File(clip.mediaPath).existsSync())
                                    Image.file(File(clip.mediaPath), fit: BoxFit.cover, errorBuilder: (_, _, _) => const Icon(Icons.movie, size: 18, color: Colors.white30))
                                  else
                                    Icon(
                                      _isImage(clip.mediaPath) ? Icons.photo : Icons.videocam,
                                      size: 18,
                                      color: Colors.white38,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      // 2. Title & Duration
                      title: Text(
                        clip.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              TimecodeFormatter.formatMmSsMs(clip.effectiveDurationMs),
                              style: const TextStyle(
                                color: Color(0xFF00E5FF),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (clip.speed != 1.0) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  color: AppColors.accent,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: Text(
                                  '${clip.speed}x',
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      // 3. Quick Move Action Arrows & Reorder Drag Handle
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Move to Beginning (⏮)
                          if (!isFirst)
                            InkWell(
                              key: ValueKey('move_start_${clip.id}'),
                              onTap: () => _moveClip(index, 0),
                              borderRadius: BorderRadius.circular(4),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 2.0, vertical: 4.0),
                                child: Icon(Icons.first_page, size: 19, color: Colors.white70),
                              ),
                            ),
                          // Move Earlier / Left (▲ / ◀)
                          InkWell(
                            key: ValueKey('move_up_${clip.id}'),
                            onTap: isFirst ? null : () => _moveClip(index, index - 1),
                            borderRadius: BorderRadius.circular(4),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 2.0, vertical: 4.0),
                              child: Icon(
                                Icons.keyboard_arrow_up,
                                size: 20,
                                color: isFirst ? Colors.white24 : Colors.white,
                              ),
                            ),
                          ),
                          // Move Later / Right (▼ / ▶)
                          InkWell(
                            key: ValueKey('move_down_${clip.id}'),
                            onTap: isLast ? null : () => _moveClip(index, index + 1),
                            borderRadius: BorderRadius.circular(4),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 2.0, vertical: 4.0),
                              child: Icon(
                                Icons.keyboard_arrow_down,
                                size: 20,
                                color: isLast ? Colors.white24 : Colors.white,
                              ),
                            ),
                          ),
                          // Move to End (⏭)
                          if (!isLast)
                            InkWell(
                              key: ValueKey('move_end_${clip.id}'),
                              onTap: () => _moveClip(index, _clips.length - 1),
                              borderRadius: BorderRadius.circular(4),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 2.0, vertical: 4.0),
                                child: Icon(Icons.last_page, size: 19, color: Colors.white70),
                              ),
                            ),
                          const SizedBox(width: 3),
                          // Reorder Drag Handle Icon
                          ReorderableDragStartListener(
                            index: index,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(Icons.drag_handle, color: Colors.white70, size: 18),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
