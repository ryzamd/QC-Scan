import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class StringKey {
  static const String invalidCredentialsMessage = "invalidCredentialsMessage";
  static const String serverErrorMessage = "serverErrorMessage";
  static const String networkErrorMessage = "networkErrorMessage";
  static const String loginSuccessMessage = "loginSuccessMessage";
  static const String materialNotFound = "materialNotFound";
  static const String cameraErrorMessage = "cameraErrorMessage";
}

class TranslateKey {
  static String getStringKey(AppLocalizations l10n, String key, {Map<String, dynamic>? args,}) {
    switch (key) {
      case StringKey.invalidCredentialsMessage:
        return l10n.invalidCredentialsMessage;
      case StringKey.serverErrorMessage:
        return l10n.serverErrorMessage;
      case StringKey.networkErrorMessage:
        return l10n.networkErrorMessage;
      case StringKey.loginSuccessMessage:
        return l10n.loginSuccessMessage;
      case StringKey.materialNotFound:
        return l10n.materialNotFound;
      case StringKey.cameraErrorMessage:
        if (args != null && args.containsKey("error")) {
          return l10n.cameraErrorMessage(args["error"]);
        }
        return l10n.cameraErrorMessage("");

      default:
        return 'Cannot find the key $key';
    }
  }
}
