/// The abstract interface for the Preferences Repository.
/// This contract defines all raw read/write methods for key-value storage.
abstract class IRepoPref {
  /// Fetches a boolean value for a given [key].
  /// Returns [defaultValue] if the key is not found.
  bool getBool(String key, {bool defaultValue = false});

  /// Saves a boolean [value] for a given [key].
  Future<void> setBool(String key, bool value);

  /// Fetches a string value for a given [key].
  /// Returns `null` if the key is not found.
  String? getString(String key);

  /// Saves a string [value] for a given [key].
  Future<void> setString(String key, String value);

  /// Removes a key-value pair from storage.
  Future<void> remove(String key);

   //secure storage

  /// Fetches a boolean value for a given [key].
  /// Returns [defaultValue] if the key is not found.
  Future<bool> getBoolSecure(String key, {bool defaultValue = false});

  /// Saves a boolean [value] for a given [key].
  Future<void> setBoolSecure(String key, bool value);

  /// Fetches a string value for a given [key].
  /// Returns `null` if the key is not found.
  Future<String?> getStringSecure(String key);

  /// Saves a string [value] for a given [key].
  Future<void> setStringSecure(String key, String value);

  /// Removes a key-value pair from storage.
  Future<void> removeSecure(String key);
}