import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddNoticia extends StatefulWidget {
  const AddNoticia({super.key});

  @override
  _AddNoticiaState createState() => _AddNoticiaState();
}

class _AddNoticiaState extends State<AddNoticia> {
  final TextEditingController _tituloController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();
  final TextEditingController _fechaController = TextEditingController();
  final TextEditingController _horaController = TextEditingController();
  bool _isEditing = false;
  String? _editingDocId;

  @override
  void dispose() {
    _tituloController.dispose();
    _descripcionController.dispose();
    _fechaController.dispose();
    _horaController.dispose();
    super.dispose();
  }

  void _eliminarNoticia(String docId) {
    FirebaseFirestore.instance.collection('noticias').doc(docId).delete();
  }

  void _editarNoticia(String docId, Map<String, dynamic> data) {
    _tituloController.text = data['titulo'];
    _descripcionController.text = data['descripcion'];
    _fechaController.text = data['fecha'];
    _horaController.text = data['hora'];
    _isEditing = true;
    _editingDocId = docId;
  }

  void _resetFields() {
    _tituloController.clear();
    _descripcionController.clear();
    _fechaController.clear();
    _horaController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Agregar Noticia'),
          backgroundColor: const Color(0xFFbdc3c7),
        ),
        body: DecoratedBox(
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
            child: Column(children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Agregar nueva noticia',
                      style: TextStyle(
                        fontSize: 20.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    TextFormField(
                      controller: _tituloController,
                      decoration: InputDecoration(
                        hintText: 'Título',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    TextFormField(
                      controller: _descripcionController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Descripción',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    TextFormField(
                      controller: _fechaController,
                      decoration: InputDecoration(
                        hintText: 'Fecha (dd/mm/yyyy)',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    TextFormField(
                      controller: _horaController,
                      decoration: InputDecoration(
                        hintText: 'Hora (hh:mm)',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    ElevatedButton(
                      onPressed: () {
                        if (_isEditing) {
                          // Actualizar noticia
                          FirebaseFirestore.instance
                              .collection('noticias')
                              .doc(_editingDocId)
                              .update({
                            'titulo': _tituloController.text.trim(),
                            'descripcion': _descripcionController.text.trim(),
                            'fecha': _fechaController.text.trim(),
                            'hora': _horaController.text.trim(),
                          });
                          _resetFields();
                          _isEditing = false;
                          _editingDocId = null;
                        } else {
                          // Agregar nueva noticia
                          final titulo = _tituloController.text.trim();
                          final descripcion =
                              _descripcionController.text.trim();
                          final fecha = _fechaController.text.trim();
                          final hora = _horaController.text.trim();

                          if (titulo.isNotEmpty &&
                              descripcion.isNotEmpty &&
                              fecha.isNotEmpty &&
                              hora.isNotEmpty) {
                            FirebaseFirestore.instance
                                .collection('noticias')
                                .add({
                              'titulo': titulo,
                              'descripcion': descripcion,
                              'fecha': fecha,
                              'hora': hora,
                            });
                            _resetFields();
                          }
                        }
                      },
                      child:
                          Text(_isEditing ? 'Actualizar' : 'Agregar noticia'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16.0),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('noticias')
                      .snapshots(),
                  builder: (BuildContext context,
                      AsyncSnapshot<QuerySnapshot> snapshot) {
                    // Manejo de errores
                    if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    }

                    // Mientras se cargan los datos, se muestra un indicador de progreso
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    // Una vez que los datos están listos, se construye la DataTable
                    return SingleChildScrollView(
                      child: DataTable(
                        columns: const [
                          DataColumn(
                              label: Text('Título',
                                  style: TextStyle(color: Colors.white))),
                          DataColumn(
                              label: Text('Descripción',
                                  style: TextStyle(color: Colors.white))),
                          DataColumn(
                              label: Text('Fecha',
                                  style: TextStyle(color: Colors.white))),
                          DataColumn(
                              label: Text('Hora',
                                  style: TextStyle(color: Colors.white))),
                          DataColumn(
                              label: Text('Acciones',
                                  style: TextStyle(color: Colors.white))),
                        ],
                        rows: snapshot.data!.docs.map((document) {
                          Map<String, dynamic>? data =
                              document.data() as Map<String, dynamic>?;
                          if (data != null) {
                            return DataRow(cells: [
                              DataCell(Text(data['titulo'] ?? '',
                                  style: const TextStyle(color: Colors.white),
                                  softWrap: true)),
                              DataCell(Text(data['descripcion'] ?? '',
                                  style: const TextStyle(color: Colors.white),
                                  softWrap: true)),
                              DataCell(Text(data['fecha'] ?? '',
                                  style: const TextStyle(color: Colors.white),
                                  softWrap: true)),
                              DataCell(Text(data['hora'] ?? '',
                                  style: const TextStyle(color: Colors.white),
                                  softWrap: true)),
                              DataCell(Row(children: [
                                IconButton(
                                    icon: const Icon(Icons.edit,
                                        color: Colors.white),
                                    onPressed: () =>
                                        _editarNoticia(document.id, data)),
                                IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.white),
                                    onPressed: () =>
                                        _eliminarNoticia(document.id))
                              ])),
                            ]);
                          } else {
                            return const DataRow(cells: [
                              DataCell(Text('Error en los datos',
                                  style: TextStyle(color: Colors.white))),
                              DataCell(Text('')),
                              DataCell(Text('')),
                              DataCell(Text('')),
                              DataCell(Text('')),
                            ]);
                          }
                        }).toList(),
                      ),
                    );
                  },
                ),
              )
            ])));
  }
}
