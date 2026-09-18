import 'package:sqflite/sqflite.dart';

import '../../domain/entities/audit.dart';
import '../../domain/entities/audit_item.dart';
import '../../domain/entities/evidence.dart';
import '../../domain/repositories/audit_repository.dart';
import '../datasources/local_database.dart';

class AuditRepositoryImpl implements AuditRepository {
  final LocalDatabase _localDb;
  AuditRepositoryImpl({LocalDatabase? localDb}) : _localDb = localDb ?? LocalDatabase.instance;

  @override
  Future<void> saveAudit(Audit audit) async {
    final db = await _localDb.database;
    await db.transaction((txn) async {
      await txn.insert('audits', audit.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);

      await txn.delete('audit_items', where: 'auditId = ?', whereArgs: [audit.id]);
      for (final item in audit.items) {
        await txn.insert('audit_items', item.toMap(audit.id));
      }

      await txn.delete('evidences', where: 'auditId = ?', whereArgs: [audit.id]);
      for (final ev in audit.evidences) {
        await txn.insert('evidences', ev.toMap(audit.id));
      }
    });
  }

  @override
  Future<List<Audit>> getAudits({AuditFilter filter = const AuditFilter()}) async {
    final db = await _localDb.database;
    final where = <String>[];
    final args = <Object?>[];

    if (filter.mes != null) {
      where.add('mesReferencia = ?');
      args.add(filter.mes);
    }
    if (filter.area != null && filter.area!.isNotEmpty) {
      where.add('area LIKE ?');
      args.add('%${filter.area}%');
    }
    if (filter.auditor != null && filter.auditor!.isNotEmpty) {
      where.add('auditor LIKE ?');
      args.add('%${filter.auditor}%');
    }
    if (filter.ano != null) {
      where.add("strftime('%Y', data) = ?");
      args.add(filter.ano.toString());
    }

    final rows = await db.query(
      'audits',
      where: where.isEmpty ? null : where.join(' AND '),
      whereArgs: where.isEmpty ? null : args,
      orderBy: 'data DESC',
    );

    final result = <Audit>[];
    for (final row in rows) {
      result.add(await _hydrate(db, row));
    }
    return result;
  }

  @override
  Future<Audit?> getAuditById(String id) async {
    final db = await _localDb.database;
    final rows = await db.query('audits', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return _hydrate(db, rows.first);
  }

  @override
  Future<void> deleteAudit(String id) async {
    final db = await _localDb.database;
    await db.transaction((txn) async {
      await txn.delete('evidences', where: 'auditId = ?', whereArgs: [id]);
      await txn.delete('audit_items', where: 'auditId = ?', whereArgs: [id]);
      await txn.delete('audits', where: 'id = ?', whereArgs: [id]);
    });
  }

  @override
  Future<Audit?> getPreviousAudit({
    required String area,
    required DateTime beforeDate,
    String? excludeId,
  }) async {
    final trimmedArea = area.trim();
    if (trimmedArea.isEmpty) return null;

    final db = await _localDb.database;
    final where = <String>['LOWER(TRIM(area)) = ?', 'data < ?'];
    final args = <Object?>[trimmedArea.toLowerCase(), beforeDate.toIso8601String()];
    if (excludeId != null) {
      where.add('id != ?');
      args.add(excludeId);
    }

    final rows = await db.query(
      'audits',
      where: where.join(' AND '),
      whereArgs: args,
      orderBy: 'data DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _hydrate(db, rows.first);
  }

  Future<Audit> _hydrate(Database db, Map<String, Object?> row) async {
    final itemRows = await db.query('audit_items', where: 'auditId = ?', whereArgs: [row['id']]);
    final evRows = await db.query('evidences', where: 'auditId = ?', whereArgs: [row['id']]);
    final items = itemRows.map((r) => AuditItem.fromMap(r)).toList();
    final evidences = evRows.map((r) => Evidence.fromMap(r)).toList();
    return Audit.fromMap(row, items: items, evidences: evidences);
  }
}
