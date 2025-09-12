// services/recipe_service.dart
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/recipe/recipe_type.dart';

class RecipeService {
  static final RecipeService _instance = RecipeService._internal();
  factory RecipeService() => _instance;
  RecipeService._internal();

  Database? _database;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<Recipe> _recipes = [];
  List<RecipeType> _recipeTypes = [];

  Future<void> initialize() async {
    await _initDatabase();
    await loadRecipeTypes();
    await loadRecipes();
  }

  Future<void> _initDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'recipes.db');

    _database = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // Create recipe_types table
        await db.execute('''
          CREATE TABLE recipe_types(
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            icon TEXT NOT NULL,
            color TEXT NOT NULL,
            description TEXT NOT NULL
          )
        ''');

        // Create recipes table
        await db.execute('''
          CREATE TABLE recipes(
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            typeId TEXT NOT NULL,
            typeName TEXT NOT NULL,
            description TEXT NOT NULL,
            imageUrl TEXT NOT NULL,
            ingredients TEXT NOT NULL,
            steps TEXT NOT NULL,
            preparationTime INTEGER NOT NULL,
            cookingTime INTEGER NOT NULL,
            servings INTEGER NOT NULL,
            difficulty TEXT NOT NULL,
            rating REAL NOT NULL,
            createdBy TEXT NOT NULL,
            createdByName TEXT NOT NULL,
            createdAt TEXT NOT NULL,
            updatedAt TEXT NOT NULL,
            firebaseId TEXT,
            FOREIGN KEY (typeId) REFERENCES recipe_types (id)
          )
        ''');
      },
    );
  }

  Future<void> loadRecipeTypes() async {
    try {
      // Load from assets first time
      final String jsonString = await rootBundle.loadString('assets/data/recipetypes.json');
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      _recipeTypes = (jsonData['recipeTypes'] as List)
          .map((item) => RecipeType.fromJson(item))
          .toList();

      // Save to SQLite
      await _saveRecipeTypesToDatabase();
    } catch (e) {
      // Try loading from SQLite if assets fail
      await _loadRecipeTypesFromDatabase();
    }
  }

  Future<void> _saveRecipeTypesToDatabase() async {
    if (_database == null) return;

    final batch = _database!.batch();
    for (final type in _recipeTypes) {
      batch.insert(
        'recipe_types',
        type.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit();
  }

  Future<void> _loadRecipeTypesFromDatabase() async {
    if (_database == null) return;

    final List<Map<String, dynamic>> maps = await _database!.query('recipe_types');
    _recipeTypes = maps.map((map) => RecipeType.fromJson(map)).toList();
  }

  Future<void> loadRecipes() async {
    await _loadRecipesFromSQLite();
    await _loadRecipesFromFirebase();
  }

  Future<void> _loadRecipesFromSQLite() async {
    if (_database == null) return;

    final List<Map<String, dynamic>> maps = await _database!.query('recipes');
    final sqliteRecipes = maps.map((map) {
      return Recipe.fromJson({
        ...map,
        'ingredients': json.decode(map['ingredients']),
        'steps': json.decode(map['steps']),
      });
    }).toList();

    _recipes = sqliteRecipes;
  }

  Future<void> _loadRecipesFromFirebase() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final querySnapshot = await _firestore
          .collection('recipes')
          .where('createdBy', isEqualTo: user.uid)
          .get();

      final firebaseRecipes = querySnapshot.docs.map((doc) {
        final data = doc.data();
        return Recipe.fromJson({
          ...data,
          'firebaseId': doc.id,
        });
      }).toList();

      // Merge with SQLite recipes, prioritizing Firebase data
      for (final firebaseRecipe in firebaseRecipes) {
        final existingIndex = _recipes.indexWhere((r) => r.id == firebaseRecipe.id);
        if (existingIndex != -1) {
          _recipes[existingIndex] = firebaseRecipe;
        } else {
          _recipes.add(firebaseRecipe);
          // Also save to SQLite
          await _saveRecipeToSQLite(firebaseRecipe);
        }
      }
    } catch (e) {
      print('Error loading recipes from Firebase: $e');
    }
  }

  Future<void> _saveRecipeToSQLite(Recipe recipe) async {
    if (_database == null) return;

    final recipeMap = recipe.toJson();
    recipeMap['ingredients'] = json.encode(recipe.ingredients);
    recipeMap['steps'] = json.encode(recipe.steps);

    await _database!.insert(
      'recipes',
      recipeMap,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> _saveRecipeToFirebase(Recipe recipe) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final recipeData = recipe.toJson();

      if (recipe.firebaseId != null) {
        // Update existing
        await _firestore
            .collection('recipes')
            .doc(recipe.firebaseId)
            .update(recipeData);
      } else {
        // Create new
        final docRef = await _firestore
            .collection('recipes')
            .add(recipeData);

        // Update local recipe with Firebase ID
        final updatedRecipe = recipe.copyWith(firebaseId: docRef.id);
        final index = _recipes.indexWhere((r) => r.id == recipe.id);
        if (index != -1) {
          _recipes[index] = updatedRecipe;
          await _saveRecipeToSQLite(updatedRecipe);
        }
      }
    } catch (e) {
      print('Error saving recipe to Firebase: $e');
    }
  }

  List<RecipeType> getRecipeTypes() => _recipeTypes;

  List<Recipe> getAllRecipes() => _recipes;

  List<Recipe> getRecipesByType(String typeId) {
    if (typeId == 'all') return _recipes;
    return _recipes.where((recipe) => recipe.typeId == typeId).toList();
  }

  Recipe? getRecipeById(String id) {
    try {
      return _recipes.firstWhere((recipe) => recipe.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<void> addRecipe(Recipe recipe) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final recipeWithUser = recipe.copyWith(
      createdBy: user.uid,
      createdByName: user.displayName ?? user.email ?? 'Unknown User',
    );

    _recipes.add(recipeWithUser);

    // Save to both SQLite and Firebase
    await _saveRecipeToSQLite(recipeWithUser);
    await _saveRecipeToFirebase(recipeWithUser);
  }

  Future<void> updateRecipe(Recipe updatedRecipe) async {
    final index = _recipes.indexWhere((recipe) => recipe.id == updatedRecipe.id);
    if (index != -1) {
      final now = DateTime.now();
      final recipeWithUpdate = updatedRecipe.copyWith(updatedAt: now);

      _recipes[index] = recipeWithUpdate;

      // Update in both SQLite and Firebase
      await _saveRecipeToSQLite(recipeWithUpdate);
      await _saveRecipeToFirebase(recipeWithUpdate);
    }
  }

  Future<void> deleteRecipe(String id) async {
    final recipe = getRecipeById(id);
    if (recipe == null) return;

    // Remove from local list
    _recipes.removeWhere((recipe) => recipe.id == id);

    // Delete from SQLite
    if (_database != null) {
      await _database!.delete(
        'recipes',
        where: 'id = ?',
        whereArgs: [id],
      );
    }

    // Delete from Firebase
    if (recipe.firebaseId != null) {
      try {
        await _firestore
            .collection('recipes')
            .doc(recipe.firebaseId)
            .delete();
      } catch (e) {
        print('Error deleting recipe from Firebase: $e');
      }
    }
  }

  String generateNewId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  Future<void> syncWithFirebase() async {
    await _loadRecipesFromFirebase();
  }

  // Get recipes by current user
  List<Recipe> getUserRecipes() {
    final user = _auth.currentUser;
    if (user == null) return [];

    return _recipes.where((recipe) => recipe.createdBy == user.uid).toList();
  }

  // Get recipe statistics
  Map<String, int> getRecipeStats() {
    final userRecipes = getUserRecipes();
    final categories = <String, int>{};

    for (final recipe in userRecipes) {
      categories[recipe.typeName] = (categories[recipe.typeName] ?? 0) + 1;
    }

    return {
      'total': userRecipes.length,
      'categories': categories.length,
      'avgRating': userRecipes.isEmpty
          ? 0
          : (userRecipes.map((r) => r.rating).reduce((a, b) => a + b) / userRecipes.length).round(),
    };
  }
}