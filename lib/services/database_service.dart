import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import '../models/duo_message.dart';

/// SQLite 数据库服务
/// 
/// 持久化消息、剪贴板、文件传输记录
class DatabaseService {
  static Database? _db;
  static const _dbName = 'duoshare.db';
  static const _version = 1;

  /// 获取数据库实例（懒加载单例）
  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  static Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, _dbName);

    if (kDebugMode) print('[DatabaseService] DB path: $path');

    return openDatabase(
      path,
      version: _version,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE messages (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            type TEXT NOT NULL,
            sender_name TEXT NOT NULL,
            payload TEXT NOT NULL,
            metadata TEXT,
            timestamp TEXT NOT NULL,
            is_mine INTEGER DEFAULT 0
          )
        ''');

        await db.execute('''
          CREATE TABLE file_records (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            file_name TEXT NOT NULL,
            file_size INTEGER NOT NULL,
            sender_name TEXT NOT NULL,
            timestamp TEXT NOT NULL,
            local_path TEXT,
            is_mine INTEGER DEFAULT 0
          )
        ''');

        if (kDebugMode) print('[DatabaseService] Tables created');
      },
    );
  }

  // ==================== 消息操作 ====================

  /// 插入一条消息记录
  static Future<void> insertMessage(DuoMessage message, {bool isMine = false}) async {
    final db = await database;
    await db.insert('messages', {
      'type': message.type.name,
      'sender_name': message.senderName,
      'payload': message.payload,
      'metadata': message.metadata?.toString(),
      'timestamp': message.timestamp.toIso8601String(),
      'is_mine': isMine ? 1 : 0,
    });
  }

  /// 获取指定类型的消息历史
  static Future<List<DuoMessage>> getMessages({
    List<MessageType>? types,
    int limit = 200,
  }) async {
    final db = await database;
    String? where;
    List<dynamic>? whereArgs;

    if (types != null && types.isNotEmpty) {
      final placeholders = types.map((_) => '?').join(',');
      where = 'type IN ($placeholders)';
      whereArgs = types.map((t) => t.name).toList();
    }

    final rows = await db.query(
      'messages',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'timestamp DESC',
      limit: limit,
    );

    return rows.map((row) => DuoMessage(
      type: MessageType.values.firstWhere(
        (e) => e.name == row['type'],
        orElse: () => MessageType.text,
      ),
      senderName: row['sender_name'] as String,
      payload: row['payload'] as String,
      timestamp: DateTime.tryParse(row['timestamp'] as String) ?? DateTime.now(),
    )).toList().reversed.toList(); // 反转为时间正序
  }

  // ==================== 文件记录操作 ====================

  /// 插入文件传输记录
  static Future<void> insertFileRecord(FileRecord record, {bool isMine = false}) async {
    final db = await database;
    await db.insert('file_records', {
      'file_name': record.fileName,
      'file_size': record.fileSize,
      'sender_name': record.senderName,
      'timestamp': record.timestamp.toIso8601String(),
      'local_path': record.localPath,
      'is_mine': isMine ? 1 : 0,
    });
  }

  /// 获取文件传输记录
  static Future<List<FileRecord>> getFileRecords({int limit = 100}) async {
    final db = await database;
    final rows = await db.query(
      'file_records',
      orderBy: 'timestamp DESC',
      limit: limit,
    );

    return rows.map((row) => FileRecord(
      fileName: row['file_name'] as String,
      fileSize: row['file_size'] as int,
      senderName: row['sender_name'] as String,
      timestamp: DateTime.tryParse(row['timestamp'] as String) ?? DateTime.now(),
      localPath: row['local_path'] as String?,
    )).toList();
  }

  // ==================== 清理操作 ====================

  /// 清除所有消息记录
  static Future<void> clearMessages() async {
    final db = await database;
    await db.delete('messages');
    if (kDebugMode) print('[DatabaseService] Messages cleared');
  }

  /// 清除所有文件记录
  static Future<void> clearFileRecords() async {
    final db = await database;
    await db.delete('file_records');
    if (kDebugMode) print('[DatabaseService] File records cleared');
  }

  /// 清除全部数据
  static Future<void> clearAll() async {
    await clearMessages();
    await clearFileRecords();
  }

  /// 获取消息总数
  static Future<int> getMessageCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM messages');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// 关闭数据库
  static Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
