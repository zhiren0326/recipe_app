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

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  UserProfile? _userProfile;
  bool _isLoading = true;
  String? _error;

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
    _loadUserProfile();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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
          backgroundColor: const Color(0xFFF8F9FA),
          appBar: _buildAppBar(),
          body: _buildBody(),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar() {
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
              Icons.person_outline,
              color: AppColors.primaryColor,
              size: ResponsiveController.iconSize(24),
            ),
          ),
          ResponsiveSpacing(width: 12),
          ResponsiveText(
            'Profile',
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
            onPressed: _loadUserProfile,
          ),
        ),
        if (_userProfile != null)
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
                Icons.edit_rounded,
                baseSize: 22,
                color: AppColors.primaryColor,
              ),
              onPressed: () => _navigateToEditProfile(),
            ),
          ),
      ],
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: AppColors.primaryColor,
        ),
      );
    }

    if (_error != null) {
      return _buildErrorState();
    }

    return RefreshIndicator(
      onRefresh: _loadUserProfile,
      color: AppColors.primaryColor,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              _buildProfileHero(),
              Padding(
                padding: ResponsiveController.padding(horizontal: 20),
                child: Column(
                  children: [
                    ResponsiveSpacing(height: 24),
                    _buildProfileInfo(),
                    ResponsiveSpacing(height: 24),
                    _buildAccountActions(),
                    ResponsiveSpacing(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.error_outline_rounded,
              size: ResponsiveController.iconSize(64),
              color: Colors.red,
            ),
          ),
          ResponsiveSpacing(height: 24),
          ResponsiveText(
            'Error loading profile',
            baseSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          ResponsiveSpacing(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: ResponsiveText(
              _error!,
              baseSize: 14,
              color: Colors.grey[600],
              textAlign: TextAlign.center,
            ),
          ),
          ResponsiveSpacing(height: 24),
          ElevatedButton.icon(
            onPressed: _loadUserProfile,
            icon: const Icon(Icons.refresh, color: Colors.white),
            label: const Text(
              'Retry',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 14,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHero() {
    final user = _authService.currentUser;
    final profile = _userProfile;

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
            // Enhanced Avatar
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
                radius: ResponsiveController.iconSize(55),
                backgroundColor: Colors.white,
                child: CircleAvatar(
                  radius: ResponsiveController.iconSize(52),
                  backgroundColor: AppColors.primaryColor,
                  child: Text(
                    _getInitial(),
                    style: TextStyle(
                      fontSize: ResponsiveController.fontSize(32),
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            ResponsiveSpacing(height: 20),
            ResponsiveText(
              profile?.displayName ?? user?.displayName ?? user?.email ?? 'User',
              baseSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              textAlign: TextAlign.center,
            ),
            if (profile?.bio != null) ...[
              ResponsiveSpacing(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: ResponsiveText(
                  profile!.bio!,
                  baseSize: 14,
                  color: Colors.grey[600],
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
            ResponsiveSpacing(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildBadge(
                  Icons.email_rounded,
                  user?.email ?? 'No email',
                  Colors.blue,
                ),
                if (user?.emailVerified == true) ...[
                  ResponsiveSpacing(width: 12),
                  _buildBadge(
                    Icons.verified_rounded,
                    'Verified',
                    Colors.green,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }


  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: ResponsiveController.padding(all: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: ResponsiveController.iconSize(20),
            ),
          ),
          ResponsiveSpacing(height: 12),
          ResponsiveText(
            value,
            baseSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          ResponsiveSpacing(height: 4),
          ResponsiveText(
            label,
            baseSize: 11,
            color: Colors.grey[600],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileInfo() {
    final profile = _userProfile;

    return Container(
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
      child: Padding(
        padding: ResponsiveController.padding(all: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.person_outline_rounded,
                      color: AppColors.primaryColor,
                      size: ResponsiveController.iconSize(20),
                    ),
                    ResponsiveSpacing(width: 8),
                    ResponsiveText(
                      'Personal Information',
                      baseSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ],
                ),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    onPressed: _navigateToEditProfile,
                    icon: Icon(
                      Icons.edit_outlined,
                      size: ResponsiveController.iconSize(18),
                      color: AppColors.primaryColor,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                    padding: const EdgeInsets.all(6),
                  ),
                ),
              ],
            ),
            ResponsiveSpacing(height: 20),
            _buildInfoRow(
              Icons.phone_rounded,
              'Phone',
              profile?.phone ?? 'Not provided',
              const Color(0xFF6C63FF),
            ),
            _buildInfoRow(
              Icons.cake_rounded,
              'Birthday',
              profile?.dateOfBirth != null
                  ? '${profile!.dateOfBirth!.day}/${profile.dateOfBirth!.month}/${profile.dateOfBirth!.year}'
                  : 'Not provided',
              const Color(0xFFFF6B6B),
            ),
            _buildInfoRow(
              Icons.location_on_rounded,
              'Location',
              profile?.location ?? 'Not provided',
              const Color(0xFF4ECDC4),
            ),
            _buildInfoRow(
              Icons.fingerprint_rounded,
              'User ID',
              profile?.uid ?? 'Unknown',
              const Color(0xFFFFD93D),
              isSelectable: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color color, {bool isSelectable = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: ResponsiveController.iconSize(18),
              color: color,
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
                ),
                ResponsiveSpacing(height: 4),
                isSelectable
                    ? SelectableText(
                  value,
                  style: TextStyle(
                    fontSize: ResponsiveController.fontSize(14),
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                )
                    : ResponsiveText(
                  value,
                  baseSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ResponsiveText(
          '⚙️ Account Settings',
          baseSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
        ResponsiveSpacing(height: 16),
        _buildActionButton(
          icon: Icons.lock_outline_rounded,
          label: 'Change Password',
          color: const Color(0xFF6C63FF),
          onTap: _changePassword,
        ),
        ResponsiveSpacing(height: 12),
        _buildActionButton(
          icon: Icons.logout_rounded,
          label: 'Sign Out',
          color: Colors.red,
          onTap: _confirmSignOut,
          filled: true,
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool filled = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: ResponsiveController.padding(all: 16),
        decoration: BoxDecoration(
          color: filled ? color : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: filled ? color : color.withOpacity(0.3),
            width: filled ? 0 : 2,
          ),
          boxShadow: [
            BoxShadow(
              color: (filled ? color : Colors.black).withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: filled ? Colors.white : color,
              size: ResponsiveController.iconSize(20),
            ),
            ResponsiveSpacing(width: 12),
            ResponsiveText(
              label,
              baseSize: 16,
              fontWeight: FontWeight.bold,
              color: filled ? Colors.white : color,
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
      if (result == true) {
        _loadUserProfile();
      }
    });
  }

  void _changePassword() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.lock_reset_rounded,
                  size: 40,
                  color: AppColors.primaryColor,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Change Password',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'A password reset email will be sent to your email address. Follow the instructions in the email to reset your password.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
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
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        'Send Email',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmSignOut() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  size: 40,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Sign Out',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Are you sure you want to sign out?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
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
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        'Sign Out',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}