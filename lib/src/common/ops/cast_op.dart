import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:tflite_flutter_helper/src/common/support_preconditions.dart';
import 'package:tflite_flutter_helper/src/common/tensor_operator.dart';
import 'package:tflite_flutter_helper/src/tensorbuffer/tensorbuffer.dart';

/// Casts a [TensorBuffer] to a specified data type.
class CastOp implements TensorOperator {
  late TfLiteType _destinationType;

  /// Constructs a CastOp.
  ///
  /// Note: For only converting type for a certain [TensorBuffer] on-the-fly rather than in
  /// a processor, please directly use [TensorBuffer.createFrom(buffer, dataType)].
  ///
  /// When this Op is executed, if the original [TensorBuffer] is already in
  /// [destinationType], the original buffer will be directly returned.
  ///
  /// Throws [ArgumentError] if [destinationType] is neither [TfLiteType.float32]
  /// nor [TfLiteType.uint8].
  CastOp(TfLiteType destinationType) {
    SupportPreconditions.checkArgument(
        destinationType == TfLiteType.uint8 ||
            destinationType == TfLiteType.float32,
        errorMessage: "Destination Type " +
            destinationType.toString() +
            " is not supported");
    _destinationType = destinationType;
  }

  @override
  TensorBuffer apply(TensorBuffer input) {
    if (input.getDataType() == _destinationType) {
      return input;
    }
    return TensorBuffer.createFrom(input, _destinationType);
  }
}
