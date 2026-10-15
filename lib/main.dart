import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'pages/homepage.dart';
import 'pages/onboarding_pages.dart';

import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  // Ensure Flutter bindings are ready before using native plugins (Firebase) in async main
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize Firebase with the configuration for the current platform
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // ProviderScope is required by Riverpod so all widgets can access providers
  runApp(const ProviderScope(child: MyApp()));
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
      home: const RootGate(),
    );
  }
}

/// Decides whether to show the onboarding walkthrough or the main app.
class RootGate extends StatefulWidget {
  const RootGate({super.key});

  @override
  State<RootGate> createState() => _RootGateState();
}

class _RootGateState extends State<RootGate> {
  bool? _onboardingDone; // null = still loading

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((prefs) {
      setState(() {
        _onboardingDone = prefs.getBool(kOnboardingDoneKey) ?? false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_onboardingDone == null) {
      // Simple splash while reading the flag.
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    // Show the walkthrough only on the first launch.
    return _onboardingDone! ? const HomepagePages() : const OnboardingPages();
  }
}
