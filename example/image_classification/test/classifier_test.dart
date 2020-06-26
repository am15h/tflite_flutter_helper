import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:imageclassification/classifier.dart';
import 'package:tflite_flutter_helper/tflite_flutter_helper.dart';

abstract class ClassiferTest extends Classifier {
  @override
  Future<void> loadLabels() async {
    labels =
        FileUtil.labelListFromString(await loadString("assets/labels.txt"));
  }

  // Copying loadString method here as it wasn't probably working bec
  Future<String> loadString(String key, {bool cache = true}) async {
    final ByteData data = await rootBundle.load(key);
    if (data == null) throw FlutterError('Unable to load asset: $key');
    return utf8.decode(data.buffer.asUint8List());
  }
}

class ClassifierFloatTest extends ClassiferTest {
  @override
  String get modelName => 'mobilenet_v1_1.0_224.tflite';

  @override
  NormalizeOp get preProcessNormalizeOp => NormalizeOp(127.5, 127.5);

  @override
  NormalizeOp get postProcessNormalizeOp => NormalizeOp(0, 1);
}

class ClassifierQuantTest extends ClassiferTest {
  @override
  String get modelName => 'mobilenet_v1_1.0_224_quant.tflite';

  @override
  NormalizeOp get preProcessNormalizeOp => NormalizeOp(0, 1);

  @override
  NormalizeOp get postProcessNormalizeOp => NormalizeOp(0, 255);
}
