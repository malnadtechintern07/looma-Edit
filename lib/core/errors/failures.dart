/// Base Failure class representing domain-level error representations
abstract class Failure {
  final String message;
  final String? code;

  const Failure(this.message, [this.code]);

  @override
  String toString() => '$runtimeType: $message';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Failure &&
          runtimeType == other.runtimeType &&
          message == other.message &&
          code == other.code;

  @override
  int get hashCode => Object.hash(runtimeType, message, code);
}

class DatabaseFailure extends Failure {
  const DatabaseFailure(super.message, [super.code]);
}

class StorageFailure extends Failure {
  const StorageFailure(super.message, [super.code]);
}

class MediaProcessingFailure extends Failure {
  const MediaProcessingFailure(super.message, [super.code]);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message, [super.code]);
}

class CloudSyncFailure extends Failure {
  const CloudSyncFailure(super.message, [super.code]);
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message, [super.code]);
}
