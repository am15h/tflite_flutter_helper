import 'package:tflite_audio_detection/src/common/operator.dart';

/// Processes [T] object with prepared [Operator].
abstract class Processor<T> {
  T process(T input);
}
