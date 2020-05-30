import 'dart:typed_data';

import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:tflite_flutter_helper/src/common/support_preconditions.dart';
import 'package:tflite_flutter_helper/src/tensorbuffer/tensorbuffer.dart';

import 'category.dart';

class TensorLabel {
  Map<int, List<String>> _axisLabels;
  TensorBuffer _tensorBuffer;
  List<int> _shape;

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

  factory TensorLabel.fromList(
      List<String> axisLabels, TensorBuffer tensorBuffer) {
    return TensorLabel.fromMap(
        makeMap(getFirstAxisWithSizeGreaterThanOne(tensorBuffer), axisLabels),
        tensorBuffer);
  }

  Map<String, TensorBuffer> getMapWithTensorBuffer() {
    int labeledAxis = getFirstAxisWithSizeGreaterThanOne(_tensorBuffer);

    Map<String, TensorBuffer> labelToTensorMap = {};
    SupportPreconditions.checkArgument(_axisLabels.containsKey(labeledAxis),
        errorMessage:
            "get a <String, TensorBuffer> map requires the labels are set on the first non-1 axis.");
    List<String> labels = _axisLabels[labeledAxis];

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

  Map<String, double> getMapWithFloatValue() {
    int labeledAxis = getFirstAxisWithSizeGreaterThanOne(_tensorBuffer);
    SupportPreconditions.checkState(labeledAxis == _shape.length - 1,
        errorMessage:
            "get a <String, Scalar> map is only valid when the only labeled axis is the last one.");
    List<String> labels = _axisLabels[labeledAxis];
    List<double> data = _tensorBuffer.getDoubleList();
    SupportPreconditions.checkState(labels.length == data.length);
    Map<String, double> result = {};
    labels.asMap().forEach((i, label) {
      result[label] = data[i];
    });
    return result;
  }

  List<Category> getCategoryList() {
    int labeledAxis = getFirstAxisWithSizeGreaterThanOne(_tensorBuffer);
    SupportPreconditions.checkState(labeledAxis == _shape.length - 1,
        errorMessage:
            "get a Category list is only valid when the only labeled axis is the last one.");
    List<String> labels = _axisLabels[labeledAxis];
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

  // Helper function to wrap the List<String> to a one-entry map.
  static Map<int, List<String>> makeMap(int axis, List<String> labels) {
    Map<int, List<String>> map = {};
    map[axis] = labels;
    return map;
  }
}
