import 'package:uuid/uuid.dart';

/// Unique ID generation utility
class IdGenerator {
  static const Uuid _uuid = Uuid();

  /// Generates a UUID v4 string
  static String generate() => _uuid.v4();

  /// Generates a short human-friendly slug ID (e.g. for projects)
  static String generateShort() => _uuid.v4().substring(0, 8);
}
