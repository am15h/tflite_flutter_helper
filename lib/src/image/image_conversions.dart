import 'package:image/image.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:tflite_flutter_helper/src/image/tensor_image.dart';
import 'package:tflite_flutter_helper/src/tensorbuffer/tensorbuffer.dart';

class ImageConversion {
  static void convertTensorBufferToImage(TensorBuffer buffer, Image image) {
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

    List<int> intValues = List(w * h);
    //TODO: check if the approach works
    /*List<int> rgbValues = buffer.getIntList();

    for (int i = 0, j = 0; i < intValues.length; i++) {
      int r = rgbValues[j++];
      int g = rgbValues[j++];
      int b = rgbValues[j++];
      intValues[i] = Color.fromRgb(r, g, b);
    }*/
    image = Image.fromBytes(w, h, intValues);
  }

  static void convertImageToTensorBuffer(Image image, TensorBuffer buffer) {
    int w = image.width;
    int h = image.height;

    List<int> intValues = List(w * h);

    //TODO: check if this approach works
    final bytesBuffer = image.getBytes().buffer;
    List<int> shape = [h, w, 3];

    buffer.loadBuffer(bytesBuffer, shape: shape);
  }
}
