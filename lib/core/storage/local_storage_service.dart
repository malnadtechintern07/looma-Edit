import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

/// Service responsible for raw file-system I/O and persistent JSON storage.
class LocalStorageService {
  static final LocalStorageService _instance = LocalStorageService._internal();
  factory LocalStorageService() => _instance;
  LocalStorageService._internal();

  Directory? _documentsDirectory;
  SharedPreferences? _prefs;
  final Map<String, String> _inMemoryFallback = {};

  /// Initialize local storage directory and shared preferences
  Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
    } catch (e) {
      debugPrint('SharedPreferences init error: $e');
    }

    if (kIsWeb) return;

    try {
      _documentsDirectory = await getApplicationDocumentsDirectory();
    } catch (e) {
      try {
        _documentsDirectory = await getApplicationSupportDirectory();
      } catch (_) {
        try {
          final home = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
          if (home != null && home.isNotEmpty) {
            _documentsDirectory = Directory('$home/.looma_data');
          }
        } catch (_) {}
      }
    }

    if (_documentsDirectory != null) {
      try {
        final projectDir = Directory('${_documentsDirectory!.path}/${AppConstants.projectsDirectory}');
        if (!await projectDir.exists()) {
          await projectDir.create(recursive: true);
        }
        final exportDir = Directory('${_documentsDirectory!.path}/${AppConstants.exportDirectory}');
        if (!await exportDir.exists()) {
          await exportDir.create(recursive: true);
        }
      } catch (e) {
        debugPrint('LocalStorageService create directory error: $e');
      }
    }
  }

  final Map<String, Future<void>> _fileWriteQueues = {};

  /// Write string content to a file path and shared preferences atomically
  Future<void> writeString(String relativePath, String content) async {
    _inMemoryFallback[relativePath] = content;

    final previousWrite = _fileWriteQueues[relativePath] ?? Future.value();
    final currentWrite = previousWrite.then((_) async {
      // 1. Persist to SharedPreferences
      try {
        _prefs ??= await SharedPreferences.getInstance();
        await _prefs?.setString('looma_$relativePath', content);
      } catch (e) {
        debugPrint('SharedPreferences write error: $e');
      }

      // 2. Persist to physical disk file
      if (!kIsWeb) {
        if (_documentsDirectory == null) {
          await init();
        }
        if (_documentsDirectory != null) {
          try {
            final file = File('${_documentsDirectory!.path}/$relativePath');
            await file.parent.create(recursive: true);
            await file.writeAsString(content, flush: true);
          } catch (e) {
            debugPrint('LocalStorageService writeString error: $e');
          }
        }
      }
    });

    _fileWriteQueues[relativePath] = currentWrite;
    await currentWrite;
  }

  /// Read string content from shared preferences, in-memory, or physical disk
  Future<String?> readString(String relativePath) async {
    // 1. Check in-memory cache
    if (_inMemoryFallback.containsKey(relativePath)) {
      return _inMemoryFallback[relativePath];
    }

    // 2. Check SharedPreferences
    try {
      _prefs ??= await SharedPreferences.getInstance();
      final prefVal = _prefs?.getString('looma_$relativePath');
      if (prefVal != null && prefVal.isNotEmpty) {
        _inMemoryFallback[relativePath] = prefVal;
        return prefVal;
      }
    } catch (e) {
      debugPrint('SharedPreferences read error: $e');
    }

    // 3. Check physical disk file
    if (!kIsWeb) {
      if (_documentsDirectory == null) {
        await init();
      }
      if (!kIsWeb && _documentsDirectory != null) {
        try {
          final file = File('${_documentsDirectory!.path}/$relativePath');
          if (await file.exists()) {
            final content = await file.readAsString();
            _inMemoryFallback[relativePath] = content;
            return content;
          }
        } catch (e) {
          debugPrint('LocalStorageService readString error: $e');
        }
      }
    }

    return null;
  }

  /// Write JSON serializable Map
  Future<void> writeJson(String relativePath, Map<String, dynamic> jsonMap) async {
    final encoded = jsonEncode(jsonMap);
    await writeString(relativePath, encoded);
  }

  Map<String, dynamic>? _tryRepairJson(String raw) {
    try {
      final startIdx = raw.indexOf('{');
      final lastIdx = raw.lastIndexOf('}');
      if (startIdx != -1 && lastIdx != -1 && lastIdx > startIdx) {
        final candidate = raw.substring(startIdx, lastIdx + 1);
        try {
          final decoded = jsonDecode(candidate);
          if (decoded is Map<String, dynamic>) return decoded;
        } catch (_) {
          // If candidate still has unbalanced braces, step backwards to find valid closing brace
          for (int i = lastIdx - 1; i > startIdx; i--) {
            if (raw[i] == '}') {
              try {
                final sub = raw.substring(startIdx, i + 1);
                final d = jsonDecode(sub);
                if (d is Map<String, dynamic>) return d;
              } catch (_) {}
            }
          }
        }
      }
    } catch (_) {}
    return null;
  }

  /// Read JSON Map with automatic corruption fallback and self-healing
  Future<Map<String, dynamic>?> readJson(String relativePath) async {
    final raw = await readString(relativePath);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return null;
    } catch (e) {
      // 1. Try automatic JSON repair (e.g. trailing extra brace)
      final repaired = _tryRepairJson(raw);
      if (repaired != null) {
        // Self-heal corrupted file on disk
        writeString(relativePath, jsonEncode(repaired));
        return repaired;
      }

      // 2. Fallback: Check SharedPreferences directly if file was corrupted
      try {
        _prefs ??= await SharedPreferences.getInstance();
        final prefVal = _prefs?.getString('looma_$relativePath');
        if (prefVal != null && prefVal.isNotEmpty) {
          try {
            final decoded = jsonDecode(prefVal);
            if (decoded is Map<String, dynamic>) {
              return decoded;
            }
          } catch (_) {
            final repairedPref = _tryRepairJson(prefVal);
            if (repairedPref != null) return repairedPref;
          }
        }
      } catch (_) {}
      debugPrint('LocalStorageService decode error from $relativePath: $e');
      return null;
    }
  }

  /// Clear all cache and storage (primarily for tests)
  Future<void> clearAll() async {
    _inMemoryFallback.clear();
    _fileWriteQueues.clear();
    try {
      _prefs ??= await SharedPreferences.getInstance();
      await _prefs?.clear();
    } catch (_) {}
    if (!kIsWeb) {
      if (_documentsDirectory == null) {
        await init();
      }
      if (_documentsDirectory != null) {
        try {
          if (await _documentsDirectory!.exists()) {
            final entries = await _documentsDirectory!.list().toList();
            for (final entry in entries) {
              try {
                await entry.delete(recursive: true);
              } catch (_) {}
            }
          }
        } catch (_) {}
      }
    }
  }

  /// Delete a file
  Future<bool> deleteFile(String relativePath) async {
    _inMemoryFallback.remove(relativePath);

    // Remove from SharedPreferences
    try {
      _prefs ??= await SharedPreferences.getInstance();
      await _prefs?.remove('looma_$relativePath');
    } catch (_) {}

    // Remove physical disk file
    if (!kIsWeb) {
      if (_documentsDirectory == null) {
        await init();
      }
      if (_documentsDirectory != null) {
        try {
          final file = File('${_documentsDirectory!.path}/$relativePath');
          if (await file.exists()) {
            await file.delete();
            return true;
          }
        } catch (_) {}
      }
    }
    return true;
  }

  /// List all files matching a prefix in the projects directory
  Future<List<String>> listProjectFiles() async {
    final Set<String> allFiles = {};

    // 1. Check SharedPreferences keys
    try {
      _prefs ??= await SharedPreferences.getInstance();
      final keys = _prefs?.getKeys() ?? {};
      for (final key in keys) {
        if (key.startsWith('looma_${AppConstants.projectsDirectory}/')) {
          allFiles.add(key.replaceFirst('looma_', ''));
        }
      }
    } catch (_) {}

    // 2. Check in-memory fallback
    allFiles.addAll(
      _inMemoryFallback.keys.where((k) => k.startsWith(AppConstants.projectsDirectory)),
    );

    // 3. Check physical disk directory
    if (!kIsWeb) {
      if (_documentsDirectory == null) {
        await init();
      }
      if (_documentsDirectory != null) {
        try {
          final projectDir = Directory('${_documentsDirectory!.path}/${AppConstants.projectsDirectory}');
          if (await projectDir.exists()) {
            final files = await projectDir.list().toList();
            for (final f in files) {
              allFiles.add(f.path.replaceFirst('${_documentsDirectory!.path}/', ''));
            }
          }
        } catch (e) {
          debugPrint('LocalStorageService listProjectFiles error: $e');
        }
      }
    }

    return allFiles.toList();
  }
}
