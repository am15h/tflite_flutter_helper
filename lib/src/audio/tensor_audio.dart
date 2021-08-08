import 'dart:math';
import 'dart:typed_data';

import 'package:quiver/check.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:tflite_flutter_helper/tflite_flutter_helper.dart';

class TensorAudio {
  static const String TAG = "TensorAudioDart";
  late final FloatRingBuffer buffer;
  late final TensorAudioFormat format;

  TensorAudio._(this.format, int sampleCount){
    this.buffer = FloatRingBuffer._(sampleCount * format.channelCount);
  }

  static TensorAudio create(TensorAudioFormat format, int sampleCount) {
    return TensorAudio._(format, sampleCount);
  }

  void loadDoubleList(List<double> src) {
    loadDoubleListOffset(src, 0, src.length);
  }

  void loadDoubleListOffset(List<double> src, int offsetInFloat,
      int sizeInFloat) {
    checkArgument(
      sizeInFloat % format.channelCount == 0,
      message:
      "Size ($sizeInFloat) needs to be a multiplier of the number of channels (${format
          .channelCount})",
    );
    buffer.loadOffset(src, offsetInFloat, sizeInFloat);
  }

  void loadShortBytes(Uint8List shortBytes) {
    ByteData byteData = ByteData.sublistView(shortBytes);
    List<int> shortList = [];
    for (int i = 0; i < byteData.lengthInBytes; i += 2) {
      shortList.add(byteData.getInt16(i, Endian.little));
    }
    loadList(shortList);
  }

  void loadFloatBytes(Uint8List floatBytes) {
    ByteData byteData = ByteData.sublistView(floatBytes);
    List<double> doubleList = [];
    for (int i = 0; i < byteData.lengthInBytes; i += 4) {
      doubleList.add(byteData.getFloat32(i, Endian.little));
    }
    loadDoubleList(doubleList);
  }

  void loadList(List<int> src) {
    loadListOffset(src, 0, src.length);
  }

  void loadListOffset(List<int> src, int offsetInShort, int sizeInShort) {
    checkArgument(
        offsetInShort + sizeInShort <= src.length,
        message: "Index out of range. offset ($offsetInShort) + size ($sizeInShort) should <= newData.length (${src
            .length})");
    List<double> floatData = List.filled(sizeInShort, 0.0);
    for (int i = offsetInShort; i < sizeInShort; i++) {
      // Convert the data to PCM Float encoding i.e. values between -1 and 1
      floatData[i] = src[i] / (pow(2, 15) - 1);
    }
    loadDoubleList(floatData);
  }


  /// Returns a float {@link TensorBuffer} holding all the available audio samples in {@link
  /// android.media.AudioFormat#ENCODING_PCM_FLOAT} i.e. values are in the range of [-1, 1].
  TensorBuffer get tensorBuffer {
    ByteBuffer byteBuffer = buffer.buffer;
    TensorBuffer tensorBuffer =
    // TODO: Confirm Shape
    TensorBuffer.createFixedSize(
        [1, byteBuffer
            .asFloat32List()
            .length
        ],
        TfLiteType.float32);
    tensorBuffer.loadBuffer(byteBuffer);
    return tensorBuffer;
  }

  /// Returns the {@link TensorAudioFormat} associated with the tensor.
  // TODO: Rename
  TensorAudioFormat get gformat {
    return format;
  }
}

// TODO: Update documentation according to flutter
/// Wraps a few constants describing the format of the incoming audio samples, namely number of
/// channels and the sample rate. By default, channels is set to 1.
class TensorAudioFormat {
  static const int DEFAULT_CHANNELS = 1;
  late final int _channelCount;
  late final int _sampleRate;

  TensorAudioFormat._(this._channelCount, this._sampleRate);

  static TensorAudioFormat create(int channelCount, int sampleRate) {
    checkArgument(channelCount > 0,
        message: "Number of channels should be greater than 0");
    checkArgument(
        sampleRate > 0, message: "Sample rate should be greater than 0");
    return TensorAudioFormat._(channelCount, sampleRate);
  }

  int get channelCount => _channelCount;

  int get sampleRate => _sampleRate;
}

/// Actual implementation of the ring buffer. */
class FloatRingBuffer {
  late final List<double> _buffer;
  int _nextIndex = 0;

  FloatRingBuffer._(int flatSize) {
    _buffer = List.filled(flatSize, 0.0);
  }

  /// Loads the entire float array to the ring buffer. If the float array is longer than ring
  /// buffer's capacity, samples with lower indicies in the array will be ignored.
  void load(List<double> newData) {
    loadOffset(newData, 0, newData.length);
  }

  /// Loads a slice of the float array to the ring buffer. If the float array is longer than ring
  /// buffer's capacity, samples with lower indicies in the array will be ignored.
  void loadOffset(List<double> newData, int offset, int size) {
    checkArgument(
      offset + size <= newData.length,
      message:
      "Index out of range. offset ($offset) + size ($size) should <= newData.length (${newData
          .length})",
    );
    // If buffer can't hold all the data, only keep the most recent data of size buffer.length
    if (size > _buffer.length) {
      offset = size - _buffer.length;
      size = _buffer.length;
    }
    if (_nextIndex + size < _buffer.length) {
      // No need to wrap nextIndex, just copy newData[offset:offset + size]
      // to buffer[nextIndex:nextIndex+size]
      List.copyRange(_buffer, _nextIndex, newData, offset, offset + size);
    } else {
      // Need to wrap nextIndex, perform copy in two chunks.
      int firstChunkSize = _buffer.length - _nextIndex;
      // First copy newData[offset:offset+firstChunkSize] to buffer[nextIndex:buffer.length]
      List.copyRange(
          _buffer, _nextIndex, newData, offset, offset + firstChunkSize);
      // Then copy newData[offset+firstChunkSize:offset+size] to buffer[0:size-firstChunkSize]
      List.copyRange(
          _buffer, 0, newData, offset + firstChunkSize, offset + size);
    }

    _nextIndex = (_nextIndex + size) % _buffer.length;
  }

  ByteBuffer get buffer {
    // TODO: Make sure there is no endianness issue
    return Float32List
        .fromList(_buffer)
        .buffer;
  }

  int get capacity => _buffer.length;
}
