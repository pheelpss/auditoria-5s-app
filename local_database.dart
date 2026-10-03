import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Camada de acesso ao banco SQLite local. Responsável apenas por abrir
/// a conexão e criar o esquema — a lógica de domínio fica no repositório.
class LocalDatabase {
  static final LocalDatabase instance = LocalDatabase._internal();
  LocalDatabase._internal();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'auditoria_5s.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE audits (
            id TEXT PRIMARY KEY,
            responsavel TEXT NOT NULL,
            area TEXT NOT NULL,
            auditor TEXT NOT NULL,
            acompanhante TEXT NOT NULL,
            data TEXT NOT NULL,
            mesReferencia TEXT NOT NULL,
            comentarios TEXT,
            createdAt TEXT NOT NULL
          );
        ''');
        await db.execute('''
          CREATE TABLE audit_items (
            auditId TEXT NOT NULL,
            categoryCode TEXT NOT NULL,
            number TEXT NOT NULL,
            question TEXT NOT NULL,
            score INTEGER,
            PRIMARY KEY (auditId, number),
            FOREIGN KEY (auditId) REFERENCES audits (id) ON DELETE CASCADE
          );
        ''');
        await db.execute('''
          CREATE TABLE evidences (
            id TEXT PRIMARY KEY,
            auditId TEXT NOT NULL,
            categoryCode TEXT NOT NULL,
            filePath TEXT NOT NULL,
            fileName TEXT NOT NULL,
            type TEXT NOT NULL,
            FOREIGN KEY (auditId) REFERENCES audits (id) ON DELETE CASCADE
          );
        ''');
      },
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }
}
