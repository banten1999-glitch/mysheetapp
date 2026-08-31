import 'package:sqflite/sqflite.dart';

import '../../domain/models/ledger_entry.dart';
import '../../domain/models/sync_status.dart';
import 'app_database.dart';

class TransactionsDao {
  TransactionsDao(this._db);

  final AppDatabase _db;

  Future<int> insert(LedgerEntry entry) async {
    final db = await _db.database;
    final map = entry.toDbMap()..remove('id');
    return db.insert(
      AppDatabase.tableTransactions,
      map,
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<void> update(LedgerEntry entry) async {
    final db = await _db.database;
    await db.update(
      AppDatabase.tableTransactions,
      entry.toDbMap()..remove('id'),
      where: 'transaction_id = ?',
      whereArgs: [entry.transactionId],
    );
  }

  /// Excludes entries marked pending_delete - they're hidden from the UI as
  /// soon as the user deletes them, even before remote cleanup completes.
  Future<List<LedgerEntry>> getAll() async {
    final db = await _db.database;
    final rows = await db.query(
      AppDatabase.tableTransactions,
      where: 'pending_delete = 0',
      orderBy: 'serial DESC',
    );
    return rows.map(LedgerEntry.fromDbMap).toList();
  }

  Future<List<LedgerEntry>> getPendingOrFailed() async {
    final db = await _db.database;
    final rows = await db.query(
      AppDatabase.tableTransactions,
      where: 'sync_status IN (?, ?) AND pending_delete = 0',
      whereArgs: [SyncStatus.pending.name, SyncStatus.failed.name],
      orderBy: 'serial ASC',
    );
    return rows.map(LedgerEntry.fromDbMap).toList();
  }

  Future<List<LedgerEntry>> getPendingDeletions() async {
    final db = await _db.database;
    final rows = await db.query(
      AppDatabase.tableTransactions,
      where: 'pending_delete = 1',
    );
    return rows.map(LedgerEntry.fromDbMap).toList();
  }

  Future<void> markPendingDeletion(String transactionId) async {
    final db = await _db.database;
    await db.update(
      AppDatabase.tableTransactions,
      {'pending_delete': 1},
      where: 'transaction_id = ?',
      whereArgs: [transactionId],
    );
  }

  Future<void> hardDelete(String transactionId) async {
    final db = await _db.database;
    await db.delete(
      AppDatabase.tableTransactions,
      where: 'transaction_id = ?',
      whereArgs: [transactionId],
    );
  }

  Future<bool> serialExists(int serial) async {
    final db = await _db.database;
    final rows = await db.query(
      AppDatabase.tableTransactions,
      where: 'serial = ?',
      whereArgs: [serial],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  Future<LedgerEntry?> getByTransactionId(String transactionId) async {
    final db = await _db.database;
    final rows = await db.query(
      AppDatabase.tableTransactions,
      where: 'transaction_id = ?',
      whereArgs: [transactionId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return LedgerEntry.fromDbMap(rows.first);
  }

  /// Highest serial number known locally (synced, pending or failed) - used
  /// together with the remote sheet's highest serial to compute the next
  /// unique number and avoid collisions.
  Future<int?> getMaxSerial() async {
    final db = await _db.database;
    final result = await db.rawQuery(
      'SELECT MAX(serial) as maxSerial FROM ${AppDatabase.tableTransactions}',
    );
    return result.first['maxSerial'] as int?;
  }
}
