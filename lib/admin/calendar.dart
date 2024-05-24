import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import 'models.dart';

class VaccinationCalendarScreen extends StatefulWidget {
  const VaccinationCalendarScreen({super.key});

  @override
  State<VaccinationCalendarScreen> createState() =>
      _VaccinationCalendarScreenState();
}

class _VaccinationCalendarScreenState extends State<VaccinationCalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<Cita>> _citas = {};

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _getCitas();
  }

  Future<void> _getCitas() async {
    final citasSnapshot = await _firestore.collection('citas').get();
    final citas =
        citasSnapshot.docs.map((doc) => Cita.fromJson(doc.data())).toList();
    setState(() {
      _citas = {
        for (var cita in citas)
          DateTime.parse(cita.fecha.toIso8601String()): [cita]
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendario de vacunación'),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFbdc3c7),
              Color(0xFF2c3e50),
              Color(0xFF3a6186),
            ],
          ),
        ),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              child: TableCalendar(
                firstDay: DateTime.utc(2023, 1, 1),
                lastDay: DateTime.utc(2025, 12, 31),
                focusedDay: _focusedDay,
                calendarFormat: _calendarFormat,
                selectedDayPredicate: (day) {
                  return isSameDay(_selectedDay, day);
                },
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                  _showCitaDialog(context, selectedDay);
                },
                onFormatChanged: (format) {
                  setState(() {
                    _calendarFormat = format;
                  });
                },
                onPageChanged: (focusedDay) {
                  _focusedDay = focusedDay;
                },
                calendarStyle: const CalendarStyle(
                  todayDecoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
                headerStyle: HeaderStyle(
                  formatButtonDecoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  formatButtonTextStyle: const TextStyle(
                    color: Colors.white,
                  ),
                ),
                eventLoader: _getEventsList,
              ),
            ),
            const SizedBox(height: 16.0),
            if (_selectedDay != null)
              Text(
                'Día seleccionado: ${_selectedDay!.toString().split(' ')[0]}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
            Expanded(
              child: ListView.builder(
                itemCount: _citas[_selectedDay]?.length ?? 0,
                itemBuilder: (context, index) {
                  final cita = _citas[_selectedDay]![index];
                  return ListTile(
                    title: Text(cita.descripcion ?? 'Sin descripción'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _editCita(cita),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _deleteCita(cita.id),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<dynamic> _getEventsList(DateTime day) {
    return _citas[day]
            ?.map(
              (cita) => {
                'date': cita.fecha,
                'title': cita.descripcion ??
                    'Sin descripción', // Proporciona un valor predeterminado en caso de que cita.descripcion sea nulo
                'mascotaId': cita.mascotaId,
              },
            )
            .toList() ??
        [];
  }

  Future<void> _showCitaDialog(BuildContext context, DateTime day) async {
    String descripcion = '';
    TimeOfDay? hora;
    Mascota? mascota;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StreamBuilder<QuerySnapshot>(
          stream: _firestore.collection('pets').snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const AlertDialog(
                title: Text('Cargando...'),
              );
            }

            final mascotas = snapshot.data!.docs
                .map(
                  (doc) => Mascota.fromJson(doc.data() as Map<String, dynamic>),
                )
                .toList();

            return StatefulBuilder(
              builder: (context, setState) {
                return AlertDialog(
                  title: const Text('Agregar Cita'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        onChanged: (text) => descripcion = text,
                        decoration: const InputDecoration(
                          hintText: 'Ingresa la descripción de la cita',
                        ),
                      ),
                      const SizedBox(height: 16.0),
                      ListTile(
                        title: const Text('Fecha'),
                        trailing: Text(
                          '${day.day}/${day.month}/${day.year}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      ListTile(
                        title: const Text('Hora'),
                        trailing: Text(
                          hora != null
                              ? '${hora?.format(context)}'
                              : 'Seleccionar hora',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        onTap: () async {
                          final selectedHora = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.now(),
                          );
                          if (selectedHora != null) {
                            setState(() {
                              hora = selectedHora;
                            });
                          }
                        },
                      ),
                      ListTile(
                        title: const Text('Mascota'),
                        trailing: Text(
                          (mascota?.name) ?? 'Seleccionar mascota',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        onTap: () async {
                          final selectedMascota = await showDialog<Mascota>(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text('Seleccionar Mascota'),
                                content: SizedBox(
                                  width: double.maxFinite,
                                  child: ListView.builder(
                                    shrinkWrap: true,
                                    itemCount: mascotas.length,
                                    itemBuilder: (context, index) {
                                      final mascotaObj = mascotas[index];
                                      return ListTile(
                                        title: Text(mascotaObj.name),
                                        onTap: () {
                                          Navigator.pop(context, mascotaObj);
                                        },
                                      );
                                    },
                                  ),
                                ),
                              );
                            },
                          );
                          if (selectedMascota != null) {
                            setState(() {
                              mascota = selectedMascota;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                    TextButton(
                      onPressed: () {
                        if (descripcion.isNotEmpty &&
                            hora != null &&
                            mascota != null) {
                          _addCita(day, descripcion, hora!, mascota!);
                        }
                        Navigator.pop(context);
                      },
                      child: const Text('Agregar'),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _addCita(DateTime fecha, String descripcion, TimeOfDay hora,
      Mascota mascota) async {
    final cita = Cita(
      id: _firestore.collection('citas').doc().id,
      fecha:
          DateTime(fecha.year, fecha.month, fecha.day, hora.hour, hora.minute),
      descripcion: descripcion,
      mascotaId: mascota.id,
    );
    await _firestore.collection('citas').doc(cita.id).set(cita.toJson());
    setState(() {
      _citas[fecha] = [..._citas[fecha] ?? [], cita];
    });
  }

  Future<void> _deleteCita(String id) async {
    await _firestore.collection('citas').doc(id).delete();
    setState(() {
      _citas.removeWhere((key, value) => value.any((cita) => cita.id == id));
    });
  }

  Future<void> _editCita(Cita cita) async {
    String? descripcion = cita.descripcion;
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Editar Cita'),
          content: TextField(
            onChanged: (text) => descripcion = text,
            decoration: const InputDecoration(
              hintText: 'Ingresa la nueva descripción de la cita',
            ),
            controller: TextEditingController(text: cita.descripcion),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                if (descripcion!.isNotEmpty) {
                  _updateCita(cita.id, cita.fecha, descripcion!);
                }
                Navigator.pop(context);
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateCita(
      String id, DateTime fecha, String descripcion) async {
    final cita = Cita(
      id: id,
      fecha: fecha,
      descripcion: descripcion,
      mascotaId: _citas[fecha]!.firstWhere((c) => c.id == id).mascotaId,
    );
    await _firestore.collection('citas').doc(id).update(cita.toJson());
    setState(() {
      _citas[fecha] = [..._citas[fecha]!.where((c) => c.id != id), cita];
    });
  }
}
