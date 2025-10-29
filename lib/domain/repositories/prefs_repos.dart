import 'package:shared_preferences/shared_preferences.dart';
import '../../data/repositories/prefs_repo.dart' as repo_base;

class PrefsRepo implements repo_base.PreferenceRepositoryBase {
  // Use a lazy singleton to ensure we only have one SharedPreferences instance
  static SharedPreferences? _prefs;

  Future<SharedPreferences> _getPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  // Define constant keys to avoid typos
  static const String themeKey = 'app_theme';
  static const String firstLaunchKey = 'first_launch';

  @override
  Future<String?> getString(String key) async {
    final prefs = await _getPrefs();
    return prefs.getString(key);
  }

  @override
  Future<void> saveString(String key, String value) async {
    final prefs = await _getPrefs();
    await prefs.setString(key, value);
  }
  
  @override
  Future<bool> getBool(String key, {bool defaultValue = false}) async {
    final prefs = await _getPrefs();
    return prefs.getBool(key) ?? defaultValue;
  }
  
  @override
  Future<void> saveBool(String key, bool value) async {
    final prefs = await _getPrefs();
    await prefs.setBool(key, value);
  }

  @override
  Future<void> clearAll() async {
    final prefs = await _getPrefs();
    await prefs.clear();
  }
}