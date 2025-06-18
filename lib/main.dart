import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:calma360/screen/home.dart';
import 'package:calma360/screen/login.dart';
import 'package:calma360/screen/signup.dart';
import 'firebase_options.dart';
import 'package:timezone/data/latest.dart' as tz; // 🕐 Import necesario

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Inicializa zonas horarias para notificaciones programadas
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
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.pinkAccent),
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => LoginScreen(),
        '/home': (context) => HomeScreen(),
        '/register': (context) => SignupScreen(),
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
    );
  }
}
