import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tflite_flutter_helper/tflite_flutter_helper.dart';

import 'classifier.dart';

class ClassifierTaskLib implements Classifier {
  final _modelFile = 'text_classification_v2.tflite';
  late final NLClassifier classifier;

  ClassifierTaskLib() {
    createClassifierInstance();
  }

  Future<void> createClassifierInstance() async {
    classifier = await NLClassifier.createFromAsset('assets/$_modelFile',
        options: NLClassifierOptions());
    print("NLClassifier Inititalized Successfully");
  }

  List<Category> classify(String rawText) {
    return classifier.classify(rawText);
  }
}

Future<File> getFile(String fileName) async {
  final appDir = await getTemporaryDirectory();
  final appPath = appDir.path;
  final fileOnDevice = File('$appPath/$fileName');
  final rawAssetFile = await rootBundle.load('assets/$fileName');
  final rawBytes = rawAssetFile.buffer.asUint8List();
  await fileOnDevice.writeAsBytes(rawBytes, flush: true);
  return fileOnDevice;
}

Future<String> getPathOnDevice(String assetFileName) async {
  final fileOnDevice = await getFile(assetFileName);
  return fileOnDevice.path;
}
