import 'package:quiver/core.dart';

/// Category is a util class, contains a label and a float value. Typically it's used as result of
/// classification tasks.
class Category {
  String _label;
  double _score;

  /// Constructs a Category.
  Category(this._label, this._score);

  /// Gets the reference of category's label.
  String get label => _label;

  /// Gets the score of the category.
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
