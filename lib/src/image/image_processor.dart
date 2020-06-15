import 'package:tflite_flutter_helper/src/common/operator.dart';
import 'package:tflite_flutter_helper/src/common/sequential_processor.dart';
import 'package:tflite_flutter_helper/src/image/tensor_image.dart';

class ImageProcessor extends SequentialProcessor<TensorImage> {
  ImageProcessor._(SequentialProcessorBuilder<TensorImage> builder)
      : super(builder);


}

class ImageProcessorBuilder extends SequentialProcessorBuilder<TensorImage> {
  ImageProcessorBuilder() : super();

  ImageProcessorBuilder add(Operator<TensorImage> op) {
    super.add(op);
    return this;
  }

  ImageProcessor build() {
    return ImageProcessor._(this);
  }
}
