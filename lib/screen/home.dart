import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  final List<DateTime> periodoDias = [
    DateTime.utc(2025, 5, 24),
    DateTime.utc(2025, 5, 25),
    DateTime.utc(2025, 5, 26),
    DateTime.utc(2025, 5, 27),
  ];

  final Map<DateTime, String> estadosDeAnimo = {
    DateTime.utc(2025, 5, 24): "😐",
    DateTime.utc(2025, 5, 25): "😢",
    DateTime.utc(2025, 5, 26): "🙂",
    DateTime.utc(2025, 5, 27): "😄",
  };

  bool _esDiaDePeriodo(DateTime day) {
    return periodoDias.any((d) =>
        d.year == day.year && d.month == day.month && d.day == day.day);
  }

  String? _estadoDeAnimoDelDia(DateTime day) {
    for (var entry in estadosDeAnimo.entries) {
      if (entry.key.year == day.year &&
          entry.key.month == day.month &&
          entry.key.day == day.day) {
        return entry.value;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final ancho = MediaQuery.of(context).size.width;
    final alto = MediaQuery.of(context).size.height;

    // def tipos de dispositivo
    final bool esSmartwatch = ancho <= 400 && alto <= 500;
    final bool esTV = ancho >= 1000 && alto >= 600;

    // config responsiva
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
    icon: const Icon(Icons.logout),
    tooltip: 'Cerrar sesión',
    onPressed: () {
      // Lógica para cerrar sesión (por ejemplo, volver a la pantalla de login)
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
            SizedBox(height: paddingAll / 2),
            Text(
              'Animo del dia',
              style: TextStyle(fontSize: headerFontSize, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: paddingAll / 4),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: paddingAll,
              children: [
                _leyenda('Periodo', Colors.pink[100]!, leyendaBox, leyendaFont),
                _leyenda('Hoy', Colors.pinkAccent, leyendaBox, leyendaFont),
              ],
            ),
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
}
