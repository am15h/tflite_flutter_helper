import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:tflite_flutter_helper/src/common/support_preconditions.dart';
import 'package:tflite_flutter_helper/src/common/tensor_operator.dart';
import 'package:tflite_flutter_helper/src/tensorbuffer/tensorbuffer.dart';

/// Normalizes a [TensorBuffer] with given mean and stddev: output = (input - mean) / stddev.
class NormalizeOp implements TensorOperator {
  late List<double> mean;
  late List<double> stddev;
  late int numChannels;
  late bool isIdentityOp;

  /// Initializes a NormalizeOp. When being called, it creates a new [TensorBuffer], which
  /// satisfies:
  ///
  /// ```
  ///   output = (input - mean) / stddev
  /// ```
  ///
  ///
  /// In the following two cases, reset [mean] to 0 and [stddev] to 1 to bypass the
  /// normalization.
  ///
  /// 1. Both [mean] and [stddev] are 0.
  ///
  /// 2. [mean] is 0 and [stddev] is Infinity.
  ///
  ///
  /// Note: If [mean] is set to 0 and [stddev] is set to 1, no computation will
  /// happen, and original input will be directly returned in execution.
  ///
  /// Note: The returned [TensorBuffer] is always a [TfLiteType.float32] tensor at
  /// present, except that the input is a [TfLiteType.uint8] tensor, [mean] is set to 0 and
  /// [stddev] is set to 1.
  ///
  ///
  /// Throws [ArgumentError] if [stddev] is zero.
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

  /// Initializes a NormalizeOp. When being called, it creates a new [TensorBuffer], which
  /// satisfies:
  ///
  /// ```
  ///   // Pseudo code. [...][i] means a certain element whose channel id is i.
  ///   output[...][i] = (input[...][i] - mean[i]) / stddev[i]
  /// ```
  ///
  ///
  /// Note: If all values in [mean] are set to 0 and all [stddev] are set to 1, no
  /// computation will happen, and original input will be directly returned in execution.
  ///
  /// Note: The returned [TensorBuffer] is always a [TfLiteType.float32] tensor at
  /// present, except that the input is a [TfLiteType.uint8] tensor, all [mean] are set to
  /// 0 and all [stddev] are set to 1.
  ///
  /// List<double> [mean] are the mean values to be subtracted first for each channel.
  ///
  /// List<double> [stddev] the standard deviation values to divide then for each channel.
  ///
  ///
  /// Throws [ArgumentError] if any [stddev] is zero, or [mean] has different
  /// number of elements with [stddev], or any of them is empty.
  NormalizeOp.multipleChannels(List<double> mean, List<double> stddev) {
    SupportPreconditions.checkNotNull(mean, message: "Mean cannot be null");
    SupportPreconditions.checkNotNull(stddev, message: "Stddev cannot be null");
    SupportPreconditions.checkArgument(mean.length == stddev.length,
        errorMessage:
            "Per channel normalization requires same number of means and stddevs");
    SupportPreconditions.checkArgument(mean.length > 0,
        errorMessage: "Means and stddevs are empty.");
    this.mean = mean.toList();
    this.stddev = stddev.toList();

    bool allMeansAreZeroAndAllDevsAre1 = true;
    this.numChannels = mean.length;
    for (int i = 0; i < numChannels; i++) {
      SupportPreconditions.checkArgument(this.stddev[i] != 0,
          errorMessage: "Stddev cannot be zero.");
      if (this.stddev[i] != 1 || this.mean[i] != 0) {
        allMeansAreZeroAndAllDevsAre1 = false;
      }
    }
    this.isIdentityOp = allMeansAreZeroAndAllDevsAre1;
  }

  /// Applies the defined normalization on given [input] tensor and returns the result.
  ///
  /// Note: [input] is possibly the same instance with the output.
  ///
  /// Returns output tensor.
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

    int flatSize = input.getFlatSize();
    List<double> values = List.filled(flatSize, 0);
    int j = 0;
    for (int i = 0; i < flatSize; i++) {
      values[i] = (input.getDoubleValue(i) - mean[j]) / stddev[j];
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
