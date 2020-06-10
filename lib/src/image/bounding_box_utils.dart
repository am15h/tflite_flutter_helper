import 'dart:ui';

import 'package:flutter/rendering.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:tflite_flutter_helper/src/common/support_preconditions.dart';
import 'package:tflite_flutter_helper/src/tensorbuffer/tensorbuffer.dart';

class BoundingBoxUtils {
  static List<Rect> convert({
    TensorBuffer tensor,
    List<int> valueIndex = const <int>[0, 1, 2, 3],
    int boundingBoxAxis,
    BoundingBoxType boundingBoxType,
    CoordinateType coordinateType,
    int height,
    int width,
  }) {
    List<int> shape = tensor.getShape();
    SupportPreconditions.checkArgument(
      boundingBoxAxis >= -shape.length && boundingBoxAxis < shape.length,
      errorMessage:
          "Axis $boundingBoxAxis is not in range (-(D+1), D), where D is the number of dimensions of input" +
              " tensor (shape=$shape)",
    );

    if (boundingBoxAxis < 0) {
      boundingBoxAxis = shape.length + boundingBoxAxis;
    }
    SupportPreconditions.checkArgument(
      shape[boundingBoxAxis] == 4,
      errorMessage:
          "Size of bounding box dimBouBoxension $boundingBoxAxis is not 4. Got ${shape[boundingBoxAxis]} in shape $shape",
    );
    SupportPreconditions.checkArgument(
      valueIndex.length == 4,
      errorMessage:
          "Bounding box index array length ${valueIndex.length} is not 4. Got index array $valueIndex",
    );
    SupportPreconditions.checkArgument(
        tensor.getDataType() == TfLiteType.float32,
        errorMessage:
            "Bounding Boxes only create from FLOAT32 buffers. Got: ${tensor.getDataType()}");

    // From Android Library
    // Collapse dimensions to {a, 4, b}. So each bounding box could be represent as (i, j), and its
    // four values are (i, k, j), where 0 <= k < 4. We can compute the 4 flattened index by
    // i * 4b + k * b + j.
    int a = 1;
    for (int i = 0; i < boundingBoxAxis; i++) {
      a *= shape[i];
    }
    int b = 1;
    for (int i = boundingBoxAxis + 1; i < shape.length; i++) {
      b *= shape[i];
    }

    List<Rect> boundingBoxList = [];

    List<double> values = List(4);
    List<double> doubleList = tensor.getDoubleList();

    for (int i = 0; i < a; i++) {
      for (int j = 0; j < b; j++) {
        for (int k = 0; k < 4; k++) {
          values[k] = doubleList.elementAt((i * 4 + k) * b + j);
        }
        boundingBoxList.add(_convertOneBoundingBox(values, boundingBoxType,
            coordinateType, height, width, valueIndex));
      }
    }

    return boundingBoxList;
  }

  static Rect _convertOneBoundingBox(List<double> values, BoundingBoxType type,
      CoordinateType coordinateType, int height, int width,
      [List<int> valueIndex = const [0, 1, 2, 3]]) {
    List<double> orderedValues = List(4);
    for (int i = 0; i < 4; i++) {
      orderedValues[i] = values[valueIndex[i]];
    }

    switch (type) {
      case BoundingBoxType.BOUNDARIES:
        return _convertFromBoundaries(values, coordinateType, height, width);
      case BoundingBoxType.UPPER_LEFT:
        return _convertFromUpperLeft(values, coordinateType, height, width);
      case BoundingBoxType.CENTER:
        return _convertFromCenter(values, coordinateType, height, width);
    }

    throw ArgumentError('Cannot recognize BoundingBox.Type $type');
  }

  static Rect _convertFromBoundaries(List<double> values,
      CoordinateType coordinateType, int height, int width) {
    if (coordinateType == CoordinateType.RATIO) {
      return Rect.fromLTRB(values[0] * width, values[1] * height,
          values[2] * width, values[3] * height);
    } else {
      return Rect.fromLTRB(values[0], values[1], values[2], values[3]);
    }
  }

  static Rect _convertFromUpperLeft(List<double> values,
      CoordinateType coordinateType, int height, int width) {
    if (coordinateType == CoordinateType.PIXEL) {
      return Rect.fromLTWH(values[0], values[1], values[2], values[3]);
    }
    //TODO: CoordinateType.RATIO
  }

  static Rect _convertFromCenter(List<double> values,
      CoordinateType coordinateType, int height, int width) {
    if (coordinateType == CoordinateType.PIXEL) {
      return Rect.fromCenter(
          center: Offset(values[0], values[1]),
          width: values[2],
          height: values[3]);
    }
    //TODO: CoordinateType.RATIO
  }
}

enum BoundingBoxType { BOUNDARIES, UPPER_LEFT, CENTER }

enum CoordinateType { RATIO, PIXEL }
