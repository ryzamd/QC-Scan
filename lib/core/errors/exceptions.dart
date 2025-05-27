class ServerException implements Exception {
  final String message;

  ServerException(this.message);
}

class CacheException implements Exception {
  final String message;

  CacheException(this.message);
}

class AuthException implements Exception {
  final String message;

  AuthException(this.message);
}

class NetWorkException implements Exception {
  final String message;

  NetWorkException(this.message);
}