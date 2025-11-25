// Stub implementation for dart:io on web platform
// This file provides placeholder implementations when dart:io is not available

class File {
  final String path;
  
  File(this.path);
  
  // Add stub methods that might be needed
  bool existsSync() => false;
  
  Future<bool> exists() async => false;
  
  Future<List<int>> readAsBytes() async => throw UnsupportedError(
    'File operations are not supported on web platform'
  );
  
  Future<String> readAsString() async => throw UnsupportedError(
    'File operations are not supported on web platform'
  );
}
