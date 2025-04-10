import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const String _accessTokenKey = 'access_token';
  static const String _tokenExpiryKey = 'token_expiry';
  static const String _userIdKey = 'user_id';
  static const String _userDataKey = 'user_data';

  Future<void> saveAccessTokenAsync(String token) async {
    await _storage.write(key: _accessTokenKey, value: token);
  }

  Future<String?> getAccessTokenAsync() async {
    return await _storage.read(key: _accessTokenKey);
  }
  
  Future<void> saveTokenExpiryAsync(DateTime expiry) async {
    await _storage.write(key: _tokenExpiryKey, value: expiry.toIso8601String());
  }

  Future<DateTime?> getTokenExpiryAsync() async {
    final expiryString = await _storage.read(key: _tokenExpiryKey);
    if (expiryString != null) {
      return DateTime.parse(expiryString);
    }
    return null;
  }
  
  Future<void> saveUserIdAsync(String userId) async {
    await _storage.write(key: _userIdKey, value: userId);
  }
  
  Future<String?> getUserId() async {
    return await _storage.read(key: _userIdKey);
  }
  
  Future<void> saveUserDataAsync(String userData) async {
    await _storage.write(key: _userDataKey, value: userData);
  }
  
  Future<String?> getUserDataAsync() async {
    return await _storage.read(key: _userDataKey);
  }

  Future<void> clearAllDataAsync() async {
    await _storage.deleteAll();
  }
  
  Future<bool> hasTokenAsync() async {
    final token = await getAccessTokenAsync();
    return token != null && token.isNotEmpty;
  }
}