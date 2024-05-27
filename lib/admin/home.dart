import 'package:flutter/material.dart';
import 'package:flutter_osavet_1/admin/addEvento.dart';
import 'package:flutter_osavet_1/admin/addnoticia.dart';
import 'package:flutter_osavet_1/usuarios/principalpage.dart';
import 'appointment.dart';
import 'medical_history.dart';
import 'billing.dart';
import 'internal_communication.dart';
import 'pet_profile.dart';
import 'calendar.dart';
import '../login.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("---OSAVET---"),
        backgroundColor: const Color(0xFFbdc3c7),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFd0e0eb),
                    Color.fromARGB(255, 137, 161, 181),
                    Color(0xFFd0e0eb),
                  ],
                ),
              ),
              child: Text(
                'Opciones',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Gestión de citas'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AppointmentScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Historial médico'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => MedicalHistoryScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.attach_money),
              title: const Text('Facturación'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const BillingScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.pets),
              title: const Text('Perfil individual de mascotas'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => PetProfileScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Calendario de vacunación'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const VaccinationCalendarScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('Agregar Noticia'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddNoticia()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('Agregar Evento'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddEvento()),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Cerrar sesión'),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const PrincipalPage()),
                );
              },
            ),
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFd0e0eb),
              Color.fromARGB(255, 137, 161, 181),
              Color(0xFFd0e0eb),
            ],
          ),
        ),
      ),
    );
  }
}