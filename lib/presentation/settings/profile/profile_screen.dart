import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:suefery/core/l10n/l10n_extension.dart';
import 'package:suefery/presentation/settings/profile/profile_cubit.dart';

import '../../../data/enum/form_status.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ProfileCubit(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.l10n.profileTitle),
          backgroundColor: Colors.teal.shade800,
        ),
        body: BlocConsumer<ProfileCubit, ProfileState>(
          listener: (context, state) {
            if (state.successMessage?.isNotEmpty == true) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content: Text(state.successMessage!),
                    backgroundColor: Colors.green,
                  ),
                );
            }
            if (state.errorMessage?.isNotEmpty == true) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content: Text(state.errorMessage!),
                    backgroundColor: Colors.red,
                  ),
                );
            }
          },
          builder: (context, state) {
            if (state.status == FromStatus.initial || state.status == FromStatus.loading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state.status == FromStatus.error && state.email.isEmpty) {
              return Center(child: Text(state.errorMessage ?? 'Failed to load profile.'));
            }

            return ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                const Center(
                  child: CircleAvatar(radius: 50, child: Icon(Icons.person, size: 50)),
                ),
                const SizedBox(height: 24),
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          initialValue: state.name,
                          decoration: const InputDecoration(labelText: 'Name', icon: Icon(Icons.person_outline)),
                          onChanged: (value) => context.read<ProfileCubit>().nameChanged(value),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          initialValue: state.phone,
                          decoration: const InputDecoration(labelText: 'Phone Number', icon: Icon(Icons.phone_outlined)),
                          keyboardType: TextInputType.phone,
                          onChanged: (value) => context.read<ProfileCubit>().phoneChanged(value),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          initialValue: state.email,
                          readOnly: true, // Email is not editable
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            icon: Icon(Icons.email_outlined),
                            fillColor: Colors.black12,
                            filled: true,
                          ),
                        ),
                        const SizedBox(height: 32),
                        ElevatedButton.icon(
                          onPressed: state.status == FromStatus.saving
                              ? null
                              : () => context.read<ProfileCubit>().saveProfile(),
                          icon: state.status == FromStatus.saving ? const SizedBox.shrink() : const Icon(Icons.save),
                          label: Text(state.status == FromStatus.saving ? 'Saving...' : 'Save Changes'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}