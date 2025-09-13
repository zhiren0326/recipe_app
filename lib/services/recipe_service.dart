// services/recipe_service.dart
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/recipe/recipe_type.dart';
import 'review_service.dart';

class RecipeService {
  static final RecipeService _instance = RecipeService._internal();
  factory RecipeService() => _instance;
  RecipeService._internal();

  Database? _database;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ReviewService _reviewService = ReviewService();

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
      version: 2, // Increment version for new columns
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

        // Create recipes table with new rating columns
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
            averageRating REAL,
            totalRatings INTEGER,
            FOREIGN KEY (typeId) REFERENCES recipe_types (id)
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // Add new columns for rating
          try {
            await db.execute('ALTER TABLE recipes ADD COLUMN averageRating REAL');
          } catch (e) {
            print('Column averageRating already exists');
          }

          try {
            await db.execute('ALTER TABLE recipes ADD COLUMN totalRatings INTEGER');
          } catch (e) {
            print('Column totalRatings already exists');
          }
        }
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
    // Clear existing recipes to avoid duplicates
    _recipes.clear();

    // Load from SQLite first
    await _loadRecipesFromSQLite();

    // Then sync with Firebase
    await syncWithFirebase();
  }

  Future<void> _loadRecipesFromSQLite() async {
    if (_database == null) return;

    try {
      final List<Map<String, dynamic>> maps = await _database!.query('recipes');
      final sqliteRecipes = maps.map((map) {
        return Recipe.fromJson({
          ...map,
          'ingredients': json.decode(map['ingredients']),
          'steps': json.decode(map['steps']),
        });
      }).toList();

      _recipes = sqliteRecipes;
      print('Loaded ${_recipes.length} recipes from SQLite');
    } catch (e) {
      print('Error loading recipes from SQLite: $e');
    }
  }

  Future<void> _loadRecipesFromFirebase() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('No user logged in, skipping Firebase load');
        return;
      }

      print('Loading recipes from Firebase for user: ${user.uid}');

      // Get ALL recipes from Firebase (not just user's recipes)
      final querySnapshot = await _firestore
          .collection('recipes')
          .get();

      print('Found ${querySnapshot.docs.length} recipes in Firebase');

      // Create a set of Firebase recipe IDs for comparison
      final firebaseRecipeIds = <String>{};

      final firebaseRecipes = querySnapshot.docs.map((doc) {
        final data = doc.data();
        firebaseRecipeIds.add(data['id']);
        return Recipe.fromJson({
          ...data,
          'firebaseId': doc.id,
        });
      }).toList();

      // Remove recipes that were deleted from Firebase
      final localRecipesCopy = List<Recipe>.from(_recipes);
      for (final localRecipe in localRecipesCopy) {
        // If recipe has a Firebase ID but is not in Firebase anymore, delete it locally
        if (localRecipe.firebaseId != null &&
            localRecipe.firebaseId!.isNotEmpty &&
            !firebaseRecipeIds.contains(localRecipe.id)) {

          print('Recipe ${localRecipe.id} was deleted from Firebase, removing locally');

          // Remove from SQLite
          if (_database != null) {
            await _database!.delete(
              'recipes',
              where: 'id = ?',
              whereArgs: [localRecipe.id],
            );
          }

          // Remove from memory
          _recipes.removeWhere((r) => r.id == localRecipe.id);
        }
      }

      // Merge with SQLite recipes
      for (final firebaseRecipe in firebaseRecipes) {
        final existingIndex = _recipes.indexWhere((r) => r.id == firebaseRecipe.id);

        if (existingIndex != -1) {
          // Update existing recipe with Firebase data
          _recipes[existingIndex] = firebaseRecipe;

          // Also update in SQLite
          await _saveRecipeToSQLite(firebaseRecipe);
        } else {
          // Add new recipe from Firebase
          _recipes.add(firebaseRecipe);

          // Also save to SQLite for offline access
          await _saveRecipeToSQLite(firebaseRecipe);
        }
      }

      print('Total recipes after Firebase sync: ${_recipes.length}');
    } catch (e) {
      print('Error loading recipes from Firebase: $e');
      // Don't throw error - continue with SQLite data
    }
  }

  Future<void> _saveRecipeToSQLite(Recipe recipe) async {
    if (_database == null) return;

    try {
      final recipeMap = recipe.toJson();
      recipeMap['ingredients'] = json.encode(recipe.ingredients);
      recipeMap['steps'] = json.encode(recipe.steps);

      await _database!.insert(
        'recipes',
        recipeMap,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      print('Error saving recipe to SQLite: $e');
    }
  }

  Future<void> _saveRecipeToFirebase(Recipe recipe) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('No user logged in, cannot save to Firebase');
        return;
      }

      final recipeData = recipe.toJson();

      // Remove firebaseId from data to avoid confusion
      recipeData.remove('firebaseId');

      if (recipe.firebaseId != null && recipe.firebaseId!.isNotEmpty) {
        // Update existing
        print('Updating recipe in Firebase: ${recipe.firebaseId}');
        await _firestore
            .collection('recipes')
            .doc(recipe.firebaseId)
            .update(recipeData);
      } else {
        // Create new
        print('Creating new recipe in Firebase');
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

        print('Created recipe in Firebase with ID: ${docRef.id}');
      }
    } catch (e) {
      print('Error saving recipe to Firebase: $e');
      // Don't throw - allow app to continue working offline
    }
  }

  List<RecipeType> getRecipeTypes() => _recipeTypes;

  List<Recipe> getAllRecipes() {
    print('Getting all recipes: ${_recipes.length}');
    return _recipes;
  }

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
    if (user == null) {
      throw Exception('User must be logged in to add recipes');
    }

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

  // FIXED DELETE FUNCTION
  Future<void> deleteRecipe(String id) async {
    final recipe = getRecipeById(id);
    if (recipe == null) {
      print('Recipe not found: $id');
      return;
    }

    try {
      // Initialize review service
      await _reviewService.initialize();

      // 1. First delete from Firebase if it exists there
      if (recipe.firebaseId != null && recipe.firebaseId!.isNotEmpty) {
        try {
          // Delete recipe from Firebase
          await _firestore
              .collection('recipes')
              .doc(recipe.firebaseId)
              .delete();
          print('Deleted recipe from Firebase: ${recipe.firebaseId}');

          // Delete all reviews for this recipe from Firebase
          await _reviewService.deleteAllReviewsForRecipe(id);

        } catch (e) {
          print('Error deleting from Firebase: $e');
          // Continue with local deletion even if Firebase fails
        }
      }

      // 2. Delete from SQLite
      if (_database != null) {
        // Delete the recipe
        await _database!.delete(
          'recipes',
          where: 'id = ?',
          whereArgs: [id],
        );
        print('Deleted recipe from SQLite: $id');

        // Delete associated reviews from SQLite
        await _database!.delete(
          'reviews',
          where: 'recipeId = ?',
          whereArgs: [id],
        );
        print('Deleted reviews from SQLite for recipe: $id');
      }

      // 3. IMPORTANT: Remove from memory/cache
      _recipes.removeWhere((recipe) => recipe.id == id);
      print('Removed recipe from cache: $id');

      // 4. Clear review cache for this recipe
      _reviewService.clearCacheForRecipe(id);

    } catch (e) {
      print('Error in deleteRecipe: $e');
      throw Exception('Failed to delete recipe: $e');
    }
  }

  String generateNewId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  Future<void> syncWithFirebase() async {
    print('Starting Firebase sync...');

    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('No user logged in, skipping Firebase sync');
        return;
      }

      // Get all recipes from Firebase
      final querySnapshot = await _firestore
          .collection('recipes')
          .get();

      print('Found ${querySnapshot.docs.length} recipes in Firebase');

      // Create a set of Firebase recipe IDs for comparison
      final firebaseRecipeIds = <String>{};

      final firebaseRecipes = querySnapshot.docs.map((doc) {
        final data = doc.data();
        firebaseRecipeIds.add(data['id']);
        return Recipe.fromJson({
          ...data,
          'firebaseId': doc.id,
        });
      }).toList();

      // Remove recipes that were deleted from Firebase
      final localRecipesCopy = List<Recipe>.from(_recipes);
      for (final localRecipe in localRecipesCopy) {
        // If recipe has a Firebase ID but is not in Firebase anymore, delete it locally
        if (localRecipe.firebaseId != null &&
            localRecipe.firebaseId!.isNotEmpty &&
            !firebaseRecipeIds.contains(localRecipe.id)) {

          print('Recipe ${localRecipe.id} was deleted from Firebase, removing locally');

          // Remove from SQLite
          if (_database != null) {
            await _database!.delete(
              'recipes',
              where: 'id = ?',
              whereArgs: [localRecipe.id],
            );

            // Also delete reviews
            await _database!.delete(
              'reviews',
              where: 'recipeId = ?',
              whereArgs: [localRecipe.id],
            );
          }

          // Remove from memory
          _recipes.removeWhere((r) => r.id == localRecipe.id);

          // Clear review cache
          _reviewService.clearCacheForRecipe(localRecipe.id);
        }
      }

      // Add or update recipes from Firebase
      for (final firebaseRecipe in firebaseRecipes) {
        final existingIndex = _recipes.indexWhere((r) => r.id == firebaseRecipe.id);

        if (existingIndex != -1) {
          // Update existing recipe
          _recipes[existingIndex] = firebaseRecipe;
        } else {
          // Add new recipe
          _recipes.add(firebaseRecipe);
        }

        // Save to SQLite for offline access
        await _saveRecipeToSQLite(firebaseRecipe);
      }

      print('Total recipes after Firebase sync: ${_recipes.length}');

    } catch (e) {
      print('Error syncing with Firebase: $e');
      // Don't throw error - continue with local data
    }
  }

  // Get recipes by current user
  List<Recipe> getUserRecipes() {
    final user = _auth.currentUser;
    if (user == null) {
      print('No user logged in, returning empty list');
      return [];
    }

    final userRecipes = _recipes.where((recipe) => recipe.createdBy == user.uid).toList();
    print('Found ${userRecipes.length} recipes for user ${user.uid}');
    return userRecipes;
  }

  // Get recipe statistics
  Map<String, dynamic> getRecipeStats() {
    final userRecipes = getUserRecipes();
    final categories = <String, int>{};

    for (final recipe in userRecipes) {
      categories[recipe.typeName] = (categories[recipe.typeName] ?? 0) + 1;
    }

    // Calculate average rating from recipes with reviews
    double avgRating = 0;
    int ratedRecipes = 0;
    for (final recipe in userRecipes) {
      if (recipe.averageRating != null && recipe.averageRating! > 0) {
        avgRating += recipe.averageRating!;
        ratedRecipes++;
      }
    }

    if (ratedRecipes > 0) {
      avgRating = avgRating / ratedRecipes;
    }

    return {
      'total': userRecipes.length,
      'categories': categories.length,
      'avgRating': avgRating.round(),
      'categoryBreakdown': categories,
    };
  }

  // Method to refresh a single recipe
  Future<void> refreshRecipe(String recipeId) async {
    try {
      // Try to get from Firebase first
      final querySnapshot = await _firestore
          .collection('recipes')
          .where('id', isEqualTo: recipeId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        // Recipe was deleted from Firebase
        print('Recipe $recipeId not found in Firebase, removing locally');

        // Remove from SQLite
        if (_database != null) {
          await _database!.delete(
            'recipes',
            where: 'id = ?',
            whereArgs: [recipeId],
          );

          // Delete reviews
          await _database!.delete(
            'reviews',
            where: 'recipeId = ?',
            whereArgs: [recipeId],
          );
        }

        // Remove from memory
        _recipes.removeWhere((r) => r.id == recipeId);

        // Clear review cache
        _reviewService.clearCacheForRecipe(recipeId);

      } else {
        // Update recipe
        final doc = querySnapshot.docs.first;
        final data = doc.data();
        final updatedRecipe = Recipe.fromJson({
          ...data,
          'firebaseId': doc.id,
        });

        final existingIndex = _recipes.indexWhere((r) => r.id == recipeId);
        if (existingIndex != -1) {
          _recipes[existingIndex] = updatedRecipe;
        } else {
          _recipes.add(updatedRecipe);
        }

        await _saveRecipeToSQLite(updatedRecipe);
      }
    } catch (e) {
      print('Error refreshing recipe: $e');
    }
  }

  // Method to clear cache and force reload
  Future<void> refreshRecipes() async {
    _recipes.clear();
    _reviewService.clearAllCache();
    await loadRecipes();
  }
}