import 'dart:typed_data';

import 'package:tflite_flutter_helper/src/common/support_preconditions.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:meta/meta.dart';
import 'package:tflite_flutter_helper/src/tensorbuffer/tensorbufferfloat.dart';
import 'package:tflite_flutter_helper/src/tensorbuffer/tensorbufferuint8.dart';

/// Represents the data buffer for either a model's input or its output.
abstract class TensorBuffer {
  /// Where the data is stored
  @protected
  late ByteData byteData;

  /// Shape of the tensor
  @protected
  late List<int> shape;

  /// Number of elements in the buffer. It will be changed to a proper value in the constructor.
  @protected
  late int flatSize = -1;

  /// Indicator of whether this buffer is dynamic or fixed-size. Fixed-size buffers will have
  ///  pre-allocated memory and fixed size. While the size of dynamic buffers can be changed.
  late bool _isDynamic;

  /// Creates a [TensorBuffer] with specified [shape] and [TfLiteType]. Here are some
  /// examples:
  ///
  /// ```dart
  /// Creating a float TensorBuffer with shape [2, 3]:
  /// List<int> shape = [2, 3];
  /// TensorBuffer tensorBuffer = TensorBuffer.createFixedSize(shape, TfLiteType.float32);
  /// ```
  ///
  /// ```dart
  /// Creating an uint8 TensorBuffer of a scalar:
  /// List<int> shape = [2, 3];
  /// TensorBuffer tensorBuffer = TensorBuffer.createFixedSize(shape, TfLiteType.uint8);
  /// ```
  ///
  /// ```dart
  /// Creating an empty uint8 TensorBuffer:
  /// List<int> shape = [0];
  /// TensorBuffer tensorBuffer = TensorBuffer.createFixedSize(shape, TfLiteType.uint8);
  /// ```
  ///
  /// The size of a fixed-size TensorBuffer cannot be changed once it is created.
  ///
  /// Throws [ArgumentError.notNull] if [shape] is null and
  /// [ArgumentError] is [shape] has non-positive elements.
  static TensorBuffer createFixedSize(List<int> shape, TfLiteType dataType) {
    switch (dataType) {
      case TfLiteType.float32:
        return TensorBufferFloat(shape);
      case TfLiteType.uint8:
        return TensorBufferUint8(shape);
      default:
        throw ArgumentError(
            'TensorBuffer does not support data type: \" +$dataType');
    }
  }

  final Endian endian = Endian.little;

  /// Creates an empty dynamic [TensorBuffer] with specified [TfLiteType]. The shape of the
  /// created [TensorBuffer] is {0}.
  ///
  /// Dynamic TensorBuffers will reallocate memory when loading arrays or data buffers of
  /// different buffer sizes.
  static TensorBuffer createDynamic(TfLiteType dataType) {
    switch (dataType) {
      case TfLiteType.float32:
        return TensorBufferFloat.dynamic();
      case TfLiteType.uint8:
        return TensorBufferUint8.dynamic();
      default:
        throw ArgumentError(
            'TensorBuffer does not support data type: \" +$dataType');
    }
  }

  /// Creates a [TensorBuffer] deep-copying data from another, with specified [TfLiteType].
  ///
  /// Throws [ArgumentError.notNull] if [buffer] is null.
  static TensorBuffer createFrom(TensorBuffer buffer, TfLiteType dataType) {
    SupportPreconditions.checkNotNull(buffer,
        message: "Cannot create a buffer from null");
    TensorBuffer result;
    if (buffer.isDynamic) {
      result = createDynamic(dataType);
    } else {
      result = createFixedSize(buffer.shape, dataType);
    }
    // The only scenario we need float array is FLOAT32->FLOAT32, or we can always use INT as
    // intermediate container.
    // The assumption is not true when we support other data types.
    if (buffer.getDataType() == TfLiteType.float32 &&
        dataType == TfLiteType.float32) {
      List<double> data = buffer.getDoubleList();
      result.loadList(data, shape: buffer.shape);
    } else {
      List<int> data = buffer.getIntList();
      result.loadList(data, shape: buffer.shape);
    }
    return result;
  }

  /// Returns the data buffer.
  ByteBuffer getBuffer() => byteData.buffer;

  /// Returns the data buffer.
  ByteBuffer get buffer => byteData.buffer;

  /// Gets the [TensorBuffer.flatSize] of the buffer.
  int getFlatSize() => flatSize;

  /// Gets the current shape. (returning a copy here to avoid unexpected modification.)
  List<int> getShape() => shape;

  /// Returns the data type of this buffer.
  TfLiteType getDataType();

  /// Returns a List<double> of the values stored in this buffer. If the buffer is of different types
  /// than double, the values will be converted into double. For example, values in
  /// [TensorBufferUint8] will be converted from uint8 to double.
  List<double> getDoubleList();

  /// Returns a double value at [absIndex]. If the buffer is of different types than double, the
  /// value will be converted into double. For example, when reading a value from
  /// [TensorBufferUint8], the value will be first read out as uint8, and then will be converted from
  /// uint8 to double.
  ///
  /// ```
  /// For example, a TensorBuffer with shape {2, 3} that represents the following list,
  /// {{0.0, 1.0, 2.0}, {3.0, 4.0, 5.0}}.
  ///
  /// The fourth element (whose value is 3.0) in the TensorBuffer can be retrieved by:
  /// double v = tensorBuffer.getDoubleValue(3);
  /// ```
  double getDoubleValue(int absIndex);

  /// Returns an int array of the values stored in this buffer. If the buffer is of different type
  /// than int, the values will be converted into int, and loss of precision may apply. For example,
  /// getting an int array from a [TensorBufferFloat] with values {400.32, 23.04}, the output
  /// is {400, 23}.
  List<int> getIntList();

  /// Returns an int value at [absIndex].
  ///
  /// Similar to [TensorBuffer.getDoubleValue]
  int getIntValue(int absIndex);

  /// Returns the number of bytes of a single element in the list. For example, a float buffer will
  /// return 4, and a byte buffer will return 1.
  int getTypeSize();

  /// Returns if the [TensorBuffer] is dynamic sized (could resize arbitrarily). */
  bool get isDynamic => _isDynamic;

  /// Loads an List<int> into this buffer with specific [shape]. If the buffer is of different types
  /// than int, the values will be converted into the buffer's type before being loaded into the
  /// buffer, and loss of precision may apply. For example, loading an List<int> with values {400,
  /// -23} into a [TensorBufferUint8] , the values will be clamped to {0, 255} and then be
  /// casted to uint8 by {255, 0}.
  ///
  /// If [shape] is null then [TensorBuffer.shape] is used.
  void loadList(List<dynamic> src, {required List<int> shape});

  /// Loads a byte buffer into this [TensorBuffer] with specific [shape].
  ///
  /// If [shape] is null then [TensorBuffer.shape] is used.
  ///
  /// Important: The loaded buffer is a reference. DO NOT MODIFY. We don't create a copy here for
  /// performance concern, but if modification is necessary, please make a copy.
  ///
  /// Throws [ArgumentError.notNull] if [buffer] is null.
  /// Throws [ArgumentError] if the size of [buffer] in bytes and [getTypeSize] * [flatSize] do not
  /// match.
  void loadBuffer(ByteBuffer buffer, {List<int>? shape}) {
    SupportPreconditions.checkNotNull(buffer,
        message: "Byte Buffer cannot be null");

    int flatSize = computeFlatSize(shape ?? this.shape);

    SupportPreconditions.checkArgument(
        (ByteData.view(buffer).lengthInBytes == getTypeSize() * flatSize),
        errorMessage:
            "The size of byte buffer and the shape do not match. buffer: ${ByteData.view(buffer).lengthInBytes} shape: ${getTypeSize() * flatSize}");

    if (!_isDynamic) {
      SupportPreconditions.checkArgument(flatSize == this.flatSize,
          errorMessage:
              "The size of byte buffer and the size of the tensor buffer do not match.");
    } else {
      this.flatSize = flatSize;
    }

    this.shape = List<int>.from(shape ?? this.shape);
    this.byteData = ByteData.view(buffer);
  }

  /// Constructs a fixed size [TensorBuffer] with specified [shape].
  @protected
  TensorBuffer(List<int> shape) {
    _isDynamic = false;
    _allocateMemory(shape);
  }

  /// Constructs a dynamic [TensorBuffer] which can be resized.
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

  /// For dynamic buffer, resize the memory if needed. For fixed-size buffer, check if the
  /// [shape] of src fits the buffer size.
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

  /// Checks if [shape] meets one of following two requirements: 1. Elements in [shape]
  /// are all non-negative numbers. 2. [shape] is an empty array, which corresponds to scalar.
  static _isShapeValid(List<int> shape) {
    if (shape.length == 0) {
      // This shape refers to a scalar.
      return true;
    }

    // This shape refers to a multidimensional list.
    for (int s in shape) {
      // All elements in shape should be non-negative.
      if (s < 0) {
        return false;
      }
    }
    return true;
  }

  /// Calculates number of elements in the buffer.
  static int computeFlatSize(List<int> shape) {
    SupportPreconditions.checkNotNull(shape, message: "Shape cannot be null.");
    int prod = 1;
    for (int s in shape) {
      prod = prod * s;
    }
    return prod;
  }
}
