import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/utils/id_generator.dart';
import '../../domain/entities/photo_sticker_overlay_entity.dart';
import '../providers/photo_editor_controller.dart';

class PhotoStickerSheet extends StatefulWidget {
  final PhotoEditorController controller;

  const PhotoStickerSheet({
    super.key,
    required this.controller,
  });

  @override
  State<PhotoStickerSheet> createState() => _PhotoStickerSheetState();
}

class _PhotoStickerSheetState extends State<PhotoStickerSheet> {
  int _selectedCategoryIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isShapeMode = false;
  int _selectedShapeColorHex = 0xFF00C2CB;
  double _shapeOpacity = 1.0;

  static const List<String> categories = [
    '🔥 Emojis',
    '✨ Trending',
    '🎯 Pointers',
    '🎙️ Creator',
    '🐶 Animals',
    '🍕 Food',
    '🎮 Gaming',
    '⚡ Neon',
    '🌸 Aesthetics',
    '🏷️ Badges',
  ];

  static const List<List<String>> stickerCollections = [
    ['😍', '🔥', '✨', '🚀', '💯', '👑', '🎉', '❤️', '😎', '🌟', '🌈', '⚡', '🤯', '😂', '🥳', '🤩', '😜', '🫡', '🫠', '🤫'],
    ['🚀', '⚡', '👑', '💎', '💯', '🍿', '📸', '🏆', '🎆', '🌈', '🌟', '🪄', '💖', '🔥', '🎁'],
    ['👉', '👇', '🎯', '📍', '⚠️', '✅', '❌', '❓', '❗', '🔔', '🏷️', '🔄'],
    ['🎙️', '🎧', '🎵', '🎬', '👍', '📹', '📼', '📻', '📢', '🎨', '🎞️', '💡'],
    ['🐱', '🐶', '🐼', '🦁', '🐰', '🦄', '🐨', '🦊', '🦋', '🐬', '🦉', '🐯'],
    ['🍕', '🍔', '🧋', '☕', '🍦', '🍩', '🌮', '🎂', '🍣', '🥑', '🍟', '🍜'],
    ['🎮', '🕹️', '🥽', '👽', '🤖', '💀', '⚔️', '🔋', '💻', '🛰️', '💿', '🛡️'],
    ['💖', '☠️', '🌩️', '🌌', '🪐', '👁️‍🗨️', '🔮', '☄️'],
    ['🌸', '🌻', '🌴', '⛅', '🌙', '🌊', '🌿', '🌺'],
    ['🆕', '🔥', '🔝', '🎁', '👑', '⚡', '😎', '🏷️'],
  ];

  static const List<Map<String, dynamic>> shapes = [
    {'type': 'circle', 'name': 'Circle', 'icon': Icons.circle},
    {'type': 'rect', 'name': 'Rectangle', 'icon': Icons.crop_din},
    {'type': 'roundedRect', 'name': 'Rounded', 'icon': Icons.crop_square_rounded},
    {'type': 'star', 'name': 'Star', 'icon': Icons.star},
    {'type': 'heart', 'name': 'Heart', 'icon': Icons.favorite},
    {'type': 'arrow', 'name': 'Arrow', 'icon': Icons.arrow_forward},
    {'type': 'speechBubble', 'name': 'Bubble', 'icon': Icons.chat_bubble},
  ];

  static const List<int> shapeColors = [
    0xFF00C2CB, // Cyan
    0xFFFF3B5C, // Neon Red
    0xFFFFB800, // Gold
    0xFF10B981, // Green
    0xFF8B5CF6, // Purple
    0xFFFFFFFF, // White
    0xFF111827, // Black
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _addShape(String shapeType) {
    widget.controller.addStickerOverlay(
      PhotoStickerOverlayEntity(
        id: IdGenerator.generate(),
        assetPath: shapeType,
        isShape: true,
        shapeType: shapeType,
        colorHex: _selectedShapeColorHex,
        opacity: _shapeOpacity,
        positionX: 120,
        positionY: 150,
        scale: 1.0,
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final activeCategoryItems = stickerCollections[_selectedCategoryIndex];
    final filteredItems = _searchQuery.isEmpty
        ? activeCategoryItems
        : stickerCollections.expand((list) => list).where((s) => s.contains(_searchQuery)).toSet().toList();

    return SafeArea(
      top: false,
      bottom: true,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.68,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.emoji_emotions, color: AppColors.primary, size: 22),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Gboard Stickers & Emojis',
                          style: AppTypography.titleMedium.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textPrimary),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Mode Selector: Stickers vs Vector Shapes
            Container(
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF1E212E),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => setState(() => _isShapeMode = false),
                      child: Container(
                        decoration: BoxDecoration(
                          color: !_isShapeMode ? AppColors.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Center(
                          child: Text(
                            'Stickers & Emojis',
                            style: TextStyle(
                              color: !_isShapeMode ? Colors.white : Colors.white70,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => setState(() => _isShapeMode = true),
                      child: Container(
                        decoration: BoxDecoration(
                          color: _isShapeMode ? AppColors.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Center(
                          child: Text(
                            'Vector Shapes',
                            style: TextStyle(
                              color: _isShapeMode ? Colors.white : Colors.white70,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            if (!_isShapeMode) ...[
              // Search Field
              TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val.trim()),
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Search stickers & emojis...',
                  hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary, size: 18),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: AppColors.textSecondary, size: 16),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  filled: true,
                  fillColor: AppColors.surfaceElevated,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.surfaceBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.surfaceBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              if (_searchQuery.isEmpty)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: List.generate(categories.length, (idx) {
                      final isSelected = _selectedCategoryIndex == idx;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(categories[idx]),
                          selected: isSelected,
                          onSelected: (_) => setState(() => _selectedCategoryIndex = idx),
                          selectedColor: AppColors.primary,
                          backgroundColor: AppColors.surfaceElevated,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : AppColors.textPrimary,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            fontSize: 11,
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              const SizedBox(height: 12),

              Expanded(
                child: GridView.builder(
                  physics: const BouncingScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.1,
                  ),
                  itemCount: filteredItems.length,
                  itemBuilder: (context, index) {
                    final item = filteredItems[index];
                    return InkWell(
                      onTap: () {
                        widget.controller.addStickerOverlay(
                          PhotoStickerOverlayEntity(
                            id: IdGenerator.generate(),
                            assetPath: item,
                            positionX: 100 + (index * 8),
                            positionY: 120 + (index * 8),
                            scale: 1.0,
                          ),
                        );
                        Navigator.of(context).pop();
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.surfaceBorder),
                        ),
                        child: Center(
                          child: Text(item, style: const TextStyle(fontSize: 28)),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ] else ...[
              // Vector Shapes Mode
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('SHAPE COLOR', style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: shapeColors.map((hex) {
                        final isSelected = _selectedShapeColorHex == hex;
                        return Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedShapeColorHex = hex),
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: Color(hex),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected ? Colors.white : Colors.transparent,
                                  width: 2.0,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('SHAPE OPACITY', style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                  Text('${(_shapeOpacity * 100).round()}%', style: AppTypography.labelSmall.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                ],
              ),
              Slider(
                value: _shapeOpacity,
                min: 0.1,
                max: 1.0,
                activeColor: AppColors.primary,
                onChanged: (val) => setState(() => _shapeOpacity = val),
              ),
              const SizedBox(height: 10),

              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.2,
                  ),
                  itemCount: shapes.length,
                  itemBuilder: (context, index) {
                    final item = shapes[index];
                    return InkWell(
                      onTap: () => _addShape(item['type'] as String),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.surfaceBorder),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(item['icon'] as IconData, size: 28, color: Color(_selectedShapeColorHex)),
                            const SizedBox(height: 4),
                            Text(item['name'] as String, style: const TextStyle(color: Colors.white70, fontSize: 11)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
