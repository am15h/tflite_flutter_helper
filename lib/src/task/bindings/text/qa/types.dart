import 'dart:ffi';

import 'package:ffi/ffi.dart';

class TfLiteBertQuestionAnswerer extends Opaque {}

class QaAnswer extends Struct {
  @Int32()
  external int start;
  @Int32()
  external int end;
  @Double()
  external double logit;

  external Pointer<Utf8> text;
}

class QaAnswers extends Struct {
  @Int32()
  external int size;

  Pointer<QaAnswer> answers;
}