import 'dart:math';
import 'dart:ui';

import 'package:tflite_flutter_helper/src/common/operator.dart';
import 'package:tflite_flutter_helper/src/common/sequential_processor.dart';
import 'package:tflite_flutter_helper/src/common/support_preconditions.dart';
import 'package:tflite_flutter_helper/src/image/tensor_image.dart';

import 'image_operator.dart';
import 'ops/rot90_op.dart';

class ImageProcessor extends SequentialProcessor<TensorImage> {
  ImageProcessor._(SequentialProcessorBuilder<TensorImage> builder)
      : super(builder);

  Point inverseTransform(
      Point point, int inputImageHeight, int inputImageWidth) {
    List<int> widths = [];
    List<int> heights = [];
    int currentWidth = inputImageWidth;
    int currentHeight = inputImageHeight;
    for (Operator<TensorImage> op in operatorList) {
      widths.add(currentWidth);
      heights.add(currentHeight);
      ImageOperator imageOperator = op as ImageOperator;
      int newHeight =
          imageOperator.getOutputImageHeight(currentHeight, currentWidth);
      int newWidth =
          imageOperator.getOutputImageWidth(currentHeight, currentWidth);
      currentHeight = newHeight;
      currentWidth = newWidth;
    }

    Iterator<Operator<TensorImage>> opIterator = operatorList.reversed.iterator;
    Iterator<int> widthIterator = widths.reversed.iterator;
    Iterator<int> heightIterator = heights.reversed.iterator;

    while (opIterator.moveNext()) {
      heightIterator.moveNext();
      widthIterator.moveNext();
      ImageOperator imageOperator = opIterator.current;
      int height = heightIterator.current;
      int width = widthIterator.current;
      point = imageOperator.inverseTransform(point, height, width);
    }
    return point;
  }

  Rect inverseTransformRect(
      Rect rect, int inputImageHeight, int inputImageWidth) {
    // when rotation is involved, corner order may change - top left changes to bottom right, .etc
    Point p1 = inverseTransform(
        Point(rect.left, rect.top), inputImageHeight, inputImageWidth);
    Point p2 = inverseTransform(
        Point(rect.right, rect.bottom), inputImageHeight, inputImageWidth);
    return Rect.fromLTRB(
        min(p1.x, p2.x), min(p1.y, p2.y), max(p1.x, p2.x), max(p1.y, p2.y));
  }

  void updateNumberOfRotations(int k, int occurrence) {
    SupportPreconditions.checkState(
        operatorIndex.containsKey(Rot90Op().runtimeType.toString()),
        errorMessage: "The Rot90Op has not been added to the ImageProcessor.");

    List<int> indexes = operatorIndex[Rot90Op().runtimeType.toString()];
    SupportPreconditions.checkElementIndex(occurrence, indexes.length,
        desc: "occurrence");

    // The index of the Rot90Op to be replaced in operatorList.
    int index = indexes[occurrence];
    Rot90Op newRot = Rot90Op(k);
    operatorList[index] = newRot;
  }
}

class ImageProcessorBuilder extends SequentialProcessorBuilder<TensorImage> {
  ImageProcessorBuilder() : super();

  ImageProcessorBuilder add(Operator<TensorImage> op) {
    super.add(op);
    return this;
  }

  ImageProcessor build() {
    return ImageProcessor._(this);
  }
}
