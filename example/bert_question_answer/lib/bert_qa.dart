import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tflite_flutter_helper/tflite_flutter_helper.dart';

class BertQA {
  late final BertQuestionAnswerer bertQuestionAnswerer;

  final _modelPath = "lite-model_mobilebert_1_metadata_1.tflite";

  BertQA () {
    createClassifier();
  }

  Future<void> createClassifier() async {
    final onDevicePath = await getPathOnDevice(_modelPath);
    bertQuestionAnswerer = BertQuestionAnswerer.create(onDevicePath);
  }

  List<QaAnswer> answer(String context, String question) {
    return bertQuestionAnswerer.answer(context, question);
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
