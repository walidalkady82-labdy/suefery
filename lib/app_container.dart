import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:suefery/core/l10n/l10n_extension.dart';
import 'data/services/firebase_service.dart';
import 'presentation/auth/auth_checker.dart';

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

/// The root widget of the SUEFERY application.
class SUEFERYApp extends StatelessWidget {
  const SUEFERYApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Wrap the app with AppContainer to ensure Firebase is ready
    final strings = context.l10n;
    return MaterialApp(
          title:strings.appTitle,
          // Theme with the primary SUEFERY color palette
          theme: ThemeData(
            primaryColor: const Color(0xFF00796B), // Teal 700 (SUEFERY Primary)
            colorScheme: ColorScheme.fromSwatch(
              primarySwatch: Colors.teal,
            ).copyWith(
              secondary: const Color(0xFFFFA000), // Amber 700 (Accent)
            ),
            useMaterial3: true,
            appBarTheme: const AppBarTheme(
              backgroundColor : Color(0xFF00796B),
              iconTheme: IconThemeData(color: Colors.white),
              titleTextStyle: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          // Set up localization delegate
          localizationsDelegates: [
              //AppLocalizations.delegate, // Custom app localizations
              GlobalMaterialLocalizations.delegate, // Material widgets localizations
              GlobalWidgetsLocalizations.delegate,  // Basic widgets localizations
              GlobalCupertinoLocalizations.delegate, // Cupertino widgets localizations
            ],
            // 2. Define supported locales
            supportedLocales: const [
              Locale('en', ''), // English
              Locale('ar', ''), // arabic
              // Add all supported locales here
            ],
            // 3. Optional: Set a fallback locale if the device locale isn't supported
            // localeResolutionCallback: (locale, supportedLocales) {
            //   if (supportedLocales.contains(locale)) {
            //     return locale;
            //   }
            //   return supportedLocales.first; // Fallback to the first supported locale
            // },
          home: const AuthChecker(),
        );
  }
}
