import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:quiver/check.dart';
import 'package:tflite_flutter_helper/src/common/file_util.dart';
import 'package:tflite_flutter_helper/src/label/category.dart';
import 'package:tflite_flutter_helper/src/task/bindings/text/nl_classifier/bert_nl_classifier.dart';
import 'package:tflite_flutter_helper/src/task/bindings/text/nl_classifier/types.dart';
import 'package:tflite_flutter_helper/src/task/text/nl_classifier/bert_nl_classifier_options.dart';

/// Classifier API for NLClassification tasks with Bert models, categorizes string into different
/// classes. The API expects a Bert based TFLite model with metadata populated.
///
/// <p>The metadata should contain the following information:
///
/// <ul>
///   <li>1 input_process_unit for Wordpiece/Sentencepiece Tokenizer.
///   <li>3 input tensors with names "ids", "mask" and "segment_ids".
///   <li>1 output tensor of type float32[1, 2], with a optionally attached label file. If a label
///       file is attached, the file should be a plain text file with one label per line, the number
///       of labels should match the number of categories the model outputs.
/// </ul>
class BertNLClassifier {
  final Pointer<TfLiteBertNLClassifier> _classifier;
  bool _deleted = false;
  Pointer<TfLiteBertNLClassifier> get base => _classifier;

  BertNLClassifier._(this._classifier);

  /// Create [BertNLClassifier] from [modelPath] and optional [options].
  ///
  /// [modelPath] is the path of the .tflite model loaded on device.
  ///
  /// throws [FileSystemException] If model file fails to load.
  static BertNLClassifier create(String modelPath,
      {BertNLClassifierOptions? options}) {
    if (options == null) {
      options = BertNLClassifierOptions();
    }
    final nativePtr = BertNLClassifierFromFileAndOptions(
        modelPath.toNativeUtf8(), options.base);
    if (nativePtr == nullptr) {
      throw FileSystemException(
          "Failed to create BertNLClassifier.", modelPath);
    }
    return BertNLClassifier._(nativePtr);
  }

  /// Create [BertNLClassifier] from [modelFile].
  ///
  /// throws [FileSystemException] If model file fails to load.
  static BertNLClassifier createFromFile(File modelFile) {
    return create(modelFile.path);
  }

  /// Create [BertNLClassifier] from [modelFile] and [options].
  ///
  /// throws [FileSystemException] If model file fails to load.
  static BertNLClassifier createFromFileAndOptions(
      File modelFile, BertNLClassifierOptions options) {
    return create(modelFile.path, options: options);
  }

  /// Create [BertNLClassifier] directly from [assetPath] and optional [options].
  ///
  /// [assetPath] must the full path to assets. Eg. 'assets/my_model.tflite'.
  ///
  /// throws [FileSystemException] If model file fails to load.
  static Future<BertNLClassifier> createFromAsset(String assetPath,
      {BertNLClassifierOptions? options}) async {
    final modelFile = await FileUtil.loadFileOnDevice(assetPath);
    return create(modelFile.path, options: options);
  }

  /// Perform classification on a string input [text],
  ///
  /// Returns classified [Category]s as List.
  List<Category> classify(String text) {
    final ref = BertNLClassifierClassify(base, text.toNativeUtf8()).ref;
    final categoryList = List.generate(
      ref.size,
      (i) => Category(
          ref.categories[i].text.toDartString(), ref.categories[i].score),
    );
    return categoryList;
  }

  /// Deletes BertNLClassifier Instance.
  void delete() {
    checkState(!_deleted, message: 'BertNLClassifier already deleted.');
    BertNLClassifierDelete(base);
    _deleted = true;
  }
}
