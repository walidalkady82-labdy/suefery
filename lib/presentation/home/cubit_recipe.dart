import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:suefery/core/utils/logger.dart';

class StateRecipe {

}

class CubitRecipe extends Cubit<StateRecipe> with LogMixin{
  CubitRecipe() : super(StateRecipe());

  //   /// A convenience method to trigger a recipe suggestion.
  // Future<void> suggestRecipe() async {
  //   //TODO: Replace localized strings
  //   await submitOrderPrompt("Suggest a recipe");
  // }
}




