import 'package:tflite_flutter_helper/src/common/support_preconditions.dart';
import 'package:tflite_flutter_helper/src/tensorbuffer/tensorbuffer.dart';

class LabelUtil {
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
