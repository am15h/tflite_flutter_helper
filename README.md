# TensorFlow Lite Flutter Helper Library

TFLite Flutter Helper Library brings [TFLite Support Library](https://www.tensorflow.org/lite/inference_with_metadata/lite_support) and [TFLite Support Task Library](https://www.tensorflow.org/lite/inference_with_metadata/task_library/overview) to Flutter and helps users to develop ML and deploy TFLite models onto mobile devices quickly without compromising on performance.

## Getting Started

### Setup TFLite Flutter Plugin

Follow the initial setup instructions given [here](https://github.com/am15h/tflite_flutter_plugin#most-important-initial-setup)

### Basic image manipulation and conversion

TFLite Helper depends on [flutter image package](https://pub.dev/packages/image) internally for
Image Processing.

The TensorFlow Lite Support Library has a suite of basic image manipulation methods such as crop
and resize. To use it, create an `ImageProcessor` and add the required operations.
To convert the image into the tensor format required by the TensorFlow Lite interpreter,
create a `TensorImage` to be used as input:

```dart
// Initialization code
// Create an ImageProcessor with all ops required. For more ops, please
// refer to the ImageProcessor Ops section in this README.
ImageProcessor imageProcessor = ImageProcessorBuilder()
  .add(ResizeOp(224, 224, ResizeMethod.NEAREST_NEIGHBOUR))
  .build();

// Create a TensorImage object from a File
TensorImage tensorImage = TensorImage.fromFile(imageFile);

// Preprocess the image.
// The image for imageFile will be resized to (224, 224)
tensorImage = imageProcessor.process(tensorImage);
```

Sample app: [Image Classification](https://github.com/am15h/tflite_flutter_helper/tree/master/example/image_classification)

### Basic audio data processing

The TensorFlow Lite Support Library also defines a TensorAudio class wrapping some basic audio data processing methods.

```dart
TensorAudio tensorAudio = TensorAudio.create(
    TensorAudioFormat.create(1, sampleRate), size);
tensorAudio.loadShortBytes(audioBytes);

TensorBuffer inputBuffer = tensorAudio.tensorBuffer;
```

Sample app: [Audio Classification](https://github.com/am15h/tflite_flutter_helper/tree/master/example/audio_classification)

### Create output objects and run the model

```dart
// Create a container for the result and specify that this is a quantized model.
// Hence, the 'DataType' is defined as UINT8 (8-bit unsigned integer)
TensorBuffer probabilityBuffer =
    TensorBuffer.createFixedSize(<int>[1, 1001], TfLiteType.uint8);
```

#### Loading the model and running inference:

```dart
import 'package:tflite_flutter/tflite_flutter.dart';

try {
    // Create interpreter from asset.
    Interpreter interpreter =
        await Interpreter.fromAsset("mobilenet_v1_1.0_224_quant.tflite");
    interpreter.run(tensorImage.buffer, probabilityBuffer.buffer);
} catch (e) {
    print('Error loading model: ' + e.toString());
}
```

### Accessing the result

Developers can access the output directly through `probabilityBuffer.getDoubleList()`.
If the model produces a quantized output, remember to convert the result.
For the MobileNet quantized model, the developer needs to divide each output value by 255
to obtain the probability ranging from 0 (least likely) to 1 (most likely) for each category.


### Optional: Mapping results to labels

Developers can also optionally map the results to labels. First, copy the text
file containing labels into the module’s assets directory. Next, load the
label file using the following code:

```dart
List<String> labels = await FileUtil.loadLabels("assets/labels.txt");
```

The following snippet demonstrates how to associate the probabilities with category labels:

```dart
TensorLabel tensorLabel = TensorLabel.fromList(
      labels, probabilityProcessor.process(probabilityBuffer));

Map<String, double> doubleMap = tensorLabel.getMapWithFloatValue();
```

### ImageProcessor Architecture

The design of the ImageProcessor allowed the image manipulation operations to be defined up
front and optimised during the build process. The ImageProcessor currently supports
three basic preprocessing operations:

```dart
int cropSize = min(_inputImage.height, _inputImage.width);

ImageProcessor imageProcessor = ImageProcessorBuilder()
    // Center crop the image to the largest square possible
    .add(ResizeWithCropOrPadOp(cropSize, cropSize))
    // Resize using Bilinear or Nearest neighbour
    .add(ResizeOp(224, 224, ResizeMethod.NEAREST_NEIGHBOUR))
    // Rotation clockwise in 90 degree increments
    .add(Rot90Op(rotationDegrees ~/ 90))
    .add(NormalizeOp(127.5, 127.5))
    .add(QuantizeOp(128.0, 1 / 128.0))
    .build();

```

See more details [here](https://www.tensorflow.org/lite/convert/metadata#normalization_and_quantization_parameters) about normalization and quantization.

### Quantization

The TensorProcessor can be used to quantize input tensors or dequantize output tensors.
For example, when processing a quantized output TensorBuffer, the developer can use DequantizeOp to
dequantize the result to a floating point probability between 0 and 1:

```dart
// Post-processor which dequantize the result
TensorProcessor probabilityProcessor =
    TensorProcessorBuilder().add(DequantizeOp(0, 1 / 255.0)).build();
TensorBuffer dequantizedBuffer =
    probabilityProcessor.process(probabilityBuffer);
```

#### Reading Qunatization Params

```dart
// Quantization Params of input tensor at index 0
QuantizationParams inputParams = interpreter.getInputTensor(0).params;

// Quantization Params of output tensor at index 0
QuantizationParams outputParams = interpreter.getOutputTensor(0).params;
```

## Task Library

Currently, Text based models like `NLClassifier`, `BertNLClassifier` and `BertQuestionAnswerer` are available to use with the Flutter Task Library.

### Integrate Natural Langugae Classifier

The Task Library's `NLClassifier` API classifies input text into different categories, and is a versatile and configurable API that can handle most text classification models. Detailed guide is available [here](https://www.tensorflow.org/lite/inference_with_metadata/task_library/nl_classifier).

```dart
final classifier = await NLClassifier.createFromAsset('assets/$_modelFileName',
        options: NLClassifierOptions());
List<Category> predictions = classifier.classify(rawText);
```

Sample app: [Text Classification](https://github.com/am15h/tflite_flutter_helper/tree/master/example/text_classification_task).

### Integrate BERT natural language classifier

The Task Library `BertNLClassifier` API is very similar to the `NLClassifier` that classifies input text into different categories, except that this API is specially tailored for Bert related models that require Wordpiece and Sentencepiece tokenizations outside the TFLite model. Detailed guide is available [here](https://www.tensorflow.org/lite/inference_with_metadata/task_library/bert_nl_classifier).

```dart
final classifier = await BertNLClassifier.createFromAsset('assets/$_modelFileName',
        options: BertNLClassifierOptions());
List<Category> predictions = classifier.classify(rawText);
```

### Integrate BERT question answerer

The Task Library `BertQuestionAnswerer` API loads a Bert model and answers questions based on the content of a given passage. For more information, see the documentation for the Question-Answer model [here](https://www.tensorflow.org/lite/models/bert_qa/overview). Detailed guide is available [here](https://www.tensorflow.org/lite/inference_with_metadata/task_library/bert_question_answerer).

```dart
final bertQuestionAnswerer = await BertQuestionAnswerer.createFromAsset('assets/$_modelFileName');
List<QaAnswer> answeres = bertQuestionAnswerer.answer(context, question);
```

Sample app: [Bert Question Answerer Sample](https://github.com/am15h/tflite_flutter_helper/tree/master/example/bert_question_answer)
