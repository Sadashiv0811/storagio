import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:storagio/core/theme/r_theme.dart';
import 'package:storagio/core/theme/vm_theme.dart';

enum ThemeModeType { light, dark }

final themeRepositoryProvider = Provider((ref) => ThemeRepository());

final themeProvider =
    StateNotifierProvider<ThemeViewModel, ThemeModeType>((ref) {
  final repo = ref.read(themeRepositoryProvider);
  return ThemeViewModel(repo, ThemeModeType.light);
});
