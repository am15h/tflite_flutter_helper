import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:quiver/check.dart';
import 'package:tflite_flutter_helper/src/task/bindings/text/nl_classifier/types.dart';

class NLClassifierOptions {
  final Pointer<TfLiteNLClassifierOptions> _options;
  bool _deleted = false;

  Pointer<TfLiteNLClassifierOptions> get base => _options;
  NLClassifierOptions._(this._options);

  static const DEFAULT_INPUT_TENSOR_INDEX = 0;
  static const DEFAULT_INPUT_TENSOR_NAME = "INPUT";
  static const DEFAULT_OUTPUT_SCORE_TENSOR_INDEX = 0;
  static const DEFAULT_OUTPUT_SCORE_TENSOR_NAME = "OUTPUT_SCORE";
  static const DEFAULT_OUTPUT_LABEL_TENSOR_NAME = "OUTPUT_LABEL";
  static const DEFAULT_OUTPUT_LABEL_TENSOR_INDEX = -1;

  /// Creates a new options instance.
  factory NLClassifierOptions() {
    final optionsPtr = TfLiteNLClassifierOptions.allocate(
        DEFAULT_INPUT_TENSOR_INDEX,
        DEFAULT_OUTPUT_SCORE_TENSOR_INDEX,
        DEFAULT_OUTPUT_LABEL_TENSOR_INDEX,
        DEFAULT_INPUT_TENSOR_NAME,
        DEFAULT_OUTPUT_SCORE_TENSOR_NAME,
        DEFAULT_OUTPUT_LABEL_TENSOR_NAME);
    return NLClassifierOptions._(optionsPtr);
  }

  int get inputTensorIndex => base.ref.inputTensorIndex;

  set inputTensorIndex(int value) {
    base.ref.inputTensorIndex = value;
  }

  int get outputScoreTensorIndex => base.ref.outputScoreTensorIndex;

  set outputScoreTensorIndex(int value) {
    base.ref.outputScoreTensorIndex = value;
  }

  int get outputLabelTensorIndex => base.ref.outputLabelTensorIndex;

  set outputLabelTensorIndex(int value) {
    base.ref.outputLabelTensorIndex = value;
  }

  String get inputTensorName => base.ref.inputTensorName.toDartString();

  set inputTensorName(String value) {
    base.ref.inputTensorName = value.toNativeUtf8();
  }

  String get outputScoreTensorName =>
      base.ref.outputScoreTensorName.toDartString();

  set outputScoreTensorName(String value) {
    base.ref.outputScoreTensorName = value.toNativeUtf8();
  }

  String get outputLabelTensorName =>
      base.ref.outputLabelTensorName.toDartString();

  set outputLabelTensorName(String value) {
    base.ref.outputLabelTensorName = value.toNativeUtf8();
  }

  /// Destroys the options instance.
  void delete() {
    checkState(!_deleted, message: 'NLClassifierOptions already deleted.');
    calloc.free(_options);
    _deleted = true;
  }
}
