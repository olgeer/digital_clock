import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'digitalClock.dart';

class FlipNumber extends StatefulWidget {
  final ItemConfig numberItem;
  final String basePath;
  final double scale;
  final Duration animationDuration;
  final int min, max;
  int currentValue;
  final bool canRevese, isPositiveSequence;
  AnimationController controller;

  FlipNumber({
    @required this.numberItem,
    @required this.basePath,
    this.scale = 1.0,
    this.animationDuration = const Duration(milliseconds: 2000),
    this.min = 0,
    this.max = 23,
    this.canRevese = true,
    this.isPositiveSequence = true,
    this.currentValue = 0,
  });

  @override
  State<StatefulWidget> createState() {
    return _FlipNumberState();
  }
}

class _FlipNumberState extends State<FlipNumber>
    with SingleTickerProviderStateMixin {
  // 动画总控制器
  AnimationController _controller;
  // 上数字 动画
  Animation<double> _upAnimation;
  // 下数字 动画
  Animation<double> _downAnimation;
  // 是否正序
  bool _isPositiveSequence;
  // 当前数值
  int _currentIndex;
  // 下一个数值
  int _nextIndex;

  Logger logger = Logger("FlipNumber");

  @override
  void initState() {
    super.initState();

    logger.finer("initState running...");
    _isPositiveSequence = widget.isPositiveSequence;
    calcValue(initValue: widget.currentValue ?? widget.min);
    widget.currentValue = null;

    // 5 秒动画，利用 reset、forward 重复执行
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    widget.controller = _controller;
    // print("FlipNumberState._controller=${widget.controller}");

    // 上数字动画
    // controller总动画比例为 0~1，Interval 参数为该比例。
    // 控制在 0.0~0.5。
    _upAnimation = Tween(
      begin: 0.0,
      end: pi / 2,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.0, 0.5),
      ),
    );
    // 下数字动画
    // controller总动画比例为 0~1，Interval 参数为该比例。
    // 控制在 0.51~1。
    _downAnimation = Tween(
      begin: 0.0,
      end: pi / 2,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.51, 1),
      ),
    );
    // 手动进行 setState，否则动画不执行。
    // 你可以使用 AnimatedContainer 等部件替代
    _controller.addListener(() {
      setState(() {});
    });

    // 动画完成时，添加数字检测，实现动画
    _controller.addStatusListener(animationListener);
    // 默认开启动画，也使用 press 效果触发。
    // _controller.forward();
  }

  void animationListener(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      calcValue(initValue: widget.currentValue);
      // 重置动画
      _controller.reset();
      // 重新开启动画
      // _controller.forward();
      setState(() {});
    }
  }

  @override
  void dispose() {
    _controller.removeStatusListener(animationListener);
    _controller.dispose();
    super.dispose();
  }

  int calcValue({int initValue}) {
    _currentIndex = initValue ?? _nextIndex;
    // 正序则累加，倒序则累减；进行边际控制。
    if (_isPositiveSequence) {
      _nextIndex = _currentIndex + 1;
      if (_nextIndex > widget.max) {
        if (widget.canRevese) {
          _isPositiveSequence = !_isPositiveSequence;
          // _currentIndex = widget.max;
          _nextIndex = _currentIndex - 1;
        } else {
          // _currentIndex = widget.min;
          _nextIndex = widget.min;
        }
      }
    } else {
      _nextIndex = _currentIndex - 1;
      if (_nextIndex < widget.min) {
        if (widget.canRevese) {
          _isPositiveSequence = !_isPositiveSequence;
          // _currentIndex = widget.min;
          _nextIndex = _currentIndex + 1;
        } else {
          // _currentIndex=widget.max;
          _nextIndex = widget.max;
        }
      }
    }
    // print("current=$_currentIndex");
    // print("next=$_nextIndex");
    return _nextIndex;
  }

  // ClipRect 做比例切割，形成图片效果
  Widget _makeUpper(int number) {
    return ClipRect(
      child: Align(
        alignment: Alignment.topCenter,
        heightFactor: 0.5,
        child: Pannel(
          scale: widget.scale,
          basePath: widget.basePath,
          picItem: widget.numberItem,
          value: number,
        ),
      ),
    );
  }

  Widget _makeLower(int number) {
    return ClipRect(
      child: Align(
        alignment: Alignment.bottomCenter,
        heightFactor: 0.5,
        child: Pannel(
          scale: widget.scale,
          basePath: widget.basePath,
          picItem: widget.numberItem,
          value: number,
        ),
      ),
    );
  }

  // 默认隐藏
  Widget uppeer1() {
    return _makeUpper(_nextIndex);
  }

  // 默认展示
  Widget upper2() {
    return Transform(
      alignment: Alignment.bottomCenter,
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.002)
        ..rotateX(_upAnimation.value),
      child: _makeUpper(_currentIndex),
    );
  }

  // 默认展示
  Widget lower1() {
    return _makeLower(_currentIndex);
  }

  // 默认隐藏，角度是垂直于屏幕的，实现下翻效果。
  Widget lower2() {
    return Transform(
      alignment: Alignment.topCenter,
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.002)
        ..rotateX(pi / 2 * 3)
        ..rotateX(_downAnimation.value),
      child: _makeLower(_nextIndex),
    );
  }

  // Stack 堆栈效果
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Stack(
          children: <Widget>[
            uppeer1(),
            upper2(),
          ],
        ),
        Stack(
          children: <Widget>[
            lower1(),
            lower2(),
          ],
        ),
      ],
    );
  }
}

class Pannel extends StatelessWidget {
  ItemConfig picItem;
  int value;
  String basePath;
  double scale;
  Pannel({
    this.value,
    this.picItem,
    this.basePath,
    this.scale,
  });

  Widget buildImage(String picName, {BoxFit fit = BoxFit.cover}) {
    return picName.contains("assets:")
        ? Image.asset(
            picName.replaceFirst("assets:", ""),
            fit: fit,
          )
        : Image.file(
            File(picName),
            fit: fit,
          );
  }

  String int2Str(int value, {int width = 2}) {
    String s = value.toString();
    for (int i = 0; i < (width - s.length); i++) {
      s = "0" + s;
    }
    return s;
  }

  @override
  Widget build(BuildContext context) {
    if (picItem.imgs == null &&
        picItem.imgPrename == null &&
        picItem.imgExtname == null) {
      return Container(
        height: picItem.rect.height * scale,
        width: picItem.rect.width * scale,
        color: Colors.black,
        alignment: Alignment.center,
        child: Text(
          int2Str(value),
          style: TextStyle(
            color: Colors.white,
            fontSize: picItem.textStyle.fontSize * scale,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }
    String picName;
    if (picItem.imgs != null &&
        picItem.imgs.isNotEmpty &&
        value < picItem.imgs.length) {
      picName = basePath + picItem.imgs[value];
    } else {
      picName =
          "$basePath${picItem.imgPrename ?? ""}${int2Str(value)}${picItem.imgExtname ?? ""}";
    }
    // print(picName);
    return Container(
      // color: Colors.white12,
      height: picItem.rect.height * scale,
      width: picItem.rect.width * scale,
      margin: EdgeInsets.all(0.0),
      alignment: Alignment.center,
      child: buildImage(
        picName,
        fit: BoxFit.cover,
      ),
    );
  }
}
