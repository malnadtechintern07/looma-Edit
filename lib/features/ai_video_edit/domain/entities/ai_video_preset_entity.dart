class AiVideoPresetEntity {
  final String id;
  final String title;
  final String category;
  final String videoAssetPath;
  final String prompt;
  final String negativePrompt;
  final String durationText;
  final String style;
  final String modelName;
  final String cameraMovement;
  final String lighting;
  final String seed;
  final List<String> tags;

  const AiVideoPresetEntity({
    required this.id,
    required this.title,
    required this.category,
    required this.videoAssetPath,
    required this.prompt,
    this.negativePrompt = 'blurry, low resolution, artifacts, distorted, flickering, jittery, watermark',
    this.durationText = '5s',
    this.style = 'Cinematic Photorealism',
    this.modelName = 'Sora / Runway Gen-3',
    this.cameraMovement = 'Smooth Cinematic Dolly',
    this.lighting = 'Volumetric Atmospheric',
    this.seed = '8492019',
    this.tags = const [],
  });
}
