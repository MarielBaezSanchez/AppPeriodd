//import 'package:calma360/screen/mood.dart';

import 'package:calma360/screen/home.dart';
import 'package:calma360/screen/login.dart';
import 'package:calma360/screen/signup.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() {
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
      supportedLocales: const [Locale('es', 'ES'), Locale('en', 'US')],
    );
  }
}
//