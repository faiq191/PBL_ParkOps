import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di.dart';
import '../../../../routes.dart';
import '../../../../theme/app_colors.dart';

/// Quick showcase shown the first time the app is opened.
///
/// Page 1: Welcome — what ParkOps is.
/// Page 2: Permissions — location + notification to use full features.
/// Page 3: Create account — with "Skip" and "Register" actions.
///
/// The "onboarding done" flag is persisted through OnboardingRepository
/// (DV-2 fix: no storage plugin call in the widget).
class OnboardingPages extends ConsumerStatefulWidget {
  const OnboardingPages({super.key});

  @override
  ConsumerState<OnboardingPages> createState() => _OnboardingPagesState();
}

class _OnboardingPagesState extends ConsumerState<OnboardingPages> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  static const List<_OnboardingData> _pages = [
    _OnboardingData(
      icon: Icons.local_parking_rounded,
      title: 'Welcome to ParkOps',
      description:
          'ParkOps helps you check the availability of car parking slots '
          'on campus in near real time. We continuously monitor the parking '
          'area and relay live status, so you can make an informed decision '
          'before you even arrive.',
    ),
    _OnboardingData(
      icon: Icons.location_on_outlined,
      title: 'Permissions',
      description:
          'To use the full features of ParkOps, please allow location '
          'access so we can show the nearest parking lots around you, and '
          'enable notifications so you never miss live slot updates and '
          'important alerts.',
    ),
    _OnboardingData(
      icon: Icons.person_add_alt_1_rounded,
      title: 'Create an account',
      description:
          'Sign up to unlock the full ParkOps experience — save your '
          'favorite lots, get personalized availability insights, and '
          'receive instant updates on your parking status.',
    ),
  ];

  /// Whether the user has accepted the required permissions (UI-only demo).
  bool _permissionGranted = false;

  /// UI-only: no real permission request, just toggles the demo state.
  void _requestPermissions() {
    setState(() => _permissionGranted = true);
  }

  /// "Grant Permission" button + live status, shown on the Permissions slide.
  Widget _buildPermissionAction() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: _requestPermissions,
            icon: Icon(
              _permissionGranted
                  ? Icons.check_circle_rounded
                  : Icons.lock_open_rounded,
              size: 20,
            ),
            label: Text(
              _permissionGranted ? 'Permissions Granted' : 'Grant Permission',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: _permissionGranted
                  ? Colors.green.shade700
                  : AppColors.navy,
              side: BorderSide(
                color: _permissionGranted
                    ? Colors.green.shade700
                    : AppColors.navy,
                width: 1.4,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _permissionGranted
              ? 'Thanks! You can continue to the next step.'
              : 'You can allow the permission later from device settings.',
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: _permissionGranted ? Colors.green.shade700 : AppColors.navy,
          ),
        ),
        const SizedBox(height: 14),
        // Next — always pressable (permissions are UI-only for now).
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _next,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.navy,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              'Next',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish({bool goHome = true}) async {
    // Persist a flag so the walkthrough does not appear again.
    await ref.read(onboardingRepositoryProvider).setDone(done: true);
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(Routes.home);
  }

  void _next() {
    if (_currentPage < _pages.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    } else {
      _finish();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _currentPage == _pages.length - 1;

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button (hidden on the last page — it has its own actions)
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 12, right: 18),
                child: isLast
                    ? const SizedBox(height: 36)
                    : TextButton(
                        onPressed: _finish,
                        child: const Text(
                          'Skip',
                          style: TextStyle(
                            color: AppColors.mist,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (_, i) => _OnboardingSlide(data: _pages[i]),
              ),
            ),
            // Page indicator dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: i == _currentPage ? 22 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: i == _currentPage ? AppColors.navy : AppColors.line,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: isLast
                  ? _buildLastPageActions()
                  : _currentPage == 1
                  ? _buildPermissionAction()
                  : _buildNextButton(),
            ),
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }

  Widget _buildNextButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _next,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.navy,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: const Text(
          'Next',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _buildLastPageActions() {
    return Row(
      children: [
        // Skip — go straight to the app without registering
        Expanded(
          child: SizedBox(
            height: 52,
            child: OutlinedButton(
              onPressed: _finish,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.navy,
                side: const BorderSide(color: AppColors.navy, width: 1.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Skip',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Register — entry point to the account creation flow
        Expanded(
          child: SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushNamed(Routes.register);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.amber,
                foregroundColor: AppColors.navy,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Register',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Immutable data for a single onboarding slide.
class _OnboardingData {
  final IconData icon;
  final String title;
  final String description;
  const _OnboardingData({
    required this.icon,
    required this.title,
    required this.description,
  });
}

class _OnboardingSlide extends StatelessWidget {
  final _OnboardingData data;
  const _OnboardingSlide({required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Illustration bubble
          Container(
            width: 160,
            height: 160,
            decoration: const BoxDecoration(
              color: AppColors.navy,
              shape: BoxShape.circle,
            ),
            child: Icon(data.icon, size: 72, color: AppColors.amber),
          ),
          const SizedBox(height: 40),
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            data.description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              height: 1.6,
              color: AppColors.mist,
            ),
          ),
        ],
      ),
    );
  }
}
