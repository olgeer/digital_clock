import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:base_utility/base_utility.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_picker/flutter_picker.dart';

import 'flipNumber.dart';

class DigitalClock extends StatefulWidget {
  double height;
  double width;
  bool sizeChange;
  DigitalClockConfig config;
  eventCall? onClockEvent;
  contextProc? onExitAction;

  DigitalClock({
    this.height = 300,
    this.width = 600,
    this.sizeChange = false,
    required this.config,
    this.onClockEvent,
    this.onExitAction,
  }) : super();

  @override
  State<StatefulWidget> createState() => DigitalClockState();

  void fireClockEvent(ClockEvent ce) =>
      onClockEvent != null ? onClockEvent!(ce) : null;
}

class DigitalClockState extends State<DigitalClock>
    with SingleTickerProviderStateMixin {
  late int hours, minutes, seconds, years, months, days, weekday;
  int? cdHours, cdMinutes, cdSeconds;
  int h12 = 0, tk = 0;
  bool isSlient = false;
  bool refreshClock = false, refreshCd = false;
  bool countDownMode = false;
  DateTime? countDownBeginTime;
  Duration? countDownDuration;
  late String currentSkinName;
  late String skinBasePath;
  late Timer clockTimer;
  double scale = 1;
  Widget nullWidget = Container();
  FlipNumber? hourFlipNumber, minuteFlipNumber, secondFlipNumber;
  FlipNumber? cdHourFlipNumber, cdMinuteFlipNumber, cdSecondFlipNumber;
  late Duration animationDuration;
  late double xScale, yScale;
  AnimationController? animationController;
  late Animation<Color?> animation;
  Logger logger = Logger("DigitalClock");

  @override
  void initState() {
    super.initState();
    // initScale();
    init();
    initAnimate();
    // tiktok();
    clockTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      tiktok();
    });
  }

  @override
  void dispose() {
    clockTimer.cancel();
    SystemChrome.setEnabledSystemUIOverlays(
        [SystemUiOverlay.top, SystemUiOverlay.bottom]);
    animationController?.dispose();
    super.dispose();
  }

  void initAnimate() {
    logger.fine("initAnimate() running...");
    animationController = AnimationController(
        duration: Duration(milliseconds: 100),
        vsync: this); //AnimationController

    animation = ColorTween(
            begin: widget.config.backgroundColor, end: widget.config.blinkColor)
        .animate(animationController!);
    animationController?.addStatusListener((status) {
      logger.finer("Animation state = ${status.toString()}");
      if (status == AnimationStatus.completed)
        Future.delayed(
            Duration(milliseconds: 100), () => animationController?.reverse());
    });
    animationController?.addListener(() {
      setState(() {
        logger.fine(animation.value);
      });
    });
    // animationController.forward();
  }

  void initScale() {
    xScale = widget.width / widget.config.width;
    yScale = widget.height / widget.config.height;
    scale = xScale < yScale ? xScale : yScale;
    logger.fine("widget.width=${widget.width} widget.height=${widget.height}");
    logger.fine("xs=$xScale ys=$yScale scale=$scale");
    widget.sizeChange = false;
  }

  void init() {
    initScale();

    currentSkinName = widget.config.skinName;

    skinBasePath = widget.config.skinBasePath ?? "";

    animationDuration = Duration(milliseconds: 900);

    refreshTime(DateTime.now());

    initHourFlipNumber(widget.config.hourItem);
    initMinuteFlipNumber(widget.config.minuteItem);
    initSecondFlipNumber(widget.config.secondItem);

    initCdHourFlipNumber(widget.config.cdHourItem);
    initCdMinuteFlipNumber(widget.config.cdMinuteItem);
    initCdSecondFlipNumber(widget.config.cdSecondItem);

    // Wakelock.enable();
    SystemChrome.setEnabledSystemUIOverlays([SystemUiOverlay.bottom]);
  }

  Widget initHourFlipNumber(ItemConfig? item, {int? initValue}) {
    if (item?.style == TimeStyle.flip.index) {
      if (hourFlipNumber == null) {
        hourFlipNumber = FlipNumber(
          "hourFlipNumber",
          scale: scale,
          basePath: skinBasePath,
          numberItem: item!,
          animationDuration: animationDuration,
          canRevese: false,
          isPositiveSequence: true,
          min: widget.config.timeType == TimeType.h12 ? 1 : 0,
          max: widget.config.timeType == TimeType.h12 ? 12 : 23,
          startValue: initValue ?? hours,
        );
      } else {
        hourFlipNumber?.scale = scale;
        hourFlipNumber?.currentValue = initValue ?? hours;
        if (hourFlipNumber?.refresh != null) hourFlipNumber!.refresh();
      }
    } else {
      // hourFlipNumber = null;
    }
    return hourFlipNumber ?? nullWidget;
  }

  Widget initMinuteFlipNumber(ItemConfig? item, {int? initValue}) {
    if (item?.style == TimeStyle.flip.index) {
      if (minuteFlipNumber == null) {
        minuteFlipNumber = FlipNumber(
          "minuteFlipNumber",
          scale: scale,
          basePath: skinBasePath,
          numberItem: item!,
          animationDuration: animationDuration,
          canRevese: false,
          isPositiveSequence: true,
          min: 0,
          max: 59,
          startValue: initValue ?? minutes,
        );
      } else {
        minuteFlipNumber?.scale = scale;
        minuteFlipNumber?.currentValue = initValue ?? minutes;
        if (minuteFlipNumber?.refresh != null) minuteFlipNumber!.refresh();
      }
    } else {
      // minuteFlipNumber = null;
    }
    return minuteFlipNumber ?? nullWidget;
  }

  Widget initSecondFlipNumber(ItemConfig? item, {int? initValue}) {
    if (item?.style == TimeStyle.flip.index) {
      if (secondFlipNumber == null) {
        secondFlipNumber = FlipNumber(
          "secondFlipNumber",
          scale: scale,
          basePath: skinBasePath,
          numberItem: item!,
          animationDuration: animationDuration,
          canRevese: false,
          isPositiveSequence: true,
          min: 0,
          max: 59,
          startValue: initValue ?? seconds,
        );
      } else {
        secondFlipNumber?.scale = scale;
        secondFlipNumber?.currentValue = initValue ?? seconds;
        if (secondFlipNumber?.refresh != null) secondFlipNumber!.refresh();
      }
    } else {
      // secondFlipNumber = null;
    }
    return secondFlipNumber ?? nullWidget;
  }

  Widget initCdHourFlipNumber(ItemConfig? item, {int? initValue}) {
    if (item?.style == TimeStyle.flip.index) {
      if (cdHourFlipNumber == null) {
        cdHourFlipNumber = FlipNumber(
          "cdHourFlipNumber",
          scale: scale,
          basePath: skinBasePath,
          numberItem: item!,
          animationDuration: animationDuration,
          canRevese: false,
          isPositiveSequence: false,
          min: 0,
          max: 59,
          startValue: initValue ?? cdHours,
        );
      } else {
        cdHourFlipNumber?.scale = scale;
        cdHourFlipNumber?.currentValue = initValue ?? cdHours;
        if (cdHourFlipNumber?.refresh != null) cdHourFlipNumber!.refresh();
      }
    } else {
      // cdHourFlipNumber = null;
    }
    return cdHourFlipNumber ?? nullWidget;
  }

  Widget initCdMinuteFlipNumber(ItemConfig? item, {int? initValue}) {
    if (item?.style == TimeStyle.flip.index) {
      if (cdMinuteFlipNumber == null) {
        cdMinuteFlipNumber = FlipNumber(
          "cdMinuteFlipNumber",
          scale: scale,
          basePath: skinBasePath,
          numberItem: item!,
          animationDuration: animationDuration,
          canRevese: false,
          isPositiveSequence: false,
          min: 0,
          max: 59,
          startValue: initValue ?? cdMinutes,
        );
      } else {
        cdMinuteFlipNumber?.scale = scale;
        cdMinuteFlipNumber?.currentValue = initValue ?? cdMinutes;
        if (cdMinuteFlipNumber?.refresh != null) cdMinuteFlipNumber!.refresh();
      }
    } else {
      // cdMinuteFlipNumber = null;
    }
    return cdMinuteFlipNumber ?? nullWidget;
  }

  Widget initCdSecondFlipNumber(ItemConfig? item, {int? initValue}) {
    if (item?.style == TimeStyle.flip.index) {
      if (cdSecondFlipNumber == null) {
        cdSecondFlipNumber = FlipNumber(
          "cdSecondFlipNumber",
          scale: scale,
          basePath: skinBasePath,
          numberItem: item!,
          animationDuration: animationDuration,
          canRevese: false,
          isPositiveSequence: false,
          min: 0,
          max: 59,
          startValue: initValue ?? cdSeconds,
        );
      } else {
        cdSecondFlipNumber?.scale = scale;
        cdSecondFlipNumber?.currentValue = initValue ?? cdSeconds;
        if (cdSecondFlipNumber?.refresh != null) cdSecondFlipNumber!.refresh();
      }
    } else {
      // cdSecondFlipNumber = null;
    }
    return cdSecondFlipNumber ?? nullWidget;
  }

  void refreshTime(DateTime now) {
    years = now.year;
    months = now.month;
    days = now.day;
    weekday = now.weekday;
    hours = getHour(now.hour);
    minutes = now.minute;
    seconds = now.second;
  }

  int getHour(int h) {
    int hour = h;
    if (widget.config.timeType == TimeType.h12) {
      if (h >= 12) {
        hour -= 12;
        h12 = 1;
      } else {
        h12 = 0;
      }
      hour = hour == 0 ? 12 : hour;
    }
    return hour;
  }

  String int2Str(int value, {int width = 2}) {
    String s = value.toString();
    for (int i = 0; i < (width - s.length); i++) {
      s = "0" + s;
    }
    return s;
  }

  void countDownBegin(int cdMin) {
    countDownDuration = Duration(minutes: cdMin);
    countDownBeginTime = DateTime.now();
    cdHours = countDownDuration?.inHours ?? 0;
    cdMinutes = countDownDuration?.inMinutes ?? 0;
    cdSeconds = 0;
    widget.config.cdHourItem?.style == TimeStyle.flip.index
        ? cdHourFlipNumber?.initValue(cdHours!)
        : DNT();
    widget.config.cdMinuteItem?.style == TimeStyle.flip.index
        ? cdMinuteFlipNumber?.initValue(cdMinutes!)
        : DNT();
    widget.config.cdSecondItem?.style == TimeStyle.flip.index
        ? cdSecondFlipNumber?.initValue(cdSeconds!)
        : DNT();
    setState(() {
      countDownMode = true;
      refreshCd = true;
      widget.fireClockEvent(
          ClockEvent(ClockEventType.countDownStart, value: countDownDuration));
    });
  }

  void countDownOver({bool cancel = false}) {
    refreshTime(DateTime.now());
    widget.config.hourItem?.style == TimeStyle.flip.index
        ? hourFlipNumber?.initValue(hours)
        : DNT();
    widget.config.minuteItem?.style == TimeStyle.flip.index
        ? minuteFlipNumber?.initValue(minutes)
        : DNT();
    widget.config.secondItem?.style == TimeStyle.flip.index
        ? secondFlipNumber?.initValue(seconds)
        : DNT();

    setState(() {
      refreshClock = true;
      countDownMode = false;
    });
    widget.fireClockEvent(
        ClockEvent(ClockEventType.countDownStop, value: cancel));
  }

  /// ???????????????????????????????????????
  void tiktok() {
    DateTime now = DateTime.now();
    int tkHour, tkMinute, tkSecond;

    if (countDownMode) {
      int tkInSeconds = countDownDuration!.inSeconds -
          ((now.millisecondsSinceEpoch -
                      countDownBeginTime!.millisecondsSinceEpoch) /
                  1000)
              .floor();

      /// ???????????????
      if (tkInSeconds == 0) {
        countDownOver();
      }

      tkHour = tkInSeconds ~/ 3600;
      tkInSeconds -= tkHour * 3600;
      tkMinute = tkInSeconds ~/ 60;
      tkInSeconds -= tkMinute * 60;
      tkSecond = tkInSeconds;

      logger.finest(
          "countDownDuration: ${countDownDuration?.inSeconds} tkHour:$tkHour tkMinute:$tkMinute tkSecond:$tkSecond");
      // if(animationController==null||animationController?.status==AnimationStatus.dismissed)animationController?.forward();
      logger.finest(
          "Tiktok running in ${countDownMode ? "CountDownMode" : "ClockMode"} $now");

      if (tkHour != cdHours || refreshCd) {
        if (cdHourFlipNumber != null) {
          // logger.finest("cdHourFlipNumber flip !");
          cdHourFlipNumber?.currentValue = tkHour;
          refreshCd
              ? cdHourFlipNumber!.refresh()
              : cdHourFlipNumber?.controller?.forward();
        }
        cdHours = tkHour;
      }
      if (tkMinute != cdMinutes || refreshCd) {
        if (cdMinuteFlipNumber != null) {
          // logger.fine("cdMinuteFlipNumber flip !");
          cdMinuteFlipNumber!.currentValue = tkMinute;
          refreshCd
              ? cdMinuteFlipNumber!.refresh()
              : cdMinuteFlipNumber!.controller?.forward();

          /// ???5?????????????????????
          if (tkMinute % 5 == 0) {
            intervalAction(() => animationController?.forward,
                millisecondInterval: [300, 1300, 1600]);
          }
        }
        cdMinutes = tkMinute;
      }
      if (tkSecond != cdSeconds || refreshCd) {
        if (cdSecondFlipNumber != null) {
          // logger.fine("cdSecondFlipNumber flip ! ${cdSecondFlipNumber!.controller?.value}");
          cdSecondFlipNumber!.currentValue = tkSecond;
          refreshCd
              ? cdSecondFlipNumber!.refresh()
              : cdSecondFlipNumber!.controller?.forward();
        }
        cdSeconds = tkSecond;
      }
      refreshCd = false;
    } else {
      tkHour = getHour(now.hour);
      tkMinute = now.minute;
      tkSecond = now.second;

      logger.finest("$hours : $minutes : $seconds");

      if (tkHour != hours || refreshClock) {
        if (hourFlipNumber != null) {
          hourFlipNumber!.currentValue = tkHour;
          refreshClock
              ? hourFlipNumber!.refresh()
              : hourFlipNumber!.controller?.forward();

          /// ?????????????????????
          intervalAction(() => animationController?.forward,
              millisecondInterval: [300, 1300, 1600, 2300, 3600]);
        }
      }
      if (tkMinute != minutes || refreshClock) {
        if (minuteFlipNumber != null) {
          logger.finest("minuteFlipNumber flip !");
          minuteFlipNumber?.currentValue = tkMinute;
          refreshClock
              ? minuteFlipNumber?.refresh()
              : minuteFlipNumber?.controller?.forward();

          /// ?????????????????????
          if (tkMinute == 30 || tkMinute == 52) {
            intervalAction(() => animationController?.forward,
                millisecondInterval: [300, 1300, 1600]);
          } else if (tkMinute == 15 || tkMinute == 45) {
            /// ????????????????????????
            intervalAction(() => animationController?.forward,
                millisecondInterval: [300]);
          }
        }
      }
      refreshClock = false;
      refreshTime(now);
    }

    setState(() {
      tk = (tk - 1).abs();
    });
  }

  Future<int> showAlarmSelect(BuildContext context) async {
    int ret = 0;
    await Picker(
        adapter: PickerDataAdapter<int>(pickerdata: [
          1,
          3,
          5,
          8,
          10,
          15,
          20,
          25,
          30,
          35,
          40,
          45,
          50,
          55,
          60
        ]),
        delimiter: [
          PickerDelimiter(
              child: Container(
            width: 60.0,
            alignment: Alignment.center,
            child: Text("??????"),
          ))
        ],
        selecteds: [5],
        textStyle: TextStyle(fontSize: 24, color: Colors.grey),
        selectedTextStyle: TextStyle(fontSize: 26, color: Colors.black),
        cancelText: "??????",
        confirmText: "??????",
        hideHeader: true,
        title: Text("???????????????????????????"),
        onSelect: (picker, idx, value) {
          Vibrate.littleShake();
        },
        onConfirm: (Picker picker, List value) async {
          // print(picker.getSelectedValues().first);
          // setState(() {
          //   countDownMode = true;
          // });
          // Future.delayed(
          //     Duration(minutes: picker.getSelectedValues().first), showAlarm);
          // showToast("???????????????");
          ret = picker.getSelectedValues().first;
        }).showDialog(context);
    return ret;
  }

  void showAlarm() {
    showToast(
      "??????????????????????????????",
      showInSec: 10,
    );
    Vibrate.keepVibrate(secend: 10);
    FlashLamp.flash(pattern: [50, 100, 50, 100, 50, 500, 50, 100, 50, 100, 50]);
    setState(() {
      countDownMode = false;
    });
  }

  EdgeInsets buildEdgeRect(Rect itemRect) {
    double rectScale = scale;
    double l = ((widget.config.width / 2) + itemRect.left) * rectScale;
    double t = ((widget.config.height / 2) + itemRect.top) * rectScale;
    double r = ((widget.config.width / 2) - itemRect.right) * rectScale;
    double b = ((widget.config.height / 2) - itemRect.bottom) * rectScale;
    // print("Rect($itemRect) EdgeInsets.fromLTRB($l,$t,$r,$b)");
    return EdgeInsets.fromLTRB(l, t, r, b);
  }

  Widget buildTextItem(
      String itemText, Rect itemRect, TextStyle itemTextStyle) {
    TextStyle scaleTextStyle = itemTextStyle.copyWith(
        fontSize: (itemTextStyle.fontSize ?? 12) * scale);
    // logger.fine("itemText:$itemText");
    return Container(
      // color: Colors.grey.withAlpha(50),
      // height: widget.config.height * scale,
      // width: widget.config.width * scale,
      height: itemRect.height * scale,
      width: itemRect.width * scale,
      margin: buildEdgeRect(itemRect),
      alignment: Alignment.center,
      child: Text(
        itemText,
        style: scaleTextStyle,
      ),
    );
  }

  Widget buildImage(String? picName, Size picRect,
      {BoxFit fit = BoxFit.cover}) {
    return picName == null
        ? nullWidget
        : picName.contains("assets:")
            ? Image.asset(
                picName.replaceFirst("assets:", ""),
                fit: fit,
                height: picRect.height * scale,
                width: picRect.width * scale,
              )
            : Image.file(
                File(picName),
                fit: fit,
                height: picRect.height * scale,
                width: picRect.width * scale,
              );
  }

  Widget buildPicItem(int value, ItemConfig picItem) {
    String picName;
    if (picItem.imgs != null &&
        picItem.imgs!.isNotEmpty &&
        value < picItem.imgs!.length) {
      picName = "${widget.config.skinBasePath}${picItem.imgs![value]}";
    } else {
      picName =
          "${widget.config.skinBasePath}${picItem.imgPrename ?? ""}${int2Str(value)}${picItem.imgExtname ?? ""}";
    }
    // print(picName);
    return Container(
      // color: Colors.white12,
      // color: Colors.grey.withAlpha(50),
      // height: widget.config.height * scale,
      // width: widget.config.width * scale,
      height: picItem.rect.height * scale,
      width: picItem.rect.width * scale,
      margin: buildEdgeRect(picItem.rect),
      alignment: Alignment.center,
      child: buildImage(picName, picItem.rect.size, fit: BoxFit.contain),
    );
  }

  Widget buildHourFlipItem(int value, ItemConfig picItem, String basePath) {
    return Container(
      // height: widget.config.height * scale,
      // width: widget.config.width * scale,
      // color: Colors.grey.withAlpha(50),
      height: picItem.rect.height * scale,
      width: picItem.rect.width * scale,
      margin: buildEdgeRect(picItem.rect),
      alignment: Alignment.center,
      // child: initHourFlipNumber(picItem,initValue: value),
      child: hourFlipNumber,
    );
  }

  Widget buildMinuteFlipItem(int value, ItemConfig picItem, String basePath) {
    return Container(
      // height: widget.config.height * scale,
      // width: widget.config.width * scale,
      height: picItem.rect.height * scale,
      width: picItem.rect.width * scale,
      margin: buildEdgeRect(picItem.rect),
      alignment: Alignment.center,
      // child: initMinuteFlipNumber(picItem,initValue: value),
      child: minuteFlipNumber,
    );
  }

  Widget buildSecondFlipItem(int value, ItemConfig picItem, String basePath) {
    return Container(
      // height: widget.config.height * scale,
      // width: widget.config.width * scale,
      height: picItem.rect.height * scale,
      width: picItem.rect.width * scale,
      margin: buildEdgeRect(picItem.rect),
      alignment: Alignment.center,
      // child: initSecondFlipNumber(picItem,initValue: value),
      child: secondFlipNumber,
    );
  }

  Widget buildCdHourFlipItem(int value, ItemConfig picItem, String basePath) {
    return Container(
      // height: widget.config.height * scale,
      // width: widget.config.width * scale,
      // color: Colors.grey.withAlpha(50),
      height: picItem.rect.height * scale,
      width: picItem.rect.width * scale,
      margin: buildEdgeRect(picItem.rect),
      alignment: Alignment.center,
      // child: initCdHourFlipNumber(picItem,initValue: value),
      child: cdHourFlipNumber,
    );
  }

  Widget buildCdMinuteFlipItem(int value, ItemConfig picItem, String basePath) {
    return Container(
      // height: widget.config.height * scale,
      // width: widget.config.width * scale,
      height: picItem.rect.height * scale,
      width: picItem.rect.width * scale,
      margin: buildEdgeRect(picItem.rect),
      alignment: Alignment.center,
      // child: initCdMinuteFlipNumber(picItem,initValue: value),
      child: cdMinuteFlipNumber,
    );
  }

  Widget buildCdSecondFlipItem(int value, ItemConfig picItem, String basePath) {
    return Container(
      // height: widget.config.height * scale,
      // width: widget.config.width * scale,
      height: picItem.rect.height * scale,
      width: picItem.rect.width * scale,
      margin: buildEdgeRect(picItem.rect),
      alignment: Alignment.center,
      // child: initCdSecondFlipNumber(picItem,initValue: value),
      child: cdSecondFlipNumber,
    );
  }

  Widget buildYear(int y, ItemConfig? ic) {
    if (ic == null) return nullWidget;
    Widget retWidget;

    switch (DateStyle.values[ic.style]) {
      case DateStyle.number:
        retWidget = buildTextItem(int2Str(y, width: 4), ic.rect, ic.textStyle);
        break;
      case DateStyle.chinese:
        retWidget =
            buildTextItem(int2Str(y, width: 4) + "???", ic.rect, ic.textStyle);
        break;
      case DateStyle.english:
        retWidget = buildTextItem(int2Str(y, width: 4), ic.rect, ic.textStyle);
        break;
      case DateStyle.shortEnglish:
        retWidget = buildTextItem(int2Str(y, width: 4), ic.rect, ic.textStyle);
        break;
      case DateStyle.pic:
      default:
        retWidget = nullWidget;
        break;
    }
    return retWidget;
  }

  Widget buildMonth(int m, ItemConfig? ic) {
    if (ic == null) return nullWidget;
    final chsMonths = [
      "??????",
      "??????",
      "??????",
      "??????",
      "??????",
      "??????",
      "??????",
      "??????",
      "??????",
      "??????",
      "?????????",
      "?????????"
    ];
    final engMonths = [
      "January",
      "February",
      "March",
      "April",
      "May",
      "June",
      "July",
      "August",
      "September",
      "October",
      "November",
      "December"
    ];
    final shortEngMonths = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec"
    ];
    Widget retWidget;
    switch (DateStyle.values[ic.style]) {
      case DateStyle.number:
        retWidget = buildTextItem(int2Str(m), ic.rect, ic.textStyle);
        break;
      case DateStyle.chinese:
        retWidget = buildTextItem(chsMonths[m - 1], ic.rect, ic.textStyle);
        break;
      case DateStyle.english:
        retWidget = buildTextItem(engMonths[m - 1], ic.rect, ic.textStyle);
        break;
      case DateStyle.shortEnglish:
        retWidget = buildTextItem(shortEngMonths[m - 1], ic.rect, ic.textStyle);
        break;
      case DateStyle.pic:
      default:
        retWidget = nullWidget;
        break;
    }
    return retWidget;
  }

  Widget buildDay(int d, ItemConfig? ic) {
    if (ic == null) return nullWidget;
    final chsDays = [
      "??????",
      "??????",
      "??????",
      "??????",
      "??????",
      "??????",
      "??????",
      "??????",
      "??????",
      "??????",
      "?????????",
      "?????????",
      "?????????",
      "?????????",
      "?????????",
      "?????????",
      "?????????",
      "?????????",
      "?????????",
      "?????????",
      "????????????",
      "????????????",
      "????????????",
      "????????????",
      "????????????",
      "????????????",
      "????????????",
      "????????????",
      "????????????",
      "?????????",
      "?????????"
    ];
    Widget retWidget;
    switch (DateStyle.values[ic.style]) {
      case DateStyle.number:
        retWidget = buildTextItem(int2Str(d), ic.rect, ic.textStyle);
        break;
      case DateStyle.chinese:
        retWidget = buildTextItem(chsDays[d - 1], ic.rect, ic.textStyle);
        break;
      case DateStyle.english:
        retWidget = buildTextItem(int2Str(d), ic.rect, ic.textStyle);
        break;
      case DateStyle.shortEnglish:
        retWidget = buildTextItem(int2Str(d), ic.rect, ic.textStyle);
        break;
      case DateStyle.pic:
      default:
        retWidget = nullWidget;
        break;
    }
    return retWidget;
  }

  Widget buildWeekDay(int wd, ItemConfig? ic) {
    if (ic == null) return nullWidget;
    final chsWeekDays = [
      "?????????",
      "?????????",
      "?????????",
      "?????????",
      "?????????",
      "?????????",
      "?????????",
    ];
    final engWeekDays = [
      "Sunday",
      "Monday",
      "Tuesday",
      "Wednesday",
      "Thursday",
      "Friday",
      "Saturday"
    ];
    final shortEngWeekDays = ["Sun", "Mon", "Tue", "Wed", "Thur", "Fri", "Sat"];

    Widget retWidget;
    switch (DateStyle.values[ic.style]) {
      case DateStyle.number:
        retWidget = buildTextItem(shortEngWeekDays[wd], ic.rect, ic.textStyle);
        break;
      case DateStyle.chinese:
        retWidget = buildTextItem(chsWeekDays[wd], ic.rect, ic.textStyle);
        break;
      case DateStyle.english:
        retWidget = buildTextItem(engWeekDays[wd], ic.rect, ic.textStyle);
        break;
      case DateStyle.shortEnglish:
        retWidget = buildTextItem(shortEngWeekDays[wd], ic.rect, ic.textStyle);
        break;
      case DateStyle.pic:
      default:
        retWidget = nullWidget;
        break;
    }
    return retWidget;
  }

  Widget buildHour(int h, ItemConfig? ic) {
    if (ic == null) return nullWidget;
    Widget retWidget;
    switch (TimeStyle.values[ic.style]) {
      case TimeStyle.number:
        retWidget = buildTextItem(int2Str(h, width: 2), ic.rect, ic.textStyle);
        break;
      case TimeStyle.chinese:
        retWidget =
            buildTextItem(int2Str(h, width: 2) + "???", ic.rect, ic.textStyle);
        break;
      case TimeStyle.pic:
        retWidget = buildPicItem(h, ic);
        break;
      case TimeStyle.flip:
        retWidget = buildHourFlipItem(h, ic, skinBasePath);
        break;
      default:
        retWidget = nullWidget;
        break;
    }
    return retWidget;
  }

  Widget buildMinute(int m, ItemConfig? ic) {
    if (ic == null) return nullWidget;
    Widget retWidget;
    switch (TimeStyle.values[ic.style]) {
      case TimeStyle.number:
        retWidget = buildTextItem(int2Str(m, width: 2), ic.rect, ic.textStyle);
        break;
      case TimeStyle.chinese:
        retWidget =
            buildTextItem(int2Str(m, width: 2) + "???", ic.rect, ic.textStyle);
        break;
      case TimeStyle.pic:
        retWidget = buildPicItem(m, ic);
        break;
      case TimeStyle.flip:
        retWidget = buildMinuteFlipItem(m, ic, skinBasePath);
        break;
      default:
        retWidget = nullWidget;
        break;
    }
    return retWidget;
  }

  Widget buildSecond(int s, ItemConfig? ic) {
    if (ic == null) return nullWidget;
    Widget retWidget;
    switch (TimeStyle.values[ic.style]) {
      case TimeStyle.number:
        retWidget = buildTextItem(int2Str(s, width: 2), ic.rect, ic.textStyle);
        break;
      case TimeStyle.chinese:
        retWidget =
            buildTextItem(int2Str(s, width: 2) + "???", ic.rect, ic.textStyle);
        break;
      case TimeStyle.pic:
        retWidget = buildPicItem(s, ic);
        break;
      case TimeStyle.flip:
        retWidget = buildMinuteFlipItem(s, ic, skinBasePath);
        break;
      default:
        retWidget = nullWidget;
        break;
    }
    return retWidget;
  }

  Widget buildTiktok(int t, ItemConfig? ic) {
    if (ic == null) return nullWidget;
    Widget retWidget;
    switch (TikTokStyle.values[ic.style]) {
      case TikTokStyle.text:
        retWidget = buildTextItem(t == 0 ? "" : ":", ic.rect, ic.textStyle);
        break;
      case TikTokStyle.pic:
        retWidget = buildPicItem(t, ic);
        break;
      case TikTokStyle.icon:
      default:
        retWidget = nullWidget;
        break;
    }
    return retWidget;
  }

  Widget buildH12(int f, ItemConfig? ic) {
    if (ic == null) return nullWidget;
    Widget retWidget;
    switch (H12Style.values[ic.style]) {
      case H12Style.text:
        retWidget = buildTextItem(f == 0 ? "AM" : "PM", ic.rect, ic.textStyle);
        break;
      case H12Style.pic:
        retWidget = buildPicItem(f, ic);
        break;
      case H12Style.icon:
      default:
        retWidget = nullWidget;
        break;
    }
    return retWidget;
  }

  Widget buildBackgroundImage(String? bgImage) {
    if (bgImage == null) return nullWidget;
    return Container(
      height: widget.height,
      width: widget.width,
      child: buildImage("${widget.config.skinBasePath}$bgImage",
          Size(widget.width, widget.height),
          fit: BoxFit.fill),
    );
  }

  Widget buildBodyImage(ItemConfig? bodyImage) {
    if (bodyImage == null) return nullWidget;

    String? picName;
    if (bodyImage.imgs != null &&
        bodyImage.imgs!.isNotEmpty &&
        bodyImage.imgs!.length > 0) {
      picName = "${widget.config.skinBasePath}${bodyImage.imgs!.first}";
    }
    // logger.fine(
    //     "height: ${widget.config.height * scale},width: ${widget.config.width * scale},rect:${buildEdgeRect(bodyImage.rect).collapsedSize}");
    return Container(
      height: widget.config.height * scale,
      width: widget.config.width * scale,
      // color: Colors.grey.withAlpha(50),
      margin: buildEdgeRect(bodyImage.rect),
      alignment: Alignment.center,
      child: buildImage(
        picName,
        bodyImage.rect.size,
        fit: BoxFit.contain,
      ),
    );
  }

  Widget buildExitControl(ItemConfig? exitItem) {
    if (exitItem == null) return nullWidget;

    String? picName;
    if (exitItem.imgs != null && exitItem.imgs!.length > 0) {
      picName = "${widget.config.skinBasePath}${exitItem.imgs!.first}";
    }
    if (exitItem.imgPrename != null || exitItem.imgExtname != null) {
      picName =
          "$widget.config.skinBasePath${exitItem.imgPrename}00${exitItem.imgExtname}";
    }
    // print("exitRect:${exitItem.rect}");
    return GestureDetector(
      onTap: () {
        widget.fireClockEvent(ClockEvent(ClockEventType.exit, value: context));
        if (widget.onExitAction != null)
          widget.onExitAction!(context);
        else {
          showDialog(
              context: context,
              builder: (context) => AlertDialog(
                    title: Text("????????????????????????????????????"),
                    actions: <Widget>[
                      TextButton(
                        child: Text("?????????"),
                        onPressed: () => Navigator.pop(context, false),
                      ),
                      TextButton(
                        child: Text("????????????"),
                        onPressed: () => SystemNavigator.pop(),
                      ),
                    ],
                  ));
        }
      },
      child: Container(
        color: Colors.transparent,
        // color: Colors.grey.withAlpha(50),
        // height: widget.config.height * scale,
        // width: widget.config.width * scale,
        height: exitItem.rect.height * scale,
        width: exitItem.rect.width * scale,
        margin: buildEdgeRect(exitItem.rect),
        alignment: Alignment.center,
        child: exitItem.style == ActionStyle.pic.index && picName != null
            ? buildImage(
                picName,
                exitItem.rect.size,
                fit: BoxFit.cover,
              )
            : exitItem.style == ActionStyle.icon.index && picName != null
                ? Icon(
                    IconData(int.parse(picName), fontFamily: "MaterialIcons"),
                    color: Colors.white,
                  )
                : nullWidget,
      ),
    );
  }

  Widget buildSettingControl(ItemConfig? settingItem, String basePath) {
    if (settingItem == null) return nullWidget;

    String? picName;
    if (settingItem.style == ActionStyle.pic.index) {
      if (settingItem.imgs != null &&
          settingItem.imgs!.isNotEmpty &&
          settingItem.imgs!.length > 0) {
        picName = basePath + settingItem.imgs!.first;
      }
      if (settingItem.imgPrename != null || settingItem.imgExtname != null) {
        picName =
            "$basePath${settingItem.imgPrename}00${settingItem.imgExtname}";
      }
    }
    if (settingItem.style == ActionStyle.icon.index) {
      if (settingItem.imgs != null &&
          settingItem.imgs!.isNotEmpty &&
          settingItem.imgs!.length > 0) {
        picName = settingItem.imgs!.first;
      }
    }
    // print("skinRect:${skinItem.rect}");
    return GestureDetector(
      onTap: () => widget.fireClockEvent(ClockEvent(ClockEventType.setting)),
      child: Container(
        color: Colors.transparent,
        // color: Colors.grey.withAlpha(50),
        // height: widget.config.height * scale,
        // width: widget.config.width * scale,
        height: settingItem.rect.height * scale,
        width: settingItem.rect.width * scale,
        margin: buildEdgeRect(settingItem.rect),
        // alignment: Alignment.center,
        child: settingItem.style == ActionStyle.pic.index && picName != null
            ? buildImage(
          picName,
                settingItem.rect.size,
                fit: BoxFit.cover,
              )
            : settingItem.style == ActionStyle.icon.index && picName != null
                ? Icon(
                    new IconData(int.parse(picName),
                        fontFamily: "MaterialIcons"),
                    color: widget.config.foregroundColor,
                    size: 12 * scale,
                  )
                : nullWidget,
      ),
    );
  }

  Widget buildSlientControl(ItemConfig? slientItem, String basePath) {
    if (slientItem == null) return nullWidget;

    String? picName;
    if (slientItem.style == ActionStyle.pic.index) {
      if (slientItem.imgs != null && slientItem.imgs!.length > 1) {
        if (isSlient)
          picName = "$basePath${slientItem.imgs![0]}";
        else
          picName = "$basePath${slientItem.imgs![1]}";
      }
      if (slientItem.imgPrename != null || slientItem.imgExtname != null) {
        if (isSlient)
          picName =
              "$basePath${slientItem.imgPrename}00${slientItem.imgExtname}";
        else
          picName =
              "$basePath${slientItem.imgPrename}01${slientItem.imgExtname}";
      }
    }
    if (slientItem.style == ActionStyle.icon.index) {
      if (slientItem.imgs != null && slientItem.imgs!.length > 1) {
        if (isSlient)
          picName = slientItem.imgs![0];
        else
          picName = slientItem.imgs![1];
      }
    }
    // print("skinRect:${skinItem.rect}");
    return GestureDetector(
      onTap: () => setState(() {
        isSlient = !isSlient;
        widget.fireClockEvent(
            ClockEvent(ClockEventType.slientChange, value: isSlient));
      }),
      child: Container(
        color: Colors.transparent,
        // height: widget.config.height * scale,
        // width: widget.config.width * scale,
        height: slientItem.rect.height * scale,
        width: slientItem.rect.width * scale,
        margin: buildEdgeRect(slientItem.rect),
        alignment: Alignment.center,
        child: slientItem.style == ActionStyle.pic.index
            ? buildImage(
          picName,
                slientItem.rect.size,
                fit: BoxFit.cover,
              )
            : slientItem.style == ActionStyle.icon.index
                ? Icon(
                    new IconData(int.parse(picName ?? "58751"),
                        fontFamily: "MaterialIcons"),
                    color: widget.config.foregroundColor,
                    size: slientItem.rect.height * scale,
                  )
                : nullWidget,
      ),
    );
  }

  Future exitCountDownDialog(BuildContext context) {
    return showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: Text("?????????????????????????????????"),
              actions: <Widget>[
                TextButton(
                  child: Text("?????????"),
                  onPressed: () => Navigator.pop(context, false),
                ),
                TextButton(
                  child: Text("????????????"),
                  onPressed: () => Navigator.pop(context, true),
                ),
              ],
            ));
  }

  Widget buildCountDownControl(ItemConfig? countDownItem, String basePath) {
    if (countDownItem == null) return nullWidget;

    String? picName;
    if (countDownItem.style == ActionStyle.pic.index) {
      if (countDownItem.imgs != null && countDownItem.imgs!.length > 1) {
        if (isSlient)
          picName = "$basePath${countDownItem.imgs![0]}";
        else
          picName = "$basePath${countDownItem.imgs![1]}";
      }
      if (countDownItem.imgPrename != null ||
          countDownItem.imgExtname != null) {
        if (isSlient)
          picName =
              "$basePath${countDownItem.imgPrename}00${countDownItem.imgExtname}";
        else
          picName =
              "$basePath${countDownItem.imgPrename}01${countDownItem.imgExtname}";
      }
    }
    if (countDownItem.style == ActionStyle.icon.index) {
      if (countDownItem.imgs != null && countDownItem.imgs!.length > 1) {
        if (countDownMode) {
          picName = countDownItem.imgs![0];
        } else {
          picName = countDownItem.imgs![1];
        }
      }
    }
    // print("skinRect:${skinItem.rect}");
    return GestureDetector(
      onTap: () async {
        if (countDownMode) {
          // refreshTime(DateTime.now());
          if (await exitCountDownDialog(context)) {
            countDownOver(cancel: true);
          }
        } else {
          int cdMin = await showAlarmSelect(context);

          if (cdMin > 0) {
            countDownBegin(cdMin);
          }
        }
      },
      child: Container(
        color: Colors.transparent,
        // height: widget.config.height * scale,
        // width: widget.config.width * scale,
        height: countDownItem.rect.height * scale,
        width: countDownItem.rect.width * scale,
        margin: buildEdgeRect(countDownItem.rect),
        alignment: Alignment.center,
        child: countDownItem.style == ActionStyle.pic.index
            ? buildImage(
                picName,
                countDownItem.rect.size,
                fit: BoxFit.cover,
              )
            : countDownItem.style == ActionStyle.icon.index
                ? Icon(
                    new IconData(
                        int.parse(
                            picName ?? Icons.restore.codePoint.toString()),
                        fontFamily: "MaterialIcons"),
                    color: widget.config.foregroundColor,
                    size: countDownItem.rect.height * scale,
                  )
                : nullWidget,
      ),
    );
  }

  Widget buildCountDownHour(int h, ItemConfig? ic) {
    if (ic == null) return nullWidget;
    Widget retWidget;
    switch (TimeStyle.values[ic.style]) {
      case TimeStyle.number:
        retWidget = buildTextItem(int2Str(h, width: 2), ic.rect, ic.textStyle);
        break;
      case TimeStyle.chinese:
        retWidget =
            buildTextItem(int2Str(h, width: 2) + "???", ic.rect, ic.textStyle);
        break;
      case TimeStyle.pic:
        retWidget = buildPicItem(h, ic);
        break;
      case TimeStyle.flip:
        retWidget = buildCdHourFlipItem(h, ic, skinBasePath);
        break;
      default:
        retWidget = nullWidget;
        break;
    }
    return retWidget;
  }

  Widget buildCountDownMinute(int m, ItemConfig? ic) {
    if (ic == null) return nullWidget;
    Widget retWidget;
    switch (TimeStyle.values[ic.style]) {
      case TimeStyle.number:
        retWidget = buildTextItem(int2Str(m, width: 2), ic.rect, ic.textStyle);
        break;
      case TimeStyle.chinese:
        retWidget =
            buildTextItem(int2Str(m, width: 2) + "???", ic.rect, ic.textStyle);
        break;
      case TimeStyle.pic:
        retWidget = buildPicItem(m, ic);
        break;
      case TimeStyle.flip:
        retWidget = buildCdMinuteFlipItem(m, ic, skinBasePath);
        break;
      default:
        retWidget = nullWidget;
        break;
    }
    return retWidget;
  }

  Widget buildCountDownSecond(int s, ItemConfig? ic) {
    if (ic == null) return nullWidget;
    Widget retWidget;
    switch (TimeStyle.values[ic.style]) {
      case TimeStyle.number:
        retWidget = buildTextItem(int2Str(s, width: 2), ic.rect, ic.textStyle);
        break;
      case TimeStyle.chinese:
        retWidget =
            buildTextItem(int2Str(s, width: 2) + "???", ic.rect, ic.textStyle);
        break;
      case TimeStyle.pic:
        retWidget = buildPicItem(s, ic);
        break;
      case TimeStyle.flip:
        retWidget = buildCdSecondFlipItem(s, ic, skinBasePath);
        break;
      default:
        retWidget = nullWidget;
        break;
    }
    return retWidget;
  }

  Widget showClock() {
    return Container(
        height: widget.height,
        width: widget.width,
        color: animation.value ?? widget.config.backgroundColor,
        child: Stack(
          alignment: Alignment.center,
          children: [
            //----------------------??????????????????----------------------
            ///???????????????
            buildBackgroundImage(widget.config.backgroundImage),

            ///????????????
            buildBodyImage(widget.config.bodyImage),

            //----------------------???????????????????????????----------------------
            ///slient
            buildSlientControl(
                widget.config.slientItem, widget.config.skinBasePath ?? ""),

            ///countDown
            buildCountDownControl(
                widget.config.countDownItem, widget.config.skinBasePath ?? ""),

            //----------------------??????????????????----------------------

            ///Tiktok
            buildTiktok(tk, widget.config.tiktokItem),

            ///???????????????
            widget.config.timeType == TimeType.h12
                ? buildH12(h12, widget.config.h12Item)
                : Container(),

            ///???
            buildYear(years, widget.config.yearItem),

            ///???
            buildMonth(months, widget.config.monthItem),

            ///???
            buildDay(days, widget.config.dayItem),

            ///??????
            buildWeekDay(weekday, widget.config.weekdayItem),

            ///??????
            buildHour(hours, widget.config.hourItem),

            ///??????
            buildMinute(minutes, widget.config.minuteItem),

            //----------------------???????????????????????????----------------------
            ///setting
            buildSettingControl(
                widget.config.settingItem, widget.config.skinBasePath ?? ""),

            ///exit
            buildExitControl(widget.config.exitItem),
          ],
        ));
  }

  Widget showCountDown() {
    return Container(
        height: widget.height,
        width: widget.width,
        color: animation.value ?? widget.config.backgroundColor,
        child: Stack(
          alignment: Alignment.center,
          children: [
            //----------------------??????????????????----------------------
            ///???????????????
            buildBackgroundImage(widget.config.backgroundImage),

            ///????????????
            buildBodyImage(widget.config.bodyImage),

            //----------------------???????????????????????????----------------------
            ///slient
            buildSlientControl(
                widget.config.slientItem, widget.config.skinBasePath ?? ""),

            ///countDown
            buildCountDownControl(
                widget.config.countDownItem, widget.config.skinBasePath ?? ""),

            //----------------------??????????????????----------------------
            ///Tiktok
            buildTiktok(tk, widget.config.tiktokItem),

            ///???????????????
            buildCountDownHour(cdHours!, widget.config.cdHourItem),

            ///???????????????
            buildCountDownMinute(cdMinutes!, widget.config.cdMinuteItem),

            ///???????????????
            buildCountDownSecond(cdSeconds!, widget.config.cdSecondItem),

            //----------------------???????????????????????????----------------------

            ///skin
            buildSettingControl(
                widget.config.settingItem, widget.config.skinBasePath ?? ""),

            ///exit
            buildExitControl(widget.config.exitItem),
          ],
        ));
  }

  @override
  Widget build(BuildContext context) {
    // if (widget.sizeChange) {
    //   initScale();
    // }
    if (widget.config.skinName.compareTo(currentSkinName) != 0 ||
        widget.sizeChange) {
      // initScale();
      init();
    }
    return countDownMode ? showCountDown() : showClock();
  }
}

enum ClockStyle { digital, watch }
enum DateStyle { number, chinese, english, shortEnglish, pic }
enum TimeStyle { number, chinese, pic, flip }
enum TimeType { h24, h12 }
enum H12 { am, pm }
enum H12Style { text, pic, icon }
enum TikTokStyle { text, pic, icon }
enum ActionStyle { text, pic, icon, empty }

enum ClockEventType {
  countDownStart,
  countDownStop,
  slientChange,
  slientScheduleChange,
  sleepScheduleChange,
  skinChange,
  exit,
  setting
}

class ClockEvent {
  ClockEventType clockEventType;
  dynamic value;
  ClockEvent(this.clockEventType, {this.value});
}

class ItemConfig {
  int style; //?????????index????????????item?????????????????????????????????
  Rect rect; //item????????????????????????????????????
  List<String>? imgs; //????????????imgs?????????imgs???null????????????imgPrename???imgExtname;
  String? imgPrename; //??????????????????????????? hour00.png ?????? "hour"
  String? imgExtname; //??????????????????????????? hour00.png ?????? ".png"
  TextStyle textStyle; //????????????????????????item???????????????????????????????????????

  ItemConfig({
    required this.style,
    required this.rect,
    this.imgs,
    this.imgPrename,
    this.imgExtname,
    this.textStyle = const TextStyle(fontSize: 12),
  });

  static ItemConfig? fromString(String? itemJsonStr) {
    if (itemJsonStr == null) return null;
    return json.decode(itemJsonStr);
  }

  static ItemConfig? fromJson(Map<String, dynamic>? j) {
    if (j == null) return null;
    return ItemConfig(
        style: j["style"],
        rect: json2Rect(j["rect"]) ?? Rect.fromLTRB(-10, -10, 10, 10),
        // imgs: objectListToStringList(j["imgs"]),
        imgs: j["imgs"] == null ? null : List.castFrom(j["imgs"]),
        imgPrename: j["imgPrename"],
        imgExtname: j["imgExtname"],
        textStyle: json2TextStyle(j["textStyle"]) ?? TextStyle(fontSize: 12));
  }

  @override
  String toString() => json.encode(toJson());

  Map<String, dynamic> toJson() {
    return {
      "style": style,
      "rect": rect2Json(rect),
      "imgs": imgs,
      "imgPrename": imgPrename,
      "imgExtname": imgExtname,
      "textStyle": textStyle2Json(textStyle),
    };
  }

  Map<String, dynamic>? textStyle2Json(TextStyle? ts) {
    if (ts == null) return null;
    return {
      "fontSize": ts.fontSize,
      "color": ts.color?.value,
      "fontFamily": ts.fontFamily,
    };
  }

  static TextStyle? json2TextStyle(Map<String, dynamic>? jts) {
    if (jts == null) return null;
    return TextStyle(
        fontSize: jts["fontSize"] ?? 12,
        color: Color(jts["color"] ?? 0x00000000),
        fontFamily: jts["fontFamily"]);
  }

  Map<String, double>? rect2Json(Rect? rect) {
    if (rect == null) return null;
    return {
      "left": rect.left,
      "top": rect.top,
      "right": rect.right,
      "bottom": rect.bottom
    };
  }

  static Rect? json2Rect(Map<String, dynamic>? jRect) {
    if (jRect == null) return null;
    return Rect.fromLTRB(
        jRect["left"], jRect["top"], jRect["right"], jRect["bottom"]);
  }
}

class DigitalClockConfig {
  static bool debugMode = true;

  String skinName;
  String? skinBasePath;

  ///??????????????????
  ItemConfig? yearItem, monthItem, dayItem, weekdayItem;

  ///??????????????????
  ItemConfig? hourItem, minuteItem, secondItem;

  ItemConfig? cdHourItem, cdMinuteItem, cdSecondItem;

  ///12????????????????????????
  TimeType timeType;
  ItemConfig? h12Item;

  ///???????????????
  ItemConfig? tiktokItem;

  ///??????????????????
  ItemConfig? settingItem;

  ///??????/????????????
  ItemConfig? exitItem;

  ///????????????
  ItemConfig? slientItem;

  ///???????????????
  ItemConfig? countDownItem;

  ///????????????
  Color backgroundColor;

  ///???????????????????????????????????????backgroundColor????????????
  Color blinkColor;

  ///????????????
  String? backgroundImage;

  ///????????????
  Color foregroundColor;

  ///????????????
  ItemConfig? bodyImage;

  ///??????????????????
  double height;
  double width;

  DigitalClockConfig(this.skinName,
      {this.skinBasePath,
      this.yearItem,
      this.monthItem,
      this.dayItem,
      this.weekdayItem,
      this.timeType = TimeType.h24,
      this.hourItem,
      this.minuteItem,
      this.secondItem,
      this.h12Item,
      this.tiktokItem,
      this.settingItem,
      this.exitItem,
      this.slientItem,
      this.countDownItem,
      this.cdHourItem,
      this.cdMinuteItem,
      this.cdSecondItem,
      this.backgroundColor = Colors.black,
      this.blinkColor = Colors.white,
      this.backgroundImage,
      this.foregroundColor = Colors.white,
      this.bodyImage,
      this.height = 100,
      this.width = 200});

  static DigitalClockConfig? fromFile(File? configFile) {
    if (configFile == null || !configFile.existsSync()) return null;
    return fromJson(configFile.readAsStringSync());
  }

  static DigitalClockConfig? fromJson(String? jsonStr) {
    if (jsonStr == null) return null;

    var jMap = jsonDecode(jsonStr);
    return DigitalClockConfig(
      jMap["skinName"],
      skinBasePath: jMap["skinBasePath"],
      yearItem: ItemConfig.fromJson(jMap["yearItem"]),
      monthItem: ItemConfig.fromJson(jMap["monthItem"]),
      dayItem: ItemConfig.fromJson(jMap["dayItem"]),
      weekdayItem: ItemConfig.fromJson(jMap["weekdayItem"]),
      hourItem: ItemConfig.fromJson(jMap["hourItem"]),
      minuteItem: ItemConfig.fromJson(jMap["minuteItem"]),
      secondItem: ItemConfig.fromJson(jMap["secondItem"]),
      h12Item: ItemConfig.fromJson(jMap["h12Item"]),
      tiktokItem: ItemConfig.fromJson(jMap["tiktokItem"]),
      settingItem: ItemConfig.fromJson(jMap["settingItem"]),
      exitItem: ItemConfig.fromJson(jMap["exitItem"]),
      slientItem: ItemConfig.fromJson(jMap["slientItem"]),
      countDownItem: ItemConfig.fromJson(jMap["countDownItem"]),
      cdHourItem: ItemConfig.fromJson(jMap["cdHourItem"]),
      cdMinuteItem: ItemConfig.fromJson(jMap["cdMinuteItem"]),
      cdSecondItem: ItemConfig.fromJson(jMap["cdSecondItem"]),
      backgroundColor: Color(jMap["backgroundColor"] ?? 0x00000000),
      blinkColor:
          jMap["blinkColor"] == null ? Colors.white : Color(jMap["blinkColor"]),
      foregroundColor: Color(jMap["foregroundColor"] ?? 0x00ffffff),
      backgroundImage: jMap["backgroundImage"],
      bodyImage: ItemConfig.fromJson(jMap["bodyImage"]),
      timeType: TimeType.values[jMap["timeType"] ?? 1],
      height: jMap["height"],
      width: jMap["width"],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "skinName": skinName,
      "skinBasePath": skinBasePath,
      "yearItem": yearItem,
      "monthItem": monthItem,
      "dayItem": dayItem,
      "weekdayItem": weekdayItem,
      "hourItem": hourItem,
      "minuteItem": minuteItem,
      "secondItem": secondItem,
      "timeType": timeType.index,
      "h12Item": h12Item,
      "tiktokItem": tiktokItem,
      "settingItem": settingItem,
      "exitItem": exitItem,
      "slientItem": slientItem,
      "countDownItem": countDownItem,
      "cdHourItem": cdHourItem,
      "cdMinuteItem": cdMinuteItem,
      "cdSecondItem": cdSecondItem,
      "backgroundColor": backgroundColor.value,
      "blinkColor": blinkColor.value,
      "foregroundColor": foregroundColor.value,
      "backgroundImage": backgroundImage,
      "bodyImage": bodyImage,
      "height": height,
      "width": width,
    };
  }

  @override
  String toString() {
    return json.encode(toJson());
  }
}
