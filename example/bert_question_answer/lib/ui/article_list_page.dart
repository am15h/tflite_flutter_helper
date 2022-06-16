import 'package:bert_question_answer/data/dataset_loader.dart';
import 'package:bert_question_answer/data/qa_data.dart';
import 'package:bert_question_answer/ui/question_answerer_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:random_color/random_color.dart';

class ArticleListPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<QaData>>(
      future: DatasetLoader.loadDatasetFromAssets(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text("Choose a topic from the list"),
              ),
              Expanded(
                child: ListView.separated(
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, i) {
                    return ListTile(
                      onTap: () {
                        Navigator.push(context,
                            MaterialPageRoute(builder: (context) {
                          return QuestionAnswererPage(
                              data: snapshot.data!.elementAt(i));
                        }));
                      },
                      title: Text(snapshot.data!.elementAt(i).title),
                    );
                  },
                  separatorBuilder: (BuildContext context, int index) {
                    return Divider();
                  },
                ),
              ),
            ],
          );
        }
        return Center(child: CircularProgressIndicator());
      },
    );
  }
}
