import 'package:tflite_flutter_helper/src/common/ops/normailze_op.dart';
import 'package:tflite_flutter_helper/src/common/tensor_operator.dart';

/// Quantizes a [TensorBuffer] with given [zeroPoint] and [scale].
///
///
/// Note: [QuantizeOp] does not cast output to UINT8, but only performs the quantization
/// math on top of input. The data type of output tensor is always [FLOAT32] except that the Op
/// is effectively an identity Op (in this case, the output tensor is the same instance as the
/// input). To connect with quantized model, a [CastOp] is probably needed.
///
///
/// If both [zeroPoint] and [scale] are 0, the [QuantizeOp] will be bypassed,
/// which is equivalent to setting [zeroPoint] to 0 and [scale] to 1. This can be useful
/// when passing in the quantization parameters that are extracted directly from the TFLite model
/// flatbuffer. If the tensor is not quantized, both [zeroPoint] and [scale] will be read
/// as 0.
class QuantizeOp extends NormalizeOp implements TensorOperator {
  // Quantization: f = (q - z) * s, i.e. q = f / s + z = (f - (-z * s)) / s
  QuantizeOp(double zeroPoint, double scale) : super(-zeroPoint * scale, scale);
}
