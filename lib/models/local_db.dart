import 'dart:async';
import 'package:sqflite/sqflite.dart';

class LocalDb {
  static const _FILENAME = 'history.db';
  static const _VERSION = 1;

  static Future<Database> connect() async {
    final basePath = await getDatabasesPath();
    final filename = '$basePath/$_FILENAME';
    return await openDatabase(
      filename,
      version: _VERSION,
      onCreate: _createTables,
      onUpgrade: _migrate,
    );
  }

  static const TABLES = {
    1: {
      'books': {
        'book_id': 'INTEGER PRIMARY KEY',
        'cover_json': 'TEXT',
        'is_favorate': 'INTEGER',
        'last_read_chapter_id': 'INTEGER',
        'max_read_chapter_id': 'INTEGER',
      },
      'chapters': {
        'chapter_id': 'INTEGER PRIMARY KEY',
        'title': 'TEXT',
        'book_id': 'INTEGER',
        'read_at': 'INTEGER',
        'read_page': 'INTEGER',
      },
    },
  };

  static void _createTables(Database db, int version) async {
    final tables = TABLES[version];
    for (var tableName in tables.keys) {
      final columns = tables[tableName].entries.map((p) => '${p.key} ${p.value}');
      await db.execute('CREATE TABLE $tableName (${columns.join(', ')})');
    }
  }

  static void _migrate(Database db, int oldVersion, int newVersion) {
  }
}