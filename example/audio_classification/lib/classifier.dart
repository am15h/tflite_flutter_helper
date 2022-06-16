import 'dart:typed_data';

import 'package:audio_classification/main.dart';
import 'package:flutter/services.dart';
import 'package:collection/collection.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:tflite_flutter_helper/tflite_flutter_helper.dart';

class Classifier {
  late Interpreter interpreter;
  late InterpreterOptions _interpreterOptions;

  late List<int> _inputShape;
  late List<int> _outputShape;

  late TensorBuffer _outputBuffer;

  TfLiteType _outputType = TfLiteType.uint8;

  final String _modelFileName = 'yamnet.tflite';
  final String _labelFileName = 'assets/yamnet_class_map.csv';

  late Map<int, String> labels;

  Classifier({int? numThreads}) {
    _interpreterOptions = InterpreterOptions();

    if (numThreads != null) {
      _interpreterOptions.threads = numThreads;
    }

    loadModel();
    loadLabels();
  }

  Future<void> loadModel() async {
    try {
      interpreter = await Interpreter.fromAsset(_modelFileName,
          options: _interpreterOptions);
      print('Interpreter Created Successfully');
      print(interpreter.getInputTensors());
      print(interpreter.getOutputTensors());
      _inputShape = interpreter.getInputTensor(0).shape;
      _outputShape = interpreter.getOutputTensor(0).shape;
      _outputType = interpreter.getOutputTensor(0).type;

      _outputBuffer = TensorBuffer.createFixedSize(_outputShape, _outputType);
    } catch (e) {
      print('Unable to create interpreter, Caught Exception: ${e.toString()}');
    }
  }

  Future<void> loadLabels() async {
    labels = await loadLabelsFile(_labelFileName);
  }

  List<Category> predict(List<int> audioSample) {
    final pres = DateTime.now().millisecondsSinceEpoch;
    Uint8List bytes = Uint8List.fromList(audioSample);
    TensorAudio tensorAudio = TensorAudio.create(
        TensorAudioFormat.create(1, sampleRate), _inputShape[0]);
    tensorAudio.loadShortBytes(bytes);
    final pre = DateTime.now().millisecondsSinceEpoch - pres;

    final runs = DateTime.now().millisecondsSinceEpoch;
    interpreter.run(
        tensorAudio.tensorBuffer.getBuffer(), _outputBuffer.getBuffer());
    final run = DateTime.now().millisecondsSinceEpoch - runs;

    Map<String, double> labeledProb = {};
    for (int i = 0; i < _outputBuffer.getDoubleList().length; i++) {
      labeledProb[labels[i]!] = _outputBuffer.getDoubleValue(i);
    }
    final top = getTopProbability(labeledProb);
    return top;
  }

  void close() {
    interpreter.close();
  }
}

List<Category> getTopProbability(Map<String, double> labeledProb) {
  var pq = PriorityQueue<MapEntry<String, double>>(compare);
  pq.addAll(labeledProb.entries);
  var result = <Category>[];
  while (pq.isNotEmpty && result.length < 5 && (pq.first.value > 0.1 || result.length < 3)) {
    result.add(Category(pq.first.key, pq.first.value));
    pq.removeFirst();
  }
  return result;
}

int compare(MapEntry<String, double> e1, MapEntry<String, double> e2) {
  if (e1.value > e2.value) {
    return -1;
  } else if (e1.value == e2.value) {
    return 0;
  } else {
    return 1;
  }
}

Future<Map<int, String>> loadLabelsFile(String fileAssetLocation) async {
  final fileString = await rootBundle.loadString('$fileAssetLocation');
  return labelListFromString(fileString);
}

Map<int, String> labelListFromString(String fileString) {
  var classMap = <int, String>{};
  final newLineList = fileString.split('\n');
  for (var i = 1; i < newLineList.length; i++) {
    final entry = newLineList[i].trim();
    if (entry.length > 0) {
      final data = entry.split(',');
      classMap[int.parse(data[0])] = data[2];
    }
  }
  return classMap;
}
