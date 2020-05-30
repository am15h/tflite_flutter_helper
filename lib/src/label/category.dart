import 'package:quiver/core.dart';

class Category {
  String _label;
  double _score;

  Category(this._label, this._score);

  String get label => _label;
  double get score => _score;

  @override
  bool operator ==(Object o) {
    if (o is Category) {
      return (o.label == _label && o.score == _score);
    }
    return false;
  }

  @override
  int get hashCode {
    return hash2(_label, _score);
  }

  @override
  String toString() {
    return "<Category \"" +
        label +
        "\" (score=" +
        score.toStringAsFixed(3) +
        ")>";
  }
}
