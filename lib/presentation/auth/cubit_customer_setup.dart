import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';


class CustomerSetupState extends Equatable {
  final String firstName;
  final String lastName;
  final String phone;
  final String address;
  final String? errorMessage;
  final bool isLoading;

  const CustomerSetupState({
    this.firstName = '',
    this.lastName = '',
    this.phone = '',
    this.address = '',
    this.errorMessage,
    this.isLoading = false,
  });

  CustomerSetupState copyWith({
    String? firstName,
    String? lastName,
    String? phone,
    String? address,
    String? errorMessage,
    bool? isLoading,
  }) {
    return CustomerSetupState(
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      errorMessage: errorMessage, // Don't fall back, allow clearing
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [
        firstName,
        lastName,
        phone,
        address,
        errorMessage,
        isLoading,
      ];
}

class CustomerSetupCubit extends Cubit<CustomerSetupState> {
  CustomerSetupCubit() : super(const CustomerSetupState());

  void firstNameChanged(String value) => emit(state.copyWith(firstName: value));
  void lastNameChanged(String value) => emit(state.copyWith(lastName: value));
  void phoneChanged(String value) => emit(state.copyWith(phone: value));
  void addressChanged(String value) => emit(state.copyWith(address: value));

  /// Final validation before submitting the whole form.
  bool validateSubmission() {
    emit(state.copyWith(errorMessage: null)); // Clear previous error

    if (state.firstName.trim().isEmpty) {
      emit(state.copyWith(errorMessage: 'First name is required.'));
      return false;
    }
    if (state.lastName.trim().isEmpty) {
      emit(state.copyWith(errorMessage: 'Last name is required.'));
      return false;
    }
    if (state.phone.trim().isEmpty) {
      emit(state.copyWith(errorMessage: 'Phone number is required.'));
      return false;
    }
    if (state.address.trim().isEmpty) {
      emit(state.copyWith(errorMessage: 'Delivery address is required.'));
      return false;
    }
    emit(state.copyWith(errorMessage: null));
    return true;
  }
}
