import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        DeviceType deviceType;

        if (width <= 400 && height <= 500) {
          deviceType = DeviceType.smartwatch;
        } else if (width < 600) {
          deviceType = DeviceType.phone;
        } else {
          deviceType = DeviceType.tv;
        }

        final double fontSizeTitle =
            {
              DeviceType.smartwatch: 18.0,
              DeviceType.phone: 28.0,
              DeviceType.tv: 36.0,
            }[deviceType]!;

        final double fontSizeText =
            {
              DeviceType.smartwatch: 12.0,
              DeviceType.phone: 16.0,
              DeviceType.tv: 20.0,
            }[deviceType]!;

        final double inputPadding =
            {
              DeviceType.smartwatch: 8.0,
              DeviceType.phone: 16.0,
              DeviceType.tv: 24.0,
            }[deviceType]!;

        final double cardWidth =
            {
              DeviceType.smartwatch: width * 0.9,
              DeviceType.phone: width * 0.95,
              DeviceType.tv: width * 0.5,
            }[deviceType]!;

        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFE8B4CB),
                  Color(0xFFD4A5C0),
                  Color(0xFFC196B5),
                ],
              ),
            ),
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: inputPadding),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: cardWidth),
                    child: Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      color: Color(0xFFF5F0F0),
                      child: Padding(
                        padding: EdgeInsets.all(inputPadding * 2),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Iniciar sesión',
                              style: TextStyle(
                                fontSize: fontSizeTitle,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF8B4A6B),
                                letterSpacing: 0.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: inputPadding * 2),

                            Text(
                              'Correo electrónico',
                              style: TextStyle(
                                fontSize: fontSizeText,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF8B4A6B),
                              ),
                            ),
                            SizedBox(height: 8),
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: _inputDecoration(
                                'ejemplo@correo.com',
                                inputPadding,
                              ),
                            ),
                            SizedBox(height: inputPadding * 1.5),

                            Text(
                              'Contraseña',
                              style: TextStyle(
                                fontSize: fontSizeText,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF8B4A6B),
                              ),
                            ),
                            SizedBox(height: 8),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: true,
                              decoration: _inputDecoration(
                                'Escribe tu contraseña',
                                inputPadding,
                              ),
                            ),
                            SizedBox(height: inputPadding * 2),

                            ElevatedButton(
                              onPressed: _handleLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF8B4A6B),
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(
                                  vertical: inputPadding,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 4,
                                shadowColor: Color(0xFF8B4A6B).withOpacity(0.3),
                              ),
                              child: Text(
                                'Entrar',
                                style: TextStyle(
                                  fontSize: fontSizeText,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            SizedBox(height: inputPadding * 1.5),

                            GestureDetector(
                              onTap: _navigateToRegister,
                              child: Text(
                                '¿No tienes cuenta? Registrarse',
                                style: TextStyle(
                                  fontSize: fontSizeText,
                                  color: Color(0xFF8B4A6B),
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  InputDecoration _inputDecoration(String hintText, double padding) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 16),
      filled: true,
      fillColor: Colors.white.withOpacity(0.8),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Color(0xFFB68A9F), width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Color(0xFFB68A9F), width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Color(0xFF8B4A6B), width: 2),
      ),
      contentPadding: EdgeInsets.symmetric(
        horizontal: padding,
        vertical: padding,
      ),
    );
  }

  void _handleLogin() async {
  final email = _emailController.text.trim();
  final password = _passwordController.text;

  if (email.isEmpty || password.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Por favor, ingresa correo y contraseña.'),
        backgroundColor: Colors.redAccent,
      ),
    );
    return;
  }

  try {
    // Intentar inicio de sesión con Firebase
    await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    // Si tiene éxito, navegar a home
    Navigator.pushReplacementNamed(context, '/home');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('¡Bienvenida a Calma360!'),
        backgroundColor: Color(0xFF8B4A6B),
      ),
    );
  } on FirebaseAuthException catch (e) {
    String message = 'Error al iniciar sesión';
    if (e.code == 'user-not-found') {
      message = 'Usuario no encontrado.';
    } else if (e.code == 'wrong-password') {
      message = 'Contraseña incorrecta.';
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
      ),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Ocurrió un error inesperado.'),
        backgroundColor: Colors.redAccent,
      ),
    );
  }
}


  void _navigateToRegister() {
    Navigator.pushNamed(context, '/register');
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}

enum DeviceType { smartwatch, phone, tv }
