import 'dart:io';
import 'package:flutter/foundation.dart' as f;
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:imageclassification/classifier.dart';
import 'package:imageclassification/classifier_quant.dart';
import 'package:logger/logger.dart';
import 'package:tflite_flutter_helper/tflite_flutter_helper.dart';

import 'classifier_float.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Image Classification',
      theme: ThemeData(
        primarySwatch: Colors.orange,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Classifier _classifier;

  var logger = Logger();

  File _image;
  final picker = ImagePicker();

  Image _imageWidget;

  img.Image fox;

  Category category;

  @override
  void initState() {
    super.initState();
    _classifier = ClassifierQuant(device: Device.NNAPI);
  }

  Future getImage() async {
    final pickedFile = await picker.getImage(source: ImageSource.gallery);

    setState(() {
      _image = File(pickedFile.path);
      _imageWidget = Image.file(
        _image,
      );

      _predict();
    });
  }

  void _predict() async {
    if (fox == null) {
      final data = await rootBundle.load('assets/lion.jpg');
      fox = img.decodeImage(data.buffer.asUint8List());
    }
    var pred;
    for (int i = 0; i < 10; i++) {
      pred = _classifier.predict(fox);
    }
    print(pred);
    setState(() {
      this.category = category;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('TfLite Flutter Helper',
            style: TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: <Widget>[
          Center(
            child: _image == null
                ? Text('No image selected.')
                : Container(
                    constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height / 2),
                    decoration: BoxDecoration(
                      border: Border.all(),
                    ),
                    child: _imageWidget,
                  ),
          ),
          SizedBox(
            height: 36,
          ),
          Text(
            category != null ? category.label : '',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          SizedBox(
            height: 8,
          ),
          Text(
            category != null
                ? 'Confidence: ${category.score.toStringAsFixed(3)}'
                : '',
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: getImage,
        tooltip: 'Pick Image',
        child: Icon(Icons.add_a_photo),
      ),
    );
  }
}
