import 'package:flutter_riverpod/legacy.dart';
import 'package:storagio/core/theme/p_theme.dart';
import 'package:storagio/core/theme/r_theme.dart';

class ThemeViewModel extends StateNotifier<ThemeModeType> {
  final ThemeRepository repo;

  ThemeViewModel(this.repo, ThemeModeType initialState) : super(initialState);

  Future<void> updateThemeFromString(String value) async {
    final mode = value == "Dark" ? ThemeModeType.dark : ThemeModeType.light;

    state = mode;
    await repo.saveTheme(mode);
  }
}
