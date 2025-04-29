class ScanBlocHelper {
  
 static bool validateDeduction(double deduction, List<String>? reasons, bool isQC2User) {
    if (!isQC2User && deduction > 0 && (reasons == null || reasons.isEmpty)) {
      return false;
    }
    
    if (isQC2User && deduction <= 0 && (reasons == null || reasons.isEmpty)) {
      return false;
    }
    
    return true;
  }
}