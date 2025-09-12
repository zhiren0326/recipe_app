// screens/home/home_screen.dart
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../utils/constants.dart';
import '../../utils/responsive_controller.dart';
import '../auth/login_screen.dart';
import '../recipe/recipe_list_screen.dart';


class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, deviceType, orientation) {
        final AuthService authService = AuthService();
        final user = authService.currentUser;

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
                  Icons.logout,
                  baseSize: 24,
                ),
                onPressed: () async {
                  await authService.signOut();
                  if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                          (route) => false,
                    );
                  }
                },
              ),
            ],
          ),
          body: Center(
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
                    user?.email ?? 'Chef',
                    baseSize: 16,
                    color: Colors.grey[600],
                  ),
                  ResponsiveSpacing(height: 20),
                  ResponsiveText(
                    'Discover, create, and manage your favorite recipes all in one place.',
                    baseSize: 14,
                    textAlign: TextAlign.center,
                    color: Colors.grey[700],
                  ),
                  ResponsiveSpacing(height: 40),

                  // Recipe Manager Button
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
                        'Browse Recipes',
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

                  // Quick Stats Card
                  Card(
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
                            'Quick Stats',
                            baseSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          ResponsiveSpacing(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatItem('16', 'Recipes', Icons.restaurant),
                              _buildStatItem('12', 'Categories', Icons.category),
                              _buildStatItem('4.6', 'Avg Rating', Icons.star),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  ResponsiveSpacing(height: 40),

                  // Logout Button
                  TextButton.icon(
                    onPressed: () async {
                      await authService.signOut();
                      if (context.mounted) {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                              (route) => false,
                        );
                      }
                    },
                    icon: ResponsiveIcon(
                      Icons.logout,
                      baseSize: 18,
                      color: AppColors.errorColor,
                    ),
                    label: ResponsiveText(
                      'Sign Out',
                      baseSize: 14,
                      color: AppColors.errorColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          size: 24,
          color: AppColors.primaryColor,
        ),
        SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}