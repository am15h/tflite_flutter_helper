import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:tflite_flutter_helper/src/common/support_preconditions.dart';
import 'package:tflite_flutter_helper/src/common/tensor_operator.dart';
import 'package:tflite_flutter_helper/src/tensorbuffer/tensorbuffer.dart';

class CastOp implements TensorOperator {
  TfLiteType _destinationType;

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
