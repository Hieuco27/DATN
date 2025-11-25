import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:book_tech/core/services/secure_storage_service.dart';
import 'package:book_tech/core/utils/app_logger.dart';
import '../models/account_model.dart';

abstract class LocalStorageDataSource {
  Future<void> saveTokens(String accessToken, String refreshToken);
  Future<String?> getAccessToken();
  Future<String?> getRefreshToken();
  Future<void> saveAccount(AccountModel account);
  Future<AccountModel?> getAccount();
  Future<bool> isLoggedIn();
  Future<void> clearAllData();
  Future<void> updateAccessToken(String newAccessToken);
}

class LocalStorageDataSourceImpl implements LocalStorageDataSource {
  // Keys cho SecureStorage (sensitive data)
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  
  // Keys cho SharedPreferences (non-sensitive data)
  static const String _accountKey = 'account_data';
  static const String _isLoggedInKey = 'is_logged_in';
  static const String _migrationKey = 'tokens_migrated_to_secure_storage';
  
  final SecureStorageService _secureStorage;
  
  LocalStorageDataSourceImpl({SecureStorageService? secureStorage})
      : _secureStorage = secureStorage ?? SecureStorageService();
  
  /// Initialize và migrate tokens cũ nếu cần
  Future<void> initialize() async {
    try {
      await _secureStorage.initialize();
      await _migrateTokensIfNeeded();
      log.i('LocalStorageDataSource initialized', 'LocalStorage');
    } catch (e) {
      log.e('Failed to initialize LocalStorageDataSource', e, 'LocalStorage');
    }
  }

  @override
  Future<void> saveTokens(String accessToken, String refreshToken) async {
    try {
      // ✅ Lưu tokens vào SecureStorage (encrypted)
      await _secureStorage.write(key: _accessTokenKey, value: accessToken);
      await _secureStorage.write(key: _refreshTokenKey, value: refreshToken);
      
      // ✅ Lưu login flag vào SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_isLoggedInKey, true);
      
      log.d('Tokens saved to secure storage', 'LocalStorage');
    } catch (e) {
      log.e('Failed to save tokens', e, 'LocalStorage');
      throw Exception('Failed to save authentication tokens');
    }
  }

  @override
  Future<String?> getAccessToken() async {
    try {
      // ✅ Đọc từ SecureStorage
      final token = await _secureStorage.read(key: _accessTokenKey);
      if (token != null) {
        log.d(
          'Access token: ***${token.substring(token.length > 6 ? token.length - 6 : 0)}',
          'LocalStorage',
        );
      }
      return token;
    } catch (e) {
      log.e('Failed to get access token', e, 'LocalStorage');
      return null;
    }
  }

  @override
  Future<String?> getRefreshToken() async {
    try {
      // ✅ Đọc từ SecureStorage
      final token = await _secureStorage.read(key: _refreshTokenKey);
      if (token != null) {
        log.d(
          'Refresh token: ***${token.substring(token.length > 6 ? token.length - 6 : 0)}',
          'LocalStorage',
        );
      }
      return token;
    } catch (e) {
      log.e('Failed to get refresh token', e, 'LocalStorage');
      return null;
    }
  }

  @override
  Future<void> saveAccount(AccountModel account) async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final accountJson = json.encode(account.toJson());
      await prefs.setString(_accountKey, accountJson);
    } catch (e) {
      throw Exception('Failed to save account data');
    }
  }

  @override
  Future<AccountModel?> getAccount() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final accountJson = prefs.getString(_accountKey);

      if (accountJson != null) {
        final Map<String, dynamic> accountData = json.decode(accountJson);
        final account = AccountModel.fromJson(accountData);
        return account;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = await getAccessToken();
    final isLoggedInFlag = prefs.getBool(_isLoggedInKey) ?? false;
    final result =
        accessToken != null && accessToken.isNotEmpty && isLoggedInFlag;
    return result;
  }

  @override
  Future<void> clearAllData() async {
    try {
      // ✅ Xóa tokens từ SecureStorage
      await _secureStorage.delete(key: _accessTokenKey);
      await _secureStorage.delete(key: _refreshTokenKey);
      
      // ✅ Xóa non-sensitive data từ SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await Future.wait([
        prefs.remove(_accountKey),
        prefs.remove(_isLoggedInKey),
      ]);
      
      log.i('All data cleared', 'LocalStorage');
    } catch (e) {
      log.e('Failed to clear all data', e, 'LocalStorage');
      throw Exception('Failed to clear user data');
    }
  }

  @override
  Future<void> updateAccessToken(String newAccessToken) async {
    try {
      // ✅ Update token trong SecureStorage
      await _secureStorage.write(key: _accessTokenKey, value: newAccessToken);
      log.d('Access token updated', 'LocalStorage');
    } catch (e) {
      log.e('Failed to update access token', e, 'LocalStorage');
      throw Exception('Failed to update access token');
    }
  }

  // Helper method để kiểm tra token expiration
  Future<bool> isTokenExpired() async {
    final token = await getAccessToken();
    if (token == null) return true;

    try {
      // Giải mã JWT để kiểm tra expiration
      final parts = token.split('.');
      if (parts.length != 3) return true;

      final payload = json.decode(utf8.decode(base64Url.decode(parts[1])));
      final exp = payload['exp'] as int?;

      if (exp == null) return true;

      final expirationTime = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      return DateTime.now().isAfter(expirationTime);
    } catch (e) {
      log.e('Failed to check token expiration', e, 'LocalStorage');
      return true;
    }
  }
  
  /// Migrate tokens từ SharedPreferences sang SecureStorage
  /// 
  /// Chỉ chạy 1 lần khi user upgrade app
  Future<void> _migrateTokensIfNeeded() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Kiểm tra đã migrate chưa
      final migrated = prefs.getBool(_migrationKey) ?? false;
      if (migrated) {
        log.d('Tokens already migrated', 'LocalStorage');
        return;
      }
      
      // Đọc tokens cũ từ SharedPreferences
      final oldAccessToken = prefs.getString(_accessTokenKey);
      final oldRefreshToken = prefs.getString(_refreshTokenKey);
      
      if (oldAccessToken != null && oldRefreshToken != null) {
        log.i('Migrating tokens to secure storage...', 'LocalStorage');
        
        // Lưu vào SecureStorage
        await _secureStorage.write(key: _accessTokenKey, value: oldAccessToken);
        await _secureStorage.write(key: _refreshTokenKey, value: oldRefreshToken);
        
        // Xóa tokens cũ từ SharedPreferences
        await prefs.remove(_accessTokenKey);
        await prefs.remove(_refreshTokenKey);
        
        // Đánh dấu đã migrate
        await prefs.setBool(_migrationKey, true);
        
        log.i('Tokens migrated successfully', 'LocalStorage');
      } else {
        // Không có tokens cũ, đánh dấu đã migrate luôn
        await prefs.setBool(_migrationKey, true);
        log.d('No old tokens to migrate', 'LocalStorage');
      }
    } catch (e) {
      log.e('Failed to migrate tokens', e, 'LocalStorage');
      // Không throw exception để không block app startup
    }
  }
}
