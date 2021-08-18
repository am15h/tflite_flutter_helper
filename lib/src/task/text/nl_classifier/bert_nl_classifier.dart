import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:quiver/check.dart';
import 'package:tflite_flutter_helper/src/label/category.dart';
import 'package:tflite_flutter_helper/src/task/bindings/text/nl_classifier/bert_nl_classifier.dart';
import 'package:tflite_flutter_helper/src/task/bindings/text/nl_classifier/types.dart';
import 'package:tflite_flutter_helper/src/task/text/nl_classifier/bert_nl_classifier_options.dart';

class BertNLClassifier {
  final Pointer<TfLiteBertNLClassifier> _classifier;
  bool _deleted = false;
  Pointer<TfLiteBertNLClassifier> get base => _classifier;

  BertNLClassifier._(this._classifier);

  factory BertNLClassifier.create(String modelPath,
      {BertNLClassifierOptions? options}) {
    if(options == null) {
      options = BertNLClassifierOptions();
    }
    final classiferPtr =
    BertNLClassifierFromFileAndOptions(modelPath.toNativeUtf8(), options.base);
    return BertNLClassifier._(classiferPtr);
  }

  List<Category> classify(String text) {
    final ref = BertNLClassifierClassify(base, text.toNativeUtf8()).ref;
    final categoryList = List.generate(
      ref.size,
          (i) => Category(
          ref.categories[i].text.toDartString(), ref.categories[i].score),
    );
    return categoryList;
  }

  void delete() {
    checkState(!_deleted, message: 'BertNLClassifier already deleted.');
    BertNLClassifierDelete(base);
    _deleted = true;
  }
}
