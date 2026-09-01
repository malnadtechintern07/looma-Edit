enum AspectRatioType {
  ratio16_9('16:9', 16 / 9, 'Landscape (YouTube)'),
  ratio9_16('9:16', 9 / 16, 'Portrait (Reels / TikTok / Shorts)'),
  ratio1_1('1:1', 1.0, 'Square (Instagram Post)'),
  ratio4_5('4:5', 4 / 5, 'Portrait (Feed)'),
  ratio21_9('21:9', 21 / 9, 'Cinematic Ultrawide');

  final String label;
  final double ratio;
  final String description;

  const AspectRatioType(this.label, this.ratio, this.description);

  static AspectRatioType fromString(String? val) {
    return AspectRatioType.values.firstWhere(
      (e) => e.name == val || e.label == val,
      orElse: () => AspectRatioType.ratio9_16,
    );
  }
}
