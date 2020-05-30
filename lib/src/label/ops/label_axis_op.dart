import 'package:meta/meta.dart';
import 'package:tflite_flutter_helper/src/common/file_util.dart';
import 'package:tflite_flutter_helper/src/common/support_preconditions.dart';
import 'package:tflite_flutter_helper/src/label/tensor_label.dart';
import 'package:tflite_flutter_helper/src/tensorbuffer/tensorbuffer.dart';

class LabelAxisOp {
  Map<int, List<String>> _axisLabels;

  @protected
  LabelAxisOp(LabelAxisOpBuilder builder) {
    _axisLabels = builder._axisLabels;
  }

  TensorLabel apply(TensorBuffer buffer) {
    SupportPreconditions.checkNotNull(buffer,
        message: "Tensor buffer cannot be null.");
    return TensorLabel(_axisLabels, buffer);
  }
}

class LabelAxisOpBuilder {
  Map<int, List<String>> _axisLabels;

  @protected
  LabelAxisOpBuilder() {
    _axisLabels = {};
  }

  Future<LabelAxisOpBuilder> addAxisLabelFromFile(
      int axis, String fileAssetLocation) async {
    SupportPreconditions.checkNotNull(fileAssetLocation,
        message: "File path cannot be null.");
    List<String> labels = await FileUtil.loadLabels(fileAssetLocation);
    _axisLabels[axis] = labels;
    return this;
  }

  LabelAxisOpBuilder addAxisLabelFromList(int axis, List<String> labels) {
    _axisLabels[axis] = labels;
    return this;
  }

  LabelAxisOp build() {
    return LabelAxisOp(this);
  }
}
