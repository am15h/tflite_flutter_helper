import 'dart:typed_data';

import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:tflite_flutter_helper/src/common/support_preconditions.dart';
import 'package:tflite_flutter_helper/src/tensorbuffer/tensorbuffer.dart';

import 'category.dart';

/// TensorLabel is an util wrapper for TensorBuffers with meaningful labels on an axis.
///
/// <p>For example, an image classification model may have an output tensor with shape as {1, 10},
/// where 1 is the batch size and 10 is the number of categories. In fact, on the 2nd axis, we could
/// label each sub-tensor with the name or description of each corresponding category.
/// [TensorLabel] could help converting the plain Tensor in [TensorBuffer] into a map from
/// predefined labels to sub-tensors. In this case, if provided 10 labels for the 2nd axis,
/// [TensorLabel] could convert the original {1, 10} Tensor to a 10 element map, each value of which
/// is Tensor in shape {} (scalar).
///
/// <p>Note: currently we only support tensor-to-map conversion for the first label with size greater
/// than 1.
///
/// See [FileUtil.loadLabels] to load labels from a label file (plain text file whose each line is a
/// label) in assets simply.
class TensorLabel {
  late Map<int, List<String>> _axisLabels;
  late TensorBuffer _tensorBuffer;
  late List<int> _shape;

  /// Creates a TensorLabel object which is able to label on the axes of multi-dimensional tensors.
  ///
  /// [axisLabels] is A map, whose key is axis id (starting from 0) and value is corresponding
  ///     labels. Note: The size of labels should be same with the size of the tensor on that axis.
  ///
  /// [tensorBuffer] to be labeled
  ///
  /// Throws [ArgumentError.notNull] if [axisLabels] or [tensorBuffer] is null, or any
  /// value in [axisLabels] is null.
  ///
  /// Throws [ArgumentError] if any key in [axisLabels] is out of range (compared to
  /// the shape of [tensorBuffer], or any value (labels) has different size with the
  /// [tensorBuffer] on the given dimension.
  factory TensorLabel(
      Map<int, List<String>> axisLabels, TensorBuffer tensorBuffer) {
    return TensorLabel.fromMap(axisLabels, tensorBuffer);
  }

  TensorLabel.fromMap(
      Map<int, List<String>> axisLabels, TensorBuffer tensorBuffer) {
    SupportPreconditions.checkNotNull(axisLabels,
        message: "Axis labels cannot be null.");
    SupportPreconditions.checkNotNull(tensorBuffer,
        message: "Tensor Buffer cannot be null.");
    _axisLabels = axisLabels;
    _tensorBuffer = tensorBuffer;
    _shape = tensorBuffer.getShape();

    axisLabels.forEach((axis, labels) {
      SupportPreconditions.checkArgument(axis >= 0 && axis < _shape.length,
          errorMessage: "Invalid axis id: $axis");
      SupportPreconditions.checkNotNull(labels,
          message: "Label list is null on axis: $axis");
      SupportPreconditions.checkArgument(_shape[axis] == labels.length,
          errorMessage: "Label number " +
              "${labels.length} mismatch the shape on axis $axis");
    });
  }

  /// Creates a TensorLabel object which is able to label on one axis of multi-dimensional tensors.
  ///
  /// <p>Note: The labels are applied on the first axis whose size is larger than 1. For example, if
  /// the shape of the tensor is {1, 10, 3}, the labels will be applied on axis 1 (id starting from
  /// 0), and size of {@code axisLabels} should be 10 as well.
  ///
  /// [axisLabels] is list of labels, whose size should be same with the size of the tensor on
  ///  the to-be-labeled axis.
  ///
  /// [tensorBuffer] to be labeled.
  factory TensorLabel.fromList(
      List<String> axisLabels, TensorBuffer tensorBuffer) {
    return TensorLabel.fromMap(
        _makeMap(getFirstAxisWithSizeGreaterThanOne(tensorBuffer), axisLabels),
        tensorBuffer);
  }

  /// Gets the map with a pair of the label and the corresponding TensorBuffer. Only allow the
  /// mapping on the first axis with size greater than 1 currently.
  Map<String, TensorBuffer> getMapWithTensorBuffer() {
    int labeledAxis = getFirstAxisWithSizeGreaterThanOne(_tensorBuffer);

    Map<String, TensorBuffer> labelToTensorMap = {};
    SupportPreconditions.checkArgument(_axisLabels.containsKey(labeledAxis),
        errorMessage:
            "get a <String, TensorBuffer> map requires the labels are set on the first non-1 axis.");
    List<String> labels = _axisLabels[labeledAxis]!;

    TfLiteType dataType = _tensorBuffer.getDataType();
    int typeSize = _tensorBuffer.getTypeSize();
    int flatSize = _tensorBuffer.getFlatSize();

    // Gets the underlying bytes that could be used to generate the sub-array later.
    ByteBuffer byteBuffer = _tensorBuffer.getBuffer();

    // Note: computation below is only correct when labeledAxis is the first axis with size greater
    // than 1.
    int subArrayLength = (flatSize / _shape[labeledAxis]).floor() * typeSize;
    SupportPreconditions.checkNotNull(labels,
        message: "Label list should never be null");
    labels.asMap().forEach((i, label) {
      ByteData bData = byteBuffer.asByteData(i * subArrayLength);
      TensorBuffer labelBuffer = TensorBuffer.createDynamic(dataType);
      labelBuffer.loadBuffer(bData.buffer,
          shape: _shape.sublist(labeledAxis + 1, _shape.length));
      labelToTensorMap[label] = labelBuffer;
    });
    return labelToTensorMap;
  }

  /// Gets a map that maps label to float. Only allow the mapping on the first axis with size greater
  /// than 1, and the axis should be effectively the last axis (which means every sub tensor
  /// specified by this axis should have a flat size of 1).
  ///
  /// [TensorLabel.getCategoryList] is an alternative API to get the result.
  ///
  /// Throws [StateError] if size of a sub tensor on each label is not 1.
  Map<String, double> getMapWithFloatValue() {
    int labeledAxis = getFirstAxisWithSizeGreaterThanOne(_tensorBuffer);
    SupportPreconditions.checkState(labeledAxis == _shape.length - 1,
        errorMessage:
            "get a <String, Scalar> map is only valid when the only labeled axis is the last one.");
    List<String> labels = _axisLabels[labeledAxis]!;
    List<double> data = _tensorBuffer.getDoubleList();
    SupportPreconditions.checkState(labels.length == data.length);
    Map<String, double> result = {};
    labels.asMap().forEach((i, label) {
      result[label] = data[i];
    });
    return result;
  }

  /// Gets a list of [Category] from the [TensorLabel] object.
  ///
  /// The axis of label should be effectively the last axis (which means every sub tensor
  /// specified by this axis should have a flat size of 1), so that each labelled sub tensor could be
  /// converted into a float value score. Example: A [TensorLabel] with shape `{2, 5, 3}`
  /// and axis 2 is valid. If axis is 1 or 0, it cannot be converted into a [Category].
  ///
  /// [TensorLabel.getMapWithFloatValue] is an alternative but returns a [Map] as
  /// the result.
  ///
  /// Throws [StateError] if size of a sub tensor on each label is not 1.
  List<Category> getCategoryList() {
    int labeledAxis = getFirstAxisWithSizeGreaterThanOne(_tensorBuffer);
    SupportPreconditions.checkState(labeledAxis == _shape.length - 1,
        errorMessage:
            "get a Category list is only valid when the only labeled axis is the last one.");
    List<String> labels = _axisLabels[labeledAxis]!;
    List<double> data = _tensorBuffer.getDoubleList();
    SupportPreconditions.checkState(labels.length == data.length);
    List<Category> result = [];
    labels.asMap().forEach((i, label) {
      result.add(Category(label, data[i]));
    });
    return result;
  }

  static int getFirstAxisWithSizeGreaterThanOne(TensorBuffer tensorBuffer) {
    List<int> shape = tensorBuffer.getShape();
    for (int i = 0; i < shape.length; i++) {
      if (shape[i] > 1) {
        return i;
      }
    }
    throw new ArgumentError(
        "Cannot find an axis to label. A valid axis to label should have size larger than 1.");
  }

  /// Helper function to wrap the List<String> to a one-entry map.
  static Map<int, List<String>> _makeMap(int axis, List<String> labels) {
    Map<int, List<String>> map = {};
    map[axis] = labels;
    return map;
  }
}
