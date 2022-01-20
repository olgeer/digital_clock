import 'dart:async';
import 'dart:io';
import 'package:phone_lamp/phone_lamp.dart';

class FlashLamp {
  static bool lampOn=false;
  static bool hasLampDevice=false;
  static bool useLamp=true;

  static Future<bool> init()async{
    if(Platform.isAndroid || Platform.isIOS)
      hasLampDevice = await PhoneLamp.hasLamp;
    return hasLampDevice;
  }

  static void doubleFlash() {
    flash(pattern: [50, 200, 50]);
  }

  static void shortFlash() => flash(pattern: [50]);

  static void flash({List<int> pattern = const [50], double intensity = 1.0}) async{
    if (hasLamp && useLamp) {
      bool lampOn = false;
      for (int i in pattern) {
        if (lampOn) {
          turnOff();
        } else {
          turnOn(intensity: intensity);
        }
        await Future.delayed(Duration(milliseconds: i));
        lampOn = !lampOn;
      }
      turnOff();
    }
  }

  static bool get hasLamp => hasLampDevice;

  static void turnOn({double intensity = 1.0}) {
    if (hasLamp && useLamp) {
      PhoneLamp.turnOn(intensity: intensity);
      lampOn=true;
    }
  }

  static void turnOff() {
    if (hasLamp && useLamp) {
      PhoneLamp.turnOff();
      lampOn=false;
    }
  }
}