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
  final DateTime createdAt;
  final DateTime updatedAt;

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
    required this.createdAt,
    required this.updatedAt,
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
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
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
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
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
    DateTime? createdAt,
    DateTime? updatedAt,
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
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}