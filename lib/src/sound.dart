import 'package:flutter/services.dart';
import 'package:soundpool/soundpool.dart';

class Sound {
  static Soundpool soundpool;

  static Future init() async {
    soundpool = Soundpool(
      maxStreams: 1,
    );
  }

  static void play(int soundId, {bool repeat = false, Duration duration}) async {
    ///不允许无限循环并无时长控制，自动修复为只播放一次
    if (repeat && duration == null) repeat = false;
    int streamId = await soundpool.play(
        soundId, repeat: (repeat ?? false) ? -1 : 0);
    if (duration != null && repeat && streamId != 0)
      Future.delayed(duration, () => soundpool.stop(streamId));
  }

  static Future<int> loadSound(dynamic soundMedia) async {
    if (soundpool == null) await init();
    if (soundMedia is ByteData) return await soundpool.load(soundMedia);
    if (soundMedia is Uri)
      return await soundpool.loadUri(soundMedia.origin + soundMedia.path);
    if (soundMedia is String)
      return await soundpool.load(await rootBundle.load(soundMedia));
    return -1;
  }
}