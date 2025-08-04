import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // Lista de días que representan el periodo marcado (último + próximo)
  List<DateTime> periodoDias = [];

  // Próxima fecha estimada para el siguiente periodo
  DateTime? proximaFechaEstimada;

  // Estados de ánimo y síntomas (ejemplo)
  final List<String> estadosDeAnimo = ['Feliz', 'Triste', 'Ansioso', 'Calmado'];
  final List<String> sintomasDisponibles = ['Dolor de cabeza', 'Cansancio', 'Náuseas'];

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Servicio hipotético que debes tener implementado
  late PeriodService _periodService;

  @override
  void initState() {
    super.initState();
    _periodService = PeriodService(_auth.currentUser!.uid, _db);
    _cargarDatosPrevios();
  }

  Future<void> _cargarDatosPrevios() async {
    await _periodService.initNotifications();

    final lastPeriodDate = await _periodService.getLastPeriodDate();
    final cycleLengths = await _periodService.getCycleLengths();
    final averageCycleLength = await _periodService.getAverageCycleLength();

    if (lastPeriodDate != null) {
      // Limpiar días previos
      periodoDias.clear();

      // Marcar los 5 días del último periodo
      periodoDias.addAll(List.generate(
        5,
        (index) => lastPeriodDate.add(Duration(days: index)),
      ));

      // Predecir próximo periodo basado en el ciclo promedio
      proximaFechaEstimada = lastPeriodDate.add(Duration(days: averageCycleLength));

      // Marcar los 5 días del próximo periodo estimado
      periodoDias.addAll(List.generate(
        5,
        (index) => proximaFechaEstimada!.add(Duration(days: index)),
      ));

      // Programar notificaciones para el próximo periodo
      await _periodService.schedulePeriodNotifications(proximaFechaEstimada!.toIso8601String());
    } else {
      periodoDias.clear();
      proximaFechaEstimada = null;
    }

    setState(() {});
  }

  bool _esDiaDePeriodo(DateTime day) {
    return periodoDias.any((d) =>
        d.year == day.year && d.month == day.month && d.day == day.day);
  }

  void _mostrarDialogoEstadoYSintomas(DateTime day) {
    showDialog(
      context: context,
      builder: (context) {
        String? estadoSeleccionado;
        List<String> sintomasSeleccionados = [];

        return AlertDialog(
          title: Text('Registrar estado y síntomas - ${day.toLocal().toIso8601String().split('T').first}'),
          content: StatefulBuilder(
            builder: (context, setDialogState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButton<String>(
                      hint: Text('Selecciona estado de ánimo'),
                      value: estadoSeleccionado,
                      items: estadosDeAnimo
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (val) {
                        setDialogState(() => estadoSeleccionado = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    Text('Selecciona síntomas'),
                    ...sintomasDisponibles.map((sintoma) {
                      return CheckboxListTile(
                        title: Text(sintoma),
                        value: sintomasSeleccionados.contains(sintoma),
                        onChanged: (checked) {
                          setDialogState(() {
                            if (checked == true) {
                              sintomasSeleccionados.add(sintoma);
                            } else {
                              sintomasSeleccionados.remove(sintoma);
                            }
                          });
                        },
                      );
                    }),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (estadoSeleccionado != null) {
                  await _periodService.guardarEstadoYSintomas(
                    fecha: day,
                    estado: estadoSeleccionado!,
                    sintomas: sintomasSeleccionados,
                  );
                  Navigator.pop(context);
                }
              },
              child: const Text('Guardar'),
            )
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Calendario de periodo')),
      body: TableCalendar(
        focusedDay: _focusedDay,
        firstDay: DateTime.utc(2010, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        selectedDayPredicate: (day) =>
            _selectedDay != null &&
            day.year == _selectedDay!.year &&
            day.month == _selectedDay!.month &&
            day.day == _selectedDay!.day,
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });

          // Solo mostrar diálogo si NO es día de periodo
          if (!_esDiaDePeriodo(selectedDay)) {
            _mostrarDialogoEstadoYSintomas(selectedDay);
          }
        },
        calendarBuilders: CalendarBuilders(
          defaultBuilder: (context, day, focusedDay) {
            if (_esDiaDePeriodo(day)) {
              return Container(
                margin: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.pinkAccent,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text('${day.day}', style: const TextStyle(color: Colors.white)),
              );
            }
            return null;
          },
        ),
      ),
    );
  }
}

// Servicio ejemplo que conecta con Firestore y gestiona periodos y estados

class PeriodService {
  final String userId;
  final FirebaseFirestore _db;

  PeriodService(this.userId, this._db);

  Future<void> initNotifications() async {
    // Aquí inicializarías las notificaciones locales
  }

  Future<DateTime?> getLastPeriodDate() async {
    final doc = await _db.collection('users').doc(userId).get();
    if (doc.exists && doc.data()!.containsKey('lastPeriodDate')) {
      final timestamp = doc.data()!['lastPeriodDate'] as Timestamp;
      return timestamp.toDate();
    }
    return null;
  }

  Future<List<int>> getCycleLengths() async {
    final doc = await _db.collection('users').doc(userId).get();
    if (doc.exists && doc.data()!.containsKey('cycleLengths')) {
      final List<dynamic> rawList = doc.data()!['cycleLengths'];
      return rawList.map((e) => e as int).toList();
    }
    return [];
  }

  Future<int> getAverageCycleLength() async {
    final cycleLengths = await getCycleLengths();
    if (cycleLengths.isEmpty) return 28; // valor por defecto si no hay datos
    final total = cycleLengths.reduce((a, b) => a + b);
    return (total / cycleLengths.length).round();
  }

  Future<void> schedulePeriodNotifications(String nextPeriodIso) async {
    // Aquí programarías notificaciones
  }

  Future<void> guardarEstadoYSintomas({
    required DateTime fecha,
    required String estado,
    required List<String> sintomas,
  }) async {
    final docRef = _db
        .collection('users')
        .doc(userId)
        .collection('dailyRecords')
        .doc(fecha.toIso8601String().split('T').first);
    await docRef.set({
      'estadoDeAnimo': estado,
      'sintomas': sintomas,
      'fecha': fecha,
    });
  }
}
