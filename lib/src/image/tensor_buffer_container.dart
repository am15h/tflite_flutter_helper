import 'package:camera/camera.dart';
import 'package:image/image.dart';
import 'package:quiver/check.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:tflite_flutter_helper/src/image/color_space_type.dart';
import 'package:tflite_flutter_helper/src/image/base_image_container.dart';
import 'package:tflite_flutter_helper/src/tensorbuffer/tensorbuffer.dart';

class TensorBufferContainer implements BaseImageContainer {
  late final TensorBuffer _buffer;
  late final ColorSpaceType _colorSpaceType;
  late final int _height;
  late final int _width;

  /// Creates a {@link TensorBufferContainer} object with the specified {@link
  /// TensorImage#ColorSpaceType}.
  ///
  /// <p>Only supports {@link ColorSapceType#RGB} and {@link ColorSpaceType#GRAYSCALE}. Use {@link
  /// #create(TensorBuffer, ImageProperties)} for other color space types.
  ///
  /// @throws IllegalArgumentException if the shape of the {@link TensorBuffer} does not match the
  ///     specified color space type, or if the color space type is not supported
  static TensorBufferContainer create(TensorBuffer buffer, ColorSpaceType colorSpaceType) {
    checkArgument(
        colorSpaceType == ColorSpaceType.RGB || colorSpaceType == ColorSpaceType.GRAYSCALE,
        message: "Only ColorSpaceType.RGB and ColorSpaceType.GRAYSCALE are supported. Use"
            + " `create(TensorBuffer, ImageProperties)` for other color space types.");

    return TensorBufferContainer._(
        buffer,
        colorSpaceType,
        colorSpaceType.getHeight(buffer.getShape()),
        colorSpaceType.getWidth(buffer.getShape()));
  }

  TensorBufferContainer._(
      TensorBuffer buffer, ColorSpaceType colorSpaceType, int height, int width) {
    checkArgument(
        colorSpaceType != ColorSpaceType.YUV_420_888,
        message: "The actual encoding format of YUV420 is required. Choose a ColorSpaceType from: NV12,"
            + " NV21, YV12, YV21. Use YUV_420_888 only when loading an android.media.Image.");

    colorSpaceType.assertNumElements(buffer.getFlatSize(), height, width);
    this._buffer = buffer;
    this._colorSpaceType = colorSpaceType;
    this._height = height;
    this._width = width;
  }

  @override
  TensorBufferContainer clone() {
    return TensorBufferContainer._(
        TensorBuffer.createFrom(_buffer, _buffer.getDataType()),
        colorSpaceType,
        height,
        width);
  }

  @override
  Image get image {
    if (_buffer.getDataType() != TfLiteType.uint8) {
      // Print warning instead of throwing an exception. When using float models, users may want to
      // convert the resulting float image into Bitmap. That's fine to do so, as long as they are
      // aware of the potential accuracy lost when casting to uint8.
      // Log.w(
      //     TAG,
      //     "<Warning> TensorBufferContainer is holding a non-uint8 image. The conversion to Bitmap"
      //         + " will cause numeric casting and clamping on the data value.");
    }

    return colorSpaceType.convertTensorBufferToImage(_buffer);
  }

  @override
  TensorBuffer getTensorBuffer(TfLiteType dataType) {
    // If the data type of buffer is desired, return it directly. Not making a defensive copy for
    // performance considerations. During image processing, users may need to set and get the
    // TensorBuffer many times.
    // Otherwise, create another one with the expected data type.
    return _buffer.getDataType() == dataType ? _buffer : TensorBuffer.createFrom(_buffer, dataType);
  }

  @override
  CameraImage get mediaImage {
    throw UnsupportedError(
        "Converting from TensorBuffer to android.media.Image is unsupported.");
  }

  @override
  int get width {
    // In case the underlying buffer in Tensorbuffer gets updated after TensorImage is created.
    _colorSpaceType.assertNumElements(_buffer.getFlatSize(), _height, _width);
    return _width;
  }

  @override
  int get height {
    // In case the underlying buffer in Tensorbuffer gets updated after TensorImage is created.
    _colorSpaceType.assertNumElements(_buffer.getFlatSize(), _height, _width);
    return _height;
  }

  @override
  ColorSpaceType get colorSpaceType {
    return _colorSpaceType;
  }

}
