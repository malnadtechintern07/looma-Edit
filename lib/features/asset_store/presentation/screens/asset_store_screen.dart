import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/route_paths.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../projects/presentation/providers/projects_provider.dart';
import '../../domain/entities/asset_category.dart';
import '../providers/asset_store_provider.dart';
import '../widgets/music_preview_tile.dart';
import 'template_feed_screen.dart';

class AssetStoreScreen extends ConsumerWidget {
  const AssetStoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeCategory = ref.watch(selectedAssetCategoryProvider);

    // Render Full-Screen CapCut Vertical Swipe Template Feed for Templates, Stickers & LUTs
    if (activeCategory == AssetCategory.templates ||
        activeCategory == AssetCategory.stickers ||
        activeCategory == AssetCategory.luts) {
      return const TemplateFeedScreen();
    }

    final musicAsync = ref.watch(musicCatalogFutureProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.auto_awesome, color: AppColors.accent, size: 22),
            const SizedBox(width: 8),
            Text('Creative Asset Hub', style: AppTypography.titleLarge),
          ],
        ),
      ),
      body: Column(
        children: [
          // Category Selector Chips
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: AppColors.surface,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: AssetCategory.values.map((cat) {
                  final isSelected = activeCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(cat.title),
                      selected: isSelected,
                      onSelected: (_) =>
                          ref.read(selectedAssetCategoryProvider.notifier).state = cat,
                      selectedColor: AppColors.primary,
                      backgroundColor: AppColors.surfaceElevated,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppColors.textSecondary,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Royalty-Free Music & SFX Catalog View
          Expanded(
            child: musicAsync.when(
              data: (musicList) => ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: musicList.length,
                itemBuilder: (context, index) {
                  final track = musicList[index];
                  return MusicPreviewTile(
                    music: track,
                    onAddToProject: () async {
                      final notifier = ref.read(projectsNotifierProvider.notifier);
                      final proj = await notifier.createProject(
                        title: 'Project with ${track.title}',
                        aspectRatio: (await ref.read(getProjectsUseCaseProvider)()).first.aspectRatio,
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Imported "${track.title}" into new project!')),
                        );
                        context.push(RoutePaths.editorPath(proj.id));
                      }
                    },
                  );
                },
              ),
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
              error: (err, _) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
    );
  }
}
