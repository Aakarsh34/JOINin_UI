import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Reactive holder for the user's preferred [ThemeMode].
///
/// The choice is persisted across launches via [FlutterSecureStorage] so the
/// app remembers light/dark/system as soon as it starts (before any provider
/// further down the tree has a chance to read it). The first frame is rendered
/// in dark mode while we hydrate from storage; the swap then animates through
/// [MaterialApp]'s themeAnimationDuration on the first frame the value lands.
class ThemeState extends ChangeNotifier {
  ThemeState();

  static const _storageKey = 'theme_mode';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  ThemeMode _mode = ThemeMode.dark;
  bool _hydrated = false;

  ThemeMode get mode => _mode;
  bool get hydrated => _hydrated;

  /// True when the current effective theme is dark (taking the platform
  /// brightness into account when [mode] is [ThemeMode.system]).
  bool isEffectivelyDark(BuildContext context) {
    switch (_mode) {
      case ThemeMode.light:
        return false;
      case ThemeMode.dark:
        return true;
      case ThemeMode.system:
        return MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    }
  }

  Future<void> bootstrap() async {
    try {
      final raw = await _storage.read(key: _storageKey);
      switch (raw) {
        case 'light':
          _mode = ThemeMode.light;
        case 'dark':
          _mode = ThemeMode.dark;
        case 'system':
          _mode = ThemeMode.system;
        default:
          _mode = ThemeMode.dark;
      }
    } catch (_) {
      _mode = ThemeMode.dark;
    } finally {
      _hydrated = true;
      notifyListeners();
    }
  }

  Future<void> setMode(ThemeMode mode) async {
    if (_mode == mode) return;
    _mode = mode;
    notifyListeners();
    try {
      await _storage.write(key: _storageKey, value: mode.name);
    } catch (_) {
      // Persistence is best-effort — UI already updated.
    }
  }

  /// Convenience used by a single-tap toggle.
  ///
  /// If currently following the system, snaps to the *opposite* of whatever
  /// the system is, so the tap always produces a visible change.
  Future<void> toggle(BuildContext context) async {
    final wasDark = isEffectivelyDark(context);
    await setMode(wasDark ? ThemeMode.light : ThemeMode.dark);
  }
}
