import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Singleton SQLite handle. Holds the offline queue of ledger entries.
class AppDatabase {
  AppDatabase._internal();

  static final AppDatabase instance = AppDatabase._internal();

  static const String tableTransactions = 'transactions';

  Database? _db;

  Future<Database> get database async {
    final existing = _db;
    if (existing != null) return existing;
    final created = await _open();
    _db = created;
    return created;
  }

  Future<Database> _open() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'hasnawi_ledger.db');
    return openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $tableTransactions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            transaction_id TEXT NOT NULL UNIQUE,
            serial INTEGER NOT NULL UNIQUE,
            date TEXT NOT NULL,
            time TEXT NOT NULL,
            statement TEXT NOT NULL,
            receipt_url TEXT,
            note TEXT,
            local_image_path TEXT,
            drive_file_id TEXT,
            debit_amount REAL,
            credit_amount REAL,
            sync_status TEXT NOT NULL DEFAULT 'pending',
            error_message TEXT,
            created_at INTEGER NOT NULL,
            pending_delete INTEGER NOT NULL DEFAULT 0
          )
        ''');
        await db.execute(
          'CREATE INDEX idx_transactions_sync_status ON $tableTransactions(sync_status)',
        );
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            'ALTER TABLE $tableTransactions ADD COLUMN pending_delete INTEGER NOT NULL DEFAULT 0',
          );
        }
      },
    );
  }
}
