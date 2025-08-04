import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      debugPrint('❌ Usuario no autenticado');
      return const Scaffold(
        body: Center(
          child: Text('Debes iniciar sesión para ver el historial.'),
        ),
      );
    }

    debugPrint('✅ Usuario autenticado con UID: $userId');

    return Scaffold(
      appBar: AppBar(title: const Text('Historial')),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('periodHistory')
                .where('userId', isEqualTo: userId)
                .orderBy('createdAt', descending: true)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Error al cargar historial.'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No hay registros disponibles.'));
          }

          final groupedEntries = groupBy(snapshot.data!.docs, (doc) {
            final createdAt = (doc['createdAt'] as Timestamp).toDate();
            return DateFormat('MMMM yyyy', 'es').format(createdAt);
          });

          return ListView.builder(
            itemCount: groupedEntries.length,
            itemBuilder: (context, index) {
              final month = groupedEntries.keys.elementAt(index);
              final entries = groupedEntries[month]!;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      month.toUpperCase(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  ...entries.map((doc) {
                    final data = doc.data()! as Map<String, dynamic>;
                    final createdAt =
                        (data['createdAt'] as Timestamp?)?.toDate() ??
                        DateTime.now();
                    final mood = data['mood'] ?? '';
                    final symptoms = List<String>.from(data['symptoms'] ?? []);

                    return ListTile(
                      leading: const Icon(Icons.favorite, color: Colors.pink),
                      title: Text(DateFormat('dd/MM/yyyy').format(createdAt)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Estado de ánimo: $mood'),
                          if (symptoms.isNotEmpty)
                            Text('Síntomas: ${symptoms.join(', ')}'),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              );
            },
          );
        },
      ),
    );
  }
}