import 'dart:ffi';
import 'dart:typed_data';
import 'dart:math';

import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:tflite_flutter_helper/src/common/support_preconditions.dart';
import 'package:tflite_flutter_helper/src/tensorbuffer/tensorbuffer.dart';

class TensorBufferUint8 extends TensorBuffer {
  TensorBufferUint8.dynamic() : super.dynamic();
  TensorBufferUint8(List<int> shape) : super(shape);

  @override
  TfLiteType getDataType() {
    return TfLiteType.uint8;
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
    return byteData.getFloat32(absIndex * 4);
  }

  @override
  List<int> getIntList() {
    List<int> arr = List(flatSize);
    for (int i = 0; i < flatSize; i++) {
      arr[i] = byteData.getInt32(i * 4);
    }
    return arr;
  }

  @override
  int getIntValue(int absIndex) {
    return byteData.getInt32(absIndex * 4);
  }

  @override
  int getTypeSize() {
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
        // TODO: Testing required here may not work
        ByteData bdata = ByteData(4);
        bdata.setFloat32(0, max(min(src[i], 255.0), 0.0));
        byteData.setUint8(i, bdata.getUint8(0));
      }
    } else if (src is List<int>) {
      for (int i = 0; i < src.length; i++) {
        // TODO: Testing required here may not work
        ByteData bdata = ByteData(4);
        bdata.setInt32(0, max(min(src[i], 255), 0));
        byteData.setUint8(i, bdata.getUint8(0));
      }
    }
  }
}
