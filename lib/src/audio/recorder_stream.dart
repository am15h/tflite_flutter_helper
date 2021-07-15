import 'dart:async';
import 'dart:typed_data';
import 'sound_stream.dart';

class RecorderStream {
  static final RecorderStream _instance = RecorderStream._internal();
  factory RecorderStream() => _instance;

  final _audioStreamController = StreamController<Uint8List>.broadcast();

  final _recorderStatusController =
  StreamController<SoundStreamStatus>.broadcast();

  RecorderStream._internal() {
    SoundStream();
    eventsStreamController.stream.listen(_eventListener);
    _recorderStatusController.add(SoundStreamStatus.Unset);
    _audioStreamController.add(Uint8List(0));
  }

  /// Initialize Recorder with specified [sampleRate]
  Future<dynamic> initialize({int sampleRate = 16000, bool showLogs = false}) =>
      methodChannel.invokeMethod<dynamic>("initializeRecorder", {
        "sampleRate": sampleRate,
        "showLogs": showLogs,
      });

  /// Start recording. Recorder will start pushing audio chunks (PCM 16bit data)
  /// to audiostream as Uint8List
  Future<dynamic> start() =>
      methodChannel.invokeMethod<dynamic>("startRecording");

  /// Recorder will stop recording and sending audio chunks to the [audioStream].
  Future<dynamic> stop() =>
      methodChannel.invokeMethod<dynamic>("stopRecording");

  /// Current status of the [RecorderStream]
  Stream<SoundStreamStatus> get status => _recorderStatusController.stream;

  /// Stream of PCM 16bit data from Microphone
  Stream<Uint8List> get audioStream => _audioStreamController.stream;

  void _eventListener(dynamic event) {
    if (event == null) return;
    final String eventName = event["name"] ?? "";
    switch (eventName) {
      case "dataPeriod":
        final Uint8List audioData =
            Uint8List.fromList(event["data"] ?? []);
        if (audioData.isNotEmpty) _audioStreamController.add(audioData);
        break;
      case "recorderStatus":
        final String status = event["data"] ?? "Unset";
        _recorderStatusController.add(SoundStreamStatus.values.firstWhere(
              (value) => enumToString(value) == status,
          orElse: () => SoundStreamStatus.Unset,
        ));
        break;
    }
  }

  /// Stop and close all streams. This cannot be undone
  /// Only call this method if you don't want to use this anymore
  void dispose() {
    stop();
    eventsStreamController.close();
    _recorderStatusController.close();
    _audioStreamController.close();
  }
}
