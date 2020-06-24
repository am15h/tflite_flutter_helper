/// The common interface for classes that carries an "apply" method, which converts [T] to another one.
abstract class Operator<T> {
  /// Applies an operation on a [T] object, returning a [T] object.
  ///
  /// Note: The returned object could probably be the same one with given input, and given input
  /// could probably be changed.
  T apply(T x);
}
