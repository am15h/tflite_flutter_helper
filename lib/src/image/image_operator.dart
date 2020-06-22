import 'dart:math';

import 'package:tflite_flutter_helper/src/common/operator.dart';
import 'package:tflite_flutter_helper/src/image/tensor_image.dart';

abstract class ImageOperator extends Operator<TensorImage> {
  TensorImage apply(TensorImage image);
  int getOutputImageWidth(int inputImageHeight, int inputImageWidth);
  int getOutputImageHeight(int inputImageHeight, int inputImageWidth);
  Point inverseTransform(
      Point point, int inputImageHeight, int inputImageWidth);
}
