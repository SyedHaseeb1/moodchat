import 'dart:convert';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../../domain/models/user_model.dart';
import '../../core/logger.dart';

class UserLocalDataSource {
  static const String _tableName = 'current_user';
  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDb();
    return _database!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'mood_user.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_tableName (
            id TEXT PRIMARY KEY,
            data TEXT NOT NULL
          )
        ''');
      },
    );
  }

  Future<void> saveUser(UserModel user) async {
    try {
      final db = await database;
      await db.insert(
        _tableName,
        {
          'id': user.id,
          'data': jsonEncode(user.toJson()),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      AppLogger.i('UserLocalDataSource: Saved user ${user.id} to local DB');
    } catch (e, stack) {
      AppLogger.e('UserLocalDataSource: Error saving user', e, stack);
    }
  }

  Future<UserModel?> getUser() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(_tableName, limit: 1);

      if (maps.isNotEmpty) {
        final data = jsonDecode(maps.first['data'] as String);
        return UserModel.fromJson(data);
      }
    } catch (e, stack) {
      AppLogger.e('UserLocalDataSource: Error getting user', e, stack);
    }
    return null;
  }

  Future<void> clearUser() async {
    try {
      final db = await database;
      await db.delete(_tableName);
      AppLogger.i('UserLocalDataSource: Cleared local user data');
    } catch (e) {
      AppLogger.e('UserLocalDataSource: Error clearing user', e);
    }
  }
}
