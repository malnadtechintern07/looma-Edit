import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../audio/presentation/widgets/audio_mixer_sheet.dart';
import '../../../audio/presentation/widgets/voiceover_modal.dart';
import '../../../filters_effects/domain/entities/filter_preset.dart';
import '../../../filters_effects/domain/entities/video_effect_type.dart';
import '../../../filters_effects/presentation/widgets/color_adjustment_sheet.dart';
import '../../../filters_effects/presentation/widgets/effects_picker_sheet.dart';
import '../../../filters_effects/presentation/widgets/filter_picker_sheet.dart';
import '../../../media_picker/domain/entities/media_item_entity.dart';
import '../../../media_picker/presentation/widgets/media_picker_modal.dart';
import '../../../text_stickers/domain/entities/text_overlay_entity.dart';
import '../../../text_stickers/presentation/widgets/sticker_picker_sheet.dart';
import '../../../text_stickers/presentation/widgets/text_editor_sheet.dart';
import '../../domain/entities/clip_animation_type.dart';
import '../../domain/entities/timeline_state.dart';
import '../providers/editor_controller.dart';
import 'animation_picker_sheet.dart';
import 'caption_editor_sheet.dart';
import 'clip_speed_sheet.dart';
import 'clip_volume_sheet.dart';
import 'crop_transform_sheet.dart';
import 'mask_sheet.dart';
import 'reorder_clips_sheet.dart';
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
    final active = state.selectedVideoClip ?? state.activeVideoClip;
    if (active == null) return;
    FilterType savedFilter = active.filterType;
    double savedIntensity = active.filterIntensity;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => FilterPickerSheet(
        selectedFilter: active.filterType,
        filterIntensity: active.filterIntensity,
        mediaPath: active.mediaPath,
        onFilterSelected: (f) {
          savedFilter = f;
          controller.setClipFilter(active.id, f);
        },
        onIntensityChanged: (val) {
          savedIntensity = val;
          controller.setClipFilterIntensity(active.id, val);
        },
        onFilterRemoved: () {
          savedFilter = FilterType.none;
          savedIntensity = 1.0;
          controller.removeClipFilter(active.id);
        },
        onHoldToCompare: (comparing) {
          if (comparing) {
            controller.setClipFilter(active.id, FilterType.none);
          } else {
            controller.setClipFilter(active.id, savedFilter, intensity: savedIntensity);
          }
        },
      ),
    );
  }

  void _openColorAdjustments(BuildContext context) {
    final active = state.selectedVideoClip ?? state.activeVideoClip;
    if (active == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF161822),
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
    if (state.selectionType == SelectionType.effectClip && state.selectedEffectClip != null) {
      final effectClip = state.selectedEffectClip!;
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: const Color(0xFF161822),
        builder: (ctx) => EffectsPickerSheet(
          selectedEffect: effectClip.effectType,
          effectIntensity: effectClip.intensity,
          initialBlur: 0,
          initialZoom: 1.0,
          initialFadeInMs: 0,
          initialFadeOutMs: 0,
          initialBrightness: 0,
          initialContrast: 1.0,
          initialSaturation: 1.0,
          onEffectSelected: (effect) {
            controller.replaceEffectClip(effectClip.id, effect);
          },
          onIntensityChanged: (eff, intensity) {
            controller.updateEffectClipIntensity(effectClip.id, intensity);
          },
          onEffectsChanged: ({
            required blur,
            required zoom,
            required fadeInMs,
            required fadeOutMs,
            required brightness,
            required contrast,
            required saturation,
          }) {},
        ),
      );
      return;
    }

    // Default: Add a new independent effect clip on the timeline at playhead
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF161822),
      builder: (ctx) => EffectsPickerSheet(
        selectedEffect: VideoEffectType.none,
        effectIntensity: 1.0,
        initialBlur: 0,
        initialZoom: 1.0,
        initialFadeInMs: 0,
        initialFadeOutMs: 0,
        initialBrightness: 0,
        initialContrast: 1.0,
        initialSaturation: 1.0,
        onEffectSelected: (effect) {
          if (effect != VideoEffectType.none) {
            controller.addEffectClip(effectType: effect);
          }
        },
        onEffectsChanged: ({
          required blur,
          required zoom,
          required fadeInMs,
          required fadeOutMs,
          required brightness,
          required contrast,
          required saturation,
        }) {},
      ),
    );
  }

  void _openSpeedSheet(BuildContext context) {
    final active = state.selectedVideoClip ?? state.activeVideoClip;
    if (active == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF161822),
      builder: (ctx) => ClipSpeedSheet(
        currentSpeed: active.speed,
        currentSpeedCurve: active.speedCurve,
        isReversed: active.isReversed,
        onSpeedChanged: (s) => controller.setClipSpeed(active.id, s),
        onSpeedCurveChanged: (c) => controller.setClipSpeedCurve(active.id, c),
        onToggleReverse: () => controller.toggleClipReverse(active.id),
        onFreezeFrame: () => controller.freezeFrameAtPlayhead(active.id),
      ),
    );
  }

  void _openCropTransformSheet(BuildContext context) {
    final active = state.selectedVideoClip ?? state.activeVideoClip;
    if (active == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF161822),
      builder: (ctx) => CropTransformSheet(
        clip: active,
        onCropChanged: (crop) => controller.setClipCrop(active.id, crop),
        onOpacityChanged: (op) => controller.setClipOpacity(active.id, op),
        onFlipHorizontal: () => controller.flipClipHorizontal(active.id),
        onFlipVertical: () => controller.flipClipVertical(active.id),
        onReset: () => controller.resetClipTransform(active.id),
      ),
    );
  }

  void _openAnimationSheet(BuildContext context) {
    if (state.selectionType == SelectionType.animationClip && state.selectedAnimationClip != null) {
      final animClip = state.selectedAnimationClip!;
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: const Color(0xFF161822),
        builder: (ctx) => AnimationPickerSheet(
          selectedAnimation: animClip.animationType,
          initialDurationMs: animClip.durationMs,
          onAnimationSelected: (anim, dur) {
            controller.replaceAnimationClip(animClip.id, anim);
            controller.updateAnimationClipDuration(animClip.id, dur);
          },
        ),
      );
      return;
    }

    // Add a new independent animation clip on the timeline at playhead
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF161822),
      builder: (ctx) => AnimationPickerSheet(
        selectedAnimation: ClipAnimationCombo.pulse,
        initialDurationMs: 2000,
        onAnimationSelected: (anim, dur) {
          controller.addAnimationClip(animationType: anim, durationMs: dur);
        },
      ),
    );
  }

  void _openMaskSheet(BuildContext context) {
    final active = state.selectedVideoClip ?? state.activeVideoClip;
    if (active == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF161822),
      builder: (ctx) => MaskSheet(
        currentMask: active.mask,
        onMaskChanged: (mask) => controller.setClipMask(active.id, mask),
      ),
    );
  }

  void _openChromaKeySheet(BuildContext context) {
    final active = state.selectedVideoClip ?? state.activeVideoClip;
    if (active == null) return;
    controller.openChromaKeyMode(active.id);
  }

  void _openVolumeSheet(BuildContext context) {
    final active = state.selectedVideoClip ?? state.activeVideoClip;
    if (active == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF161822),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => ClipVolumeSheet(
        clip: active,
        onVolumeChanged: (vol) => controller.setClipVolume(active.id, vol),
        onMuteChanged: (isMuted) => controller.setClipMute(active.id, isMuted),
        onResetVolume: () => controller.resetClipVolume(active.id),
        onExtractAudio: () => controller.extractAudioFromClip(active.id),
      ),
    );
  }

  void _openReorderSheet(BuildContext context) {
    final mainClips = state.project.videoClips.where((c) => !c.isOverlay).toList();
    if (mainClips.isEmpty) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF161822),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => ReorderClipsSheet(
        clips: mainClips,
        controller: controller,
        selectedClipId: state.selectedItemId,
      ),
    );
  }

  void _openCaptionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF161822),
      builder: (ctx) => CaptionEditorSheet(
        onSaveSubtitle: (text) => controller.addSubtitle(text: text),
      ),
    );
  }

  void _openTransitionPicker(BuildContext context) {
    final active = state.selectedVideoClip ?? state.activeVideoClip;
    if (active == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF161822),
      builder: (ctx) => TransitionPickerSheet(
        currentTransition: active.transitionIn,
        currentDurationMs: active.transitionDurationMs,
        onTransitionSelected: (t, dur) => controller.setClipTransition(active.id, t, durationMs: dur),
      ),
    );
  }

  void _openTextEditor(BuildContext context, {TextOverlayEntity? initialText}) {
    final selectedText = initialText ??
        (state.selectionType == SelectionType.textOverlay ? state.selectedTextOverlay : null);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF161822),
      builder: (ctx) => TextEditorSheet(
        initialText: selectedText,
        onSave: ({
          required text,
          required fontFamily,
          required fontSize,
          required colorHex,
          backgroundColorHex,
          required animationType,
        }) {
          if (selectedText != null) {
            controller.updateTextOverlay(
              selectedText.copyWith(
                text: text,
                fontFamily: fontFamily,
                fontSize: fontSize,
                colorHex: colorHex,
                backgroundColorHex: backgroundColorHex,
                animationType: animationType,
              ),
            );
          } else {
            controller.addTextOverlay(
              text: text,
              fontFamily: fontFamily,
              fontSize: fontSize,
              colorHex: colorHex,
              backgroundColorHex: backgroundColorHex,
              animationType: animationType,
            );
          }
        },
      ),
    );
  }

  void _openStickerPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF161822),
      builder: (ctx) => StickerPickerSheet(
        onStickerSelected: (key, name, emoji) {
          if (state.selectionType == SelectionType.stickerOverlay && state.selectedItemId != null) {
            controller.replaceSticker(
              stickerId: state.selectedItemId!,
              newAssetPath: emoji,
            );
          } else {
            controller.addStickerOverlay(
              stickerKey: key,
              stickerName: name,
              assetEmojiOrPath: emoji,
            );
          }
        },
      ),
    );
  }

  void _openVoiceoverModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF161822),
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
      backgroundColor: const Color(0xFF161822),
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
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (ctx) => MediaPickerModal(
          title: 'Add to Timeline',
          actionLabel: 'Add',
          onMediaSelected: (selectedMedia) {
            for (final m in selectedMedia) {
              if (m.type == MediaType.photo) {
                controller.addPhotoClip(
                  name: m.name,
                  mediaPath: m.path,
                  durationMs: m.durationMs > 0 ? m.durationMs : 4000,
                  isOverlay: false,
                );
              } else {
                controller.addVideoClip(
                  name: m.name,
                  mediaPath: m.path,
                  durationMs: m.durationMs,
                );
              }
            }
          },
        ),
      ),
    );
  }

  void _openOverlayPicker(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (ctx) => MediaPickerModal(
          title: 'Add Picture-in-Picture (PIP)',
          actionLabel: 'Add PIP',
          onMediaSelected: (selectedMedia) {
            for (final m in selectedMedia) {
              if (m.type == MediaType.photo) {
                controller.addPhotoClip(
                  name: m.name,
                  mediaPath: m.path,
                  durationMs: m.durationMs > 0 ? m.durationMs : 4000,
                  isOverlay: true,
                );
              } else {
                controller.addOverlayClip(
                  name: m.name,
                  mediaPath: m.path,
                  durationMs: m.durationMs,
                );
              }
            }
          },
        ),
      ),
    );
  }

  void _handleReplaceAction(BuildContext context) {
    // 1. If effect clip selected -> replace effect
    if (state.selectionType == SelectionType.effectClip && state.selectedEffectClip != null) {
      _openEffectsSheet(context);
      return;
    }

    // 2. If sticker selected -> replace sticker
    if (state.selectionType == SelectionType.stickerOverlay && state.selectedItemId != null) {
      _openStickerPicker(context);
      return;
    }

    // 3. If audio selected -> open audio mixer
    if (state.selectionType == SelectionType.audioClip && state.selectedItemId != null) {
      _openAudioMixer(context);
      return;
    }

    // 4. If text selected -> open text editor
    if (state.selectionType == SelectionType.textOverlay && state.selectedItemId != null) {
      _openTextEditor(context);
      return;
    }

    // 5. Video clip or active video clip -> replace video media
    final clipId = state.selectedItemId ?? state.activeVideoClip?.id;
    if (clipId == null) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (ctx) => MediaPickerModal(
          title: 'Replace Clip',
          actionLabel: 'Replace',
          onMediaSelected: (selectedMedia) {
            if (selectedMedia.isNotEmpty) {
              final m = selectedMedia.first;
              controller.replaceVideoClip(
                clipId: clipId,
                newMediaPath: m.path,
                newName: m.name,
                newSourceDurationMs: m.durationMs,
              );
            }
          },
        ),
      ),
    );
  }

  void _handleSplitAction() {
    if (state.selectionType == SelectionType.effectClip && state.selectedItemId != null) {
      controller.splitEffectClipAtPlayhead(state.selectedItemId!);
    } else {
      controller.splitActiveClip();
    }
  }

  void _handleDuplicateAction() {
    if (state.selectionType != SelectionType.none && state.selectedItemId != null) {
      controller.duplicateSelected();
    } else if (state.activeVideoClip != null) {
      controller.duplicateVideoClip(state.activeVideoClip!.id);
    }
  }

  void _handleKeyframeAction() {
    final clipId = state.selectedItemId ?? state.activeVideoClip?.id;
    if (clipId != null) {
      controller.addKeyframeAtPlayhead(clipId);
    }
  }

  @override
  Widget build(BuildContext context) {
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
              // 0. Add Media (Videos & Photos)
              _buildActionButton(
                icon: Icons.add_photo_alternate,
                label: 'Add Media',
                color: const Color(0xFF00FF88),
                onTap: () => _openMediaPicker(context),
              ),

              // 1. Split
              _buildActionButton(
                icon: Icons.splitscreen,
                label: 'Split',
                color: AppColors.primaryLight,
                onTap: _handleSplitAction,
              ),

              // 2. Reorder Clips
              _buildActionButton(
                icon: Icons.reorder,
                label: 'Reorder',
                color: const Color(0xFF00E5FF),
                onTap: () => _openReorderSheet(context),
              ),

              // 3. Speed
              _buildActionButton(
                icon: Icons.speed,
                label: 'Speed',
                color: AppColors.accent,
                onTap: () => _openSpeedSheet(context),
              ),

              // 3. Volume / Original Audio
              _buildActionButton(
                icon: (state.selectedVideoClip?.isMuted ?? state.activeVideoClip?.isMuted ?? false)
                    ? Icons.volume_off
                    : Icons.volume_up,
                label: 'Volume',
                color: (state.selectedVideoClip?.isMuted ?? state.activeVideoClip?.isMuted ?? false)
                    ? AppColors.error
                    : const Color(0xFF00E5FF),
                onTap: () => _openVolumeSheet(context),
              ),

              // 4. Animations
              _buildActionButton(
                icon: Icons.animation,
                label: 'Animation',
                color: AppColors.accent,
                onTap: () => _openAnimationSheet(context),
              ),

              // 4. Effects (70+ CapCut effects)
              _buildActionButton(
                icon: Icons.auto_fix_high,
                label: 'Effects',
                color: const Color(0xFF00E5FF),
                onTap: () => _openEffectsSheet(context),
              ),

              // 5. Mask
              _buildActionButton(
                icon: Icons.masks,
                label: 'Mask',
                color: AppColors.secondary,
                onTap: () => _openMaskSheet(context),
              ),

              // 6. Chroma Key
              _buildActionButton(
                icon: Icons.colorize,
                label: 'Chroma Key',
                color: const Color(0xFF00FF88),
                onTap: () => _openChromaKeySheet(context),
              ),

              // 7. Filters
              _buildActionButton(
                icon: Icons.filter_vintage,
                label: 'Filters',
                color: AppColors.secondary,
                onTap: () => _openFilterPicker(context),
              ),

              // 8. Adjust (Color & Brightness)
              _buildActionButton(
                icon: Icons.tune,
                label: 'Adjust',
                color: AppColors.secondaryLight,
                onTap: () => _openColorAdjustments(context),
              ),

              // 9. Overlay (PIP)
              _buildActionButton(
                icon: Icons.layers,
                label: 'Overlay (PIP)',
                color: AppColors.accentRose,
                onTap: () => _openOverlayPicker(context),
              ),

              // 10. Keyframe
              _buildActionButton(
                icon: Icons.diamond_outlined,
                label: 'Keyframe',
                color: AppColors.accent,
                onTap: _handleKeyframeAction,
              ),

              // 11. Duplicate
              _buildActionButton(
                icon: Icons.control_point_duplicate,
                label: 'Duplicate',
                color: AppColors.primaryLight,
                onTap: _handleDuplicateAction,
              ),

              // 12. Replace
              _buildActionButton(
                icon: Icons.swap_horiz,
                label: 'Replace',
                color: AppColors.secondary,
                onTap: () => _handleReplaceAction(context),
              ),

              // 13. Crop / Frame
              _buildActionButton(
                icon: Icons.crop,
                label: 'Crop/Frame',
                color: AppColors.primaryLight,
                onTap: () => _openCropTransformSheet(context),
              ),

              // 14. Text
              _buildActionButton(
                icon: Icons.title,
                label: 'Text',
                color: AppColors.textTrack,
                onTap: () => _openTextEditor(context),
              ),

              // 15. Stickers
              _buildActionButton(
                icon: Icons.emoji_emotions,
                label: 'Stickers',
                color: AppColors.stickerTrack,
                onTap: () => _openStickerPicker(context),
              ),

              // 16. Voiceover
              _buildActionButton(
                icon: Icons.mic,
                label: 'Voiceover',
                color: AppColors.voiceoverTrack,
                onTap: () => _openVoiceoverModal(context),
              ),

              // 17. Audio Mix
              _buildActionButton(
                icon: Icons.equalizer,
                label: 'Audio Mix',
                color: AppColors.audioTrack,
                onTap: () => _openAudioMixer(context),
              ),

              // 18. Transitions
              _buildActionButton(
                icon: Icons.transform,
                label: 'Transitions',
                color: AppColors.primaryLight,
                onTap: () => _openTransitionPicker(context),
              ),

              // 19. Add Clip
              _buildActionButton(
                icon: Icons.add_to_photos,
                label: 'Add Clip',
                color: AppColors.success,
                onTap: () => _openMediaPicker(context),
              ),

              // 20. Captions
              _buildActionButton(
                icon: Icons.subtitles,
                label: 'Captions',
                color: AppColors.textTrack,
                onTap: () => _openCaptionSheet(context),
              ),

              // 21. Delete
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
