// screens/profile/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../../utils/constants.dart';
import '../../utils/responsive_controller.dart';
import '../auth/login_screen.dart';
import 'profile_edit_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  UserProfile? _userProfile;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final profile = await _userService.getUserProfile();
      setState(() {
        _userProfile = profile;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  String _getInitial() {
    final user = _authService.currentUser;
    final profile = _userProfile;

    // Priority: Display Name > Profile Name > Email > Default
    String nameSource = profile?.displayName ??
        user?.displayName ??
        user?.email ??
        'U';

    return nameSource[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, deviceType, orientation) {
        return Scaffold(
          appBar: AppBar(
            title: ResponsiveText(
              'Profile',
              baseSize: 20,
              fontWeight: FontWeight.bold,
            ),
            actions: [
              IconButton(
                icon: ResponsiveIcon(
                  Icons.refresh,
                  baseSize: 24,
                ),
                onPressed: _loadUserProfile,
              ),
              if (_userProfile != null)
                IconButton(
                  icon: ResponsiveIcon(
                    Icons.edit,
                    baseSize: 24,
                  ),
                  onPressed: () => _navigateToEditProfile(),
                ),
            ],
          ),
          body: _buildBody(),
        );
      },
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: ResponsiveController.iconSize(64),
              color: Colors.red,
            ),
            ResponsiveSpacing(height: 16),
            ResponsiveText(
              'Error loading profile',
              baseSize: 18,
              fontWeight: FontWeight.bold,
            ),
            ResponsiveSpacing(height: 8),
            ResponsiveText(
              _error!,
              baseSize: 14,
              color: Colors.grey[600],
              textAlign: TextAlign.center,
            ),
            ResponsiveSpacing(height: 16),
            ElevatedButton(
              onPressed: _loadUserProfile,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadUserProfile,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Center(
          child: ResponsiveContainer(
            padding: ResponsiveController.padding(all: 20),
            maxWidth: ResponsiveController.containerWidth(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProfileHeader(),
                ResponsiveSpacing(height: 24),
                _buildProfileInfo(),
                ResponsiveSpacing(height: 24),
                _buildAccountActions(),
                ResponsiveSpacing(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    final user = _authService.currentUser;
    final profile = _userProfile;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          ResponsiveController.borderRadius(16),
        ),
      ),
      child: Container(
        width: double.infinity,
        padding: ResponsiveController.padding(all: 24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(
            ResponsiveController.borderRadius(16),
          ),
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
            // Circle Avatar with Letter Initial (matching home screen)
            Container(
              width: ResponsiveController.iconSize(100),
              height: ResponsiveController.iconSize(100),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  _getInitial(),
                  style: TextStyle(
                    fontSize: ResponsiveController.fontSize(40),
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryColor,
                  ),
                ),
              ),
            ),
            ResponsiveSpacing(height: 16),
            ResponsiveText(
              profile?.displayName ?? user?.displayName ?? user?.email ?? 'User',
              baseSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              textAlign: TextAlign.center,
            ),
            if (profile?.bio != null) ...[
              ResponsiveSpacing(height: 8),
              ResponsiveText(
                profile!.bio!,
                baseSize: 14,
                color: Colors.white.withOpacity(0.9),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            ResponsiveSpacing(height: 16),
            Container(
              padding: ResponsiveController.padding(
                horizontal: 16,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(
                  ResponsiveController.borderRadius(20),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.email,
                    size: ResponsiveController.iconSize(16),
                    color: Colors.white,
                  ),
                  ResponsiveSpacing(width: 8),
                  Flexible(
                    child: ResponsiveText(
                      user?.email ?? 'No email',
                      baseSize: 14,
                      color: Colors.white,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            if (user?.emailVerified == true) ...[
              ResponsiveSpacing(height: 8),
              Container(
                padding: ResponsiveController.padding(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(
                    ResponsiveController.borderRadius(16),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.verified,
                      size: ResponsiveController.iconSize(16),
                      color: Colors.white,
                    ),
                    ResponsiveSpacing(width: 6),
                    ResponsiveText(
                      'Verified',
                      baseSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProfileInfo() {
    final profile = _userProfile;

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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ResponsiveText(
                  'Personal Information',
                  baseSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                IconButton(
                  onPressed: _navigateToEditProfile,
                  icon: Icon(
                    Icons.edit_outlined,
                    size: ResponsiveController.iconSize(20),
                    color: AppColors.primaryColor,
                  ),
                  tooltip: 'Edit Profile',
                ),
              ],
            ),
            ResponsiveSpacing(height: 16),
            _buildInfoItem(
              Icons.phone,
              'Phone',
              profile?.phone ?? 'Not provided',
            ),
            _buildInfoItem(
              Icons.cake,
              'Date of Birth',
              profile?.dateOfBirth != null
                  ? '${profile!.dateOfBirth!.day}/${profile.dateOfBirth!.month}/${profile.dateOfBirth!.year}${profile.age != null ? ' (${profile.age} years old)' : ''}'
                  : 'Not provided',
            ),
            _buildInfoItem(
              Icons.location_on,
              'Location',
              profile?.location ?? 'Not provided',
            ),
            _buildInfoItem(
              Icons.person,
              'User ID',
              profile?.uid ?? 'Unknown',
              isSelectable: true,
            ),
            if (profile?.createdAt != null)
              _buildInfoItem(
                Icons.calendar_today,
                'Member Since',
                '${profile!.createdAt!.day}/${profile.createdAt!.month}/${profile.createdAt!.year}',
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value, {bool isSelectable = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: ResponsiveController.padding(all: 8),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(
                ResponsiveController.borderRadius(8),
              ),
            ),
            child: Icon(
              icon,
              size: ResponsiveController.iconSize(20),
              color: AppColors.primaryColor,
            ),
          ),
          ResponsiveSpacing(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ResponsiveText(
                  label,
                  baseSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
                ResponsiveSpacing(height: 4),
                isSelectable
                    ? SelectableText(
                  value,
                  style: TextStyle(
                    fontSize: ResponsiveController.fontSize(14),
                    fontWeight: FontWeight.normal,
                  ),
                )
                    : ResponsiveText(
                  value,
                  baseSize: 14,
                  fontWeight: FontWeight.normal,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountActions() {
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
              'Account Actions',
              baseSize: 18,
              fontWeight: FontWeight.bold,
            ),
            ResponsiveSpacing(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _changePassword,
                icon: Icon(
                  Icons.lock_outline,
                  size: ResponsiveController.iconSize(18),
                ),
                label: ResponsiveText(
                  'Change Password',
                  baseSize: 14,
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppColors.primaryColor),
                  padding: ResponsiveController.padding(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      ResponsiveController.borderRadius(8),
                    ),
                  ),
                ),
              ),
            ),
            ResponsiveSpacing(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _confirmSignOut,
                icon: Icon(
                  Icons.logout,
                  size: ResponsiveController.iconSize(18),
                  color: Colors.white,
                ),
                label: ResponsiveText(
                  'Sign Out',
                  baseSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: ResponsiveController.padding(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      ResponsiveController.borderRadius(8),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToEditProfile() {
    if (_userProfile == null) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProfileEditScreen(userProfile: _userProfile!),
      ),
    ).then((result) {
      // Refresh profile data when returning from edit screen
      if (result == true) {
        _loadUserProfile();
      }
    });
  }

  void _changePassword() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: const Text(
          'A password reset email will be sent to your email address. '
              'Follow the instructions in the email to reset your password.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await FirebaseAuth.instance.sendPasswordResetEmail(
                  email: _authService.currentUser!.email!,
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Password reset email sent!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Send Reset Email'),
          ),
        ],
      ),
    );
  }

  void _confirmSignOut() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _authService.signOut();
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                );
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}