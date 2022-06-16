import 'package:bert_question_answer/bert_qa.dart';
import 'package:bert_question_answer/data/qa_data.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:random_color/random_color.dart';

class QuestionAnswererPage extends StatefulWidget {
  final QaData data;

  const QuestionAnswererPage({Key? key, required this.data}) : super(key: key);

  @override
  _QuestionAnswererPageState createState() => _QuestionAnswererPageState();
}

class _QuestionAnswererPageState extends State<QuestionAnswererPage> {
  final controller = TextEditingController();
  late final BertQA classifier;

  late List<Widget> suggestedQuestions;

  String? answer;

  @override
  void initState() {
    super.initState();
    classifier = BertQA();
    suggestedQuestions = List.generate(
      widget.data.questions.length,
      (i) => GestureDetector(
        onTap: () {
          controller.text = widget.data.questions.elementAt(i);
          getAnswer();
        },
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Chip(
            backgroundColor: RandomColor()
                .randomColor(colorBrightness: ColorBrightness.veryLight)
                .withOpacity(0.5),
            label: Text(widget.data.questions.elementAt(i)),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: BackButton(color: Colors.white),
        title: Text(
          widget.data.title,
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Card(
                    child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    widget.data.content,
                  ),
                )),
              ),
            ),
            Expanded(
              child: Container(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: answer != null
                            ? Colors.orangeAccent
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                      child: Text(
                        answer ?? 'Ask Question',
                        style: TextStyle(
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    Container(
                      height: 60,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: suggestedQuestions,
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            maxLines: 3,
                            maxLengthEnforcement: MaxLengthEnforcement.none,
                            style: TextStyle(fontSize: 14),
                            controller: controller,
                            decoration: InputDecoration(
                                border: OutlineInputBorder(),
                                hintText: 'Enter question'),
                          ),
                        ),
                        IconButton(
                          onPressed: getAnswer,
                          icon: Icon(
                            Icons.arrow_upward_sharp,
                            color: Colors.orange,
                          ),
                        )
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void getAnswer() {
    setState(() {
      answer =
          classifier.answer(widget.data.content, controller.text).first.text;
    });
  }
}
