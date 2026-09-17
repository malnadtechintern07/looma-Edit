import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app.dart';
import 'core/config/server_config.dart';
import 'core/storage/local_storage_service.dart';
import 'core/storage/storage_providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storageService = LocalStorageService();
  await storageService.init();

  // Fast pre-warm backend server connection cache
  ServerConfig.getBaseUrl().ignore();

  runApp(
    ProviderScope(
      overrides: [
        localStorageServiceProvider.overrideWithValue(storageService),
      ],
      child: const ProCutApp(),
    ),
  );
}
