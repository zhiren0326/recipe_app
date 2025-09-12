// screens/recipes/recipe_form_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:recipe_app/screens/recipe/recipe_type.dart';
import '../../services/recipe_service.dart';
import '../../utils/constants.dart';
import '../../utils/responsive_controller.dart';

class RecipeFormScreen extends StatefulWidget {
  final Recipe? recipe;

  const RecipeFormScreen({
    Key? key,
    this.recipe,
  }) : super(key: key);

  @override
  State<RecipeFormScreen> createState() => _RecipeFormScreenState();
}

class _RecipeFormScreenState extends State<RecipeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final RecipeService _recipeService = RecipeService();

  // Form Controllers
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _imageUrlController;
  late TextEditingController _prepTimeController;
  late TextEditingController _cookTimeController;
  late TextEditingController _servingsController;

  // Lists for ingredients and steps
  List<TextEditingController> _ingredientControllers = [];
  List<TextEditingController> _stepControllers = [];

  // Selected values
  String? _selectedTypeId;
  String? _selectedTypeName;
  String _selectedDifficulty = 'Medium';
  double _rating = 4.0;

  List<RecipeType> _recipeTypes = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadRecipeTypes();
  }

  void _initializeControllers() {
    final recipe = widget.recipe;

    _nameController = TextEditingController(text: recipe?.name ?? '');
    _descriptionController = TextEditingController(text: recipe?.description ?? '');
    _imageUrlController = TextEditingController(text: recipe?.imageUrl ?? '');
    _prepTimeController = TextEditingController(text: recipe?.preparationTime.toString() ?? '');
    _cookTimeController = TextEditingController(text: recipe?.cookingTime.toString() ?? '');
    _servingsController = TextEditingController(text: recipe?.servings.toString() ?? '');

    if (recipe != null) {
      _selectedTypeId = recipe.typeId;
      _selectedTypeName = recipe.typeName;
      _selectedDifficulty = recipe.difficulty;
      _rating = recipe.rating;

      // Initialize ingredient controllers
      for (String ingredient in recipe.ingredients) {
        _ingredientControllers.add(TextEditingController(text: ingredient));
      }

      // Initialize step controllers
      for (String step in recipe.steps) {
        _stepControllers.add(TextEditingController(text: step));
      }
    } else {
      // Add one empty field for new recipe
      _ingredientControllers.add(TextEditingController());
      _stepControllers.add(TextEditingController());
    }
  }

  void _loadRecipeTypes() async {
    await _recipeService.initialize();
    setState(() {
      _recipeTypes = _recipeService.getRecipeTypes();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose();
    _prepTimeController.dispose();
    _cookTimeController.dispose();
    _servingsController.dispose();

    for (var controller in _ingredientControllers) {
      controller.dispose();
    }
    for (var controller in _stepControllers) {
      controller.dispose();
    }

    super.dispose();
  }

  void _addIngredient() {
    setState(() {
      _ingredientControllers.add(TextEditingController());
    });
  }

  void _removeIngredient(int index) {
    setState(() {
      _ingredientControllers[index].dispose();
      _ingredientControllers.removeAt(index);
    });
  }

  void _addStep() {
    setState(() {
      _stepControllers.add(TextEditingController());
    });
  }

  void _removeStep(int index) {
    setState(() {
      _stepControllers[index].dispose();
      _stepControllers.removeAt(index);
    });
  }

  Future<void> _saveRecipe() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedTypeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a recipe type')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Get non-empty ingredients and steps
      final ingredients = _ingredientControllers
          .map((c) => c.text.trim())
          .where((text) => text.isNotEmpty)
          .toList();

      final steps = _stepControllers
          .map((c) => c.text.trim())
          .where((text) => text.isNotEmpty)
          .toList();

      if (ingredients.isEmpty || steps.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please add at least one ingredient and one step')),
        );
        setState(() => _isLoading = false);
        return;
      }

      final now = DateTime.now();
      final recipe = Recipe(
        id: widget.recipe?.id ?? _recipeService.generateNewId(),
        name: _nameController.text.trim(),
        typeId: _selectedTypeId!,
        typeName: _selectedTypeName!,
        description: _descriptionController.text.trim(),
        imageUrl: _imageUrlController.text.trim().isEmpty
            ? 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=500'
            : _imageUrlController.text.trim(),
        ingredients: ingredients,
        steps: steps,
        preparationTime: int.tryParse(_prepTimeController.text) ?? 15,
        cookingTime: int.tryParse(_cookTimeController.text) ?? 30,
        servings: int.tryParse(_servingsController.text) ?? 4,
        difficulty: _selectedDifficulty,
        rating: _rating,
        createdAt: widget.recipe?.createdAt ?? now,
        updatedAt: now,
      );

      if (widget.recipe != null) {
        _recipeService.updateRecipe(recipe);
      } else {
        _recipeService.addRecipe(recipe);
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving recipe: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, deviceType, orientation) {
        return Scaffold(
          appBar: AppBar(
            title: ResponsiveText(
              widget.recipe != null ? 'Edit Recipe' : 'New Recipe',
              baseSize: 20,
              fontWeight: FontWeight.bold,
            ),
            actions: [
              TextButton.icon(
                onPressed: _isLoading ? null : _saveRecipe,
                icon: Icon(Icons.save, color: Colors.white),
                label: Text(
                  'Save',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          body: _isLoading
              ? Center(child: CircularProgressIndicator())
              : Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: ResponsiveController.padding(all: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBasicInfoSection(),
                  ResponsiveSpacing(height: 24),
                  _buildRecipeDetailsSection(),
                  ResponsiveSpacing(height: 24),
                  _buildIngredientsSection(),
                  ResponsiveSpacing(height: 24),
                  _buildStepsSection(),
                  ResponsiveSpacing(height: 32),
                  _buildSaveButton(),
                  ResponsiveSpacing(height: 32),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBasicInfoSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          ResponsiveController.borderRadius(12),
        ),
      ),
      child: Padding(
        padding: ResponsiveController.padding(all: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ResponsiveText(
              'Basic Information',
              baseSize: 18,
              fontWeight: FontWeight.bold,
            ),
            ResponsiveSpacing(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Recipe Name *',
                prefixIcon: Icon(Icons.restaurant_menu),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    ResponsiveController.borderRadius(8),
                  ),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter recipe name';
                }
                return null;
              },
            ),
            ResponsiveSpacing(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedTypeId,
              decoration: InputDecoration(
                labelText: 'Recipe Type *',
                prefixIcon: Icon(Icons.category),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    ResponsiveController.borderRadius(8),
                  ),
                ),
              ),
              items: _recipeTypes.map((type) {
                return DropdownMenuItem(
                  value: type.id,
                  child: Text(type.name),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedTypeId = value;
                  _selectedTypeName = _recipeTypes
                      .firstWhere((t) => t.id == value)
                      .name;
                });
              },
            ),
            ResponsiveSpacing(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Description *',
                prefixIcon: Icon(Icons.description),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    ResponsiveController.borderRadius(8),
                  ),
                ),
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter description';
                }
                return null;
              },
            ),
            ResponsiveSpacing(height: 16),
            TextFormField(
              controller: _imageUrlController,
              decoration: InputDecoration(
                labelText: 'Image URL (optional)',
                prefixIcon: Icon(Icons.image),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    ResponsiveController.borderRadius(8),
                  ),
                ),
                hintText: 'https://example.com/image.jpg',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecipeDetailsSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          ResponsiveController.borderRadius(12),
        ),
      ),
      child: Padding(
        padding: ResponsiveController.padding(all: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ResponsiveText(
              'Recipe Details',
              baseSize: 18,
              fontWeight: FontWeight.bold,
            ),
            ResponsiveSpacing(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _prepTimeController,
                    decoration: InputDecoration(
                      labelText: 'Prep Time (min)',
                      prefixIcon: Icon(Icons.timer),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          ResponsiveController.borderRadius(8),
                        ),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _cookTimeController,
                    decoration: InputDecoration(
                      labelText: 'Cook Time (min)',
                      prefixIcon: Icon(Icons.local_fire_department),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          ResponsiveController.borderRadius(8),
                        ),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                ),
              ],
            ),
            ResponsiveSpacing(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _servingsController,
                    decoration: InputDecoration(
                      labelText: 'Servings',
                      prefixIcon: Icon(Icons.people),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          ResponsiveController.borderRadius(8),
                        ),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedDifficulty,
                    decoration: InputDecoration(
                      labelText: 'Difficulty',
                      prefixIcon: Icon(Icons.speed),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          ResponsiveController.borderRadius(8),
                        ),
                      ),
                    ),
                    items: ['Easy', 'Medium', 'Hard'].map((difficulty) {
                      return DropdownMenuItem(
                        value: difficulty,
                        child: Text(difficulty),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedDifficulty = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
            ResponsiveSpacing(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.star, color: Colors.amber),
                    SizedBox(width: 8),
                    Text(
                      'Rating: ${_rating.toStringAsFixed(1)}',
                      style: TextStyle(
                        fontSize: ResponsiveController.fontSize(14),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _rating,
                  min: 1.0,
                  max: 5.0,
                  divisions: 8,
                  activeColor: Colors.amber,
                  onChanged: (value) {
                    setState(() {
                      _rating = value;
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIngredientsSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          ResponsiveController.borderRadius(12),
        ),
      ),
      child: Padding(
        padding: ResponsiveController.padding(all: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ResponsiveText(
                  'Ingredients',
                  baseSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                IconButton(
                  icon: Icon(Icons.add_circle, color: AppColors.primaryColor),
                  onPressed: _addIngredient,
                ),
              ],
            ),
            ResponsiveSpacing(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: _ingredientControllers.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              fontSize: ResponsiveController.fontSize(12),
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryColor,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _ingredientControllers[index],
                          decoration: InputDecoration(
                            hintText: 'Enter ingredient',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                ResponsiveController.borderRadius(8),
                              ),
                            ),
                            contentPadding: ResponsiveController.padding(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                        ),
                      ),
                      if (_ingredientControllers.length > 1)
                        IconButton(
                          icon: Icon(Icons.remove_circle, color: AppColors.errorColor),
                          onPressed: () => _removeIngredient(index),
                        ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepsSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          ResponsiveController.borderRadius(12),
        ),
      ),
      child: Padding(
        padding: ResponsiveController.padding(all: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ResponsiveText(
                  'Instructions',
                  baseSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                IconButton(
                  icon: Icon(Icons.add_circle, color: AppColors.primaryColor),
                  onPressed: _addStep,
                ),
              ],
            ),
            ResponsiveSpacing(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: _stepControllers.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              fontSize: ResponsiveController.fontSize(12),
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _stepControllers[index],
                          decoration: InputDecoration(
                            hintText: 'Enter step',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                ResponsiveController.borderRadius(8),
                              ),
                            ),
                            contentPadding: ResponsiveController.padding(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          maxLines: 2,
                        ),
                      ),
                      if (_stepControllers.length > 1)
                        IconButton(
                          icon: Icon(Icons.remove_circle, color: AppColors.errorColor),
                          onPressed: () => _removeStep(index),
                        ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _saveRecipe,
        icon: Icon(Icons.save),
        label: ResponsiveText(
          widget.recipe != null ? 'Update Recipe' : 'Create Recipe',
          baseSize: 16,
          fontWeight: FontWeight.bold,
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              ResponsiveController.borderRadius(8),
            ),
          ),
        ),
      ),
    );
  }
}