// ignore_for_file: use_build_context_synchronously

import 'package:calma360/period_service.dart';
import 'package:calma360/registro_diario_service.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  List<DateTime> periodoDias = [];

  final Map<DateTime, String> estadosDeAnimo = {};
  final Map<DateTime, List<String>> sintomasPorDia = {};

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
    final hoy = DateTime.now();
    if (_esDiaDePeriodo(hoy)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mostrarDialogoEstadoYSintomas(hoy);
      });
    }
  }

  Future<void> _cargarDatosPrevios() async {
    DateTime? lastPeriodDate = await _periodService.getLastPeriodDate();
    List<int> cycleLengths = await _periodService.getCycleLengths();
    double averageCycleLength = _periodService.getAverageCycleLength(cycleLengths);

    if (lastPeriodDate != null) {
      periodoDias = List.generate(7, (index) => lastPeriodDate.add(Duration(days: index)));

      DateTime? nextPeriodDate = _periodService.predictNextPeriodDate(lastPeriodDate, averageCycleLength);

      if (nextPeriodDate != null) {
        await _periodService.schedulePeriodNotifications(nextPeriodDate.toIso8601String());
      }
    } else {
      periodoDias.clear();
    }

    // Escuchar los registros diarios y actualizar mapas de ánimo y síntomas
    _registroDiarioService.obtenerRegistrosDiarios().listen((registros) {
      setState(() {
        estadosDeAnimo.clear();
        sintomasPorDia.clear();
        for (var registro in registros) {
          estadosDeAnimo[registro.fecha] = registro.estadoAnimo;
          sintomasPorDia[registro.fecha] = registro.sintomas;
        }
      });
    });

    setState(() {});
  }

  bool _esDiaDePeriodo(DateTime day) {
    return periodoDias.any((d) =>
        d.year == day.year && d.month == day.month && d.day == day.day);
  }

  String? _estadoDeAnimoDelDia(DateTime day) {
    for (var entry in estadosDeAnimo.entries) {
      if (_esMismoDia(entry.key, day)) return entry.value;
    }
    return null;
  }

  bool _esMismoDia(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _mostrarDialogoEstadoYSintomas(DateTime dia) {
    String? estadoSeleccionado = _estadoDeAnimoDelDia(dia);
    List<String> sintomasSeleccionados = sintomasPorDia[dia]?.toList() ?? [];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              scrollable: true,
              title: Text('¿Cómo te sientes hoy? (${DateFormat('dd/MM/yyyy').format(dia)})'),
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
                      children: ['😢', '😐', '🙂', '😄'].map((emoji) {
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
                                    ? Colors.pink
                                    : Colors.grey,
                                width: 2,
                              ),
                            ),
                            child: Text(emoji, style: const TextStyle(fontSize: 32)),
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
                    setState(() {
                      if (estadoSeleccionado != null) {
                        estadosDeAnimo[dia] = estadoSeleccionado!;
                      }
                      sintomasPorDia[dia] = sintomasSeleccionados;
                    });

                    // Guardar el registro diario en Firestore
                    await _registroDiarioService.guardarRegistroDiario(dia, estadoSeleccionado ?? '', sintomasSeleccionados);

                    // Guardar último periodo y duración promedio del ciclo localmente
                    await _periodService.saveLastPeriodDate(dia);
                    await _periodService.saveCycleLengths([28]); // Aquí ajusta la lógica real si tienes múltiples duraciones

                    await _cargarDatosPrevios(); // Refresca datos y notificaciones

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
        titleTextStyle: TextStyle(fontSize: headerFontSize, fontWeight: FontWeight.bold),
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
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
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
                  final animo = _estadoDeAnimoDelDia(day);
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: rowHeight * 0.8,
                        height: rowHeight * 0.8,
                        decoration: BoxDecoration(
                          color: esPeriodo ? Colors.pink[100] : null,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${day.day}',
                            style: TextStyle(
                              fontSize: dayFontSize,
                              color: esPeriodo ? Colors.pink[900] : Colors.black87,
                            ),
                          ),
                        ),
                      ),
                      if (animo != null)
                        Positioned(
                          bottom: 2,
                          child: Text(animo, style: TextStyle(fontSize: emojiFontSize)),
                        ),
                    ],
                  );
                },
                todayBuilder: (context, day, _) {
                  final esPeriodo = _esDiaDePeriodo(day);
                  final animo = _estadoDeAnimoDelDia(day);
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: rowHeight * 0.8,
                        height: rowHeight * 0.8,
                        decoration: BoxDecoration(
                          color: esPeriodo ? Colors.pink[100] : Colors.pink[200],
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${day.day}',
                            style: TextStyle(
                              fontSize: dayFontSize,
                              color: esPeriodo ? Colors.pink[900] : Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      if (animo != null)
                        Positioned(
                          bottom: 2,
                          child: Text(animo, style: TextStyle(fontSize: emojiFontSize)),
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
    final diasConInfo = <DateTime>[];
    
    diasConInfo.addAll(estadosDeAnimo.keys);
    diasConInfo.addAll(sintomasPorDia.keys);
    diasConInfo.addAll(periodoDias);
    
    final diasUnicos = diasConInfo.toSet().toList();
    diasUnicos.sort();
    
    if (diasUnicos.isEmpty) {
      return Column(
        children: [
          Text(
            'Información guardada',
            style: TextStyle(
                fontSize: headerFontSize, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: paddingAll / 2),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('No hay información guardada aún. Selecciona un día en el calendario para agregar información.'),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Información guardada',
          style: TextStyle(
              fontSize: headerFontSize, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: paddingAll / 2),
        ...diasUnicos.map((dia) => _mostrarInfoDelDia(dia)),
      ],
    );
  }

  Widget _mostrarInfoDelDia(DateTime dia) {
    final animo = _estadoDeAnimoDelDia(dia);
    final sintomas = sintomasPorDia[dia] ?? [];
    final esPeriodo = _esDiaDePeriodo(dia);

    if (animo == null && sintomas.isEmpty && !esPeriodo) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('dd/MM/yyyy').format(dia),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (esPeriodo)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.pink[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '🩸 Período',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.pink[800],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            if (animo != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text('Estado de ánimo: ', style: TextStyle(fontWeight: FontWeight.w500)),
                  Text(animo, style: const TextStyle(fontSize: 20)),
                ],
              ),
            ],
            if (sintomas.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text('Síntomas:', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: sintomas.map((sintoma) => Chip(
                  label: Text(sintoma, style: const TextStyle(fontSize: 12)),
                  backgroundColor: Colors.pink[50],
                  labelStyle: TextStyle(color: Colors.pink[800]),
                )).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
