import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;

  /// Initialisation de la base SQLite
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final path = join(await getDatabasesPath(), 'portefeuille.db');

    return await openDatabase(
      path,
      version: 4,
      onCreate: (db, version) async {
        await _createTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        await _upgradeDatabase(db, oldVersion, newVersion);
      },
      onOpen: (db) async {
        await _createTables(db);
      },
    );
  }

  Future<void> _upgradeDatabase(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    // Créer les nouvelles tables pour l'épargne si elles n'existent pas
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS devices(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          nom TEXT NOT NULL
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS motif_epargne(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          nom TEXT NOT NULL,
          motif TEXT NOT NULL
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS epargne(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          device_id INTEGER NOT NULL,
          montant REAL NOT NULL,
          motif_epargne_id INTEGER NOT NULL,
          libelle TEXT NOT NULL,
          created_at INTEGER NOT NULL,
          FOREIGN KEY (device_id) REFERENCES devices (id),
          FOREIGN KEY (motif_epargne_id) REFERENCES motif_epargne (id)
        )
      ''');

      // Insérer des données par défaut
      await _insertDefaultData(db);
    }
  }

  Future<void> _createTables(Database db) async {
    // Créer les tables existantes
    await db.execute('''
      CREATE TABLE IF NOT EXISTS users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        email TEXT UNIQUE,
        password TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS categories(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        type TEXT NOT NULL CHECK(type IN ('income', 'expense')),
        created_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS transactions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        amount REAL NOT NULL,
        category TEXT NOT NULL,
        note TEXT NOT NULL,
        device_id INTEGER,
        created_at INTEGER NOT NULL,
        FOREIGN KEY (device_id) REFERENCES devices (id)
      )
    ''');

    // Créer les nouvelles tables pour l'épargne
    await db.execute('''
      CREATE TABLE IF NOT EXISTS devices(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nom TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS motif_epargne(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nom TEXT NOT NULL,
        motif TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS epargne(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        device_id INTEGER NOT NULL,
        montant REAL NOT NULL,
        motif_epargne_id INTEGER NOT NULL,
        libelle TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        FOREIGN KEY (device_id) REFERENCES devices (id),
        FOREIGN KEY (motif_epargne_id) REFERENCES motif_epargne (id)
      )
    ''');

    // Insérer des données par défaut si les tables sont vides
    await _insertDefaultData(db);
  }

  Future<void> _insertDefaultData(Database db) async {
    // Vérifier si les devices existent déjà
    final devicesCount = await db.rawQuery(
      'SELECT COUNT(*) as count FROM devices',
    );
    if ((devicesCount.first['count'] as int) == 0) {
      await db.insert('devices', {'nom': '\$'});
      await db.insert('devices', {'nom': 'FC'});
    }

    //Verifier si les categories existent deja
    final categoriesCount = await db.rawQuery(
      'SELECT COUNT(*) as count FROM categories',
    );
    if ((categoriesCount.first['count'] as int) == 0) {
      await db.insert('categories', {
        'name': 'salaire',
        'type': 'income',
        'created_at': DateTime.now().millisecondsSinceEpoch,
      });
      await db.insert('categories', {
        'name': 'transport',
        'type': 'expense',
        'created_at': DateTime.now().millisecondsSinceEpoch,
      });
    }

    // Vérifier si les motifs existent déjà
    final motifsCount = await db.rawQuery(
      'SELECT COUNT(*) as count FROM motif_epargne',
    );
    if ((motifsCount.first['count'] as int) == 0) {
      await db.insert('motif_epargne', {
        'nom': 'Urgence',
        'motif': 'Fonds d\'urgence pour imprévus',
      });
      await db.insert('motif_epargne', {
        'nom': 'Vacances',
        'motif': 'Épargne pour les vacances',
      });
      await db.insert('motif_epargne', {
        'nom': 'Projet',
        'motif': 'Épargne pour un projet spécifique',
      });
      await db.insert('motif_epargne', {
        'nom': 'Investissement',
        'motif': 'Épargne pour investissement',
      });
      await db.insert('motif_epargne', {
        'nom': 'Retraite',
        'motif': 'Épargne pour la retraite',
      });
    }
  }

  // ================= UTILISATEURS =================

  /// Insérer un nouvel utilisateur
  Future<int> insertUser(Map<String, dynamic> user) async {
    final db = await database;
    return await db.insert('users', user);
  }

  /// Vérifier login
  Future<Map<String, dynamic>?> getUser(
    String email,
    String passwordHash,
  ) async {
    final db = await database;
    final result = await db.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email, passwordHash],
    );
    if (result.isNotEmpty) {
      return result.first;
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> getAllUsers() async {
    final db = await database;
    return await db.query('users'); // SELECT * FROM users
  }

  // ================= CATÉGORIES =================

  Future<int> insertCategory(Map<String, dynamic> category) async {
    final db = await database;
    return await db.insert('categories', category);
  }

  Future<List<Map<String, dynamic>>> getCategoriesByType(String type) async {
    final db = await database;
    return await db.query(
      'categories',
      where: 'type = ?',
      whereArgs: [type],
      orderBy: 'name ASC',
    );
  }

  Future<int> deleteCategory(int id) async {
    final db = await database;
    return await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  Future<bool> categoryExists(String name, String type) async {
    final db = await database;
    final result = await db.query(
      'categories',
      where: 'name = ? AND type = ?',
      whereArgs: [name, type],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  Future<int> updateCategory(int id, Map<String, dynamic> category) async {
    final db = await database;
    return await db.update(
      'categories',
      category,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ================= TRANSACTIONS =================

  Future<int> insertTransaction(Map<String, dynamic> transaction) async {
    final db = await database;
    return await db.insert('transactions', transaction);
  }

  Future<List<Map<String, dynamic>>> getAllTransactions({int? deviceId}) async {
    final db = await database;
    if (deviceId != null) {
      return await db.query(
        'transactions',
        where: 'device_id = ?',
        whereArgs: [deviceId],
        orderBy: 'created_at DESC',
      );
    }
    return await db.query('transactions', orderBy: 'created_at DESC');
  }

  Future<int> deleteTransaction(int id) async {
    final db = await database;
    return await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  Future<Map<String, dynamic>> getTotals({int? deviceId}) async {
    final db = await database;
    String query = 'SELECT type, SUM(amount) AS total FROM transactions';
    List<dynamic> args = [];

    if (deviceId != null) {
      query += ' WHERE device_id = ?';
      args.add(deviceId);
    }

    query += ' GROUP BY type';

    final rows = await db.rawQuery(query, args);

    double income = 0;
    double expense = 0;

    for (final row in rows) {
      final type = row['type'] as String?;
      final totalNum = row['total'] as num?;
      final total = (totalNum ?? 0).toDouble();
      if (type == 'income') {
        income = total;
      } else if (type == 'expense') {
        expense = total;
      }
    }

    return {'income': income, 'expense': expense};
  }

  // ================= ÉPARGNE =================

  // CRUD pour devices
  Future<int> insertDevice(Map<String, dynamic> device) async {
    final db = await database;
    return await db.insert('devices', device);
  }

  Future<List<Map<String, dynamic>>> getAllDevices() async {
    final db = await database;
    return await db.query('devices', orderBy: 'nom ASC');
  }

  Future<int> deleteDevice(int id) async {
    final db = await database;
    return await db.delete('devices', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> updateDevice(int id, Map<String, dynamic> device) async {
    final db = await database;
    return await db.update('devices', device, where: 'id = ?', whereArgs: [id]);
  }

  // CRUD pour motif_epargne
  Future<int> insertMotifEpargne(Map<String, dynamic> motif) async {
    final db = await database;
    return await db.insert('motif_epargne', motif);
  }

  Future<List<Map<String, dynamic>>> getAllMotifsEpargne() async {
    final db = await database;
    return await db.query('motif_epargne', orderBy: 'nom ASC');
  }

  Future<int> deleteMotifEpargne(int id) async {
    final db = await database;
    return await db.delete('motif_epargne', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> updateMotifEpargne(int id, Map<String, dynamic> motif) async {
    final db = await database;
    return await db.update(
      'motif_epargne',
      motif,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // CRUD pour epargne
  Future<int> insertEpargne(Map<String, dynamic> epargne) async {
    final db = await database;
    return await db.insert('epargne', epargne);
  }

  Future<List<Map<String, dynamic>>> getAllEpargne({int? deviceId}) async {
    final db = await database;
    String query = '''
      SELECT 
        e.id,
        e.montant,
        e.libelle,
        e.created_at,
        d.nom as device_nom,
        m.nom as motif_nom,
        m.motif as motif_description
      FROM epargne e
      INNER JOIN devices d ON e.device_id = d.id
      INNER JOIN motif_epargne m ON e.motif_epargne_id = m.id
    ''';

    if (deviceId != null) {
      query += ' WHERE e.device_id = ?';
      return await db.rawQuery(query, [deviceId]);
    }

    query += ' ORDER BY e.created_at DESC';
    return await db.rawQuery(query);
  }

  //Total epargne avec device spécifique ou toutes
  Future<double> getTotalEpargne({int? deviceId}) async {
    final db = await database;
    String query = 'SELECT SUM(montant) as total FROM epargne';

    if (deviceId != null) {
      query += ' WHERE device_id = ?';
      final result = await db.rawQuery(query, [deviceId]);
      return (result.first['total'] as num?)?.toDouble() ?? 0.0;
    }

    // Si aucun device spécifié, retourner le total des dollars (device_id = 2)
    query += ' WHERE device_id = 2';
    final result = await db.rawQuery(query);
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  //Total epargne avec device spécifique ou toutes
  Future<double> getTotalEpargneFranc({int? deviceId}) async {
    final db = await database;
    String query = 'SELECT SUM(montant) as total FROM epargne';

    if (deviceId != null) {
      query += ' WHERE device_id = ?';
      final result = await db.rawQuery(query, [deviceId]);
      return (result.first['total'] as num?)?.toDouble() ?? 0.0;
    }

    // Si aucun device spécifié, retourner le total des francs (device_id = 1)
    query += ' WHERE device_id = 1';
    final result = await db.rawQuery(query);
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<int> deleteEpargne(int id) async {
    final db = await database;
    return await db.delete('epargne', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> updateEpargne(int id, Map<String, dynamic> epargne) async {
    final db = await database;
    return await db.update(
      'epargne',
      epargne,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ================= UTILITAIRES =================

  Future<void> printDatabaseContent() async {
    final db = await database;

    final users = await db.query('users');
    final categories = await db.query('categories');
    final transactions = await db.query('transactions');

    print('👥 Utilisateurs: ${users.length}');
    print('📂 Catégories: ${categories.length}');
    print('💰 Transactions: ${transactions.length}');
  }

  Future<void> resetDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }

    final path = join(await getDatabasesPath(), 'portefeuille.db');
    await deleteDatabase(path);
  }

  // Méthode pour forcer la mise à jour de la base de données
  Future<void> forceDatabaseUpdate() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }

    final path = join(await getDatabasesPath(), 'portefeuille.db');
    await deleteDatabase(path);

    // Recréer la base avec la nouvelle version
    await database;
  }

  // // Méthode pour mettre à jour les devices
  // Future<void> updateDevices() async {
  //   try {
  //     final db = await database;
  //     await db.update(
  //       'devices',
  //       {'nom': '\$'},
  //       where: 'id = ?',
  //       whereArgs: [1],
  //     );
  //     await db.update(
  //       'devices',
  //       {'nom': 'FC'},
  //       where: 'id = ?',
  //       whereArgs: [2],
  //     );
  //   } catch (e) {
  //     // Ignorer les erreurs si les devices n'existent pas
  //   }
  // }
}
