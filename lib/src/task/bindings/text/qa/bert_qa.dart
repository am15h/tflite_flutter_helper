import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'types.dart';

import 'package:tflite_flutter_helper/src/task/bindings/dlib.dart';

// ignore_for_file: non_constant_identifier_names, camel_case_types

// Creates BertQuestionAnswerer from model path, returns nullptr if the file
// doesn't exist or is not a well formatted TFLite model path.
Pointer<TfLiteBertQuestionAnswerer> Function(Pointer<Utf8> modelPath)
BertQuestionAnswererFromFile = tflitelib
    .lookup<NativeFunction<_BertQuestionAnswererFromFile_native_t>>(
    'BertQuestionAnswererFromFile')
    .asFunction();

typedef _BertQuestionAnswererFromFile_native_t = Pointer<TfLiteBertQuestionAnswerer> Function(
    Pointer<Utf8> modelPath);

// Invokes the encapsulated TFLite model and answers a question based on
// context.
Pointer<TfLiteQaAnswers> Function(Pointer<TfLiteBertQuestionAnswerer> questionAnswerer,
    Pointer<Utf8> context, Pointer<Utf8> question)
BertQuestionAnswererAnswer = tflitelib
    .lookup<NativeFunction<_BertQuestionAnswererAnswer_native_t>>(
    'BertQuestionAnswererAnswer')
    .asFunction();

typedef _BertQuestionAnswererAnswer_native_t = Pointer<TfLiteQaAnswers> Function(Pointer<TfLiteBertQuestionAnswerer> questionAnswerer,
    Pointer<Utf8> context, Pointer<Utf8> question);

// Deletes BertQuestionAnswerer instance
void Function(Pointer<TfLiteBertQuestionAnswerer>) BertQuestionAnswererDelete = tflitelib
    .lookup<NativeFunction<_BertQuestionAnswererDelete_native_t>>(
    'BertQuestionAnswererDelete')
    .asFunction();

typedef _BertQuestionAnswererDelete_native_t = Void Function(Pointer<TfLiteBertQuestionAnswerer>);

// Deletes BertQuestionAnswererQaAnswers instance
void Function(Pointer<TfLiteQaAnswers>) BertQuestionAnswererQaAnswersDelete = tflitelib
    .lookup<NativeFunction<_BertQuestionAnswererQaAnswersDelete_native_t>>(
    'BertQuestionAnswererQaAnswersDelete')
    .asFunction();

typedef _BertQuestionAnswererQaAnswersDelete_native_t = Void Function(Pointer<TfLiteQaAnswers>);
