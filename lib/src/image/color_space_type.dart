import 'package:image/image.dart';
import 'package:quiver/check.dart';
import 'package:tflite_flutter_helper/src/image/image_conversions.dart';
import 'package:tflite_flutter_helper/src/tensorbuffer/tensorbuffer.dart';

abstract class ColorSpaceType {
  // The first element of the normalizaed shape.
  static const int BATCH_DIM = 0;
  // The batch axis should always be one.
  static const int BATCH_VALUE = 1;
  // The second element of the normalizaed shape.
  static const int HEIGHT_DIM = 1;
  // The third element of the normalizaed shape.
  static const int WIDTH_DIM = 2;
  // The fourth element of the normalizaed shape.
  static const int CHANNEL_DIM = 3;

  static const ColorSpaceType RGB = const _RGB();
  static const ColorSpaceType GRAYSCALE = const _GRAYSCALE();
  static const ColorSpaceType NV12 = const _NV12();
  static const ColorSpaceType NV21 = const _NV21();
  static const ColorSpaceType YV12 = const _YV12();
  static const ColorSpaceType YV21 = const _YV21();
  static const ColorSpaceType YUV_420_888 = const _YUV_420_888();

  final int value;
  const ColorSpaceType(this.value);

  int getValue() {
    return value;
  }

  /// Verifies if the given shape matches the color space type.
  ///
  /// @throws ArgumentError if {@code shape} does not match the color space type
  /// @throws UnsupportedError if the color space type is not RGB or GRAYSCALE
  void assertShape(List<int> shape) {
    assertRgbOrGrayScale("assertShape()");

    List<int> normalizedShape = getNormalizedShape(shape);
    checkArgument(isValidNormalizedShape(normalizedShape),
        message: getShapeInfoMessage() + "The provided image shape is $shape");
  }

  /// Verifies if the given {@code numElements} in an image buffer matches {@code height} / {@code
  /// width} under this color space type. For example, the {@code numElements} of an RGB image of 30
  /// x 20 should be {@code 30 * 20 * 3 = 1800}; the {@code numElements} of a NV21 image of 30 x 20
  /// should be {@code 30 * 20 + ((30 + 1) / 2 * (20 + 1) / 2) * 2 = 952}.
  ///
  /// @throws ArgumentError if {@code shape} does not match the color space type
  void assertNumElements(int numElements, int height, int width) {
    checkArgument(numElements >= getNumElements(height, width),
        message:
            "The given number of elements $numElements does not match the image ${this.toString()} in $height x $width. The" +
                " expected number of elements should be at least ${getNumElements(height, width)}.");
  }

  /// Converts a {@link TensorBuffer} that represents an image to a Image with the color space type.
  ///
  /// @throws ArgumentError if the shape of buffer does not match the color space type,
  /// @throws UnsupportedError if the color space type is not RGB or GRAYSCALE
  Image convertTensorBufferToImage(TensorBuffer buffer) {
    throw UnsupportedError(
        "convertTensorBufferToImage() is unsupported for the color space type " +
            this.toString());
  }

  /// Returns the width of the given shape corresponding to the color space type.
  ///
  /// @throws ArgumentError if {@code shape} does not match the color space type
  /// @throws UnsupportedError if the color space type is not RGB or GRAYSCALE
  int getWidth(List<int> shape) {
    assertRgbOrGrayScale("getWidth()");
    assertShape(shape);
    return getNormalizedShape(shape)[WIDTH_DIM];
  }

  /// Returns the height of the given shape corresponding to the color space type.
  ///
  /// @throws ArgumentError if {@code shape} does not match the color space type
  /// @throws UnsupportedError if the color space type is not RGB or GRAYSCALE
  int getHeight(List<int> shape) {
    assertRgbOrGrayScale("getHeight()");
    assertShape(shape);
    return getNormalizedShape(shape)[HEIGHT_DIM];
  }

  /// Returns the channel value corresponding to the color space type.
  ///
  /// @throws UnsupportedError if the color space type is not RGB or GRAYSCALE
  int getChannelValue() {
    throw UnsupportedError(
        "getChannelValue() is unsupported for the color space type " +
            this.toString());
  }

  /// Gets the normalized shape in the form of (1, h, w, c). Sometimes, a given shape may not have
  /// batch or channel axis.
  ///
  /// @throws UnsupportedError if the color space type is not RGB or GRAYSCALE
  List<int> getNormalizedShape(List<int> shape) {
    throw UnsupportedError(
        "getNormalizedShape() is unsupported for the color space type " +
            this.toString());
  }

  /// Returns the shape information corresponding to the color space type.
  ///
  /// @throws UnsupportedError if the color space type is not RGB or GRAYSCALE
  String getShapeInfoMessage() {
    throw UnsupportedError(
        "getShapeInfoMessage() is unsupported for the color space type " +
            this.toString());
  }

  /// Gets the number of elements given the height and width of an image. For example, the number of
  /// elements of an RGB image of 30 x 20 is {@code 30 * 20 * 3 = 1800}; the number of elements of a
  /// NV21 image of 30 x 20 is {@code 30 * 20 + ((30 + 1) / 2 * (20 + 1) / 2) * 2 = 952}.
  int getNumElements(int height, int width);

  static int getYuv420NumElements(int height, int width) {
    // Height and width of U/V planes are half of the Y plane.
    return height * width +
        ((height + 1) / 2).floor() * ((width + 1) / 2).floor() * 2;
  }

  /// Inserts a value at the specified position and return the  array. */
  static List<int> insertValue(List<int> array, int pos, int value) {
    List<int> newArray = List.filled(array.length + 1, 0);
    for (int i = 0; i < pos; i++) {
      newArray[i] = array[i];
    }
    newArray[pos] = value;
    for (int i = pos + 1; i < newArray.length; i++) {
      newArray[i] = array[i - 1];
    }
    return newArray;
  }

  bool isValidNormalizedShape(List<int> shape) {
    return shape[BATCH_DIM] == BATCH_VALUE &&
        shape[HEIGHT_DIM] > 0 &&
        shape[WIDTH_DIM] > 0 &&
        shape[CHANNEL_DIM] == getChannelValue();
  }

  /// Some existing methods are only valid for RGB and GRAYSCALE images. */
  void assertRgbOrGrayScale(String unsupportedMethodName) {
    if (this != ColorSpaceType.RGB && this != ColorSpaceType.GRAYSCALE) {
      throw UnsupportedError(unsupportedMethodName +
          " only supports RGB and GRAYSCALE formats, but not " +
          this.toString());
    }
  }
}

class _RGB extends ColorSpaceType {
  const _RGB() : super(0);

  // The channel axis should always be 3 for RGB images.
  static const int CHANNEL_VALUE = 3;

  Image convertTensorBufferToImage(TensorBuffer buffer) {
    return ImageConversions.convertRgbTensorBufferToImage(buffer);
  }

  int getChannelValue() {
    return CHANNEL_VALUE;
  }

  List<int> getNormalizedShape(List<int> shape) {
    switch (shape.length) {
      // The shape is in (h, w, c) format.
      case 3:
        return ColorSpaceType.insertValue(
            shape, ColorSpaceType.BATCH_DIM, ColorSpaceType.BATCH_VALUE);
      case 4:
        return shape;
      default:
        throw ArgumentError(getShapeInfoMessage() +
            "The provided image shape is " +
            shape.toString());
    }
  }

  int getNumElements(int height, int width) {
    return height * width * CHANNEL_VALUE;
  }

  String getShapeInfoMessage() {
    return "The shape of a RGB image should be (h, w, c) or (1, h, w, c), and channels" +
        " representing R, G, B in order. ";
  }
}

/// Each pixel is a single element representing only the amount of light. */
class _GRAYSCALE extends ColorSpaceType {
  // The channel axis should always be 1 for grayscale images.
  static const int CHANNEL_VALUE = 1;

  const _GRAYSCALE() : super(1);

  Image convertTensorBufferToImage(TensorBuffer buffer) {
    return ImageConversions.convertGrayscaleTensorBufferToImage(buffer);
  }

  int getChannelValue() {
    return CHANNEL_VALUE;
  }

  List<int> getNormalizedShape(List<int> shape) {
    switch (shape.length) {
      // The shape is in (h, w) format.
      case 2:
        List<int> shapeWithBatch = ColorSpaceType.insertValue(
            shape, ColorSpaceType.BATCH_DIM, ColorSpaceType.BATCH_VALUE);
        return ColorSpaceType.insertValue(
            shapeWithBatch, ColorSpaceType.CHANNEL_DIM, CHANNEL_VALUE);
      case 4:
        return shape;
      default:
        // (1, h, w) and (h, w, 1) are potential grayscale image shapes. However, since they
        // both have three dimensions, it will require extra info to differentiate between them.
        // Since we haven't encountered real use cases of these two shapes, they are not supported
        // at this moment to avoid confusion. We may want to revisit it in the future.
        throw new ArgumentError(getShapeInfoMessage() +
            "The provided image shape is " +
            shape.toString());
    }
  }

  int getNumElements(int height, int width) {
    return height * width;
  }

  String getShapeInfoMessage() {
    return "The shape of a grayscale image should be (h, w) or (1, h, w, 1). ";
  }
}

/// YUV420sp format, encoded as "YYYYYYYY UVUV". */
class _NV12 extends ColorSpaceType {
  const _NV12() : super(2);

  int getNumElements(int height, int width) {
    return ColorSpaceType.getYuv420NumElements(height, width);
  }
}

/// YUV420sp format, encoded as "YYYYYYYY VUVU", the standard picture format on Android Camera1
/// preview.
class _NV21 extends ColorSpaceType {
  const _NV21() : super(3);

  int getNumElements(int height, int width) {
    return ColorSpaceType.getYuv420NumElements(height, width);
  }
}

/// YUV420p format, encoded as "YYYYYYYY VV UU". */
class _YV12 extends ColorSpaceType {
  const _YV12() : super(4);

  int getNumElements(int height, int width) {
    return ColorSpaceType.getYuv420NumElements(height, width);
  }
}

/// YUV420p format, encoded as "YYYYYYYY UU VV". */
class _YV21 extends ColorSpaceType {
  const _YV21() : super(5);
  int getNumElements(int height, int width) {
    return ColorSpaceType.getYuv420NumElements(height, width);
  }
}

/// YUV420 format corresponding to {@link android.graphics.ImageFormat#YUV_420_888}. The actual
/// encoding format (i.e. NV12 / Nv21 / YV12 / YV21) depends on the implementation of the image.
///
/// <p>Use this format only when you load an {@link android.media.Image}.
class _YUV_420_888 extends ColorSpaceType {
  const _YUV_420_888() : super(6);

  int getNumElements(int height, int width) {
    return ColorSpaceType.getYuv420NumElements(height, width);
  }
}
