class ApiConfig {
  // Base URL của API Backend
  static const String baseUrl = 'http://10.0.2.2:8080'; // Android Emulator
  // static const String baseUrl = 'http://localhost:5000'; // iOS Simulator
  // static const String baseUrl = 'https://your-production-api.com'; // Production
  
  // API Endpoints
  static const String loginEndpoint = '/auth/login-reader';
  static const String registerInitEndpoint = '/auth/register-init';
  static const String registerVerifyEndpoint = '/auth/register-verify';
  static const String registerCompleteEndpoint = '/auth/register-complete';
  static const String fcmRegisterEndpoint = '/fcm/register';
  static const String fcmUnregisterEndpoint = '/fcm/unregister';
  
  // Timeouts
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
