import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Single SharedPreferences instance for the whole app (DI-3): it is loaded
/// once in `main()` and injected here, so widgets and repositories never call
/// `SharedPreferences.getInstance()` themselves.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError(
    'sharedPreferencesProvider must be overridden in main()',
  ),
);
