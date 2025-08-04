import 'package:calma360/period_service.dart';
import 'package:calma360/registro_diario_service.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime? _ultimoPeriodo; // Fecha del último periodo guardada
  DateTime? _proximoPeriodo;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  List<DateTime> periodoDias = [];

  // Mapa donde clave = fecha sin hora, valor = Map con keys 'mood' y 'symptoms'
  final Map<DateTime, Map<String, dynamic>> registrosPorDia = {};

  final List<String> sintomasDisponibles = [
    'Alteración del sueño',
    'Cambios de humor',
    'Dolor pélvico',
    'Acné',
    'Alteración del apetito',
    'Bochornos',
    'Caída del cabello',
    'Cólicos',
    'Diarrea',
    'Distensión abdominal',
    'Dolor de cabeza',
    'Dolor de espalda baja',
    'Dolor en los senos',
    'Escalofríos',
    'Estreñimiento',
  ];

  final PeriodService _periodService = PeriodService();
  final RegistroDiarioService _registroDiarioService = RegistroDiarioService();

  @override
  void initState() {
    super.initState();
    _periodService.initNotifications();
    _cargarDatosPrevios();
    _cargarRegistrosFirestore();
  }

  Future<void> _cargarDatosPrevios() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    // Cargar fechaUltimoPeriodo guardada en Firestore en colección 'users', en caso de no existir, muestra un calendario para que el usuario ingrese la fecha
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();

    if (doc.exists && doc.data()?['fechaUltimoPeriodo'] != null) {
      Timestamp ts = doc.data()!['fechaUltimoPeriodo'];
      setState(() {
        _ultimoPeriodo = ts.toDate();
      });

      // Después de cargar último periodo, calcular próximo periodo
      _calcularProximoPeriodo();
    } else {
      // Si no hay fecha último periodo guardada, pedir al usuario que la ingrese
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _pedirFechaUltimoPeriodo();
      });
    }
  }

  Future<void> _pedirFechaUltimoPeriodo() async {
    DateTime ahora = DateTime.now();
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: ahora,
      firstDate: DateTime(2020),
      lastDate: ahora,
    );

    if (picked != null) {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .set({'fechaUltimoPeriodo': Timestamp.fromDate(picked)}, SetOptions(merge: true));

      setState(() {
        _ultimoPeriodo = picked;
      });

      // Luego recalculamos próximo periodo basándonos en este dato
      _calcularProximoPeriodo();
    }
  }

  void _calcularProximoPeriodo() {
    if (_ultimoPeriodo == null) return;

    // Tomamos el promedio de duración de ciclo si hay datos suficientes
    int promedioDiasCiclo = 28; // Valor por defecto

    if (periodoDias.length >= 2) {
      periodoDias.sort();
      List<int> diferencias = [];
      for (int i = 1; i < periodoDias.length; i++) {
        diferencias.add(periodoDias[i].difference(periodoDias[i - 1]).inDays);
      }
      promedioDiasCiclo = diferencias.reduce((a, b) => a + b) ~/ diferencias.length;
    }

    final calculo = _ultimoPeriodo!.add(Duration(days: promedioDiasCiclo));
    setState(() {
      _proximoPeriodo = calculo;
    });
  }

  // Carga registros de periodos y estados desde Firestore
  Future<void> _cargarRegistrosFirestore() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('periodHistory')
        .where('userId', isEqualTo: userId)
        .get();

    final Map<DateTime, Map<String, dynamic>> registros = {};
    final List<DateTime> fechasPeriodo = [];

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final createdAtTimestamp = data['createdAt'] as Timestamp?;
      if (createdAtTimestamp == null) continue;

      final fechaDia = DateUtils.dateOnly(createdAtTimestamp.toDate().toLocal());
      final mood = data['mood'] ?? '';
      final symptoms = List<String>.from(data['symptoms'] ?? []);

      registros[fechaDia] = {
        'mood': mood,
        'symptoms': symptoms,
      };

      if (mood == '🩸' || data['isPeriod'] == true) {
        fechasPeriodo.add(fechaDia);
      }
    }

    setState(() {
      registrosPorDia.clear();
      registrosPorDia.addAll(registros);
      periodoDias = fechasPeriodo;
    });

    // Recalcular próximo periodo basándonos en último periodo y datos actuales
    _calcularProximoPeriodo();
  }

  bool _esDiaDePeriodo(DateTime day) {
    return periodoDias.any(
      (d) => _esMismoDia(d, day),
    );
  }

  String? _estadoDeAnimoDelDia(DateTime day) {
    final registro = registrosPorDia[DateUtils.dateOnly(day)];
    if (registro == null) return null;
    final mood = registro['mood'] as String?;
    return mood?.isNotEmpty == true ? mood : null;
  }

  List<String> _sintomasDelDia(DateTime day) {
    final registro = registrosPorDia[DateUtils.dateOnly(day)];
    if (registro == null) return [];
    final symptoms = registro['symptoms'] as List<String>?;
    return symptoms ?? [];
  }

  bool _esMismoDia(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _mostrarDialogoEstadoYSintomas(DateTime dia) {
    String? estadoSeleccionado = _estadoDeAnimoDelDia(dia);
    List<String> sintomasSeleccionados = List<String>.from(_sintomasDelDia(dia));

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              scrollable: true,
              title: Text(
                '¿Cómo te sientes hoy? (${DateFormat('dd/MM/yyyy').format(dia)})',
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Selecciona tu estado de ánimo:'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 10,
                      children: ['🩸', '😊', '😐', '😞'].map((emoji) {
                        return GestureDetector(
                          onTap: () {
                            setDialogState(() {
                              estadoSeleccionado = emoji;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: estadoSeleccionado == emoji
                                  ? Colors.pink[100]
                                  : Colors.grey[100],
                              border: Border.all(
                                color: estadoSeleccionado == emoji
                                    ? Colors.pink!
                                    : Colors.grey,
                                width: 2,
                              ),
                            ),
                            child: Text(
                              emoji,
                              style: const TextStyle(fontSize: 32),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    const Text('Selecciona los síntomas que presentas:'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: sintomasDisponibles.map((sintoma) {
                        final estaSeleccionado = sintomasSeleccionados.contains(sintoma);
                        return FilterChip(
                          label: Text(sintoma),
                          selected: estaSeleccionado,
                          onSelected: (valor) {
                            setDialogState(() {
                              if (valor) {
                                sintomasSeleccionados.add(sintoma);
                              } else {
                                sintomasSeleccionados.remove(sintoma);
                              }
                            });
                          },
                          selectedColor: Colors.pink[100],
                          checkmarkColor: Colors.pink[800],
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: const Text('Cancelar'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: const Text('Guardar'),
                  onPressed: () async {
                    final userId = FirebaseAuth.instance.currentUser?.uid;
                    if (userId == null) return;

                    // Actualizar el mapa local
                    setState(() {
                      registrosPorDia[DateUtils.dateOnly(dia)] = {
                        'mood': estadoSeleccionado ?? '',
                        'symptoms': sintomasSeleccionados,
                      };

                      if (estadoSeleccionado == '🩸') {
                        if (!periodoDias.any((d) => _esMismoDia(d, dia))) {
                          periodoDias.add(DateUtils.dateOnly(dia));
                        }
                      } else {
                        periodoDias.removeWhere((d) => _esMismoDia(d, dia));
                      }
                    });

                    // Guardar en Firestore (añadir nuevo documento)
                    await FirebaseFirestore.instance.collection('periodHistory').add({
                      'userId': userId,
                      'createdAt': Timestamp.fromDate(dia),
                      'mood': estadoSeleccionado ?? '',
                      'symptoms': sintomasSeleccionados,
                      'isPeriod': estadoSeleccionado == '🩸',
                    });

                    // Opcional: si guardas un nuevo día de periodo, actualizar también fecha último periodo
                    if (estadoSeleccionado == '🩸') {
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(userId)
                          .set({'fechaUltimoPeriodo': Timestamp.fromDate(dia)}, SetOptions(merge: true));

                      setState(() {
                        _ultimoPeriodo = dia;
                      });
                    }

                    // Actualizar próximos periodos
                    await _cargarRegistrosFirestore();

                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final ancho = MediaQuery.of(context).size.width;
    final alto = MediaQuery.of(context).size.height;

    final bool esSmartwatch = ancho <= 400 && alto <= 500;
    final bool esTV = ancho >= 1000 && alto >= 600;

    double rowHeight = esSmartwatch ? 28 : esTV ? 60 : 40;
    double daysOfWeekHeight = esSmartwatch ? 18 : esTV ? 30 : 20;
    double headerFontSize = esSmartwatch ? 12 : esTV ? 24 : 16;
    double dayFontSize = esSmartwatch ? 11 : esTV ? 22 : 14;
    double emojiFontSize = esSmartwatch ? 10 : esTV ? 20 : 12;
    double leyendaBox = esSmartwatch ? 12 : esTV ? 24 : 16;
    double leyendaFont = esSmartwatch ? 10 : esTV ? 20 : 12;
    double paddingAll = esSmartwatch ? 8 : esTV ? 24 : 16;
    double? toolbarH = esSmartwatch ? 30 : esTV ? 80 : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendario Menstrual'),
        backgroundColor: Colors.pinkAccent,
        toolbarHeight: toolbarH,
        titleTextStyle: TextStyle(
          fontSize: headerFontSize,
          fontWeight: FontWeight.bold,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Ver historial',
            onPressed: () {
              Navigator.pushNamed(context, '/historialScreen');
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(paddingAll),
        child: Column(
          children: [
            TableCalendar(
              focusedDay: _focusedDay,
              firstDay: DateTime.utc(2020),
              lastDay: DateTime.utc(2030),
              rowHeight: rowHeight,
              daysOfWeekHeight: daysOfWeekHeight,
              headerStyle: HeaderStyle(
                titleCentered: true,
                formatButtonVisible: false,
                titleTextStyle: TextStyle(fontSize: headerFontSize),
              ),
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: Colors.pink[200],
                  shape: BoxShape.circle,
                ),
                selectedDecoration: const BoxDecoration(
                  color: Colors.deepPurple,
                  shape: BoxShape.circle,
                ),
              ),
              selectedDayPredicate: (day) => _selectedDay != null && _esMismoDia(day, _selectedDay!),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });

                _mostrarDialogoEstadoYSintomas(selectedDay);
              },
              calendarBuilders: CalendarBuilders(
                defaultBuilder: (context, day, _) {
                  final esPeriodo = _esDiaDePeriodo(day);
                  final esProximoPeriodo =
                      _proximoPeriodo != null && _esMismoDia(day, _proximoPeriodo!);
                  final tieneRegistro = registrosPorDia.containsKey(DateUtils.dateOnly(day));
                  final animo = _estadoDeAnimoDelDia(day);

                  Color? bgColor;
                  Color textColor = Colors.black87;

                  if (esPeriodo) {
                    bgColor = Colors.pink[100];
                    textColor = Colors.pink[900]!;
                  } else if (esProximoPeriodo) {
                    bgColor = Colors.lightBlue[100];
                    textColor = Colors.blue[900]!;
                  } else if (tieneRegistro) {
                    bgColor = Colors.deepPurple[100];
                    textColor = Colors.deepPurple[900]!;
                  }

                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: rowHeight * 0.8,
                        height: rowHeight * 0.8,
                        decoration: BoxDecoration(
                          color: bgColor,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${day.day}',
                            style: TextStyle(
                              fontSize: dayFontSize,
                              color: textColor,
                            ),
                          ),
                        ),
                      ),
                      if (animo != null)
                        Positioned(
                          bottom: 2,
                          child: Text(
                            animo,
                            style: TextStyle(fontSize: emojiFontSize),
                          ),
                        ),
                    ],
                  );
                },
                todayBuilder: (context, day, _) {
                  final esPeriodo = _esDiaDePeriodo(day);
                  final esProximoPeriodo =
                      _proximoPeriodo != null && _esMismoDia(day, _proximoPeriodo!);
                  final tieneRegistro = registrosPorDia.containsKey(DateUtils.dateOnly(day));
                  final animo = _estadoDeAnimoDelDia(day);

                  Color bgColor = Colors.pink[200]!;
                  Color textColor = Colors.white;

                  if (esPeriodo) {
                    bgColor = Colors.pink[100]!;
                    textColor = Colors.pink[900]!;
                  } else if (esProximoPeriodo) {
                    bgColor = Colors.lightBlue[300]!;
                    textColor = Colors.blue[900]!;
                  } else if (tieneRegistro) {
                    bgColor = Colors.deepPurple[300]!;
                    textColor = Colors.white;
                  }

                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: rowHeight * 0.8,
                        height: rowHeight * 0.8,
                        decoration: BoxDecoration(
                          color: bgColor,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${day.day}',
                            style: TextStyle(
                              fontSize: dayFontSize,
                              color: textColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      if (animo != null)
                        Positioned(
                          bottom: 2,
                          child: Text(
                            animo,
                            style: TextStyle(fontSize: emojiFontSize),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
            SizedBox(height: paddingAll),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: paddingAll,
              children: [
                _leyenda('Periodo', Colors.pink[100]!, leyendaBox, leyendaFont),
                _leyenda('Hoy', Colors.pink[200]!, leyendaBox, leyendaFont),
                _leyenda('Con registro', Colors.deepPurple[100]!, leyendaBox, leyendaFont),
                _leyenda('Proximo periodo', Colors.lightBlue[100]!, leyendaBox, leyendaFont),
              ],
            ),
            SizedBox(height: paddingAll),
            _mostrarInformacionGuardada(headerFontSize, paddingAll),
          ],
        ),
      ),
    );
  }

  Widget _leyenda(String texto, Color color, double boxSize, double fontSize) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: boxSize,
          height: boxSize,
          margin: EdgeInsets.only(right: boxSize * 0.2),
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        Text(texto, style: TextStyle(fontSize: fontSize)),
      ],
    );
  }

  Widget _mostrarInformacionGuardada(double headerFontSize, double paddingAll) {
    final diasConInfo = registrosPorDia.keys.toList();
    diasConInfo.addAll(periodoDias);
    final diasUnicos = diasConInfo.toSet().toList()..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Días con registro:', style: TextStyle(fontSize: headerFontSize, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...diasUnicos.map((dia) {
          final mood = _estadoDeAnimoDelDia(dia) ?? '';
          final symptoms = _sintomasDelDia(dia);
          return Padding(
            padding: EdgeInsets.only(bottom: paddingAll / 2),
            child: Text(
              '${DateFormat('dd/MM/yyyy').format(dia)} - Estado: $mood - Síntomas: ${symptoms.join(', ')}',
              style: const TextStyle(fontSize: 14),
            ),
          );
        }),
      ],
    );
  }
}
