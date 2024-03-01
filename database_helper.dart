import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart' as sql;

class DatabaseHelper {
  static Future<sql.Database> db() async {
    return sql.openDatabase(
      'auto_notes_booklet.db',
      version: 1,
      onCreate: (sql.Database database, int version) async {
        await createTables(database);
      },
    );
  }

  static Future<void> createTables(sql.Database database) async {
    await database.execute("""CREATE TABLE cars_table(
        id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
        car TEXT,
        createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
      )
      """);
    await database.execute("""CREATE TABLE car_notes(
        id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
        car_id INTEGER,
        date TEXT,
        work TEXT,
        km TEXT,
        notes TEXT,
        createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
      )
      """);
  }

// id: the id of a item
// title, description: name and description of  activity
// created_at: the time that the item was created. It will be automatically handled by SQLite
  // Create new item
  static Future<int> createCar(String? car) async {
    final db = await DatabaseHelper.db();

    final data = {'car': car};
    final id = await db.insert('cars_table', data,
        conflictAlgorithm: sql.ConflictAlgorithm.replace);
    return id;

    // When a UNIQUE constraint violation occurs,
    // the pre-existing rows that are causing the constraint violation
    // are removed prior to inserting or updating the current row.
    // Thus the insert or update always occurs.
  }

  // Read all items
  static Future<List<Map<String, dynamic>>> getCars() async {
    final db = await DatabaseHelper.db();
    return db.query('cars_table', orderBy: "id");
  }

  // Get a single item by id
  //We dont use this method, it is for you if you want it.
  static Future<List<Map<String, dynamic>>> getItem(int id) async {
    final db = await DatabaseHelper.db();
    return db.query('cars_table', where: "id = ?", whereArgs: [id], limit: 1);
  }

  // Update an item by id
  static Future<int> updateItem(int id, String car) async {
    final db = await DatabaseHelper.db();

    final data = {'car': car, 'createdAt': DateTime.now().toString()};

    final result =
        await db.update('cars_table', data, where: "id = ?", whereArgs: [id]);
    return result;
  }

  // Delete
  static Future<void> deleteItem(int id) async {
    final db = await DatabaseHelper.db();
    try {
      await db.delete("cars_table", where: "id = ?", whereArgs: [id]);
      await db.delete("car_notes", where: "car_id = ?", whereArgs: [id]);
    } catch (err) {
      debugPrint("Something went wrong when deleting an item: $err");
    }
  }

//NOTES

// Read all items
  static Future<List<Map<String, dynamic>>> getNotes(int carID) async {
    final db = await DatabaseHelper.db();
    return db.query('car_notes',
        where: "car_id = ?", whereArgs: [carID], orderBy: "id");
  }

  // Create new item
  static Future<int> createNote(
      int? carID, String? work, String? date, String? km, String? notes) async {
    final db = await DatabaseHelper.db();

    final data = {
      'car_id': carID,
      'work': work,
      'date': date,
      'km': km,
      'notes': notes
    };
    final id = await db.insert('car_notes', data,
        conflictAlgorithm: sql.ConflictAlgorithm.replace);
    return id;

    // When a UNIQUE constraint violation occurs,
    // the pre-existing rows that are causing the constraint violation
    // are removed prior to inserting or updating the current row.
    // Thus the insert or update always occurs.
  }

  static Future<int> updateNote(
      int id, String work, String date, String km, String notes) async {
    final db = await DatabaseHelper.db();

    final data = {
      'work': work,
      'date': date,
      'km': km,
      'notes': notes,
      'createdAt': DateTime.now().toString()
    };

    final result =
        await db.update('car_notes', data, where: "id = ?", whereArgs: [id]);
    return result;
  }

  // Delete
  static Future<void> deleteNote(int id) async {
    final db = await DatabaseHelper.db();
    try {
      await db.delete("car_notes", where: "id = ?", whereArgs: [id]);
    } catch (err) {
      debugPrint("Something went wrong when deleting an item: $err");
    }
  }
}
