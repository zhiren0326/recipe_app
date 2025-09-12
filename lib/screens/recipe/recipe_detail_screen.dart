// screens/recipes/recipe_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:recipe_app/screens/recipe/recipe_type.dart';
import '../../services/recipe_service.dart';
import '../../utils/constants.dart';
import '../../utils/responsive_controller.dart';
import 'recipe_form_screen.dart';

class RecipeDetailScreen extends StatefulWidget {
  final String recipeId;

  const RecipeDetailScreen({
    Key? key,
    required this.recipeId,
  }) : super(key: key);

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  final RecipeService _recipeService = RecipeService();
  Recipe? _recipe;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecipe();
  }

  void _loadRecipe() {
    setState(() => _isLoading = true);
    final recipe = _recipeService.getRecipeById(widget.recipeId);
    setState(() {
      _recipe = recipe;
      _isLoading = false;
    });
  }

  Future<void> _editRecipe() async {
    if (_recipe == null) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecipeFormScreen(recipe: _recipe),
      ),
    );

    if (result == true) {
      _loadRecipe();
    }
  }

  Future<void> _deleteRecipe() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Recipe'),
        content: Text('Are you sure you want to delete this recipe?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.errorColor,
            ),
            child: Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _recipeService.deleteRecipe(widget.recipeId);
      if (mounted) {
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, deviceType, orientation) {
        if (_isLoading) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (_recipe == null) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(
              child: ResponsiveText(
                'Recipe not found',
                baseSize: 18,
                color: Colors.grey.shade600,
              ),
            ),
          );
        }

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              _buildSliverAppBar(),
              SliverToBoxAdapter(
                child: Padding(
                  padding: ResponsiveController.padding(all: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildRecipeInfo(),
                      ResponsiveSpacing(height: 24),
                      _buildDescription(),
                      ResponsiveSpacing(height: 24),
                      _buildIngredients(),
                      ResponsiveSpacing(height: 24),
                      _buildSteps(),
                      ResponsiveSpacing(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
          floatingActionButton: _buildFloatingActionButtons(),
        );
      },
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 250,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          _recipe!.name,
          style: TextStyle(
            fontSize: ResponsiveController.fontSize(18),
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                color: Colors.black54,
                blurRadius: 4,
              ),
            ],
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              _recipe!.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey.shade300,
                  child: Icon(
                    Icons.restaurant,
                    size: 60,
                    color: Colors.grey.shade500,
                  ),
                );
              },
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.edit),
          onPressed: _editRecipe,
        ),
        IconButton(
          icon: Icon(Icons.delete),
          onPressed: _deleteRecipe,
        ),
      ],
    );
  }

  Widget _buildRecipeInfo() {
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
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildInfoItem(
                  Icons.timer,
                  'Prep Time',
                  '${_recipe!.preparationTime} min',
                ),
                _buildInfoItem(
                  Icons.local_fire_department,
                  'Cook Time',
                  '${_recipe!.cookingTime} min',
                ),
                _buildInfoItem(
                  Icons.people,
                  'Servings',
                  _recipe!.servings.toString(),
                ),
              ],
            ),
            Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildInfoItem(
                  Icons.restaurant_menu,
                  'Category',
                  _recipe!.typeName,
                ),
                _buildInfoItem(
                  Icons.speed,
                  'Difficulty',
                  _recipe!.difficulty,
                ),
                _buildInfoItem(
                  Icons.star,
                  'Rating',
                  _recipe!.rating.toString(),
                  color: Colors.amber,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value, {Color? color}) {
    return Column(
      children: [
        Icon(
          icon,
          size: 24,
          color: color ?? AppColors.primaryColor,
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: ResponsiveController.fontSize(11),
            color: Colors.grey.shade600,
          ),
        ),
        SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: ResponsiveController.fontSize(14),
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildDescription() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ResponsiveText(
          'Description',
          baseSize: 18,
          fontWeight: FontWeight.bold,
        ),
        ResponsiveSpacing(height: 8),
        Text(
          _recipe!.description,
          style: TextStyle(
            fontSize: ResponsiveController.fontSize(14),
            color: Colors.grey.shade700,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildIngredients() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.shopping_cart, color: AppColors.primaryColor),
            SizedBox(width: 8),
            ResponsiveText(
              'Ingredients',
              baseSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ],
        ),
        ResponsiveSpacing(height: 12),
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              ResponsiveController.borderRadius(8),
            ),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: _recipe!.ingredients.length,
            separatorBuilder: (context, index) => Divider(height: 1),
            itemBuilder: (context, index) {
              return ListTile(
                leading: Container(
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
                title: Text(
                  _recipe!.ingredients[index],
                  style: TextStyle(
                    fontSize: ResponsiveController.fontSize(14),
                  ),
                ),
                contentPadding: ResponsiveController.padding(
                  horizontal: 16,
                  vertical: 8,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSteps() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.format_list_numbered, color: AppColors.primaryColor),
            SizedBox(width: 8),
            ResponsiveText(
              'Instructions',
              baseSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ],
        ),
        ResponsiveSpacing(height: 12),
        ...List.generate(_recipe!.steps.length, (index) {
          return Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        fontSize: ResponsiveController.fontSize(14),
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: ResponsiveController.padding(all: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(
                        ResponsiveController.borderRadius(8),
                      ),
                      border: Border.all(
                        color: Colors.grey.shade200,
                      ),
                    ),
                    child: Text(
                      _recipe!.steps[index],
                      style: TextStyle(
                        fontSize: ResponsiveController.fontSize(14),
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildFloatingActionButtons() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        FloatingActionButton(
          heroTag: 'edit',
          onPressed: _editRecipe,
          backgroundColor: AppColors.primaryColor,
          child: Icon(Icons.edit),
        ),
        SizedBox(height: 12),
        FloatingActionButton(
          heroTag: 'delete',
          onPressed: _deleteRecipe,
          backgroundColor: AppColors.errorColor,
          child: Icon(Icons.delete),
        ),
      ],
    );
  }
}