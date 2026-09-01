import 'sync_status.dart';

/// One row of the ledger, mirroring columns A..I of the linked Google Sheet.
class LedgerEntry {
  const LedgerEntry({
    this.id,
    required this.transactionId,
    required this.serial,
    required this.date,
    required this.time,
    required this.statement,
    this.receiptUrl,
    this.note,
    this.localImagePath,
    this.driveFileId,
    this.debitAmount,
    this.creditAmount,
    required this.syncStatus,
    this.errorMessage,
    required this.createdAt,
    this.pendingDeletion = false,
  });

  /// Local SQLite row id (null before first insert).
  final int? id;

  /// Stable idempotency key - prevents the same operation being written
  /// twice to Google Sheets across retries.
  final String transactionId;

  final int serial;
  final String date; // yyyy-MM-dd
  final String time; // HH:mm
  final String statement; // البيان
  final String? receiptUrl; // رابط صورة الوصل (Drive)
  final String? note; // النص أو الملاحظة
  final String? localImagePath; // pending local file, pre-upload
  final String? driveFileId;
  final double? debitAmount; // مدين له
  final double? creditAmount; // مدين عليه
  final SyncStatus syncStatus;
  final String? errorMessage;
  final DateTime createdAt;
  final bool pendingDeletion;

  bool get hasReceiptImage => localImagePath != null || receiptUrl != null;

  bool get isDebit => (debitAmount ?? 0) > 0;

  double get amount => isDebit ? (debitAmount ?? 0) : (creditAmount ?? 0);

  LedgerEntry copyWith({
    int? id,
    String? transactionId,
    int? serial,
    String? date,
    String? time,
    String? statement,
    String? receiptUrl,
    bool clearReceiptUrl = false,
    String? note,
    bool clearNote = false,
    String? localImagePath,
    bool clearLocalImagePath = false,
    String? driveFileId,
    bool clearDriveFileId = false,
    double? debitAmount,
    bool clearDebitAmount = false,
    double? creditAmount,
    bool clearCreditAmount = false,
    SyncStatus? syncStatus,
    String? errorMessage,
    bool clearErrorMessage = false,
    DateTime? createdAt,
    bool? pendingDeletion,
  }) {
    return LedgerEntry(
      id: id ?? this.id,
      transactionId: transactionId ?? this.transactionId,
      serial: serial ?? this.serial,
      date: date ?? this.date,
      time: time ?? this.time,
      statement: statement ?? this.statement,
      receiptUrl: clearReceiptUrl ? null : (receiptUrl ?? this.receiptUrl),
      note: clearNote ? null : (note ?? this.note),
      localImagePath:
          clearLocalImagePath ? null : (localImagePath ?? this.localImagePath),
      driveFileId: clearDriveFileId ? null : (driveFileId ?? this.driveFileId),
      debitAmount: clearDebitAmount ? null : (debitAmount ?? this.debitAmount),
      creditAmount: clearCreditAmount ? null : (creditAmount ?? this.creditAmount),
      syncStatus: syncStatus ?? this.syncStatus,
      errorMessage: clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      createdAt: createdAt ?? this.createdAt,
      pendingDeletion: pendingDeletion ?? this.pendingDeletion,
    );
  }

  Map<String, Object?> toDbMap() => <String, Object?>{
        'id': id,
        'transaction_id': transactionId,
        'serial': serial,
        'date': date,
        'time': time,
        'statement': statement,
        'receipt_url': receiptUrl,
        'note': note,
        'local_image_path': localImagePath,
        'drive_file_id': driveFileId,
        'debit_amount': debitAmount,
        'credit_amount': creditAmount,
        'sync_status': syncStatus.name,
        'error_message': errorMessage,
        'created_at': createdAt.millisecondsSinceEpoch,
        'pending_delete': pendingDeletion ? 1 : 0,
      };

  factory LedgerEntry.fromDbMap(Map<String, Object?> map) => LedgerEntry(
        id: map['id'] as int?,
        transactionId: map['transaction_id'] as String,
        serial: map['serial'] as int,
        date: map['date'] as String,
        time: map['time'] as String,
        statement: map['statement'] as String,
        receiptUrl: map['receipt_url'] as String?,
        note: map['note'] as String?,
        localImagePath: map['local_image_path'] as String?,
        driveFileId: map['drive_file_id'] as String?,
        debitAmount: (map['debit_amount'] as num?)?.toDouble(),
        creditAmount: (map['credit_amount'] as num?)?.toDouble(),
        syncStatus: SyncStatus.fromName(map['sync_status'] as String),
        errorMessage: map['error_message'] as String?,
        createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
        pendingDeletion: (map['pending_delete'] as int? ?? 0) != 0,
      );

  /// Values keyed by field. The caller places each one at the spreadsheet
  /// column the user mapped it to (see SheetColumns.buildRow), so the sheet
  /// layout stays fully configurable.
  Map<String, Object?> toSheetValues() => <String, Object?>{
        'serial': serial,
        'date': date,
        'time': time,
        'statement': statement,
        'receipt': receiptUrl ?? '',
        'note': note ?? '',
        'debit': debitAmount ?? '',
        'credit': creditAmount ?? '',
        'transactionId': transactionId,
      };
}
