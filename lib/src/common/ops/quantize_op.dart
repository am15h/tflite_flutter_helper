import 'package:tflite_flutter_helper/src/common/ops/normailze_op.dart';
import 'package:tflite_flutter_helper/src/common/tensor_operator.dart';

class QuantizeOp extends NormalizeOp implements TensorOperator {
  QuantizeOp(double zeroPoint, double scale) : super(-zeroPoint * scale, scale);
}
