import 'package:tflite_flutter_helper/src/common/ops/normailze_op.dart';
import 'package:tflite_flutter_helper/src/common/tensor_operator.dart';

class DequantizeOp extends NormalizeOp implements TensorOperator {
  DequantizeOp(double zeroPoint, double scale) : super(zeroPoint, scale);
}
