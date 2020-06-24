import 'dart:io';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:logger/logger.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:tflite_flutter_helper/tflite_flutter_helper.dart';

abstract class Classifier {
  Interpreter _interpreter;

  var logger = Logger();

  List<int> _inputShape;
  List<int> _outputShape;

  TensorImage _inputImage;
  TensorBuffer _outputBuffer;

  TfLiteType _outputType = TfLiteType.uint8;

  final String _labelsFileName = 'assets/labels_mobilenet_quant_v1_224.txt';

  final int _labelsLength = 1001;

  List<String> _labels;

  String get modelName;

  NormalizeOp get preProcessNormalizeOp;
  NormalizeOp get postProcessNormalizeOp;

  Classifier() {
    _loadModel();
    _loadLabels();
  }

  Future<void> _loadModel() async {
    _interpreter = await Interpreter.fromAsset(modelName);
    if (_interpreter != null) {
      print('Interpreter Created Successfully');
      _inputShape = _interpreter.getInputTensor(0).shape;
      _outputShape = _interpreter.getOutputTensor(0).shape;
      _outputType = _interpreter.getOutputTensor(0).type;
      _outputBuffer = TensorBuffer.createFixedSize(_outputShape, _outputType);
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

  Future<Category> predict(File imageFile) async {
    _inputImage = TensorImage.fromFile(imageFile);
    _inputImage = _preProcess();

    logger.d(_inputImage.tensorBuffer.getDoubleList().sublist(0, 30));

    final st = DateTime.now().millisecondsSinceEpoch;
    _interpreter.run(_inputImage.buffer, _outputBuffer.getBuffer());
    logger.d(
        'Run Time :' + (DateTime.now().millisecondsSinceEpoch - st).toString());

    final _probabilityProcessor =
        TensorProcessorBuilder().add(postProcessNormalizeOp).build();

    Map<String, double> labeledProb = TensorLabel.fromList(
            _labels, _probabilityProcessor.process(_outputBuffer))
        .getMapWithFloatValue();

    final pred = getTopProbability(labeledProb);
    return Category(pred.key, pred.value);
  }
}

getTopProbability(Map<String, double> labeledProb) {
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
