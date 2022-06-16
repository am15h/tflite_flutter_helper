import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:quiver/check.dart';
import 'package:tflite_flutter_helper/src/task/bindings/text/nl_classifier/types.dart';

/// Options to identify input and output tensors of the model.
///
/// Configure the input/output tensors for NLClassifier:
///
/// <p>- No special configuration is needed if the model has only one input tensor and one
/// output tensor.
///
/// <p>- When the model has multiple input or output tensors, use the following configurations
/// to specifiy the desired tensors: <br>
/// -- tensor names: {inputTensorName}, {outputScoreTensorName}, {@code
/// outputLabelTensorName}<br>
/// -- tensor indices: {inputTensorIndex}, {outputScoreTensorIndex}, {@code
/// outputLabelTensorIndex} <br>
/// Tensor names has higher priorities than tensor indices in locating the tensors. It means
/// the tensors will be first located according to tensor names. If not found, then the tensors
/// will be located according to tensor indices.
///
/// <p>- Failing to match the input text tensor or output score tensor with neither tensor
/// names nor tensor indices will trigger a runtime error. However, failing to locate the
/// output label tensor will not trigger an error because the label tensor is optional.
class NLClassifierOptions {
  final Pointer<TfLiteNLClassifierOptions> _options;
  bool _deleted = false;

  Pointer<TfLiteNLClassifierOptions> get base => _options;
  NLClassifierOptions._(this._options);

  static const DEFAULT_INPUT_TENSOR_NAME = "INPUT";
  static const DEFAULT_OUTPUT_SCORE_TENSOR_NAME = "OUTPUT_SCORE";
  // By default there is no output label tensor. The label file can be attached
  // to the output score tensor metadata.
  static const DEFAULT_OUTPUT_LABEL_TENSOR_NAME = "OUTPUT_LABEL";
  static const DEFAULT_INPUT_TENSOR_INDEX = 0;
  static const DEFAULT_OUTPUT_SCORE_TENSOR_INDEX = 0;
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

  String get inputTensorName => base.ref.inputTensorName.toDartString();

  /// Set the name of the input text tensor, if the model has multiple inputs. Only the input
  /// tensor specified will be used for inference; other input tensors will be ignored. Dafualt
  /// to ["INPUT"].
  ///
  /// <p>See the section, Configure the input/output tensors for NLClassifier, for more details.
  set inputTensorName(String value) {
    base.ref.inputTensorName = value.toNativeUtf8();
  }

  String get outputScoreTensorName =>
      base.ref.outputScoreTensorName.toDartString();

  /// Set the name of the output score tensor, if the model has multiple outputs. Dafualt to
  /// ["OUTPUT_SCORE"].
  ///
  ///  <p>See the section, Configure the input/output tensors for NLClassifier, for more details.
  set outputScoreTensorName(String value) {
    base.ref.outputScoreTensorName = value.toNativeUtf8();
  }

  String get outputLabelTensorName =>
      base.ref.outputLabelTensorName.toDartString();

  /// Set the name of the output label tensor, if the model has multiple outputs. Dafualt to
  /// ["OUTPUT_LABEL"].
  ///
  /// <p>See the section, Configure the input/output tensors for NLClassifier, for more details.
  ///
  /// <p>By default, label file should be packed with the output score tensor through Model
  /// Metadata. See the <a
  /// href="https://www.tensorflow.org/lite/convert/metadata_writer_tutorial#natural_language_classifiers">MetadataWriter
  /// for NLClassifier</a>. NLClassifier reads and parses labels from the label file
  /// automatically. However, some models may output a specific label tensor instead. In this
  /// case, NLClassifier reads labels from the output label tensor.
  set outputLabelTensorName(String value) {
    base.ref.outputLabelTensorName = value.toNativeUtf8();
  }

  int get inputTensorIndex => base.ref.inputTensorIndex;

  /// Set the index of the input text tensor among all input tensors, if the model has multiple
  /// inputs. Only the input tensor specified will be used for inference; other input tensors
  /// will be ignored. Dafualt to 0.
  ///
  /// <p>See the section, Configure the input/output tensors for NLClassifier, for more details.
  set inputTensorIndex(int value) {
    base.ref.inputTensorIndex = value;
  }

  int get outputScoreTensorIndex => base.ref.outputScoreTensorIndex;

  /// Set the index of the output score tensor among all output tensors, if the model has
  /// multiple outputs. Dafualt to 0.
  ///
  /// <p>See the section, Configure the input/output tensors for NLClassifier, for more details.
  set outputScoreTensorIndex(int value) {
    base.ref.outputScoreTensorIndex = value;
  }

  int get outputLabelTensorIndex => base.ref.outputLabelTensorIndex;

  /// Set the index of the optional output label tensor among all output tensors, if the model
  /// has multiple outputs.
  ///
  /// <p>See the document above [outputLabelTensorName] for more information about what the
  /// output label tensor is.
  ///
  /// <p>See the section, Configure the input/output tensors for NLClassifier, for more details.
  ///
  /// <p>[outputLabelTensorIndex] dafualts to -1, meaning to disable the output label
  /// tensor.
  set outputLabelTensorIndex(int value) {
    base.ref.outputLabelTensorIndex = value;
  }

  /// Destroys the options instance.
  void delete() {
    checkState(!_deleted, message: 'NLClassifierOptions already deleted.');
    calloc.free(_options);
    _deleted = true;
  }
}
