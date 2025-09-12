// models/recipe_type.dart
class RecipeType {
  final String id;
  final String name;
  final String icon;
  final String color;
  final String description;

  RecipeType({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.description,
  });

  factory RecipeType.fromJson(Map<String, dynamic> json) {
    return RecipeType(
      id: json['id'],
      name: json['name'],
      icon: json['icon'],
      color: json['color'],
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'color': color,
      'description': description,
    };
  }
}

// models/recipe.dart
class Recipe {
  final String id;
  final String name;
  final String typeId;
  final String typeName;
  final String description;
  final String imageUrl;
  final List<String> ingredients;
  final List<String> steps;
  final int preparationTime; // in minutes
  final int cookingTime; // in minutes
  final int servings;
  final String difficulty; // Easy, Medium, Hard
  final double rating;
  final String createdBy; // User UID
  final String createdByName; // User display name or email
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? firebaseId; // Firebase document ID

  Recipe({
    required this.id,
    required this.name,
    required this.typeId,
    required this.typeName,
    required this.description,
    required this.imageUrl,
    required this.ingredients,
    required this.steps,
    required this.preparationTime,
    required this.cookingTime,
    required this.servings,
    required this.difficulty,
    required this.rating,
    required this.createdBy,
    required this.createdByName,
    required this.createdAt,
    required this.updatedAt,
    this.firebaseId,
  });

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      id: json['id'],
      name: json['name'],
      typeId: json['typeId'],
      typeName: json['typeName'],
      description: json['description'],
      imageUrl: json['imageUrl'],
      ingredients: List<String>.from(json['ingredients']),
      steps: List<String>.from(json['steps']),
      preparationTime: json['preparationTime'],
      cookingTime: json['cookingTime'],
      servings: json['servings'],
      difficulty: json['difficulty'],
      rating: json['rating'].toDouble(),
      createdBy: json['createdBy'] ?? '',
      createdByName: json['createdByName'] ?? 'Unknown User',
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      firebaseId: json['firebaseId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'typeId': typeId,
      'typeName': typeName,
      'description': description,
      'imageUrl': imageUrl,
      'ingredients': ingredients,
      'steps': steps,
      'preparationTime': preparationTime,
      'cookingTime': cookingTime,
      'servings': servings,
      'difficulty': difficulty,
      'rating': rating,
      'createdBy': createdBy,
      'createdByName': createdByName,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      if (firebaseId != null) 'firebaseId': firebaseId,
    };
  }

  Recipe copyWith({
    String? id,
    String? name,
    String? typeId,
    String? typeName,
    String? description,
    String? imageUrl,
    List<String>? ingredients,
    List<String>? steps,
    int? preparationTime,
    int? cookingTime,
    int? servings,
    String? difficulty,
    double? rating,
    String? createdBy,
    String? createdByName,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? firebaseId,
  }) {
    return Recipe(
      id: id ?? this.id,
      name: name ?? this.name,
      typeId: typeId ?? this.typeId,
      typeName: typeName ?? this.typeName,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      ingredients: ingredients ?? this.ingredients,
      steps: steps ?? this.steps,
      preparationTime: preparationTime ?? this.preparationTime,
      cookingTime: cookingTime ?? this.cookingTime,
      servings: servings ?? this.servings,
      difficulty: difficulty ?? this.difficulty,
      rating: rating ?? this.rating,
      createdBy: createdBy ?? this.createdBy,
      createdByName: createdByName ?? this.createdByName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      firebaseId: firebaseId ?? this.firebaseId,
    );
  }

  // Helper methods
  bool get isOwnedByCurrentUser {
    // This would need to be checked against current user
    return true; // Implementation depends on how you handle current user
  }

  String get formattedCreatedDate {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 30) {
      return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else {
      return 'Just now';
    }
  }

  int get totalTime => preparationTime + cookingTime;
}