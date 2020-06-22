import 'dart:convert';
import 'dart:math';

import 'package:e2e/e2e.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:tflite_flutter_helper/tflite_flutter_helper.dart';

const sampleFileName = 'assets/greyfox.jpg';
const modelFileName = 'mobilenet_v1_1.0_224_quant.tflite';
const labelFileName = 'assets/labels_mobilenet_quant_v1_224.txt';

//flutter driver --driver='test_driver/image_classification_e2e_test.dart' test/image_classification_e2e.dart
void main() {
  E2EWidgetsFlutterBinding.ensureInitialized();

  group('inference', () {
    var rawAssetFile;
    Interpreter interpreter;
    var labels;

    setUpAll(() async {
      rawAssetFile = await rootBundle.load(sampleFileName);
      interpreter = await Interpreter.fromAsset(modelFileName);
      final fileString = await loadString(labelFileName);
      labels = FileUtil.labelListFromString(fileString);
    });

    TensorImage inputImage;

    test('create tensorimage', () {
      var image = decodeImage(rawAssetFile.buffer.asUint8List());

      var inputTensors = interpreter.getInputTensor(0);

      List<int> inputShape = inputTensors.shape;

      int inputY = inputShape[1];
      int inputX = inputShape[2];

      int cropSize = min(image.width, image.height);

      inputImage = ImageProcessorBuilder()
          .add(ResizeWithCropOrPadOp(cropSize, cropSize))
          .add(ResizeOp(inputY, inputX, ResizeMethod.NEAREST_NEIGHBOUR))
          .build()
          .process(TensorImage.fromImage(image));

      expect(inputImage.width, inputY);
      expect(inputImage.height, inputX);
    });

    TensorBuffer outputBuffer;

    test('create output buffer', () {
      var outputTensors = interpreter.getOutputTensor(0);
      List<int> probShape = outputTensors.shape;
      TfLiteType probDataType = TfLiteType.uint8;

      outputBuffer = TensorBuffer.createFixedSize(probShape, probDataType);
      expect(outputBuffer.getShape(), probShape);
    });

    test('inference', () {
      interpreter.run(inputImage.buffer.asUint8List(),
          outputBuffer.getBuffer().asUint8List());
      print(
          'Inference time: ${interpreter.lastNativeInferenceDurationMicroSeconds / 1000}');
    });

    test('post processing', () {
      var probabilityProcessor =
          TensorProcessorBuilder().add(NormalizeOp(0, 255)).build();

      Map<String, double> labeledProb = TensorLabel.fromList(
              labels, probabilityProcessor.process(outputBuffer))
          .getMapWithFloatValue();

      expect(labeledProb['grey fox'] > 0.98, true);
    });

    tearDownAll(() {
      interpreter.close();
    });
  });
}

// Copying loadString method here as it wasn't probably working bec
Future<String> loadString(String key, {bool cache = true}) async {
  final ByteData data = await rootBundle.load(key);
  if (data == null) throw FlutterError('Unable to load asset: $key');
  return utf8.decode(data.buffer.asUint8List());
}
