import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart';
import 'package:quiver/check.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:tflite_flutter_helper/src/image/base_image_container.dart';
import 'package:tflite_flutter_helper/src/image/color_space_type.dart';
import 'package:tflite_flutter_helper/src/image/image_container.dart';
import 'package:tflite_flutter_helper/src/image/tensor_buffer_container.dart';
import 'package:tflite_flutter_helper/src/tensorbuffer/tensorbuffer.dart';

/// [TensorImage] is the wrapper class for [Image] object. When using image processing utils in
/// Flutter Helper library, it's common to convert image objects in variant types to TensorImage at
/// first.
///
/// IMPORTANT: [Image] always refers to [Image] from 'package:image/image.dart' and not those from
/// 'dart:ui' or 'package:flutter/widgets.dart.
///
/// At present, only RGB images are supported, and the A channel is always ignored.
///
/// Details of data storage: a [TensorImage] object may have 2 potential sources of truth: a
/// [Image] or a [TensorBuffer]. [TensorImage] maintains the state and only
/// convert one to the other when needed.
///
/// IMPORTANT: The container doesn't own its data. Callers should not modify data objects those
/// are passed to [BaseImageContainer.bufferImage] or [BaseImageContainer.tensorBuffer].
///
/// See [ImageProcessor] which is often used for transforming a [TensorImage].
class TensorImage {
  BaseImageContainer? _container;
  final TfLiteType _tfLiteType;

  /// Initialize a [TensorImage] object.
  ///
  /// Note: For Image with float value pixels use [TensorImage(TfLiteType.float)]
  TensorImage([TfLiteType dataType = TfLiteType.uint8])
      : _tfLiteType = dataType;

  /// Initialize [TensorImage] from [Image]
  ///
  /// Important Note: [Image] is imported from import 'package:image/image.dart'
  static TensorImage fromImage(Image image) {
    TensorImage tensorImage = TensorImage();
    tensorImage.loadImage(image);
    return tensorImage;
  }

  /// Initialize [TensorImage] from [File]
  ///
  /// Load image as a [File] and create [TensorImage].
  static TensorImage fromFile(File imageFile) {
    Image image = decodeImage(imageFile.readAsBytesSync())!;
    TensorImage tensorImage = TensorImage();
    tensorImage.loadImage(image);
    return tensorImage;
  }

  /// Initialize [TensorImage] from [TensorBuffer]
  static TensorImage fromTensorBuffer(TensorBuffer buffer) {
    TensorImage tensorImage = TensorImage();
    tensorImage.loadTensorBuffer(buffer);
    return tensorImage;
  }

  /// Load [Image] to this [TensorImage]
  void loadImage(Image image) {
    _container = ImageContainer.create(image);
  }

  /// Load a list of RGB pixels into this [TensorImage]
  ///
  /// Throws [ArgumentError] if [pixels] is not List<double> or List<int>,
  /// and [shape] is not in form (height, width ,channels) or
  /// (1, height, width, channels)
  void loadRgbPixels(List pixels, List<int> shape) {
    TensorBuffer buffer = TensorBuffer.createDynamic(dataType);
    buffer.loadList(pixels, shape: shape);
    loadTensorBuffer(buffer);
  }

  /// Loads a [TensorBuffer] containing pixel values. The color layout should be RGB.
  ///
  /// Throws [ArgumentError] if [TensorBuffer.shape] is not in form (height, width ,channels) or
  /// (1, height, width, channels)
  void loadTensorBuffer(TensorBuffer buffer) {
    load(buffer, ColorSpaceType.RGB);
  }

  void load(TensorBuffer buffer, ColorSpaceType colorSpaceType) {
    checkArgument(
        colorSpaceType == ColorSpaceType.RGB ||
            colorSpaceType == ColorSpaceType.GRAYSCALE,
        message:
            "Only ColorSpaceType.RGB and ColorSpaceType.GRAYSCALE are supported. Use" +
                " `load(TensorBuffer, ImageProperties)` for other color space types.");
    _container = TensorBufferContainer.create(buffer, colorSpaceType);
  }

  /// Gets the image width.
  ///
  /// Throws [StateError] if the TensorImage never loads data.
  /// and [ArgumentError] if the container data is corrupted.
  int get width {
    if (_container == null) {
      throw new StateError("No image has been loaded yet.");
    }
    return _container!.width;
  }

  /// Gets the image height.
  ///
  /// Throws [StateError] if the TensorImage never loads data.
  /// and [ArgumentError] if the container data is corrupted.
  int get height {
    if (_container == null) {
      throw new StateError("No image has been loaded yet.");
    }
    return _container!.height;
  }

  /// Gets the image height.
  ///
  /// Throws [StateError] if the TensorImage never loads data.
  /// and [ArgumentError] if the container data is corrupted.
  int getHeight() => height;

  /// Gets the image width.
  ///
  /// Throws [StateError] if the TensorImage never loads data.
  /// and [ArgumentError] if the container data is corrupted.
  int getWidth() => width;

  /// Gets the current data type.
  ///
  /// Currently only UINT8 and FLOAT32 are possible.
  TfLiteType get dataType {
    return _tfLiteType;
  }

  /// Gets the current data type.
  ///
  /// Currently only UINT8 and FLOAT32 are possible.
  TfLiteType getDataType() => dataType;

  /// Gets the current data type.
  ///
  /// Currently only UINT8 and FLOAT32 are possible.
  TfLiteType get tfLiteType {
    return _tfLiteType;
  }

  /// Returns the underlying [Image] representation of this [TensorImage].
  ///
  /// Important: It's only a reference. DO NOT MODIFY. We don't create a copy here for performance
  /// concern, but if modification is necessary, please make a copy.
  ///
  /// Throws [StateError] if the TensorImage never loads data.
  Image get image {
    if (_container == null) {
      throw new StateError("No image has been loaded yet.");
    }
    return _container!.image;
  }

  /// Returns a [ByteBuffer] representation of this [TensorImage].
  ///
  /// Important: It's only a reference. DO NOT MODIFY. We don't create a copy here for performance
  /// concern, but if modification is necessary, please make a copy.
  ///
  /// It's essentially a short cut for [getTensorBuffer.getBuffer()].
  ///
  /// Throws [StateError] if the TensorImage never loads data.
  ByteBuffer get buffer {    
    return tensorBuffer.buffer;
  }

  /// Returns a [ByteBuffer] representation of this [TensorImage].
  ///
  /// Important: It's only a reference. DO NOT MODIFY. We don't create a copy here for performance
  /// concern, but if modification is necessary, please make a copy.
  ///
  /// It's essentially a short cut for [getTensorBuffer.getBuffer()].
  ///
  /// Throws [StateError] if the TensorImage never loads data.
  ByteBuffer getBuffer() => buffer;

  /// Returns the underlying [TensorBuffer] representation for this [TensorImage]
  ///
  /// Important: It's only a reference. DO NOT MODIFY. We don't create a copy here for performance
  /// concern, but if modification is necessary, please make a copy.
  ///
  /// Throws [ArgumentError] if this TensorImage never loads data.
  TensorBuffer get tensorBuffer {
    if (_container == null) {
      throw new StateError("No image has been loaded yet.");
    }
    return _container!.getTensorBuffer(_tfLiteType);
  }

  /// Returns the underlying [TensorBuffer] representation for this [TensorImage]
  ///
  /// Important: It's only a reference. DO NOT MODIFY. We don't create a copy here for performance
  /// concern, but if modification is necessary, please make a copy.
  ///
  /// Throws [ArgumentError] if this TensorImage never loads data.
  TensorBuffer getTensorBuffer() => tensorBuffer;
}
