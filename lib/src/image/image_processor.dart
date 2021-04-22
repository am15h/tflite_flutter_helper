import 'dart:math';
import 'dart:ui';

import 'package:tflite_flutter_helper/src/common/operator.dart';
import 'package:tflite_flutter_helper/src/common/sequential_processor.dart';
import 'package:tflite_flutter_helper/src/common/support_preconditions.dart';
import 'package:tflite_flutter_helper/src/common/tensor_operator.dart';
import 'package:tflite_flutter_helper/src/image/ops/tensor_operator_wrapper.dart';
import 'package:tflite_flutter_helper/src/image/tensor_image.dart';

import 'image_operator.dart';
import 'ops/rot90_op.dart';

/// ImageProcessor is a helper class for preprocessing and postprocessing [TensorImage].
///
/// It could transform a [TensorImage] to another by executing a chain of [ImageOperator].
///
/// Example Usage:
///
/// ```dart
///   ImageProcessor processor = ImageProcessorBuilder()
///       .add(ResizeOp(224, 224, ResizeMethod.NEAREST_NEIGHBOR)
///       .add(Rot90Op())
///       .add(NormalizeOp(127.5, 127.5))
///       .build();
///   TensorImage anotherTensorImage = processor.process(tensorImage);
/// ```
///
/// See [ImageProcessorBuilder] to build a [ImageProcessor] instance
///
/// See [SequentialProcessor.process] to apply the processor on a [TensorImage]
class ImageProcessor extends SequentialProcessor<TensorImage> {
  ImageProcessor._(SequentialProcessorBuilder<TensorImage> builder)
      : super(builder);

  /// Transforms a [point] from coordinates system of the result image back to the one of the input
  /// image.
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
      ImageOperator imageOperator = opIterator.current as ImageOperator;
      int height = heightIterator.current;
      int width = widthIterator.current;
      point = imageOperator.inverseTransform(point, height, width);
    }
    return point;
  }

  /// Transforms a [rect] from coordinates system of the result image back to the one of the input
  /// image.
  Rect inverseTransformRect(
      Rect rect, int inputImageHeight, int inputImageWidth) {
    // when rotation is involved, corner order may change - top left changes to bottom right, .etc
    Point p1 = inverseTransform(
        Point(rect.left, rect.top), inputImageHeight, inputImageWidth);
    Point p2 = inverseTransform(
        Point(rect.right, rect.bottom), inputImageHeight, inputImageWidth);
    return Rect.fromLTRB(min(p1.x, p2.x) as double, min(p1.y, p2.y) as double,
        max(p1.x, p2.x) as double, max(p1.y, p2.y) as double);
  }

  void updateNumberOfRotations(int k, int occurrence) {
    SupportPreconditions.checkState(
        operatorIndex.containsKey(Rot90Op().runtimeType.toString()),
        errorMessage: "The Rot90Op has not been added to the ImageProcessor.");

    List<int> indexes = operatorIndex[Rot90Op().runtimeType.toString()]!;
    SupportPreconditions.checkElementIndex(occurrence, indexes.length,
        desc: "occurrence");

    // The index of the Rot90Op to be replaced in operatorList.
    int index = indexes[occurrence];
    Rot90Op newRot = Rot90Op(k);
    operatorList[index] = newRot;
  }
}

/// The Builder to create an [ImageProcessor], which could be executed later.
///
/// See [add] to add a [TensorOperator] or [ImageOperator]
/// See [build] complete the building process and get a built Processor
class ImageProcessorBuilder extends SequentialProcessorBuilder<TensorImage> {
  ImageProcessorBuilder() : super();

  /// Adds an [ImageOperator] or a [TensorOperator] into the Operator chain.
  ///
  /// Throws [UnsupportedError] if [op] is neither an [ImageOperator] nor a
  /// [TensorOperator]
  ImageProcessorBuilder add(Operator op) {
    if (op is ImageOperator) {
      super.add(op);
      return this;
    } else if (op is TensorOperator) {
      return this.add(TensorOperatorWrapper(op));
    } else {
      throw UnsupportedError(
          '${op.runtimeType} is not supported, only ImageOperator and TensorOperator is supported');
    }
  }

  /// Completes the building process and gets the {@link ImageProcessor} instance.
  ImageProcessor build() {
    return ImageProcessor._(this);
  }
}
