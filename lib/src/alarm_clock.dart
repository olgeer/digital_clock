import 'dart:io';

import 'define.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:logging/logging.dart';
import 'package:cron/cron.dart';
import 'sound.dart';
import 'vibrate.dart';
import 'lamp.dart';

class AlarmClock {
  Cron cron;
  ScheduledTask alarmTask;

  ///报时计划
  Schedule alarmSchedule;
  actionCall alarmAction;

  ///免打搅时段，取消报时声音
  Schedule slientSchedule;

  ///允许休眠时段
  Schedule sleepSchedule;
  actionCall sleepEnableAction;
  actionCall sleepDisableAction;

  ///允许震动开关
  bool enableVibrate;

  ///允许报时音开关
  bool enableAlarmSound;

  ///允许闪光灯开关
  bool enableFlashLamp;

  ///刻钟报时音文件
  dynamic quarterAlarmSound;
  int quarterSoundIdx;

  ///半点报时音文件
  dynamic halfAlarmSound;
  int halfSoundIdx;

  ///整点报时音文件
  dynamic oclockAlarmSound;
  int oclockSoundIdx;

  ///静音开关
  bool isSlient = false;

  String normalAlarmMessageTemplate = "现在是 {}";
  String anytimeTemplate = "{}点{}分";
  String halfPastTemplate = "{}点半";
  String oclockTemplate = "{}点正";
  String aQuarterTemplate = "{}点一刻";
  String threeQuarterTemplate = "{}点三刻";

  Map<String, Schedule> specialAlarms = Map<String, Schedule>();

  final Logger logger = Logger('AlarmClock');

  AlarmClock(
      {dynamic newSchedule,
      actionCall newAlarmAction,
      dynamic noSoundSchedule,
      dynamic noWakeLockSchedule,
      this.sleepEnableAction,
      this.sleepDisableAction,
      this.enableVibrate = true,
      this.enableAlarmSound = true,
      this.enableFlashLamp = true,
      this.quarterAlarmSound,
      this.halfAlarmSound,
      this.oclockAlarmSound}) {
    if (newSchedule != null) {
      if (newSchedule is Schedule) alarmSchedule = newSchedule;
      if (newSchedule is String) alarmSchedule = Schedule.parse(newSchedule);
    } else {
      alarmSchedule = Schedule.parse("* 0,15,30,45 * * * *");
    }
    alarmAction = newAlarmAction ?? alarm;
    cron = Cron();
    alarmTask = cron.schedule(alarmSchedule, alarmAction);

    if (noSoundSchedule != null) {
      if (noSoundSchedule is Schedule) slientSchedule = noSoundSchedule;
      if (noSoundSchedule is String)
        slientSchedule = Schedule.parse(noSoundSchedule);
    }

    if (noWakeLockSchedule != null) {
      if (noWakeLockSchedule is Schedule) sleepSchedule = noWakeLockSchedule;
      if (noWakeLockSchedule is String)
        sleepSchedule = Schedule.parse(noWakeLockSchedule);
    }
    setSleepState();

    if (enableVibrate) Vibrate.init();

    if (enableAlarmSound) Sound.init();

    if (enableFlashLamp) FlashLamp.init();

    initAsync();
  }

  void setSleepState(){
    if (sleepSchedule?.match(DateTime.now()) == false) {
      logger.fine("do wakelock");
      // if (sleepDisableAction != null) sleepDisableAction();
      sleepDisableAction?.call();
    } else {
      logger.fine("do not wakelock");
      // if (sleepEnableAction != null) sleepEnableAction();
      sleepEnableAction?.call();
    }
  }

  void initAsync() async {
    if (enableAlarmSound) {
      if (oclockAlarmSound != null)
        oclockSoundIdx = await Sound.loadSound(oclockAlarmSound);
      if (halfAlarmSound != null)
        halfSoundIdx = await Sound.loadSound(halfAlarmSound);
      if (quarterAlarmSound != null)
        quarterSoundIdx = await Sound.loadSound(quarterAlarmSound);
    }

    // Uri uriRes=Uri.parse("http://olgeer.3322.org:8888/justclock/iphone.mp3");
    // logger.severe(uriRes.origin+uriRes.path);
    // await sound.play(await sound.loadSound(uriRes));
  }

  set newAlarmAction(actionCall action) {
    alarmTask?.cancel();
    alarmAction = action ?? alarmAction;
    alarmTask = cron.schedule(alarmSchedule, alarmAction);
  }

  set newSchedule(Schedule s) {
    alarmTask?.cancel();
    alarmSchedule = s;
    alarmTask = cron.schedule(alarmSchedule, alarmAction);
  }

  set setSlient(bool b) {
    isSlient = b;
    FlashLamp.useLamp=!b;
    Vibrate.enableVibrate=!b;
    logger.fine("isSlient is $b");
  }

  Schedule get newSchedule => alarmSchedule;

  set noSoundSchedule(Schedule s) => slientSchedule = s;
  Schedule get noSoundSchedule => slientSchedule;

  set noWakeLockSchedule(Schedule s) {
    sleepSchedule = s;
    setSleepState();
  }

  Schedule get noWakeLockSchedule => sleepSchedule;

  String get alarmTemplate {
    String alarmTmp = normalAlarmMessageTemplate;
    if (specialAlarms.isNotEmpty) {
      DateTime now = DateTime.now();

      specialAlarms.forEach((key, value) {
        if (value.match(now)) {
          if (key.contains("{}"))
            alarmTmp = key;
          else
            alarmTmp = "$key\n$alarmTmp";
        }
      });
    }
    return alarmTmp;
  }

  void addSpecialSchedule(Schedule s, String alarmTemplate) {
    assert(s != null && alarmTemplate != null);
    specialAlarms.putIfAbsent(alarmTemplate, () => s);
  }

  void clearSpecialSchedule() => specialAlarms.clear();

  void dispose() {
    Sound.soundpool.dispose();
    // if (sleepEnableAction != null) sleepEnableAction();
    sleepEnableAction?.call();
    alarmTask.cancel();
  }

  void playSound(int soundIdx, {bool repeat, Duration duration}) {
    //仅设定时间段内报时
    if (!(slientSchedule?.match(DateTime.now()) ?? false) && !isSlient) {
      Sound.play(soundIdx,
          repeat: repeat ?? duration != null, duration: duration);
    }
  }

  void alarm() {
    var now = DateTime.now();
    // if (sleepDisableAction != null) sleepDisableAction();
    sleepDisableAction?.call();
    String alertMsg = this.alarmTemplate;
    String alertTime;
    switch (now.minute) {
      case 15:
        alertTime = aQuarterTemplate.tl(args: [now.hour.toString()]);
        if (quarterSoundIdx != null)
          playSound(quarterSoundIdx,
              repeat: true, duration: Duration(seconds: 2));
        intervalAction(FlashLamp.flash, millisecondInterval: [300]);
        Vibrate.littleShake();
        break;
      case 45:
        alertTime = threeQuarterTemplate.tl(args: [now.hour.toString()]);
        if (quarterSoundIdx != null)
          playSound(quarterSoundIdx,
              repeat: true, duration: Duration(seconds: 2));
        intervalAction(FlashLamp.flash, millisecondInterval: [300]);
        Vibrate.littleShake();
        break;
      case 30:
        alertTime = halfPastTemplate.tl(args: [now.hour.toString()]);
        if (halfSoundIdx != null)
          playSound(halfSoundIdx, repeat: true, duration: Duration(seconds: 3));
        intervalAction(FlashLamp.flash, millisecondInterval: [300, 1300, 1600]);
        Vibrate.mediumVibrate();
        break;
      case 0:
        alertTime = oclockTemplate.tl(args: [now.hour.toString()]);
        if (oclockSoundIdx != null)
          playSound(oclockSoundIdx,
              repeat: true, duration: Duration(seconds: 10));
        intervalAction(FlashLamp.flash,
            millisecondInterval: [300, 1300, 1600, 3300, 3600, 4300, 4600]);
        Vibrate.longVibrate();
        break;
      default:
        alertTime = anytimeTemplate
            .tl(args: [now.hour.toString(), now.minute.toString()]);
        if (quarterSoundIdx != null) playSound(quarterSoundIdx);
        intervalAction(FlashLamp.flash, millisecondInterval: [300, 1300, 1600]);
        Vibrate.mediumVibrate();
        break;
    }

    //按休眠计划改变激活锁定状态
    if (sleepSchedule?.match(now) == false) {
      // if (sleepDisableAction != null) sleepDisableAction();
      sleepDisableAction?.call();
    } else {
      // if (sleepEnableAction != null) sleepEnableAction();
      sleepEnableAction?.call();
    }

    showToast(alertMsg.tl(args: [alertTime]));
  }

  void showToast(String msg,
      {int showInSec = 2,
      ToastGravity gravity = ToastGravity.BOTTOM,
      double fontSize = 16.0,
      bool debugMode = true}) {
    if(Platform.isAndroid||Platform.isIOS) {
      Fluttertoast.showToast(
        msg: msg,
        toastLength: Toast.LENGTH_SHORT,
        gravity: gravity,
        timeInSecForIosWeb: showInSec,
        fontSize: fontSize,
      );
    }
    if (debugMode) logger.fine(msg);
  }

  ///按一定时间间隔重复执行processer方法，方法调用后立即执行processer方法，如millisecondInterval不为null则按此间隔继续执行
  void intervalAction(actionCall processer, {List<int> millisecondInterval}) {
    if (processer != null) {
      processer();
      if (millisecondInterval?.isNotEmpty == true) {
        for (int i in millisecondInterval) {
          Future.delayed(Duration(milliseconds: i), processer);
        }
      }
    }
  }
}

