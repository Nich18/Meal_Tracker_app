import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:typed_data';


class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  factory DatabaseHelper() => _instance;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'meal.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) {
        db.execute('''
          CREATE TABLE users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            email TEXT UNIQUE NOT NULL,
            password TEXT NOT NULL
          )
        ''');
       db.execute('''
        CREATE TABLE profiles (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          height REAL NOT NULL,
          weight REAL NOT NULL,
          calorieGoal REAL, -- Ajouter le seuil calorique
          userId INTEGER NOT NULL,
          FOREIGN KEY(userId) REFERENCES users(id)
        )
      ''');
        db.execute('''
        CREATE TABLE meals (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          calories REAL NOT NULL,
          datetime TEXT NOT NULL,
          photo BLOB,
          userId INTEGER NOT NULL,  
          FOREIGN KEY(userId) REFERENCES users(id)
        )
      ''');

      db.execute('''
      CREATE TABLE notifications (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        message TEXT NOT NULL,
        is_read INTEGER DEFAULT 0,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');
    db.execute('''
      CREATE TABLE IF NOT EXISTS messages (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER,
        message TEXT,
        isUser INTEGER,  -- 1 pour l'utilisateur, 0 pour le chatbot
        timestamp INTEGER
      )
    ''');
      },
    );
  }

  Future<int> insertUser(String name, String email, String password) async {
    final db = await database;
    return await db.insert('users', {'name': name, 'email': email, 'password': password});
  }

  Future<Map<String, dynamic>?> getUser(String email, String password) async {
    final db = await database;
    final result = await db.query('users',
        where: 'email = ? AND password = ?', whereArgs: [email, password]);
    return result.isNotEmpty ? result.first : null;
  }

  Future<int> insertProfile(double height, double weight, int userId, double calorieGoal) async {
  final db = await database;
  return await db.insert('profiles', {
    'height': height,
    'weight': weight,
    'userId': userId,
    'calorieGoal': calorieGoal, // Ajoutez ce champ
  });
}

  Future<Map<String, dynamic>?> getUserById(int id) async {
  final db = await database;
  final result = await db.query('users', where: 'id = ?', whereArgs: [id]);
  return result.isNotEmpty ? result.first : null;
}

Future<Map<String, dynamic>?> getProfileByUserId(int userId) async {
  final db = await database;
  final result = await db.query('profiles', where: 'userId = ?', whereArgs: [userId]);
  return result.isNotEmpty ? result.first : null;
}

Future<int> insertMeal(String name, double calories, DateTime datetime, Uint8List? photo, int userId) async {
  final db = await database;
  return await db.insert('meals', {
    'name': name,
    'calories': calories,
    'datetime': datetime.toIso8601String(),
    'photo': photo,
    'userId': userId, // Ajoutez userId ici
  });
}
Future<List<Map<String, dynamic>>> getMeals() async {
  final db = await database;
  return await db.query('meals'); // Récupérer tous les repas
}

Future<List<Map<String, dynamic>>> getMealsByUserId(int userId) async {
  final db = await database;
  return await db.query('meals', where: 'userId = ?', whereArgs: [userId], orderBy: 'datetime DESC');
}
Future<Map<String, dynamic>?> getMeal(int id) async {
  final db = await database;
  final result = await db.query('meals', where: 'id = ?', whereArgs: [id]);
  return result.isNotEmpty ? result.first : null;
}
Future<void> deleteMeal(int id) async {
  final db = await database; // Accès à la base de données
  await db.delete(
    'meals', // Nom de la table
    where: 'id = ?', // Condition de suppression
    whereArgs: [id], // Valeur pour remplacer "?"
  );
}
Future<void> updateMeal(int id, String name, double calories) async {
  final db = await database;
  await db.update(
    'meals',
    {
      'name': name,
      'calories': calories,
      'datetime': DateTime.now().toIso8601String(), // Optionnel : mettre à jour la date
    },
    where: 'id = ?',
    whereArgs: [id],
  );
}

Future<double> getTotalCaloriesByDate(DateTime date) async {
  final db = await database;
  final startDate = DateTime(date.year, date.month, date.day);
  final endDate = startDate.add(Duration(days: 1));

  final result = await db.rawQuery('''
    SELECT SUM(calories) as totalCalories
    FROM meals
    WHERE datetime >= ? AND datetime < ?
  ''', [startDate.toIso8601String(), endDate.toIso8601String()]);

  final totalCalories = result.first['totalCalories'];
  return (totalCalories as num?)?.toDouble() ?? 0.0;
}

Future<double> getTotalCaloriesByWeek(DateTime date) async {
  final db = await database;
  final startDate = date.subtract(Duration(days: date.weekday - 1));
  final endDate = startDate.add(Duration(days: 7));

  final result = await db.rawQuery('''
    SELECT SUM(calories) as totalCalories
    FROM meals
    WHERE datetime >= ? AND datetime < ?
  ''', [startDate.toIso8601String(), endDate.toIso8601String()]);

  final totalCalories = result.first['totalCalories'];
  return (totalCalories as num?)?.toDouble() ?? 0.0;
}

Future<double> getTotalCaloriesByMonth(int year, int month) async {
  final db = await database;
  final startDate = DateTime(year, month, 1);
  final endDate = DateTime(year, month + 1, 1);

  final result = await db.rawQuery('''
    SELECT SUM(calories) as totalCalories
    FROM meals
    WHERE datetime >= ? AND datetime < ?
  ''', [startDate.toIso8601String(), endDate.toIso8601String()]);

  final totalCalories = result.first['totalCalories'];
  return (totalCalories as num?)?.toDouble() ?? 0.0;
}

Future<double> getWeeklyAverageCalories() async {
  final db = await database;

  final result = await db.rawQuery('''
    SELECT AVG(dailyCalories) as weeklyAverage
    FROM (
      SELECT SUM(calories) as dailyCalories
      FROM meals
      GROUP BY strftime('%Y-%m-%d', datetime)
    )
  ''');
  
  final weeklyAverage = result.first['weeklyAverage'];
  return (weeklyAverage as num?)?.toDouble() ?? 0.0;
}

Future<double> getTotalCaloriesBySpecificDateRange(int userId, DateTime start, DateTime end) async {
  final db = await database;

  final result = await db.rawQuery('''
    SELECT SUM(calories) AS totalCalories
    FROM meals
    WHERE datetime >= ? AND datetime < ? AND userId = ?
  ''', [start.toIso8601String(), end.toIso8601String(), userId]);

  final totalCalories = result.first['totalCalories'];
  return (totalCalories as num?)?.toDouble() ?? 0.0;
}

Future<double> getAverageCaloriesForWeek(int userId, DateTime date) async {
  final db = await database;

  final startDate = date.subtract(Duration(days: date.weekday - 1));
  final endDate = startDate.add(Duration(days: 7));

  final result = await db.rawQuery('''
    SELECT AVG(dailyCalories) AS averageCalories
    FROM (
      SELECT SUM(calories) AS dailyCalories
      FROM meals
      WHERE datetime >= ? AND datetime < ? AND userId = ?
      GROUP BY strftime('%Y-%m-%d', datetime)
    )
  ''', [startDate.toIso8601String(), endDate.toIso8601String(), userId]);

  final averageCalories = result.first['averageCalories'];
  return (averageCalories as num?)?.toDouble() ?? 0.0;
}
Future<List<Map<String, dynamic>>> getCaloriesByMonth(int year, int month) async {
  final db = await database;

  // Définir les dates de début et de fin du mois
  final startDate = DateTime(year, month, 1);
  final endDate = DateTime(year, month + 1, 1);

  // Requête SQL pour obtenir le total des calories par jour
  final result = await db.rawQuery('''
    SELECT strftime('%d', datetime) as date, SUM(calories) as calories
    FROM meals
    WHERE datetime >= ? AND datetime < ?
    GROUP BY strftime('%Y-%m-%d', datetime)
    ORDER BY strftime('%Y-%m-%d', datetime)
  ''', [startDate.toIso8601String(), endDate.toIso8601String()]);

  return result;
}

Future<double> getTotalCaloriesByYear(int userId, int year) async {
  final db = await database;

  final startDate = DateTime(year, 1, 1);
  final endDate = DateTime(year + 1, 1, 1);

  final result = await db.rawQuery('''
    SELECT SUM(calories) as totalCalories
    FROM meals
    WHERE datetime >= ? AND datetime < ? AND userId = ?
  ''', [startDate.toIso8601String(), endDate.toIso8601String(), userId]);

  final totalCalories = result.first['totalCalories'];
  return (totalCalories as num?)?.toDouble() ?? 0.0;
}

Future<void> addNotification({
  required int userId,
  required String title,
  required String message,
}) async {
  final db = await database; // Obtenez l'instance de la base de données
  await db.insert(
    'notifications',
    {
      'user_id': userId,
      'title': title,
      'message': message,
      'is_read': 0, // Par défaut, non lue
      'created_at': DateTime.now().toIso8601String(),
    },
    conflictAlgorithm: ConflictAlgorithm.replace,
  );
}
Future<List<Map<String, dynamic>>> getNotificationsByUserId(int userId) async {
  final db = await database;
  return await db.query(
    'notifications',
    where: 'user_id = ?',
    whereArgs: [userId],
    orderBy: 'created_at DESC', // Trier par la plus récente
  );
}
Future<void> markNotificationAsRead(int notificationId) async {
  final db = await database;
  await db.update(
    'notifications',
    {'is_read': 1}, // Marquer comme lue
    where: 'id = ?',
    whereArgs: [notificationId],
  );
}

// Insérer un message dans la table
  Future<void> insertMessage(int userId, String message, bool isUser) async {
    final db = await database;

    await db.insert(
      'messages',
      {
        'userId': userId,
        'message': message,
        'isUser': isUser ? 1 : 0,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Récupérer les messages pour un utilisateur donné
  Future<List<Map<String, dynamic>>> getMessages(int userId) async {
    final db = await database;
    return await db.query(
      'messages',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'timestamp ASC',  // Trier les messages par date croissante
    );
  }



}
