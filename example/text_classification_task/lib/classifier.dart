import 'package:tflite_flutter_helper/tflite_flutter_helper.dart';

abstract class Classifier {
  List<Category> classify(String text);
}
