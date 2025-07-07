import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/first_aid_guideline_model.dart';
import '../models/post_model.dart';
import '../models/user_model.dart';
import '../models/zone_model.dart';
import '../models/rescue_model.dart';

class DatabaseHelper {
  // --- SINGLETON SETUP ---
  // This ensures we have only one instance of the database helper.
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  // This is the actual database instance. It's static so it's not re-initialized.
  static Database? _database;

  // Getter for the database. If it's null, it initializes it.
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // --- DATABASE INITIALIZATION ---
  static const _databaseName = "AppDatabase.db";
  static const _databaseVersion = 1;

  // Opens the database and creates it if it doesn't exist.
  _initDatabase() async {
    String path = join(await getDatabasesPath(), _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      // Optional: Enable foreign key support
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  // --- TABLE CREATION ---
  // SQL code to create the database tables. This is executed only once.
  Future _onCreate(Database db, int version) async {
    // User Table
    await db.execute('''
      CREATE TABLE users (
        uid TEXT PRIMARY KEY NOT NULL,
        uname TEXT NOT NULL,
        passwordHash TEXT NOT NULL, 
        imageUrl TEXT,
        isAdmin INTEGER NOT NULL,
        occupation TEXT,
        isVerified INTEGER NOT NULL
      )
    ''');

    // Post Table
    await db.execute('''
      CREATE TABLE posts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        uid TEXT NOT NULL,
        uname TEXT NOT NULL,
        time TEXT NOT NULL,
        zoneType TEXT NOT NULL,
        description TEXT NOT NULL,
        imageUrl TEXT,
        communityNotes TEXT,
        postStatus TEXT NOT NULL,
        verificationScore REAL NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        FOREIGN KEY (uid) REFERENCES users (uid) ON DELETE CASCADE
      )
    ''');

    // Zone Table
    await db.execute('''
      CREATE TABLE zones (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        description TEXT NOT NULL,
        userId TEXT NOT NULL,
        postId INTEGER NOT NULL,
        FOREIGN KEY (userId) REFERENCES users (uid) ON DELETE CASCADE,
        FOREIGN KEY (postId) REFERENCES posts (id) ON DELETE CASCADE
      )
    ''');

    // First Aid Guideline Table
    await db.execute('''
      CREATE TABLE guidelines (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        problemName TEXT NOT NULL UNIQUE,
        problemDescription TEXT NOT NULL
      )
    ''');

    // User Post votes
    await db.execute('''
    CREATE TABLE user_post_votes (
      userId TEXT NOT NULL,
      postId INTEGER NOT NULL,
      voteType INTEGER NOT NULL, -- 1 for like, -1 for dislike
      PRIMARY KEY (userId, postId),
      FOREIGN KEY (userId) REFERENCES users (uid) ON DELETE CASCADE,
      FOREIGN KEY (postId) REFERENCES posts (id) ON DELETE CASCADE
    )
  ''');

    // Rescue Table
    await db.execute('''
    CREATE TABLE rescues (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      message TEXT NOT NULL,
      locationText TEXT NOT NULL,
      latitude REAL NOT NULL,
      longitude REAL NOT NULL,
      imageUrl TEXT,
      timestamp TEXT NOT NULL
    )
  ''');
  }

  // --- CRUD METHODS FOR POSTS ---

  Future<Post> insertPost(Post post) async {
    final db = await instance.database;
    // sqflite's insert method returns the id of the new row.
    final id = await db.insert('posts', post.toMap());
    // Return a new Post object with the id from the database.
    return Post.fromMap({...post.toMap(), 'id': id});
  }

  Future<List<Post>> getAllPosts() async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query('posts', orderBy: 'time DESC');
    return List.generate(maps.length, (i) {
      return Post.fromMap(maps[i]);
    });
  }

  Future<int> updatePost(Post post) async {
    final db = await instance.database;
    return await db.update(
      'posts',
      post.toMap(),
      where: 'id = ?',
      whereArgs: [post.id],
    );
  }

  Future<int> deletePost(int id) async {
    final db = await instance.database;
    return await db.delete(
      'posts',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- CRUD METHODS FOR USERS ---

  Future<int> insertUser(User user) async {
    final db = await instance.database;
    return await db.insert('users', user.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<User?> getUser(String uid) async {
    final db = await instance.database;
    final maps = await db.query(
      'users',
      where: 'uid = ?',
      whereArgs: [uid],
    );
    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateUser(User user) async {
    final db = await instance.database;
    return await db.update(
      'users',
      user.toMap(),
      where: 'uid = ?',
      whereArgs: [user.uid],
    );
  }

  // --- CRUD METHODS FOR ZONES ---

  Future<int> insertZone(Zone zone) async {
    final db = await instance.database;
    return await db.insert('zones', zone.toMap());
  }

  Future<List<Zone>> getZonesForPost(int postId) async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'zones',
      where: 'postId = ?',
      whereArgs: [postId],
    );
    return List.generate(maps.length, (i) {
      return Zone.fromMap(maps[i]);
    });
  }

  // --- CRUD METHODS FOR FIRST AID GUIDELINES ---

  Future<int> insertGuideline(FirstAidGuideline guideline) async {
    final db = await instance.database;
    // Use replace to avoid errors if the unique problemName already exists
    return await db.insert('guidelines', guideline.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<FirstAidGuideline>> getAllGuidelines() async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query('guidelines', orderBy: 'problemName ASC');
    return List.generate(maps.length, (i) {
      return FirstAidGuideline.fromMap(maps[i]);
    });
  }


  Future<User?> getUserByUsername(String uname) async {
    final db = await instance.database;
    final maps = await db.query(
      'users',
      where: 'uname = ?',
      whereArgs: [uname],
      limit: 1, // We expect only one user with a given username
    );
    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }







  // --- CRUD METHODS FOR VOTES ---

  // Adds or updates a user's vote for a post.
  Future<void> addOrUpdateVote(String userId, int postId, int voteType) async {
    final db = await instance.database;
    await db.insert(
      'user_post_votes',
      {'userId': userId, 'postId': postId, 'voteType': voteType},
      // This will replace the existing vote if the user changes their mind
      // (e.g., from a like to a dislike).
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Removes a user's vote for a post (when they "un-like" or "un-dislike").
  Future<void> removeVote(String userId, int postId) async {
    final db = await instance.database;
    await db.delete(
      'user_post_votes',
      where: 'userId = ? AND postId = ?',
      whereArgs: [userId, postId],
    );
  }

  // Gets all the votes for a specific user to display their state correctly.
  Future<Map<int, int>> getVotesForUser(String userId) async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'user_post_votes',
      where: 'userId = ?',
      whereArgs: [userId],
    );
    // Convert the list of maps into a single map of {postId: voteType}
    return {for (var map in maps) map['postId']: map['voteType']};
  }



  // --- CRUD METHODS FOR RESCUES ---

  Future<int> insertRescue(Rescue rescue) async {
    final db = await instance.database;
    return await db.insert('rescues', rescue.toMap());
  }

  Future<List<Rescue>> getAllRescues() async {
    final db = await instance.database;
    final maps = await db.query('rescues', orderBy: 'timestamp DESC');
    return List.generate(maps.length, (i) => Rescue.fromMap(maps[i]));
  }


}




