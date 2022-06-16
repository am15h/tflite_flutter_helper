class QaData {
  final String title;
  final String content;
  final List<String> questions;

  QaData(this.title, this.content, this.questions);

  @override
  String toString() {
    return 'QaData{title: $title, content: $content, questions: $questions}';
  }
}

