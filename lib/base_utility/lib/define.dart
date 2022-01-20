import 'package:cron/cron.dart';
import 'package:flutter/cupertino.dart';

typedef eventCall = Function(dynamic value);
typedef contextProc = Function(BuildContext context);
typedef actionCall = Function();

extension MatchExtension on Schedule {
  bool match(DateTime now) {
    if (seconds?.contains(now.second) == false) return false;
    if (minutes?.contains(now.minute) == false) return false;
    if (hours?.contains(now.hour) == false) return false;
    if (days?.contains(now.day) == false) return false;
    if (months?.contains(now.month) == false) return false;
    if (weekdays?.contains(now.weekday) == false) return false;
    return true;
  }
}

extension TranslateExtension on String {
  String tl({List<String>? args}) {
    String tmp = this;
    while (tmp.contains("{}") && !(args?.isEmpty ?? true)) {
      tmp = tmp.replaceFirst("{}", args!.removeAt(0));
    }
    return tmp;
  }
}

///按一定时间间隔重复执行processer方法，方法调用后立即执行processer方法，如millisecondInterval不为null则按此间隔继续执行
void intervalAction(actionCall? processer, {List<int>? millisecondInterval}) {
  if (processer != null) {
    processer();
    if ((millisecondInterval?.isNotEmpty ?? false) == true) {
      for (int i in millisecondInterval!) {
        Future.delayed(Duration(milliseconds: i), processer);
      }
    }
  }
}

/// Do nothing function
void DNT() {}