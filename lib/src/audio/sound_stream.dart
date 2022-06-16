import 'dart:async';

import 'package:flutter/services.dart';
import 'recorder_stream.dart';

const methodChannelName = 'com.tfliteflutter.tflite_flutter_helper:methods';

const MethodChannel methodChannel = MethodChannel(methodChannelName);

final eventsStreamController = StreamController<dynamic>.broadcast();

enum SoundStreamStatus {
  Unset,
  Initialized,
  Playing,
  Stopped,
}

class SoundStream {
  static final SoundStream _instance = SoundStream._internal();
  factory SoundStream() => _instance;
  SoundStream._internal() {
    methodChannel.setMethodCallHandler(_onMethodCall);
  }

  /// Return [RecorderStream] instance (Singleton).
  RecorderStream get recorder => RecorderStream();


  Future<dynamic> _onMethodCall(MethodCall call) async {
    switch (call.method) {
      case "platformEvent":
        eventsStreamController.add(call.arguments);
        break;
    }
    return null;
  }
}

String enumToString(Object o) => o.toString().split('.').last;
