// screens/recipe/recipe_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:recipe_app/screens/recipe/recipe_type.dart';
import '../../services/recipe_service.dart';
import '../../services/auth_service.dart';
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
  final AuthService _authService = AuthService();
  Recipe? _recipe;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecipe();
  }

  Future<void> _loadRecipe() async {
    setState(() => _isLoading = true);

    try {
      await _recipeService.initialize();
      final recipe = _recipeService.getRecipeById(widget.recipeId);
      setState(() {
        _recipe = recipe;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading recipe: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _editRecipe() async {
    if (_recipe == null) return;

    final user = _authService.currentUser;
    if (user == null || _recipe!.createdBy != user.uid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You can only edit your own recipes'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

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
    if (_recipe == null) return;

    final user = _authService.currentUser;
    if (user == null || _recipe!.createdBy != user.uid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You can only delete your own recipes'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Recipe'),
        content: Text('Are you sure you want to delete "${_recipe!.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.errorColor,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _recipeService.deleteRecipe(widget.recipeId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Recipe deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting recipe: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
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
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (_recipe == null) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.restaurant_menu,
                    size: 80,
                    color: Colors.grey.shade400,
                  ),
                  ResponsiveSpacing(height: 16),
                  ResponsiveText(
                    'Recipe not found',
                    baseSize: 18,
                    color: Colors.grey.shade600,
                  ),
                  ResponsiveSpacing(height: 8),
                  ResponsiveText(
                    'This recipe may have been deleted or moved',
                    baseSize: 14,
                    color: Colors.grey.shade500,
                  ),
                ],
              ),
            ),
          );
        }

        final user = _authService.currentUser;
        final isOwner = user != null && _recipe!.createdBy == user.uid;

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              _buildSliverAppBar(isOwner),
              SliverToBoxAdapter(
                child: Padding(
                  padding: ResponsiveController.padding(all: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildCreatorInfo(),
                      ResponsiveSpacing(height: 16),
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
          floatingActionButton: isOwner ? _buildFloatingActionButtons() : null,
        );
      },
    );
  }

  Widget _buildSliverAppBar(bool isOwner) {
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
              const Shadow(
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
            if (isOwner)
              Positioned(
                top: 100,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    'Your Recipe',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      actions: [
        if (isOwner) ...[
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _editRecipe,
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _deleteRecipe,
          ),
        ],
      ],
    );
  }

  Widget _buildCreatorInfo() {
    return Card(
      elevation: 1,
      color: Colors.blue.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          ResponsiveController.borderRadius(8),
        ),
      ),
      child: Padding(
        padding: ResponsiveController.padding(all: 16),
        child: Row(
          children: [
            CircleAvatar(
              radius: ResponsiveController.iconSize(20),
              backgroundColor: AppColors.primaryColor,
              child: Icon(
                Icons.person,
                size: ResponsiveController.iconSize(20),
                color: Colors.white,
              ),
            ),
            ResponsiveSpacing(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ResponsiveText(
                    'Recipe by ${_recipe!.createdByName}',
                    baseSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  ResponsiveText(
                    'Created ${_recipe!.formattedCreatedDate}',
                    baseSize: 12,
                    color: Colors.grey[600],
                  ),
                ],
              ),
            ),
            if (_recipe!.updatedAt != _recipe!.createdAt)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Updated',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ),
          ],
        ),
      ),
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
            const Divider(height: 24),
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
          size: ResponsiveController.iconSize(24),
          color: color ?? AppColors.primaryColor,
        ),
        ResponsiveSpacing(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: ResponsiveController.fontSize(11),
            color: Colors.grey.shade600,
          ),
        ),
        ResponsiveSpacing(height: 2),
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
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              ResponsiveController.borderRadius(8),
            ),
          ),
          child: Padding(
            padding: ResponsiveController.padding(all: 16),
            child: Text(
              _recipe!.description,
              style: TextStyle(
                fontSize: ResponsiveController.fontSize(14),
                color: Colors.grey.shade700,
                height: 1.5,
              ),
            ),
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
            ResponsiveSpacing(width: 8),
            ResponsiveText(
              'Ingredients (${_recipe!.ingredients.length})',
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
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _recipe!.ingredients.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
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
            ResponsiveSpacing(width: 8),
            ResponsiveText(
              'Instructions (${_recipe!.steps.length} steps)',
              baseSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ],
        ),
        ResponsiveSpacing(height: 12),
        ...List.generate(_recipe!.steps.length, (index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
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
                ResponsiveSpacing(width: 12),
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
          child: const Icon(Icons.edit),
        ),
        ResponsiveSpacing(height: 12),
        FloatingActionButton(
          heroTag: 'delete',
          onPressed: _deleteRecipe,
          backgroundColor: AppColors.errorColor,
          child: const Icon(Icons.delete),
        ),
      ],
    );
  }
}