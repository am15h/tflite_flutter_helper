import 'dart:math' show Point;
import 'package:image/image.dart' show Image, drawPixel;
import 'dart:math';
import 'package:tflite_flutter_helper/src/image/image_operator.dart';
import 'package:tflite_flutter_helper/src/image/ops/resize_op.dart';
import 'package:tflite_flutter_helper/src/image/tensor_image.dart';
import 'package:tuple/tuple.dart';

/// As a computation unit for processing images, it could resize image to predefined size.
///
/// It will not stretch or compress the content of image. However, to fit the new size, it crops
/// or pads pixels. When it crops image, it performs a center-crop; when it pads pixels, it performs
/// a zero-padding.
///
/// See [ResizeOp] for resizing images while stretching / compressing the content.
class ResizeWithCropOrPadOp implements ImageOperator {
  final int _targetHeight;
  final int _targetWidth;
  final Tuple2<int, int> _cropPosition;
  final Image _output;

  /// Creates a ResizeWithCropOrPadOp which could crop/pad images to height: [_targetHeight] &
  /// width: [_targetWidth]. It adopts center-crop and zero-padding.
  /// You can pass whith [_cropPosition] a tuple2 representing a top-left position (width, height) of a crop to overide the default centered one.
  ResizeWithCropOrPadOp(this._targetHeight, this._targetWidth,
      [this._cropPosition = const Tuple2<int, int>(null, null)])
      : _output = Image(_targetWidth, _targetHeight);

  /// Applies the defined resizing with cropping or/and padding on [image] and returns the
  /// result.
  ///
  /// Note: the content of input [image] will change, and [image] is the same instance
  /// with the output.
  @override
  TensorImage apply(TensorImage image) {
    Image input = image.image;
    int srcL;
    int srcR;
    int srcT;
    int srcB;
    int dstL;
    int dstR;
    int dstT;
    int dstB;
    int w = input.width;
    int h = input.height;
    // TODO: Return an error if the crop position is out of the image

    if (_targetWidth > w) {
      // padding
      srcL = 0;
      srcR = w;
      dstL = (_targetWidth - w) ~/ 2;
      dstR = dstL + w;
    } else {
      // cropping
      dstL = 0;
      dstR = _targetWidth;
      // custom crop position. First item of the tuple represent the desired position for left position
      // and the second item the right position
      Tuple2<int, int> cropPos =
          _computeCropPosition(_targetWidth, w, _cropPosition.item1);
      srcL = cropPos.item1;
      srcR = cropPos.item2;
    }
    if (_targetHeight > h) {
      // padding
      srcT = 0;
      srcB = h;
      dstT = (_targetHeight - h) ~/ 2;
      dstB = dstT + h;
    } else {
      // cropping
      dstT = 0;
      dstB = _targetHeight;
      // custom crop position. First item of the tuple represent the desired position for top position
      // and the second item the bottom position
      Tuple2<int, int> cropPos =
          _computeCropPosition(_targetHeight, w, _cropPosition.item2);
      srcT = cropPos.item1;
      srcB = cropPos.item2;
    }

    Image resized = _drawImage(_output, image.image,
        dstX: dstL,
        dstY: dstT,
        dstH: dstB - dstT,
        dstW: dstR - dstL,
        srcX: srcL,
        srcY: srcT,
        srcH: srcB - srcT,
        srcW: srcR - srcL);

    image.loadImage(resized);

    return image;
  }

  Tuple2<int, int> _computeCropPosition(int targetSize, int imageSize,
      [int cropPosition]) {
    int srcLT;
    int srcRB;

    if (cropPosition != null) {
      srcLT = cropPosition; // custom crop
    } else {
      srcLT = (imageSize - targetSize) ~/ 2; // centered crop
    }
    srcRB = srcLT + targetSize;

    return Tuple2<int, int>(srcLT, srcRB);
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
    return _transformImpl(
        point, _targetHeight, _targetWidth, inputImageHeight, inputImageWidth);
  }

  Point _transformImpl(Point point, int srcH, int srcW, int dstH, int dstW) {
    return Point(point.x + (dstW - srcW) / 2, point.y + (dstH - srcH) / 2);
  }

  Image _drawImage(Image dst, Image src,
      {int dstX,
      int dstY,
      int dstW,
      int dstH,
      int srcX,
      int srcY,
      int srcW,
      int srcH,
      bool blend = false}) {
    dstX ??= 0;
    dstY ??= 0;
    srcX ??= 0;
    srcY ??= 0;
    srcW ??= src.width;
    srcH ??= src.height;
    dstW ??= (dst.width < src.width) ? dstW = dst.width : src.width;
    dstH ??= (dst.height < src.height) ? dst.height : src.height;

    for (var y = 0; y < dstH; ++y) {
      for (var x = 0; x < dstW; ++x) {
        var stepX = (x * (srcW / dstW)).toInt();
        var stepY = (y * (srcH / dstH)).toInt();

        final srcPixel = src.getPixel(srcX + stepX, srcY + stepY);
        if (blend) {
          drawPixel(dst, dstX + x, dstY + y, srcPixel);
        } else {
          dst.setPixel(dstX + x, dstY + y, srcPixel);
        }
      }
    }

    return dst;
  }
}
