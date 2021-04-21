import 'define.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:logging/logging.dart';
import 'package:cron/cron.dart';
import 'sound.dart' as sound;
import 'vibrate.dart' as vibrate;
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
  actionCall sleepEnableAction = (){};
  actionCall sleepDisableAction = (){};

  ///允许震动开关
  bool enableVibrate;

  ///允许报时音开关
  bool enableAlarmSound;

  ///允许闪光灯开关
  bool enableFlashLamp;

  ///刻钟报时音文件
  String quarterAlarmSound;
  int quarterSoundIdx;

  ///半点报时音文件
  String halfAlarmSound;
  int halfSoundIdx;

  ///整点报时音文件
  String oclockAlarmSound;
  int oclockSoundIdx;

  ///静音开关
  bool isSlient=false;

  String normalAlarmMessageTemplate = "现在是 {}";
  String anytimeTemplate = "{}点{}分";
  String halfPastTemplate = "{}点半";
  String oclockTemplate = "{}点正";
  String aQuarterTemplate = "{}点一刻";
  String threeQuarterTemplate = "{}点三刻";

  Map<String,Schedule> specialAlarms=Map<String,Schedule>();

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
    if (sleepSchedule?.match(DateTime.now()) == false){
      logger.fine("do wakelock");
      sleepDisableAction();
    }else{
      logger.fine("do not wakelock");
      sleepEnableAction();
    }

    if (enableVibrate) vibrate.init();

    if (enableAlarmSound) sound.initSound();

    if (enableFlashLamp) FlashLamp.init();

    initAsync();
  }

  void initAsync() async {
    if (enableAlarmSound) {
      oclockSoundIdx =
      await sound.loadSound(oclockAlarmSound ?? "assets/voices/座钟报时.mp3");
      halfSoundIdx =
      await sound.loadSound(halfAlarmSound ?? "assets/voices/短促欢愉.mp3");
      quarterSoundIdx =
      await sound.loadSound(quarterAlarmSound ?? "assets/voices/钟琴颤音.mp3");
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

  set setSlient(bool b){
    isSlient=b;
    logger.fine("isSlient is $b");
  }

  Schedule get newSchedule => alarmSchedule;

  set noSoundSchedule(Schedule s) => slientSchedule = s;
  Schedule get noSoundSchedule => slientSchedule;

  set noWakeLockSchedule(Schedule s) => sleepSchedule = s;
  Schedule get noWakeLockSchedule => sleepSchedule;

  String get alarmTemplate{
    String alarmTmp=normalAlarmMessageTemplate;
    if(specialAlarms.isNotEmpty){
      DateTime now=DateTime.now();

      specialAlarms.forEach((key, value) {
        if(value.match(now)){
          if(key.contains("{}"))alarmTmp=key;
          else alarmTmp="$key\n$alarmTmp";
        }
      });
    }
    return alarmTmp;
  }

  void addSpecialSchedule(Schedule s,String alarmTemplate){
    assert(s!=null && alarmTemplate!=null);
    specialAlarms.putIfAbsent(alarmTemplate, () => s);
  }

  void clearSpecialSchedule()=>specialAlarms.clear();

  void dispose() {
    sound.soundpool.dispose();
    sleepEnableAction();
    alarmTask.cancel();
  }

  void playSound(int soundIdx,{bool repeat,Duration duration}) {
    //仅设定时间段内报时
    if (!(slientSchedule?.match(DateTime.now()) ?? false) && !isSlient) {
      sound.play(soundIdx,repeat: repeat??duration!=null,duration: duration);
    }
  }

  void alarm() {
    var now = DateTime.now();
    sleepDisableAction();
    String alertMsg = this.alarmTemplate;
    String alertTime;
    switch (now.minute) {
      case 15:
        alertTime = aQuarterTemplate.tl(args: [now.hour.toString()]);
        playSound(quarterSoundIdx,repeat: true,duration:Duration(seconds: 2));
        intervalAction(FlashLamp.flash,millisecondInterval: [300]);
        vibrate.littleShake();
        break;
      case 45:
        alertTime = threeQuarterTemplate.tl(args: [now.hour.toString()]);
        playSound(quarterSoundIdx,repeat: true,duration:Duration(seconds: 2));
        intervalAction(FlashLamp.flash,millisecondInterval: [300]);
        vibrate.littleShake();
        break;
      case 30:
        alertTime = halfPastTemplate.tl(args: [now.hour.toString()]);
        playSound(halfSoundIdx,repeat: true,duration:Duration(seconds: 3));
        intervalAction(FlashLamp.flash,millisecondInterval: [300,1300,1600]);
        vibrate.mediumVibrate();
        break;
      case 0:
        alertTime = oclockTemplate.tl(args: [now.hour.toString()]);
        playSound(oclockSoundIdx,repeat: true,duration:Duration(seconds: 10));
        intervalAction(FlashLamp.flash,millisecondInterval: [300,1300,1600,3300,3600,4300,4600]);
        vibrate.longVibrate();
        break;
      default:
        alertTime =
            anytimeTemplate.tl(args: [now.hour.toString(), now.minute.toString()]);
        playSound(quarterSoundIdx);
        intervalAction(FlashLamp.flash,millisecondInterval: [300,1300,1600]);
        vibrate.mediumVibrate();
        break;
    }

    //按休眠计划改变激活锁定状态
    if (sleepSchedule?.match(now)==false) {
      sleepDisableAction();
    } else {
      sleepEnableAction();
    }

    showToast(alertMsg.tl(args: [alertTime]));
  }

  void showToast(String msg,
      {int showInSec = 2,
        ToastGravity gravity = ToastGravity.BOTTOM,
        double fontSize = 16.0,
        bool debugMode = true}) {
    Fluttertoast.showToast(
      msg: msg,
      toastLength: Toast.LENGTH_SHORT,
      gravity: gravity,
      timeInSecForIosWeb: showInSec,
      fontSize: fontSize,
    );
    if (debugMode)logger.fine(msg);
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
