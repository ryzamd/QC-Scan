import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class StringKey {
  static const String invalidCredentialsMessage = "invalidCredentialsMessage";
  static const String serverErrorMessage = "serverErrorMessage";
  static const String networkErrorMessage = "networkErrorMessage";
  static const String loginSuccessMessage = "loginSuccessMessage";
  static const String materialNotFound = "materialNotFound";
  static const String cameraErrorMessage = "cameraErrorMessage";
  static const String connectionTimeoutMessage = "connectionTimeoutMessage";
  static const String cannotConnectToServerMessage = "cannotConnectToServerMessage";
  static const String networkErrorWithDetailsMessage = "networkErrorWithDetailsMessage";
  static const String serverErrorWithCodeMessage = "serverErrorWithCodeMessage";
  static const String invalidTokenMessage = "invalidTokenMessage";
  static const String failedToGetMaterialInfoMessage = "failedToGetMaterialInfoMessage";
  static const String unknownErrorMessage = "unknownErrorMessage";
  static const String eitherDeductionOrReasonsMessage = "eitherDeductionOrReasonsMessage";
  static const String reasonsRequiredMessage = "reasonsRequiredMessage";
  static const String saveFailedMessage = "saveFailedMessage";
  static const String failedToGetDeductionReasons = "failedToGetDeductionReasons";
  static const String failedToLoadProcessingItemsMessage = "failedToLoadProcessingItemsMessage";
  static const String errorFetchingProcessingItemsMessage = "errorFetchingProcessingItemsMessage";
  static const String errorProcessingDeductionMessage = "errorProcessingDeductionMessage";
  static const String quantityExceedsLimitMessage = "quantityExceedsLimitMessage";
  static const String deductionExceedsQuantityMessage = "deductionExceedsQuantityMessage";
  static const String deductionMustBeGreaterThanZeroMessage = "deductionMustBeGreaterThanZeroMessage";
  static const String errorLoadingDataMessage = "errorLoadingDataMessage";
  static const String errorRefreshingDataMessage = "errorRefreshingDataMessage";
  static const String noInternetConnectionMessage = "noInternetConnectionMessage";
  static const String itemNotFound = "itemNotFound";
  static const String deductionSuccessMessage = "deductionSuccessMessage";
  static const String alreadyQuantityInspectedMessage = "alreadyQuantityInspectedMessage";
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

      case StringKey.connectionTimeoutMessage:
        return l10n.connectionTimeoutMessage;

      case StringKey.cannotConnectToServerMessage:
        return l10n.cannotConnectToServerMessage;

      case StringKey.invalidTokenMessage:
        return l10n.invalidTokenMessage;

      case StringKey.unknownErrorMessage:
        return l10n.unknownErrorMessage;

      case StringKey.eitherDeductionOrReasonsMessage:
        return l10n.eitherDeductionOrReasonsMessage;

      case StringKey.reasonsRequiredMessage:
        return l10n.reasonsRequiredMessage;

      case StringKey.saveFailedMessage:
        return l10n.saveFailedMessage;

      case StringKey.failedToGetDeductionReasons:
        return l10n.failedToGetDeductionReasons;

      case StringKey.failedToLoadProcessingItemsMessage:
        return l10n.failedToLoadProcessingItemsMessage;

      case StringKey.errorFetchingProcessingItemsMessage:
        return l10n.errorFetchingProcessingItemsMessage;

      case StringKey.errorProcessingDeductionMessage:
        return l10n.errorProcessingDeductionMessage;

      case StringKey.quantityExceedsLimitMessage:
        return l10n.quantityExceedsLimitMessage;

      case StringKey.deductionExceedsQuantityMessage:
        return l10n.deductionExceedsQuantityMessage;

      case StringKey.deductionMustBeGreaterThanZeroMessage:
        return l10n.deductionMustBeGreaterThanZeroMessage;

      case StringKey.errorLoadingDataMessage:
        return l10n.errorLoadingDataMessage(args?["details"] ?? "");

      case StringKey.errorRefreshingDataMessage:
        return l10n.errorRefreshingDataMessage(args?["details"] ?? "");

      case StringKey.itemNotFound:
        return l10n.itemNotFound;

      case StringKey.deductionSuccessMessage:
        return l10n.deductionSuccessMessage;

      case StringKey.alreadyQuantityInspectedMessage:
        return l10n.alreadyQuantityInspectedMessage;

      default:
        return 'Cannot find the key $key';
    }
  }
}
