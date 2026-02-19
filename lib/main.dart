import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'home.dart';
import 'starting_pages/welcome_page.dart';
import 'starting_pages/loading_screen.dart';
import 'firebase_options.dart';
import 'profile.dart';
import 'health.dart';
import 'personal.dart';
import 'theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Suppress the "disposed EngineFlutterView" assertion that fires on
  // Flutter Web during hot restart. It is harmless and does not affect
  // production builds.
  if (kIsWeb) {
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      final message = details.exceptionAsString();
      if (message.contains('disposed EngineFlutterView')) {
        // Ignore this web-engine hot-restart artefact.
        return;
      }
      originalOnError?.call(details);
    };
  }

  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'My Companion',
          theme: themeProvider.lightTheme,
          darkTheme: themeProvider.darkTheme,
          themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          debugShowCheckedModeBanner: false,
          home: LoadingScreen(nextScreen: AuthCheck()),
          routes: {
            '/profile': (context) => ProfilePage(),
            '/health': (context) => HealthPage(),
            '/personal': (context) => PersonalPage(),
          },
        );
      },
    );
  }
}

class AuthCheck extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasData) {
          return HomePage();
        } else {
          return WelcomePage();
        }
      },
    );
  }
}
