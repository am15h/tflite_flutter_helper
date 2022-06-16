import 'package:tflite_flutter_helper/src/task/text/qa/qa_answer.dart';

/// API to answer questions based on context. */
abstract class QuestionAnswerer {
  /// Answers [question] based on [context], and returns a list of possible [QaAnswer]s. Could be
  /// empty if no answer was found from the given context.
  List<QaAnswer> answer(String context, String question);
}
