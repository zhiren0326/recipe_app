// screens/home/home_screen.dart
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/recipe_service.dart';
import '../../utils/constants.dart';
import '../../utils/responsive_controller.dart';
import '../auth/login_screen.dart';
import '../recipe/recipe_list_screen.dart';
import '../recipe/recipe_form_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();
  final RecipeService _recipeService = RecipeService();
  Map<String, int> _stats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);

    try {
      await _recipeService.initialize();
      await _recipeService.syncWithFirebase();

      final stats = _recipeService.getRecipeStats();
      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, deviceType, orientation) {
        final user = _authService.currentUser;

        return Scaffold(
          appBar: AppBar(
            title: ResponsiveText(
              'Recipe Manager',
              baseSize: 20,
              fontWeight: FontWeight.bold,
            ),
            actions: [
              IconButton(
                icon: ResponsiveIcon(
                  Icons.refresh,
                  baseSize: 24,
                ),
                onPressed: _loadStats,
              ),
              if (ResponsiveController.isMobile)
                PopupMenuButton<String>(
                  onSelected: (value) async {
                    if (value == 'logout') {
                      await _authService.signOut();
                      if (mounted) {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                              (route) => false,
                        );
                      }
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'logout',
                      child: Row(
                        children: [
                          Icon(Icons.logout, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Sign Out'),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: _loadStats,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Center(
                child: ResponsiveContainer(
                  padding: ResponsiveController.padding(all: 20),
                  maxWidth: ResponsiveController.containerWidth(maxWidth: 600),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ResponsiveIcon(
                        Icons.restaurant_menu,
                        baseSize: 80,
                        color: AppColors.primaryColor,
                      ),
                      ResponsiveSpacing(height: 30),
                      ResponsiveText(
                        'Welcome to Recipe Manager!',
                        baseSize: 24,
                        fontWeight: FontWeight.bold,
                        textAlign: TextAlign.center,
                      ),
                      ResponsiveSpacing(height: 10),
                      ResponsiveText(
                        user?.displayName ?? user?.email ?? 'Chef',
                        baseSize: 16,
                        color: Colors.grey[600],
                      ),
                      ResponsiveSpacing(height: 20),
                      ResponsiveText(
                        'Create, manage, and discover your favorite recipes all in one place.',
                        baseSize: 14,
                        textAlign: TextAlign.center,
                        color: Colors.grey[700],
                      ),
                      ResponsiveSpacing(height: 40),

                      // Quick Action Buttons
                      _buildQuickActions(),

                      ResponsiveSpacing(height: 30),

                      // Stats Card
                      _buildStatsCard(),

                      ResponsiveSpacing(height: 30),

                      // Recent Activity (placeholder for future implementation)
                      _buildRecentActivity(),

                      ResponsiveSpacing(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickActions() {
    return Column(
      children: [
        // Browse Recipes Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const RecipeListScreen(),
                ),
              );
            },
            icon: ResponsiveIcon(
              Icons.book,
              baseSize: 20,
              color: Colors.white,
            ),
            label: ResponsiveText(
              'Browse My Recipes',
              baseSize: 16,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              padding: ResponsiveController.padding(
                horizontal: 30,
                vertical: 15,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  ResponsiveController.borderRadius(8),
                ),
              ),
            ),
          ),
        ),

        ResponsiveSpacing(height: 16),

        // Add Recipe Button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const RecipeFormScreen(),
                ),
              );
            },
            icon: ResponsiveIcon(
              Icons.add,
              baseSize: 20,
              color: AppColors.primaryColor,
            ),
            label: ResponsiveText(
              'Add New Recipe',
              baseSize: 16,
              color: AppColors.primaryColor,
              fontWeight: FontWeight.bold,
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppColors.primaryColor),
              padding: ResponsiveController.padding(
                horizontal: 30,
                vertical: 15,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  ResponsiveController.borderRadius(8),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsCard() {
    if (_isLoading) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            ResponsiveController.borderRadius(12),
          ),
        ),
        child: Padding(
          padding: ResponsiveController.padding(all: 20),
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          ResponsiveController.borderRadius(12),
        ),
      ),
      child: Padding(
        padding: ResponsiveController.padding(all: 20),
        child: Column(
          children: [
            ResponsiveText(
              'Your Recipe Stats',
              baseSize: 18,
              fontWeight: FontWeight.bold,
            ),
            ResponsiveSpacing(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  _stats['total']?.toString() ?? '0',
                  'Total Recipes',
                  Icons.restaurant,
                ),
                _buildStatItem(
                  _stats['categories']?.toString() ?? '0',
                  'Categories',
                  Icons.category,
                ),
                _buildStatItem(
                  _stats['avgRating']?.toString() ?? '0',
                  'Avg Rating',
                  Icons.star,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          size: ResponsiveController.iconSize(24),
          color: AppColors.primaryColor,
        ),
        ResponsiveSpacing(height: 8),
        ResponsiveText(
          value,
          baseSize: 20,
          fontWeight: FontWeight.bold,
        ),
        ResponsiveText(
          label,
          baseSize: 12,
          color: Colors.grey[600],
        ),
      ],
    );
  }

  Widget _buildRecentActivity() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          ResponsiveController.borderRadius(12),
        ),
      ),
      child: Padding(
        padding: ResponsiveController.padding(all: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ResponsiveText(
              'Quick Tips',
              baseSize: 18,
              fontWeight: FontWeight.bold,
            ),
            ResponsiveSpacing(height: 16),
            _buildTipItem(
              Icons.camera_alt,
              'Add photos to make your recipes more appealing',
            ),
            ResponsiveSpacing(height: 12),
            _buildTipItem(
              Icons.star,
              'Rate your recipes to keep track of favorites',
            ),
            ResponsiveSpacing(height: 12),
            _buildTipItem(
              Icons.share,
              'Your recipes are synced across all your devices',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipItem(IconData icon, String tip) {
    return Row(
      children: [
        Icon(
          icon,
          size: ResponsiveController.iconSize(20),
          color: AppColors.primaryColor.withOpacity(0.7),
        ),
        ResponsiveSpacing(width: 12),
        Expanded(
          child: ResponsiveText(
            tip,
            baseSize: 14,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }
}