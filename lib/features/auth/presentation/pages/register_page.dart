import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di.dart';
import '../../../../routes.dart';
import '../../../../theme/app_colors.dart';
import '../../domain/auth_validators.dart';
import '../providers/auth_providers.dart';

/// Registration page. Creates a Firebase Auth account plus its Firestore
/// profile through AuthRepository, then marks onboarding as done.
class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscure = true;
  bool _obscureConfirm = true;
  String? _usernameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmError;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    FocusScope.of(context).unfocus();
    final usernameError = AuthValidators.username(_usernameController.text);
    final emailError = AuthValidators.email(_emailController.text);
    final passwordError = AuthValidators.password(_passwordController.text);
    final confirmError = AuthValidators.confirmPassword(
      _confirmController.text,
      _passwordController.text,
    );
    setState(() {
      _usernameError = usernameError;
      _emailError = emailError;
      _passwordError = passwordError;
      _confirmError = confirmError;
    });
    if (usernameError != null ||
        emailError != null ||
        passwordError != null ||
        confirmError != null) {
      return;
    }

    final error = await ref.read(authControllerProvider.notifier).register(
          username: _usernameController.text,
          email: _emailController.text,
          password: _passwordController.text,
        );
    if (!mounted) return;
    if (error != null) {
      _showSoon(error);
      return;
    }
    await ref.read(onboardingRepositoryProvider).setDone(done: true);
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(Routes.home);
  }

  Future<void> _social(Future<String?> Function() action) async {
    FocusScope.of(context).unfocus();
    final error = await action();
    if (!mounted) return;
    if (error != null) {
      _showSoon(error);
      return;
    }
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
    final loading = ref.watch(authControllerProvider).isLoading;
    final palette = context.palette;
    return Scaffold(
      backgroundColor: palette.paper,
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
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 20,
                  color: palette.navy,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Hello! Register to get\nstarted',
                style: TextStyle(
                  fontSize: 28,
                  height: 1.25,
                  fontWeight: FontWeight.w700,
                  color: palette.navy,
                ),
              ),
              const SizedBox(height: 36),
              _field(
                controller: _usernameController,
                hint: 'Username',
                icon: Icons.person_outline_rounded,
                errorText: _usernameError,
              ),
              const SizedBox(height: 14),
              _field(
                controller: _emailController,
                hint: 'Email',
                icon: Icons.mail_outline_rounded,
                keyboardType: TextInputType.emailAddress,
                errorText: _emailError,
              ),
              const SizedBox(height: 14),
              _field(
                controller: _passwordController,
                hint: 'Password',
                icon: Icons.lock_outline_rounded,
                obscure: _obscure,
                errorText: _passwordError,
                suffix: IconButton(
                  onPressed: () => setState(() => _obscure = !_obscure),
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 20,
                    color: palette.mist,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              _field(
                controller: _confirmController,
                hint: 'Confirm Password',
                icon: Icons.lock_outline_rounded,
                obscure: _obscureConfirm,
                errorText: _confirmError,
                suffix: IconButton(
                  onPressed: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                  icon: Icon(
                    _obscureConfirm
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 20,
                    color: palette.mist,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: loading ? null : _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: palette.navy,
                    foregroundColor: palette.paper,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: loading
                      ? SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: palette.paper,
                          ),
                        )
                      : const Text(
                          'Register',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                ),
              ),
              const SizedBox(height: 36),
              Row(
                children: [
                  Expanded(
                      child: Divider(
                          color: palette.line, thickness: 1)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Text(
                      'Or Register with',
                      style:
                          TextStyle(fontSize: 12.5, color: palette.mist),
                    ),
                  ),
                  Expanded(
                      child: Divider(
                          color: palette.line, thickness: 1)),
                ],
              ),
              const SizedBox(height: 22),
              _socialButton(
                onTap: loading
                    ? null
                    : () => _social(ref
                        .read(authControllerProvider.notifier)
                        .signInWithGoogle),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.g_mobiledata_rounded,
                      size: 36,
                      color: Color(0xFFDB4437),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Continue with Google',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: palette.navy,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),
              Center(
                child: GestureDetector(
                  onTap: () => Navigator.of(context)
                      .pushReplacementNamed(Routes.login),
                  child: Text.rich(
                    TextSpan(
                      text: "Already have an account?  ",
                      style: TextStyle(fontSize: 13, color: palette.mist),
                      children: [
                        TextSpan(
                          text: 'Login',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: palette.navy,
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
    TextInputType? keyboardType,
    String? errorText,
  }) {
    final palette = context.palette;
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: TextStyle(fontSize: 14, color: palette.navy),
      decoration: InputDecoration(
        errorText: errorText,
        hintText: hint,
        hintStyle: TextStyle(fontSize: 14, color: palette.mist),
        prefixIcon: Icon(icon, size: 22, color: palette.navy),
        suffixIcon: suffix,
        filled: true,
        fillColor: palette.fieldFill,
        contentPadding: const EdgeInsets.symmetric(vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: palette.navy, width: 1.2),
        ),
      ),
    );
  }

  Widget _socialButton({
    required Widget child,
    required VoidCallback? onTap,
  }) {
    return Material(
      color: context.palette.fieldFill,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: SizedBox(
          height: 52,
          child: Center(child: child),
        ),
      ),
    );
  }
}
