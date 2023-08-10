import 'package:tflite_audio_detection/src/common/operator.dart';
import 'package:tflite_audio_detection/src/tensorbuffer/tensorbuffer.dart';

/// Applies some operation on TensorBuffers.
abstract class TensorOperator extends Operator<TensorBuffer> {
  /// See [Operator.apply].
  @override
  TensorBuffer apply(TensorBuffer input);
}
