import 'package:flutter/material.dart';
import 'package:recipe_app/screens/auth/register_screen.dart';

import '../../services/auth_service.dart';
import '../../utils/constants.dart';
import '../../utils/responsive_controller.dart';
import '../../widgets/custom_text_field.dart';
import '../home/navigation_components.dart'; // Import the navigation wrapper
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final user = await _authService.signInWithEmailAndPassword(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );

        if (user != null && mounted) {
          // Navigate to MainNavigationWrapper instead of HomeScreen
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => const MainNavigationWrapper(initialIndex: 0),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString()),
              backgroundColor: AppColors.errorColor,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isGoogleLoading = true;
    });

    try {
      final user = await _authService.signInWithGoogle();

      if (user != null && mounted) {
        // Navigate to MainNavigationWrapper instead of HomeScreen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const MainNavigationWrapper(initialIndex: 0),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGoogleLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, deviceType, orientation) {
        return Scaffold(
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: ResponsiveController.padding(all: 20),
                child: ResponsiveContainer(
                  maxWidth: ResponsiveController.containerWidth(maxWidth: 500),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ResponsiveVisibility(
                          showInLandscape: ResponsiveController.isTablet,
                          child: Column(
                            children: [
                              ResponsiveIcon(
                                Icons.lock_outline,
                                baseSize: 80,
                                color: AppColors.primaryColor,
                              ),
                              ResponsiveSpacing(height: 30),
                            ],
                          ),
                        ),
                        ResponsiveText(
                          'Welcome Back!',
                          baseSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textColor,
                          textAlign: TextAlign.center,
                        ),
                        ResponsiveSpacing(height: 30),
                        CustomTextField(
                          controller: _emailController,
                          hintText: 'Email',
                          prefixIcon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            }
                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                .hasMatch(value)) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                        ),
                        ResponsiveSpacing(height: 20),
                        CustomTextField(
                          controller: _passwordController,
                          hintText: 'Password',
                          prefixIcon: Icons.lock_outline,
                          obscureText: _obscurePassword,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password';
                            }
                            if (value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ),
                        ResponsiveSpacing(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const ForgotPasswordScreen(),
                                ),
                              );
                            },
                            child: ResponsiveText(
                              'Forgot Password?',
                              baseSize: 14,
                              color: AppColors.primaryColor,
                            ),
                          ),
                        ),
                        ResponsiveSpacing(height: 20),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryColor,
                            padding: EdgeInsets.symmetric(
                              vertical: ResponsiveController.buttonHeight(mobile: 15),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                ResponsiveController.borderRadius(10),
                              ),
                            ),
                          ),
                          child: _isLoading
                              ? SizedBox(
                            height: ResponsiveController.iconSize(20),
                            width: ResponsiveController.iconSize(20),
                            child: const CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                              : ResponsiveText(
                            'LOGIN',
                            baseSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        ResponsiveSpacing(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 1,
                                color: Colors.grey[300],
                              ),
                            ),
                            Padding(
                              padding: ResponsiveController.padding(horizontal: 15),
                              child: ResponsiveText(
                                'OR',
                                baseSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            Expanded(
                              child: Container(
                                height: 1,
                                color: Colors.grey[300],
                              ),
                            ),
                          ],
                        ),
                        ResponsiveSpacing(height: 20),
                        OutlinedButton.icon(
                          onPressed: _isGoogleLoading ? null : _signInWithGoogle,
                          icon: _isGoogleLoading
                              ? SizedBox(
                            height: ResponsiveController.iconSize(18),
                            width: ResponsiveController.iconSize(18),
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                              : Image.network(
                            "https://ouch-cdn2.icons8.com/VGHyfDgzIiyEwg3RIll1nYupfj653vnEPRLr0AeoJ8g/rs:fit:456:456/czM6Ly9pY29uczgu/b3VjaC1wcm9kLmFz/c2V0cy9wbmcvODg2/LzRjNzU2YThjLTQx/MjgtNGZlZS04MDNl/LTAwMTM0YzEwOTMy/Ny5wbmc.png",
                            height: ResponsiveController.iconSize(24),
                            width: ResponsiveController.iconSize(24),
                          ),
                          label: ResponsiveText(
                            'Continue with Google',
                            baseSize: 15,
                            color: AppColors.textColor,
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                              vertical: ResponsiveController.buttonHeight(mobile: 12),
                              horizontal: ResponsiveController.spacing(20),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                ResponsiveController.borderRadius(10),
                              ),
                            ),
                            side: BorderSide(
                              color: Colors.grey[300]!,
                            ),
                          ),
                        ),
                        ResponsiveSpacing(height: 30),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ResponsiveText(
                              "Don't have an account? ",
                              baseSize: 14,
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const RegisterScreen(),
                                  ),
                                );
                              },
                              child: ResponsiveText(
                                'Sign Up',
                                baseSize: 14,
                                color: AppColors.primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}