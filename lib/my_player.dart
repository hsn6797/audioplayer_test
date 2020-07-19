import 'dart:io';

import 'package:http/http.dart';
import 'package:path_provider/path_provider.dart';
import 'package:just_audio/just_audio.dart';

const String TAG = '{ MyPlayer }: ';

class MyPlayer {
  String _audioFilePath;
//  Duration _startPosition;
//  Duration _endPosition;

  AudioPlayer player;

  MyPlayer() {
    if (Platform.isIOS) AudioPlayer.setIosCategory(IosCategory.playback);
    player = AudioPlayer();
  }

  void releasePlayer() async => await player.dispose();

  Future<Duration> setUpPlayer(String url) async {
    return await player.setUrl(url);
  }

  Future<Duration> seekToNewPosition(Duration s, Duration e) async {
//    // Set the position  from where audio starts
//    this._startPosition = s;
//    // Set the position where audio ends
//    this._endPosition = e;

    // Return true if successfully seek to audio start position, false otherwise
    return await player.setClip(start: s, end: e);
  }

  get audioFilePath => _audioFilePath;

  Future<void> playAudio() async {
    return await player.play();
  }

  Future<void> stopAudio() async {
    return await player.stop();
  }

  Future<void> pauseAudio() async {
    return player.pause();
  }

  Future<File> _downloadAudioFile({String url, File destinationFile}) async {
    try {
      final bytes = await readBytes(url);
      File f = await destinationFile.create(recursive: true);

      var fa = await f.open(mode: FileMode.write);
      File finalFile = await f.writeAsBytes(bytes);
      await fa.close();
      return finalFile;
    } catch (err) {
      print(err);
      return null;
    }
  }

  Future loadAudio(String url,
      {bool download = false, String fileName = ''}) async {
    var dir;

    if (Platform.isIOS) {
      dir = await getApplicationDocumentsDirectory();
    } else {
      dir = await getExternalStorageDirectory();
    }

    File file = File('${dir.path}/Audio/$fileName');
    if (await file.exists() == false) {
      if (download) {
        File f1 =
            await this._downloadAudioFile(url: url, destinationFile: file);
        if (f1 != null) _audioFilePath = f1.path;
      } else {
        _audioFilePath = url;
      }
    } else {
      // File Exists in Phone Storage
      _audioFilePath = file.path;
    }
  }
}
