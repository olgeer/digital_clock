// import 'dart:io';

// import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

// void showToast(String msg,
//     {int showInSec = 2,
//     ToastGravity gravity = ToastGravity.BOTTOM,
//     double fontSize = 16.0,
//     bool debugMode = true}) {
//   if(Platform.isAndroid || Platform.isIOS) {
//     Fluttertoast.showToast(
//       msg: msg,
//       toastLength: Toast.LENGTH_SHORT,
//       gravity: gravity,
//       timeInSecForIosWeb: showInSec,
//       fontSize: fontSize,
// //      backgroundColor: Colors.white,
// //      textColor: Colors.black
//     );
//   }
//   if (debugMode)logger.fine(msg);
// }

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
