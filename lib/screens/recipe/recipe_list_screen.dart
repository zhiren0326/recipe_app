// screens/recipe/recipe_list_screen.dart
import 'package:flutter/material.dart';
import 'package:recipe_app/screens/recipe/recipe_detail_screen.dart';
import 'package:recipe_app/screens/recipe/recipe_form_screen.dart';
import 'package:recipe_app/screens/recipe/recipe_type.dart';

import '../../services/recipe_service.dart';
import '../../services/auth_service.dart';
import '../../utils/constants.dart';
import '../../utils/responsive_controller.dart';

class RecipeListScreen extends StatefulWidget {
  const RecipeListScreen({Key? key}) : super(key: key);

  @override
  State<RecipeListScreen> createState() => _RecipeListScreenState();
}

class _RecipeListScreenState extends State<RecipeListScreen> {
  final RecipeService _recipeService = RecipeService();
  final AuthService _authService = AuthService();
  List<Recipe> _recipes = [];
  List<Recipe> _filteredRecipes = [];
  List<RecipeType> _recipeTypes = [];
  String _selectedTypeId = 'all';
  String _searchQuery = '';
  bool _isLoading = true;
  bool _showOnlyMyRecipes = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      await _recipeService.initialize();
      await _recipeService.syncWithFirebase();

      setState(() {
        _recipeTypes = _recipeService.getRecipeTypes();
        _loadRecipes();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _loadRecipes() {
    if (_showOnlyMyRecipes) {
      _recipes = _recipeService.getUserRecipes();
    } else {
      _recipes = _recipeService.getAllRecipes();
    }
    _filterRecipes();
  }

  void _filterRecipes() {
    setState(() {
      _filteredRecipes = _recipes.where((recipe) {
        final matchesType = _selectedTypeId == 'all' || recipe.typeId == _selectedTypeId;
        final matchesSearch = _searchQuery.isEmpty ||
            recipe.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            recipe.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            recipe.createdByName.toLowerCase().contains(_searchQuery.toLowerCase());
        return matchesType && matchesSearch;
      }).toList();

      // Sort by creation date (newest first)
      _filteredRecipes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    });
  }

  void _onTypeChanged(String? typeId) {
    if (typeId != null) {
      setState(() {
        _selectedTypeId = typeId;
        _filterRecipes();
      });
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      _filterRecipes();
    });
  }

  void _toggleRecipeView() {
    setState(() {
      _showOnlyMyRecipes = !_showOnlyMyRecipes;
      _loadRecipes();
    });
  }

  Future<void> _navigateToRecipeForm({Recipe? recipe}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecipeFormScreen(recipe: recipe),
      ),
    );
    if (result == true) {
      _loadData();
    }
  }

  Future<void> _navigateToRecipeDetail(Recipe recipe) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecipeDetailScreen(recipeId: recipe.id),
      ),
    );
    if (result == true) {
      _loadData();
    }
  }

  Future<void> _deleteRecipe(Recipe recipe) async {
    final user = _authService.currentUser;
    if (user == null || recipe.createdBy != user.uid) {
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
        content: Text('Are you sure you want to delete "${recipe.name}"?'),
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
        await _recipeService.deleteRecipe(recipe.id);
        _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Recipe deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
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
        return Scaffold(
          appBar: AppBar(
            title: Text(
              _showOnlyMyRecipes ? 'My Recipes' : 'All Recipes',
              style: TextStyle(
                fontSize: ResponsiveController.fontSize(20),
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  _showOnlyMyRecipes ? Icons.person : Icons.public,
                  size: ResponsiveController.iconSize(24),
                ),
                onPressed: _toggleRecipeView,
                tooltip: _showOnlyMyRecipes ? 'Show All Recipes' : 'Show My Recipes',
              ),
              IconButton(
                icon: Icon(
                  Icons.add,
                  size: ResponsiveController.iconSize(24),
                ),
                onPressed: () => _navigateToRecipeForm(),
              ),
            ],
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
            children: [
              _buildFilters(),
              _buildViewToggle(),
              Expanded(
                child: _filteredRecipes.isEmpty
                    ? _buildEmptyState()
                    : _buildRecipeGrid(),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _navigateToRecipeForm(),
            icon: Icon(
              Icons.add,
              size: ResponsiveController.iconSize(20),
            ),
            label: Text(
              'Add Recipe',
              style: TextStyle(
                fontSize: ResponsiveController.fontSize(14),
              ),
            ),
            backgroundColor: AppColors.primaryColor,
          ),
        );
      },
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: EdgeInsets.all(ResponsiveController.spacing(16)),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Search Bar
          TextField(
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Search recipes...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  ResponsiveController.borderRadius(8),
                ),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: ResponsiveController.spacing(16),
                vertical: ResponsiveController.spacing(12),
              ),
            ),
          ),
          SizedBox(height: ResponsiveController.spacing(12)),
          // Recipe Type Dropdown
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: ResponsiveController.spacing(12),
            ),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(
                ResponsiveController.borderRadius(8),
              ),
            ),
            child: DropdownButton<String>(
              value: _selectedTypeId,
              isExpanded: true,
              underline: const SizedBox(),
              icon: const Icon(Icons.arrow_drop_down),
              items: [
                const DropdownMenuItem(
                  value: 'all',
                  child: Row(
                    children: [
                      Icon(Icons.all_inclusive, size: 20),
                      SizedBox(width: 8),
                      Text('All Categories'),
                    ],
                  ),
                ),
                ..._recipeTypes.map((type) {
                  return DropdownMenuItem(
                    value: type.id,
                    child: Row(
                      children: [
                        Icon(
                          _getIconFromString(type.icon),
                          size: 20,
                          color: _getColorFromString(type.color),
                        ),
                        const SizedBox(width: 8),
                        Text(type.name),
                      ],
                    ),
                  );
                }).toList(),
              ],
              onChanged: _onTypeChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewToggle() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveController.spacing(16),
        vertical: ResponsiveController.spacing(8),
      ),
      child: Row(
        children: [
          Icon(
            _showOnlyMyRecipes ? Icons.person : Icons.public,
            size: ResponsiveController.iconSize(20),
            color: AppColors.primaryColor,
          ),
          SizedBox(width: ResponsiveController.spacing(8)),
          Text(
            _showOnlyMyRecipes
                ? 'Showing your recipes (${_filteredRecipes.length})'
                : 'Showing all recipes (${_filteredRecipes.length})',
            style: TextStyle(
              fontSize: ResponsiveController.fontSize(14),
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: _toggleRecipeView,
            child: Text(
              _showOnlyMyRecipes ? 'Show All' : 'Show Mine',
              style: TextStyle(
                fontSize: ResponsiveController.fontSize(12),
                color: AppColors.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipeGrid() {
    // Initialize ResponsiveController first
    ResponsiveController.init(context);

    return RefreshIndicator(
      onRefresh: _loadData,
      child: GridView.builder(
        padding: EdgeInsets.all(ResponsiveController.spacing(16)),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: ResponsiveController.isTablet ? 3 : 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: ResponsiveController.spacing(16),
          mainAxisSpacing: ResponsiveController.spacing(16),
        ),
        itemCount: _filteredRecipes.length,
        itemBuilder: (context, index) {
          final recipe = _filteredRecipes[index];
          return _buildRecipeCard(recipe);
        },
      ),
    );
  }

  Widget _buildRecipeCard(Recipe recipe) {
    final user = _authService.currentUser;
    final isOwner = user != null && recipe.createdBy == user.uid;

    return GestureDetector(
      onTap: () => _navigateToRecipeDetail(recipe),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            ResponsiveController.borderRadius(12),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Recipe Image
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(ResponsiveController.borderRadius(12)),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      recipe.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey.shade200,
                          child: Icon(
                            Icons.restaurant,
                            size: 40,
                            color: Colors.grey.shade400,
                          ),
                        );
                      },
                    ),
                    // Gradient Overlay
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 60,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withOpacity(0.7),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Recipe Type Badge
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getIconForType(recipe.typeId),
                              size: 14,
                              color: _getColorForType(recipe.typeId),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              recipe.typeName,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Owner badge
                    if (isOwner)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Mine',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    // Action buttons for owner
                    if (isOwner)
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.9),
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.edit, size: 16),
                                onPressed: () => _navigateToRecipeForm(recipe: recipe),
                                padding: const EdgeInsets.all(4),
                                constraints: const BoxConstraints(
                                  minWidth: 24,
                                  minHeight: 24,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.9),
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                icon: Icon(Icons.delete, size: 16, color: AppColors.errorColor),
                                onPressed: () => _deleteRecipe(recipe),
                                padding: const EdgeInsets.all(4),
                                constraints: const BoxConstraints(
                                  minWidth: 24,
                                  minHeight: 24,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // Recipe Info
            Expanded(
              flex: 2,
              child: Padding(
                padding: EdgeInsets.all(ResponsiveController.spacing(12)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe.name,
                      style: TextStyle(
                        fontSize: ResponsiveController.fontSize(14),
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'by ${recipe.createdByName}',
                      style: TextStyle(
                        fontSize: ResponsiveController.fontSize(10),
                        color: AppColors.primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: Text(
                        recipe.description,
                        style: TextStyle(
                          fontSize: ResponsiveController.fontSize(11),
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.timer, size: 12, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          '${recipe.totalTime} min',
                          style: TextStyle(
                            fontSize: ResponsiveController.fontSize(10),
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            const Icon(Icons.star, size: 12, color: Colors.amber),
                            const SizedBox(width: 2),
                            Text(
                              recipe.rating.toString(),
                              style: TextStyle(
                                fontSize: ResponsiveController.fontSize(10),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.restaurant_menu,
            size: 80,
            color: Colors.grey.shade400,
          ),
          SizedBox(height: ResponsiveController.spacing(16)),
          Text(
            _showOnlyMyRecipes ? 'No recipes created yet' : 'No recipes found',
            style: TextStyle(
              fontSize: ResponsiveController.fontSize(18),
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: ResponsiveController.spacing(8)),
          Text(
            _showOnlyMyRecipes
                ? 'Create your first recipe!'
                : _searchQuery.isNotEmpty
                ? 'Try adjusting your search'
                : 'No recipes available',
            style: TextStyle(
              fontSize: ResponsiveController.fontSize(14),
              color: Colors.grey.shade500,
            ),
          ),
          if (_showOnlyMyRecipes) ...[
            SizedBox(height: ResponsiveController.spacing(24)),
            ElevatedButton.icon(
              onPressed: () => _navigateToRecipeForm(),
              icon: const Icon(Icons.add),
              label: const Text('Add Your First Recipe'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                padding: EdgeInsets.symmetric(
                  horizontal: ResponsiveController.spacing(24),
                  vertical: ResponsiveController.spacing(12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  IconData _getIconFromString(String iconName) {
    final iconMap = {
      'restaurant_menu': Icons.restaurant_menu,
      'dinner_dining': Icons.dinner_dining,
      'cake': Icons.cake,
      'local_cafe': Icons.local_cafe,
      'breakfast_dining': Icons.breakfast_dining,
      'eco': Icons.eco,
      'soup_kitchen': Icons.soup_kitchen,
      'tapas': Icons.tapas,
      'ramen_dining': Icons.ramen_dining,
      'set_meal': Icons.set_meal,
      'grass': Icons.grass,
      'outdoor_grill': Icons.outdoor_grill,
    };
    return iconMap[iconName] ?? Icons.restaurant;
  }

  Color _getColorFromString(String colorHex) {
    try {
      return Color(int.parse(colorHex.replaceAll('#', '0xFF')));
    } catch (e) {
      return Colors.blue;
    }
  }

  IconData _getIconForType(String typeId) {
    final type = _recipeTypes.firstWhere(
          (t) => t.id == typeId,
      orElse: () => _recipeTypes.first,
    );
    return _getIconFromString(type.icon);
  }

  Color _getColorForType(String typeId) {
    final type = _recipeTypes.firstWhere(
          (t) => t.id == typeId,
      orElse: () => _recipeTypes.first,
    );
    return _getColorFromString(type.color);
  }
}