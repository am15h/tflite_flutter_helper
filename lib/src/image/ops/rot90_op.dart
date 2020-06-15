import 'package:image/image.dart';
import 'package:image/src/util/point.dart';
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
    // TODO: implement inverseTransform
    return null;
  }
}
