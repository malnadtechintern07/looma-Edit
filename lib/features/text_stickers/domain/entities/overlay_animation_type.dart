enum OverlayAnimationType {
  none('None'),
  fadeIn('Fade In'),
  typewriter('Typewriter'),
  slideUp('Slide Up'),
  bounce('Bounce'),
  glitch('Glitch Wave'),
  glow('Neon Pulse'),
  slideDown('Slide Down'),
  slideLeft('Slide Left'),
  slideRight('Slide Right'),
  zoomIn('Pop In'),
  zoomOut('Zoom Out'),
  spin('Spin In'),
  flip('3D Flip'),
  pulse('Heartbeat'),
  shake('Shake'),
  drop('Drop In'),
  wave('Wave Float'),
  flash('Flash Strobe'),
  swing('Swing'),
  blur('Blur In');

  final String label;
  const OverlayAnimationType(this.label);

  static OverlayAnimationType fromString(String? val) {
    return OverlayAnimationType.values.firstWhere(
      (e) => e.name == val,
      orElse: () => OverlayAnimationType.none,
    );
  }
}
