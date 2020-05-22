import 'dart:typed_data';

import 'package:tflite_flutter_helper/src/common/support_preconditions.dart';
import 'package:flutter/foundation.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

abstract class TensorBuffer {
  /// Where the data is stored
  @protected
  ByteData byteData;

  /// Shape of the tensor
  @protected
  List<int> shape;

  /// Number of elements in the buffer. It will be changed to a proper value in the constructor.
  @protected
  int flatSize = -1;

  /// Indicator of whether this buffer is dynamic or fixed-size. Fixed-size buffers will have
  ///  pre-allocated memory and fixed size. While the size of dynamic buffers can be changed.
  bool _isDynamic;

  static TensorBuffer createFixedSize(List<int> shape, TfLiteType dataType) {
    switch (dataType) {
      case TfLiteType.float32:
        //TODO: return TensorBufferFloat()
        return null;
      case TfLiteType.uint8:
        //TODO: return TensorBufferUInt8()
        return null;
      default:
        throw ArgumentError(
            'TensorBuffer does not support data type: \" +$dataType');
    }
  }

  static TensorBuffer createDynamic(TfLiteType dataType) {
    switch (dataType) {
      case TfLiteType.float32:
        //TODO: return TensorBufferFloat()
        return null;
      case TfLiteType.uint8:
        //TODO: return TensorBufferUInt8()
        return null;
      default:
        throw ArgumentError(
            'TensorBuffer does not support data type: \" +$dataType');
    }
  }

  ByteBuffer getBuffer() => byteData.buffer;

  int getFlatSize() => flatSize;

  List<int> getShape() => shape;

  TfLiteType getDataType();

  List<double> getDoubleList();

  double getDoubleValue(int absIndex);

  List<int> getIntList();

  int getIntValue(int absIndex);

  int getTypeSize();

  bool get isDynamic => _isDynamic;

  void loadList(List<dynamic> src, {List<int> shape});

  void loadBuffer(ByteBuffer buffer, {List<int> shape}) {
    SupportPreconditions.checkNotNull(buffer,
        message: "Byte Buffer cannot be null");
    int flatSize = computeFlatSize(shape);
    SupportPreconditions.checkArgument(
        (ByteData.view(buffer).lengthInBytes == getTypeSize() * flatSize),
        errorMessage: "The size of byte buffer and the shape do not match.");

    if (!_isDynamic) {
      SupportPreconditions.checkArgument(flatSize == this.flatSize,
          errorMessage:
              "The size of byte buffer and the size of the tensor buffer do not match.");
    } else {
      this.flatSize = flatSize;
    }

    this.shape = List<int>.from(shape);
    this.byteData = ByteData.view(buffer);
  }

  @protected
  TensorBuffer(List<int> shape) {
    _isDynamic = false;
    _allocateMemory(shape);
  }

  @protected
  TensorBuffer.dynamic() {
    _isDynamic = true;
    _allocateMemory([0]);
  }

  void _allocateMemory(List<int> shape) {
    SupportPreconditions.checkNotNull(shape,
        message: 'TensorBuffer shape cannot be null.');
    SupportPreconditions.checkArgument(_isShapeValid(shape),
        errorMessage: 'TensorBuffer shape cannot be null.');

    int newFlatSize = computeFlatSize(shape);
    this.shape = List<int>.from(shape);
    if (flatSize == newFlatSize) {
      return;
    }

    // Update to the new shape.
    flatSize = newFlatSize;
    byteData = ByteData(flatSize * getTypeSize());
  }

  @protected
  void resize(List<int> shape) {
    if (_isDynamic) {
      _allocateMemory(shape);
    } else {
      // Make sure the new shape fits the buffer size when TensorBuffer has fixed size.
      SupportPreconditions.checkArgument(
          (computeFlatSize(shape) == computeFlatSize(this.shape)));
      this.shape = List<int>.from(shape);
    }
  }

  static _isShapeValid(List<int> shape) {
    if (shape.length == 0) {
      // This shape refers to a scalar.
      return true;
    }

    // This shape refers to a multidimensional array.
    for (int s in shape) {
      // All elements in shape should be non-negative.
      if (s < 0) {
        return false;
      }
    }
    return true;
  }

  static int computeFlatSize(List<int> shape) {
    SupportPreconditions.checkNotNull(shape, message: "Shape cannot be null.");
    int prod = 1;
    for (int s in shape) {
      prod = prod * s;
    }
    return prod;
  }
}
