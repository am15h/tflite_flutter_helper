import 'dart:math' as m;
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:tflite_flutter_helper/src/common/file_util.dart';
import 'package:tflite_flutter_helper/src/common/ops/normailze_op.dart';
import 'package:tflite_flutter_helper/src/common/tensor_processor.dart';
import 'package:tflite_flutter_helper/src/image/image_processor.dart';
import 'package:tflite_flutter_helper/src/image/ops/resize_op.dart';
import 'package:tflite_flutter_helper/src/image/ops/resize_with_crop_or_pad_op.dart';
import 'package:tflite_flutter_helper/src/image/ops/rot90_op.dart';
import 'package:tflite_flutter_helper/src/image/tensor_image.dart';
import 'package:tflite_flutter_helper/src/tensorbuffer/tensorbuffer.dart';
import 'package:tflite_flutter_helper/src/tensorbuffer/tensorbufferfloat.dart';
import 'package:tflite_flutter_helper/src/tensorbuffer/tensorbufferuint8.dart';

const int h = 100;
const int w = 150;
const String imageFileName = 'test_assets/lion.jpg';
// flutter test test
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('tensorbuffer', () {
    group('uint8', () {
      test('static', () {
        late TensorBuffer tensorBuffer = TensorBufferUint8([1, 3, 2]);
        ByteBuffer buffer = Uint8List.fromList([1, 2, 3, 4, 5, 6]).buffer;
        tensorBuffer.loadBuffer(buffer);
        expect(tensorBuffer.getIntList(), [1, 2, 3, 4, 5, 6]);
        expect(tensorBuffer.getDoubleList(), <double>[1, 2, 3, 4, 5, 6]);
      });

      test('static', () {
        late TensorBuffer tensorBuffer =
            TensorBuffer.createFixedSize([1, 3, 2], TfLiteType.uint8);
        ByteBuffer buffer = Uint8List.fromList([1, 2, 3, 4, 5, 6]).buffer;
        tensorBuffer.loadBuffer(buffer);
        expect(tensorBuffer.getIntList(), [1, 2, 3, 4, 5, 6]);
        expect(tensorBuffer.getDoubleList(), <double>[1, 2, 3, 4, 5, 6]);
      });

      test('dynamic', () {
        late TensorBuffer tensorBuffer = TensorBufferUint8.dynamic();
        ByteBuffer buffer = Uint8List.fromList([1, 2, 3, 4, 5, 6]).buffer;
        tensorBuffer.loadBuffer(buffer, shape: [1, 3, 2]);
        expect(tensorBuffer.getIntList(), [1, 2, 3, 4, 5, 6]);
        expect(tensorBuffer.getDoubleList(), <double>[1, 2, 3, 4, 5, 6]);
      });

      test('load list int', () {
        late TensorBuffer tensorBuffer = TensorBufferUint8.dynamic();
        List<int> list = [1, 2, 3, 4, 5, 655];
        tensorBuffer.loadList(list, shape: [1, 3, 2]);
        expect(tensorBuffer.getIntList(), [1, 2, 3, 4, 5, 255]);
      });

      test('load list float', () {
        late TensorBuffer tensorBuffer = TensorBufferUint8.dynamic();
        List<double> list = [1, 2, 883, -4, 5, 255.0];
        tensorBuffer.loadList(list, shape: [1, 3, 2]);
        expect(tensorBuffer.getIntList(), [1, 2, 255, 0, 5, 255]);
      });
    });

    group('float', () {
      test('static', () {
        late TensorBuffer tensorBuffer = TensorBufferFloat([1, 2, 2]);
        var bdata = ByteData(16);

        for (int i = 0, j = 1; i < 16; i += 4, j++)
          bdata.setFloat32(i, j.toDouble(), Endian.little);

        tensorBuffer.loadBuffer(bdata.buffer);
        expect(tensorBuffer.getDoubleList(), <double>[1, 2, 3, 4]);

        expect(tensorBuffer.getIntList(), [1, 2, 3, 4]);
      });

      test('static', () {
        late TensorBuffer tensorBuffer =
            TensorBuffer.createFixedSize([1, 2, 2], TfLiteType.float32);
        var bdata = ByteData(16);

        for (int i = 0, j = 1; i < 16; i += 4, j++)
          bdata.setFloat32(i, j.toDouble(), Endian.little);

        tensorBuffer.loadBuffer(bdata.buffer);
        expect(tensorBuffer.getDoubleList(), <double>[1, 2, 3, 4]);

        expect(tensorBuffer.getIntList(), [1, 2, 3, 4]);
      });

      test('load list int', () {
        late TensorBuffer tensorBuffer =
            TensorBuffer.createFixedSize([1, 2, 2], TfLiteType.float32);

        tensorBuffer.loadList(<int>[1, 2, 3, 4], shape: [1, 2, 2]);
        expect(tensorBuffer.getDoubleList(), <double>[1, 2, 3, 4]);
        expect(tensorBuffer.getIntList(), [1, 2, 3, 4]);
      });

      test('load list float', () {
        late TensorBuffer tensorBuffer =
            TensorBuffer.createFixedSize([1, 2, 2], TfLiteType.float32);

        tensorBuffer.loadList(<double>[1.0, 2.0, 3.0, 4.0], shape: [1, 2, 2]);
        expect(tensorBuffer.getDoubleList(), <double>[1.0, 2.0, 3.0, 4.0]);
        expect(tensorBuffer.getIntList(), [1, 2, 3, 4]);
      });
    });
  });

  group('common', () {
    test('file_util labels from file', () async {
      File file = File('test_assets/labels.txt');
      List<String> labels = FileUtil.loadLabelsFromFile(file);
      expect(labels[0], 'background');
    });

    group('ops', () {
      test('normalize', () {
        late TensorBuffer tensorBuffer =
            TensorBuffer.createFixedSize([3], TfLiteType.float32);
        tensorBuffer.loadList(<double>[0, 255, 127.5], shape: [3]);

        final processor =
            TensorProcessorBuilder().add(NormalizeOp(127.5, 127.5)).build();

        tensorBuffer = processor.process(tensorBuffer);

        expect(tensorBuffer.getDoubleList(), [-1, 1, 0]);
      });
    });
  });

  group('image', () {
    File imageFile = File(imageFileName);
    Image image = decodeImage(imageFile.readAsBytesSync())!;
    final inputHeight = image.height;
    final inputWidth = image.width;

    group('TensorImage', () {
      late TensorImage tensorImage;
      late TensorBuffer tensorbuffer;

      test('fromFile', () {
        tensorImage = TensorImage.fromFile(imageFile);
        expect(tensorImage, isNotNull);
      });

      test('fromImage', () {
        tensorImage = TensorImage.fromImage(image);
        expect(tensorImage, isNotNull);
      });

      test('load pixels', () {
        late TensorImage tensorImage = TensorImage();

        tensorImage.loadRgbPixels(
            image.getBytes(format: Format.rgb), [inputHeight, inputWidth, 3]);

        expect(tensorImage.image.height, inputHeight);
        expect(tensorImage.image.width, inputWidth);
      });

      test('width height', () {
        expect(tensorImage.width, inputWidth);
        expect(tensorImage.height, inputHeight);
      });

      test('get Image', () {
        var image = tensorImage.image;
        expect(image.width, inputWidth);
      });

      test('get tensorbuffer', () {
        tensorbuffer = tensorImage.tensorBuffer;
        expect(tensorbuffer, isNotNull);
        expect(tensorbuffer.getFlatSize(),
            image.getBytes(format: Format.rgb).length);
        expect(tensorbuffer.getIntList().length,
            image.getBytes(format: Format.rgb).length);
      });

      test('fromTensorBuffer', () {
        var tensorImage = TensorImage.fromTensorBuffer(tensorbuffer);

        expect(tensorImage.width, inputWidth);
        expect(tensorImage.height, inputHeight);
      });
    });

    group('ImageProcessor', () {
      test('resize', () {
        ImageProcessor imageProcessor = ImageProcessorBuilder()
            .add(ResizeOp(h, w, ResizeMethod.BILINEAR))
            .build();

        TensorImage processedImage =
            imageProcessor.process(TensorImage.fromImage(image));

        expect(processedImage.height, h);
        expect(processedImage.width, w);
      });

      test('rot90', () {
        ImageProcessor imageProcessor = ImageProcessorBuilder()
            .add(ResizeOp(h, w, ResizeMethod.NEAREST_NEIGHBOUR))
            .add(Rot90Op())
            .build();

        TensorImage processedImage =
            imageProcessor.process(TensorImage.fromImage(image));

        expect(processedImage.height, w);
        expect(processedImage.width, h);
      });
      test('resize with crop', () {
        ImageProcessor imageProcessor =
            ImageProcessorBuilder().add(ResizeWithCropOrPadOp(h, w)).build();

        TensorImage processedImage =
            imageProcessor.process(TensorImage.fromImage(image));

        expect(processedImage.height, h);
        expect(processedImage.width, w);
      });

      test('resize with custom crop position', () {
        ImageProcessor imageProcessor = ImageProcessorBuilder()
            .add(ResizeWithCropOrPadOp(h, w, 0, 0))
            .build();

        TensorImage processedImage =
            imageProcessor.process(TensorImage.fromImage(image));

        expect(processedImage.height, h);
        expect(processedImage.width, w);
        // check that the crop position is taken in account
        // ie:(checking pixel value of the original image vs pixel in crop)
        for (var i = 0; i < w; i++) {
          for (var j = 0; j < h; j++) {
            expect(image.getPixel(i, j), processedImage.image.getPixel(i, j));
          }
        }
      });

      test('resize with custom crop position outside image', () {
        ImageProcessor imageProcessor = ImageProcessorBuilder()
            // the be sure we are outside we took the input size of the image and add 1 pixel
            .add(ResizeWithCropOrPadOp(h, w, inputWidth + 1, inputHeight + 1))
            .build();

        TensorImage sourceImage = TensorImage.fromImage(image);
        expect(() => imageProcessor.process(sourceImage),
            throwsA(isA<ArgumentError>()));
      });

      test('resize with custom crop and one null argument', () {
        ImageProcessor imageProcessor = ImageProcessorBuilder()
            // the be sure we are outside we took the input size of the image and add 1 pixel
            .add(ResizeWithCropOrPadOp(h, w, 0, null))
            .build();

        TensorImage sourceImage = TensorImage.fromImage(image);
        expect(() => imageProcessor.process(sourceImage),
            throwsA(isA<ArgumentError>()));
      });

      test(
          'resize with custom a crop position that make a part of it outside the image',
          () {
        ImageProcessor imageProcessor = ImageProcessorBuilder()
            // the be sure that a part of the crop is outside the iamge we took the input size and substract crop size / 2
            .add(ResizeWithCropOrPadOp(
                h, w, inputWidth - (w ~/ 2), inputHeight - (h ~/ 2)))
            .build();

        TensorImage sourceImage = TensorImage.fromImage(image);
        expect(() => imageProcessor.process(sourceImage),
            throwsA(isA<ArgumentError>()));
      });

      test('resize with a negative a crop position', () {
        ImageProcessor imageProcessor = ImageProcessorBuilder()
            // the be sure that a part of the crop is outside the iamge we took the input size and substract crop size / 2
            .add(ResizeWithCropOrPadOp(h, w, -100, -10))
            .build();

        TensorImage sourceImage = TensorImage.fromImage(image);
        expect(() => imageProcessor.process(sourceImage),
            throwsA(isA<ArgumentError>()));
      });

      test('resize with pad', () {
        int h = 3000;
        int w = 4000;
        ImageProcessor imageProcessor =
            ImageProcessorBuilder().add(ResizeWithCropOrPadOp(h, w)).build();

        TensorImage processedImage =
            imageProcessor.process(TensorImage.fromImage(image));

        expect(processedImage.height, h);
        expect(processedImage.width, w);
      });

      test('inverse transform', () {
        ImageProcessor imageProcessor =
            ImageProcessorBuilder().add(Rot90Op(2)).build();

        final p = imageProcessor.inverseTransform(
            m.Point(image.width / 2, image.height / 2),
            image.height,
            image.width);

        expect(p == m.Point(image.width / 2, image.height / 2), true);
      });

      test('tensor operator wrapper', () {
        ImageProcessor imageProcessor =
            ImageProcessorBuilder().add(NormalizeOp(127.5, 127.5)).build();

        TensorImage processedImage =
            imageProcessor.process(TensorImage.fromImage(image));

        for (var i in processedImage.tensorBuffer.getDoubleList()) {
          expect(-1 <= i && i <= 1, true);
        }
      });
      test('tensor operator wrapper', () {
        ImageProcessor imageProcessor =
            ImageProcessorBuilder().add(NormalizeOp(0, 1)).build();

        TensorImage processedImage =
            imageProcessor.process(TensorImage.fromImage(image));

        for (var i in processedImage.tensorBuffer.getDoubleList()) {
          expect(0 <= i && i <= 255, true);
        }
      });
    });
  });
}

// Visually verify using
// File('test_assets/output.jpg').writeAsBytes(JpegEncoder().encodeImage(tensorImage.image));
