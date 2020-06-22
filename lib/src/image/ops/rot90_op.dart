import 'dart:math' show Point;
import 'package:image/image.dart' show Image, copyRotate;
import 'package:tflite_flutter_helper/src/image/image_operator.dart';
import 'package:tflite_flutter_helper/src/image/tensor_image.dart';

class Rot90Op extends ImageOperator {
  int _numRotation;

  Rot90Op([int k = 1]) : _numRotation = (k % 4);

  @override
  TensorImage apply(TensorImage image) {
    Image rotated = copyRotate(image.image, 90 * _numRotation);
    image.loadImage(rotated);
    return image;
  }

  @override
  int getOutputImageHeight(int inputImageHeight, int inputImageWidth) {
    return (_numRotation % 2 == 0) ? inputImageHeight : inputImageWidth;
  }

  @override
  int getOutputImageWidth(int inputImageHeight, int inputImageWidth) {
    return (_numRotation % 2 == 0) ? inputImageWidth : inputImageHeight;
  }

  @override
  Point inverseTransform(
      Point point, int inputImageHeight, int inputImageWidth) {
    int inverseNumRotation = (4 - _numRotation) % 4;
    int height = getOutputImageHeight(inputImageHeight, inputImageWidth);
    int width = getOutputImageWidth(inputImageHeight, inputImageWidth);
    return transformImpl(point, height, width, inverseNumRotation);
  }

  Point transformImpl(Point point, int height, int width, int numRotation) {
    if (numRotation == 0) {
      return point;
    } else if (numRotation == 1) {
      return Point(point.y, width - point.x);
    } else if (numRotation == 2) {
      return Point(width - point.x, height - point.y);
    } else {
      // numRotation == 3
      return Point(height - point.y, point.x);
    }
  }
}
