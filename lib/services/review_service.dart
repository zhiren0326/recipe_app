// services/review_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../screens/review/review.dart';

class ReviewService {
  static final ReviewService _instance = ReviewService._internal();
  factory ReviewService() => _instance;
  ReviewService._internal();

  Database? _database;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Map<String, List<Review>> _reviewsByRecipe = {};
  Map<String, StreamSubscription?> _reviewListeners = {};

  Future<void> initialize() async {
    await _initDatabase();
  }

  Future<void> _initDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'recipes.db');

    _database = await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        // Create recipe_types table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS recipe_types(
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            icon TEXT NOT NULL,
            color TEXT NOT NULL,
            description TEXT NOT NULL
          )
        ''');

        // Create recipes table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS recipes(
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

        // Create reviews table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS reviews(
            id TEXT PRIMARY KEY,
            recipeId TEXT NOT NULL,
            userId TEXT NOT NULL,
            userName TEXT NOT NULL,
            userEmail TEXT NOT NULL,
            rating REAL NOT NULL,
            comment TEXT NOT NULL,
            createdAt TEXT NOT NULL,
            updatedAt TEXT NOT NULL,
            firebaseId TEXT,
            FOREIGN KEY (recipeId) REFERENCES recipes (id) ON DELETE CASCADE
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // Add reviews table
          await db.execute('''
            CREATE TABLE IF NOT EXISTS reviews(
              id TEXT PRIMARY KEY,
              recipeId TEXT NOT NULL,
              userId TEXT NOT NULL,
              userName TEXT NOT NULL,
              userEmail TEXT NOT NULL,
              rating REAL NOT NULL,
              comment TEXT NOT NULL,
              createdAt TEXT NOT NULL,
              updatedAt TEXT NOT NULL,
              firebaseId TEXT,
              FOREIGN KEY (recipeId) REFERENCES recipes (id) ON DELETE CASCADE
            )
          ''');

          // Add rating columns to recipes table if they don't exist
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

  // Stream for real-time review updates
  Stream<List<Review>> getReviewsStream(String recipeId) {
    // Cancel any existing listener for this recipe
    _reviewListeners[recipeId]?.cancel();

    // Create a stream controller
    final controller = StreamController<List<Review>>.broadcast();

    // Load initial data from SQLite
    _loadReviewsFromSQLite(recipeId).then((_) {
      controller.add(_reviewsByRecipe[recipeId] ?? []);
    });

    // Set up Firebase listener
    final subscription = _firestore
        .collection('reviews')
        .where('recipeId', isEqualTo: recipeId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
      final firebaseReviews = snapshot.docs.map((doc) {
        final data = doc.data();
        return Review.fromJson({
          ...data,
          'firebaseId': doc.id,
        });
      }).toList();

      // Update local cache
      _reviewsByRecipe[recipeId] = firebaseReviews;

      // Save to SQLite for offline access
      for (final review in firebaseReviews) {
        _saveReviewToSQLite(review);
      }

      // Emit the updated reviews
      controller.add(firebaseReviews);
    }, onError: (error) {
      print('Error listening to reviews: $error');
      // On error, return cached data
      controller.add(_reviewsByRecipe[recipeId] ?? []);
    });

    // Store the subscription
    _reviewListeners[recipeId] = subscription;

    // Clean up on cancel
    controller.onCancel = () {
      subscription.cancel();
      _reviewListeners.remove(recipeId);
    };

    return controller.stream;
  }

  // Load reviews for a specific recipe (one-time load)
  Future<List<Review>> loadReviewsForRecipe(String recipeId) async {
    // Load from SQLite first
    await _loadReviewsFromSQLite(recipeId);

    // Then sync with Firebase
    await _loadReviewsFromFirebase(recipeId);

    return _reviewsByRecipe[recipeId] ?? [];
  }

  Future<void> _loadReviewsFromSQLite(String recipeId) async {
    if (_database == null) return;

    try {
      final List<Map<String, dynamic>> maps = await _database!.query(
        'reviews',
        where: 'recipeId = ?',
        whereArgs: [recipeId],
        orderBy: 'createdAt DESC',
      );

      final reviews = maps.map((map) => Review.fromJson(map)).toList();
      _reviewsByRecipe[recipeId] = reviews;
      print('Loaded ${reviews.length} reviews from SQLite for recipe $recipeId');
    } catch (e) {
      print('Error loading reviews from SQLite: $e');
      _reviewsByRecipe[recipeId] = [];
    }
  }

  Future<void> _loadReviewsFromFirebase(String recipeId) async {
    try {
      final querySnapshot = await _firestore
          .collection('reviews')
          .where('recipeId', isEqualTo: recipeId)
          .orderBy('createdAt', descending: true)
          .get();

      print('Found ${querySnapshot.docs.length} reviews in Firebase for recipe $recipeId');

      final firebaseReviews = querySnapshot.docs.map((doc) {
        final data = doc.data();
        return Review.fromJson({
          ...data,
          'firebaseId': doc.id,
        });
      }).toList();

      // Merge with SQLite reviews
      final existingReviews = _reviewsByRecipe[recipeId] ?? [];
      final updatedReviews = <Review>[];
      final processedIds = <String>{};

      // Add or update Firebase reviews
      for (final firebaseReview in firebaseReviews) {
        updatedReviews.add(firebaseReview);
        processedIds.add(firebaseReview.id);

        // Save to SQLite for offline access
        await _saveReviewToSQLite(firebaseReview);
      }

      // Add local-only reviews (not in Firebase)
      for (final localReview in existingReviews) {
        if (!processedIds.contains(localReview.id)) {
          updatedReviews.add(localReview);
        }
      }

      // Sort by creation date
      updatedReviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _reviewsByRecipe[recipeId] = updatedReviews;

    } catch (e) {
      print('Error loading reviews from Firebase: $e');
      // Continue with local data
    }
  }

  Future<void> _saveReviewToSQLite(Review review) async {
    if (_database == null) return;

    try {
      await _database!.insert(
        'reviews',
        review.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      print('Saved review ${review.id} to SQLite');
    } catch (e) {
      print('Error saving review to SQLite: $e');
    }
  }

  Future<void> _saveReviewToFirebase(Review review) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('No user logged in, cannot save review to Firebase');
        return;
      }

      if (review.firebaseId != null && review.firebaseId!.isNotEmpty) {
        // Update existing
        print('Updating review in Firebase: ${review.firebaseId}');
        await _firestore
            .collection('reviews')
            .doc(review.firebaseId)
            .update(review.toFirestore());
      } else {
        // Create new
        print('Creating new review in Firebase');
        final docRef = await _firestore
            .collection('reviews')
            .add(review.toFirestore());

        // Update local review with Firebase ID
        final updatedReview = review.copyWith(firebaseId: docRef.id);

        // Update in local cache
        final reviews = _reviewsByRecipe[review.recipeId] ?? [];
        final index = reviews.indexWhere((r) => r.id == review.id);
        if (index != -1) {
          reviews[index] = updatedReview;
          await _saveReviewToSQLite(updatedReview);
        }

        print('Created review in Firebase with ID: ${docRef.id}');
      }

      // Update recipe's average rating
      await _updateRecipeRating(review.recipeId);

    } catch (e) {
      print('Error saving review to Firebase: $e');
      // Don't throw - allow app to continue working offline
    }
  }

  // Add a new review
  Future<void> addReview({
    required String recipeId,
    required double rating,
    required String comment,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User must be logged in to add reviews');
    }

    final now = DateTime.now();
    final review = Review(
      id: now.millisecondsSinceEpoch.toString(),
      recipeId: recipeId,
      userId: user.uid,
      userName: user.displayName ?? user.email?.split('@')[0] ?? 'Anonymous',
      userEmail: user.email ?? '',
      rating: rating,
      comment: comment,
      createdAt: now,
      updatedAt: now,
    );

    // Add to local cache
    if (!_reviewsByRecipe.containsKey(recipeId)) {
      _reviewsByRecipe[recipeId] = [];
    }
    _reviewsByRecipe[recipeId]!.insert(0, review);

    // Save to both SQLite and Firebase
    await _saveReviewToSQLite(review);
    await _saveReviewToFirebase(review);
  }

  // Update a review
  Future<void> updateReview({
    required Review review,
    required double rating,
    required String comment,
  }) async {
    final user = _auth.currentUser;
    if (user == null || user.uid != review.userId) {
      throw Exception('You can only edit your own reviews');
    }

    final updatedReview = review.copyWith(
      rating: rating,
      comment: comment,
      updatedAt: DateTime.now(),
    );

    // Update in local cache
    final reviews = _reviewsByRecipe[review.recipeId] ?? [];
    final index = reviews.indexWhere((r) => r.id == review.id);
    if (index != -1) {
      reviews[index] = updatedReview;
    }

    // Update in both SQLite and Firebase
    await _saveReviewToSQLite(updatedReview);
    await _saveReviewToFirebase(updatedReview);
  }

  // Delete a review
  Future<void> deleteReview(Review review) async {
    final user = _auth.currentUser;
    if (user == null || user.uid != review.userId) {
      throw Exception('You can only delete your own reviews');
    }

    // Remove from local cache
    final reviews = _reviewsByRecipe[review.recipeId] ?? [];
    reviews.removeWhere((r) => r.id == review.id);

    // Delete from SQLite
    if (_database != null) {
      await _database!.delete(
        'reviews',
        where: 'id = ?',
        whereArgs: [review.id],
      );
      print('Deleted review from SQLite: ${review.id}');
    }

    // Delete from Firebase
    if (review.firebaseId != null) {
      try {
        await _firestore
            .collection('reviews')
            .doc(review.firebaseId)
            .delete();

        print('Deleted review from Firebase: ${review.firebaseId}');

        // Update recipe's average rating
        await _updateRecipeRating(review.recipeId);

      } catch (e) {
        print('Error deleting review from Firebase: $e');
        // Don't throw - allow app to continue working offline
      }
    }
  }

  // Get reviews for a recipe
  List<Review> getReviewsForRecipe(String recipeId) {
    return _reviewsByRecipe[recipeId] ?? [];
  }

  // Calculate average rating for a recipe
  double calculateAverageRating(String recipeId) {
    final reviews = _reviewsByRecipe[recipeId] ?? [];
    if (reviews.isEmpty) return 0.0;

    final total = reviews.fold<double>(0, (sum, review) => sum + review.rating);
    return total / reviews.length;
  }

  // Get rating statistics
  Map<String, dynamic> getRatingStatistics(String recipeId) {
    final reviews = _reviewsByRecipe[recipeId] ?? [];

    if (reviews.isEmpty) {
      return {
        'average': 0.0,
        'total': 0,
        'distribution': {1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
      };
    }

    final distribution = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    double total = 0;

    for (final review in reviews) {
      total += review.rating;
      distribution[review.rating.round()] = (distribution[review.rating.round()] ?? 0) + 1;
    }

    return {
      'average': total / reviews.length,
      'total': reviews.length,
      'distribution': distribution,
    };
  }

  // Check if user has already reviewed a recipe
  bool hasUserReviewed(String recipeId, String userId) {
    final reviews = _reviewsByRecipe[recipeId] ?? [];
    return reviews.any((review) => review.userId == userId);
  }

  // Get user's review for a recipe
  Review? getUserReview(String recipeId, String userId) {
    final reviews = _reviewsByRecipe[recipeId] ?? [];
    try {
      return reviews.firstWhere((review) => review.userId == userId);
    } catch (e) {
      return null;
    }
  }

  // Update recipe's average rating in Firestore
  Future<void> _updateRecipeRating(String recipeId) async {
    try {
      final stats = getRatingStatistics(recipeId);

      // Update recipe document with new average rating
      final recipeQuery = await _firestore
          .collection('recipes')
          .where('id', isEqualTo: recipeId)
          .limit(1)
          .get();

      if (recipeQuery.docs.isNotEmpty) {
        await recipeQuery.docs.first.reference.update({
          'averageRating': stats['average'],
          'totalRatings': stats['total'],
        });
        print('Updated recipe rating: avg=${stats['average']}, total=${stats['total']}');
      }

      // Also update in SQLite
      if (_database != null) {
        await _database!.update(
          'recipes',
          {
            'averageRating': stats['average'],
            'totalRatings': stats['total'],
          },
          where: 'id = ?',
          whereArgs: [recipeId],
        );
      }
    } catch (e) {
      print('Error updating recipe rating: $e');
    }
  }

  // Delete all reviews for a recipe (called when recipe is deleted)
  Future<void> deleteAllReviewsForRecipe(String recipeId) async {
    // Remove from cache
    _reviewsByRecipe.remove(recipeId);

    // Cancel any active listener
    _reviewListeners[recipeId]?.cancel();
    _reviewListeners.remove(recipeId);

    // Delete from SQLite
    if (_database != null) {
      await _database!.delete(
        'reviews',
        where: 'recipeId = ?',
        whereArgs: [recipeId],
      );
    }

    // Delete from Firebase
    try {
      final reviewsSnapshot = await _firestore
          .collection('reviews')
          .where('recipeId', isEqualTo: recipeId)
          .get();

      for (final doc in reviewsSnapshot.docs) {
        await doc.reference.delete();
      }
      print('Deleted ${reviewsSnapshot.docs.length} reviews for recipe $recipeId');
    } catch (e) {
      print('Error deleting reviews from Firebase: $e');
    }
  }

  // Clear cache for a recipe
  void clearCacheForRecipe(String recipeId) {
    _reviewsByRecipe.remove(recipeId);
    _reviewListeners[recipeId]?.cancel();
    _reviewListeners.remove(recipeId);
  }

  // Clear all cache
  void clearAllCache() {
    _reviewsByRecipe.clear();
    for (final subscription in _reviewListeners.values) {
      subscription?.cancel();
    }
    _reviewListeners.clear();
  }

  // Dispose method to clean up listeners
  void dispose() {
    for (final subscription in _reviewListeners.values) {
      subscription?.cancel();
    }
    _reviewListeners.clear();
  }
}