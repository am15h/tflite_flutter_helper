import 'dart:ffi';

import 'package:ffi/ffi.dart';

class TfLiteNLClassifier extends Opaque {}

// struct NLClassifierOptions {
// int input_tensor_index;
// int output_score_tensor_index;
// int output_label_tensor_index;
// const char* input_tensor_name;
// const char* output_score_tensor_name;
// const char* output_label_tensor_name;
// };

class TfLiteNLClassifierOptions extends Struct {
  @Int32()
  external int inputTensorIndex;

  @Int32()
  external int outputScoreTensorIndex;

  @Int32()
  external int outputLabelTensorIndex;

  external Pointer<Utf8> inputTensorName;

  external Pointer<Utf8> outputScoreTensorName;

  external Pointer<Utf8> outputLabelTensorName;

  static Pointer<TfLiteNLClassifierOptions> allocate(
    int inputTensorIndex,
    int outputScoreTensorIndex,
    int outputLabelTensorIndex,
    String inputTensorName,
    String outputScoreTensorName,
    String outputLabelTensorName,
  ) {
    final result = calloc<TfLiteNLClassifierOptions>();
    result.ref
      ..inputTensorIndex = inputTensorIndex
      ..outputScoreTensorIndex = outputScoreTensorIndex
      ..outputLabelTensorIndex = outputLabelTensorIndex
      ..inputTensorName = inputTensorName.toNativeUtf8()
      ..outputScoreTensorName = outputScoreTensorName.toNativeUtf8()
      ..outputLabelTensorName = outputLabelTensorName.toNativeUtf8();
    return result;
  }
}

class TfLiteCategories extends Struct {
  @Int32()
  external int size;

  external Pointer<TfLiteCategory> categories;
}

class TfLiteCategory extends Struct {
  external Pointer<Utf8> text;

  @Double()
  external double score;
}

class TfLiteBertNLClassifier extends Opaque {}

class TfLiteBertNLClassifierOptions extends Struct {
  @Int32()
  external int maxSeqLen;
}
