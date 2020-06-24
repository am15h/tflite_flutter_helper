import 'package:tflite_flutter_helper/src/common/support_preconditions.dart';
import 'package:tflite_flutter_helper/src/tensorbuffer/tensorbuffer.dart';

/// Label operation utils.
class LabelUtil {
  /// Maps an int value tensor to a list of string labels. It takes an list of strings as the
  /// dictionary. Example: if the given tensor is {3, 1, 0}, and given labels is {"background",
  /// "apple", "banana", "cherry", "date"}, the result will be {"date", "banana", "apple"}.
  ///
  /// [tensorBuffer] is a tensor with index values. The values should be non-negative integers,
  /// and each value `x` will be converted to `labels[x + offset]`. If the tensor is
  /// given as a float [TensorBuffer], values will be cast to integers. All values that are
  /// out of bound will map to empty string.
  ///
  /// [labels] is used as a dictionary to look up. The index of the list
  /// element will be used as the key.
  ///
  /// [offset] value when look up int values in the [labels].
  ///
  /// Returns the mapped strings. The length of the list is [TensorBuffer.getFlatSize].
  ///
  /// Throws [ArgumentError.notNull] if [tensorBuffer] or [labels] is null
  static List<String> mapValueToLabels(
      TensorBuffer tensorBuffer, List<String> labels, int offset) {
    SupportPreconditions.checkNotNull(tensorBuffer,
        message: "Given tensor should not be null");
    SupportPreconditions.checkNotNull(labels,
        message: "Given labels should not be null");
    List<int> values = tensorBuffer.getIntList();
    print("values: $values");

    List<String> result = [];
    values.forEach((v) {
      int index = v + offset;
      if (index < 0 || index >= labels.length) {
        result.add("");
      } else {
        result.add(labels.elementAt(index));
      }
    });

    return result;
  }
}
