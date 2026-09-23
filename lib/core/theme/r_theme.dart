import 'package:shared_preferences/shared_preferences.dart';
import 'package:storagio/core/theme/p_theme.dart';

class ThemeRepository {
  static const _key = 'theme_mode';

  Future<ThemeModeType> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool(_key) ?? false;
    return isDark ? ThemeModeType.dark : ThemeModeType.light;
  }

  Future<void> saveTheme(ThemeModeType mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, mode == ThemeModeType.dark);
  }
}