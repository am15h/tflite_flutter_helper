import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:quiver/check.dart';
import 'package:tflite_flutter_helper/src/common/file_util.dart';
import 'package:tflite_flutter_helper/src/label/category.dart';
import 'package:tflite_flutter_helper/src/task/bindings/text/nl_classifier/nl_classifer.dart';
import 'package:tflite_flutter_helper/src/task/bindings/text/nl_classifier/types.dart';
import 'package:tflite_flutter_helper/src/task/text/nl_classifier/nl_classifier_options.dart';

/// Classifier API for natural language classification tasks, categorizes string into different
/// classes.
///
/// The API expects a TFLite model with the following input/output tensor:
///
/// <ul>
///   <li>Input tensor (kTfLiteString)
///       input of the model, accepts a string.
///
///   <li>Output score tensor
///       (kTfLiteUInt8/kTfLiteInt8/kTfLiteInt16/kTfLiteFloat32/kTfLiteFloat64/kTfLiteBool)
///
///       - output scores for each class, if type is one of the Int types, dequantize it, if it
///         is Bool type, convert the values to 0.0 and 1.0 respectively.
///
///       - can have an optional associated file in metadata for labels, the file should be a
///         plain text file with one label per line, the number of labels should match the number
///         of categories the model outputs. Output label tensor: optional (kTfLiteString) -
///         output classname for each class, should be of the same length with scores. If this
///         tensor is not present, the API uses score indices as classnames. - will be ignored if
///         output score tensor already has an associated label file.
///
///   <li>Optional Output label tensor (kTfLiteString/kTfLiteInt32)
///       - output classname for each class, should be of the same length with scores. If this
///         tensor is not present, the API uses score indices as classnames.
///       - will be ignored if output score tensor already has an associated labe file.
/// </ul>
///
/// By default the API tries to find the input/output tensors with default configurations in
/// [NLClassifierOptions], with tensor name prioritized over tensor index. The option is
/// configurable for different TFLite models.
class NLClassifier {
  final Pointer<TfLiteNLClassifier> _classifier;
  bool _deleted = false;
  Pointer<TfLiteNLClassifier> get base => _classifier;

  NLClassifier._(this._classifier);

  /// Create [NLClassifier] from [modelPath] and optional [options].
  ///
  /// [modelPath] is the path of the .tflite model loaded on device.
  ///
  /// throws [FileSystemException] If model file fails to load.
  static NLClassifier create(String modelPath, {NLClassifierOptions? options}) {
    if (options == null) {
      options = NLClassifierOptions();
    }
    final nativePtr =
        NLClassifierFromFileAndOptions(modelPath.toNativeUtf8(), options.base);
    if (nativePtr == nullptr) {
      throw FileSystemException("Failed to create NLClassifier.", modelPath);
    }
    return NLClassifier._(nativePtr);
  }

  /// Create [NLClassifier] from [modelFile].
  ///
  /// throws [FileSystemException] If model file fails to load.
  static NLClassifier createFromFile(File modelFile) {
    return create(modelFile.path);
  }

  /// Create [NLClassifier] from [modelFile] and [options].
  ///
  /// throws [FileSystemException] If model file fails to load.
  static NLClassifier createFromFileAndOptions(
      File modelFile, NLClassifierOptions options) {
    return create(modelFile.path, options: options);
  }

  /// Create [NLClassifier] directly from [assetPath] and optional [options].
  ///
  /// [assetPath] must the full path to assets. Eg. 'assets/my_model.tflite'.
  ///
  /// throws [FileSystemException] If model file fails to load.
  static Future<NLClassifier> createFromAsset(String assetPath,
      {NLClassifierOptions? options}) async {
    final modelFile = await FileUtil.loadFileOnDevice(assetPath);
    return create(modelFile.path, options: options);
  }

  /// Perform classification on a string input [text],
  ///
  /// Returns classified [Category]s as List.
  List<Category> classify(String text) {
    final ref = NLClassifierClassify(base, text.toNativeUtf8()).ref;
    final categoryList = List.generate(
      ref.size,
      (i) => Category(
          ref.categories[i].text.toDartString(), ref.categories[i].score),
    );
    return categoryList;
  }

  /// Deletes NLClassifier Instance.
  void delete() {
    checkState(!_deleted, message: 'NLCLassifier already deleted.');
    NLClassifierDelete(base);
    _deleted = true;
  }
}
