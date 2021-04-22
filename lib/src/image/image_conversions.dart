import 'package:image/image.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:tflite_flutter_helper/src/image/tensor_image.dart';
import 'package:tflite_flutter_helper/src/tensorbuffer/tensorbuffer.dart';

/// Implements some stateless image conversion methods.
///
/// This class is an internal helper.
class ImageConversion {
  static Image convertTensorBufferToImage(TensorBuffer buffer, Image image) {
    if (buffer.getDataType() != TfLiteType.uint8) {
      throw UnsupportedError(
        "Converting TensorBuffer of type ${buffer.getDataType()} to Image is not supported yet.",
      );
    }
    List<int> shape = buffer.getShape();
    TensorImage.checkImageTensorShape(shape);
    int h = shape[shape.length - 3];
    int w = shape[shape.length - 2];
    if (image.width != w || image.height != h) {
      throw ArgumentError(
        "Given image has different width or height ${[
          image.width,
          image.height
        ]} with the expected ones ${[w, h]}.",
      );
    }

    List<int> rgbValues = buffer.getIntList();

    assert(rgbValues.length == w * h * 3);

    for (int i = 0, j = 0, wi = 0, hi = 0; j < rgbValues.length; i++) {
      int r = rgbValues[j++];
      int g = rgbValues[j++];
      int b = rgbValues[j++];
      image.setPixelRgba(wi, hi, r, g, b);
      wi++;
      if (wi % w == 0) {
        wi = 0;
        hi++;
      }
    }

    return image;
  }

  static void convertImageToTensorBuffer(Image image, TensorBuffer buffer) {
    int w = image.width;
    int h = image.height;
    List<int> intValues = image.data;

    List<int> shape = [h, w, 3];
    List<int> rgbValues = List.filled(h * w * 3, 0);
    for (int i = 0, j = 0; i < intValues.length; i++) {
      rgbValues[j++] = ((intValues[i]) & 0xFF);
      rgbValues[j++] = ((intValues[i] >> 8) & 0xFF);
      rgbValues[j++] = ((intValues[i] >> 16) & 0xFF);
    }

    buffer.loadList(rgbValues, shape: shape);
  }
}
