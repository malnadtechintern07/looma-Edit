import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../constants/app_constants.dart';
import '../errors/exceptions.dart';

/// Service responsible for raw file-system I/O and persistent JSON storage.
class LocalStorageService {
  Directory? _documentsDirectory;
  final Map<String, String> _inMemoryFallback = {};

  /// Initialize local storage directory
  Future<void> init() async {
    if (kIsWeb) return;
    try {
      _documentsDirectory = await getApplicationDocumentsDirectory();
      final projectDir = Directory('${_documentsDirectory!.path}/${AppConstants.projectsDirectory}');
      if (!await projectDir.exists()) {
        await projectDir.create(recursive: true);
      }
      final exportDir = Directory('${_documentsDirectory!.path}/${AppConstants.exportDirectory}');
      if (!await exportDir.exists()) {
        await exportDir.create(recursive: true);
      }
    } catch (e) {
      debugPrint('LocalStorageService init fallback to in-memory: $e');
    }
  }

  /// Write string content to a file path or in-memory key
  Future<void> writeString(String relativePath, String content) async {
    if (kIsWeb || _documentsDirectory == null) {
      _inMemoryFallback[relativePath] = content;
      return;
    }
    try {
      final file = File('${_documentsDirectory!.path}/$relativePath');
      await file.parent.create(recursive: true);
      await file.writeAsString(content, flush: true);
    } catch (e) {
      _inMemoryFallback[relativePath] = content;
      throw StorageException('Failed to write file at $relativePath: $e');
    }
  }

  /// Read string content from a file path or in-memory key
  Future<String?> readString(String relativePath) async {
    if (kIsWeb || _documentsDirectory == null) {
      return _inMemoryFallback[relativePath];
    }
    try {
      final file = File('${_documentsDirectory!.path}/$relativePath');
      if (await file.exists()) {
        return await file.readAsString();
      }
      return _inMemoryFallback[relativePath];
    } catch (e) {
      return _inMemoryFallback[relativePath];
    }
  }

  /// Write JSON serializable Map
  Future<void> writeJson(String relativePath, Map<String, dynamic> jsonMap) async {
    final encoded = jsonEncode(jsonMap);
    await writeString(relativePath, encoded);
  }

  /// Read JSON Map
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
      throw StorageException('Failed to decode JSON from $relativePath: $e');
    }
  }

  /// Delete a file
  Future<bool> deleteFile(String relativePath) async {
    _inMemoryFallback.remove(relativePath);
    if (kIsWeb || _documentsDirectory == null) return true;
    try {
      final file = File('${_documentsDirectory!.path}/$relativePath');
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// List all files matching a prefix in the projects directory
  Future<List<String>> listProjectFiles() async {
    if (kIsWeb || _documentsDirectory == null) {
      return _inMemoryFallback.keys
          .where((k) => k.startsWith(AppConstants.projectsDirectory))
          .toList();
    }
    try {
      final projectDir = Directory('${_documentsDirectory!.path}/${AppConstants.projectsDirectory}');
      if (!await projectDir.exists()) {
        return [];
      }
      final files = await projectDir.list().toList();
      return files.map((f) => f.path.replaceFirst('${_documentsDirectory!.path}/', '')).toList();
    } catch (e) {
      return [];
    }
  }
}
