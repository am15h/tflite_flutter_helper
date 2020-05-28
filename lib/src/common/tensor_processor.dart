import 'package:tflite_flutter_helper/src/common/operator.dart';
import 'package:tflite_flutter_helper/src/common/sequential_processor.dart';
import 'package:tflite_flutter_helper/src/tensorbuffer/tensorbuffer.dart';

class TensorProcessor extends SequentialProcessor<TensorBuffer> {
  TensorProcessor._(builder) : super(builder);
}

class TensorProcessorBuilder extends SequentialProcessorBuilder<TensorBuffer> {
  TensorProcessorBuilder() : super();

  @override
  SequentialProcessor<TensorBuffer> build() {
    return TensorProcessor._(this);
  }

  @override
  SequentialProcessorBuilder<TensorBuffer> add(Operator<TensorBuffer> op) {
    super.add(op);
    return this;
  }
}
