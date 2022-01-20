import 'package:flutter_easyloading/flutter_easyloading.dart';

void showToast(String msg,
    {int showInSec = 3,
    EasyLoadingToastPosition toastPosition = EasyLoadingToastPosition.bottom,
    EasyLoadingMaskType maskType = EasyLoadingMaskType.clear,
    bool debugMode = true}) {
  EasyLoading.showToast(msg,
      duration: Duration(seconds: showInSec),
      toastPosition: toastPosition,
      maskType: maskType);
  // if (debugMode) logger.fine( msg);
}
