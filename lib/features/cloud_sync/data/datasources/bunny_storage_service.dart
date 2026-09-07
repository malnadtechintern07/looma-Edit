import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../domain/entities/bunny_storage_config.dart';

/// Low-level HTTP client interface for Bunny.net Edge Storage API
class BunnyStorageService {
  final BunnyStorageConfig config;
  final HttpClient? _customHttpClient;

  BunnyStorageService({
    required this.config,
    HttpClient? httpClient,
  }) : _customHttpClient = httpClient;

  HttpClient _createHttpClient() {
    final custom = _customHttpClient;
    if (custom != null) return custom;
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 12);
    return client;
  }


  String _cleanPath(String path) {
    var p = path.trim();
    while (p.startsWith('/')) {
      p = p.substring(1);
    }
    return p;
  }

  Uri _buildUri(String remotePath, {bool isDirectory = false}) {
    final clean = _cleanPath(remotePath);
    final endpoint = config.storageEndpoint.trim();
    final zone = config.storageZoneName.trim();
    final pathSuffix = isDirectory
        ? (clean.isEmpty ? '' : '$clean/')
        : clean;
    return Uri.parse('https://$endpoint/$zone/$pathSuffix');
  }

  /// Upload file to Bunny.net storage via HTTP PUT
  Future<bool> uploadFile(
    String remotePath,
    List<int> bytes, {
    String contentType = 'application/json',
  }) async {
    if (!config.hasValidCredentials) return false;
    final client = _createHttpClient();
    try {
      final uri = _buildUri(remotePath);
      final request = await client.putUrl(uri);
      request.headers.set('AccessKey', config.accessKey);
      request.headers.set('Content-Type', contentType);
      request.headers.set('Content-Length', bytes.length.toString());
      request.add(bytes);

      final response = await request.close();
      final statusCode = response.statusCode;
      await response.drain();

      return statusCode == 200 || statusCode == 201;
    } catch (e) {
      debugPrint('BunnyStorageService: uploadFile failed for $remotePath: $e');
      return false;
    } finally {
      if (_customHttpClient == null) client.close();
    }
  }

  /// Download file content from Bunny.net storage via HTTP GET
  Future<String?> downloadFile(String remotePath) async {
    if (!config.hasValidCredentials) return null;
    final client = _createHttpClient();
    try {
      final uri = _buildUri(remotePath);
      final request = await client.getUrl(uri);
      request.headers.set('AccessKey', config.accessKey);
      request.headers.set('Accept', '*/*');

      final response = await request.close();
      if (response.statusCode == 200) {
        final content = await response.transform(utf8.decoder).join();
        return content;
      }
      await response.drain();
      return null;
    } catch (e) {
      debugPrint('BunnyStorageService: downloadFile failed for $remotePath: $e');
      return null;
    } finally {
      if (_customHttpClient == null) client.close();
    }
  }

  /// List objects in a Bunny.net storage directory via HTTP GET
  Future<List<Map<String, dynamic>>?> listFiles(String remoteDirectoryPath) async {
    if (!config.hasValidCredentials) return null;
    final client = _createHttpClient();
    try {
      final uri = _buildUri(remoteDirectoryPath, isDirectory: true);
      final request = await client.getUrl(uri);
      request.headers.set('AccessKey', config.accessKey);
      request.headers.set('Accept', 'application/json');

      final response = await request.close();
      if (response.statusCode == 200) {
        final raw = await response.transform(utf8.decoder).join();
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          return decoded.whereType<Map<String, dynamic>>().toList();
        }
      }
      await response.drain();
      return null;
    } catch (e) {
      debugPrint('BunnyStorageService: listFiles failed for $remoteDirectoryPath: $e');
      return null;
    } finally {
      if (_customHttpClient == null) client.close();
    }
  }

  /// Delete a file from Bunny.net storage via HTTP DELETE
  Future<bool> deleteFile(String remotePath) async {
    if (!config.hasValidCredentials) return false;
    final client = _createHttpClient();
    try {
      final uri = _buildUri(remotePath);
      final request = await client.deleteUrl(uri);
      request.headers.set('AccessKey', config.accessKey);

      final response = await request.close();
      final statusCode = response.statusCode;
      await response.drain();

      // 200 OK or 404 (already deleted) are considered successful
      return statusCode == 200 || statusCode == 404;
    } catch (e) {
      debugPrint('BunnyStorageService: deleteFile failed for $remotePath: $e');
      return false;
    } finally {
      if (_customHttpClient == null) client.close();
    }
  }

  /// Test connectivity to Bunny.net storage zone
  Future<bool> testConnection() async {
    if (!config.hasValidCredentials) return false;
    final client = _createHttpClient();
    try {
      final uri = _buildUri('', isDirectory: true);
      final request = await client.getUrl(uri);
      request.headers.set('AccessKey', config.accessKey);
      request.headers.set('Accept', 'application/json');

      final response = await request.close();
      final statusCode = response.statusCode;
      await response.drain();

      return statusCode == 200;
    } catch (_) {
      return false;
    } finally {
      if (_customHttpClient == null) client.close();
    }
  }
}
