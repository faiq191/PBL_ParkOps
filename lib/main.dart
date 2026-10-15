import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'core/providers.dart';
import 'features/onboarding/presentation/pages/onboarding_pages.dart';
import 'features/onboarding/presentation/providers/onboarding_providers.dart';
import 'features/parking/presentation/pages/homepage.dart';
import 'routes.dart';

import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  // Ensure Flutter bindings are ready before using native plugins (Firebase) in async main
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize Firebase with the configuration for the current platform
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // DI-3 fix: load SharedPreferences once here and expose it through a single
  // provider, so widgets never call SharedPreferences.getInstance() themselves.
  final prefs = await SharedPreferences.getInstance();
  // ProviderScope is required by Riverpod so all widgets can access providers
  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ParkOps',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      // All page-to-page navigation goes through named routes (see routes.dart)
      routes: Routes.all,
      home: const RootGate(),
    );
  }
}

/// Decides whether to show the onboarding walkthrough or the main app.
/// DV-2/DI-2 fix: reads the flag through OnboardingRepository via Riverpod
/// instead of calling SharedPreferences directly.
class RootGate extends ConsumerWidget {
  const RootGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // loading = still reading the flag
    final done = ref.watch(onboardingDoneProvider);
    return done.when(
      // Simple splash while reading the flag.
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      // Show the walkthrough only on the first launch.
      data: (done) => done ? const HomepagePages() : const OnboardingPages(),
      error: (e, _) =>
          const Scaffold(body: Center(child: Text('Failed to start ParkOps'))),
    );
  }
}
