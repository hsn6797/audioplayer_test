import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'my_player.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'Al Fatihah'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver {
  String URL =
//      'http://192.168.10.6:8888/PHP_Scripts/01.mp3';
//      'http://download.quranurdu.com/Al%20Quran%20with%20Urdu%20Translation%20By%20Mishari%20Bin%20Rashid%20Al%20Afasi/1%20Al%20Fatiha.mp3';
      'http://quranapp.masstechnologist.com/01.mp3';
//      'https://luan.xyz/files/audio/ambient_c_motion.mp3';
  List<Verse> _verseList = [];
  MyPlayer _mp;
  bool _progressBarActive = true;

  int _currentSelectedVerse = -1;

  Future<bool> requestStoragePermission() async {
    var status = await Permission.storage.request();
    if (status.isGranted) {
      return true;
    }
    return false;
  }

  Future<String> _loadFromAsset(String fileName) async {
    return await rootBundle.loadString("assets/$fileName");
  }

  Future<dynamic> parseJson(String fileName) async {
    String jsonString = await _loadFromAsset(fileName);
    return jsonDecode(jsonString);
//    _verseList = await Verse.list(data['verses']);
  }

  Future<void> setAudioPlayer(String url, {download = false, fileName}) async {
    // Request Storage permission
    if (!await requestStoragePermission()) return;

    setState(() => _progressBarActive = true);

    _mp = MyPlayer();
    await _mp.loadAudio(url, download: download, fileName: fileName);
    if (_mp.audioFilePath == null) return;

    // Set the url
    await _mp.setUpPlayer(_mp.audioFilePath);

    setState(() => _progressBarActive = false);

    _mp.player.getPositionStream().listen((event) {
      // Track the position
      if (_mp.endPosition != null && event >= _mp.endPosition) {
        setState(() {
          _currentSelectedVerse++;
          if (_currentSelectedVerse > 0 &&
              _currentSelectedVerse < _verseList.length) {
            _mp.startPosition =
                _verseList[_currentSelectedVerse].arabic_start_time;
            _mp.endPosition = _verseList[_currentSelectedVerse].urdu_end_time;
          } else {
            _currentSelectedVerse = -1;
          }
        });
      }
    });
  }

  void setUpSura() async {
    var data = await parseJson('01.json');
    _verseList = await Verse.list(data['verses']);
    await setAudioPlayer(URL, download: true, fileName: data['file_name']);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    setUpSura();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    print('Dispose Called!!');

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // user returned to our app
      this.setUpSura();
    } else if (state == AppLifecycleState.inactive) {
      // app is inactive
      if (_mp != null) _mp.releasePlayer();
    } else if (state == AppLifecycleState.paused) {
      // user is about quit our app temporally
      if (_mp != null) _mp.releasePlayer();
    }
  }

  Future playVerse(Duration s, Duration e, {bool continues = false}) async {
    if (_mp.player.playbackState == AudioPlaybackState.playing)
      await _mp.stopAudio();
    setState(() {
      _progressBarActive = true;
    });
    _mp.startPosition = s;
    _mp.endPosition = e;
    await _mp.seekToNewPosition(continues: continues);

    setState(() {
      _progressBarActive = false;
    });

    await _mp.playAudio();
  }

  @override
  Widget build(BuildContext context) {
//    MyPlayer _mp = MyPlayer(URL);
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Stack(
        children: <Widget>[
          ListView.builder(
            itemBuilder: (context, ind) {
              final verse = _verseList[ind];
              return ListTile(
                onTap: () async {
                  // Play Arabic
                  setState(() {
                    _currentSelectedVerse = ind;
                  });
                  await playVerse(verse.arabic_start_time, verse.urdu_end_time,
                      continues: true);

                  // Play Urdu
//                  await playVerse(verse.urdu_start_time, verse.urdu_end_time);
                },
                title: Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: Text(
                    verse.arabic_text,
                    style: TextStyle(
                      fontSize: 18.0,
                      color: _currentSelectedVerse == ind
                          ? Colors.blue
                          : Colors.grey.shade900,
                    ),
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: Text(
                    verse.urdu_text,
                    style: TextStyle(
                      fontSize: 18.0,
                      color: _currentSelectedVerse == ind
                          ? Colors.blue
                          : Colors.grey.shade900,
                    ),
                  ),
                ),
              );
            },
            itemCount: _verseList.length,
          ),
          _progressBarActive == true
              ? Center(child: const CircularProgressIndicator())
              : Container(
                  height: 10,
                ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: null,
        tooltip: 'Increment',
        child: Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

class Verse {
  int index;
  String arabic_text;
  String urdu_text;

  Duration arabic_start_time;
  Duration arabic_end_time;
  Duration urdu_start_time;
  Duration urdu_end_time;

  static Future<List<Verse>> list(var maps) async {
    // Convert the List<Map<String, dynamic> into a List<Verse>.
    return List.generate(maps.length, (i) {
      Verse v = Verse();
      v.index = int.parse(maps[i]['index']);
      v.arabic_text = maps[i]['arabic_text'];
      v.urdu_text = maps[i]['urdu_text'];

      v.arabic_start_time = parseDuration(maps[i]['arabic_start_time']);
      v.arabic_end_time = parseDuration(maps[i]['arabic_end_time']);
      v.urdu_start_time = parseDuration(maps[i]['urdu_start_time']);
      v.urdu_end_time = parseDuration(maps[i]['urdu_end_time']);

      return v;
    });
  }

  static Duration parseDuration(String s) {
    int hours = 0;
    int minutes = 0;
    int micros;
    List<String> parts = s.split(':');
    if (parts.length > 2) {
      hours = int.parse(parts[parts.length - 3]);
    }
    if (parts.length > 1) {
      minutes = int.parse(parts[parts.length - 2]);
    }
    micros = (double.parse(parts[parts.length - 1]) * 1000000).round();
    return Duration(hours: hours, minutes: minutes, microseconds: micros);
  }
}
