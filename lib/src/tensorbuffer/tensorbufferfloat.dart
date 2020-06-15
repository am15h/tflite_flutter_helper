import 'package:tflite_flutter/src/bindings/types.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:tflite_flutter_helper/src/common/support_preconditions.dart';

import 'tensorbuffer.dart';

class TensorBufferFloat extends TensorBuffer {
  static final TfLiteType DATA_TYPE = TfLiteType.float32;

  TensorBufferFloat(List<int> shape) : super(shape);
  TensorBufferFloat.dynamic() : super.dynamic();

  @override
  TfLiteType getDataType() {
    return DATA_TYPE;
  }

  @override
  List<double> getDoubleList() {
    List<double> arr = List(flatSize);
    for (int i = 0; i < flatSize; i++) {
      arr[i] = byteData.getFloat32(i * 4);
    }
    return arr;
  }

  @override
  double getDoubleValue(int absIndex) {
    return getDoubleList().elementAt(absIndex);
  }

  @override
  List<int> getIntList() {
    List<int> arr = List(flatSize);
    for (int i = 0; i < flatSize; i++) {
      arr[i] = byteData.getFloat32(i * 4).floor();
    }
    return arr;
  }

  @override
  int getIntValue(int absIndex) {
    return getIntList().elementAt(absIndex);
  }

  @override
  int getTypeSize() {
    // returns size in bytes
    return 4;
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
        byteData.setFloat32(i * 4, src[i]);
      }
    } else if (src is List<int>) {
      for (int i = 0; i < src.length; i++) {
        byteData.setInt32(i * 4, src[i]);
      }
    }
  }
}
