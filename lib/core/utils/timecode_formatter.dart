/// Formats millisecond timestamps into SMPTE timecodes and UI strings
class TimecodeFormatter {
  /// Format milliseconds into MM:SS.ms (e.g. 01:23.4)
  static String formatMmSsMs(int milliseconds) {
    if (milliseconds < 0) milliseconds = 0;
    final int minutes = (milliseconds ~/ 60000);
    final int seconds = (milliseconds % 60000) ~/ 1000;
    final int tenths = (milliseconds % 1000) ~/ 100;
    final String mm = minutes.toString().padLeft(2, '0');
    final String ss = seconds.toString().padLeft(2, '0');
    return '$mm:$ss.$tenths';
  }

  /// Format milliseconds into standard timecode MM:SS:FF (Frames at given FPS)
  static String formatTimecode(int milliseconds, {int fps = 30}) {
    if (milliseconds < 0) milliseconds = 0;
    final int totalSeconds = milliseconds ~/ 1000;
    final int hours = totalSeconds ~/ 3600;
    final int minutes = (totalSeconds % 3600) ~/ 60;
    final int seconds = totalSeconds % 60;
    final int frameMs = (1000 / fps).round();
    final int frames = ((milliseconds % 1000) / frameMs).floor().clamp(0, fps - 1);

    final String mm = minutes.toString().padLeft(2, '0');
    final String ss = seconds.toString().padLeft(2, '0');
    final String ff = frames.toString().padLeft(2, '0');

    if (hours > 0) {
      final String hh = hours.toString().padLeft(2, '0');
      return '$hh:$mm:$ss:$ff';
    }
    return '$mm:$ss:$ff';
  }

  /// Format milliseconds into human readable duration string (e.g. "2m 15s" or "45s")
  static String formatHumanDuration(int milliseconds) {
    if (milliseconds < 0) milliseconds = 0;
    final int totalSeconds = (milliseconds / 1000).round();
    if (totalSeconds < 60) {
      return '${totalSeconds}s';
    }
    final int minutes = totalSeconds ~/ 60;
    final int remainingSec = totalSeconds % 60;
    if (remainingSec == 0) {
      return '${minutes}m';
    }
    return '${minutes}m ${remainingSec}s';
  }

  /// Format milliseconds into precise decimal seconds (e.g. "2.4s", "0.5s")
  static String formatSecondsPrecise(int milliseconds) {
    if (milliseconds < 0) milliseconds = 0;
    final double secs = milliseconds / 1000.0;
    return '${secs.toStringAsFixed(1)}s';
  }

  /// Format milliseconds into high-precision decimal seconds (e.g. "2.48s", "0.52s")
  static String formatSecondsDetailed(int milliseconds) {
    if (milliseconds < 0) milliseconds = 0;
    final double secs = milliseconds / 1000.0;
    return '${secs.toStringAsFixed(2)}s';
  }

  /// Format milliseconds into MM:SS.hundredths (e.g. 01:23.45)
  static String formatMmSsHundredths(int milliseconds) {
    if (milliseconds < 0) milliseconds = 0;
    final int minutes = (milliseconds ~/ 60000);
    final int seconds = (milliseconds % 60000) ~/ 1000;
    final int hundredths = (milliseconds % 1000) ~/ 10;
    final String mm = minutes.toString().padLeft(2, '0');
    final String ss = seconds.toString().padLeft(2, '0');
    final String hh = hundredths.toString().padLeft(2, '0');
    return '$mm:$ss.$hh';
  }
}
