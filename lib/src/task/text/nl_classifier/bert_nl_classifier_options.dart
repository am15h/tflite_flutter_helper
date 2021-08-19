import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:quiver/check.dart';
import 'package:tflite_flutter_helper/src/task/bindings/text/nl_classifier/types.dart';

/// Options to configure BertNLClassifier.
class BertNLClassifierOptions {
  final Pointer<TfLiteBertNLClassifierOptions> _options;
  bool _deleted = false;
  Pointer<TfLiteBertNLClassifierOptions> get base => _options;

  BertNLClassifierOptions._(this._options);

  static const int DEFAULT_MAX_SEQ_LEN = 128;

  /// Creates a new options instance.
  factory BertNLClassifierOptions() {
    final optionsPtr = TfLiteBertNLClassifierOptions.allocate(DEFAULT_MAX_SEQ_LEN);
    return BertNLClassifierOptions._(optionsPtr);
  }

  int get maxSeqLen => base.ref.maxSeqLen;

  set maxSeqLen(int value) {
    base.ref.maxSeqLen = value;
  }

  /// Destroys the options instance.
  void delete() {
    checkState(!_deleted, message: 'BertNLClassifierOptions already deleted.');
    calloc.free(_options);
    _deleted = true;
  }
}
