import 'package:tflite_flutter_helper/src/common/support_preconditions.dart';
import 'package:tflite_flutter_helper/src/image/image_processor.dart';
import 'operator.dart';
import 'processor.dart';
import 'package:meta/meta.dart';

/// A processor base class that chains a serial of [Operator] of type [T]
/// and executes them.
///
/// Typically, users could use its subclasses, e.g. [ImageProcessor]
/// rather than directly use this one.
class SequentialProcessor<T> implements Processor<T> {
  /// List of operators added to this [SequentialProcessor].
  @protected
  late List<Operator<T>> operatorList;

  /// The [Map] between the operator name and the corresponding op indexes in [operatorList].
  /// An operator may be added multiple times into this [SequentialProcessor].
  @protected
  late Map<String, List<int>> operatorIndex;

  @protected
  SequentialProcessor(SequentialProcessorBuilder<T> builder) {
    operatorList = builder._operatorList;
    operatorIndex = Map.unmodifiable(builder._operatorIndex);
  }

  @override
  T process(T input) {
    operatorList.forEach((op) {
      input = op.apply(input);
    });
    return input;
  }
}

/// The builder class to build a Sequential Processor.
class SequentialProcessorBuilder<T> {
  final List<Operator<T>> _operatorList;
  final Map<String, List<int>> _operatorIndex;

  @protected
  SequentialProcessorBuilder()
      : _operatorList = [],
        _operatorIndex = {};

  SequentialProcessorBuilder<T> add(Operator<T> op) {
    SupportPreconditions.checkNotNull(op,
        message: 'Adding null Op is illegal.');
    _operatorList.add(op);

    String operatorName = op.runtimeType.toString();
    if (!_operatorIndex.containsKey(operatorName)) {
      _operatorIndex[operatorName] = <int>[];
    }
    _operatorIndex[operatorName]!.add(_operatorList.length - 1);
    return this;
  }

  SequentialProcessor<T> build() {
    return SequentialProcessor<T>(this);
  }
}
