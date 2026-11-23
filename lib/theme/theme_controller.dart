import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends ChangeNotifier {
  final SharedPreferences prefs;
  String _currentTheme;

  ThemeController(this.prefs)
    : _currentTheme = prefs.getString('app_theme') ?? 'System Default';

  String get currentTheme => _currentTheme;

  ThemeMode get themeMode {
    switch (_currentTheme) {
      case 'Light':
        return ThemeMode.light;
      case 'Dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  void updateTheme(String? newTheme) {
    if (newTheme == null || newTheme == _currentTheme) return;
    _currentTheme = newTheme;
    prefs.setString('app_theme', newTheme);
    notifyListeners();
  }
}
