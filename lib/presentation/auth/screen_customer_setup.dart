import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:suefery/core/l10n/l10n_extension.dart';
import 'package:suefery/presentation/auth/cubit_auth.dart';
import 'package:suefery/presentation/auth/cubit_customer_setup.dart';

class ScreenCustomerSetup extends StatelessWidget {
  const ScreenCustomerSetup({super.key});

  @override
  Widget build(BuildContext context) {
    // Provide the CustomerSetupCubit for this screen
    return BlocProvider(
      create: (_) => CustomerSetupCubit(),
      child: const _CustomerSetupView(),
    );
  }
}

class _CustomerSetupView extends StatelessWidget {
  const _CustomerSetupView();

  @override
  Widget build(BuildContext context) {
    final strings = context.l10n;
    final theme = Theme.of(context);
    final authCubit = context.read<CubitAuth>();
    final setupCubit = context.read<CustomerSetupCubit>();

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.setupTitle),
        centerTitle: true,
      ),
      body: BlocConsumer<CustomerSetupCubit, CustomerSetupState>(
        listener: (context, state) {
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: theme.colorScheme.error,
              ),
            );
          }
        },
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 32),
                TextFormField(
                  initialValue: state.firstName,
                  decoration: InputDecoration(
                    labelText: strings.firstNameLabel,
                    prefixIcon: const Icon(Icons.person_outline),
                  ),
                  onChanged: setupCubit.firstNameChanged,
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: state.lastName,
                  decoration: InputDecoration(
                    labelText: strings.lastNameLabel,
                    prefixIcon: const Icon(Icons.person_outline),
                  ),
                  onChanged: setupCubit.lastNameChanged,
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: state.phone,
                  decoration: InputDecoration(
                    labelText: strings.phoneLabel,
                    prefixIcon: const Icon(Icons.phone_outlined),
                  ),
                  keyboardType: TextInputType.phone,
                  onChanged: setupCubit.phoneChanged,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: state.address,
                  decoration: InputDecoration(
                    labelText: strings.addressLabel,
                    prefixIcon: const Icon(Icons.location_on_outlined),
                  ),
                  onChanged: setupCubit.addressChanged,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: state.isLoading
                      ? null
                      : () {
                          if (setupCubit.validateSubmission()) {
                            authCubit.completeCustomerSetup(
                              firstName: state.firstName,
                              lastName: state.lastName,
                              phone: state.phone,
                              address: state.address,
                            );
                          }
                        },
                  child: state.isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(strokeWidth: 3),
                        )
                      : Text(strings.completeSetup),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}