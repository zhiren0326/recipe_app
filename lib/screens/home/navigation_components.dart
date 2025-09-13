// widgets/navigation_components.dart (Updated)
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../services/auth_service.dart';
import '../../utils/constants.dart';
import '../../utils/responsive_controller.dart';
import '../auth/login_screen.dart';
import '../recipe/recipe_form_screen.dart';
import '../recipe/recipe_list_screen.dart';
import '../profile/profile_screen.dart';
import 'home_screen.dart';

class MainNavigationWrapper extends StatefulWidget {
  final int initialIndex;

  const MainNavigationWrapper({
    Key? key,
    this.initialIndex = 0,
  }) : super(key: key);

  @override
  State<MainNavigationWrapper> createState() => _MainNavigationWrapperState();
}

class _MainNavigationWrapperState extends State<MainNavigationWrapper> {
  late int _currentIndex;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  final List<Widget> _screens = [
    const HomeScreen(),
    const RecipeListScreen(),
    const RecipeFormScreen(),
    const ProfileScreen(),
  ];

  final List<BottomNavigationBarItem> _navItems = [
    const BottomNavigationBarItem(
      icon: Icon(Icons.home),
      label: 'Home',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.book),
      label: 'Recipes',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.add),
      label: 'Add Recipe',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.person),
      label: 'Profile',
    ),
  ];

  void _onNavItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, deviceType, orientation) {
        return Scaffold(
          body: Row(
            children: [
              // Sidebar for tablet and desktop
              if (ResponsiveController.isTablet || ResponsiveController.isDesktop)
                AppSidebar(
                  currentIndex: _currentIndex,
                  onItemSelected: _onNavItemTapped,
                ),
              // Main content
              Expanded(
                child: _screens[_currentIndex],
              ),
            ],
          ),
          // Bottom navigation for mobile
          bottomNavigationBar: ResponsiveController.isMobile
              ? AppBottomNavigation(
            currentIndex: _currentIndex,
            onItemTapped: _onNavItemTapped,
            items: _navItems,
          )
              : null,
        );
      },
    );
  }
}

class AppBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final Function(int) onItemTapped;
  final List<BottomNavigationBarItem> items;

  const AppBottomNavigation({
    Key? key,
    required this.currentIndex,
    required this.onItemTapped,
    required this.items,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, deviceType, orientation) {
        return Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: BottomNavigationBar(
            currentIndex: currentIndex,
            onTap: onItemTapped,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: AppColors.primaryColor,
            unselectedItemColor: Colors.grey.shade600,
            selectedLabelStyle: TextStyle(
              fontSize: ResponsiveController.fontSize(12),
              fontWeight: FontWeight.bold,
            ),
            unselectedLabelStyle: TextStyle(
              fontSize: ResponsiveController.fontSize(12),
            ),
            iconSize: ResponsiveController.iconSize(24),
            items: items,
          ),
        );
      },
    );
  }
}

class AppSidebar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onItemSelected;

  const AppSidebar({
    Key? key,
    required this.currentIndex,
    required this.onItemSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();
    final user = authService.currentUser;

    return ResponsiveBuilder(
      builder: (context, deviceType, orientation) {
        final sidebarWidth = ResponsiveController.isDesktop ? 280.0 : 240.0;

        return Container(
          width: sidebarWidth,
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(5, 0),
              ),
            ],
          ),
          child: Column(
            children: [
              // User Profile Section
              GestureDetector(
                onTap: () => onItemSelected(3), // Navigate to profile
                child: Container(
                  padding: ResponsiveController.padding(all: 20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primaryColor,
                        AppColors.primaryColor.withOpacity(0.8),
                      ],
                    ),
                  ),
                  child: Column(
                    children: [
                      Hero(
                        tag: 'profile_avatar',
                        child: CircleAvatar(
                          radius: ResponsiveController.iconSize(30),
                          backgroundColor: Colors.white,
                          child: Icon(
                            Icons.person,
                            size: ResponsiveController.iconSize(30),
                            color: AppColors.primaryColor,
                          ),
                        ),
                      ),
                      ResponsiveSpacing(height: 12),
                      ResponsiveText(
                        user?.displayName ?? user?.email ?? 'Chef',
                        baseSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        textAlign: TextAlign.center,
                      ),
                      ResponsiveSpacing(height: 4),
                      ResponsiveText(
                        'Recipe Manager',
                        baseSize: 12,
                        color: Colors.white.withOpacity(0.8),
                        textAlign: TextAlign.center,
                      ),
                      ResponsiveSpacing(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ResponsiveText(
                          'Tap to view profile',
                          baseSize: 10,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Navigation Items
              Expanded(
                child: ListView(
                  padding: ResponsiveController.padding(vertical: 8),
                  children: [
                    _buildNavItem(
                      context: context,
                      icon: Icons.home,
                      title: 'Home',
                      index: 0,
                      isSelected: currentIndex == 0,
                    ),
                    _buildNavItem(
                      context: context,
                      icon: Icons.book,
                      title: 'My Recipes',
                      index: 1,
                      isSelected: currentIndex == 1,
                    ),
                    _buildNavItem(
                      context: context,
                      icon: Icons.add,
                      title: 'Add Recipe',
                      index: 2,
                      isSelected: currentIndex == 2,
                    ),
                    _buildNavItem(
                      context: context,
                      icon: Icons.person,
                      title: 'Profile',
                      index: 3,
                      isSelected: currentIndex == 3,
                    ),
                    const Divider(),
                    _buildNavItem(
                      context: context,
                      icon: Icons.settings,
                      title: 'Settings',
                      index: -1,
                      isSelected: false,
                      onTap: () => _showSettings(context),
                    ),
                  ],
                ),
              ),

              // Logout Button
              Container(
                padding: ResponsiveController.padding(all: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _logout(context),
                    icon: Icon(Icons.logout, size: ResponsiveController.iconSize(18)),
                    label: ResponsiveText(
                      'Sign Out',
                      baseSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.errorColor,
                      foregroundColor: Colors.white,
                      padding: ResponsiveController.padding(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          ResponsiveController.borderRadius(8),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required int index,
    required bool isSelected,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: ResponsiveController.padding(horizontal: 8, vertical: 2),
      child: ListTile(
        leading: Icon(
          icon,
          size: ResponsiveController.iconSize(22),
          color: isSelected ? AppColors.primaryColor : Colors.grey.shade600,
        ),
        title: ResponsiveText(
          title,
          baseSize: 14,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? AppColors.primaryColor : Colors.grey.shade700,
        ),
        selected: isSelected,
        selectedTileColor: AppColors.primaryColor.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            ResponsiveController.borderRadius(8),
          ),
        ),
        onTap: onTap ?? () => onItemSelected(index),
      ),
    );
  }

  void _showSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Settings'),
        content: const Text('Settings page coming soon! Use the Profile page to manage your account settings.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onItemSelected(3); // Navigate to profile
            },
            child: const Text('Go to Profile'),
          ),
        ],
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
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
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final authService = AuthService();
      await authService.signOut();
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
              (route) => false,
        );
      }
    }
  }
}