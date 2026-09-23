import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBHelper {
  DBHelper._privateConstructor();

  static final DBHelper instance = DBHelper._privateConstructor();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  // ========================
  // INIT DATABASE
  // ========================
  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();

    final path = join(dbPath, 'storagio.db');

    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  // ========================
  // CREATE TABLES
  // ========================
  Future<void> _onCreate(Database db, int version) async {
    // ========================
    // ACTIVITIES TABLE
    // ========================

    // activity system supports:
    // Item quantity changed from 5 → 2
    // Room renamed
    // Category renamed
    // Item moved Kitchen → Store Room
    // Low stock detected

    // ========================
    // ACTIVITIES TABLE 
    // ========================
    await db.execute('''
      CREATE TABLE activities (
        localId INTEGER PRIMARY KEY AUTOINCREMENT,

        id TEXT UNIQUE NOT NULL,

        entityId TEXT NOT NULL,
        entityName TEXT NOT NULL,

        entityType TEXT NOT NULL,
        actionType TEXT NOT NULL,   

        -- Store as INTEGER for better sorting + performance
        createdAt INTEGER NOT NULL,

        -- Generic field change tracking
        fieldName TEXT,
        oldValue TEXT,
        newValue TEXT,

        -- Sync status
        synced INTEGER
      )
    ''');

    // INDEXES
    // Fast lookup for specific entity history
    await db.execute(
      'CREATE INDEX idx_activities_entityId '
      'ON activities(entityId)',
    );

    // Filter by item/category/room
    await db.execute(
      'CREATE INDEX idx_activities_entityType '
      'ON activities(entityType)',
    );

    // Timeline sorting
    await db.execute(
      'CREATE INDEX idx_activities_createdAt '
      'ON activities(createdAt DESC)',
    );

    // Sync operations
    await db.execute(
      'CREATE INDEX idx_activities_synced '
      'ON activities(synced)',
    );

    // Optional: filter by action type
    await db.execute(
      'CREATE INDEX idx_activities_actionType '
      'ON activities(actionType)',
    );

    await db.execute(
      'CREATE INDEX idx_activities_entity_created '
      'ON activities(entityId, createdAt DESC)',
    );

    // ========================
    // CATEGORIES TABLE 
    // ========================
    await db.execute('''
    CREATE TABLE categories (
      localId INTEGER PRIMARY KEY AUTOINCREMENT,
      id TEXT UNIQUE NOT NULL,
      categoryName TEXT UNIQUE NOT NULL,
      icon TEXT NOT NULL,
      color INTEGER NOT NULL,
      synced INTEGER
    )
  ''');

    // Index for fast lookup
    await db.execute('CREATE INDEX idx_categories_id ON categories(id)');

    // ========================
    // ROOMS TABLE 
    // ========================
    await db.execute('''
    CREATE TABLE rooms (
      localId INTEGER PRIMARY KEY AUTOINCREMENT,
      id TEXT UNIQUE NOT NULL,
      roomName TEXT UNIQUE NOT NULL,
      icon TEXT NOT NULL,
      color INTEGER NOT NULL,
      synced INTEGER
    )
  ''');

    await db.execute('CREATE INDEX idx_rooms_id ON rooms(id)');

    // ========================
    // ITEMS TABLE  
    // ========================
    await db.execute('''
    CREATE TABLE items (
      localId INTEGER PRIMARY KEY AUTOINCREMENT,
      id TEXT UNIQUE NOT NULL,

      name TEXT UNIQUE NOT NULL,
      categoryName TEXT NOT NULL,
      synced INTEGER,

      unit TEXT,

      quantity REAL,
      lowStockLimit REAL,
      roomId TEXT,
      lastPaymentAmount INTEGER,
      
      purchaseDate TEXT,
      warrantyExpiry TEXT,

      notes TEXT,
      imagePath TEXT
    )
  ''');

    // Indexes for performance
    await db.execute('CREATE INDEX idx_items_id ON items(id)');

    // ========================
    // USERS TABLE    
    // ========================
    await db.execute('''
    CREATE TABLE users (
      localId INTEGER PRIMARY KEY AUTOINCREMENT,
      id TEXT UNIQUE NOT NULL,
      fullName TEXT NOT NULL,
      email TEXT UNIQUE NOT NULL,
      password TEXT NOT NULL,
      loginMethod TEXT NOT NULL,
      profileImage TEXT NOT NULL,
      lowStockLimit INTEGER NOT NULL,
      synced INTEGER
    )
  ''');

    await db.execute('CREATE INDEX idx_users_email ON users(email)');

    // ========================
    // DELETED RECORDS TABLE
    // ========================
    await db.execute('''
    CREATE TABLE deleted_records (
      localId INTEGER PRIMARY KEY AUTOINCREMENT,

      recordId TEXT NOT NULL,
      collectionName TEXT NOT NULL,

      deletedAt INTEGER NOT NULL
    )
  ''');

    // ========================
    // CUSTOM REMINDER TABLE
    // ========================
    await db.execute('''
    CREATE TABLE custom_reminders (
      localId INTEGER PRIMARY KEY AUTOINCREMENT,
      id TEXT UNIQUE NOT NULL,
      
      itemId TEXT NOT NULL, 
      content TEXT,
      startDate TEXT NOT NULL,
      intervalDays INTEGER NOT NULL,
      
      isActive INTEGER DEFAULT 1,
      synced INTEGER,

      FOREIGN KEY (itemId) REFERENCES items (id) ON DELETE CASCADE
    )
  ''');
  }
}
