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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeCategoryItems = stickerCollections[_selectedCategoryIndex];

    final filteredItems = _searchQuery.isEmpty
        ? activeCategoryItems
        : stickerCollections.expand((list) => list).where((s) => s.contains(_searchQuery)).toSet().toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.emoji_emotions, color: AppColors.primary, size: 22),
                  const SizedBox(width: 8),
                  Text('Gboard Stickers & Emojis', style: AppTypography.titleMedium),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 10),

          TextField(
            controller: _searchController,
            onChanged: (val) => setState(() => _searchQuery = val.trim()),
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Search stickers & emojis...',
              hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
              prefixIcon: const Icon(Icons.search, color: Colors.white54, size: 18),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.white54, size: 16),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.surfaceBorder),
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
                      backgroundColor: AppColors.surface,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppColors.textSecondary,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
                        positionX: 100 + (index * 10),
                        positionY: 120 + (index * 10),
                        scale: 1.0,
                      ),
                    );
                    Navigator.of(context).pop();
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.surfaceBorder),
                    ),
                    child: Center(
                      child: Text(
                        item,
                        style: const TextStyle(fontSize: 28),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
