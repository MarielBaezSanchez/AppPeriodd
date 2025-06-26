import 'package:calma360/period_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PeriodPredictionCard extends StatelessWidget {
  final String userId;
  final PeriodService periodService;

  const PeriodPredictionCard({
    super.key,
    required this.userId,
    required this.periodService,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: periodService.getCurrentPrediction(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return const Text(
            'No hay predicción disponible',
            style: TextStyle(color: Colors.grey),
          );
        }

        final data = snapshot.data!;
        final DateTime startDate = data['nextPeriodStart'] as DateTime;
        final int days = data['daysRemaining'] as int;
        final int duration = data['durationDays'] as int;
        final DateTime endDate = startDate.add(Duration(days: duration - 1));

        return Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          color: const Color(0xFFFFEBEF),
          elevation: 4,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Próximo periodo',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.pink[800],
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                Text(
                  '${DateFormat('dd/MM/yyyy').format(startDate)} - ${DateFormat('dd/MM/yyyy').format(endDate)}',
                  style: const TextStyle(fontSize: 16, color: Colors.black87),
                ),
                const SizedBox(height: 12),
                Text(
                  days > 0
                      ? 'Faltan $days día${days == 1 ? '' : 's'}'
                      : 'Tu periodo debería comenzar hoy',
                  style: TextStyle(
                    fontSize: 16,
                    color: days <= 3 ? Colors.redAccent : Colors.pinkAccent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
