import 'package:dvote/dvote.dart';
import 'package:states_rebuilder/states_rebuilder.dart';

class QuestionSingleChoice extends StatesRebuilder {
  final ProcessMetadata_Details_Question questionDetails;
  String selectedAnswer;
  String error;

  QuestionSingleChoice({this.questionDetails}) {
    if (optionsAreNotUnique()) this.error = "Options are not unique";
  }

  set answer(value) {
    this.selectedAnswer = value;
  }

  String get answer {
    return this.selectedAnswer;
  }

  optionsAreNotUnique() {
    List<String> existing = [];
    for (var option in this.questionDetails.voteOptions) {
      for (String checkd in existing) {
        if (option.value == checkd) return true;
      }
      existing.add(option.value);
    }
  }
}
