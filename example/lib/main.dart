import 'dart:async';

import 'package:console/console.dart';
import 'package:digital_clock/digital_clock.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Clock',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: ClockComponent(),
    );
  }
}

class ClockComponent extends StatefulWidget {
  @override
  ClockComponentState createState() => ClockComponentState();
}

class ClockComponentState extends State<ClockComponent> {
  DigitalClockConfig flipClock = DigitalClockConfig(
    "SimpleFlipClock",
    height: 360,
    width: 640,
    foregroundColor: Colors.grey,
    backgroundColor: Colors.black,
    blinkColor: Colors.grey,
    backgroundImage: null,
    bodyImage: ItemConfig(
      style: H12Style.pic.index,
      rect: Rect.fromCenter(center: Offset(0, 0), width: 461, height: 261),
      imgs: ["body.png"],
    ),
    timeType: TimeType.h12,
    skinBasePath: "SimpleFlipClock",
    hourItem: ItemConfig(
        style: TimeStyle.flip.index,
        rect: Rect.fromCenter(center: Offset(-119, 1), width: 222, height: 239),
        imgPrename: "d",
        imgExtname: ".png"),
    minuteItem: ItemConfig(
        style: TimeStyle.flip.index,
        rect: Rect.fromCenter(center: Offset(119, 1), width: 222, height: 239),
        imgPrename: "d",
        imgExtname: ".png"),
    secondItem: ItemConfig(
        style: TimeStyle.flip.index,
        rect: Rect.fromCenter(center: Offset(0, 0), width: 222, height: 239),
        imgPrename: "d",
        imgExtname: ".png"),
    h12Item: ItemConfig(
      style: H12Style.pic.index,
      rect: Rect.fromCenter(center: Offset(-200, -94), width: 45, height: 39),
      imgs: ["am.png", "pm.png"],
    ),
    tiktokItem: null,
    settingItem: ItemConfig(
      style: H12Style.pic.index,
      rect: Rect.fromCenter(center: Offset(-119, 1), width: 222, height: 239),
    ),
    exitItem: ItemConfig(
      style: H12Style.pic.index,
      rect: Rect.fromCenter(center: Offset(119, 1), width: 222, height: 239),
    ),
    slientItem: ItemConfig(
      style: ActionStyle.icon.index,
      rect: Rect.fromCenter(center: Offset(260, -110), width: 32, height: 32),
      imgs: [
        Icons.notifications_off.codePoint.toString(),
        Icons.notifications.codePoint.toString()
      ],
    ),
    countDownItem: ItemConfig(
      style: ActionStyle.icon.index,
      rect: Rect.fromCenter(center: Offset(260, 100), width: 32, height: 32),
      imgs: [
        Icons.restore.codePoint.toString(),
        Icons.timer.codePoint.toString()
      ],
    ),
    cdMinuteItem: ItemConfig(
        style: TimeStyle.flip.index,
        rect: Rect.fromCenter(center: Offset(-119, 1), width: 222, height: 239),
        imgPrename: "d",
        imgExtname: ".png"),
    cdSecondItem: ItemConfig(
        style: TimeStyle.flip.index,
        rect: Rect.fromCenter(center: Offset(119, 1), width: 222, height: 239),
        imgPrename: "d",
        imgExtname: ".png"),
  );

  int second=0;
  late Timer myTimer;
  @override
  void initState() {
    initLogger(logLevel:Level.FINER);
    // myTimer=Timer.periodic(Duration(seconds: 1), tt);
    second=DateTime.now().second;
  }

  @override
  void dispose(){
    myTimer.cancel();
    super.dispose();
  }

  void initLogger({Level logLevel=Level.FINE}){
    Logger.root.level = logLevel;
    Logger.root.onRecord.listen((event) {
      String color="{@yellow}";
      final String colorEnd="{@end}";
      switch(event.level.value){
        case 0:
        case 300:
        case 400:
        case 500:
          color="{@green}";
          break;
        case 700:
        case 800:
          color="{@blue}";
          break;
        case 900:
          color="{@magenta}";
          break;
        case 1000:
          color="{@cyan}";
          break;
        case 1200:
        default:
          color="{@yellow}";
          break;
      }
      if(event.level>=logLevel)print(format("${DateTime.now().toString()} - {@blue}[${event.loggerName}]{@end} - $color${event.level.toString()}{@end} : ${event.message}"));
      // log("${DateTime.now().toString()} -- ${event.level.toString()} : ${event.message}",time:DateTime.now(),name: event.loggerName,level: 0);
    });
  }

  void tt(_){
    setState(() {
      // second=DateTime.now().second;
      print("second: ${DateTime.now().second}");
    });
  }

  @override
  Widget build(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;
    return Scaffold(
      body: Container(
        height: screenSize.height,
        width: screenSize.width,
        alignment: Alignment.center,
        color: flipClock.backgroundColor,
        child: FlipNumber(
          "ExampleFlipNumber",
          basePath: '/Users/max/Library/Containers/com.example.example/Data/skins/SimpleFlipClock/',
          // currentValue: second,
          isPositiveSequence: true,
          canRevese: false,
          autoRun: true,
          min: 0,
          max: 59,
          startValue: second,
          numberItem: flipClock.secondItem ??
              ItemConfig(
                  style: TimeStyle.flip.index,
                  rect: Rect.fromCenter(
                      center: Offset(0, 0), width: 222, height: 239)),
        ),
      ),
    );
  }
}
