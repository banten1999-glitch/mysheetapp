enum SyncStatus {
  pending,
  syncing,
  synced,
  failed;

  String get label => switch (this) {
        SyncStatus.pending => 'بانتظار المزامنة',
        SyncStatus.syncing => 'جارٍ الرفع...',
        SyncStatus.synced => 'تمت المزامنة',
        SyncStatus.failed => 'فشلت المزامنة',
      };

  static SyncStatus fromName(String name) =>
      SyncStatus.values.firstWhere((e) => e.name == name, orElse: () => SyncStatus.pending);
}
