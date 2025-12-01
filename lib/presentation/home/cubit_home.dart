import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:suefery/core/utils/logger.dart';

// --- STATE ---
class StateHome extends Equatable {
  final int selectedViewIndex;

  const StateHome({this.selectedViewIndex = 0});

  StateHome copyWith({int? selectedViewIndex}) {
    return StateHome(
      selectedViewIndex: selectedViewIndex ?? this.selectedViewIndex,
    );
  }

  @override
  List<Object?> get props => [selectedViewIndex];
}

// --- CUBIT ---
class CubitHome extends Cubit<StateHome> with LogMixin {
  CubitHome() : super(const StateHome());

  void changeView(int index) {
    emit(state.copyWith(selectedViewIndex: index));
  }
}