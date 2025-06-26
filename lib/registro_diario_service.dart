import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RegistroDiarioService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Guarda el estado de ánimo y síntomas del día actual en la colección periodHistory
  Future<void> guardarRegistroDiario(DateTime fecha, String estadoAnimo, List<String> sintomas) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('Usuario no autenticado');

    await _firestore.collection('periodHistory').add({
      'userId': uid,
      'startDate': fecha,
      'endDate': fecha, // Puedes ajustar si hay más de un día
      'mood': estadoAnimo,
      'symptoms': sintomas,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Este método queda opcional: puedes usarlo si decides mostrar los registros antiguos
  Stream<List<RegistroDiario>> obtenerRegistrosDiarios() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('Usuario no autenticado');

    return _firestore.collection('usuarios').doc(uid).collection('registros')
        .orderBy('fecha', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            return RegistroDiario(
              fecha: (data['fecha'] as Timestamp).toDate(),
              estadoAnimo: data['estadoAnimo'] ?? '',
              sintomas: List<String>.from(data['sintomas'] ?? []),
            );
          }).toList();
        });
  }
}

class RegistroDiario {
  final DateTime fecha;
  final String estadoAnimo;
  final List<String> sintomas;

  RegistroDiario({
    required this.fecha,
    required this.estadoAnimo,
    required this.sintomas,
  });
}
