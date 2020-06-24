import 'package:imageclassification/classifier.dart';
import 'package:tflite_flutter_helper/src/common/ops/normailze_op.dart';

class ClassifierQuant extends Classifier {
  @override
  String get modelName => 'mobilenet_v1_1.0_224_quant.tflite';

  @override
  NormalizeOp get preProcessNormalizeOp => NormalizeOp(0, 1);

  @override
  NormalizeOp get postProcessNormalizeOp => NormalizeOp(0, 255);
}
