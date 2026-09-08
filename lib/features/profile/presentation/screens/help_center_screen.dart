import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/route_paths.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';

class _UserGuideItem {
  final String id;
  final String title;
  final String category;
  final String readTime;
  final IconData icon;
  final Color color;
  final String summary;
  final List<String> steps;
  final String proTip;

  const _UserGuideItem({
    required this.id,
    required this.title,
    required this.category,
    required this.readTime,
    required this.icon,
    required this.color,
    required this.summary,
    required this.steps,
    required this.proTip,
  });
}

class _FaqItem {
  final String question;
  final String answer;
  final String category;

  const _FaqItem({
    required this.question,
    required this.answer,
    required this.category,
  });
}

/// Interactive Help Center & User Guides Screen for Looma Creators
class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All',
    'Timeline & Editing',
    'Filters & FX',
    'Text & Stickers',
    'Audio & Music',
    'Export & Cloud',
  ];

  static const List<_UserGuideItem> _guides = [
    _UserGuideItem(
      id: 'timeline_editing',
      title: 'Mastering the Multi-Track Timeline',
      category: 'Timeline & Editing',
      readTime: '3 min read',
      icon: Icons.view_timeline_rounded,
      color: Color(0xFF0D6EFD),
      summary: 'Learn how to trim, split clips at the playhead, and reorder multi-track video layers with magnetic snapping.',
      steps: [
        '1. Drag the red vertical playhead to the exact frame where you want to perform a cut.',
        '2. Tap the "Split" button on the bottom editing toolbar to cut the active video clip into two independent segments.',
        '3. Tap either clip to reveal white trim handles on the left and right edges. Drag them inward to trim start/end frames.',
        '4. Long-press any video clip thumbnail and drag left or right to seamlessly reorder clips on the timeline.',
        '5. Tap the speed button to adjust clip playback between 0.2x slow-motion and 5.0x ultra fast-forward.',
      ],
      proTip: 'Double tap anywhere along the timeline ruler to quickly snap the playhead to the nearest clip boundary.',
    ),
    _UserGuideItem(
      id: 'cinematic_filters',
      title: 'Applying 70+ Cinematic Filters & LUTs',
      category: 'Filters & FX',
      readTime: '2 min read',
      icon: Icons.auto_awesome_rounded,
      color: Color(0xFF00C2CB),
      summary: 'Transform mobile footage with warm vintage tones, blockbuster cinematic looks, Moody Noir, and cyberpunk grades.',
      steps: [
        '1. Select any video clip on your timeline and tap "Filters" in the bottom action bar.',
        '2. Browse filter categories including Cinematic, Vintage, B&W, Cyberpunk, and Vibrant.',
        '3. Tap any filter to instantly preview the grade in full resolution on the video player.',
        '4. Drag the Intensity slider (0% to 100%) to calibrate the blend strength of the color matrix.',
        '5. Tap "Apply to All" if you want consistent color grading across all clips in your timeline.',
      ],
      proTip: 'Combine the "Cinematic Teal & Orange" filter with a slight vignette for an instant Hollywood look.',
    ),
    _UserGuideItem(
      id: 'keyframe_animations',
      title: 'Keyframe Motion & Sticker Animations',
      category: 'Text & Stickers',
      readTime: '4 min read',
      icon: Icons.animation_rounded,
      color: Color(0xFF5B4DFB),
      summary: 'Create custom motion paths, zoom-in punch cuts, and smooth rotational effects using timeline keyframing.',
      steps: [
        '1. Select an element on the canvas (such as a text overlay, sticker, or picture-in-picture clip).',
        '2. Move the timeline playhead to the moment you want your animation to start and tap the "+ Keyframe" diamond icon.',
        '3. Advance the playhead forward by 1 or 2 seconds.',
        '4. Adjust the size, rotation, or position of your element on the canvas. A new keyframe diamond will automatically record.',
        '5. Press Play to see smooth interpolated motion between your keyframe points.',
      ],
      proTip: 'Use keyframes for smooth animated subtitles that bounce or fade in sync with speech.',
    ),
    _UserGuideItem(
      id: 'audio_mixing',
      title: 'Audio Mixing, Ducking & Voiceovers',
      category: 'Audio & Music',
      readTime: '3 min read',
      icon: Icons.music_note_rounded,
      color: Color(0xFF10B981),
      summary: 'Balance background music with spoken voiceovers and add dramatic sound effects.',
      steps: [
        '1. Tap the Audio tab to import local MP3/WAV tracks or choose from Looma royalty-free creator soundbites.',
        '2. Use the volume slider on the video clip to lower background noise (e.g. set clip audio to 30%).',
        '3. Tap "Record Voiceover" while watching video playback to record live narration with your microphone.',
        '4. Split and trim audio tracks independently from your video track on the dedicated green audio lane.',
        '5. Apply Fade-In and Fade-Out (1s-3s) to avoid jarring audio cuts at the start and end of your video.',
      ],
      proTip: 'Always lower music volume to 15%-25% whenever spoken dialogue or voiceover narration is active.',
    ),
    _UserGuideItem(
      id: 'export_4k',
      title: 'Exporting 4K / 60 FPS & Bitrate Control',
      category: 'Export & Cloud',
      readTime: '2 min read',
      icon: Icons.file_upload_outlined,
      color: Color(0xFFFFB800),
      summary: 'Export crisp high-bitrate videos optimized for Instagram Reels, YouTube Shorts, or TikTok.',
      steps: [
        '1. Tap the blue "Export" button located in the top right corner of the editor.',
        '2. Choose your export resolution: 720p (Fastest), 1080p (Standard Full HD), or 4K (Ultra HD).',
        '3. Select your target frame rate: 24 FPS (Cinematic film), 30 FPS (Standard video), or 60 FPS (Ultra smooth).',
        '4. Toggle "Direct Save to Gallery" to automatically register the exported file with your phone camera roll.',
        '5. Keep the Looma app open while the GPU acceleration engine completes the encoding process.',
      ],
      proTip: 'For 9:16 vertical shorts, 1080p at 60 FPS provides the ideal balance between upload compression and visual clarity.',
    ),
    _UserGuideItem(
      id: 'cloud_sync_guide',
      title: 'Cloud Sync & Multi-Device Backup',
      category: 'Export & Cloud',
      readTime: '3 min read',
      icon: Icons.cloud_sync_rounded,
      color: Color(0xFF084298),
      summary: 'Safeguard your multi-track project files in private cloud storage and continue edits on another device.',
      steps: [
        '1. Create a free Looma account from the "Me" tab or during initial setup.',
        '2. Open the Cloud Sync dashboard from the AppBar or project management card.',
        '3. Tap "Sync Now" to backup project timelines, clip arrangements, and text styles to your private cloud.',
        '4. When logging into a secondary device, tap "Restore from Cloud" to sync your projects locally.',
        '5. Check individual project badges to ensure status displays "Synced" with a green checkmark.',
      ],
      proTip: 'Cloud sync backs up project files and metadata so you can free up local space safely.',
    ),
  ];

  static const List<_FaqItem> _faqs = [
    _FaqItem(
      question: 'Does Looma put a watermark on my videos?',
      answer:
          'No! Looma allows you to export clean, watermark-free videos. You can also customize or toggle the optional creator watermark in the export settings if you want to protect your original creations.',
      category: 'Export & Cloud',
    ),
    _FaqItem(
      question: 'Can I edit videos offline without an internet connection?',
      answer:
          'Yes, 100%! Looma is built with an offline-first architecture. Timeline editing, trimming, filters, audio mixing, speed adjustments, and video rendering happen entirely on your phone without requiring Wi-Fi or cellular data.',
      category: 'Timeline & Editing',
    ),
    _FaqItem(
      question: 'Where are exported videos saved on my phone?',
      answer:
          'Exported videos are saved directly into your device’s native photo gallery / Camera Roll under the "Looma" or "Movies" album. If you enable "Direct Save to Gallery" in the Me tab, they will immediately appear in your standard Photos app.',
      category: 'Export & Cloud',
    ),
    _FaqItem(
      question: 'How do I undo an accidental cut or deleted clip?',
      answer:
          'You can tap the Undo button (curved left arrow) on the top bar in the editor screen at any time to revert your previous action. Tap the Redo button to re-apply any reverted changes.',
      category: 'Timeline & Editing',
    ),
    _FaqItem(
      question: 'What video aspect ratios and formats are supported?',
      answer:
          'Looma supports 16:9 (Landscape / YouTube), 9:16 (Vertical / TikTok, Reels, Shorts), 1:1 (Square), 4:5 (Instagram Feed), and 21:9 (Cinemascope). Supported formats include MP4, MOV, and standard modern video codecs (H.264 / HEVC).',
      category: 'Timeline & Editing',
    ),
    _FaqItem(
      question: 'How do I recover space taken by temporary cache?',
      answer:
          'Go to the "Me" tab, find the "System & Storage" section, and tap "Clear Temporary Cache". This will safely remove generated video preview fragments and waveform thumbnails without deleting your project drafts.',
      category: 'Export & Cloud',
    ),
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<_UserGuideItem> get _filteredGuides {
    return _guides.where((guide) {
      final matchesCat = _selectedCategory == 'All' || guide.category == _selectedCategory;
      final query = _searchQuery.toLowerCase();
      final matchesQuery = query.isEmpty ||
          guide.title.toLowerCase().contains(query) ||
          guide.summary.toLowerCase().contains(query) ||
          guide.steps.any((s) => s.toLowerCase().contains(query));
      return matchesCat && matchesQuery;
    }).toList();
  }

  List<_FaqItem> get _filteredFaqs {
    return _faqs.where((faq) {
      final matchesCat = _selectedCategory == 'All' || faq.category == _selectedCategory;
      final query = _searchQuery.toLowerCase();
      final matchesQuery = query.isEmpty ||
          faq.question.toLowerCase().contains(query) ||
          faq.answer.toLowerCase().contains(query);
      return matchesCat && matchesQuery;
    }).toList();
  }

  void _openGuideDetails(_UserGuideItem guide) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _GuideReaderSheet(guide: guide),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredGuides = _filteredGuides;
    final filteredFaqs = _filteredFaqs;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9FE),
        elevation: 0,
        leading: IconButton(
          key: const Key('help_center_back_button'),
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF111827), size: 20),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.pop();
            }
          },
        ),
        title: Text(
          'Help & User Guides',
          style: AppTypography.titleLarge.copyWith(
            color: const Color(0xFF111827),
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Contact Support',
            icon: const Icon(Icons.support_agent_rounded, color: AppColors.primary, size: 24),
            onPressed: () => context.push(RoutePaths.contactSupport),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Search Bar
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFECEEF5)),
                boxShadow: const [
                  BoxShadow(color: Color(0x08000000), blurRadius: 10, offset: Offset(0, 3)),
                ],
              ),
              child: TextField(
                key: const Key('help_center_search_field'),
                controller: _searchCtrl,
                onChanged: (val) => setState(() => _searchQuery = val.trim()),
                decoration: InputDecoration(
                  hintText: 'Search guides, timeline tips, FAQs...',
                  hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13.5),
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF6B7280)),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Color(0xFF9CA3AF), size: 18),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 2. Category Chips Horizontal Scroll
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: _categories.map((cat) {
                  final isSelected = _selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(cat),
                      selected: isSelected,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : const Color(0xFF374151),
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        fontSize: 12.5,
                      ),
                      selectedColor: AppColors.primary,
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected ? AppColors.primary : const Color(0xFFE5E7EB),
                        ),
                      ),
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedCategory = cat);
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 22),

            // 3. User Guides Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Creator Tutorials & Guides',
                  style: AppTypography.titleMedium.copyWith(
                    color: const Color(0xFF111827),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  '${filteredGuides.length} articles',
                  style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Guides List
            if (filteredGuides.isEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFECEEF5)),
                ),
                child: Column(
                  children: const [
                    Icon(Icons.search_off_rounded, color: Color(0xFF9CA3AF), size: 40),
                    SizedBox(height: 10),
                    Text(
                      'No guides found matching query',
                      style: TextStyle(color: Color(0xFF374151), fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ] else ...[
              ...filteredGuides.map((guide) => _buildGuideCard(guide)),
            ],
            const SizedBox(height: 26),

            // 4. Frequently Asked Questions (Accordion)
            Text(
              'Frequently Asked Questions',
              style: AppTypography.titleMedium.copyWith(
                color: const Color(0xFF111827),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),

            if (filteredFaqs.isEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFECEEF5)),
                ),
                child: Column(
                  children: const [
                    Icon(Icons.help_outline_rounded, color: Color(0xFF9CA3AF), size: 40),
                    SizedBox(height: 10),
                    Text(
                      'No FAQs match your search',
                      style: TextStyle(color: Color(0xFF374151), fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                clipBehavior: Clip.antiAlias,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFECEEF5)),
                  ),
                  child: Column(
                    children: [
                      for (int i = 0; i < filteredFaqs.length; i++) ...[
                        if (i > 0) const Divider(height: 1, color: Color(0xFFF3F4F6)),
                        _buildFaqTile(filteredFaqs[i], i),
                      ],
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),

            // 5. Need More Help / Contact Us Banner
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF084298), Color(0xFF0D6EFD)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.support_agent_rounded, color: Colors.white, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Still Have Questions?',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Our creator support team replies within 12 hours.',
                          style: TextStyle(color: Color(0xFFC7D2FE), fontSize: 11.5),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    key: const Key('help_center_contact_button'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    onPressed: () => context.push(RoutePaths.contactSupport),
                    child: const Text('Contact Us', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuideCard(_UserGuideItem guide) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFECEEF5)),
        boxShadow: const [
          BoxShadow(color: Color(0x06000000), blurRadius: 10, offset: Offset(0, 2)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          key: Key('guide_card_${guide.id}'),
          borderRadius: BorderRadius.circular(18),
          onTap: () => _openGuideDetails(guide),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: guide.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(guide.icon, color: guide.color, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              guide.category.toUpperCase(),
                              style: const TextStyle(
                                color: Color(0xFF6B7280),
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            guide.readTime,
                            style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 11),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        guide.title,
                        style: const TextStyle(
                          color: Color(0xFF111827),
                          fontWeight: FontWeight.bold,
                          fontSize: 14.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        guide.summary,
                        style: const TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 12,
                          height: 1.35,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.chevron_right, color: Color(0xFF9CA3AF), size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFaqTile(_FaqItem faq, int index) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        key: Key('faq_tile_$index'),
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        iconColor: AppColors.primary,
        collapsedIconColor: const Color(0xFF9CA3AF),
        title: Text(
          faq.question,
          style: const TextStyle(
            color: Color(0xFF111827),
            fontWeight: FontWeight.w600,
            fontSize: 13.5,
          ),
        ),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FE),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              faq.answer,
              style: const TextStyle(
                color: Color(0xFF4B5563),
                fontSize: 12.5,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GuideReaderSheet extends StatelessWidget {
  final _UserGuideItem guide;

  const _GuideReaderSheet({required this.guide});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFD1D5DB),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Top action bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: guide.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    guide.category.toUpperCase(),
                    style: TextStyle(
                      color: guide.color,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: Color(0xFF6B7280)),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF3F4F6)),

          // Scrollable reader content
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: guide.color.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(guide.icon, color: guide.color, size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              guide.title,
                              style: const TextStyle(
                                color: Color(0xFF111827),
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              guide.readTime,
                              style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    guide.summary,
                    style: const TextStyle(
                      color: Color(0xFF374151),
                      fontSize: 14,
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 20),

                  const Text(
                    'Step-by-Step Instructions',
                    style: TextStyle(
                      color: Color(0xFF111827),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),

                  ...guide.steps.map((step) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F9FE),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFECEEF5)),
                      ),
                      child: Text(
                        step,
                        style: const TextStyle(
                          color: Color(0xFF1F2937),
                          fontSize: 13,
                          height: 1.45,
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 16),

                  // Pro Tip Callout
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFFCD34D)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.lightbulb_rounded, color: Color(0xFFF59E0B), size: 22),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Pro Creator Tip',
                                style: TextStyle(
                                  color: Color(0xFF92400E),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                guide.proTip,
                                style: const TextStyle(
                                  color: Color(0xFF78350F),
                                  fontSize: 12.5,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
