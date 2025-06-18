import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> registrarUsuario({
    required String nombre,
    required String correo,
    required String contrasena,
    required DateTime ultimoPeriodo,
  }) async {
    UserCredential cred = await _auth.createUserWithEmailAndPassword(
      email: correo,
      password: contrasena,
    );

    await _db.collection('usuarios').doc(cred.user!.uid).set({
      'nombre': nombre,
      'correo': correo,
      'ultimoPeriodo': ultimoPeriodo.toIso8601String(),
    });
  }
}
  