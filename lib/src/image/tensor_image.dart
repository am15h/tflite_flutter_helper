import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:tflite_flutter_helper/src/common/support_preconditions.dart';
import 'package:tflite_flutter_helper/src/image/image_conversions.dart';
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
/// are passed to [_ImageContainer.bufferImage] or [_ImageContainer.tensorBuffer].
///
/// See [ImageProcessor] which is often used for transforming a [TensorImage].
class TensorImage {
  _ImageContainer _container;

  /// Initialize a [TensorImage] object.
  ///
  /// Note: For Image with float value pixels use [TensorImage(TfLiteType.float)]
  TensorImage([TfLiteType dataType = TfLiteType.uint8])
      : _container = _ImageContainer(dataType);

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
    SupportPreconditions.checkNotNull(image,
        message: "Cannot load null image.");
    _container.image = image;
  }

  /// Load a list of RGB pixels into this [TensorImage]
  ///
  /// Throws [ArgumentError] if [pixels] is not List<double> or List<int>,
  /// and [shape] is not in form (height, width ,channels) or
  /// (1, height, width, channels)
  void loadRgbPixels(List pixels, List<int> shape) {
    checkImageTensorShape(shape);
    TensorBuffer buffer = TensorBuffer.createDynamic(dataType);
    buffer.loadList(pixels, shape: shape);
    loadTensorBuffer(buffer);
  }

  /// Loads a [TensorBuffer] containing pixel values. The color layout should be RGB.
  ///
  /// Throws [ArgumentError] if [TensorBuffer.shape] is not in form (height, width ,channels) or
  /// (1, height, width, channels)
  void loadTensorBuffer(TensorBuffer buffer) {
    checkImageTensorShape(buffer.getShape());
    _container.bufferImage = buffer;
  }

  /// Requires tensor shape [h, w, 3] or [1, h, w, 3].
  static void checkImageTensorShape(List<int> shape) {
    SupportPreconditions.checkArgument(
        (shape.length == 3 || (shape.length == 4 && shape[0] == 1)) &&
            shape[shape.length - 3] > 0 &&
            shape[shape.length - 2] > 0 &&
            shape[shape.length - 1] == 3,
        errorMessage:
            "Only supports image shape in (h, w, c) or (1, h, w, c), and channels representing R, G, B" +
                " in order.");
  }

  /// Gets the image width.
  ///
  /// Throws [StateError] if the TensorImage never loads data.
  /// and [ArgumentError] if the container data is corrupted.
  int get width => _container.width;

  /// Gets the image height.
  ///
  /// Throws [StateError] if the TensorImage never loads data.
  /// and [ArgumentError] if the container data is corrupted.
  int get height => _container.height;

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
  TfLiteType get dataType => _container.tfLiteType!;

  /// Gets the current data type.
  ///
  /// Currently only UINT8 and FLOAT32 are possible.
  TfLiteType getDataType() => dataType;

  /// Gets the current data type.
  ///
  /// Currently only UINT8 and FLOAT32 are possible.
  TfLiteType get tfLiteType => _container.tfLiteType!;

  /// Returns the underlying [Image] representation of this [TensorImage].
  ///
  /// Important: It's only a reference. DO NOT MODIFY. We don't create a copy here for performance
  /// concern, but if modification is necessary, please make a copy.
  ///
  /// Throws [StateError] if the TensorImage never loads data.
  Image get image => _container.image;

  /// Returns a [ByteBuffer] representation of this [TensorImage].
  ///
  /// Important: It's only a reference. DO NOT MODIFY. We don't create a copy here for performance
  /// concern, but if modification is necessary, please make a copy.
  ///
  /// It's essentially a short cut for [getTensorBuffer.getBuffer()].
  ///
  /// Throws [StateError] if the TensorImage never loads data.
  ByteBuffer get buffer => _container.tensorBuffer.getBuffer();

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
  TensorBuffer get tensorBuffer => _container.tensorBuffer;

  /// Returns the underlying [TensorBuffer] representation for this [TensorImage]
  ///
  /// Important: It's only a reference. DO NOT MODIFY. We don't create a copy here for performance
  /// concern, but if modification is necessary, please make a copy.
  ///
  /// Throws [ArgumentError] if this TensorImage never loads data.
  TensorBuffer getTensorBuffer() => tensorBuffer;
}

// Handles RGB image data storage strategy of TensorBuffer.
class _ImageContainer {
  TensorBuffer? _bufferImage;
  Image? _image;

  late bool _isBufferUpdated;
  late bool _isImageUpdated;
  final TfLiteType? tfLiteType;

  static final int? argbElementBytes = 4;

  _ImageContainer(this.tfLiteType);

  Image get image {
    if (_isImageUpdated) return _image!;
    if (!_isBufferUpdated)
      throw StateError(
          "Both buffer and bitmap data are obsolete. Forgot to call TensorImage.loadImage?");
    if (_bufferImage!.getDataType() != TfLiteType.uint8) {
      throw StateError(
          "TensorImage is holding a float-value image which is not able to convert a Image.");
    }
    num reqAllocation = _bufferImage!.getFlatSize() * argbElementBytes!;
    if (_image == null || _image!.getBytes().length < reqAllocation) {
      List<int> shape = _bufferImage!.getShape();
      int h = shape[shape.length - 3];
      int w = shape[shape.length - 2];
      _image = Image(w, h);
    }

    _image = ImageConversion.convertTensorBufferToImage(_bufferImage!, _image!);
    _isImageUpdated = true;
    return _image!;
  }

  // Internal method to set the image source-of-truth with a image.
  set image(Image value) {
    _image = value;
    _isBufferUpdated = false;
    _isImageUpdated = true;
  }

  TensorBuffer get tensorBuffer {
    if (_isBufferUpdated) {
      return _bufferImage!;
    }
    SupportPreconditions.checkArgument(
      _isImageUpdated,
      errorMessage:
          "Both buffer and bitmap data are obsolete. Forgot to call TensorImage#load?",
    );
    int requiredFlatSize = image.width * image.height * 3;
    if (_bufferImage == null ||
        (!_bufferImage!.isDynamic &&
            _bufferImage!.getFlatSize() != requiredFlatSize)) {
      _bufferImage = TensorBuffer.createDynamic(tfLiteType!);
    }

    ImageConversion.convertImageToTensorBuffer(_image!, _bufferImage!);
    _isBufferUpdated = true;
    return _bufferImage!;
  }

  // Internal method to set the image source-of-truth with a TensorBuffer.
  set bufferImage(TensorBuffer value) {
    _bufferImage = value;
    _isImageUpdated = false;
    _isBufferUpdated = true;
  }

  int get width {
    SupportPreconditions.checkState(_isBufferUpdated || _isImageUpdated,
        errorMessage:
            "Both buffer and bitmap data are obsolete. Forgot to call TensorImage#load?");
    if (_isImageUpdated) {
      return image.width;
    }
    return _getBufferDimensionSize(-2);
  }

  int get height {
    SupportPreconditions.checkState(_isBufferUpdated || _isImageUpdated,
        errorMessage:
            "Both buffer and bitmap data are obsolete. Forgot to call TensorImage#load?");
    if (_isImageUpdated) {
      return image.height;
    }
    return _getBufferDimensionSize(-3);
  }

  int _getBufferDimensionSize(int dim) {
    List<int> shape = _bufferImage!.getShape();
    // The defensive check is needed because bufferImage might be invalidly changed by user
    // (a.k.a internal data is corrupted)
    TensorImage.checkImageTensorShape(shape);
    dim = dim % shape.length;
    if (dim < 0) {
      dim += shape.length;
    }
    return shape[dim];
  }
}
