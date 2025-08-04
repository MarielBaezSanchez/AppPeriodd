import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Historial')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('usuarios')
            .doc(userId)
            .collection('registros')
            .orderBy('fecha', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final groupedEntries = groupBy(snapshot.data!.docs, (doc) {
            final date = (doc['fecha'] as Timestamp).toDate();
            return DateFormat('MMMM yyyy', 'es').format(date);
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
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  ...entries.map((doc) {
                    final data = doc.data()! as Map<String, dynamic>;
                    final fecha = (data['fecha'] as Timestamp).toDate();
                    final estadoAnimo = data['estadoAnimo'] ?? '';
                    final sintomas = List<String>.from(data['sintomas'] ?? []);

                    return ListTile(
                      title: Text(DateFormat('dd/MM/yyyy').format(fecha)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Estado de ánimo: $estadoAnimo'),
                          if (sintomas.isNotEmpty) Text('Síntomas: ${sintomas.join(', ')}'),
                        ],
                      ),
                    );
                  }),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
