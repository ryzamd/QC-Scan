// lib/core/constants/api_constants.dart
class ApiConstants {
  // Base URL for the API
  static const String baseUrl = 'http://192.168.6.141:7053/api/';
  
  // Auth endpoints
  static const String loginEndpoint = 'login/auth/login';
  
  // Data list endpoints
  static const String homeListEndpoint = 'login/data_list/user_name';
  static const String checkCodeEndpoint = 'login/data_list/check_code';
  
  // QC scan endpoints
  static const String saveQualityInspectionEndpoint = 'qc_scan/qc_int/NoFormal_save';
  
  // Full URLs
  static String get loginUrl => baseUrl + loginEndpoint;
  static String get homeListUrl => baseUrl + homeListEndpoint;
  static String get checkCodeUrl => baseUrl + checkCodeEndpoint;
  static String get saveQualityInspectionUrl => baseUrl + saveQualityInspectionEndpoint;
}