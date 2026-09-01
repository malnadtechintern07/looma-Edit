enum TransitionType {
  none('None'),
  crossFade('Cross Fade'),
  slideLeft('Slide Left'),
  slideUp('Slide Up'),
  wipeRight('Wipe Right'),
  zoomIn('Zoom In'),
  glitch('Glitch');

  final String label;
  const TransitionType(this.label);

  static TransitionType fromString(String? val) {
    return TransitionType.values.firstWhere(
      (e) => e.name == val,
      orElse: () => TransitionType.none,
    );
  }
}
