class AiPhotoPresetEntity {
  final String id;
  final String title;
  final String category;
  final String prompt;
  final String referenceImagePath;
  final String badgeText;
  final List<String> styleKeywords;
  final String aspectRatio;
  final int likesCount;

  final String? negativePrompt;
  final String? modelRecommendation;
  final String? lightingStyle;
  final String? cameraLens;

  const AiPhotoPresetEntity({
    required this.id,
    required this.title,
    required this.category,
    required this.prompt,
    required this.referenceImagePath,
    required this.badgeText,
    this.styleKeywords = const [],
    this.aspectRatio = '3:4',
    this.likesCount = 1240,
    this.negativePrompt,
    this.modelRecommendation,
    this.lightingStyle,
    this.cameraLens,
  });
}
