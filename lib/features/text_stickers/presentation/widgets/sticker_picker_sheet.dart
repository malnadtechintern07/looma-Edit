import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';

class StickerItem {
  final String key;
  final String name;
  final String emojiOrGraphic;
  final String category;

  const StickerItem(this.key, this.name, this.emojiOrGraphic, this.category);
}

class StickerPickerSheet extends StatefulWidget {
  final Function(String key, String name, String emoji) onStickerSelected;

  const StickerPickerSheet({super.key, required this.onStickerSelected});

  @override
  State<StickerPickerSheet> createState() => _StickerPickerSheetState();
}

class _StickerPickerSheetState extends State<StickerPickerSheet> {
  String _activeCategory = '🔥 Expressions';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<String> _categories = const [
    '🔥 Expressions',
    '✨ Trending',
    '🎯 Arrows & Tags',
    '🎙️ Creator Vibes',
    '🐶 Animals & Pets',
    '🍕 Food & Drinks',
    '🎮 Gaming & Tech',
    '⚡ Neon & Cyber',
    '🌸 Nature & Vibe',
    '🏷️ Badges & Labels',
  ];

  final List<StickerItem> _allStickers = const [
    // 🔥 Expressions
    StickerItem('fire', 'Fire Flame', '🔥', '🔥 Expressions'),
    StickerItem('sparkles', 'Magic Sparkles', '✨', '🔥 Expressions'),
    StickerItem('heart_eyes', 'Love Eyes', '😍', '🔥 Expressions'),
    StickerItem('mind_blown', 'Exploding Head', '🤯', '🔥 Expressions'),
    StickerItem('cool_glasses', 'Cool Shades', '😎', '🔥 Expressions'),
    StickerItem('joy_crying', 'Laughing Crying', '😂', '🔥 Expressions'),
    StickerItem('party_face', 'Celebration Face', '🥳', '🔥 Expressions'),
    StickerItem('star_struck', 'Starstruck', '🤩', '🔥 Expressions'),
    StickerItem('wink_tongue', 'Wink & Tongue', '😜', '🔥 Expressions'),
    StickerItem('salute_face', 'Salute Respect', '🫡', '🔥 Expressions'),
    StickerItem('melting_face', 'Melting Warmth', '🫠', '🔥 Expressions'),
    StickerItem('shushing_face', 'Secret Shh', '🤫', '🔥 Expressions'),

    // ✨ Trending
    StickerItem('rocket', 'Super Rocket', '🚀', '✨ Trending'),
    StickerItem('neon_zap', 'Electric Zap', '⚡', '✨ Trending'),
    StickerItem('crown', 'Royal Crown', '👑', '✨ Trending'),
    StickerItem('diamond', 'Rare Diamond', '💎', '✨ Trending'),
    StickerItem('100', '100 Percent', '💯', '✨ Trending'),
    StickerItem('popcorn', 'Movie Time', '🍿', '✨ Trending'),
    StickerItem('camera_flash', 'Film Camera', '📸', '✨ Trending'),
    StickerItem('trophy', 'Winner Trophy', '🏆', '✨ Trending'),
    StickerItem('firework', 'Fireworks Pop', '🎆', '✨ Trending'),
    StickerItem('rainbow', 'Rainbow Arc', '🌈', '✨ Trending'),
    StickerItem('glowing_star', 'Golden Star', '🌟', '✨ Trending'),
    StickerItem('magic_wand', 'Magic Wand', '🪄', '✨ Trending'),

    // 🎯 Arrows & Tags
    StickerItem('arrow_right', 'Pointer Right', '👉', '🎯 Arrows & Tags'),
    StickerItem('arrow_down', 'Look Down', '👇', '🎯 Arrows & Tags'),
    StickerItem('target', 'Bullseye', '🎯', '🎯 Arrows & Tags'),
    StickerItem('pin', 'Map Pin', '📍', '🎯 Arrows & Tags'),
    StickerItem('warning_badge', 'Caution Warning', '⚠️', '🎯 Arrows & Tags'),
    StickerItem('check_badge', 'Verified Check', '✅', '🎯 Arrows & Tags'),
    StickerItem('cross_mark', 'Red Cross', '❌', '🎯 Arrows & Tags'),
    StickerItem('question_mark', 'Help Question', '❓', '🎯 Arrows & Tags'),
    StickerItem('exclamation', 'Alert Mark', '❗', '🎯 Arrows & Tags'),
    StickerItem('bell_alert', 'Notification Bell', '🔔', '🎯 Arrows & Tags'),
    StickerItem('fire_tag', 'Hot Deal', '🏷️', '🎯 Arrows & Tags'),
    StickerItem('recycling', 'Loop Cycle', '🔄', '🎯 Arrows & Tags'),

    // 🎙️ Creator Vibes
    StickerItem('microphone', 'On Air Mic', '🎙️', '🎙️ Creator Vibes'),
    StickerItem('headphones', 'Studio Phones', '🎧', '🎙️ Creator Vibes'),
    StickerItem('music_notes', 'Melody Notes', '🎵', '🎙️ Creator Vibes'),
    StickerItem('clapperboard', 'Action Cut', '🎬', '🎙️ Creator Vibes'),
    StickerItem('thumbs_up', 'Like & Up', '👍', '🎙️ Creator Vibes'),
    StickerItem('video_cam', 'Pro Cinema', '📹', '🎙️ Creator Vibes'),
    StickerItem('cassette', 'Retro Tape', '📼', '🎙️ Creator Vibes'),
    StickerItem('radio', 'FM Boombox', '📻', '🎙️ Creator Vibes'),
    StickerItem('megaphone', 'Shout Out', '📢', '🎙️ Creator Vibes'),
    StickerItem('palette', 'Art Brush', '🎨', '🎙️ Creator Vibes'),
    StickerItem('camera_vintage', 'Polaroid Instant', '🎞️', '🎙️ Creator Vibes'),
    StickerItem('spotlight', 'Stage Light', '💡', '🎙️ Creator Vibes'),

    // 🐶 Animals & Pets
    StickerItem('cat_face', 'Cute Kitty', '🐱', '🐶 Animals & Pets'),
    StickerItem('dog_face', 'Playful Dog', '🐶', '🐶 Animals & Pets'),
    StickerItem('panda', 'Panda Bear', '🐼', '🐶 Animals & Pets'),
    StickerItem('lion', 'Roaring Lion', '🦁', '🐶 Animals & Pets'),
    StickerItem('rabbit', 'Bunny Hop', '🐰', '🐶 Animals & Pets'),
    StickerItem('unicorn', 'Magic Unicorn', '🦄', '🐶 Animals & Pets'),
    StickerItem('koala', 'Cozy Koala', '🐨', '🐶 Animals & Pets'),
    StickerItem('fox', 'Clever Fox', '🦊', '🐶 Animals & Pets'),
    StickerItem('butterfly', 'Monarch Fly', '🦋', '🐶 Animals & Pets'),
    StickerItem('dolphin', 'Ocean Dolphin', '🐬', '🐶 Animals & Pets'),
    StickerItem('owl', 'Wise Owl', '🦉', '🐶 Animals & Pets'),
    StickerItem('tiger', 'Wild Tiger', '🐯', '🐶 Animals & Pets'),

    // 🍕 Food & Drinks
    StickerItem('pizza', 'Cheese Pizza', '🍕', '🍕 Food & Drinks'),
    StickerItem('burger', 'Juicy Burger', '🍔', '🍕 Food & Drinks'),
    StickerItem('boba_tea', 'Boba Milk Tea', '🧋', '🍕 Food & Drinks'),
    StickerItem('coffee', 'Hot Espresso', '☕', '🍕 Food & Drinks'),
    StickerItem('ice_cream', 'Sweet Cone', '🍦', '🍕 Food & Drinks'),
    StickerItem('donut', 'Glazed Donut', '🍩', '🍕 Food & Drinks'),
    StickerItem('taco', 'Mexican Taco', '🌮', '🍕 Food & Drinks'),
    StickerItem('cake', 'Birthday Cake', '🎂', '🍕 Food & Drinks'),
    StickerItem('sushi', 'Fresh Sushi', '🍣', '🍕 Food & Drinks'),
    StickerItem('avocado', 'Healthy Avo', '🥑', '🍕 Food & Drinks'),
    StickerItem('fries', 'Crispy Fries', '🍟', '🍕 Food & Drinks'),
    StickerItem('ramen', 'Hot Noodles', '🍜', '🍕 Food & Drinks'),

    // 🎮 Gaming & Tech
    StickerItem('controller', 'Game Controller', '🎮', '🎮 Gaming & Tech'),
    StickerItem('joystick', 'Arcade Stick', '🕹️', '🎮 Gaming & Tech'),
    StickerItem('vr_headset', 'VR Metaverse', '🥽', '🎮 Gaming & Tech'),
    StickerItem('alien', 'Space Invader', '👽', '🎮 Gaming & Tech'),
    StickerItem('robot', 'Cyber Robot', '🤖', '🎮 Gaming & Tech'),
    StickerItem('skull', 'GameOver Skull', '💀', '🎮 Gaming & Tech'),
    StickerItem('sword', 'Pixel Sword', '⚔️', '🎮 Gaming & Tech'),
    StickerItem('battery', 'Full Charge', '🔋', '🎮 Gaming & Tech'),
    StickerItem('laptop', 'Developer Rig', '💻', '🎮 Gaming & Tech'),
    StickerItem('satellite', 'Space Orbital', '🛰️', '🎮 Gaming & Tech'),
    StickerItem('disc', 'CD Optical', '💿', '🎮 Gaming & Tech'),
    StickerItem('firewall', 'Shield Protect', '🛡️', '🎮 Gaming & Tech'),

    // ⚡ Neon & Cyber
    StickerItem('neon_heart', 'Glowing Heart', '💖', '⚡ Neon & Cyber'),
    StickerItem('neon_skull', 'Neon Cyber Skull', '☠️', '⚡ Neon & Cyber'),
    StickerItem('neon_lightning', 'Hyper Lightning', '🌩️', '⚡ Neon & Cyber'),
    StickerItem('cyber_star', 'Cosmic Nova', '🌌', '⚡ Neon & Cyber'),
    StickerItem('neon_ring', 'Saturn Glow', '🪐', '⚡ Neon & Cyber'),
    StickerItem('neon_eye', 'Third Eye Cyber', '👁️‍🗨️', '⚡ Neon & Cyber'),
    StickerItem('neon_crystal', 'Cyber Crystal', '🔮', '⚡ Neon & Cyber'),
    StickerItem('neon_comet', 'Neon Shooting Star', '☄️', '⚡ Neon & Cyber'),

    // 🌸 Nature & Vibe
    StickerItem('cherry_blossom', 'Sakura Blossom', '🌸', '🌸 Nature & Vibe'),
    StickerItem('sunflower', 'Bright Sunflower', '🌻', '🌸 Nature & Vibe'),
    StickerItem('palm_tree', 'Tropical Vibe', '🌴', '🌸 Nature & Vibe'),
    StickerItem('cloud_sun', 'Sunny Sky', '⛅', '🌸 Nature & Vibe'),
    StickerItem('moon', 'Crescent Night', '🌙', '🌸 Nature & Vibe'),
    StickerItem('ocean_wave', 'Surf Wave', '🌊', '🌸 Nature & Vibe'),
    StickerItem('herb_leaf', 'Fresh Leaves', '🌿', '🌸 Nature & Vibe'),
    StickerItem('hibiscus', 'Island Flower', '🌺', '🌸 Nature & Vibe'),

    // 🏷️ Badges & Labels
    StickerItem('badge_new', 'NEW Badge', '🆕', '🏷️ Badges & Labels'),
    StickerItem('badge_hot', 'HOT Tag', '🔥', '🏷️ Badges & Labels'),
    StickerItem('badge_top', 'TOP Rank', '🔝', '🏷️ Badges & Labels'),
    StickerItem('badge_free', 'FREE Gift', '🎁', '🏷️ Badges & Labels'),
    StickerItem('badge_vip', 'VIP Access', '👑', '🏷️ Badges & Labels'),
    StickerItem('badge_pro', 'PRO Badge', '⚡', '🏷️ Badges & Labels'),
    StickerItem('badge_cool', 'COOL Vibe', '😎', '🏷️ Badges & Labels'),
    StickerItem('badge_sale', 'SALE Discount', '🏷️', '🏷️ Badges & Labels'),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredStickers = _allStickers.where((s) {
      final matchesCategory = _searchQuery.isEmpty ? s.category == _activeCategory : true;
      final matchesSearch = _searchQuery.isEmpty ||
          s.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          s.key.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.emoji_emotions, color: AppColors.primary, size: 22),
                  const SizedBox(width: 8),
                  Text('Gboard Stickers & Emojis', style: AppTypography.titleMedium),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${_allStickers.length}+',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.primaryLight,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Search Bar
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

          // Categories Bar
          if (_searchQuery.isEmpty)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: _categories.map((cat) {
                  final isSelected = _activeCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6.0),
                    child: ChoiceChip(
                      label: Text(cat),
                      selected: isSelected,
                      onSelected: (_) => setState(() => _activeCategory = cat),
                      selectedColor: AppColors.primary,
                      backgroundColor: AppColors.surface,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppColors.textSecondary,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 11,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          const SizedBox(height: 12),

          // Sticker Grid View
          Expanded(
            child: filteredStickers.isEmpty
                ? const Center(
                    child: Text(
                      'No matching stickers found',
                      style: TextStyle(color: Colors.white38, fontSize: 13),
                    ),
                  )
                : GridView.builder(
                    itemCount: filteredStickers.length,
                    physics: const BouncingScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 1.0,
                    ),
                    itemBuilder: (context, index) {
                      final sticker = filteredStickers[index];
                      return InkWell(
                        onTap: () {
                          widget.onStickerSelected(
                            sticker.key,
                            sticker.name,
                            sticker.emojiOrGraphic,
                          );
                          Navigator.of(context).pop();
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.surfaceBorder),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                sticker.emojiOrGraphic,
                                style: const TextStyle(fontSize: 32),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                sticker.name,
                                style: AppTypography.labelSmall.copyWith(
                                  fontSize: 8,
                                  color: Colors.white70,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
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
    );
  }
}
