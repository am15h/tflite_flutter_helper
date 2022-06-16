import 'package:camera/camera.dart';
import 'package:image/image.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:tflite_flutter_helper/src/image/color_space_type.dart';
import 'package:tflite_flutter_helper/src/tensorbuffer/tensorbuffer.dart';

abstract class BaseImageContainer {

  /// Performs deep copy of the {@link ImageContainer}. */
  BaseImageContainer clone();

  /// Returns the width of the image. */
  int get width;

  /// Returns the height of the image. */
  int get height;

  /// Gets the {@link Image} representation of the underlying image format. */
  Image get image;

  /// Gets the {@link TensorBuffer} representation with the specific {@code dataType} of the
  /// underlying image format.
  TensorBuffer getTensorBuffer(TfLiteType dataType);

  /// Gets the {@link Image} representation of the underlying image format. */
  CameraImage get mediaImage;

  /// Returns the color space type of the image. */
  ColorSpaceType get colorSpaceType;
}
