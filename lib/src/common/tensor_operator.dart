import 'package:tflite_flutter_helper/src/common/operator.dart';
import 'package:tflite_flutter_helper/src/common/sequential_processor.dart';
import 'package:tflite_flutter_helper/src/tensorbuffer/tensorbuffer.dart';

abstract class TensorOperator extends Operator<TensorBuffer> {
  @override
  TensorBuffer apply(TensorBuffer input);
}
