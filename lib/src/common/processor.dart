import 'package:tflite_flutter_helper/src/common/operator.dart';

/// Processes [T] object with prepared [Operator].
abstract class Processor<T> {
  T process(T input);
}
