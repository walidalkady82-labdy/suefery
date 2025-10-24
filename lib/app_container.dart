import 'package:flutter/material.dart';
import 'services/firebase_service.dart';

/// A wrapper widget that handles the asynchronous initialization of Firebase
/// and authentication before rendering the main application.
class AppContainer extends StatefulWidget {
  final Widget child;
  
  const AppContainer({super.key, required this.child});

  @override
  State<AppContainer> createState() => _AppContainerState();
}

class _AppContainerState extends State<AppContainer> {
  Future<void>? _initialization;

  @override
  void initState() {
    super.initState();
    // Start the initialization process when the widget is created
    _initialization = FirebaseService.instance.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initialization,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasError) {
            // Display an error message if initialization fails
            return _ErrorView(
              message: 'Failed to load Firebase: ${snapshot.error}',
            );
          }
          // Firebase is ready, render the main application content
          return widget.child;
        }
        
        // While loading, display a splash screen or loading indicator
        return const _LoadingView();
      },
    );
  }
}

// Simple loading view
class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Initializing SUEFERY...', style: TextStyle(fontSize: 18, color: Colors.blueGrey)),
            ],
          ),
        ),
      ),
    );
  }
}

// Simple error view
class _ErrorView extends StatelessWidget {
  final String message;
  
  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                const Text(
                  'Initialization Error', 
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(message, textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
