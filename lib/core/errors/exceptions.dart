/// Base Exception for all data/infrastructure errors in LOOMA
abstract class AppException implements Exception {
  final String message;
  final String? code;

  const AppException(this.message, [this.code]);

  @override
  String toString() => 'AppException: $message (code: $code)';
}

/// Database & File Storage Exceptions
class DatabaseException extends AppException {
  const DatabaseException(super.message, [super.code]);
}

class StorageException extends AppException {
  const StorageException(super.message, [super.code]);
}

/// Video Processing & Media Exceptions
class VideoProcessingException extends AppException {
  const VideoProcessingException(super.message, [super.code]);
}

class MediaNotFoundException extends AppException {
  const MediaNotFoundException(super.message, [super.code]);
}

/// Network & Cloud Sync Exceptions
class NetworkException extends AppException {
  const NetworkException(super.message, [super.code]);
}

class SyncConflictException extends AppException {
  const SyncConflictException(super.message, [super.code]);
}
