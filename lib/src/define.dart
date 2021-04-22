import 'package:cron/cron.dart';
import 'package:flutter/cupertino.dart';

typedef eventCall = Function(dynamic value);
typedef contextProc = Function(BuildContext context);
typedef actionCall = Function();


extension MatchExtension on Schedule {
  bool match(DateTime now) {
    if (this?.seconds?.contains(now.second) == false) return false;
    if (this?.minutes?.contains(now.minute) == false) return false;
    if (this?.hours?.contains(now.hour) == false) return false;
    if (this?.days?.contains(now.day) == false) return false;
    if (this?.months?.contains(now.month) == false) return false;
    if (this?.weekdays?.contains(now.weekday) == false) return false;
    return true;
  }
}

extension TranslateExtension on String {
  String tl({List<String> args}) {
    String tmp = this;
    while (tmp.contains("{}") && !(args?.isEmpty ?? true)) {
      tmp = tmp.replaceFirst("{}", args.removeAt(0));
    }
    return tmp;
  }
}