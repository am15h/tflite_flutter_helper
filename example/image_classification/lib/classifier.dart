import 'dart:io';
import 'dart:math';

import 'package:image/image.dart';
import 'package:collection/collection.dart';
import 'package:imageclassification/classifier_quant.dart';
import 'package:logger/logger.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:tflite_flutter_helper/tflite_flutter_helper.dart';

abstract class Classifier {
  Interpreter _interpreter;
  InterpreterOptions _interpreterOptions;

  var logger = Logger();

  List<int> _inputShape;
  List<int> _outputShape;

  TensorImage _inputImage;
  TensorBuffer _outputBuffer;

  TfLiteType _outputType = TfLiteType.uint8;

  final String _labelsFileName = 'assets/labels.txt';

  final int _labelsLength = 1001;

  var _probabilityProcessor;

  List<String> _labels;

  String get modelName;

  NormalizeOp get preProcessNormalizeOp;
  NormalizeOp get postProcessNormalizeOp;

  Classifier({int numThreads: 1, Device device = Device.CPU}) {
    _interpreterOptions = InterpreterOptions()
      ..threads = numThreads
      ..useNnApiForAndroid = device == Device.NNAPI;

    if (device == Device.GPU) {
      _interpreterOptions.addDelegate(GpuDelegateV2());
    }

    _loadModel();
    _loadLabels();
  }

  Future<void> _loadModel() async {
    _interpreter =
        await Interpreter.fromAsset(modelName, options: _interpreterOptions);
    if (_interpreter != null) {
      print('Interpreter Created Successfully');
      _inputShape = _interpreter.getInputTensor(0).shape;
      _outputShape = _interpreter.getOutputTensor(0).shape;
      _outputType = _interpreter.getOutputTensor(0).type;
      logger.d(_interpreter.getInputTensor(0).params);
      logger.d(_interpreter.getOutputTensor(0).params);
      _outputBuffer = TensorBuffer.createFixedSize(_outputShape, _outputType);
      _probabilityProcessor =
          TensorProcessorBuilder().add(postProcessNormalizeOp).build();
    } else {
      print('Unable to create interpreter');
    }
  }

  Future<void> _loadLabels() async {
    _labels = await FileUtil.loadLabels(_labelsFileName);
    if (_labels.length == _labelsLength) {
      print('Labels loaded successfully');
    } else {
      print('Unable to load labels');
    }
  }

  TensorImage _preProcess() {
    int cropSize = min(_inputImage.height, _inputImage.width);
    return ImageProcessorBuilder()
        .add(ResizeWithCropOrPadOp(cropSize, cropSize))
        .add(ResizeOp(
            _inputShape[1], _inputShape[2], ResizeMethod.NEAREST_NEIGHBOUR))
        .add(preProcessNormalizeOp)
        .build()
        .process(_inputImage);
  }

  Category predict(Image image) {
    final pres = DateTime.now().millisecondsSinceEpoch;
    _inputImage = TensorImage.fromImage(image);
    _inputImage = _preProcess();
    final pree = DateTime.now().millisecondsSinceEpoch - pres;

    final runs = DateTime.now().millisecondsSinceEpoch;
    _interpreter.run(_inputImage.buffer, _outputBuffer.getBuffer());
    final rune = DateTime.now().millisecondsSinceEpoch - runs;

    final posts = DateTime.now().millisecondsSinceEpoch;
    Map<String, double> labeledProb = TensorLabel.fromList(
            _labels, _probabilityProcessor.process(_outputBuffer))
        .getMapWithFloatValue();

    final pred = getTopProbability(labeledProb);
    final poste = DateTime.now().millisecondsSinceEpoch - posts;

    print('$pree | $rune | $poste | Total : ${pree + rune + poste}');

    return Category(pred.key, pred.value);
  }
}

enum Device { CPU, NNAPI, GPU }

MapEntry<String, double> getTopProbability(Map<String, double> labeledProb) {
  var pq = PriorityQueue<MapEntry<String, double>>(compare);
  pq.addAll(labeledProb.entries);

  return pq.first;
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
