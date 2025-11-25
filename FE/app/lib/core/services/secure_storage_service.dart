import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:book_tech/core/utils/app_logger.dart';

/// Service để lưu trữ dữ liệu nhạy cảm một cách an toàn
/// 
/// Sử dụng platform-specific secure storage:
/// - iOS: Keychain
/// - Android: EncryptedSharedPreferences
/// - Web: Web Crypto API
class SecureStorageService {
  static final SecureStorageService _instance = SecureStorageService._internal();
  
  factory SecureStorageService() => _instance;
  
  SecureStorageService._internal();

  late final FlutterSecureStorage _storage;
  
  bool _isInitialized = false;

  /// Initialize secure storage với platform-specific options
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      _storage = FlutterSecureStorage(
        aOptions: _getAndroidOptions(),
        iOptions: _getIOSOptions(),
        webOptions: _getWebOptions(),
      );
      
      _isInitialized = true;
      log.i('SecureStorageService initialized', 'SecureStorage');
    } catch (e) {
      log.e('Failed to initialize SecureStorageService', e, 'SecureStorage');
      rethrow;
    }
  }

  /// Android-specific options
  AndroidOptions _getAndroidOptions() {
    return const AndroidOptions(
      // Sử dụng EncryptedSharedPreferences (Android API 23+)
      encryptedSharedPreferences: true,
      // Reset khi cần thiết
      resetOnError: true,
    );
  }

  /// iOS-specific options
  IOSOptions _getIOSOptions() {
    return const IOSOptions(
      // Cho phép truy cập khi device unlocked
      accessibility: KeychainAccessibility.first_unlock,
      // Đồng bộ với iCloud Keychain (optional)
      synchronizable: false,
    );
  }

  /// Web-specific options
  WebOptions _getWebOptions() {
    return WebOptions(
      dbName: 'book_tech_secure_storage',
      publicKey: 'book_tech_public_key',
    );
  }

  /// Kiểm tra service đã được initialize chưa
  void _checkInitialized() {
    if (!_isInitialized) {
      throw StateError(
        'SecureStorageService chưa được initialize. '
        'Gọi initialize() trước khi sử dụng.',
      );
    }
  }

  /// Lưu giá trị string
  /// 
  /// Throws [Exception] nếu lưu thất bại
  Future<void> write({
    required String key,
    required String value,
  }) async {
    _checkInitialized();
    
    try {
      await _storage.write(key: key, value: value);
      log.d('Saved value for key: $key', 'SecureStorage');
    } catch (e) {
      log.e('Failed to write secure storage', e, 'SecureStorage');
      throw Exception('Failed to save secure data for key: $key');
    }
  }

  /// Đọc giá trị string
  /// 
  /// Returns null nếu key không tồn tại
  Future<String?> read({required String key}) async {
    _checkInitialized();
    
    try {
      final value = await _storage.read(key: key);
      if (value != null) {
        log.d('Read value for key: $key', 'SecureStorage');
      } else {
        log.d('No value found for key: $key', 'SecureStorage');
      }
      return value;
    } catch (e) {
      log.e('Failed to read secure storage', e, 'SecureStorage');
      return null;
    }
  }

  /// Xóa giá trị theo key
  Future<void> delete({required String key}) async {
    _checkInitialized();
    
    try {
      await _storage.delete(key: key);
      log.d('Deleted value for key: $key', 'SecureStorage');
    } catch (e) {
      log.e('Failed to delete from secure storage', e, 'SecureStorage');
      throw Exception('Failed to delete secure data for key: $key');
    }
  }

  /// Xóa tất cả dữ liệu
  /// 
  /// ⚠️ Sử dụng cẩn thận - xóa toàn bộ secure storage
  Future<void> deleteAll() async {
    _checkInitialized();
    
    try {
      await _storage.deleteAll();
      log.i('Cleared all secure storage', 'SecureStorage');
    } catch (e) {
      log.e('Failed to clear secure storage', e, 'SecureStorage');
      throw Exception('Failed to clear all secure data');
    }
  }

  /// Kiểm tra key có tồn tại không
  Future<bool> containsKey({required String key}) async {
    _checkInitialized();
    
    try {
      return await _storage.containsKey(key: key);
    } catch (e) {
      log.e('Failed to check key existence', e, 'SecureStorage');
      return false;
    }
  }

  /// Đọc tất cả keys và values
  /// 
  /// Chỉ dùng cho debugging, không nên dùng trong production
  Future<Map<String, String>> readAll() async {
    _checkInitialized();
    
    try {
      return await _storage.readAll();
    } catch (e) {
      log.e('Failed to read all from secure storage', e, 'SecureStorage');
      return {};
    }
  }

  /// Lưu multiple key-value pairs
  Future<void> writeMultiple(Map<String, String> data) async {
    _checkInitialized();
    
    try {
      for (final entry in data.entries) {
        await _storage.write(key: entry.key, value: entry.value);
      }
      log.d('Saved ${data.length} items to secure storage', 'SecureStorage');
    } catch (e) {
      log.e('Failed to write multiple items', e, 'SecureStorage');
      throw Exception('Failed to save multiple secure data items');
    }
  }
}

/// Extension để dễ dàng access singleton
extension SecureStorageX on SecureStorageService {
  /// Quick access methods cho tokens
  
  Future<void> saveAccessToken(String token) async {
    await write(key: 'access_token', value: token);
  }

  Future<String?> getAccessToken() async {
    return await read(key: 'access_token');
  }

  Future<void> saveRefreshToken(String token) async {
    await write(key: 'refresh_token', value: token);
  }

  Future<String?> getRefreshToken() async {
    return await read(key: 'refresh_token');
  }

  Future<void> clearTokens() async {
    await delete(key: 'access_token');
    await delete(key: 'refresh_token');
  }
}
