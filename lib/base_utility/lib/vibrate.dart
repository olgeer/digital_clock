import 'dart:async';
import 'dart:io';

import 'package:vibration/vibration.dart';

class Vibrate {
  static bool hasVibrator = false,
      hasCustomVibrationsSupport = false,
      hasAmplitudeControl = false;
  static bool enableVibrate = false;

  static void init() async {
    //获取震动器信息
    if(Platform.isAndroid || Platform.isIOS) {
      hasVibrator = await Vibration.hasVibrator() ?? false;
      hasAmplitudeControl = await Vibration.hasAmplitudeControl() ?? false;
      hasCustomVibrationsSupport =
          await Vibration.hasCustomVibrationsSupport() ?? false;
      enableVibrate = true;
    }
  }

  static void vibrateCustom({int duration = 500,
    List<int> pattern = const [],
    int amplitude = -1,
    int repeat = -1,
    List<int> intensities = const []}) {
    if (hasVibrator && enableVibrate) {
      if (hasCustomVibrationsSupport) {
        if (hasAmplitudeControl) {
          Vibration.vibrate(
              duration: duration,
              pattern: pattern,
              amplitude: amplitude,
              repeat: repeat,
              intensities: intensities);
        } else {
          Vibration.vibrate(
              duration: duration,
              pattern: pattern,
              repeat: repeat,
              intensities: intensities);
        }
      } else {
        Vibration.vibrate();
      }
    }
  }

  static void longVibrate() =>
      vibrateCustom(pattern: [100, 500, 100, 500, 100, 500, 100, 500]);

  static void mediumVibrate() => vibrateCustom(pattern: [100, 400, 100, 400]);

  static void littleShake() => vibrateCustom(duration: 20);

  static void shake() => vibrateCustom();

  static void keepVibrate({int secend=3}) {
    int begin = DateTime
        .now()
        .millisecondsSinceEpoch;
    Timer.periodic(const Duration(seconds: 1), (timer) {
      longVibrate();
      if (DateTime
          .now()
          .millisecondsSinceEpoch > begin + (secend * 1000)) {
        timer.cancel();
      }
    });
  }
}