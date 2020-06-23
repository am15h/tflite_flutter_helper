import 'dart:ui';

import 'package:flutter/rendering.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:tflite_flutter_helper/src/common/support_preconditions.dart';
import 'package:tflite_flutter_helper/src/tensorbuffer/tensorbuffer.dart';

/// Helper class for converting values that represents bounding boxes into rectangles.
///
/// The class provides a static function to create bounding boxes as {@link RectF} from different
/// types of configurations.
///
/// Generally, a bounding box could be represented by 4 double values, but the values could be
/// interpreted in many ways. Three [BoundingBoxType] of configurations are supported, and the order of
/// elements in each type is configurable as well.
class BoundingBoxUtils {
  /// Creates a list of bounding boxes from a [TensorBuffer] [tensor] which represents bounding boxes.
  ///
  /// [valueIndex] denotes the order of the elements defined in each bounding box type. An empty
  /// index list represent the default order of each bounding box type. For example, to denote
  /// the default order of BOUNDARIES, [left, top, right, bottom], the index should be [0, 1, 2,
  /// 3]. To denote the order [left, right, top, bottom], the order should be [0, 2, 1, 3].
  /// The index list can be applied to all bounding box types to adjust the order of their
  /// corresponding underlying elements.
  ///
  /// [boundingBoxAxis] specifies the index of the dimension that represents bounding box. The
  /// size of that dimension is required to be 4. Index here starts from 0. For example, if the
  /// tensor has shape 4x10, the axis for bounding boxes is likely to be 0. For shape 10x4, the
  /// axis is likely to be 1 (or -1, equivalently).
  ///
  /// [boundingBoxType] defines how values should be converted into boxes. See [BoundingBoxType]
  ///
  /// [coordinateType] defines how values are interpreted to coordinates. See [CoordinateType]
  ///
  /// [height] is height of the image which the boxes belong to. Only has effects when [coordinateType]
  /// is [CoordinateType.RATIO]
  ///
  /// [width] is width of the image which the boxes belong to. Only has effects when [coordinateType]
  /// is [CoordinateType.RATIO]
  ///
  /// Returns A list of bounding boxes [List<Rect>] that the [tensor] represents. All dimensions except
  /// [boundingBoxAxis] will be collapsed with order kept. For example, given
  /// [tensor] with shape [1, 4, 10, 2] and [boundingBoxAxis = 1], The result will be a list
  /// of 20 bounding boxes.
  ///
  /// Throws [ArgumentError] if size of bounding box dimension (set by
  /// [boundingBoxAxis]) is not 4.
  ///
  /// Throws [ArgumentError] if [boundingBoxAxis] is not in [(-(D+1), D)] where
  /// [D] is the number of dimensions of the [tensor].
  ///
  /// Throws [ArgumentError] if [tensor] has data type other than
  /// [TfLiteType.float32].
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
          "Bounding box index list length ${valueIndex.length} is not 4. Got index list $valueIndex",
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
    } else {
      throw UnsupportedError(
          'CoordinateType.RATIO not supported with BoundingBoxType.UPPER_LEFT');
    }
  }

  static Rect _convertFromCenter(List<double> values,
      CoordinateType coordinateType, int height, int width) {
    if (coordinateType == CoordinateType.PIXEL) {
      return Rect.fromCenter(
          center: Offset(values[0], values[1]),
          width: values[2],
          height: values[3]);
    } else {
      throw UnsupportedError(
          'CoordinateType.RATIO not supported with BoundingBoxType.CENTER');
    }
  }
}

/// Denotes how a bounding box is represented.
enum BoundingBoxType {
  /// Represents the bounding box by using the combination of boundaries, [left, top, right,
  /// bottom]. The default order is [left, top, right, bottom]. Other orders can be indicated by an
  /// index list.
  BOUNDARIES,

  /// Represents the bounding box by using the upper_left corner, width and height. The default
  /// order is [upper_left_x, upper_left_y, width, height]. Other orders can be indicated by an
  /// index list.
  UPPER_LEFT,

  /// Represents the bounding box by using the center of the box, width and height. The default
  /// order is [center_x, center_y, width, height]. Other orders can be indicated by an index
  /// list.
  CENTER
}

/// Denotes if the coordinates are actual pixels or relative ratios.
enum CoordinateType {
  /// The coordinates are relative ratios in range [0, 1]. */
  RATIO,

  /// The coordinates are actual pixel values.
  PIXEL
}
