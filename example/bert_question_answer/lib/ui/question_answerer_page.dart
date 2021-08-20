import 'package:bert_question_answer/bert_qa.dart';
import 'package:bert_question_answer/data/qa_data.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class QuestionAnswererPage extends StatefulWidget {
  final QaData data;

  const QuestionAnswererPage({Key? key, required this.data}) : super(key: key);

  @override
  _QuestionAnswererPageState createState() => _QuestionAnswererPageState();
}

class _QuestionAnswererPageState extends State<QuestionAnswererPage> {
  final controller = TextEditingController();
  late final BertQA classifier;

  String? answer;

  @override
  void initState() {
    super.initState();
    classifier = BertQA();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                child: Text(widget.data.content),
              ),
            ),
            Expanded(
              child: Container(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                          color: answer != null
                              ? Colors.orange
                              : Colors.transparent),
                      child: Column(
                        children: [
                          Text(answer ?? 'Ask Question'),
                        ],
                      ),
                    ),
                    Container(
                      height: 60,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: widget.data.questions.length,
                        itemBuilder: (context, i) {
                          return GestureDetector(
                            onTap: () {
                              controller.text =
                                  widget.data.questions.elementAt(i);
                              getAnswer();
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Chip(
                                label: Text(widget.data.questions.elementAt(i)),
                              ),
                            ),
                          );
                        },
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
                          icon: Icon(Icons.arrow_right_alt_rounded),
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
