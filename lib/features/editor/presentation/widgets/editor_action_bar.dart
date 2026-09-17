import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/services/app_remote_config_service.dart';
import '../../../../core/widgets/responsive_tap_button.dart';
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

class EditorActionBar extends ConsumerWidget {
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
    final allClips = state.project.videoClips;
    if (allClips.isEmpty) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF161822),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => ReorderClipsSheet(
        clips: allClips,
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

  void _openTextEditor(BuildContext context, {TextOverlayEntity? initialText, bool forceAddNew = false}) {
    final selectedText = forceAddNew
        ? null
        : (initialText ??
            (state.selectionType == SelectionType.textOverlay ? state.selectedTextOverlay : null));

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
      controller.toggleKeyframeAtPlayhead(clipId);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Remote config tools — sorted, filtered by enabled
    final remoteTools = ref.watch(appRemoteConfigProvider).valueOrNull?.videoEditorTools ?? [];
    final enabledKeys = remoteTools.isEmpty
        ? null // null = no remote config, show all
        : {for (final t in remoteTools) t.key: t};

    // Helper: should a given tool key be shown?
    bool shouldShow(String key) {
      if (enabledKeys == null) return true;
      return enabledKeys[key]?.enabled ?? true;
    }

    // Helper: label from remote config, fallback to local label
    String toolLabel(String key, String fallback) {
      if (enabledKeys == null) return fallback;
      return enabledKeys[key]?.label ?? fallback;
    }

    // Build the ordered list of buttons
    final List<Widget> toolButtons = [];

    void addBtn(String key, String defaultLabel, IconData icon, Color color, VoidCallback onTap, {Widget? customWidget}) {
      if (!shouldShow(key)) return;
      if (customWidget != null) {
        toolButtons.add(customWidget);
      } else {
        toolButtons.add(_buildActionButton(
          icon: icon,
          label: toolLabel(key, defaultLabel),
          color: color,
          onTap: onTap,
        ));
      }
    }

    addBtn('add_media',   'Add Media',    Icons.add_photo_alternate,        const Color(0xFF00FF88),   () => _openMediaPicker(context));
    addBtn('split',       'Split',        Icons.splitscreen,                 AppColors.primaryLight,    _handleSplitAction);
    addBtn('reorder',     'Reorder',      Icons.reorder,                     const Color(0xFF00E5FF),   () => _openReorderSheet(context));
    addBtn('speed',       'Speed',        Icons.speed,                       AppColors.accent,          () => _openSpeedSheet(context));
    addBtn('volume',      'Volume',
      (state.selectedVideoClip?.isMuted ?? state.activeVideoClip?.isMuted ?? false) ? Icons.volume_off : Icons.volume_up,
      (state.selectedVideoClip?.isMuted ?? state.activeVideoClip?.isMuted ?? false) ? AppColors.error : const Color(0xFF00E5FF),
      () => _openVolumeSheet(context));
    addBtn('animation',   'Animation',    Icons.animation,                   AppColors.accent,          () => _openAnimationSheet(context));
    addBtn('effects',     'Effects',      Icons.auto_fix_high,               const Color(0xFF00E5FF),   () => _openEffectsSheet(context));
    addBtn('mask',        'Mask',         Icons.masks,                       AppColors.secondary,       () => _openMaskSheet(context));
    addBtn('chroma_key',  'Chroma Key',   Icons.colorize,                    const Color(0xFF00FF88),   () => _openChromaKeySheet(context));
    addBtn('filters',     'Filters',      Icons.filter_vintage,              AppColors.secondary,       () => _openFilterPicker(context));
    addBtn('adjust',      'Adjust',       Icons.tune,                        AppColors.secondaryLight,  () => _openColorAdjustments(context));
    addBtn('overlay',     'Overlay (PIP)',Icons.layers,                      AppColors.accentRose,      () => _openOverlayPicker(context));

    // Keyframe — special (needs Builder for live state)
    if (shouldShow('keyframe')) {
      toolButtons.add(Builder(builder: (context) {
        final clipId = state.selectedItemId ?? state.activeVideoClip?.id;
        final isAtKf = clipId != null && controller.isAtKeyframe(clipId);
        return _buildActionButton(
          icon: isAtKf ? Icons.diamond : Icons.diamond_outlined,
          label: isAtKf ? 'Remove KF' : toolLabel('keyframe', 'Keyframe'),
          color: isAtKf ? AppColors.accentRose : AppColors.accent,
          onTap: _handleKeyframeAction,
        );
      }));
    }

    addBtn('duplicate',   'Duplicate',    Icons.control_point_duplicate,     AppColors.primaryLight,    _handleDuplicateAction);
    addBtn('replace',     'Replace',      Icons.swap_horiz,                  AppColors.secondary,       () => _handleReplaceAction(context));
    addBtn('crop',        'Crop/Frame',   Icons.crop,                        AppColors.primaryLight,    () => _openCropTransformSheet(context));
    addBtn('text',        'Text',         Icons.title,                       AppColors.textTrack,       () => _openTextEditor(context, forceAddNew: true));
    addBtn('stickers',    'Stickers',     Icons.emoji_emotions,              AppColors.stickerTrack,    () => _openStickerPicker(context));
    addBtn('voiceover',   'Voiceover',    Icons.mic,                         AppColors.voiceoverTrack,  () => _openVoiceoverModal(context));
    addBtn('audio_mix',   'Audio Mix',    Icons.equalizer,                   AppColors.audioTrack,      () => _openAudioMixer(context));
    addBtn('transitions', 'Transitions',  Icons.transform,                   AppColors.primaryLight,    () => _openTransitionPicker(context));
    addBtn('add_clip',    'Add Clip',     Icons.add_to_photos,               AppColors.success,         () => _openMediaPicker(context));
    addBtn('captions',    'Captions',     Icons.subtitles,                   AppColors.textTrack,       () => _openCaptionSheet(context));
    addBtn('delete',      'Delete',       Icons.delete_outline,              AppColors.error,           controller.deleteSelected);

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
            children: toolButtons,
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
      child: ResponsiveTapButton(
        onTap: onTap,
        pressedScale: 0.90,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          splashColor: color.withValues(alpha: 0.25),
          highlightColor: color.withValues(alpha: 0.10),
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
      ),
    );
  }
}
