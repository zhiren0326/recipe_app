// screens/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../services/auth_service.dart';
import '../../services/recipe_service.dart';
import '../../utils/constants.dart';
import '../../utils/responsive_controller.dart';
import '../auth/login_screen.dart';
import '../recipe/recipeBundel.dart';
import '../recipe/recipe_list_screen.dart';
import '../recipe/recipe_form_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final RecipeService _recipeService = RecipeService();
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

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
    _loadStats();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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
          SnackBar(
            content: Text('Error loading data: $e'),
            backgroundColor: Colors.red,
          ),
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
          backgroundColor: const Color(0xFFF8F9FA),
          appBar: _buildAppBar(user),
          body: RefreshIndicator(
            onRefresh: _loadStats,
            color: AppColors.primaryColor,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // Hero Header Section with Gradient
                    _buildHeroSection(user),

                    // Main Content
                    Padding(
                      padding: ResponsiveController.padding(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Featured Recipe Collections
                          _buildRecipeBundlesSection(),

                          ResponsiveSpacing(height: 30),

                          // Quick Actions with new design
                          _buildQuickActions(),

                          ResponsiveSpacing(height: 30),

                          // Stats Dashboard
                          _buildStatsSection(),

                          ResponsiveSpacing(height: 30),

                          // Tips Section
                          _buildTipsSection(),

                          ResponsiveSpacing(height: 40),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(user) {
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
              Icons.restaurant_menu,
              color: AppColors.primaryColor,
              size: ResponsiveController.iconSize(24),
            ),
          ),
          ResponsiveSpacing(width: 12),
          ResponsiveText(
            'Recipe Hub',
            baseSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ],
      ),
      actions: [
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
            onPressed: _loadStats,
          ),
        ),
        if (ResponsiveController.isMobile)
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
            child: PopupMenuButton<String>(
              icon: Icon(
                Icons.more_vert,
                color: Colors.black87,
                size: ResponsiveController.iconSize(22),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              onSelected: (value) async {
                if (value == 'logout') {
                  await _authService.signOut();
                  if (mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                          (route) => false,
                    );
                  }
                } else if (value == 'profile') {
                  _showUserProfileDialog();
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'profile',
                  child: Row(
                    children: [
                      Icon(Icons.person_outline, color: AppColors.primaryColor),
                      const SizedBox(width: 12),
                      Text(user?.displayName ?? user?.email ?? 'Profile'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout_rounded, color: Colors.red),
                      SizedBox(width: 12),
                      Text('Sign Out'),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildHeroSection(user) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryColor.withOpacity(0.1),
            AppColors.primaryColor.withOpacity(0.05),
          ],
        ),
      ),
      child: Padding(
        padding: ResponsiveController.padding(all: 30),
        child: Column(
          children: [
            // Enhanced Avatar with border
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryColor,
                    AppColors.primaryColor.withOpacity(0.7),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryColor.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: ResponsiveController.iconSize(45),
                backgroundColor: Colors.white,
                child: CircleAvatar(
                  radius: ResponsiveController.iconSize(42),
                  backgroundColor: AppColors.primaryColor,
                  child: Text(
                    (user?.displayName ?? user?.email ?? 'U')[0].toUpperCase(),
                    style: TextStyle(
                      fontSize: ResponsiveController.fontSize(28),
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            ResponsiveSpacing(height: 20),
            ResponsiveText(
              'Welcome Back,',
              baseSize: 18,
              color: Colors.black54,
            ),
            ResponsiveSpacing(height: 5),
            ResponsiveText(
              user?.displayName ?? user?.email ?? 'Master Chef',
              baseSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            ResponsiveSpacing(height: 15),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ResponsiveText(
                '🍳 Create • 📚 Manage • ⭐ Discover',
                baseSize: 14,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecipeBundlesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ResponsiveText(
              '✨ Featured Collections',
              baseSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            TextButton(
              onPressed: () {},
              child: ResponsiveText(
                'See All',
                baseSize: 14,
                color: AppColors.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        ResponsiveSpacing(height: 16),
        SizedBox(
          height: ResponsiveController.height(28),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: recipeBundles.length,
            itemBuilder: (context, index) => Padding(
              padding: EdgeInsets.only(
                right: ResponsiveController.spacing(16),
              ),
              child: _buildEnhancedRecipeCard(recipeBundles[index], index),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedRecipeCard(RecipeBundle recipeBundle, int index) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const RecipeListScreen(),
          ),
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: ResponsiveController.width(80),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              recipeBundle.color,
              recipeBundle.color.withOpacity(0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: recipeBundle.color.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Background Pattern
            Positioned(
              right: -20,
              top: -20,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
            ),
            // Content
            Padding(
              padding: ResponsiveController.padding(all: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: ResponsiveText(
                      index == 0 ? '🔥 Trending' : index == 1 ? '⭐ Popular' : '🍴 Featured',
                      baseSize: 11,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  ResponsiveText(
                    recipeBundle.title,
                    baseSize: 20,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  ResponsiveSpacing(height: 8),
                  ResponsiveText(
                    recipeBundle.description,
                    baseSize: 13,
                    color: Colors.white.withOpacity(0.9),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      _buildStatChip(
                        Icons.restaurant_menu,
                        '${recipeBundle.recipes}',
                      ),
                      ResponsiveSpacing(width: 12),
                      _buildStatChip(
                        Icons.people,
                        '${recipeBundle.chefs}',
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: ResponsiveController.iconSize(20),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: ResponsiveController.iconSize(14),
            color: Colors.white,
          ),
          ResponsiveSpacing(width: 4),
          ResponsiveText(
            value,
            baseSize: 12,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ResponsiveText(
          '🚀 Quick Actions',
          baseSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
        ResponsiveSpacing(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                icon: Icons.search_rounded,
                title: 'Browse',
                subtitle: 'Explore recipes',
                color: const Color(0xFF6C63FF),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const RecipeListScreen(),
                    ),
                  );
                },
              ),
            ),
            ResponsiveSpacing(width: 16),
            Expanded(
              child: _buildActionCard(
                icon: Icons.add_circle_outline,
                title: 'Create',
                subtitle: 'Add new recipe',
                color: const Color(0xFFFF6B6B),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const RecipeFormScreen(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: ResponsiveController.padding(all: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(0.1),
              color.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: color.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: color,
                size: ResponsiveController.iconSize(28),
              ),
            ),
            ResponsiveSpacing(height: 16),
            ResponsiveText(
              title,
              baseSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            ResponsiveSpacing(height: 4),
            ResponsiveText(
              subtitle,
              baseSize: 12,
              color: Colors.black54,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    if (_isLoading) {
      return _buildLoadingCard();
    }

    final total = _stats['total'] ?? 0;
    final categories = _stats['categories'] ?? 0;
    final avgRating = _stats['avgRating'] ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ResponsiveText(
          '📊 Your Dashboard',
          baseSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
        ResponsiveSpacing(height: 16),
        Container(
          padding: ResponsiveController.padding(all: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    icon: Icons.restaurant_menu,
                    value: total.toString(),
                    label: 'Recipes',
                    color: const Color(0xFF6C63FF),
                  ),
                  _buildDivider(),
                  _buildStatItem(
                    icon: Icons.category_rounded,
                    value: categories.toString(),
                    label: 'Categories',
                    color: const Color(0xFF4ECDC4),
                  ),
                  _buildDivider(),
                  _buildStatItem(
                    icon: Icons.star_rounded,
                    value: avgRating.toStringAsFixed(1),
                    label: 'Avg Rating',
                    color: const Color(0xFFFFD93D),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 40,
      width: 1,
      color: Colors.grey.withOpacity(0.2),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            icon,
            color: color,
            size: ResponsiveController.iconSize(24),
          ),
        ),
        ResponsiveSpacing(height: 12),
        ResponsiveText(
          value,
          baseSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
        ResponsiveSpacing(height: 4),
        ResponsiveText(
          label,
          baseSize: 12,
          color: Colors.black54,
        ),
      ],
    );
  }

  Widget _buildTipsSection() {
    final tips = [
      {'icon': Icons.camera_alt_rounded, 'text': 'Add photos to make recipes appealing', 'color': const Color(0xFF6C63FF)},
      {'icon': Icons.star_rounded, 'text': 'Rate recipes to track favorites', 'color': const Color(0xFFFFD93D)},
      {'icon': Icons.cloud_sync_rounded, 'text': 'Auto-sync across all devices', 'color': const Color(0xFF4ECDC4)},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ResponsiveText(
          '💡 Pro Tips',
          baseSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
        ResponsiveSpacing(height: 16),
        ...tips.map((tip) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            padding: ResponsiveController.padding(all: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: (tip['color'] as Color).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    tip['icon'] as IconData,
                    color: tip['color'] as Color,
                    size: ResponsiveController.iconSize(20),
                  ),
                ),
                ResponsiveSpacing(width: 16),
                Expanded(
                  child: ResponsiveText(
                    tip['text'] as String,
                    baseSize: 14,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        )).toList(),
      ],
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      padding: ResponsiveController.padding(all: 40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Center(
        child: CircularProgressIndicator(
          color: AppColors.primaryColor,
        ),
      ),
    );
  }

  void _showUserProfileDialog() {
    final user = _authService.currentUser;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: AppColors.primaryColor,
                child: Text(
                  (user?.displayName ?? user?.email ?? 'U')[0].toUpperCase(),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'User Profile',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 20),
              _buildProfileItem(Icons.person, 'Name', user?.displayName ?? 'Not set'),
              _buildProfileItem(Icons.email, 'Email', user?.email ?? 'Not available'),
              _buildProfileItem(Icons.verified_user, 'Verified', user?.emailVerified == true ? 'Yes' : 'No'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primaryColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}