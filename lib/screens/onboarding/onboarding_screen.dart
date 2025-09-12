import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../utils/constants.dart';
import '../../utils/responsive_controller.dart';
import '../auth/login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  bool isLastPage = false;

  final List<OnboardingPage> pages = [
    OnboardingPage(
      title: 'Easy Recipes',
      description: 'Discover simple and delicious recipes that anyone can make. Perfect for beginners and busy home cooks looking for quick meal solutions.',
      imagePath: 'assets/images/onboard/onboarding1.png',
    ),
    OnboardingPage(
      title: 'Cooking Life Hacks',
      description: 'Learn smart kitchen tips and tricks that save time and effort. Make cooking easier with our collection of clever culinary shortcuts.',
      imagePath: 'assets/images/onboard/onboarding2.png',
    ),
    OnboardingPage(
      title: 'Make Shopping Lists',
      description: 'Create organized grocery lists instantly from any recipe. Never forget an ingredient and make shopping trips more efficient.',
      imagePath: 'assets/images/onboard/onboarding3.png',
    ),
    OnboardingPage(
      title: 'The Most Popular Recipes',
      description: 'Explore trending dishes loved by thousands of home cooks. Find top-rated recipes that are guaranteed to impress.',
      imagePath: 'assets/images/onboard/onboarding4.png',
    ),
    OnboardingPage(
      title: 'Book In Your Pocket',
      description: 'Access your entire recipe collection anywhere, anytime. Save your favorites and carry your personalized cookbook wherever you go.',
      imagePath: 'assets/images/onboard/onboarding5.png',
    ),
    OnboardingPage(
      title: 'Step by Step Cooking',
      description: 'Follow easy-to-understand instructions with detailed guidance. Cook with confidence as we walk you through every step of the process.',
      imagePath: 'assets/images/onboard/onboarding6.png',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', true);

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, deviceType, orientation) {
        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: ResponsiveController.spacing(80),
              ),
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    isLastPage = index == pages.length - 1;
                  });
                },
                itemCount: pages.length,
                itemBuilder: (context, index) {
                  return _buildPage(pages[index]);
                },
              ),
            ),
          ),
          bottomSheet: Container(
            padding: ResponsiveController.padding(horizontal: 20),
            height: ResponsiveController.spacing(80),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: _completeOnboarding,
                  child: ResponsiveText(
                    'SKIP',
                    baseSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                Center(
                  child: SmoothPageIndicator(
                    controller: _pageController,
                    count: pages.length,
                    effect: WormEffect(
                      spacing: ResponsiveController.spacing(12),
                      dotColor: Colors.grey.shade300,
                      activeDotColor: AppColors.primaryColor,
                      dotHeight: ResponsiveController.spacing(10),
                      dotWidth: ResponsiveController.spacing(10),
                    ),
                    onDotClicked: (index) => _pageController.animateToPage(
                      index,
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeIn,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    if (isLastPage) {
                      _completeOnboarding();
                    } else {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                  child: ResponsiveText(
                    isLastPage ? 'DONE' : 'NEXT',
                    baseSize: 14,
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPage(OnboardingPage page) {
    return ResponsiveContainer(
      padding: ResponsiveController.padding(all: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Image container with decoration
          Container(
            height: ResponsiveController.imageSize(250),
            width: ResponsiveController.imageSize(250),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(
                ResponsiveController.borderRadius(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  spreadRadius: 5,
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(
                ResponsiveController.borderRadius(20),
              ),
              child: Image.asset(
                page.imagePath,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  // Fallback if image not found
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(
                        ResponsiveController.borderRadius(20),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ResponsiveIcon(
                          Icons.image_not_supported,
                          baseSize: 60,
                          color: Colors.grey.shade400,
                        ),
                        ResponsiveSpacing(height: 10),
                        ResponsiveText(
                          'Image not found',
                          baseSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          ResponsiveSpacing(height: 40),
          ResponsiveText(
            page.title,
            baseSize: 26,
            fontWeight: FontWeight.bold,
            color: AppColors.textColor,
            textAlign: TextAlign.center,
          ),
          ResponsiveSpacing(height: 20),
          Padding(
            padding: ResponsiveController.padding(horizontal: 20),
            child: ResponsiveText(
              page.description,
              baseSize: 15,
              color: Colors.grey.shade600,
              textAlign: TextAlign.center,
              style: TextStyle(height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingPage {
  final String title;
  final String description;
  final String imagePath;

  OnboardingPage({
    required this.title,
    required this.description,
    required this.imagePath,
  });
}