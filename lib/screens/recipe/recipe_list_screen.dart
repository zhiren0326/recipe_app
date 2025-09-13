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

class _RecipeListScreenState extends State<RecipeListScreen> with TickerProviderStateMixin {
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

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));
    _loadData();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      await _recipeService.initialize();
      _recipeTypes = _recipeService.getRecipeTypes();
      await _syncWithFirebase();
      _loadRecipes();
      setState(() => _isLoading = false);
    } catch (e) {
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
      await _recipeService.syncWithFirebase();
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
      } else {
        _recipes = _recipeService.getAllRecipes();
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

  Future<void> _manualRefresh() async {
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
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

  Widget _buildRecipeImage(String imageUrl, {BoxFit fit = BoxFit.cover}) {
    if (imageUrl.startsWith('data:image')) {
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
      return Image.network(
        imageUrl,
        fit: fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                  loadingProgress.expectedTotalBytes!
                  : null,
              color: AppColors.primaryColor,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return _buildImagePlaceholder();
        },
      );
    }
  }

  Widget _buildImagePlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.grey.shade300,
            Colors.grey.shade200,
          ],
        ),
      ),
      child: Icon(
        Icons.restaurant_menu,
        size: 50,
        color: Colors.grey.shade400,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, deviceType, orientation) {
        return Scaffold(
          backgroundColor: const Color(0xFFF8F9FA),
          appBar: _buildAppBar(),
          body: _isLoading
              ? const Center(
            child: CircularProgressIndicator(),
          )
              : FadeTransition(
            opacity: _fadeAnimation,
            child: _buildScrollableContent(),
          ),
          floatingActionButton: _buildFloatingActionButton(),
        );
      },
    );
  }

  // New method for scrollable content using CustomScrollView
  Widget _buildScrollableContent() {
    return RefreshIndicator(
      onRefresh: _manualRefresh,
      color: AppColors.primaryColor,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // Search and Filter Section as Sliver
          SliverToBoxAdapter(
            child: _buildSearchAndFilter(),
          ),

          // Progress Indicator
          if (_isSyncing)
            SliverToBoxAdapter(
              child: LinearProgressIndicator(
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
              ),
            ),

          // Content Area
          if (_filteredRecipes.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _buildEmptyState(),
            )
          else
            SliverPadding(
              padding: EdgeInsets.all(ResponsiveController.spacing(20)),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: ResponsiveController.isTablet ? 3 : 2,
                  childAspectRatio: 0.60,
                  crossAxisSpacing: ResponsiveController.spacing(16),
                  mainAxisSpacing: ResponsiveController.spacing(16),
                ),
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    final recipe = _filteredRecipes[index];
                    return _buildModernRecipeCard(recipe, index);
                  },
                  childCount: _filteredRecipes.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final user = _authService.currentUser;

    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _showOnlyMyRecipes ? Icons.person : Icons.public,
              color: AppColors.primaryColor,
              size: ResponsiveController.iconSize(24),
            ),
          ),
          ResponsiveSpacing(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ResponsiveText(
                  _showOnlyMyRecipes ? 'My Recipes' : 'All Recipes',
                  baseSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                ResponsiveText(
                  '${_filteredRecipes.length} recipes',
                  baseSize: 12,
                  color: Colors.grey[600],
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        if (_isSyncing)
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
              ),
            ),
          )
        else
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: ResponsiveIcon(
                Icons.refresh_rounded,
                baseSize: 22,
                color: AppColors.primaryColor,
              ),
              onPressed: _manualRefresh,
            ),
          ),
        Container(
          margin: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: ResponsiveIcon(
              _showOnlyMyRecipes ? Icons.public : Icons.person,
              baseSize: 22,
              color: AppColors.primaryColor,
            ),
            onPressed: _toggleRecipeView,
            tooltip: _showOnlyMyRecipes ? 'Show All Recipes' : 'Show My Recipes',
          ),
        ),
      ],
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: ResponsiveController.padding(all: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search Bar with modern design
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F7),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.grey.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    style: TextStyle(
                      fontSize: ResponsiveController.fontSize(15),
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search recipes, ingredients, or chefs...',
                      hintStyle: TextStyle(
                        color: Colors.grey[500],
                        fontSize: ResponsiveController.fontSize(14),
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: Colors.grey[600],
                        size: ResponsiveController.iconSize(22),
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                        icon: Icon(
                          Icons.clear_rounded,
                          color: Colors.grey[600],
                          size: ResponsiveController.iconSize(20),
                        ),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                          : null,
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: ResponsiveController.spacing(20),
                        vertical: ResponsiveController.spacing(16),
                      ),
                    ),
                  ),
                ),

                ResponsiveSpacing(height: 16),

                // Category Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      _buildFilterChip(
                        'all',
                        'All Categories',
                        Icons.all_inclusive,
                        null,
                      ),
                      ..._recipeTypes.map((type) {
                        return _buildFilterChip(
                          type.id,
                          type.name,
                          _getIconFromString(type.icon),
                          _getColorFromString(type.color),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Stats Bar
          Container(
            padding: ResponsiveController.padding(
              horizontal: 20,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryColor.withOpacity(0.05),
                  AppColors.primaryColor.withOpacity(0.02),
                ],
              ),
              border: Border(
                top: BorderSide(
                  color: AppColors.primaryColor.withOpacity(0.1),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.restaurant_menu,
                        size: ResponsiveController.iconSize(16),
                        color: AppColors.primaryColor,
                      ),
                    ),
                    ResponsiveSpacing(width: 8),
                    ResponsiveText(
                      '${_filteredRecipes.length} Recipes Found',
                      baseSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ],
                ),
                if (_selectedTypeId != 'all')
                  TextButton.icon(
                    onPressed: () => _onTypeChanged('all'),
                    icon: Icon(
                      Icons.clear,
                      size: ResponsiveController.iconSize(16),
                    ),
                    label: ResponsiveText(
                      'Clear Filter',
                      baseSize: 12,
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primaryColor,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String id, String label, IconData icon, Color? color) {
    final isSelected = _selectedTypeId == id;

    return Padding(
      padding: EdgeInsets.only(right: ResponsiveController.spacing(8)),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        child: FilterChip(
          selected: isSelected,
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: ResponsiveController.iconSize(16),
                color: isSelected
                    ? Colors.white
                    : (color ?? AppColors.primaryColor),
              ),
              ResponsiveSpacing(width: 6),
              ResponsiveText(
                label,
                baseSize: 13,
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ],
          ),
          onSelected: (selected) => _onTypeChanged(id),
          backgroundColor: Colors.white,
          selectedColor: color ?? AppColors.primaryColor,
          checkmarkColor: Colors.white,
          elevation: isSelected ? 4 : 1,
          shadowColor: (color ?? AppColors.primaryColor).withOpacity(0.3),
          padding: EdgeInsets.symmetric(
            horizontal: ResponsiveController.spacing(12),
            vertical: ResponsiveController.spacing(8),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isSelected
                  ? Colors.transparent
                  : Colors.grey.withOpacity(0.2),
              width: 1,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernRecipeCard(Recipe recipe, int index) {
    final user = _authService.currentUser;
    final isOwner = user != null && recipe.createdBy == user.uid;
    final hasFirebaseId = recipe.firebaseId != null && recipe.firebaseId!.isNotEmpty;

    return GestureDetector(
      onTap: () => _navigateToRecipeDetail(recipe),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300 + (index * 50)),
        curve: Curves.easeOutBack,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image Section
                Expanded(
                  flex: 3,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Hero(
                        tag: 'recipe_${recipe.id}',
                        child: _buildRecipeImage(recipe.imageUrl),
                      ),
                      // Gradient Overlay
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.6),
                            ],
                            stops: const [0.6, 1.0],
                          ),
                        ),
                      ),
                      // Badges
                      Positioned(
                        top: 12,
                        left: 12,
                        right: 12,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (isOwner)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.primaryColor,
                                      AppColors.primaryColor.withOpacity(0.8),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.star,
                                      size: 12,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 4),
                                    const Text(
                                      'Mine',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    if (hasFirebaseId) ...[
                                      const SizedBox(width: 4),
                                      const Icon(
                                        Icons.cloud_done,
                                        size: 12,
                                        color: Colors.white,
                                      ),
                                    ],
                                  ],
                                ),
                              )
                            else
                              const SizedBox.shrink(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.95),
                                borderRadius: BorderRadius.circular(20),
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
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Rating
                      Positioned(
                        bottom: 12,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                size: 14,
                                color: Colors.amber,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                recipe.rating.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Content Section
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          recipe.name,
                          style: TextStyle(
                            fontSize: ResponsiveController.fontSize(15),
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 8,
                              backgroundColor: AppColors.primaryColor.withOpacity(0.2),
                              child: Icon(
                                Icons.person,
                                size: 10,
                                color: AppColors.primaryColor,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                recipe.createdByName,
                                style: TextStyle(
                                  fontSize: ResponsiveController.fontSize(11),
                                  color: AppColors.primaryColor,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            _buildInfoChip(
                              Icons.timer,
                              '${recipe.totalTime}m',
                              const Color(0xFF6C63FF),
                            ),
                            const SizedBox(width: 8),
                            _buildInfoChip(
                              Icons.restaurant,
                              recipe.difficulty,
                              const Color(0xFF4ECDC4),
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
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.restaurant_menu,
              size: 80,
              color: AppColors.primaryColor.withOpacity(0.5),
            ),
          ),
          SizedBox(height: ResponsiveController.spacing(24)),
          Text(
            _showOnlyMyRecipes
                ? 'No recipes created yet'
                : 'No recipes found',
            style: TextStyle(
              fontSize: ResponsiveController.fontSize(20),
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: ResponsiveController.spacing(8)),
          Text(
            _showOnlyMyRecipes
                ? 'Start your culinary journey!'
                : _searchQuery.isNotEmpty
                ? 'Try adjusting your search'
                : 'Be the first to share a recipe',
            style: TextStyle(
              fontSize: ResponsiveController.fontSize(14),
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: ResponsiveController.spacing(32)),
          if (_showOnlyMyRecipes) ...[
            ElevatedButton.icon(
              onPressed: () => _navigateToRecipeForm(),
              icon: const Icon(Icons.add_circle_outline, color: Colors.white),
              label: const Text(
                'Create Your First Recipe',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 4,
              ),
            ),
          ] else ...[
            OutlinedButton.icon(
              onPressed: _manualRefresh,
              icon: Icon(Icons.refresh, color: AppColors.primaryColor),
              label: Text(
                'Refresh',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryColor,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppColors.primaryColor, width: 2),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: FloatingActionButton.extended(
        onPressed: () => _navigateToRecipeForm(),
        backgroundColor: AppColors.primaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'New Recipe',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        elevation: 8,
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