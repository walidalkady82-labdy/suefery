import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:suefery/core/l10n/l10n_extension.dart';
import 'package:suefery/presentation/auth/auth_cubit.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = context.l10n;
    // The AuthCubit is provided globally, so we can access it here.
    final authState = context.watch<AuthCubit>().state;
    final user = authState.user;

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.profileTitle), // You will need to add 'profileTitle' to your localization files
        backgroundColor: Colors.teal.shade800,
      ),
      body: user == null
          ? const Center(child: Text('No user logged in.'))
          : ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                const Center(
                  child: CircleAvatar(
                    radius: 50,
                    child: Icon(Icons.person, size: 50),
                  ),
                ),
                const SizedBox(height: 24),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.person_outline),
                        title: Text(user.name ?? 'No Name'),
                      ),
                      ListTile(
                        leading: const Icon(Icons.email_outlined),
                        title: Text(user.email ?? 'No Email'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}