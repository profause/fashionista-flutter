import 'package:fashionista/core/onboarding/onboarding_cubit.dart';
import 'package:fashionista/core/theme/app.theme.dart';
import 'package:fashionista/core/widgets/animated_primary_button.dart';
import 'package:fashionista/data/models/onboarding/models/onboarding_page_data.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController(viewportFraction: 1);
  //double _currentPage = 0;
  bool isLastPage = false;
  late OnboardingCubit _onboardingCubit;

  final List<OnboardingPageData> onboardingPageData = [
    OnboardingPageData(
      title: 'Discover New Styles',
      description:
          'Browse through endless fashion inspirations tailored just for you.',
      icon: Icons.style,
    ),
    OnboardingPageData(
      title: 'Connect with Designers',
      description:
          'Collaborate directly with talented designers to bring your vision to life.',
      icon: Icons.people,
    ),
    OnboardingPageData(
      title: 'Manage Clients Easily',
      description:
          'Save measurements, track progress, and share updates effortlessly.',
      icon: Icons.rule,
    ),
    OnboardingPageData(
      title: 'Manage Your Closet',
      description:
          'Save your outfits, track progress, and keep everything organized.',
      icon: Icons.checkroom,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {});
    if (mounted) {
      _onboardingCubit = context.read<OnboardingCubit>();
    }
  }

  Future<void> navigateToLogin() async {
    _onboardingCubit.hasSeenOnboarding(true);//here
    context.go('/sign-in');
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: AppTheme.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(
                    () => isLastPage = index == onboardingPageData.length - 1,
                  );
                },
                itemCount: onboardingPageData.length,
                itemBuilder: (context, index) {
                  final pageOffset = (_pageController.page ?? 0) - index;
                  //final opacity = (1 - pageOffset.abs()).clamp(0.0, 1.0);
                  // Fade effect
                  //double opacity =
                  //  1.0 - (_currentPage - index).abs().clamp(0.0, 1.0);

                  final page = onboardingPageData[index];
                  return AnimatedOpacity(
                    opacity: 1,
                    duration: const Duration(milliseconds: 300),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            page.icon,
                            size: 100,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(height: 20),
                          AnimatedSlide(
                            duration: const Duration(milliseconds: 500),
                            offset: pageOffset.abs() < 0.5
                                ? const Offset(0, 0)
                                : const Offset(0, 0.2),
                            child: Text(
                              page.title,
                              style: Theme.of(context).textTheme.headlineMedium,
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 10),
                          AnimatedSlide(
                            duration: const Duration(milliseconds: 500),
                            offset: pageOffset.abs() < 0.5
                                ? const Offset(0, 0)
                                : const Offset(0, 0.2),
                            child: Text(
                              page.description,
                              style: Theme.of(context).textTheme.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                          ),
                          if (isLastPage &&
                              index == onboardingPageData.length - 1)
                            Padding(
                              padding: const EdgeInsets.only(top: 40),
                              child: Hero(
                                tag: "getStarted",
                                child: AnimatedPrimaryButton(
                                  text: "Get Started",
                                  onPressed: navigateToLogin,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            SmoothPageIndicator(
              controller: _pageController,
              count: onboardingPageData.length,
              effect: ExpandingDotsEffect(
                activeDotColor: colorScheme.primary,
                dotColor: colorScheme.secondary.withValues(alpha: 0.4),
                dotHeight: 8,
                dotWidth: 8,
                spacing: 8,
                expansionFactor: 4,
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
