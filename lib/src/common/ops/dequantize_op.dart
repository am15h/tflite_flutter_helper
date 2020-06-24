import 'package:tflite_flutter_helper/src/common/ops/normailze_op.dart';
import 'package:tflite_flutter_helper/src/common/tensor_operator.dart';

/// Dequantizes a [TensorBuffer] with given [zeroPoint] and [scale].
///
///
/// Note: The data type of output tensor is always [FLOAT32] except when the DequantizeOp is
/// created effectively as an identity Op such as setting [zeroPoint] to 0 and [scale] to
/// 1 (in this case, the output tensor is the same instance as input).
///
///
/// If both [zeroPoint] and [scale] are 0, the [DequantizeOp] will be bypassed,
/// which is equivalent to setting [zeroPoint] to 0 and [scale] to 1. This can be useful
/// when passing in the quantization parameters that are extracted directly from the TFLite model
/// flatbuffer. If the tensor is not quantized, both [zeroPoint] and [scale] will be read
/// as 0.
class DequantizeOp extends NormalizeOp implements TensorOperator {
  DequantizeOp(double zeroPoint, double scale) : super(zeroPoint, scale);
}
