import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:logger/logger.dart';
import '../../models/user_profile.dart';
import '../../models/activity_result.dart';
import '../../models/child_profile.dart';

/// Servicio de base de datos SQLite para autenticación y gestión de usuarios
class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;
  final _logger = Logger();

  static const String _usersTable = 'users';
  static const String _activityResultsTable = 'activity_results';
  static const String _childrenTable = 'children';

  /// Inicializar la base de datos
  Future<Database> get database async {
    _database ??= await _initializeDatabase();
    return _database!;
  }

  /// Inicializar y crear tablas
  Future<Database> _initializeDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'dyslexia_app.db');

    _logger.i('Database path: $path');

    try {
      return await openDatabase(
        path,
        version: 3,
        onCreate: _createTables,
        onUpgrade: _onUpgrade,
      );
    } catch (e) {
      _logger.e('Error opening database: $e');
      _logger.i('Attempting to delete and recreate database...');

      try {
        // Borrar la BD corrupta
        await deleteDatabase(path);
        _logger.i('✅ Database deleted, recreating...');

        // Recrear
        return await openDatabase(
          path,
          version: 3,
          onCreate: _createTables,
          onUpgrade: _onUpgrade,
        );
      } catch (e2) {
        _logger.e('Failed to recreate database: $e2');
        rethrow;
      }
    }
  }

  /// Actualizar base de datos
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    _logger.i('Upgrading database from version $oldVersion to $newVersion');

    if (oldVersion < 2) {
      // Crear tabla de niños
      _logger.i('Creating children table...');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $_childrenTable (
          id TEXT PRIMARY KEY,
          tutorId TEXT NOT NULL,
          name TEXT NOT NULL,
          age INTEGER NOT NULL,
          dateOfBirth TEXT,
          notes TEXT,
          createdAt TEXT NOT NULL,
          updatedAt TEXT,
          FOREIGN KEY (tutorId) REFERENCES $_usersTable (id)
        )
      ''');

      // Agregar columna childId a activity_results
      _logger.i('Adding childId column to activity_results...');
      try {
        await db.execute('''
          ALTER TABLE $_activityResultsTable ADD COLUMN childId TEXT
        ''');
      } catch (e) {
        _logger.w('childId column may already exist: $e');
      }
    }

    if (oldVersion < 3) {
      _logger.i('Verifying all tables exist in version 3...');
      // Asegurar que todas las tablas existen
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS $_childrenTable (
            id TEXT PRIMARY KEY,
            tutorId TEXT NOT NULL,
            name TEXT NOT NULL,
            age INTEGER NOT NULL,
            dateOfBirth TEXT,
            notes TEXT,
            createdAt TEXT NOT NULL,
            updatedAt TEXT,
            FOREIGN KEY (tutorId) REFERENCES $_usersTable (id)
          )
        ''');
        _logger.i('✅ Children table ready');
      } catch (e) {
        _logger.e('Error creating children table: $e');
      }
    }
  }

  /// Crear tablas
  Future<void> _createTables(Database db, int version) async {
    _logger.i('Creating database tables...');

    // Tabla de usuarios
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_usersTable (
        id TEXT PRIMARY KEY,
        username TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        fullName TEXT NOT NULL,
        age INTEGER NOT NULL,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');

    // Tabla de perfiles de niños
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_childrenTable (
        id TEXT PRIMARY KEY,
        tutorId TEXT NOT NULL,
        name TEXT NOT NULL,
        age INTEGER NOT NULL,
        dateOfBirth TEXT,
        notes TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT,
        FOREIGN KEY (tutorId) REFERENCES $_usersTable (id)
      )
    ''');

    // Tabla de resultados de actividades
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_activityResultsTable (
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        childId TEXT,
        activityId TEXT NOT NULL,
        activityName TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        result TEXT NOT NULL,
        probability REAL NOT NULL,
        confidence REAL NOT NULL,
        details TEXT NOT NULL,
        durationSeconds INTEGER NOT NULL,
        FOREIGN KEY (userId) REFERENCES $_usersTable (id),
        FOREIGN KEY (childId) REFERENCES $_childrenTable (id)
      )
    ''');

    _logger.i('Database tables created successfully');
  }

  // ==================== USUARIOS ====================

  /// Registrar nuevo usuario
  Future<UserProfile?> registerUser({
    required String username,
    required String password,
    required String email,
    required String fullName,
    required int age,
  }) async {
    try {
      final db = await database;

      // Verificar si usuario ya existe
      final existing = await db.query(
        _usersTable,
        where: 'username = ? OR email = ?',
        whereArgs: [username, email],
      );

      if (existing.isNotEmpty) {
        _logger.w('Usuario o email ya existe');
        return null;
      }

      final now = DateTime.now().toIso8601String();
      final id = 'user_${DateTime.now().millisecondsSinceEpoch}';

      await db.insert(_usersTable, {
        'id': id,
        'username': username,
        'password': password, // En producción usar bcrypt
        'email': email,
        'fullName': fullName,
        'age': age,
        'createdAt': now,
        'updatedAt': now,
      });

      _logger.i('Usuario registrado: $username');

      return UserProfile(
        id: id,
        name: fullName,
        age: age,
        createdAt: DateTime.parse(now),
      );
    } catch (e) {
      _logger.e('Error registrando usuario: $e');
      return null;
    }
  }

  /// Iniciar sesión
  Future<UserProfile?> loginUser({
    required String username,
    required String password,
  }) async {
    try {
      final db = await database;

      final result = await db.query(
        _usersTable,
        where: 'username = ? AND password = ?',
        whereArgs: [username, password],
      );

      if (result.isEmpty) {
        _logger.w('Credenciales inválidas');
        return null;
      }

      final user = result.first;

      return UserProfile(
        id: user['id'] as String,
        name: user['fullName'] as String,
        age: user['age'] as int,
        createdAt: DateTime.parse(user['createdAt'] as String),
      );
    } catch (e) {
      _logger.e('Error en login: $e');
      return null;
    }
  }

  /// Obtener usuario por nombre de usuario
  Future<UserProfile?> getUserByUsername(String username) async {
    try {
      final db = await database;

      final result = await db.query(
        _usersTable,
        where: 'username = ?',
        whereArgs: [username],
      );

      if (result.isEmpty) return null;

      final user = result.first;

      return UserProfile(
        id: user['id'] as String,
        name: user['fullName'] as String,
        age: user['age'] as int,
        createdAt: DateTime.parse(user['createdAt'] as String),
      );
    } catch (e) {
      _logger.e('Error obteniendo usuario por username: $e');
      return null;
    }
  }

  /// Obtener usuario por ID
  Future<UserProfile?> getUserById(String userId) async {
    try {
      final db = await database;

      final result = await db.query(
        _usersTable,
        where: 'id = ?',
        whereArgs: [userId],
      );

      if (result.isEmpty) return null;

      final user = result.first;

      return UserProfile(
        id: user['id'] as String,
        name: user['fullName'] as String,
        age: user['age'] as int,
        createdAt: DateTime.parse(user['createdAt'] as String),
      );
    } catch (e) {
      _logger.e('Error obteniendo usuario: $e');
      return null;
    }
  }

  /// Actualizar perfil de usuario
  Future<bool> updateUserProfile({
    required String userId,
    required String fullName,
    required int age,
  }) async {
    try {
      final db = await database;

      await db.update(
        _usersTable,
        {
          'fullName': fullName,
          'age': age,
          'updatedAt': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [userId],
      );

      _logger.i('Perfil actualizado: $userId');
      return true;
    } catch (e) {
      _logger.e('Error actualizando perfil: $e');
      return false;
    }
  }

  // ==================== PERFILES DE NIÑOS ====================

  /// Crear perfil de niño
  Future<ChildProfile?> createChild({
    required String tutorId,
    required String name,
    required int age,
    DateTime? dateOfBirth,
    String? notes,
  }) async {
    try {
      _logger.i('📝 Creando niño: name="$name", age=$age, tutorId=$tutorId');

      final db = await database;
      final now = DateTime.now().toIso8601String();
      final id = 'child_${DateTime.now().millisecondsSinceEpoch}';

      final childData = {
        'id': id,
        'tutorId': tutorId,
        'name': name,
        'age': age,
        'dateOfBirth': dateOfBirth?.toIso8601String(),
        'notes': notes,
        'createdAt': now,
        'updatedAt': now,
      };

      _logger.i('📊 Datos a guardar: $childData');

      await db.insert(_childrenTable, childData);

      _logger.i('✅ Perfil de niño creado exitosamente: $name (ID: $id)');

      return ChildProfile(
        id: id,
        tutorId: tutorId,
        name: name,
        age: age,
        dateOfBirth: dateOfBirth,
        notes: notes,
        createdAt: DateTime.parse(now),
        updatedAt: DateTime.parse(now),
      );
    } catch (e) {
      _logger.e('❌ Error creando perfil de niño: $e');
      return null;
    }
  }

  /// Obtener todos los niños de un tutor
  Future<List<ChildProfile>> getChildrenByTutor(String tutorId) async {
    try {
      final db = await database;

      final results = await db.query(
        _childrenTable,
        where: 'tutorId = ?',
        whereArgs: [tutorId],
        orderBy: 'createdAt DESC',
      );

      return results.map(_mapToChildProfile).toList();
    } catch (e) {
      _logger.e('Error obteniendo niños: $e');
      return [];
    }
  }

  /// Obtener niño por ID
  Future<ChildProfile?> getChildById(String childId) async {
    try {
      final db = await database;

      final results = await db.query(
        _childrenTable,
        where: 'id = ?',
        whereArgs: [childId],
      );

      if (results.isEmpty) return null;

      return _mapToChildProfile(results.first);
    } catch (e) {
      _logger.e('Error obteniendo niño: $e');
      return null;
    }
  }

  /// Actualizar perfil de niño
  Future<bool> updateChild({
    required String childId,
    required String name,
    required int age,
    DateTime? dateOfBirth,
    String? notes,
  }) async {
    try {
      final db = await database;

      await db.update(
        _childrenTable,
        {
          'name': name,
          'age': age,
          'dateOfBirth': dateOfBirth?.toIso8601String(),
          'notes': notes,
          'updatedAt': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [childId],
      );

      _logger.i('Perfil de niño actualizado: $childId');
      return true;
    } catch (e) {
      _logger.e('Error actualizando perfil de niño: $e');
      return false;
    }
  }

  /// Eliminar perfil de niño
  Future<bool> deleteChild(String childId) async {
    try {
      final db = await database;

      await db.delete(_childrenTable, where: 'id = ?', whereArgs: [childId]);

      _logger.i('Perfil de niño eliminado: $childId');
      return true;
    } catch (e) {
      _logger.e('Error eliminando perfil de niño: $e');
      return false;
    }
  }

  /// Mapear resultado de BD a ChildProfile
  ChildProfile _mapToChildProfile(Map<String, dynamic> map) {
    return ChildProfile(
      id: map['id'] as String,
      tutorId: map['tutorId'] as String,
      name: map['name'] as String,
      age: map['age'] as int,
      dateOfBirth: map['dateOfBirth'] != null
          ? DateTime.parse(map['dateOfBirth'] as String)
          : null,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : null,
    );
  }

  // ==================== RESULTADOS DE ACTIVIDADES ====================

  /// Guardar resultado de actividad
  Future<bool> saveActivityResult({
    required String userId,
    String? childId,
    required ActivityResult result,
  }) async {
    try {
      _logger.i('📝 Intentando guardar resultado...');
      _logger.i('   userId: $userId');
      _logger.i('   childId: $childId');
      _logger.i('   activityName: ${result.activityName}');

      final db = await database;

      final id = 'result_${DateTime.now().millisecondsSinceEpoch}';

      final dataToInsert = {
        'id': id,
        'userId': userId,
        'childId': childId,
        'activityId': result.activityId,
        'activityName': result.activityName,
        'timestamp': result.timestamp.toIso8601String(),
        'result': result.result,
        'probability': result.probability,
        'confidence': result.confidence,
        'details': _encodeJson(result.details),
        'durationSeconds': result.duration.inSeconds,
      };

      _logger.i('   Datos a insertar: ${dataToInsert.keys.join(", ")}');

      final insertedId = await db.insert(_activityResultsTable, dataToInsert);

      _logger.i('✅ Resultado guardado exitosamente!');
      _logger.i('   ID insertado: $insertedId');
      _logger.i('   Actividad: ${result.activityName}');

      // Verificar que se guardó
      final verificacion = await db.query(
        _activityResultsTable,
        where: 'childId = ?',
        whereArgs: [childId],
      );
      _logger.i(
        '   Total de resultados para este niño: ${verificacion.length}',
      );

      return true;
    } catch (e, stackTrace) {
      _logger.e('❌ Error guardando resultado: $e');
      _logger.e('   Stack trace: $stackTrace');
      return false;
    }
  }

  /// Obtener resultados de actividad de un usuario
  Future<List<ActivityResult>> getUserActivityResults(String userId) async {
    try {
      final db = await database;

      final results = await db.query(
        _activityResultsTable,
        where: 'userId = ?',
        whereArgs: [userId],
        orderBy: 'timestamp DESC',
      );

      return results.map(_mapToActivityResult).toList();
    } catch (e) {
      _logger.e('Error obteniendo resultados: $e');
      return [];
    }
  }

  /// Obtener resultados de actividad de un niño específico
  Future<List<ActivityResult>> getChildActivityResults(String childId) async {
    try {
      _logger.i('🔍 Buscando resultados para childId: $childId');

      final db = await database;

      final results = await db.query(
        _activityResultsTable,
        where: 'childId = ?',
        whereArgs: [childId],
        orderBy: 'timestamp DESC',
      );

      _logger.i('   Resultados encontrados: ${results.length}');
      if (results.isNotEmpty) {
        for (var i = 0; i < results.length; i++) {
          _logger.i(
            '   [$i] ${results[i]['activityName']} - ${results[i]['timestamp']}',
          );
        }
      }

      return results.map(_mapToActivityResult).toList();
    } catch (e, stackTrace) {
      _logger.e('❌ Error obteniendo resultados del niño: $e');
      _logger.e('   Stack trace: $stackTrace');
      return [];
    }
  }

  /// Obtener resultados recientes de un usuario
  Future<List<ActivityResult>> getRecentActivityResults(
    String userId, {
    int limit = 10,
  }) async {
    try {
      final db = await database;

      final results = await db.query(
        _activityResultsTable,
        where: 'userId = ?',
        whereArgs: [userId],
        orderBy: 'timestamp DESC',
        limit: limit,
      );

      return results.map(_mapToActivityResult).toList();
    } catch (e) {
      _logger.e('Error obteniendo resultados recientes: $e');
      return [];
    }
  }

  /// Obtener resultados filtrados por actividad
  Future<List<ActivityResult>> getActivityResultsByType(
    String userId,
    String activityId,
  ) async {
    try {
      final db = await database;

      final results = await db.query(
        _activityResultsTable,
        where: 'userId = ? AND activityId = ?',
        whereArgs: [userId, activityId],
        orderBy: 'timestamp DESC',
      );

      return results.map(_mapToActivityResult).toList();
    } catch (e) {
      _logger.e('Error obteniendo resultados por tipo: $e');
      return [];
    }
  }

  // ==================== MÉTODOS AUXILIARES ====================

  /// Mapear resultado de BD a ActivityResult
  ActivityResult _mapToActivityResult(Map<String, dynamic> map) {
    return ActivityResult(
      activityId: map['activityId'] as String,
      activityName: map['activityName'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
      result: map['result'] as String,
      probability: (map['probability'] as num).toDouble(),
      confidence: (map['confidence'] as num).toDouble(),
      details: _decodeJson(map['details'] as String),
      duration: Duration(seconds: map['durationSeconds'] as int),
    );
  }

  /// Codificar JSON como string
  String _encodeJson(Map<String, dynamic> data) {
    return data.toString();
  }

  /// Decodificar JSON desde string
  Map<String, dynamic> _decodeJson(String data) {
    try {
      // Simple parsing para evitar dependencias adicionales
      return {'raw': data};
    } catch (e) {
      return {};
    }
  }

  /// Limpiar todos los datos
  Future<bool> clearAllData() async {
    try {
      final db = await database;
      await db.delete(_activityResultsTable);
      await db.delete(_usersTable);
      _logger.i('Todos los datos eliminados');
      return true;
    } catch (e) {
      _logger.e('Error limpiando datos: $e');
      return false;
    }
  }

  /// Cerrar base de datos
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
