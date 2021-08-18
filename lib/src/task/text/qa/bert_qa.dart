import 'dart:ffi';

import 'package:quiver/check.dart';
import 'package:tflite_flutter_helper/src/task/bindings/text/qa/bert_qa.dart';
import 'package:tflite_flutter_helper/src/task/bindings/text/qa/types.dart';

import 'package:ffi/ffi.dart';

class BertQuestionAnswerer {
  final Pointer<TfLiteBertQuestionAnswerer> _classifier;
  bool _deleted = false;
  Pointer<TfLiteBertQuestionAnswerer> get base => _classifier;

  BertQuestionAnswerer._(this._classifier);

  factory BertQuestionAnswerer.create(String modelPath) {
    final classiferPtr = BertQuestionAnswererFromFile(modelPath.toNativeUtf8());
    return BertQuestionAnswerer._(classiferPtr);
  }

  List<QaAnswer> answer(String context, String question) {
    final ref = BertQuestionAnswererAnswer(
            base, context.toNativeUtf8(), question.toNativeUtf8())
        .ref;
    final qaList = List.generate(
        ref.size,
        (i) => QaAnswer(
              ref.answers[i].start,
              ref.answers[i].end,
              ref.answers[i].logit,
              ref.answers[i].text.toDartString(),
            ),
    );
    return qaList;
  }

  void delete() {
    checkState(!_deleted, message: 'NLCLassifier already deleted.');
    BertQuestionAnswererDelete(base);
    _deleted = true;
  }
}

class QaAnswer {
  int start;
  int end;
  double logit;
  String text;

  QaAnswer(this.start, this.end, this.logit, this.text);
}
