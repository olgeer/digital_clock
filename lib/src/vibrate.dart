import 'dart:async';
import 'package:vibration/vibration.dart';

bool hasVibrator=false, hasCustomVibrationsSupport=false, hasAmplitudeControl=false;
bool enableVibrate=false;

void init() async {
  //获取震动器信息
  hasVibrator = await Vibration.hasVibrator();
  hasAmplitudeControl = await Vibration.hasAmplitudeControl();
  hasCustomVibrationsSupport = await Vibration.hasCustomVibrationsSupport();
  enableVibrate=true;
}

void vibrateCustom(
    {int duration = 500,
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

void longVibrate() =>
    vibrateCustom(pattern: [100, 500, 100, 500, 100, 500, 100, 500]);
void mediumVibrate() => vibrateCustom(pattern: [100, 400, 100, 400]);
void littleShake() => vibrateCustom(duration: 20);
void shake() => vibrateCustom();
void keepVibrate(int secends) {
  int begin = DateTime.now().millisecondsSinceEpoch;
  Timer timer = Timer.periodic(Duration(seconds: 3), (timer) {
    longVibrate();
    if (DateTime.now().millisecondsSinceEpoch > begin + (secends * 1000))
      timer.cancel();
  });
}
