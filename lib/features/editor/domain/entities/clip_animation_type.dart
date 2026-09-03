import 'package:flutter/material.dart';

enum ClipAnimationIn {
  none,
  fadeIn,
  slideInLeft,
  slideInRight,
  slideInUp,
  slideInDown,
  zoomIn,
  popIn,
  bounceIn,
  rotateIn,
  blurIn,
  flipInX,
  flipInY,
  spinIn,
  swingIn,
  dropIn,
}

enum ClipAnimationOut {
  none,
  fadeOut,
  slideOutLeft,
  slideOutRight,
  slideOutUp,
  slideOutDown,
  zoomOut,
  popOut,
  rotateOut,
  blurOut,
  flipOutX,
  flipOutY,
  spinOut,
  swingOut,
  shrinkOut,
}

enum ClipAnimationCombo {
  none,
  pulse,
  zoomRotate,
  shake,
  bounce,
  floating,
  heartbeat,
  sway,
  pendulum,
  wobble,
  flashBeat,
  spin360,
  rubberBand,
  jiggle,
}

extension ClipAnimationInExt on ClipAnimationIn {
  String get label {
    switch (this) {
      case ClipAnimationIn.none:
        return 'None';
      case ClipAnimationIn.fadeIn:
        return 'Fade In';
      case ClipAnimationIn.slideInLeft:
        return 'Slide Left';
      case ClipAnimationIn.slideInRight:
        return 'Slide Right';
      case ClipAnimationIn.slideInUp:
        return 'Slide Up';
      case ClipAnimationIn.slideInDown:
        return 'Slide Down';
      case ClipAnimationIn.zoomIn:
        return 'Zoom In';
      case ClipAnimationIn.popIn:
        return 'Pop In';
      case ClipAnimationIn.bounceIn:
        return 'Bounce In';
      case ClipAnimationIn.rotateIn:
        return 'Rotate In';
      case ClipAnimationIn.blurIn:
        return 'Blur In';
      case ClipAnimationIn.flipInX:
        return 'Flip X';
      case ClipAnimationIn.flipInY:
        return 'Flip Y';
      case ClipAnimationIn.spinIn:
        return 'Spin In';
      case ClipAnimationIn.swingIn:
        return 'Swing In';
      case ClipAnimationIn.dropIn:
        return 'Drop In';
    }
  }

  IconData get icon {
    switch (this) {
      case ClipAnimationIn.none:
        return Icons.block;
      case ClipAnimationIn.fadeIn:
        return Icons.gradient;
      case ClipAnimationIn.slideInLeft:
        return Icons.arrow_forward;
      case ClipAnimationIn.slideInRight:
        return Icons.arrow_back;
      case ClipAnimationIn.slideInUp:
        return Icons.arrow_upward;
      case ClipAnimationIn.slideInDown:
        return Icons.arrow_downward;
      case ClipAnimationIn.zoomIn:
        return Icons.zoom_in;
      case ClipAnimationIn.popIn:
        return Icons.aspect_ratio;
      case ClipAnimationIn.bounceIn:
        return Icons.sports_volleyball;
      case ClipAnimationIn.rotateIn:
        return Icons.rotate_right;
      case ClipAnimationIn.blurIn:
        return Icons.blur_on;
      case ClipAnimationIn.flipInX:
        return Icons.flip;
      case ClipAnimationIn.flipInY:
        return Icons.flip_camera_android;
      case ClipAnimationIn.spinIn:
        return Icons.sync;
      case ClipAnimationIn.swingIn:
        return Icons.swipe;
      case ClipAnimationIn.dropIn:
        return Icons.vertical_align_bottom;
    }
  }

  Color get color1 {
    switch (this) {
      case ClipAnimationIn.none:
        return const Color(0xFF2C2F38);
      case ClipAnimationIn.fadeIn:
        return const Color(0xFFF7971E);
      case ClipAnimationIn.slideInLeft:
        return const Color(0xFF00C6FF);
      case ClipAnimationIn.slideInRight:
        return const Color(0xFF0072FF);
      case ClipAnimationIn.slideInUp:
        return const Color(0xFF11998E);
      case ClipAnimationIn.slideInDown:
        return const Color(0xFF38EF7D);
      case ClipAnimationIn.zoomIn:
        return const Color(0xFFFF416C);
      case ClipAnimationIn.popIn:
        return const Color(0xFF8E2DE2);
      case ClipAnimationIn.bounceIn:
        return const Color(0xFFFF9900);
      case ClipAnimationIn.rotateIn:
        return const Color(0xFFFC5C7D);
      case ClipAnimationIn.blurIn:
        return const Color(0xFF4A00E0);
      case ClipAnimationIn.flipInX:
        return const Color(0xFF302B63);
      case ClipAnimationIn.flipInY:
        return const Color(0xFF24243E);
      case ClipAnimationIn.spinIn:
        return const Color(0xFF00F2FE);
      case ClipAnimationIn.swingIn:
        return const Color(0xFFF857A6);
      case ClipAnimationIn.dropIn:
        return const Color(0xFFFF5858);
    }
  }

  Color get color2 {
    switch (this) {
      case ClipAnimationIn.none:
        return const Color(0xFF1E2028);
      default:
        return const Color(0xFF161822);
    }
  }
}

extension ClipAnimationOutExt on ClipAnimationOut {
  String get label {
    switch (this) {
      case ClipAnimationOut.none:
        return 'None';
      case ClipAnimationOut.fadeOut:
        return 'Fade Out';
      case ClipAnimationOut.slideOutLeft:
        return 'Slide Left';
      case ClipAnimationOut.slideOutRight:
        return 'Slide Right';
      case ClipAnimationOut.slideOutUp:
        return 'Slide Up';
      case ClipAnimationOut.slideOutDown:
        return 'Slide Down';
      case ClipAnimationOut.zoomOut:
        return 'Zoom Out';
      case ClipAnimationOut.popOut:
        return 'Pop Out';
      case ClipAnimationOut.rotateOut:
        return 'Rotate Out';
      case ClipAnimationOut.blurOut:
        return 'Blur Out';
      case ClipAnimationOut.flipOutX:
        return 'Flip X';
      case ClipAnimationOut.flipOutY:
        return 'Flip Y';
      case ClipAnimationOut.spinOut:
        return 'Spin Out';
      case ClipAnimationOut.swingOut:
        return 'Swing Out';
      case ClipAnimationOut.shrinkOut:
        return 'Shrink Out';
    }
  }

  IconData get icon {
    switch (this) {
      case ClipAnimationOut.none:
        return Icons.block;
      case ClipAnimationOut.fadeOut:
        return Icons.gradient;
      case ClipAnimationOut.slideOutLeft:
        return Icons.arrow_back;
      case ClipAnimationOut.slideOutRight:
        return Icons.arrow_forward;
      case ClipAnimationOut.slideOutUp:
        return Icons.arrow_upward;
      case ClipAnimationOut.slideOutDown:
        return Icons.arrow_downward;
      case ClipAnimationOut.zoomOut:
        return Icons.zoom_out;
      case ClipAnimationOut.popOut:
        return Icons.fullscreen_exit;
      case ClipAnimationOut.rotateOut:
        return Icons.rotate_left;
      case ClipAnimationOut.blurOut:
        return Icons.blur_off;
      case ClipAnimationOut.flipOutX:
        return Icons.flip;
      case ClipAnimationOut.flipOutY:
        return Icons.flip_camera_android;
      case ClipAnimationOut.spinOut:
        return Icons.sync_disabled;
      case ClipAnimationOut.swingOut:
        return Icons.swipe;
      case ClipAnimationOut.shrinkOut:
        return Icons.compress;
    }
  }

  Color get color1 {
    switch (this) {
      case ClipAnimationOut.none:
        return const Color(0xFF2C2F38);
      case ClipAnimationOut.fadeOut:
        return const Color(0xFF434343);
      case ClipAnimationOut.slideOutLeft:
        return const Color(0xFF654EA3);
      case ClipAnimationOut.slideOutRight:
        return const Color(0xFFEAAFC8);
      case ClipAnimationOut.slideOutUp:
        return const Color(0xFFB92B27);
      case ClipAnimationOut.slideOutDown:
        return const Color(0xFF1565C0);
      case ClipAnimationOut.zoomOut:
        return const Color(0xFFFDC830);
      case ClipAnimationOut.popOut:
        return const Color(0xFFF37335);
      case ClipAnimationOut.rotateOut:
        return const Color(0xFFE52D27);
      case ClipAnimationOut.blurOut:
        return const Color(0xFF4A00E0);
      case ClipAnimationOut.flipOutX:
        return const Color(0xFF134E5E);
      case ClipAnimationOut.flipOutY:
        return const Color(0xFF71B280);
      case ClipAnimationOut.spinOut:
        return const Color(0xFFFF0844);
      case ClipAnimationOut.swingOut:
        return const Color(0xFFFFB199);
      case ClipAnimationOut.shrinkOut:
        return const Color(0xFF3A1C71);
    }
  }

  Color get color2 {
    switch (this) {
      case ClipAnimationOut.none:
        return const Color(0xFF1E2028);
      default:
        return const Color(0xFF161822);
    }
  }
}

extension ClipAnimationComboExt on ClipAnimationCombo {
  String get label {
    switch (this) {
      case ClipAnimationCombo.none:
        return 'None';
      case ClipAnimationCombo.pulse:
        return 'Pulse';
      case ClipAnimationCombo.zoomRotate:
        return 'Zoom + Rotate';
      case ClipAnimationCombo.shake:
        return 'Shake';
      case ClipAnimationCombo.bounce:
        return 'Bounce';
      case ClipAnimationCombo.floating:
        return 'Floating';
      case ClipAnimationCombo.heartbeat:
        return 'Heartbeat';
      case ClipAnimationCombo.sway:
        return 'Sway';
      case ClipAnimationCombo.pendulum:
        return 'Pendulum';
      case ClipAnimationCombo.wobble:
        return 'Wobble';
      case ClipAnimationCombo.flashBeat:
        return 'Flash Beat';
      case ClipAnimationCombo.spin360:
        return 'Spin 360';
      case ClipAnimationCombo.rubberBand:
        return 'Rubber Band';
      case ClipAnimationCombo.jiggle:
        return 'Jiggle';
    }
  }

  IconData get icon {
    switch (this) {
      case ClipAnimationCombo.none:
        return Icons.block;
      case ClipAnimationCombo.pulse:
        return Icons.favorite;
      case ClipAnimationCombo.zoomRotate:
        return Icons.rotate_right;
      case ClipAnimationCombo.shake:
        return Icons.vibration;
      case ClipAnimationCombo.bounce:
        return Icons.sports_volleyball;
      case ClipAnimationCombo.floating:
        return Icons.air;
      case ClipAnimationCombo.heartbeat:
        return Icons.monitor_heart;
      case ClipAnimationCombo.sway:
        return Icons.waves;
      case ClipAnimationCombo.pendulum:
        return Icons.schedule;
      case ClipAnimationCombo.wobble:
        return Icons.blur_circular;
      case ClipAnimationCombo.flashBeat:
        return Icons.flash_on;
      case ClipAnimationCombo.spin360:
        return Icons.loop;
      case ClipAnimationCombo.rubberBand:
        return Icons.straighten;
      case ClipAnimationCombo.jiggle:
        return Icons.motion_photos_on;
    }
  }

  Color get color1 {
    switch (this) {
      case ClipAnimationCombo.none:
        return const Color(0xFF2C2F38);
      case ClipAnimationCombo.pulse:
        return const Color(0xFFFF007A);
      case ClipAnimationCombo.zoomRotate:
        return const Color(0xFF00C6FF);
      case ClipAnimationCombo.shake:
        return const Color(0xFFE52D27);
      case ClipAnimationCombo.bounce:
        return const Color(0xFFFF9900);
      case ClipAnimationCombo.floating:
        return const Color(0xFF11998E);
      case ClipAnimationCombo.heartbeat:
        return const Color(0xFFFF416C);
      case ClipAnimationCombo.sway:
        return const Color(0xFF8E2DE2);
      case ClipAnimationCombo.pendulum:
        return const Color(0xFF4A00E0);
      case ClipAnimationCombo.wobble:
        return const Color(0xFF00F2FE);
      case ClipAnimationCombo.flashBeat:
        return const Color(0xFFFFD200);
      case ClipAnimationCombo.spin360:
        return const Color(0xFFFC5C7D);
      case ClipAnimationCombo.rubberBand:
        return const Color(0xFF6A82FB);
      case ClipAnimationCombo.jiggle:
        return const Color(0xFF00F5D4);
    }
  }

  Color get color2 {
    switch (this) {
      case ClipAnimationCombo.none:
        return const Color(0xFF1E2028);
      default:
        return const Color(0xFF161822);
    }
  }
}
