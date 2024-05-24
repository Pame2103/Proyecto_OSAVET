import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

class AppointmentScreen extends StatefulWidget {
  const AppointmentScreen({Key? key}) : super(key: key);

  @override
  _AppointmentScreenState createState() => _AppointmentScreenState();
}

class _AppointmentScreenState extends State<AppointmentScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _petNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  TimeOfDay? _selectedTime;
  final List<Map<String, String>> _appointments = [];

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _saveAppointment() async {
    if (_formKey.currentState!.validate() && _selectedTime != null) {
      final appointment = {
        'name': _nameController.text,
        'petName': _petNameController.text,
        'phone': _phoneController.text,
        'date': _selectedDay.toIso8601String(),
        'time': _selectedTime!.format(context),
      };

      setState(() {
        _appointments.add(appointment);
      });

      _nameController.clear();
      _petNameController.clear();
      _phoneController.clear();
      _selectedTime = null;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cita guardada con éxito')),
      );
    }
  }

  List<Map<String, String>> _getAppointmentsForSelectedDay() {
    return _appointments.where((appointment) {
      return isSameDay(DateTime.parse(appointment['date']!), _selectedDay);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Citas Veterinaria'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            TableCalendar(
              focusedDay: _focusedDay,
              firstDay: DateTime(2020),
              lastDay: DateTime(2030),
              calendarFormat: _calendarFormat,
              selectedDayPredicate: (day) {
                return isSameDay(_selectedDay, day);
              },
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              onFormatChanged: (format) {
                setState(() {
                  _calendarFormat = format;
                });
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration:
                          const InputDecoration(labelText: 'Nombre del dueño'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingrese el nombre del dueño';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: _petNameController,
                      decoration: const InputDecoration(
                          labelText: 'Nombre de la mascota'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingrese el nombre de la mascota';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(labelText: 'Teléfono'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingrese el teléfono';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => _selectTime(context),
                      child: const Text(
                        'Seleccionar Hora',
                        style: TextStyle(color: Colors.blue),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _saveAppointment,
                      child: const Text('Guardar Cita'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: _getAppointmentsForSelectedDay().map((appointment) {
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    child: ListTile(
                      title: Text(
                          '${appointment['name']} - ${appointment['petName']}'),
                      subtitle: Text(
                        'Tel: ${appointment['phone']} - ${DateTime.parse(appointment['date']!).toLocal().toIso8601String().split('T').first} a las ${appointment['time']}',
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}