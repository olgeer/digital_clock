import 'dart:async';
import 'package:zeking_flash_lamp/zeking_flash_lamp.dart';

class FlashLamp {
  static bool lampOn=false;
  static bool hasLampDevice=false;
  static bool useLamp=true;

  static Future<bool> init()async{
    hasLampDevice = await ZekingFlashLamp.hasLamp;
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
      ZekingFlashLamp.turnOn(intensity: intensity);
      lampOn=true;
    }
  }

  static void turnOff() {
    if (hasLamp && useLamp) {
      ZekingFlashLamp.turnOff();
      lampOn=false;
    }
  }
}