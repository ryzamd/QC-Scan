class ApiConstants {
  static const String baseUrl = 'http://192.168.6.141:7053/api/';
  
  static const String loginEndpoint = 'login/auth/login';
  
  static const String homeListEndpoint = 'login/data_list/user_name';
  static const String checkCodeEndpoint = 'login/data_list/check_code';
  
  static const String saveQualityInspectionEndpoint = 'qc_scan/qc_int/NoFormal_save';
  static const String saveQC2DeductionEndpoint = 'qc_check/qc_check/Formal_save';

  static const String getListEndpoint = 'login/GetList';
  static String getListUrl(String date) => '$baseUrl$getListEndpoint?date=$date';
  
  static String get loginUrl => baseUrl + loginEndpoint;
  static String get homeListUrl => baseUrl + homeListEndpoint;
  static String get checkCodeUrl => baseUrl + checkCodeEndpoint;
  static String get saveQualityInspectionUrl => baseUrl + saveQualityInspectionEndpoint;
  static String get saveQC2DeductionUrl => baseUrl + saveQC2DeductionEndpoint;
}