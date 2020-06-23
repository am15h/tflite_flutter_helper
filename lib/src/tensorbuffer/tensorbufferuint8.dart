import 'dart:ffi';
import 'dart:typed_data';
import 'dart:math';

import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:tflite_flutter_helper/src/common/support_preconditions.dart';
import 'package:tflite_flutter_helper/src/tensorbuffer/tensorbuffer.dart';

/// Represents data buffer with 8-bit unsigned integer values.
class TensorBufferUint8 extends TensorBuffer {
  /// Creates a [TensorBufferUint8] with specified [shape].
  ///
  /// Throws [ArgumentError.notNull] if [shape] is null.
  /// Throws [ArgumentError] if [shape] has non-positive elements.
  TensorBufferUint8(List<int> shape) : super(shape);
  TensorBufferUint8.dynamic() : super.dynamic();

  @override
  TfLiteType getDataType() {
    return TfLiteType.uint8;
  }

  @override
  List<double> getDoubleList() {
    List<int> intList = getIntList();
    return intList.map((i) => i.toDouble()).toList();
  }

  @override
  double getDoubleValue(int absIndex) {
    return byteData.getFloat32(absIndex);
  }

  @override
  List<int> getIntList() {
    List<int> arr = List(flatSize);
    for (int i = 0; i < flatSize; i++) {
      arr[i] = byteData.getUint8(i);
    }
    return arr;
  }

  @override
  int getIntValue(int absIndex) {
    return byteData.getUint8(absIndex);
  }

  @override
  int getTypeSize() {
    return 1;
  }

  @override
  void loadList(List src, {List<int> shape}) {
    SupportPreconditions.checkNotNull(src,
        message: "The array to be loaded cannot be null.");
    SupportPreconditions.checkArgument(
        src.length == TensorBuffer.computeFlatSize(shape),
        errorMessage:
            "The size of the array to be loaded does not match the specified shape.");
    resize(shape);

    if (src is List<double>) {
      for (int i = 0; i < src.length; i++) {
        // TODO: Implementation required
        throw ArgumentError('List<double> not supported yet');
      }
    } else if (src is List<int>) {
      for (int i = 0; i < src.length; i++) {
        byteData.setUint8(i, max(min(src[i], 255), 0));
      }
    }
  }
}
