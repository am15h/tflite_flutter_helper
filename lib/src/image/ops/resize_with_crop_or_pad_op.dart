import 'dart:math' show Point;
import 'package:image/image.dart' show Image, drawPixel;
import 'dart:math';
import 'package:tflite_flutter_helper/src/image/image_operator.dart';
import 'package:tflite_flutter_helper/src/image/tensor_image.dart';

class ResizeWithCropOrPadOp implements ImageOperator {
  final int _targetHeight;
  final int _targetWidth;
  final Image _output;

  ResizeWithCropOrPadOp(this._targetHeight, this._targetWidth)
      : _output = Image(_targetWidth, _targetHeight);

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
      srcL = (w - _targetWidth) ~/ 2;
      srcR = srcL + _targetWidth;
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
      srcT = (h - _targetHeight) ~/ 2;
      srcB = srcT + _targetHeight;
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
