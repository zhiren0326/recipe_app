// screens/recipe/recipe_list_screen.dart
import 'dart:convert';
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
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Initialize recipe service
      await _recipeService.initialize();

      // Load recipe types
      _recipeTypes = _recipeService.getRecipeTypes();

      // Sync with Firebase
      await _syncWithFirebase();

      // Load recipes after sync
      _loadRecipes();

      setState(() => _isLoading = false);
    } catch (e) {
      print('Error loading data: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: $e'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              onPressed: _loadData,
              textColor: Colors.white,
            ),
          ),
        );
      }
    }
  }

  Future<void> _syncWithFirebase() async {
    setState(() => _isSyncing = true);

    try {
      print('Starting Firebase sync...');
      await _recipeService.syncWithFirebase();
      print('Firebase sync completed');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Recipes synced successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      print('Error syncing with Firebase: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync error: Working offline. ${e.toString()}'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } finally {
      setState(() => _isSyncing = false);
    }
  }

  void _loadRecipes() {
    setState(() {
      if (_showOnlyMyRecipes) {
        _recipes = _recipeService.getUserRecipes();
        print('Loaded ${_recipes.length} user recipes');
      } else {
        _recipes = _recipeService.getAllRecipes();
        print('Loaded ${_recipes.length} total recipes');
      }
      _filterRecipes();
    });
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

      print('Filtered to ${_filteredRecipes.length} recipes');
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

  Future<void> _manualRefresh() async {
    // Force refresh from Firebase
    await _recipeService.refreshRecipes();
    await _loadData();
  }

  Future<void> _navigateToRecipeForm({Recipe? recipe}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecipeFormScreen(recipe: recipe),
      ),
    );
    if (result == true) {
      await _loadData();
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
      await _loadData();
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
        await _loadData();
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

  // Helper method to build image widget that handles both base64 and URLs
  Widget _buildRecipeImage(String imageUrl, {BoxFit fit = BoxFit.cover}) {
    if (imageUrl.startsWith('data:image')) {
      // Base64 image
      try {
        final base64String = imageUrl.split(',').last;
        final bytes = base64Decode(base64String);
        return Image.memory(
          bytes,
          fit: fit,
          errorBuilder: (context, error, stackTrace) {
            return _buildImagePlaceholder();
          },
        );
      } catch (e) {
        return _buildImagePlaceholder();
      }
    } else {
      // Regular URL
      return Image.network(
        imageUrl,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          return _buildImagePlaceholder();
        },
      );
    }
  }

  Widget _buildImagePlaceholder() {
    return Container(
      color: Colors.grey.shade200,
      child: Icon(
        Icons.restaurant,
        size: 40,
        color: Colors.grey.shade400,
      ),
    );
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
              // Sync status indicator
              if (_isSyncing)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                ),
              // Refresh button
              IconButton(
                icon: Icon(
                  Icons.refresh,
                  size: ResponsiveController.iconSize(24),
                ),
                onPressed: _isSyncing ? null : _manualRefresh,
                tooltip: 'Refresh from Firebase',
              ),
              // Toggle view button
              IconButton(
                icon: Icon(
                  _showOnlyMyRecipes ? Icons.person : Icons.public,
                  size: ResponsiveController.iconSize(24),
                ),
                onPressed: _toggleRecipeView,
                tooltip: _showOnlyMyRecipes ? 'Show All Recipes' : 'Show My Recipes',
              ),
              // Add recipe button
              IconButton(
                icon: Icon(
                  Icons.add,
                  size: ResponsiveController.iconSize(24),
                ),
                onPressed: () => _navigateToRecipeForm(),
                tooltip: 'Add Recipe',
              ),
            ],
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
            children: [
              _buildFilters(),
              _buildViewToggle(),
              if (_isSyncing)
                LinearProgressIndicator(
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
                ),
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
    final user = _authService.currentUser;
    final userInfo = user != null
        ? ' (${user.displayName ?? user.email ?? "Unknown"})'
        : '';

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveController.spacing(16),
        vertical: ResponsiveController.spacing(8),
      ),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _showOnlyMyRecipes ? Icons.person : Icons.public,
            size: ResponsiveController.iconSize(20),
            color: AppColors.primaryColor,
          ),
          SizedBox(width: ResponsiveController.spacing(8)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _showOnlyMyRecipes
                      ? 'Your recipes$userInfo'
                      : 'All community recipes',
                  style: TextStyle(
                    fontSize: ResponsiveController.fontSize(14),
                    color: Colors.grey[800],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${_filteredRecipes.length} recipe${_filteredRecipes.length != 1 ? 's' : ''} found',
                  style: TextStyle(
                    fontSize: ResponsiveController.fontSize(12),
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: TextButton(
              onPressed: _toggleRecipeView,
              child: Text(
                _showOnlyMyRecipes ? 'Show All' : 'Show Mine',
                style: TextStyle(
                  fontSize: ResponsiveController.fontSize(12),
                  color: AppColors.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
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
      onRefresh: _manualRefresh,
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
    final hasFirebaseId = recipe.firebaseId != null && recipe.firebaseId!.isNotEmpty;

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
                    // Use the helper method to display image
                    _buildRecipeImage(recipe.imageUrl),
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
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'Mine',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              if (hasFirebaseId) ...[
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.cloud_done,
                                  size: 10,
                                  color: Colors.white,
                                ),
                              ],
                            ],
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
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'by ${recipe.createdByName}',
                            style: TextStyle(
                              fontSize: ResponsiveController.fontSize(10),
                              color: AppColors.primaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!hasFirebaseId && isOwner)
                          Icon(
                            Icons.cloud_off,
                            size: 12,
                            color: Colors.orange,
                          ),
                      ],
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
                : 'No recipes available in the community',
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
          ] else ...[
            SizedBox(height: ResponsiveController.spacing(24)),
            ElevatedButton.icon(
              onPressed: _manualRefresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
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