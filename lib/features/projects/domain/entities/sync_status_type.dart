enum SyncStatusType {
  localOnly('Saved on device'),
  syncing('Syncing to cloud...'),
  synced('Synced with cloud'),
  error('Sync failed');

  final String label;
  const SyncStatusType(this.label);

  static SyncStatusType fromString(String? val) {
    return SyncStatusType.values.firstWhere(
      (e) => e.name == val,
      orElse: () => SyncStatusType.localOnly,
    );
  }
}
