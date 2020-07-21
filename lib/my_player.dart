import 'dart:io';

import 'package:http/http.dart';
import 'package:path_provider/path_provider.dart';
import 'package:just_audio/just_audio.dart';

const String TAG = '{ MyPlayer }: ';

class MyPlayer {
  String _audioFilePath;
  Duration _startPosition;
  Duration _endPosition;

  AudioPlayer player;

  MyPlayer() {
    if (Platform.isIOS) AudioPlayer.setIosCategory(IosCategory.playback);
    player = AudioPlayer();

//    player.getPositionStream().listen((event) {
//      // Track the position
//      print(event);
//      if (_endPosition != null && event >= _endPosition) player.pause();
//    });
  }

  String get audioFilePath => _audioFilePath;
  AudioPlaybackState get status => player.playbackState;

  Duration get startPosition => _startPosition;
  set startPosition(Duration value) {
    _startPosition = value;
  }

  Duration get endPosition => _endPosition;
  set endPosition(Duration value) {
    _endPosition = value;
  }

  void releasePlayer() async => await player.dispose();

  Future<Duration> setUpPlayer(String url) async {
    return await player.setUrl(url);
  }

  Future<void> seekToNewPosition({continues = false}) async {
    // Return true if successfully seek to audio start position, false otherwise
    return !continues
        ? await player.setClip(
            start: this._startPosition, end: this._endPosition)
        : await player.seek(this._startPosition);
  }

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

  /// Get the url or path of audio file
  /// prams: url, download, filename
  /// check if file exists in phone storage return path
  /// if download = true downloads the file from url
  ///
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
//      print('Already exists');
    }
  }
}
