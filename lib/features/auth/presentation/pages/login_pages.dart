import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di.dart';
import '../../../../routes.dart';
import '../../../../theme/app_colors.dart';

/// Login page. There is no REST/Firebase-Auth backend yet, so logging in
/// only marks onboarding as done through OnboardingRepository (DV-1 fix: no
/// storage plugin call in the widget; a real AuthRepository is added when
/// a backend exists — see the refactoring notes in Refactoring_Assignment.md).
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();
    // No backend yet: credentials are collected but not verified; logging in
    // just persists the walkthrough flag so it never shows again.
    await ref.read(onboardingRepositoryProvider).setDone(done: true);
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(Routes.home);
  }

  void _showSoon(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                padding: EdgeInsets.zero,
                alignment: Alignment.centerLeft,
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 20,
                  color: AppColors.navy,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Welcome Back! Glad\nto see you, Again!',
                style: TextStyle(
                  fontSize: 28,
                  height: 1.25,
                  fontWeight: FontWeight.w700,
                  color: AppColors.navy,
                ),
              ),
              const SizedBox(height: 44),
              _field(
                controller: _usernameController,
                hint: 'Username',
                icon: Icons.person_outline_rounded,
              ),
              const SizedBox(height: 14),
              _field(
                controller: _passwordController,
                hint: 'Password',
                icon: Icons.lock_outline_rounded,
                obscure: _obscure,
                suffix: IconButton(
                  onPressed: () => setState(() => _obscure = !_obscure),
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 20,
                    color: AppColors.mist,
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () =>
                      _showSoon('Password reset is not available yet.'),
                  child: const Text(
                    'Forgot password?',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF6A7685),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.navy,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Login',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 36),
              const Row(
                children: [
                  Expanded(
                      child: Divider(
                          color: AppColors.line, thickness: 1)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 14),
                    child: Text(
                      'Or Login with',
                      style:
                          TextStyle(fontSize: 12.5, color: Color(0xFF6A7685)),
                    ),
                  ),
                  Expanded(
                      child: Divider(
                          color: AppColors.line, thickness: 1)),
                ],
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: _socialButton(
                      icon: Icons.g_mobiledata_rounded,
                      color: const Color(0xFFDB4437),
                      size: 36,
                      label: 'Google',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _socialButton(
                      icon: Icons.facebook,
                      color: const Color(0xFF1877F2),
                      size: 26,
                      label: 'Facebook',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _socialButton(
                      icon: Icons.apple,
                      color: Colors.black,
                      size: 28,
                      label: 'Apple',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 48),
              Center(
                child: GestureDetector(
                  onTap: () => Navigator.of(context)
                      .pushReplacementNamed(Routes.register),
                  child: const Text.rich(
                    TextSpan(
                      text: "Don't have an account?  ",
                      style: TextStyle(fontSize: 13, color: Color(0xFF6A7685)),
                      children: [
                        TextSpan(
                          text: 'Sign Up',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.navy,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(fontSize: 14, color: AppColors.navy),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 14, color: AppColors.mist),
        prefixIcon: Icon(icon, size: 22, color: AppColors.navy),
        suffixIcon: suffix,
        filled: true,
        fillColor: const Color(0xFFF5F6F8),
        contentPadding: const EdgeInsets.symmetric(vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.navy, width: 1.2),
        ),
      ),
    );
  }

  Widget _socialButton({
    required IconData icon,
    required Color color,
    required double size,
    required String label,
  }) {
    return Material(
      color: const Color(0xFFF5F6F8),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showSoon('$label login is not available yet.'),
        child: SizedBox(
          height: 52,
          child: Center(child: Icon(icon, size: size, color: color)),
        ),
      ),
    );
  }
}
