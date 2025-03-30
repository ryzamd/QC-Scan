/// Constants for hardware scanner keycodes
class KeycodeConstants {
  // Common scanner button keycodes - including the one from logs (73014444552)
  static const List<int> scannerKeyCodes = [120, 121, 122, 293, 294, 73014444552];
  
  // Specific key codes for various scanners
  static const int urovo = 120;
  static const int honeywell = 121;
  static const int zebra = 122;
  static const int keyEvent1 = 293;
  static const int keyEvent2 = 294;
  static const int keyEventFromLogs = 73014444552;
}