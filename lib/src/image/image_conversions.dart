import 'dart:io';

import 'package:image/image.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:tflite_flutter_helper/src/image/tensor_image.dart';
import 'package:tflite_flutter_helper/src/tensorbuffer/tensorbuffer.dart';

class ImageConversion {
  static Image convertTensorBufferToImage(TensorBuffer buffer, Image image) {
    if (buffer.getDataType() != TfLiteType.uint8) {
      throw UnsupportedError(
        "Converting TensorBuffer of type ${buffer.getDataType()} to ARGB_8888 Bitmap is not supported yet.",
      );
    }
    List<int> shape = buffer.getShape();
    TensorImage.checkImageTensorShape(shape);
    int h = shape[shape.length - 3];
    int w = shape[shape.length - 2];
    if (image.width != w || image.height != h) {
      throw ArgumentError(
        "Given bitmap has different width or height ${[
          image.width,
          image.height
        ]} with the expected ones ${[w, h]}.",
      );
    }

    List<int> bytes = List(w * h * 3);
    List<int> rgbValues = buffer.getIntList();

    for (int i = 0, j = 0; i < bytes.length; i += 3) {
      bytes[i] = rgbValues[j++];
      bytes[i + 1] = rgbValues[j++];
      bytes[i + 2] = rgbValues[j++];
    }

    return Image.fromBytes(w, h, bytes);
  }

  static void convertImageToTensorBuffer(Image image, TensorBuffer buffer) {
    int w = image.width;
    int h = image.height;

    final bytesList = image.getBytes(format: Format.rgb);

    List<int> shape = [h, w, 3];
//    List<int> rgbValues = List(h * w * 3);
//    for (int i = 0, j = 0; i < bytesList.length - 3; i += 3) {
//      rgbValues[j++] = bytesList[i];
//      rgbValues[j++] = bytesList[i + 1];
//      rgbValues[j++] = bytesList[i + 2];
//    }

    buffer.loadList(bytesList, shape: shape);
  }
}
