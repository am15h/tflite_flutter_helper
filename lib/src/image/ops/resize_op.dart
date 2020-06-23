import 'package:image/image.dart' show Image, copyResize, Interpolation;
import 'dart:math' show Point;
import 'package:tflite_flutter_helper/src/image/image_operator.dart';
import 'package:tflite_flutter_helper/src/image/ops/resize_with_crop_or_pad_op.dart';
import 'package:tflite_flutter_helper/src/image/tensor_image.dart';

/// As a computation unit for processing images, it can resize an image to user-specified size.
///
/// It interpolates pixels when image is stretched, and discards pixels when image is compressed.
///
/// See [ResizeWithCropOrPadOp] for resizing without content distortion.
class ResizeOp implements ImageOperator {
  final int _targetHeight;
  final int _targetWidth;
  final bool _useBilinear;

  /// Creates a ResizeOp which can resize images to height: [_targetHeight] &
  /// width: [_targetWidth] using algorithm [resizeMethod].
  ///
  /// Options: [ResizeMethod]
  ResizeOp(this._targetHeight, this._targetWidth, ResizeMethod resizeMethod)
      : this._useBilinear = resizeMethod == ResizeMethod.BILINEAR;

  /// Applies the defined resizing on [image] and returns the result.
  ///
  /// Note: the content of input [image] will change, and [image] is the same instance
  /// with the output.
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

/// Algorithms for resizing.
enum ResizeMethod { BILINEAR, NEAREST_NEIGHBOUR }
