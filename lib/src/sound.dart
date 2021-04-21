import 'package:flutter/services.dart';
import 'package:soundpool/soundpool.dart';

final Map<String, String> effectVoice = {
  "玻璃撞击声": "玻璃撞击声.mp3",
  "短促喇叭声": "短促喇叭声.mp3",
  "座钟报时": "座钟报时.mp3",
  "钟琴颤音": "钟琴颤音.mp3",
  "短促欢愉": "短促欢愉.mp3",
  "短促嘟嘟声": "短促嘟嘟声.mp3",
  "华为铃声": "华为铃声.mp3",
  "机械闹钟铃声": "机械闹钟铃声.mp3",
  "iphone铃声": "iphone铃声.mp3",
};

Soundpool soundpool;

void initSound() async {
  soundpool = Soundpool(
    maxStreams: 1,
  );
}

void play(int soundId, {bool repeat=false, Duration duration}) async {
  ///不允许无限循环并无时长控制，自动修复为只播放一次
  if(repeat && duration==null)repeat=false;
  int streamId = await soundpool.play(soundId, repeat: (repeat??false)?-1:0);
  if (duration != null && repeat && streamId != 0)
    Future.delayed(duration, () => soundpool.stop(streamId));
}

Future<int> loadSound(dynamic soundMedia) async {
  if (soundpool == null) initSound();
  if (soundMedia is ByteData) return await soundpool.load(soundMedia);
  if (soundMedia is Uri)
    return await soundpool.loadUri(soundMedia.origin+soundMedia.path);
  if (soundMedia is String)
    return await soundpool.load(await rootBundle.load(soundMedia));
  return -1;
}