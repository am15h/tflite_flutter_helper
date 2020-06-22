import 'package:image/image.dart' show Image, copyResize, Interpolation;
import 'dart:math' show Point;
import 'package:tflite_flutter_helper/src/image/image_operator.dart';
import 'package:tflite_flutter_helper/src/image/tensor_image.dart';

class ResizeOp implements ImageOperator {
  final int _targetHeight;
  final int _targetWidth;
  final bool _useBilinear;

  ResizeOp(this._targetHeight, this._targetWidth, ResizeMethod resizeMethod)
      : this._useBilinear = resizeMethod == ResizeMethod.BILINEAR;

  @override
  TensorImage apply(TensorImage image) {
    Image scaled = copyResize(
      image.image,
      width: _targetWidth,
      height: _targetHeight,
      interpolation:
          _useBilinear ? Interpolation.linear : Interpolation.nearest,
    );
    image.loadImage(scaled);
    return image;
  }

  @override
  int getOutputImageHeight(int inputImageHeight, int inputImageWidth) {
    return _targetHeight;
  }

  @override
  int getOutputImageWidth(int inputImageHeight, int inputImageWidth) {
    return _targetWidth;
  }

  @override
  Point inverseTransform(
      Point point, int inputImageHeight, int inputImageWidth) {
    return Point(point.x * inputImageWidth / _targetWidth,
        point.y * inputImageHeight / _targetHeight);
  }
}

enum ResizeMethod { BILINEAR, NEAREST_NEIGHBOUR }
