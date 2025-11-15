import 'package:flutter/material.dart';
import 'package:suefery/core/l10n/l10n_extension.dart';

class Placeholder extends StatelessWidget {
  final String titleKey;
  const Placeholder({required this.titleKey, super.key});

  @override
  Widget build(BuildContext context) {
    final strings = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(strings.appTitle),
        backgroundColor: const Color.fromARGB(255, 207, 150, 150),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.construction, size: 80, color: Colors.grey),
            const SizedBox(height: 20),
            Text(
              strings.appTitle,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'Development in Progress...',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}