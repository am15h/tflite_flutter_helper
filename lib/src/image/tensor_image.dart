import 'dart:typed_data';

import 'package:image/image.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:tflite_flutter_helper/src/common/support_preconditions.dart';
import 'package:tflite_flutter_helper/src/image/image_conversions.dart';
import 'package:tflite_flutter_helper/src/tensorbuffer/tensorbuffer.dart';

class TensorImage {
  _ImageContainer _container;

  TensorImage([TfLiteType dataType = TfLiteType.uint8])
      : _container = _ImageContainer(dataType);

  static TensorImage fromImage(Image image) {
    TensorImage tensorImage = TensorImage();
    tensorImage.loadImage(image);
    return tensorImage;
  }

  void loadImage(Image image) {
    SupportPreconditions.checkNotNull(image,
        message: "Cannot load null image.");
    _container.image = image;
  }

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

  int get width => _container.width;
  int get height => _container.height;
  TfLiteType get dataType => _container.tfLiteType;

  Image get image => _container.image;
  ByteBuffer get buffer => _container.tensorBuffer.getBuffer();

  TensorBuffer get tensorBuffer => _container.tensorBuffer;

  TfLiteType get tfLiteType => _container.tfLiteType;
}

class _ImageContainer {
  TensorBuffer _bufferImage;
  bool _isBufferUpdated;
  Image _image;

  bool _isImageUpdated;
  final TfLiteType tfLiteType;

  static final int argbElementBytes = 4;

  _ImageContainer(this.tfLiteType);

  Image get image {
    if (_isImageUpdated) return _image;
    if (!_isBufferUpdated)
      throw StateError(
          "Both buffer and bitmap data are obsolete. Forgot to call TensorImage#load?");
    if (_bufferImage.getDataType() != TfLiteType.uint8) {
      throw StateError(
          "TensorImage is holding a float-value image which is not able to convert a Bitmap.");
    }
    int reqAllocation = _bufferImage.getFlatSize() * argbElementBytes;
    if (_image == null || _image.getBytes().length < reqAllocation) {
      List<int> shape = _bufferImage.getShape();
      int h = shape[shape.length - 3];
      int w = shape[shape.length - 2];
      _image = Image(w, h);
    }
    ImageConversion.convertTensorBufferToImage(tensorBuffer, image);
    _isImageUpdated = true;
    return _image;
  }

  set image(Image value) {
    _image = value;
    _isBufferUpdated = false;
    _isImageUpdated = true;
  }

  TensorBuffer get tensorBuffer {
    if (_isBufferUpdated) {
      return _bufferImage;
    }
    SupportPreconditions.checkArgument(
      _isImageUpdated,
      errorMessage:
          "Both buffer and bitmap data are obsolete. Forgot to call TensorImage#load?",
    );
    int requiredFlatSize = image.width * image.height * 3;
    if (_bufferImage == null ||
        (!_bufferImage.isDynamic &&
            _bufferImage.getFlatSize() != requiredFlatSize)) {
      _bufferImage = TensorBuffer.createDynamic(tfLiteType);
    }

    ImageConversion.convertImageToTensorBuffer(_image, _bufferImage);
    _isBufferUpdated = true;
    return _bufferImage;
  }

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
    List<int> shape = _bufferImage.getShape();
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
