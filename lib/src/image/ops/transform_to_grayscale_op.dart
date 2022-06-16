import 'dart:math';
import 'package:image/image.dart' as imageLib;
import 'package:tflite_flutter_helper/src/image/image_operator.dart';
import 'package:tflite_flutter_helper/src/image/tensor_image.dart';

class TransformToGrayscaleOp extends ImageOperator {
  @override
  TensorImage apply(TensorImage image) {
    final transformedImage = imageLib.grayscale(image.image);
    image.loadImage(transformedImage);
    return image;
  }

  @override
  int getOutputImageHeight(int inputImageHeight, int inputImageWidth) {
    return inputImageHeight;
  }

  @override
  int getOutputImageWidth(int inputImageHeight, int inputImageWidth) {
    return inputImageWidth;
  }

  @override
  Point<num> inverseTransform(
      Point<num> point, int inputImageHeight, int inputImageWidth) {
    return point;
  }
}
