import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:tflite_flutter_helper/src/common/support_preconditions.dart';
import 'package:tflite_flutter_helper/src/common/tensor_operator.dart';
import 'package:tflite_flutter_helper/src/tensorbuffer/tensorbuffer.dart';
import 'package:tflite_flutter_helper/src/tensorbuffer/tensorbufferfloat.dart';

class NormalizeOp implements TensorOperator {
  List<double> mean;
  List<double> stddev;
  int numChannels;
  bool isIdentityOp;

  NormalizeOp(double mean, double stddev) {
    if (mean == 0.0 && (stddev == 0.0 || stddev.isInfinite)) {
      stddev = 1.0;
    }

    SupportPreconditions.checkArgument(stddev != 0.0,
        errorMessage: "Stddev cannot be zero.");
    bool meansIsZeroAndDevsIs1 = false;
    if (mean == 0.0 && stddev == 1.0) {
      meansIsZeroAndDevsIs1 = true;
    }

    this.isIdentityOp = meansIsZeroAndDevsIs1;
    this.mean = [mean];
    this.stddev = [stddev];
    this.numChannels = 1;
  }

  @override
  TensorBuffer apply(TensorBuffer input) {
    if (isIdentityOp) {
      return input;
    }
    List<int> shape = input.getShape();
    SupportPreconditions.checkArgument(
        numChannels == 1 ||
            (shape.length != 0 && shape[shape.length - 1] == numChannels),
        errorMessage:
            "Number of means (stddevs) is not same with number of channels (size of last axis).");
    // TODO(136750944): Eliminate the array copy here.
    List<double> values = input.getDoubleList();
    int j = 0;
    for (int i = 0; i < values.length; i++) {
      values[i] = (values[i] - mean[j]) / stddev[j];
      j = (j + 1) % numChannels;
    }
    TensorBuffer output;
    if (input.isDynamic) {
      output = TensorBuffer.createDynamic(TfLiteType.float32);
    } else {
      output = TensorBuffer.createFixedSize(shape, TfLiteType.float32);
    }
    output.loadList(values, shape: shape);
    return output;
  }
}
