import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'i_repo_pref.dart';

/// This is the concrete implementation of [IRepoPref].
/// Its only job is to talk directly to the SharedPreferences plugin.
class RepoPref implements IRepoPref {
  final SharedPreferences _prefs;
  final FlutterSecureStorage _secureStorage;

  // The SharedPreferences instance is passed in, not created here.
  RepoPref(this._prefs,this._secureStorage);

  /// A static factory for creating an initialized instance.
  /// Your service locator (like GetIt) should call this.
  static Future<RepoPref> create() async {
    // You can configure platform-specific options here if needed
    // AndroidOptions androidOptions = const AndroidOptions(
    //   encryptedSharedPreferences: true,
    // );
    final secureStorage = FlutterSecureStorage(/*aOptions: androidOptions*/);
    final prefs = await SharedPreferences.getInstance();
    return RepoPref(prefs,secureStorage) ;
  }

  @override
  bool getBool(String key, {bool defaultValue = false}) {
    return _prefs.getBool(key) ?? defaultValue;
  }

  @override
  Future<void> setBool(String key, bool value) async {
    await _prefs.setBool(key, value);
  }

  @override
  String? getString(String key) {
    return _prefs.getString(key);
  }

  @override
  Future<void> setString(String key, String value) async {
    await _prefs.setString(key, value);
  }

  @override
  Future<void> remove(String key) async {
    await _prefs.remove(key);
  }
  //Secure storage
  @override
  Future<bool> getBoolSecure(String key, {bool defaultValue = false}) async {
    final value = await _secureStorage.read(key: key);
    if (value == null) {
      return defaultValue;
    }
    // Convert the stored string back to a bool
    return value.toLowerCase() == 'true';
  }

  @override
  Future<void> setBoolSecure(String key, bool value) async {
    // Convert the bool to a string for storage
    await _secureStorage.write(key: key, value: value.toString());
  }

  @override
  Future<String?> getStringSecure(String key) async {
    return await _secureStorage.read(key: key);
  }

  @override
  Future<void> setStringSecure(String key, String value) async {
    await _secureStorage.write(key: key, value: value);
  }

  @override
  Future<void> removeSecure(String key) async {
    await _secureStorage.delete(key: key);
  }
}