/// Answers to [QuestionAnswerer]. Contains information about the answer and its relative
/// position information to the context.
class QaAnswer {
  Pos pos;
  String text;

  QaAnswer(this.pos, this.text);
}

/// Position information of the answer relative to context. It is sortable in descending order
/// based on logit.
class Pos implements Comparable<Pos> {
  int start;
  int end;
  double logit;

  Pos(this.start, this.end, this.logit);

  @override
  int compareTo(Pos other) {
    return other.logit.compareTo(this.logit);
  }
}
