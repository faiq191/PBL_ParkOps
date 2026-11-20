import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../routes.dart';
import '../../../../theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

/// Shows [child] only to a signed-in user whose Firestore profile has
/// role == 'admin'. Everyone else sees a sign-in or access-denied screen.
/// This protects the screen only; Firestore rules must protect real data.
class AdminGuard extends ConsumerWidget {
  const AdminGuard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    return auth.when(
      loading: () => Scaffold(
        backgroundColor: context.palette.paper,
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const _Notice(
        icon: Icons.error_outline_rounded,
        title: 'Could not verify your account',
        message: 'Check your connection and try again.',
      ),
      data: (user) {
        debugPrint(
          'AdminGuard: email=${user?.email} role=${user?.role} '
          'isAdmin=${user?.isAdmin}',
        );
        if (user == null) {
          return _Notice(
            icon: Icons.lock_outline_rounded,
            title: 'Admin sign-in required',
            message: 'Sign in with an administrator account to continue.',
            actionLabel: 'Sign in',
            onAction: () => Navigator.of(context).pushReplacementNamed(
              Routes.login,
              arguments: Routes.admin,
            ),
          );
        }
        if (!user.isAdmin) {
          return _Notice(
            icon: Icons.block_rounded,
            title: 'Access denied',
            message: '${user.email} is not an administrator account.',
            actionLabel: 'Switch account',
            onAction: () async {
              final navigator = Navigator.of(context);
              await ref.read(authControllerProvider.notifier).signOut();
              navigator.pushReplacementNamed(
                Routes.login,
                arguments: Routes.admin,
              );
            },
          );
        }
        return child;
      },
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Scaffold(
      backgroundColor: palette.paper,
      appBar: AppBar(
        backgroundColor: palette.paper,
        elevation: 0,
        iconTheme: IconThemeData(color: palette.navy),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 56, color: palette.navy),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: palette.navy,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: palette.mist),
              ),
              if (actionLabel != null) ...[
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: onAction,
                  style: FilledButton.styleFrom(
                    backgroundColor: palette.navy,
                    foregroundColor: palette.paper,
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: Text(actionLabel!),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}