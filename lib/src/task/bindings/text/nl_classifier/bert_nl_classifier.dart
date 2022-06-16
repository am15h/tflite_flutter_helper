import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'types.dart';

import 'package:tflite_flutter_helper/src/task/bindings/dlib.dart';

// ignore_for_file: non_constant_identifier_names, camel_case_types

// Creates BertBertNLClassifier from model path and options, returns nullptr if the
// file doesn't exist or is not a well formatted TFLite model path.
Pointer<TfLiteBertNLClassifier> Function(Pointer<Utf8> modelPath,
    Pointer<TfLiteBertNLClassifierOptions> options)
BertNLClassifierFromFileAndOptions = tflitelib
    .lookup<NativeFunction<_BertNLClassifierFromFileAndOptions_native_t>>(
    'BertNLClassifierFromFileAndOptions')
    .asFunction();

typedef _BertNLClassifierFromFileAndOptions_native_t = Pointer<TfLiteBertNLClassifier> Function(
    Pointer<Utf8> modelPath,
    Pointer<TfLiteBertNLClassifierOptions> options);

// Creates BertNLClassifier from model path and default options, returns nullptr
// if the file doesn't exist or is not a well formatted TFLite model path.
Pointer<TfLiteBertNLClassifier> Function(Pointer<Utf8> modelPath)
BertNLClassifierFromFile = tflitelib
    .lookup<NativeFunction<_BertNLClassifierFromFile_native_t>>(
    'BertNLClassifierFromFile')
    .asFunction();

typedef _BertNLClassifierFromFile_native_t = Pointer<TfLiteBertNLClassifier> Function(
    Pointer<Utf8> modelPath);

// Invokes the encapsulated TFLite model and classifies the input text.
Pointer<TfLiteCategories> Function(Pointer<TfLiteBertNLClassifier> classifier,
    Pointer<Utf8> text)
BertNLClassifierClassify = tflitelib
    .lookup<NativeFunction<_BertNLClassifierClassify_native_t>>(
    'BertNLClassifierClassify')
    .asFunction();

typedef _BertNLClassifierClassify_native_t = Pointer<TfLiteCategories> Function(Pointer<TfLiteBertNLClassifier> classifier,
    Pointer<Utf8> text);

// Deletes BertNLClassifer instance
void Function(Pointer<TfLiteBertNLClassifier>) BertNLClassifierDelete = tflitelib
    .lookup<NativeFunction<_BertNLClassifierDelete_native_t>>(
    'BertNLClassifierDelete')
    .asFunction();

typedef _BertNLClassifierDelete_native_t = Void Function(Pointer<TfLiteBertNLClassifier>);