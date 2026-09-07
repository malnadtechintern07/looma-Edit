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
  String _activeCategory = '🍏 iOS Memojis';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<String> _categories = const [
    '🍏 iOS Memojis',
    '🔥 Expressions',
    '✨ Aesthetic',
    '💬 Gestures',
    '🎯 Badges & Tags',
    '🍕 Food & Drinks',
    '🐶 Animals & Nature',
    '🎮 Gaming & Neon',
    '✈️ Travel & Places',
  ];

  final List<StickerItem> _allStickers = const [
    // 🍏 iOS Memojis & Reactions
    StickerItem('ios_heart_hands', 'Heart Hands', '🫶', '🍏 iOS Memojis'),
    StickerItem('ios_hand_heart', 'Finger Heart', '🫰', '🍏 iOS Memojis'),
    StickerItem('ios_italian_hand', 'Pinched Fingers', '🤌', '🍏 iOS Memojis'),
    StickerItem('ios_salute', 'Salute Respect', '🫡', '🍏 iOS Memojis'),
    StickerItem('ios_melting', 'Melting Warmth', '🫠', '🍏 iOS Memojis'),
    StickerItem('ios_holding_back_tears', 'Holding Tears', '🥹', '🍏 iOS Memojis'),
    StickerItem('ios_peeking', 'Peeking Eye', '🫣', '🍏 iOS Memojis'),
    StickerItem('ios_shushing', 'Secret Shh', '🤫', '🍏 iOS Memojis'),
    StickerItem('ios_gasp', 'Hand Over Mouth', '🫢', '🍏 iOS Memojis'),
    StickerItem('ios_giggle', 'Giggle Hand', '🤭', '🍏 iOS Memojis'),
    StickerItem('ios_dotted_face', 'Dotted Line', '🫥', '🍏 iOS Memojis'),
    StickerItem('ios_diagonal_mouth', 'Skeptical Face', '🫤', '🍏 iOS Memojis'),
    StickerItem('ios_nails', 'Nail Polish', '💅', '🍏 iOS Memojis'),
    StickerItem('ios_selfie', 'Selfie Cam', '🤳', '🍏 iOS Memojis'),
    StickerItem('ios_dancer', 'Party Dancer', '💃', '🍏 iOS Memojis'),
    StickerItem('ios_disco_dancer', 'Groovy Man', '🕺', '🍏 iOS Memojis'),
    StickerItem('ios_magic_sparkles', 'Glow Sparkles', '✨', '🍏 iOS Memojis'),
    StickerItem('ios_fire', 'Hot Fire', '🔥', '🍏 iOS Memojis'),
    StickerItem('ios_hundred', '100 Score', '💯', '🍏 iOS Memojis'),
    StickerItem('ios_sparkling_heart', 'Sparkle Heart', '💖', '🍏 iOS Memojis'),

    // 🔥 Expressions
    StickerItem('joy_crying', 'Laughing Crying', '😂', '🔥 Expressions'),
    StickerItem('rofl', 'Rolling Laugh', '🤣', '🔥 Expressions'),
    StickerItem('skull', 'Dead Skull', '💀', '🔥 Expressions'),
    StickerItem('loud_crying', 'Sobbing Loud', '😭', '🔥 Expressions'),
    StickerItem('pleading', 'Puppy Eyes', '🥺', '🔥 Expressions'),
    StickerItem('heart_eyes', 'Love Eyes', '😍', '🔥 Expressions'),
    StickerItem('star_struck', 'Starstruck', '🤩', '🔥 Expressions'),
    StickerItem('mind_blown', 'Exploding Head', '🤯', '🔥 Expressions'),
    StickerItem('cool_glasses', 'Cool Shades', '😎', '🔥 Expressions'),
    StickerItem('party_face', 'Celebration Party', '🥳', '🔥 Expressions'),
    StickerItem('wink_tongue', 'Wink & Tongue', '😜', '🔥 Expressions'),
    StickerItem('cowboy', 'Cowboy Smile', '🤠', '🔥 Expressions'),
    StickerItem('devil_smile', 'Cheeky Devil', '😈', '🔥 Expressions'),
    StickerItem('ghost', 'Cute Ghost', '👻', '🔥 Expressions'),
    StickerItem('alien', 'Space Alien', '👽', '🔥 Expressions'),
    StickerItem('robot', 'Cyber Bot', '🤖', '🔥 Expressions'),
    StickerItem('clown', 'Circus Clown', '🤡', '🔥 Expressions'),
    StickerItem('poop', 'Happy Poop', '💩', '🔥 Expressions'),
    StickerItem('cat_heart', 'Cat Love', '😻', '🔥 Expressions'),
    StickerItem('monkey_see_no', 'See No Evil', '🙈', '🔥 Expressions'),
    StickerItem('monkey_hear_no', 'Hear No Evil', '🙉', '🔥 Expressions'),
    StickerItem('monkey_speak_no', 'Speak No Evil', '🙊', '🔥 Expressions'),
    StickerItem('hot_face', 'Overheated Face', '🥵', '🔥 Expressions'),
    StickerItem('cold_face', 'Freezing Cold', '🥶', '🔥 Expressions'),
    StickerItem('dizzy_face', 'Dizzy Spiral', '😵‍💫', '🔥 Expressions'),

    // ✨ Aesthetic & Vibes
    StickerItem('magic_wand', 'Magic Wand', '🪄', '✨ Aesthetic'),
    StickerItem('sparkles', 'Magic Sparkles', '✨', '✨ Aesthetic'),
    StickerItem('sparkling_heart_2', 'Pink Heart Glow', '💖', '✨ Aesthetic'),
    StickerItem('dizzy_star', 'Orbit Stars', '💫', '✨ Aesthetic'),
    StickerItem('glowing_star', 'Golden Star', '🌟', '✨ Aesthetic'),
    StickerItem('rainbow', 'Rainbow Arc', '🌈', '✨ Aesthetic'),
    StickerItem('bubbles', 'Air Bubbles', '🫧', '✨ Aesthetic'),
    StickerItem('crescent_moon', 'Moon Crescent', '🌙', '✨ Aesthetic'),
    StickerItem('ringed_planet', 'Saturn Planet', '🪐', '✨ Aesthetic'),
    StickerItem('lightning_bolt', 'Zap Flash', '⚡', '✨ Aesthetic'),
    StickerItem('mirror_ball', 'Disco Ball', '🪩', '✨ Aesthetic'),
    StickerItem('crystal_ball', 'Fortune Crystal', '🔮', '✨ Aesthetic'),
    StickerItem('nazar_amulet', 'Evil Eye Charm', '🧿', '✨ Aesthetic'),
    StickerItem('teddy_bear', 'Plush Teddy', '🧸', '✨ Aesthetic'),
    StickerItem('angel_wings', 'Feather Wings', '🪽', '✨ Aesthetic'),
    StickerItem('ribbon_bow', 'Pink Ribbon', '🎀', '✨ Aesthetic'),
    StickerItem('diamond_gem', 'Blue Diamond', '💎', '✨ Aesthetic'),
    StickerItem('white_dove', 'Peace Dove', '🕊️', '✨ Aesthetic'),
    StickerItem('lotus_flower', 'Zen Lotus', '🪷', '✨ Aesthetic'),
    StickerItem('candle_lit', 'Warm Candle', '🕯️', '✨ Aesthetic'),
    StickerItem('fireworks_burst', 'Night Fireworks', '🎆', '✨ Aesthetic'),
    StickerItem('sparkler_fire', 'Party Sparkler', '🎇', '✨ Aesthetic'),

    // 💬 Gestures & Hands
    StickerItem('thumbs_up', 'Thumbs Up', '👍', '💬 Gestures'),
    StickerItem('thumbs_down', 'Thumbs Down', '👎', '💬 Gestures'),
    StickerItem('peace_sign', 'Victory Peace', '✌️', '💬 Gestures'),
    StickerItem('crossed_fingers', 'Good Luck', '🤞', '💬 Gestures'),
    StickerItem('rock_on', 'Rock On Sign', '🤟', '💬 Gestures'),
    StickerItem('call_me', 'Call Me Shaka', '🤙', '💬 Gestures'),
    StickerItem('clapping_hands', 'Applaud Clap', '👏', '💬 Gestures'),
    StickerItem('raised_hands', 'Hooray Hands', '🙌', '💬 Gestures'),
    StickerItem('handshake', 'Partnership Deal', '🤝', '💬 Gestures'),
    StickerItem('folded_hands', 'Namaste Prayer', '🙏', '💬 Gestures'),
    StickerItem('fist_bump', 'Punch Bump', '👊', '💬 Gestures'),
    StickerItem('writing_hand', 'Author Writing', '✍️', '💬 Gestures'),
    StickerItem('pointing_right', 'Look Right', '👉', '💬 Gestures'),
    StickerItem('pointing_left', 'Look Left', '👈', '💬 Gestures'),
    StickerItem('pointing_up', 'Look Above', '👆', '💬 Gestures'),
    StickerItem('pointing_down', 'Look Below', '👇', '💬 Gestures'),
    StickerItem('hand_rightwards', 'Reach Right', '🫱', '💬 Gestures'),
    StickerItem('hand_leftwards', 'Reach Left', '🫲', '💬 Gestures'),
    StickerItem('flexed_biceps', 'Power Muscle', '💪', '💬 Gestures'),
    StickerItem('wave_hello', 'Friendly Wave', '👋', '💬 Gestures'),

    // 🎯 Badges & Tags
    StickerItem('badge_new', 'NEW Badge', '🆕', '🎯 Badges & Tags'),
    StickerItem('badge_top', 'TOP Rank', '🔝', '🎯 Badges & Tags'),
    StickerItem('badge_100', '100 Percent', '💯', '🎯 Badges & Tags'),
    StickerItem('warning_badge', 'Warning Sign', '⚠️', '🎯 Badges & Tags'),
    StickerItem('check_badge', 'Verified Check', '✅', '🎯 Badges & Tags'),
    StickerItem('cross_mark', 'Cancel Cross', '❌', '🎯 Badges & Tags'),
    StickerItem('question_mark', 'Help Question', '❓', '🎯 Badges & Tags'),
    StickerItem('exclamation', 'Alert Exclamation', '❗', '🎯 Badges & Tags'),
    StickerItem('bell_alert', 'Notification Bell', '🔔', '🎯 Badges & Tags'),
    StickerItem('tag_price', 'Price Tag', '🏷️', '🎯 Badges & Tags'),
    StickerItem('gift_box', 'Special Gift', '🎁', '🎯 Badges & Tags'),
    StickerItem('crown_gold', 'Royal Crown', '👑', '🎯 Badges & Tags'),
    StickerItem('trophy_cup', 'Winner Trophy', '🏆', '🎯 Badges & Tags'),
    StickerItem('medal_gold', '1st Gold Medal', '🥇', '🎯 Badges & Tags'),
    StickerItem('medal_silver', '2nd Silver Medal', '🥈', '🎯 Badges & Tags'),
    StickerItem('medal_bronze', '3rd Bronze Medal', '🥉', '🎯 Badges & Tags'),
    StickerItem('military_medal', 'Hero Medal', '🎖️', '🎯 Badges & Tags'),
    StickerItem('shield_protect', 'Security Shield', '🛡️', '🎯 Badges & Tags'),
    StickerItem('lock_closed', 'Private Lock', '🔒', '🎯 Badges & Tags'),
    StickerItem('key_gold', 'VIP Key', '🔑', '🎯 Badges & Tags'),
    StickerItem('lightbulb_idea', 'Smart Idea', '💡', '🎯 Badges & Tags'),
    StickerItem('megaphone_shout', 'Announcement', '📢', '🎯 Badges & Tags'),

    // 🍕 Food & Drinks
    StickerItem('pizza_slice', 'Cheese Pizza', '🍕', '🍕 Food & Drinks'),
    StickerItem('juicy_burger', 'Double Burger', '🍔', '🍕 Food & Drinks'),
    StickerItem('french_fries', 'Crispy Fries', '🍟', '🍕 Food & Drinks'),
    StickerItem('hot_dog', 'Classic Hotdog', '🌭', '🍕 Food & Drinks'),
    StickerItem('popcorn_bucket', 'Movie Popcorn', '🍿', '🍕 Food & Drinks'),
    StickerItem('sushi_roll', 'Salmon Sushi', '🍣', '🍕 Food & Drinks'),
    StickerItem('ramen_bowl', 'Noodle Ramen', '🍜', '🍕 Food & Drinks'),
    StickerItem('boba_cup', 'Boba Milk Tea', '🧋', '🍕 Food & Drinks'),
    StickerItem('hot_coffee', 'Fresh Espresso', '☕', '🍕 Food & Drinks'),
    StickerItem('glazed_donut', 'Sweet Donut', '🍩', '🍕 Food & Drinks'),
    StickerItem('soft_ice_cream', 'Ice Cream Cone', '🍦', '🍕 Food & Drinks'),
    StickerItem('birthday_cake', 'Party Cake', '🎂', '🍕 Food & Drinks'),
    StickerItem('fresh_avocado', 'Healthy Avocado', '🥑', '🍕 Food & Drinks'),
    StickerItem('red_strawberry', 'Ripe Berry', '🍓', '🍕 Food & Drinks'),
    StickerItem('chocolate_bar', 'Cocoa Chocolate', '🍫', '🍕 Food & Drinks'),
    StickerItem('crispy_taco', 'Mexican Taco', '🌮', '🍕 Food & Drinks'),
    StickerItem('fluffy_pancakes', 'Maple Pancakes', '🥞', '🍕 Food & Drinks'),
    StickerItem('sweet_cookie', 'Choco Cookie', '🍪', '🍕 Food & Drinks'),
    StickerItem('cupcake', 'Frosted Cupcake', '🧁', '🍕 Food & Drinks'),
    StickerItem('cocktail_drink', 'Tropical Drink', '🍹', '🍕 Food & Drinks'),

    // 🐶 Animals & Nature
    StickerItem('dog_face', 'Puppy Dog', '🐶', '🐶 Animals & Nature'),
    StickerItem('cat_face', 'Kitty Cat', '🐱', '🐶 Animals & Nature'),
    StickerItem('panda_face', 'Panda Bear', '🐼', '🐶 Animals & Nature'),
    StickerItem('lion_face', 'King Lion', '🦁', '🐶 Animals & Nature'),
    StickerItem('tiger_face', 'Wild Tiger', '🐯', '🐶 Animals & Nature'),
    StickerItem('bunny_face', 'Cute Bunny', '🐰', '🐶 Animals & Nature'),
    StickerItem('koala_face', 'Cozy Koala', '🐨', '🐶 Animals & Nature'),
    StickerItem('fox_face', 'Clever Fox', '🦊', '🐶 Animals & Nature'),
    StickerItem('unicorn_face', 'Magic Unicorn', '🦄', '🐶 Animals & Nature'),
    StickerItem('butterfly_blue', 'Blue Butterfly', '🦋', '🐶 Animals & Nature'),
    StickerItem('dolphin_jump', 'Ocean Dolphin', '🐬', '🐶 Animals & Nature'),
    StickerItem('cherry_blossom', 'Sakura Blossom', '🌸', '🐶 Animals & Nature'),
    StickerItem('hibiscus_flower', 'Aloha Flower', '🌺', '🐶 Animals & Nature'),
    StickerItem('sunflower_bloom', 'Sunny Flower', '🌻', '🐶 Animals & Nature'),
    StickerItem('palm_tree', 'Tropical Palm', '🌴', '🐶 Animals & Nature'),
    StickerItem('clover_lucky', 'Lucky Clover', '🍀', '🐶 Animals & Nature'),
    StickerItem('maple_leaf', 'Autumn Leaf', '🍁', '🐶 Animals & Nature'),
    StickerItem('mushroom', 'Wild Shroom', '🍄', '🐶 Animals & Nature'),
    StickerItem('flamingo', 'Pink Flamingo', '🦩', '🐶 Animals & Nature'),
    StickerItem('honeybee', 'Busy Bee', '🐝', '🐶 Animals & Nature'),

    // 🎮 Gaming & Neon
    StickerItem('controller', 'Game Controller', '🎮', '🎮 Gaming & Neon'),
    StickerItem('arcade_joystick', 'Arcade Joystick', '🕹️', '🎮 Gaming & Neon'),
    StickerItem('vr_goggles', 'VR Metaverse', '🥽', '🎮 Gaming & Neon'),
    StickerItem('laptop_mac', 'Pro Laptop', '💻', '🎮 Gaming & Neon'),
    StickerItem('iphone_mobile', 'Smart Phone', '📱', '🎮 Gaming & Neon'),
    StickerItem('studio_headphones', 'Pro Audio Phones', '🎧', '🎮 Gaming & Neon'),
    StickerItem('studio_mic', 'Broadcasting Mic', '🎙️', '🎮 Gaming & Neon'),
    StickerItem('cinema_clapper', 'Film Clapper', '🎬', '🎮 Gaming & Neon'),
    StickerItem('polaroid_camera', 'Instant Camera', '📸', '🎮 Gaming & Neon'),
    StickerItem('full_battery', 'Full Battery', '🔋', '🎮 Gaming & Neon'),
    StickerItem('optical_disc', 'Laser CD', '💿', '🎮 Gaming & Neon'),
    StickerItem('pixel_sword', 'Hero Sword', '⚔️', '🎮 Gaming & Neon'),
    StickerItem('super_rocket', 'Space Rocket', '🚀', '🎮 Gaming & Neon'),
    StickerItem('alien_ufo', 'Cosmic UFO', '🛸', '🎮 Gaming & Neon'),
    StickerItem('space_invader', 'Pixel Invader', '👾', '🎮 Gaming & Neon'),
    StickerItem('satellite_dish', 'Radio Satellite', '📡', '🎮 Gaming & Neon'),
    StickerItem('retro_tv', 'Vintage Television', '📺', '🎮 Gaming & Neon'),
    StickerItem('cassette_tape', 'Synth Cassette', '📼', '🎮 Gaming & Neon'),

    // ✈️ Travel & Places
    StickerItem('airplane_flight', 'Jet Airplane', '✈️', '✈️ Travel & Places'),
    StickerItem('sports_car', 'Red Supercar', '🚗', '✈️ Travel & Places'),
    StickerItem('beach_umbrella', 'Sunny Beach', '🏖️', '✈️ Travel & Places'),
    StickerItem('camping_tent', 'Wild Camping', '🏕️', '✈️ Travel & Places'),
    StickerItem('ferris_wheel', 'Theme Park Wheel', '🎡', '✈️ Travel & Places'),
    StickerItem('skateboard', 'Street Skater', '🛹', '✈️ Travel & Places'),
    StickerItem('basketball', 'Hoop Ball', '🏀', '✈️ Travel & Places'),
    StickerItem('soccer_ball', 'Football Match', '⚽', '✈️ Travel & Places'),
    StickerItem('weightlifting', 'Gym Fitness', '🏋️', '✈️ Travel & Places'),
    StickerItem('surfing_wave', 'Surf Ocean', '🏄', '✈️ Travel & Places'),
    StickerItem('artist_palette', 'Color Palette', '🎨', '✈️ Travel & Places'),
    StickerItem('musical_notes', 'Melody Symphony', '🎵', '✈️ Travel & Places'),
    StickerItem('statue_liberty', 'New York City', '🗽', '✈️ Travel & Places'),
    StickerItem('eiffel_tower', 'Paris Landmark', '🗼', '✈️ Travel & Places'),
    StickerItem('snow_mountain', 'Alps Mountain', '🏔️', '✈️ Travel & Places'),
    StickerItem('desert_island', 'Paradise Island', '🏝️', '✈️ Travel & Places'),
    StickerItem('roller_coaster', 'Roller Coaster', '🎢', '✈️ Travel & Places'),
    StickerItem('bicycle_ride', 'City Bike', '🚴', '✈️ Travel & Places'),
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
          s.key.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          s.emojiOrGraphic.contains(_searchQuery);
      return matchesCategory && matchesSearch;
    }).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.70,
      decoration: const BoxDecoration(
        color: Color(0xFF141724),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Pill Indicator
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00E5FF), Color(0xFF7C4DFF)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.emoji_emotions, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Text('iOS Stickers & Memojis', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00E5FF).withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.4), width: 0.8),
                    ),
                    child: Text(
                      '${_allStickers.length}+',
                      style: AppTypography.labelSmall.copyWith(
                        color: const Color(0xFF00E5FF),
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white70),
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
              hintText: 'Search 180+ iOS stickers, memojis & emojis...',
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
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.surfaceBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.surfaceBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF00E5FF), width: 1.5),
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
                      selectedColor: const Color(0xFF00E5FF),
                      backgroundColor: AppColors.surface,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.black : AppColors.textSecondary,
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
                      childAspectRatio: 0.95,
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
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.surfaceBorder),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                sticker.emojiOrGraphic,
                                style: const TextStyle(fontSize: 34),
                              ),
                              const SizedBox(height: 3),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: Text(
                                  sticker.name,
                                  style: AppTypography.labelSmall.copyWith(
                                    fontSize: 8.5,
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
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
    );
  }
}

