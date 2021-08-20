import 'dart:convert';

import 'package:bert_question_answer/data/qa_data.dart';
import 'package:flutter/services.dart';

class DatasetLoader {
  static Future<List<QaData>> loadDatasetFromAssets () async {
    final jsonString = await rootBundle.loadString('assets/qa.json');
    final Map<String, dynamic> rawData = jsonDecode(jsonString);
    int size = (rawData["titles"] as List).length;
    return List.generate(size, (index) => QaData(rawData['titles'][index][0], rawData['contents'][index][0], List<String>.from(rawData["questions"][index])));
  }
}
