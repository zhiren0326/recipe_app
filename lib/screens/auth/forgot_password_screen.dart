import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../utils/constants.dart';
import '../../utils/responsive_controller.dart';
import '../../widgets/custom_text_field.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        await _authService.resetPassword(_emailController.text.trim());

        if (mounted) {
          setState(() {
            _emailSent = true;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Password reset email sent to ${_emailController.text.trim()}'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 4),
            ),
          );

          // Navigate back after a delay
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) {
              Navigator.pop(context);
            }
          });
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

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, deviceType, orientation) {
        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: ResponsiveIcon(
                Icons.arrow_back,
                baseSize: 24,
                color: AppColors.textColor,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
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
                        ResponsiveIcon(
                          _emailSent ? Icons.mark_email_read : Icons.lock_reset,
                          baseSize: 80,
                          color: _emailSent ? Colors.green : AppColors.primaryColor,
                        ),
                        ResponsiveSpacing(height: 30),
                        ResponsiveText(
                          _emailSent ? 'Email Sent!' : 'Reset Password',
                          baseSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textColor,
                          textAlign: TextAlign.center,
                        ),
                        ResponsiveSpacing(height: 15),
                        ResponsiveText(
                          _emailSent
                              ? 'Please check your email for instructions to reset your password.'
                              : 'Enter your email address and we\'ll send you instructions to reset your password.',
                          baseSize: 14,
                          color: Colors.grey[600],
                          textAlign: TextAlign.center,
                        ),
                        ResponsiveSpacing(height: 30),
                        if (!_emailSent) ...[
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
                          ResponsiveSpacing(height: 30),
                          ElevatedButton(
                            onPressed: _isLoading ? null : _resetPassword,
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
                              'SEND RESET EMAIL',
                              baseSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ] else ...[
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context),
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
                            child: ResponsiveText(
                              'BACK TO LOGIN',
                              baseSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                        ResponsiveSpacing(height: 20),
                        if (!_emailSent)
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: ResponsiveText(
                              'Back to Login',
                              baseSize: 14,
                              color: AppColors.primaryColor,
                            ),
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