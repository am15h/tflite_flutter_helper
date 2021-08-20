import 'dart:ffi';
import 'dart:io';

import 'package:quiver/check.dart';
import 'package:tflite_flutter_helper/src/common/file_util.dart';
import 'package:tflite_flutter_helper/src/task/bindings/text/qa/bert_qa.dart';
import 'package:tflite_flutter_helper/src/task/bindings/text/qa/types.dart';

import 'package:ffi/ffi.dart';
import 'package:tflite_flutter_helper/src/task/text/qa/question_answerer.dart';

import 'qa_answer.dart';

/// Task API for BertQA models. */
class BertQuestionAnswerer implements QuestionAnswerer {
  final Pointer<TfLiteBertQuestionAnswerer> _classifier;
  bool _deleted = false;
  Pointer<TfLiteBertQuestionAnswerer> get base => _classifier;

  BertQuestionAnswerer._(this._classifier);

  /// Generic API to create the QuestionAnswerer for bert models with metadata populated. The API
  /// expects a Bert based TFLite model with metadata containing the following information:
  ///
  /// <ul>
  ///   <li>input_process_units for Wordpiece/Sentencepiece Tokenizer - Wordpiece Tokenizer can be
  ///       used for a <a
  ///       href="https://tfhub.dev/tensorflow/lite-model/mobilebert/1/default/1">MobileBert</a>
  ///       model, Sentencepiece Tokenizer Tokenizer can be used for an <a
  ///       href="https://tfhub.dev/tensorflow/lite-model/albert_lite_base/squadv1/1">Albert</a>
  ///       model.
  ///   <li>3 input tensors with names "ids", "mask" and "segment_ids".
  ///   <li>2 output tensors with names "end_logits" and "start_logits".
  /// </ul>
  ///
  /// Creates [BertQuestionAnswerer] from [modelPath].
  ///
  /// [modelPath] is the path of the .tflite model loaded on device.
  ///
  /// throws [FileSystemException] If model file fails to load.
  static BertQuestionAnswerer create(String modelPath) {
    final nativePtr = BertQuestionAnswererFromFile(modelPath.toNativeUtf8());
    if (nativePtr == nullptr) {
      throw FileSystemException(
          "Failed to create BertQuestionAnswerer.", modelPath);
    }
    return BertQuestionAnswerer._(nativePtr);
  }

  /// Generic API to create the QuestionAnswerer for bert models with metadata populated. The API
  /// expects a Bert based TFLite model with metadata containing the following information:
  ///
  /// <ul>
  ///   <li>input_process_units for Wordpiece/Sentencepiece Tokenizer - Wordpiece Tokenizer can be
  ///       used for a <a
  ///       href="https://tfhub.dev/tensorflow/lite-model/mobilebert/1/default/1">MobileBert</a>
  ///       model, Sentencepiece Tokenizer Tokenizer can be used for an <a
  ///       href="https://tfhub.dev/tensorflow/lite-model/albert_lite_base/squadv1/1">Albert</a>
  ///       model.
  ///   <li>3 input tensors with names "ids", "mask" and "segment_ids".
  ///   <li>2 output tensors with names "end_logits" and "start_logits".
  /// </ul>
  ///
  /// Create [BertQuestionAnswerer] from [modelFile].
  ///
  /// throws [FileSystemException] If model file fails to load.
  static BertQuestionAnswerer createFromFile(File modelFile) {
    return create(modelFile.path);
  }

  /// Create [BertQuestionAnswerer] directly from [assetPath].
  ///
  /// [assetPath] must the full path to assets. Eg. 'assets/my_model.tflite'.
  ///
  /// throws [FileSystemException] If model file fails to load.
  static Future<BertQuestionAnswerer> createFromAsset(String assetPath) async {
    final modelFile = await FileUtil.loadFileOnDevice(assetPath);
    return create(modelFile.path);
  }

  @override
  List<QaAnswer> answer(String context, String question) {
    final ref = BertQuestionAnswererAnswer(
            base, context.toNativeUtf8(), question.toNativeUtf8())
        .ref;
    final qaList = List.generate(
      ref.size,
      (i) => QaAnswer(
        Pos(ref.answers[i].start, ref.answers[i].end, ref.answers[i].logit),
        ref.answers[i].text.toDartString(),
      ),
    );
    return qaList;
  }

  /// Deletes BertQuestionAnswerer native instance.
  void delete() {
    checkState(!_deleted, message: 'NLCLassifier already deleted.');
    BertQuestionAnswererDelete(base);
    _deleted = true;
  }
}
