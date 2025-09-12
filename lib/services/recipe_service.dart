// services/recipe_service.dart
import 'dart:convert';
import 'package:flutter/services.dart';
import '../screens/recipe/recipe_type.dart';

class RecipeService {
  static final RecipeService _instance = RecipeService._internal();
  factory RecipeService() => _instance;
  RecipeService._internal();

  List<Recipe> _recipes = [];
  List<RecipeType> _recipeTypes = [];

  Future<void> initialize() async {
    await loadRecipeTypes();
    _initializeSampleRecipes();
  }

  Future<void> loadRecipeTypes() async {
    try {
      final String jsonString = await rootBundle.loadString('assets/data/recipetypes.json');
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      _recipeTypes = (jsonData['recipeTypes'] as List)
          .map((item) => RecipeType.fromJson(item))
          .toList();
    } catch (e) {
      print('Error loading recipe types: $e');
    }
  }

  void _initializeSampleRecipes() {
    _recipes = [
      // Appetizers
      Recipe(
        id: '1',
        name: 'Bruschetta',
        typeId: '1',
        typeName: 'Appetizers',
        description: 'Classic Italian appetizer with fresh tomatoes, basil, and garlic on toasted bread',
        imageUrl: 'https://images.unsplash.com/photo-1572695157366-5e585ab2b69f?w=500',
        ingredients: [
          '6 ripe tomatoes, diced',
          '1 baguette, sliced',
          '3 cloves garlic, minced',
          '1/4 cup fresh basil, chopped',
          '3 tbsp olive oil',
          'Salt and pepper to taste',
          '1 tbsp balsamic vinegar',
        ],
        steps: [
          'Preheat oven to 400°F (200°C)',
          'Slice baguette into 1/2 inch thick slices',
          'Brush bread slices with olive oil and toast for 5-7 minutes',
          'Mix diced tomatoes, garlic, basil, remaining olive oil, and balsamic vinegar',
          'Season with salt and pepper',
          'Top toasted bread with tomato mixture',
          'Serve immediately',
        ],
        preparationTime: 15,
        cookingTime: 10,
        servings: 6,
        difficulty: 'Easy',
        rating: 4.5,
        createdAt: DateTime.now().subtract(Duration(days: 30)),
        updatedAt: DateTime.now().subtract(Duration(days: 2)),
      ),
      Recipe(
        id: '2',
        name: 'Spinach and Artichoke Dip',
        typeId: '1',
        typeName: 'Appetizers',
        description: 'Creamy, cheesy dip perfect for parties',
        imageUrl: 'https://images.unsplash.com/photo-1536304993881-ff6e9eefa2a6?w=500',
        ingredients: [
          '1 package frozen spinach, thawed and drained',
          '1 can artichoke hearts, chopped',
          '8 oz cream cheese, softened',
          '1/2 cup sour cream',
          '1/4 cup mayonnaise',
          '1 cup mozzarella cheese, shredded',
          '1/2 cup parmesan cheese, grated',
          '3 cloves garlic, minced',
        ],
        steps: [
          'Preheat oven to 350°F (175°C)',
          'Mix cream cheese, sour cream, and mayonnaise until smooth',
          'Add spinach, artichokes, garlic, and half of each cheese',
          'Transfer to baking dish',
          'Top with remaining cheese',
          'Bake for 25-30 minutes until bubbly',
          'Serve with tortilla chips or bread',
        ],
        preparationTime: 15,
        cookingTime: 30,
        servings: 8,
        difficulty: 'Easy',
        rating: 4.7,
        createdAt: DateTime.now().subtract(Duration(days: 25)),
        updatedAt: DateTime.now().subtract(Duration(days: 1)),
      ),

      // Main Courses
      Recipe(
        id: '3',
        name: 'Grilled Salmon with Lemon Butter',
        typeId: '2',
        typeName: 'Main Course',
        description: 'Perfectly grilled salmon with a zesty lemon butter sauce',
        imageUrl: 'https://images.unsplash.com/photo-1467003909585-2f8a72700288?w=500',
        ingredients: [
          '4 salmon fillets (6 oz each)',
          '4 tbsp butter',
          '2 lemons (juice and zest)',
          '3 cloves garlic, minced',
          '2 tbsp fresh dill',
          'Salt and black pepper',
          '1 tbsp olive oil',
          'Lemon wedges for serving',
        ],
        steps: [
          'Pat salmon dry and season with salt and pepper',
          'Heat grill to medium-high heat',
          'Brush salmon with olive oil',
          'Grill salmon for 4-5 minutes per side',
          'Meanwhile, melt butter in a pan',
          'Add garlic, lemon juice, and zest to butter',
          'Remove salmon from grill',
          'Drizzle with lemon butter sauce and garnish with dill',
        ],
        preparationTime: 10,
        cookingTime: 15,
        servings: 4,
        difficulty: 'Medium',
        rating: 4.8,
        createdAt: DateTime.now().subtract(Duration(days: 20)),
        updatedAt: DateTime.now().subtract(Duration(days: 3)),
      ),
      Recipe(
        id: '4',
        name: 'Chicken Marsala',
        typeId: '2',
        typeName: 'Main Course',
        description: 'Italian-American dish with tender chicken in rich marsala wine sauce',
        imageUrl: 'https://images.unsplash.com/photo-1604908176997-125f25cc6f3d?w=500',
        ingredients: [
          '4 chicken breasts, pounded thin',
          '1 cup all-purpose flour',
          '8 oz mushrooms, sliced',
          '3/4 cup Marsala wine',
          '3/4 cup chicken broth',
          '4 tbsp butter',
          '2 tbsp olive oil',
          '2 cloves garlic, minced',
          'Fresh parsley for garnish',
        ],
        steps: [
          'Dredge chicken in flour, shaking off excess',
          'Heat oil and 2 tbsp butter in large skillet',
          'Cook chicken 3-4 minutes per side until golden',
          'Remove chicken and set aside',
          'Add mushrooms and garlic to pan, sauté 5 minutes',
          'Add Marsala wine and broth, simmer 10 minutes',
          'Stir in remaining butter',
          'Return chicken to pan, coat with sauce',
          'Garnish with parsley and serve',
        ],
        preparationTime: 20,
        cookingTime: 25,
        servings: 4,
        difficulty: 'Medium',
        rating: 4.6,
        createdAt: DateTime.now().subtract(Duration(days: 15)),
        updatedAt: DateTime.now(),
      ),

      // Desserts
      Recipe(
        id: '5',
        name: 'Chocolate Lava Cake',
        typeId: '3',
        typeName: 'Desserts',
        description: 'Decadent chocolate cake with molten center',
        imageUrl: 'https://images.unsplash.com/photo-1624353365286-3f8d62daad51?w=500',
        ingredients: [
          '4 oz dark chocolate, chopped',
          '4 tbsp butter',
          '2 eggs',
          '2 tbsp sugar',
          '2 tbsp all-purpose flour',
          '1/4 tsp vanilla extract',
          'Pinch of salt',
          'Powdered sugar for dusting',
          'Ice cream for serving',
        ],
        steps: [
          'Preheat oven to 425°F (220°C)',
          'Grease 2 ramekins with butter',
          'Melt chocolate and butter together',
          'Whisk eggs and sugar until thick',
          'Add chocolate mixture to eggs',
          'Fold in flour and salt',
          'Divide batter between ramekins',
          'Bake for 12-14 minutes',
          'Let cool 1 minute, then invert onto plates',
          'Dust with powdered sugar and serve with ice cream',
        ],
        preparationTime: 10,
        cookingTime: 14,
        servings: 2,
        difficulty: 'Medium',
        rating: 4.9,
        createdAt: DateTime.now().subtract(Duration(days: 10)),
        updatedAt: DateTime.now(),
      ),
      Recipe(
        id: '6',
        name: 'Tiramisu',
        typeId: '3',
        typeName: 'Desserts',
        description: 'Classic Italian coffee-flavored dessert',
        imageUrl: 'https://images.unsplash.com/photo-1571877227200-a0d98ea607e9?w=500',
        ingredients: [
          '6 egg yolks',
          '3/4 cup sugar',
          '1 1/3 cups mascarpone cheese',
          '1 3/4 cups heavy cream',
          '2 cups strong espresso, cooled',
          '1/2 cup coffee liqueur',
          '2 packages ladyfinger cookies',
          'Cocoa powder for dusting',
        ],
        steps: [
          'Whisk egg yolks and sugar until thick and pale',
          'Add mascarpone to yolk mixture and beat until smooth',
          'Whip cream to stiff peaks',
          'Fold whipped cream into mascarpone mixture',
          'Combine espresso and coffee liqueur',
          'Dip ladyfingers in coffee mixture',
          'Arrange in dish and spread half of mascarpone mixture',
          'Repeat layers',
          'Refrigerate for 4 hours',
          'Dust with cocoa before serving',
        ],
        preparationTime: 30,
        cookingTime: 0,
        servings: 8,
        difficulty: 'Medium',
        rating: 4.8,
        createdAt: DateTime.now().subtract(Duration(days: 8)),
        updatedAt: DateTime.now(),
      ),

      // Beverages
      Recipe(
        id: '7',
        name: 'Mango Lassi',
        typeId: '4',
        typeName: 'Beverages',
        description: 'Refreshing Indian yogurt-based mango drink',
        imageUrl: 'https://images.unsplash.com/photo-1623065422902-30a2d299bbe4?w=500',
        ingredients: [
          '1 cup ripe mango, chopped',
          '1/2 cup plain yogurt',
          '1/2 cup milk',
          '2 tbsp sugar',
          '1/4 tsp cardamom powder',
          'Ice cubes',
          'Mint leaves for garnish',
        ],
        steps: [
          'Add mango pieces to blender',
          'Add yogurt, milk, and sugar',
          'Add cardamom powder',
          'Blend until smooth and creamy',
          'Add ice cubes and blend again',
          'Pour into glasses',
          'Garnish with mint leaves',
        ],
        preparationTime: 5,
        cookingTime: 0,
        servings: 2,
        difficulty: 'Easy',
        rating: 4.7,
        createdAt: DateTime.now().subtract(Duration(days: 5)),
        updatedAt: DateTime.now(),
      ),

      // Breakfast
      Recipe(
        id: '8',
        name: 'Fluffy Pancakes',
        typeId: '5',
        typeName: 'Breakfast',
        description: 'Light and fluffy buttermilk pancakes',
        imageUrl: 'https://images.unsplash.com/photo-1567620905732-2d1ec7ab7445?w=500',
        ingredients: [
          '2 cups all-purpose flour',
          '2 tbsp sugar',
          '2 tsp baking powder',
          '1 tsp baking soda',
          '1/2 tsp salt',
          '2 cups buttermilk',
          '2 eggs',
          '1/4 cup melted butter',
          'Maple syrup for serving',
          'Fresh berries for topping',
        ],
        steps: [
          'Mix flour, sugar, baking powder, baking soda, and salt',
          'In another bowl, whisk buttermilk, eggs, and melted butter',
          'Add wet ingredients to dry ingredients',
          'Mix until just combined (lumps are okay)',
          'Heat griddle over medium heat',
          'Pour 1/4 cup batter for each pancake',
          'Cook until bubbles form and edges look dry',
          'Flip and cook until golden brown',
          'Serve with maple syrup and berries',
        ],
        preparationTime: 10,
        cookingTime: 20,
        servings: 4,
        difficulty: 'Easy',
        rating: 4.6,
        createdAt: DateTime.now().subtract(Duration(days: 12)),
        updatedAt: DateTime.now(),
      ),
      Recipe(
        id: '9',
        name: 'Eggs Benedict',
        typeId: '5',
        typeName: 'Breakfast',
        description: 'Classic breakfast with poached eggs and hollandaise sauce',
        imageUrl: 'https://images.unsplash.com/photo-1608039829572-78524f79c4c7?w=500',
        ingredients: [
          '4 English muffins, halved',
          '8 slices Canadian bacon',
          '8 eggs',
          '3 egg yolks (for sauce)',
          '1/2 cup butter, melted',
          '1 tbsp lemon juice',
          '1 tsp white vinegar',
          'Cayenne pepper',
          'Salt to taste',
        ],
        steps: [
          'Make hollandaise: Whisk egg yolks with lemon juice',
          'Slowly add melted butter while whisking',
          'Season with salt and cayenne',
          'Keep sauce warm',
          'Bring pot of water to simmer, add vinegar',
          'Crack eggs into water, poach 3-4 minutes',
          'Toast English muffins',
          'Cook Canadian bacon until warm',
          'Assemble: muffin, bacon, egg, hollandaise',
          'Serve immediately',
        ],
        preparationTime: 15,
        cookingTime: 20,
        servings: 4,
        difficulty: 'Hard',
        rating: 4.8,
        createdAt: DateTime.now().subtract(Duration(days: 7)),
        updatedAt: DateTime.now(),
      ),

      // Salads
      Recipe(
        id: '10',
        name: 'Caesar Salad',
        typeId: '6',
        typeName: 'Salads',
        description: 'Classic Caesar salad with homemade dressing and croutons',
        imageUrl: 'https://images.unsplash.com/photo-1550304943-4f24f54ddde9?w=500',
        ingredients: [
          '2 romaine lettuce hearts, chopped',
          '1 cup croutons',
          '1/2 cup parmesan cheese, shaved',
          '2 cloves garlic, minced',
          '2 anchovy fillets',
          '1 egg yolk',
          '2 tbsp lemon juice',
          '1/2 cup olive oil',
          '1 tsp Dijon mustard',
          'Black pepper',
        ],
        steps: [
          'Make dressing: Mash garlic and anchovies',
          'Whisk in egg yolk, lemon juice, and mustard',
          'Slowly add olive oil while whisking',
          'Season with black pepper',
          'Wash and dry lettuce',
          'Toss lettuce with dressing',
          'Add croutons and half the parmesan',
          'Top with remaining parmesan',
          'Serve immediately',
        ],
        preparationTime: 15,
        cookingTime: 0,
        servings: 4,
        difficulty: 'Easy',
        rating: 4.5,
        createdAt: DateTime.now().subtract(Duration(days: 9)),
        updatedAt: DateTime.now(),
      ),

      // Soups
      Recipe(
        id: '11',
        name: 'Tomato Basil Soup',
        typeId: '7',
        typeName: 'Soups',
        description: 'Creamy tomato soup with fresh basil',
        imageUrl: 'https://images.unsplash.com/photo-1547592166-23ac45744acd?w=500',
        ingredients: [
          '2 cans crushed tomatoes',
          '1 onion, diced',
          '4 cloves garlic, minced',
          '2 cups vegetable broth',
          '1 cup heavy cream',
          '1/4 cup fresh basil',
          '2 tbsp olive oil',
          '1 tbsp sugar',
          'Salt and pepper',
        ],
        steps: [
          'Heat olive oil in large pot',
          'Sauté onion until translucent',
          'Add garlic, cook 1 minute',
          'Add crushed tomatoes and broth',
          'Simmer for 20 minutes',
          'Add basil and sugar',
          'Blend soup until smooth',
          'Stir in cream',
          'Season with salt and pepper',
          'Serve hot with crusty bread',
        ],
        preparationTime: 10,
        cookingTime: 30,
        servings: 6,
        difficulty: 'Easy',
        rating: 4.6,
        createdAt: DateTime.now().subtract(Duration(days: 6)),
        updatedAt: DateTime.now(),
      ),

      // Snacks
      Recipe(
        id: '12',
        name: 'Loaded Nachos',
        typeId: '8',
        typeName: 'Snacks',
        description: 'Crispy tortilla chips loaded with cheese and toppings',
        imageUrl: 'https://images.unsplash.com/photo-1582169296194-e4d644c48063?w=500',
        ingredients: [
          '1 bag tortilla chips',
          '2 cups cheddar cheese, shredded',
          '1 cup black beans, cooked',
          '1 cup ground beef, cooked',
          '1 jalapeño, sliced',
          '1/2 cup sour cream',
          '1/2 cup guacamole',
          '1/4 cup green onions, chopped',
          'Salsa for serving',
        ],
        steps: [
          'Preheat oven to 350°F (175°C)',
          'Spread chips on baking sheet',
          'Layer with cheese, beans, and beef',
          'Add jalapeño slices',
          'Bake for 10-15 minutes until cheese melts',
          'Top with sour cream and guacamole',
          'Sprinkle with green onions',
          'Serve with salsa',
        ],
        preparationTime: 10,
        cookingTime: 15,
        servings: 4,
        difficulty: 'Easy',
        rating: 4.4,
        createdAt: DateTime.now().subtract(Duration(days: 4)),
        updatedAt: DateTime.now(),
      ),

      // Pasta
      Recipe(
        id: '13',
        name: 'Spaghetti Carbonara',
        typeId: '9',
        typeName: 'Pasta',
        description: 'Authentic Italian pasta with eggs, cheese, and pancetta',
        imageUrl: 'https://images.unsplash.com/photo-1612874742237-6526221588e3?w=500',
        ingredients: [
          '1 lb spaghetti',
          '4 oz pancetta, diced',
          '4 egg yolks',
          '1 whole egg',
          '1 cup Pecorino Romano, grated',
          '2 cloves garlic',
          'Black pepper',
          'Salt for pasta water',
        ],
        steps: [
          'Bring large pot of salted water to boil',
          'Cook spaghetti according to package',
          'Meanwhile, cook pancetta until crispy',
          'Add garlic to pancetta, cook 1 minute',
          'Whisk eggs and cheese together',
          'Reserve 1 cup pasta water before draining',
          'Add hot pasta to pancetta',
          'Remove from heat',
          'Add egg mixture, toss quickly',
          'Add pasta water to achieve creamy consistency',
          'Season with black pepper and serve',
        ],
        preparationTime: 10,
        cookingTime: 20,
        servings: 4,
        difficulty: 'Medium',
        rating: 4.7,
        createdAt: DateTime.now().subtract(Duration(days: 11)),
        updatedAt: DateTime.now(),
      ),

      // Seafood
      Recipe(
        id: '14',
        name: 'Garlic Butter Shrimp',
        typeId: '10',
        typeName: 'Seafood',
        description: 'Succulent shrimp in garlic butter sauce',
        imageUrl: 'https://images.unsplash.com/photo-1565680018434-b513d5e5fd47?w=500',
        ingredients: [
          '1 lb large shrimp, peeled',
          '4 tbsp butter',
          '4 cloves garlic, minced',
          '1/4 cup white wine',
          '2 tbsp lemon juice',
          '1/4 cup parsley, chopped',
          'Red pepper flakes',
          'Salt and pepper',
        ],
        steps: [
          'Pat shrimp dry and season with salt and pepper',
          'Heat 2 tbsp butter in large skillet',
          'Cook shrimp 2 minutes per side',
          'Remove shrimp from pan',
          'Add remaining butter and garlic',
          'Cook garlic 30 seconds',
          'Add wine and lemon juice',
          'Return shrimp to pan',
          'Toss with parsley and red pepper flakes',
          'Serve over rice or pasta',
        ],
        preparationTime: 10,
        cookingTime: 10,
        servings: 4,
        difficulty: 'Easy',
        rating: 4.6,
        createdAt: DateTime.now().subtract(Duration(days: 13)),
        updatedAt: DateTime.now(),
      ),

      // Vegetarian
      Recipe(
        id: '15',
        name: 'Vegetable Stir Fry',
        typeId: '11',
        typeName: 'Vegetarian',
        description: 'Colorful vegetables in savory Asian sauce',
        imageUrl: 'https://images.unsplash.com/photo-1609501676725-7186f017a4b7?w=500',
        ingredients: [
          '2 cups broccoli florets',
          '1 bell pepper, sliced',
          '1 carrot, julienned',
          '1 cup snap peas',
          '8 oz mushrooms, sliced',
          '3 tbsp soy sauce',
          '1 tbsp sesame oil',
          '2 tbsp vegetable oil',
          '2 cloves garlic, minced',
          '1 tbsp ginger, minced',
          '1 tbsp cornstarch',
          'Sesame seeds for garnish',
        ],
        steps: [
          'Mix soy sauce, sesame oil, and cornstarch',
          'Heat wok or large skillet over high heat',
          'Add vegetable oil',
          'Stir fry garlic and ginger 30 seconds',
          'Add broccoli and carrot, cook 2 minutes',
          'Add bell pepper and mushrooms, cook 2 minutes',
          'Add snap peas, cook 1 minute',
          'Pour sauce over vegetables',
          'Toss until sauce thickens',
          'Garnish with sesame seeds',
        ],
        preparationTime: 15,
        cookingTime: 10,
        servings: 4,
        difficulty: 'Easy',
        rating: 4.5,
        createdAt: DateTime.now().subtract(Duration(days: 14)),
        updatedAt: DateTime.now(),
      ),

      // BBQ & Grill
      Recipe(
        id: '16',
        name: 'BBQ Ribs',
        typeId: '12',
        typeName: 'BBQ & Grill',
        description: 'Fall-off-the-bone tender ribs with homemade BBQ sauce',
        imageUrl: 'https://images.unsplash.com/photo-1529193591184-b1d58069ecdd?w=500',
        ingredients: [
          '2 racks baby back ribs',
          '1/4 cup brown sugar',
          '2 tbsp paprika',
          '1 tbsp black pepper',
          '1 tbsp salt',
          '1 tbsp chili powder',
          '1 tsp garlic powder',
          '1 tsp onion powder',
          '1 tsp cayenne pepper',
          '2 cups BBQ sauce',
        ],
        steps: [
          'Remove membrane from ribs',
          'Mix all dry spices for rub',
          'Coat ribs with spice rub',
          'Wrap in foil and refrigerate 2 hours',
          'Preheat oven to 275°F (135°C)',
          'Bake wrapped ribs for 2.5 hours',
          'Remove foil, brush with BBQ sauce',
          'Increase heat to 350°F (175°C)',
          'Bake uncovered 30 minutes, basting with sauce',
          'Let rest 10 minutes before cutting',
        ],
        preparationTime: 20,
        cookingTime: 180,
        servings: 4,
        difficulty: 'Medium',
        rating: 4.8,
        createdAt: DateTime.now().subtract(Duration(days: 16)),
        updatedAt: DateTime.now(),
      ),
    ];
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

  void addRecipe(Recipe recipe) {
    _recipes.add(recipe);
  }

  void updateRecipe(Recipe updatedRecipe) {
    final index = _recipes.indexWhere((recipe) => recipe.id == updatedRecipe.id);
    if (index != -1) {
      _recipes[index] = updatedRecipe;
    }
  }

  void deleteRecipe(String id) {
    _recipes.removeWhere((recipe) => recipe.id == id);
  }

  String generateNewId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }
}