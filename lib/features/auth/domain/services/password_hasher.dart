import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

class PasswordHasher {
  static const int _saltBytesLength = 16;
  static const int _iterations = 1000;

  static String generateSalt() {
    final rand = Random.secure();
    final bytes = List<int>.generate(_saltBytesLength, (_) => rand.nextInt(256));
    return base64Url.encode(bytes);
  }

  static String hashPassword(String password, String salt) {
    List<int> current = utf8.encode('$password::$salt');
    for (int i = 0; i < _iterations; i++) {
      current = sha256.convert(current).bytes;
    }
    return base64Url.encode(current);
  }

  static bool verifyPassword(String password, String salt, String expectedHash) {
    final hash = hashPassword(password, salt);
    if (hash.length != expectedHash.length) return false;
    int result = 0;
    for (int i = 0; i < hash.length; i++) {
      result |= hash.codeUnitAt(i) ^ expectedHash.codeUnitAt(i);
    }
    return result == 0;
  }
}
