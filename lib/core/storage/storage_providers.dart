import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'local_storage_service.dart';

/// Singleton provider for local file & JSON storage
final localStorageServiceProvider = Provider<LocalStorageService>((ref) {
  final service = LocalStorageService();
  // Init asynchronously
  service.init();
  return service;
});
