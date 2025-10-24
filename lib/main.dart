import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'app_container.dart';
import 'app_localizations.dart';
import 'blocs/order_history_bloc.dart';
import 'screens/order_history.dart';
import 'services/firebase_service.dart';
import 'services/logging_service.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

final _log = LoggerReprository('main');
void main() {
  // Ensure Flutter engine is initialized before running the app
  _log.i('initializing localization...');
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SUEFERYApp());
  _log.i('App initialized...');
}

/// The root widget of the SUEFERY application.
class SUEFERYApp extends StatelessWidget {
  const SUEFERYApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Wrap the app with AppContainer to ensure Firebase is ready
    return AppContainer(
      child: MultiBlocProvider(
        providers: [
          // Provide the OrderHistoryBloc to the widget tree
          BlocProvider(
            create: (context) {
              return OrderHistoryBloc()..add(LoadOrderHistory());
            },
          ),
        ],
        child: MaterialApp(
          title: 'SUEFERY',
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
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            CustomLocalizationsDelegate(),
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          locale: const Locale('en', ''), // Default locale
          home: const HomeScreen(),
        ),
      ),
    );
  }
}

/// A simple screen to host the HistoryScreen for demonstration.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // The AppLocalizations class must be initialized here
    final loc = AppLocalizations.of(context)!;
    
    // Display the current user ID to confirm successful authentication
    final userId = FirebaseService.instance.userId;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.translate('home_title')),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Welcome to SUEFERY!', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 10),
            // MANDATORY: Display the full user ID for multi-user collaboration
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: SelectableText(
                'Current User ID (Firestore Path): $userId',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const OrderHistoryScreen(),
                ));
              },
              icon: const Icon(Icons.history),
              label: Text(loc.translate('view_history')),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.secondary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                textStyle: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
