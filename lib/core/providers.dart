import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'database/database_service.dart';
import 'database/inventory_repository.dart';

/// Global provider for the repository (lazily initialized DB).
final databaseServiceProvider = Provider((ref) {
  final service = DatabaseService.instance;
  ref.onDispose(service.close);
  return service;
});

final repositoryProvider = Provider((ref) {
  return InventoryRepository(ref.watch(databaseServiceProvider));
});

/// Persisted user preferences.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('overridden in main()'),
);

const _kThemeModePref = 'themeMode';
const _kLocalePref = 'locale';

/// Theme brightness (dark/light) state.
final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(() {
  return ThemeModeNotifier();
});

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    final name = ref.watch(sharedPreferencesProvider).getString(_kThemeModePref);
    return ThemeMode.values.firstWhere(
      (m) => m.name == name,
      orElse: () => ThemeMode.dark,
    );
  }

  void set(ThemeMode mode) {
    state = mode;
    ref.read(sharedPreferencesProvider).setString(_kThemeModePref, mode.name);
  }

  void toggle() {
    set(state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);
  }
}

/// Locale (en/ar) state.
final localeProvider = NotifierProvider<LocaleNotifier, Locale>(() {
  return LocaleNotifier();
});

class LocaleNotifier extends Notifier<Locale> {
  @override
  Locale build() {
    final code =
        ref.watch(sharedPreferencesProvider).getString(_kLocalePref) ?? 'en';
    return Locale(code);
  }

  void set(Locale locale) {
    state = locale;
    ref
        .read(sharedPreferencesProvider)
        .setString(_kLocalePref, locale.languageCode);
  }
}