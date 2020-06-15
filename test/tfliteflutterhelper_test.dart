import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart';
import 'package:tflite_flutter_helper/src/common/file_util.dart';
import 'package:tflite_flutter_helper/src/image/image_processor.dart';
import 'package:tflite_flutter_helper/src/image/ops/resize_op.dart';
import 'package:tflite_flutter_helper/src/image/ops/resize_with_crop_or_pad_op.dart';
import 'package:tflite_flutter_helper/src/image/ops/rot90_op.dart';
import 'package:tflite_flutter_helper/src/image/tensor_image.dart';
import 'package:tflite_flutter_helper/src/tensorbuffer/tensorbuffer.dart';
import 'package:tflite_flutter_helper/src/tensorbuffer/tensorbufferfloat.dart';
import 'package:tflite_flutter_helper/src/tensorbuffer/tensorbufferuint8.dart';

// flutter test test
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('tensorbuffer', () {
    group('uint8', () {
      test('static', () {
        TensorBuffer tensorBuffer = TensorBufferUint8([1, 3, 2]);
        ByteBuffer buffer = Uint8List.fromList([1, 2, 3, 4, 5, 6]).buffer;
        tensorBuffer.loadBuffer(buffer);
        expect(tensorBuffer.getIntList(), [1, 2, 3, 4, 5, 6]);
        expect(tensorBuffer.getDoubleList(), <double>[1, 2, 3, 4, 5, 6]);
      });

      test('dynamic', () {
        TensorBuffer tensorBuffer = TensorBufferUint8.dynamic();
        ByteBuffer buffer = Uint8List.fromList([1, 2, 3, 4, 5, 6]).buffer;
        tensorBuffer.loadBuffer(buffer, shape: [1, 3, 2]);
        expect(tensorBuffer.getIntList(), [1, 2, 3, 4, 5, 6]);
        expect(tensorBuffer.getDoubleList(), <double>[1, 2, 3, 4, 5, 6]);
      });

      test('load list int', () {
        TensorBuffer tensorBuffer = TensorBufferUint8.dynamic();
        List<int> list = [1, 2, 3, 4, 5, 655];
        tensorBuffer.loadList(list, shape: [1, 3, 2]);
        expect(tensorBuffer.getIntList(), [1, 2, 3, 4, 5, 255]);
      });
    });

    group('float', () {
      test('static', () {
        TensorBuffer tensorBuffer = TensorBufferFloat([1, 2, 2]);
        var bdata = ByteData(16);

        for (int i = 0, j = 1; i < 16; i += 4, j++)
          bdata.setFloat32(i, j.toDouble());

        tensorBuffer.loadBuffer(bdata.buffer);
        expect(tensorBuffer.getDoubleList(), <double>[1, 2, 3, 4]);

        expect(tensorBuffer.getIntList(), [1, 2, 3, 4]);
      });
    });
  });

  group('common', () {
    test('file_util', () async {
      File file = File('test_assets/labels_mobilenet_quant_v1_224.txt');
      List<String> labels = FileUtil.loadLabelsFromFile(file);
      expect(labels[0], 'background');
    });
  });

  group('image', () {
    Image image =
        decodeImage(File('test_assets/goldfish.jpg').readAsBytesSync());
    final inputHeight = image.height;
    final inputWidth = image.width;

    File('test_assets/asd.jpg').writeAsBytes(JpegEncoder().encodeImage(image));

    group('TensorImage', () {
      TensorImage tensorImage;
      TensorBuffer tensorbuffer;

      test('fromImage', () {
        tensorImage = TensorImage.fromImage(image);
        expect(tensorImage, isNotNull);
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

        File('test_assets/buffer3.jpg').writeAsBytes(JpegEncoder().encodeImage(
            Image.fromBytes(
                inputWidth, inputHeight, tensorImage.tensorBuffer.getIntList(),
                format: Format.rgb)));
      });
    });

    group('ImageProcessor', () {
      test('resize', () {
        ImageProcessor imageProcessor = ImageProcessorBuilder()
            .add(ResizeOp(400, 400, ResizeMethod.BILINEAR))
            .build();

        TensorImage processedImage =
            imageProcessor.process(TensorImage.fromImage(image));

        expect(processedImage.height, 400);
        expect(processedImage.width, 400);

        File('test_assets/buffer.jpg')
            .writeAsBytes(JpegEncoder().encodeImage(processedImage.image));
      });

      test('rot90', () {
        ImageProcessor imageProcessor = ImageProcessorBuilder()
            .add(Rot90Op())
            .add(ResizeOp(400, 800, ResizeMethod.NEAREST_NEIGHBOUR))
            .build();

        TensorImage processedImage =
            imageProcessor.process(TensorImage.fromImage(image));

        expect(processedImage.height, 400);
        expect(processedImage.width, 800);

        File('test_assets/rot90.jpg')
            .writeAsBytes(JpegEncoder().encodeImage(processedImage.image));
      });
      test('resize with crop', () {
        ImageProcessor imageProcessor = ImageProcessorBuilder()
            .add(ResizeWithCropOrPadOp(1000, 2000))
            .build();

        TensorImage processedImage =
            imageProcessor.process(TensorImage.fromImage(image));
//
//        expect(processedImage.height, 400);
//        expect(processedImage.width, 800);

        File('test_assets/resize_crop.jpg')
            .writeAsBytes(JpegEncoder().encodeImage(processedImage.image));
      });

      test('resize with pad', () {
        ImageProcessor imageProcessor = ImageProcessorBuilder()
            .add(ResizeWithCropOrPadOp(3000, 4000))
            .build();

        TensorImage processedImage =
            imageProcessor.process(TensorImage.fromImage(image));

        expect(processedImage.height, 3000);
        expect(processedImage.width, 4000);

        File('test_assets/resize_pad.jpg')
            .writeAsBytes(JpegEncoder().encodeImage(processedImage.image));
      });
    });
  });
}
