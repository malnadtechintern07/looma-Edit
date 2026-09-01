import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../audio/presentation/widgets/audio_mixer_sheet.dart';
import '../../../audio/presentation/widgets/voiceover_modal.dart';
import '../../../filters_effects/presentation/widgets/color_adjustment_sheet.dart';
import '../../../filters_effects/presentation/widgets/effects_picker_sheet.dart';
import '../../../filters_effects/presentation/widgets/filter_picker_sheet.dart';
import '../../../media_picker/presentation/widgets/media_picker_modal.dart';
import '../../../text_stickers/presentation/widgets/sticker_picker_sheet.dart';
import '../../../text_stickers/presentation/widgets/text_editor_sheet.dart';
import '../../domain/entities/timeline_state.dart';
import '../providers/editor_controller.dart';
import 'clip_speed_sheet.dart';
import 'transition_picker_sheet.dart';

class EditorActionBar extends StatelessWidget {
  final TimelineState state;
  final EditorController controller;

  const EditorActionBar({
    super.key,
    required this.state,
    required this.controller,
  });

  void _openFilterPicker(BuildContext context) {
    final active = state.activeVideoClip;
    if (active == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => FilterPickerSheet(
        selectedFilter: active.filterType,
        onFilterSelected: (f) => controller.setClipFilter(active.id, f),
      ),
    );
  }

  void _openColorAdjustments(BuildContext context) {
    final active = state.activeVideoClip;
    if (active == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => ColorAdjustmentSheet(
        initialBrightness: active.brightness,
        initialContrast: active.contrast,
        initialSaturation: active.saturation,
        onAdjustmentsChanged: (b, c, s) {
          controller.setClipColorAdjustments(
            clipId: active.id,
            brightness: b,
            contrast: c,
            saturation: s,
          );
        },
      ),
    );
  }

  void _openEffectsSheet(BuildContext context) {
    final active = state.activeVideoClip;
    if (active == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => EffectsPickerSheet(
        initialBlur: active.blurSigma,
        initialZoom: active.zoomScale,
        initialFadeInMs: active.fadeInDurationMs,
        initialFadeOutMs: active.fadeOutDurationMs,
        initialBrightness: active.brightness,
        initialContrast: active.contrast,
        initialSaturation: active.saturation,
        onEffectsChanged: ({
          required blur,
          required zoom,
          required fadeInMs,
          required fadeOutMs,
          required brightness,
          required contrast,
          required saturation,
        }) {
          controller.setClipBlur(active.id, blur);
          controller.setClipZoom(active.id, zoom);
          controller.setClipFade(active.id, fadeInMs, fadeOutMs);
          controller.setClipColorAdjustments(
            clipId: active.id,
            brightness: brightness,
            contrast: contrast,
            saturation: saturation,
          );
        },
      ),
    );
  }

  void _openSpeedSheet(BuildContext context) {
    final active = state.activeVideoClip;
    if (active == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => ClipSpeedSheet(
        currentSpeed: active.speed,
        onSpeedChanged: (s) => controller.setClipSpeed(active.id, s),
      ),
    );
  }

  void _openTransitionPicker(BuildContext context) {
    final active = state.activeVideoClip;
    if (active == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => TransitionPickerSheet(
        currentTransition: active.transitionIn,
        currentDurationMs: active.transitionDurationMs,
        onTransitionSelected: (t, dur) => controller.setClipTransition(active.id, t, durationMs: dur),
      ),
    );
  }

  void _openTextEditor(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => TextEditorSheet(
        onSave: ({
          required text,
          required fontFamily,
          required fontSize,
          required colorHex,
          backgroundColorHex,
          required animationType,
        }) {
          controller.addTextOverlay(
            text: text,
            fontFamily: fontFamily,
            fontSize: fontSize,
            colorHex: colorHex,
            backgroundColorHex: backgroundColorHex,
            animationType: animationType,
          );
        },
      ),
    );
  }

  void _openStickerPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StickerPickerSheet(
        onStickerSelected: (key, name, emoji) {
          controller.addStickerOverlay(
            stickerKey: key,
            stickerName: name,
            assetEmojiOrPath: emoji,
          );
        },
      ),
    );
  }

  void _openVoiceoverModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => VoiceoverModal(
        timelineInsertStartMs: state.playheadPositionMs,
        onVoiceoverRecorded: (audio) => controller.addAudioClip(audio),
      ),
    );
  }

  void _openAudioMixer(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => AudioMixerSheet(
        audioClips: state.project.audioClips,
        onAddAudioTrack: (newAudio) => controller.addAudioClip(newAudio),
        onUpdateAudioTrack: (updatedAudio) => controller.updateAudioTrack(updatedAudio),
        onDeleteAudioTrack: (clipId) => controller.deleteAudioTrack(clipId),
        onAddVoiceover: () => _openVoiceoverModal(context),
      ),
    );
  }

  void _openMediaPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceElevated,
      builder: (ctx) => MediaPickerModal(
        title: 'Add Videos & Photos to Timeline',
        actionLabel: 'Add to Timeline',
        onMediaSelected: (selectedMedia) {
          for (final m in selectedMedia) {
            controller.addVideoClip(
              name: m.name,
              mediaPath: m.path,
              durationMs: m.durationMs,
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasSelection = state.selectionType != SelectionType.none;

    return Container(
      height: 64,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.surfaceBorder, width: 1)),
      ),
      child: SafeArea(
        top: false,
        bottom: false,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildActionButton(
                icon: Icons.splitscreen,
                label: 'Split',
                color: AppColors.primaryLight,
                onTap: controller.splitActiveClip,
              ),
              _buildActionButton(
                icon: Icons.speed,
                label: 'Speed',
                color: AppColors.accent,
                onTap: () => _openSpeedSheet(context),
              ),
              _buildActionButton(
                icon: Icons.filter_vintage,
                label: 'Filters',
                color: AppColors.secondary,
                onTap: () => _openFilterPicker(context),
              ),
              _buildActionButton(
                icon: Icons.tune,
                label: 'Adjust',
                color: AppColors.secondaryLight,
                onTap: () => _openColorAdjustments(context),
              ),
              _buildActionButton(
                icon: Icons.auto_fix_high,
                label: 'Effects',
                color: AppColors.accent,
                onTap: () => _openEffectsSheet(context),
              ),
              _buildActionButton(
                icon: Icons.title,
                label: 'Text',
                color: AppColors.textTrack,
                onTap: () => _openTextEditor(context),
              ),
              _buildActionButton(
                icon: Icons.emoji_emotions,
                label: 'Stickers',
                color: AppColors.stickerTrack,
                onTap: () => _openStickerPicker(context),
              ),
              _buildActionButton(
                icon: Icons.mic,
                label: 'Voiceover',
                color: AppColors.voiceoverTrack,
                onTap: () => _openVoiceoverModal(context),
              ),
              _buildActionButton(
                icon: Icons.equalizer,
                label: 'Audio Mix',
                color: AppColors.audioTrack,
                onTap: () => _openAudioMixer(context),
              ),
              _buildActionButton(
                icon: Icons.transform,
                label: 'Transitions',
                color: AppColors.primaryLight,
                onTap: () => _openTransitionPicker(context),
              ),
              _buildActionButton(
                icon: Icons.add_to_photos,
                label: 'Add Clip',
                color: AppColors.success,
                onTap: () => _openMediaPicker(context),
              ),
              if (hasSelection)
                _buildActionButton(
                  icon: Icons.delete_outline,
                  label: 'Delete',
                  color: AppColors.error,
                  onTap: controller.deleteSelected,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          constraints: const BoxConstraints(minWidth: 56),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(height: 3),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: AppTypography.labelSmall.copyWith(fontSize: 10),
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
