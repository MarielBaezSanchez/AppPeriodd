import 'package:calma360/screen/historialScreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:calma360/screen/home.dart';
import 'package:calma360/screen/login.dart';
import 'package:calma360/screen/signup.dart';
import 'firebase_options.dart';
import 'package:timezone/data/latest.dart' as tz;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  tz.initializeTimeZones();
  runApp(const Calma360App());
}

class Calma360App extends StatelessWidget {
  const Calma360App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calma360',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system, // Seguir preferencia del sistema
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
        '/historialScreen': (context) => const HistoryScreen(),
        '/register': (context) => const SignupScreen(),
      },
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es', 'ES'),
        Locale('en', 'US'),
      ],
      locale: const Locale('es', 'ES'),
    );
  }
}