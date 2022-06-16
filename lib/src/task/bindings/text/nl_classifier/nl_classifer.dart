import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'types.dart';

import 'package:tflite_flutter_helper/src/task/bindings/dlib.dart';

// ignore_for_file: non_constant_identifier_names, camel_case_types

// Creates NLClassifier from model path and options, returns nullptr if the file
// doesn't exist or is not a well formatted TFLite model path.
Pointer<TfLiteNLClassifier> Function(Pointer<Utf8> modelPath,
    Pointer<TfLiteNLClassifierOptions> options)
NLClassifierFromFileAndOptions = tflitelib
    .lookup<NativeFunction<_NLClassifierFromFileAndOptions_native_t>>(
    'NLClassifierFromFileAndOptions')
    .asFunction();

typedef _NLClassifierFromFileAndOptions_native_t = Pointer<TfLiteNLClassifier> Function(
    Pointer<Utf8> modelPath,
    Pointer<TfLiteNLClassifierOptions> options);

// Invokes the encapsulated TFLite model and classifies the input text.
Pointer<TfLiteCategories> Function(Pointer<TfLiteNLClassifier> classifier,
    Pointer<Utf8> text)
NLClassifierClassify = tflitelib
    .lookup<NativeFunction<_NLClassifierClassify_native_t>>(
    'NLClassifierClassify')
    .asFunction();

typedef _NLClassifierClassify_native_t = Pointer<TfLiteCategories> Function(Pointer<TfLiteNLClassifier> classifier,
    Pointer<Utf8> text);

// Deletes NLClassifer instance
void Function(Pointer<TfLiteNLClassifier>) NLClassifierDelete = tflitelib
    .lookup<NativeFunction<_NLClassifierDelete_native_t>>(
    'NLClassifierDelete')
    .asFunction();

typedef _NLClassifierDelete_native_t = Void Function(Pointer<TfLiteNLClassifier>);