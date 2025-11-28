import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class ChatFileDatabase {
  factory ChatFileDatabase() => _instance;
  ChatFileDatabase._internal();
  static final ChatFileDatabase _instance = ChatFileDatabase._internal();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'chat_files.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE files (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            fileName TEXT,
            filePath TEXT,
            groupId TEXT,
            conversationId TEXT,
            createdAt TEXT
          )
        ''');
      },
    );
  }

  Future<int> insertFile(Map<String, dynamic> data) async {
    final db = await database;
    return db.insert('files', data);
  }

  Future<List<Map<String, dynamic>>> searchFiles({
    String? groupId,
    String? conversationId,
  }) async {
    final db = await database;
    final conditions = <String>[];
    final whereArgs = <String>[];

    if (groupId != null) {
      conditions.add('groupId = ?');
      whereArgs.add(groupId);
    }
    if (conversationId != null) {
      conditions.add('conversationId = ?');
      whereArgs.add(conversationId);
    }

    final where = conditions.isNotEmpty ? conditions.join(' AND ') : null;

    return db.query(
      'files',
      where: where,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
    );
  }

  Future<void> clearAll() async {
    final db = await database;
    await db.delete('files');
  }

  /// 🆕 Update conversationId after temp -> real
  Future<int> updateConversationId(
    String oldConversationId,
    String newConversationId,
  ) async {
    final db = await database;
    return db.update(
      'files',
      {'conversationId': newConversationId},
      where: 'conversationId = ?',
      whereArgs: [oldConversationId],
    );
  }

  /// Get all stored files
  Future<List<Map<String, dynamic>>> getAllFiles() async {
    final db = await database;
    return db.query('files');
  }
}
