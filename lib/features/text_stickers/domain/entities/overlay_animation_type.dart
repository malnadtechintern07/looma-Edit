enum OverlayAnimationType {
  none('None'),
  fadeIn('Fade In'),
  typewriter('Typewriter'),
  slideUp('Slide Up'),
  bounce('Bounce'),
  glitch('Glitch Wave'),
  glow('Neon Pulse');

  final String label;
  const OverlayAnimationType(this.label);

  static OverlayAnimationType fromString(String? val) {
    return OverlayAnimationType.values.firstWhere(
      (e) => e.name == val,
      orElse: () => OverlayAnimationType.none,
    );
  }
}
