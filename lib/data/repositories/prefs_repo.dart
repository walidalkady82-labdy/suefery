abstract class PreferenceRepositoryBase {
  Future<void> saveString(String key, String value);
  Future<String?> getString(String key);
  
  Future<void> saveBool(String key, bool value);
  Future<bool> getBool(String key, {bool defaultValue = false});

  Future<void> clearAll();
}