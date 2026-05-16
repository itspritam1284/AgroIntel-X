import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'gemini_service.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('farming_plans.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE farming_plans (
        id TEXT PRIMARY KEY,
        crop_name TEXT NOT NULL,
        planting_date TEXT NOT NULL,
        created_date TEXT NOT NULL,
        overview TEXT NOT NULL,
        total_duration TEXT NOT NULL,
        activities TEXT NOT NULL,
        sensor_data TEXT NOT NULL
      )
    ''');
  }

  // Insert a farming plan
  Future<void> insertPlan(FarmingPlan plan) async {
    final db = await database;
    await db.insert('farming_plans', {
      'id': plan.id,
      'crop_name': plan.cropName,
      'planting_date': plan.plantingDate.toIso8601String(),
      'created_date': plan.createdDate.toIso8601String(),
      'overview': plan.overview,
      'total_duration': plan.totalDuration,
      'activities': jsonEncode(plan.activities.map((a) => a.toJson()).toList()),
      'sensor_data': jsonEncode(plan.sensorData.toJson()),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // Get all farming plans
  Future<List<FarmingPlan>> getAllPlans() async {
    final db = await database;
    final result = await db.query(
      'farming_plans',
      orderBy: 'created_date DESC',
    );

    return result.map((map) {
      return FarmingPlan(
        id: map['id'] as String,
        cropName: map['crop_name'] as String,
        plantingDate: DateTime.parse(map['planting_date'] as String),
        createdDate: DateTime.parse(map['created_date'] as String),
        overview: map['overview'] as String,
        totalDuration: map['total_duration'] as String,
        activities:
            (jsonDecode(map['activities'] as String) as List)
                .map((a) => PlanActivity.fromJson(a))
                .toList(),
        sensorData: SensorSnapshot.fromJson(
          jsonDecode(map['sensor_data'] as String),
        ),
      );
    }).toList();
  }

  // Get the latest plan
  Future<FarmingPlan?> getLatestPlan() async {
    final plans = await getAllPlans();
    return plans.isEmpty ? null : plans.first;
  }

  // Get a specific plan by ID
  Future<FarmingPlan?> getPlanById(String id) async {
    final db = await database;
    final result = await db.query(
      'farming_plans',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (result.isEmpty) return null;

    final map = result.first;
    return FarmingPlan(
      id: map['id'] as String,
      cropName: map['crop_name'] as String,
      plantingDate: DateTime.parse(map['planting_date'] as String),
      createdDate: DateTime.parse(map['created_date'] as String),
      overview: map['overview'] as String,
      totalDuration: map['total_duration'] as String,
      activities:
          (jsonDecode(map['activities'] as String) as List)
              .map((a) => PlanActivity.fromJson(a))
              .toList(),
      sensorData: SensorSnapshot.fromJson(
        jsonDecode(map['sensor_data'] as String),
      ),
    );
  }

  // Delete a plan
  Future<void> deletePlan(String id) async {
    final db = await database;
    await db.delete('farming_plans', where: 'id = ?', whereArgs: [id]);
  }

  // Delete all plans
  Future<void> deleteAllPlans() async {
    final db = await database;
    await db.delete('farming_plans');
  }

  // Close the database
  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
