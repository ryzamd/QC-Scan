class ScanException implements Exception {
  final String message;

  ScanException(this.message);

  @override
  String toString() => message;
}

class MaterialNotFoundException implements Exception {
  final String barcode;

  MaterialNotFoundException(this.barcode);

  @override
  String toString() => 'No material found for barcode: $barcode';
}

class ProcessingException implements Exception {
  final String message;

  ProcessingException(this.message);

  @override
  String toString() => message;
}

class CameraException implements Exception {
  final String errorCode;
  final String message;

  CameraException(this.errorCode, this.message);

  @override
  String toString() => '[$errorCode]: $message';
}