import 'package:flutter/services.dart';
import 'package:soundpool/soundpool.dart';

class Sound {
  static late Soundpool soundpool;
  static bool inited = false;
  static bool loaded = false;

  static Future init() async {
    soundpool = Soundpool.fromOptions(
      options: SoundpoolOptions(maxStreams: 1),
    );
    inited = true;
  }

  static void play(int soundId,
      {bool repeat = false, Duration? duration}) async {
    if (inited && loaded) {
      ///不允许无限循环并无时长控制，自动修复为只播放一次
      if (repeat && duration == null) repeat = false;
      int streamId = await soundpool.play(soundId, repeat: repeat ? -1 : 0);
      if (duration != null && repeat && streamId != 0)
        Future.delayed(duration, () => soundpool.stop(streamId));
    }
  }

  static Future<int> loadSound(dynamic soundMedia) async {
    if (!inited) await init();
    loaded = true;
    if (soundMedia is ByteData) return await soundpool.load(soundMedia);
    if (soundMedia is Uri)
      return await soundpool.loadUri(soundMedia.origin + soundMedia.path);
    if (soundMedia is String)
      return await soundpool.load(await rootBundle.load(soundMedia));
    loaded = false;
    return -1;
  }
}