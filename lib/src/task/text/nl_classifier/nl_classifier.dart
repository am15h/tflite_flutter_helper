import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:quiver/check.dart';
import 'package:tflite_flutter_helper/src/label/category.dart';
import 'package:tflite_flutter_helper/src/task/bindings/text/nl_classifier/nl_classifer.dart';
import 'package:tflite_flutter_helper/src/task/bindings/text/nl_classifier/types.dart';
import 'package:tflite_flutter_helper/src/task/text/nl_classifier/nl_classifier_options.dart';

class NLClassifier {
  final Pointer<TfLiteNLClassifier> _classifier;
  bool _deleted = false;
  Pointer<TfLiteNLClassifier> get base => _classifier;

  NLClassifier._(this._classifier);

  // TODO: create convenience constructors
  factory NLClassifier.create(String modelPath, NLClassifierOptions options) {
    final classiferPtr =
        NLClassifierFromFileAndOptions(modelPath.toNativeUtf8(), options.base);
    return NLClassifier._(classiferPtr);
  }

  List<Category> classify(String text) {
    final ref = NLClassifierClassify(base, text.toNativeUtf8()).ref;
    var categoryList = List.generate(
      ref.size,
      (i) => Category(
          ref.categories[i].text.toDartString(), ref.categories[i].score),
    );
    return categoryList;
  }

  void delete() {
    checkState(!_deleted, message: 'NLCLassifier already deleted.');
    NLClassifierDelete(base);
    _deleted = true;
  }
}
