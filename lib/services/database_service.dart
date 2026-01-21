import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:soul_note/models/note.dart';
import 'package:soul_note/models/message.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('soulnote.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // 创建笔记表
    await db.execute('''
      CREATE TABLE notes (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        createdAt INTEGER NOT NULL,
        updatedAt INTEGER NOT NULL,
        messageCount INTEGER DEFAULT 0,
        lastMessagePreview TEXT,
        lastMessageType TEXT,
        noteType TEXT DEFAULT 'chat',
        markdownContent TEXT
      )
    ''');

    // 创建消息表
    await db.execute('''
      CREATE TABLE messages (
        id TEXT PRIMARY KEY,
        noteId TEXT NOT NULL,
        content TEXT NOT NULL,
        type TEXT NOT NULL,
        createdAt INTEGER NOT NULL,
        isSynced INTEGER DEFAULT 0,
        mediaPath TEXT,
        FOREIGN KEY (noteId) REFERENCES notes (id) ON DELETE CASCADE
      )
    ''');

    // 创建索引
    await db.execute('''
      CREATE INDEX idx_messages_noteId ON messages(noteId)
    ''');
    await db.execute('''
      CREATE INDEX idx_messages_createdAt ON messages(createdAt)
    ''');
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // 添加 noteType 和 markdownContent 字段
      await db.execute('ALTER TABLE notes ADD COLUMN noteType TEXT DEFAULT "chat"');
      await db.execute('ALTER TABLE notes ADD COLUMN markdownContent TEXT');
    }
  }

  // ============ Notes CRUD ============

  Future<Note> createNote(Note note) async {
    final db = await database;
    await db.insert('notes', note.toMap());
    return note;
  }

  Future<List<Note>> getAllNotes() async {
    final db = await database;
    final result = await db.query(
      'notes',
      orderBy: 'updatedAt DESC',
    );
    return result.map((map) => Note.fromMap(map)).toList();
  }

  Future<Note?> getNote(String id) async {
    final db = await database;
    final result = await db.query(
      'notes',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isEmpty) return null;
    return Note.fromMap(result.first);
  }

  Future<int> updateNote(Note note) async {
    final db = await database;
    return await db.update(
      'notes',
      note.toMap(),
      where: 'id = ?',
      whereArgs: [note.id],
    );
  }

  Future<int> deleteNote(String id) async {
    final db = await database;
    // 先删除相关消息
    await db.delete('messages', where: 'noteId = ?', whereArgs: [id]);
    // 再删除笔记
    return await db.delete('notes', where: 'id = ?', whereArgs: [id]);
  }

  // ============ Messages CRUD ============

  Future<Message> createMessage(Message message) async {
    final db = await database;
    await db.insert('messages', message.toMap());
    
    // 更新笔记的最后消息和时间
    final note = await getNote(message.noteId);
    if (note != null) {
      await updateNote(note.copyWith(
        updatedAt: message.createdAt,
        messageCount: note.messageCount + 1,
        lastMessagePreview: message.type == MessageType.text 
            ? message.content 
            : message.type == MessageType.image 
                ? '[图片]' 
                : '[视频]',
        lastMessageType: message.type.toString().split('.').last,
      ));
    }
    
    return message;
  }

  Future<List<Message>> getMessagesForNote(String noteId) async {
    final db = await database;
    final result = await db.query(
      'messages',
      where: 'noteId = ?',
      whereArgs: [noteId],
      orderBy: 'createdAt ASC',
    );
    return result.map((map) => Message.fromMap(map)).toList();
  }

  Future<int> updateMessage(Message message) async {
    final db = await database;
    return await db.update(
      'messages',
      message.toMap(),
      where: 'id = ?',
      whereArgs: [message.id],
    );
  }

  Future<int> deleteMessage(String id) async {
    final db = await database;
    return await db.delete('messages', where: 'id = ?', whereArgs: [id]);
  }

  // ============ Search ============

  Future<List<Message>> searchMessages(String query) async {
    final db = await database;
    final result = await db.query(
      'messages',
      where: 'content LIKE ?',
      whereArgs: ['%$query%'],
      orderBy: 'createdAt DESC',
    );
    return result.map((map) => Message.fromMap(map)).toList();
  }

  // ============ 删除所有数据 ============

  Future<void> deleteAllData() async {
    final db = await database;
    await db.delete('messages');
    await db.delete('notes');
  }

  // ============ 关闭数据库 ============

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
