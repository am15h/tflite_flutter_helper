import 'package:tflite_flutter_helper/src/common/operator.dart';
import 'package:tflite_flutter_helper/src/common/sequential_processor.dart';
import 'package:tflite_flutter_helper/src/tensorbuffer/tensorbuffer.dart';

/// TensorProcessor is a helper class for preprocessing and postprocessing tensors. It could
/// transform a [TensorBuffer] to another by executing a chain of [TensorOperator].
///
///
/// Example Usage:
///
/// ```dart
///   TensorProcessor processor = TensorProcessorBuilder().add(NormalizeOp(1.0, 2.0)).build();
///   TensorBuffer anotherTensorBuffer = processor.process(tensorBuffer);
/// ```
///
///
/// See [TensorProcessorBuilder] to build a [TensorProcessor] instance.
/// See [SequentialProcessor.process] to apply the processor on a [TensorBuffer].
class TensorProcessor extends SequentialProcessor<TensorBuffer> {
  TensorProcessor._(builder) : super(builder);
}

/// The Builder to create an [TensorProcessor], which could be executed later.
class TensorProcessorBuilder extends SequentialProcessorBuilder<TensorBuffer> {
  /// Creates a Builder to build [TensorProcessor].
  ///
  /// See [add] to add an Op.
  /// See [build] to complete the building process and get a built Processor.
  TensorProcessorBuilder() : super();

  /// Adds an [TensorOperator] [op] into the Operator chain.
  @override
  SequentialProcessorBuilder<TensorBuffer> add(Operator<TensorBuffer> op) {
    super.add(op);
    return this;
  }

  /// Completes the building process and gets the [TensorProcessor] instance.
  @override
  SequentialProcessor<TensorBuffer> build() {
    return TensorProcessor._(this);
  }
}
