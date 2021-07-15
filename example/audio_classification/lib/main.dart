import 'dart:async';
import 'dart:typed_data';
import 'dart:ui';
import 'package:audio_classification/classifier.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:tflite_flutter_helper/tflite_flutter_helper.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:just_audio/just_audio.dart';

void main() {
  runApp(MyApp());
}

const int sampleRate = 16000;

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  RecorderStream _recorder = RecorderStream();
  final AudioPlayer _player = AudioPlayer();

  List<int> _micChunks = [];
  bool _isRecording = false;
  late StreamSubscription _recorderStatus;
  late StreamSubscription _audioStream;

  late Classifier _classifier;

  Category? prediction;

  @override
  void initState() {
    super.initState();
    initPlugin();
    _init();
    _classifier = Classifier();
  }

  @override
  void dispose() {
    _recorderStatus.cancel();
    _audioStream.cancel();
    _player.dispose();
    super.dispose();
  }

  Future<void> initPlugin() async {
    _recorderStatus = _recorder.status.listen((status) {
      if (mounted)
        setState(() {
          _isRecording = status == SoundStreamStatus.Playing;
        });
    });

    _audioStream = _recorder.audioStream.listen((data) {
      _micChunks.addAll(data);
    });

    await Future.wait([
      _recorder.initialize(),
    ]);
  }

  Future<void> _init() async {
    // Inform the operating system of our app's audio attributes etc.
    // We pick a reasonable default for an app that plays speech.
    final session = await AudioSession.instance;
    await session.configure(AudioSessionConfiguration.speech());
    // Listen to errors during playback.
    _player.playbackEventStream.listen(
      (event) {
      },
      onError: (Object e, StackTrace stackTrace) {
        print('A stream error occurred: $e');
      },
    );
  }

  Future<void> _loadMicChunks() async {
    // Try to load audio from a source and catch any errors.
    try {
      final savePath = await save(_micChunks, sampleRate);
      await _player.setAudioSource(AudioSource.uri(Uri.file(savePath)));
    } catch (e) {
      print("Error loading audio source: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Audio Classification'),
        ),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                IconButton(
                  iconSize: 64.0,
                  icon: Icon(_isRecording ? Icons.mic_off : Icons.mic),
                  onPressed: _isRecording ? () {
                    _recorder.stop();
                    _loadMicChunks();
                  } : () {
                    _micChunks = [];
                    _recorder.start();
                  },
                ),
                StreamBuilder<PlayerState>(
                  stream: _player.playerStateStream,
                  builder: (context, snapshot) {
                    final playerState = snapshot.data;
                    final processingState = playerState?.processingState;
                    final playing = playerState?.playing;
                    if (processingState == ProcessingState.loading ||
                        processingState == ProcessingState.buffering) {
                      return Container(
                        margin: EdgeInsets.all(8.0),
                        width: 64.0,
                        height: 64.0,
                        child: CircularProgressIndicator(),
                      );
                    } else if (playing != true) {
                      return IconButton(
                        icon: Icon(Icons.play_arrow),
                        iconSize: 64.0,
                        onPressed: _player.play,
                      );
                    } else if (processingState != ProcessingState.completed) {
                      return IconButton(
                        icon: Icon(Icons.pause),
                        iconSize: 64.0,
                        onPressed: _player.pause,
                      );
                    } else {
                      return IconButton(
                        icon: Icon(Icons.play_arrow),
                        iconSize: 64.0,
                        onPressed: () => _player.seek(Duration.zero),
                      );
                    }
                  },
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: ElevatedButton(
                onPressed: () async {
                  setState(() {
                    prediction = _classifier.predict(_micChunks);
                  });
                },
                child: Text("Predict"),
              ),
            ),
            if(prediction != null)
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                children: [
                  Text(prediction!.label, style: TextStyle(fontWeight: FontWeight.bold),),
                  SizedBox(height: 4),
                  Text(prediction!.score.toString()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Uint8List addWavHeader(List<int> data, int sampleRate) {
  var channels = 1;
  int byteRate = ((16 * sampleRate * channels) / 8).round();

  var size = data.length;

  var fileSize = size + 36;

  Uint8List header = Uint8List.fromList([
    // "RIFF"
    82, 73, 70, 70,
    fileSize & 0xff,
    (fileSize >> 8) & 0xff,
    (fileSize >> 16) & 0xff,
    (fileSize >> 24) & 0xff,
    // WAVE
    87, 65, 86, 69,
    // fmt
    102, 109, 116, 32,
    // fmt chunk size 16
    16, 0, 0, 0,
    // Type of format
    1, 0,
    // One channel
    channels, 0,
    // Sample rate
    sampleRate & 0xff,
    (sampleRate >> 8) & 0xff,
    (sampleRate >> 16) & 0xff,
    (sampleRate >> 24) & 0xff,
    // Byte rate
    byteRate & 0xff,
    (byteRate >> 8) & 0xff,
    (byteRate >> 16) & 0xff,
    (byteRate >> 24) & 0xff,
    // Uhm
    ((16 * channels) / 8).round(), 0,
    // bitsize
    16, 0,
    // "data"
    100, 97, 116, 97,
    size & 0xff,
    (size >> 8) & 0xff,
    (size >> 16) & 0xff,
    (size >> 24) & 0xff,
    ...data
  ]);
  return header;
}

Future<String> save(List<int> data, int sampleRate) async {
  Directory tempDir = await getTemporaryDirectory();
  String tempPath = tempDir.path;
  var filePath = tempPath + '/file_01.wav';
  File recordedFile = File(filePath);
  final header = addWavHeader(data, sampleRate);
  recordedFile.writeAsBytesSync(header, flush: true);
  return filePath;
}

class BufferAudioSource extends StreamAudioSource {
  Uint8List _buffer;

  BufferAudioSource(this._buffer) : super();

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) {
    start = start ?? 0;
    end = end ?? _buffer.length;

    return Future.value(
      StreamAudioResponse(
        sourceLength: _buffer.length,
        contentLength: end - start,
        offset: start,
        contentType: 'audio/wav',
        stream:
            Stream.value(List<int>.from(_buffer.skip(start).take(end - start))),
      ),
    );
  }
}
