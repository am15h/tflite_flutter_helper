import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class FileUtil {
  static Future<File> loadFileOnDevice(String fileAssetLocation) async {
    final appDir = await getTemporaryDirectory();
    final appPath = appDir.path;
    final fileOnDevice = File('$appPath/$fileAssetLocation');
    final rawAssetFile = await rootBundle.load('$fileAssetLocation');
    final rawBytes = rawAssetFile.buffer.asUint8List();
    await fileOnDevice.writeAsBytes(rawBytes, flush: true);
    return fileOnDevice;
  }

  Future<Uint8List> loadFileAsBytes(String fileAssetLocation) async {
    final rawAssetFile = await rootBundle.load('$fileAssetLocation');
    final rawBytes = rawAssetFile.buffer.asUint8List();
    return rawBytes;
  }

  static Future<List<String>> loadLabels(String fileAssetLocation) async {
    final fileString = await rootBundle.loadString('$fileAssetLocation');
    return labelListFromString(fileString);
  }

  static List<String> loadLabelsFromFile(File file) {
    final fileString = file.readAsStringSync();
    return labelListFromString(fileString);
  }

  static List<String> labelListFromString(String fileString) {
    var list = <String>[];
    final newLineList = fileString.split('\n');
    for (var i = 0; i < newLineList.length; i++) {
      var entry = newLineList[i].trim();
      if (entry.length > 0) {
        list.add(entry);
      }
    }
    return list;
  }
}
