import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class Pet {
  final String name;
  final String type;
  final int age;
  final String ownerName;
  final String ownerPhone;
  final String photoUrl;
  final String medicalConditions;
  final String allergies;
  final String currentMedications;
  final String vaccinations;
  final String id;

  Pet({
    required this.name,
    required this.type,
    required this.age,
    required this.ownerName,
    required this.ownerPhone,
    required this.photoUrl,
    required this.medicalConditions,
    required this.allergies,
    required this.currentMedications,
    required this.vaccinations,
    required this.id,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type,
      'age': age,
      'ownerName': ownerName,
      'ownerPhone': ownerPhone,
      'photoUrl': photoUrl,
      'medicalConditions': medicalConditions,
      'allergies': allergies,
      'currentMedications': currentMedications,
      'vaccinations': vaccinations,
    };
  }

  static Pet fromJson(Map<String, dynamic> json, String id) {
    return Pet(
      name: json['name'],
      type: json['type'],
      age: json['age'],
      ownerName: json['ownerName'],
      ownerPhone: json['ownerPhone'],
      photoUrl: json['photoUrl'],
      medicalConditions: json['medicalConditions'] ?? '',
      allergies: json['allergies'] ?? '',
      currentMedications: json['currentMedications'] ?? '',
      vaccinations: json['vaccinations'] ?? '',
      id: id,
    );
  }
}

class PetProfileScreen extends StatefulWidget {
  const PetProfileScreen({super.key});

  @override
  State<PetProfileScreen> createState() => _PetProfileScreenState();
}

class _PetProfileScreenState extends State<PetProfileScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  File? _selectedImage;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _typeController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _ownerNameController = TextEditingController();
  final TextEditingController _ownerPhoneController = TextEditingController();
  final TextEditingController _medicalConditionsController =
      TextEditingController();
  final TextEditingController _allergiesController = TextEditingController();
  final TextEditingController _currentMedicationsController =
      TextEditingController();
  final TextEditingController _vaccinationsController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfiles de Mascotas'),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('pets').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final pets = snapshot.data!.docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final id = doc.id;
                    return Pet.fromJson(data, id);
                  }).toList();

                  return ListView.builder(
                    itemCount: pets.length,
                    itemBuilder: (context, index) {
                      final pet = pets[index];
                      return ListTile(
                        leading: pet.photoUrl.isNotEmpty
                            ? CircleAvatar(
                                backgroundImage: NetworkImage(pet.photoUrl),
                              )
                            : const CircleAvatar(
                                child: Icon(Icons.pets),
                              ),
                        title: Text(pet.name),
                        subtitle: Text('${pet.type}, ${pet.age} años'),
                        trailing: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('${pet.ownerName}'),
                            Text('${pet.ownerPhone}'),
                          ],
                        ),
                        onTap: () {
                          _showPetDetailsDialog(context, pet);
                        },
                      );
                    },
                  );
                } else {
                  return const Center(child: CircularProgressIndicator());
                }
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: () {
                _showAddPetDialog(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color.fromRGBO(4, 65, 80, 0.835),
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                textStyle: const TextStyle(fontSize: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text('Agregar Mascota'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showPetDetailsDialog(BuildContext context, Pet pet) async {
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(pet.name),
          content: SingleChildScrollView(
            child: Column(
              children: [
                pet.photoUrl.isNotEmpty
                    ? Image.network(pet.photoUrl)
                    : const Icon(Icons.pets, size: 100),
                Text('Raza: ${pet.type}'),
                Text('Edad: ${pet.age} años'),
                Text('Nombre del Dueño: ${pet.ownerName}'),
                Text('Teléfono del Dueño: ${pet.ownerPhone}'),
                Text('Condiciones Médicas: ${pet.medicalConditions}'),
                Text('Alergias: ${pet.allergies}'),
                Text('Medicamentos Actuales: ${pet.currentMedications}'),
                Text('Vacunas: ${pet.vaccinations}'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _showEditPetDialog(context, pet);
              },
              child: const Text('Editar'),
            ),
            TextButton(
              onPressed: () {
                _deletePet(pet.id);
                Navigator.pop(context);
              },
              child: const Text('Eliminar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showAddPetDialog(BuildContext context) async {
    _clearControllers(); // Clear the controllers before showing the add dialog
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Agregar Mascota'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                GestureDetector(
                  onTap: () async {
                    final pickedImage = await _imagePicker.pickImage(
                        source: ImageSource.gallery);
                    if (pickedImage != null) {
                      setState(() {
                        _selectedImage = File(pickedImage.path);
                      });
                    }
                  },
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.grey[300],
                    ),
                    child: _selectedImage != null
                        ? Image.file(
                            _selectedImage!,
                            fit: BoxFit.cover,
                          )
                        : const Icon(Icons.camera_alt),
                  ),
                ),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre',
                  ),
                ),
                TextField(
                  controller: _typeController,
                  decoration: const InputDecoration(
                    labelText: 'Raza',
                  ),
                ),
                TextField(
                  controller: _ageController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Edad',
                  ),
                ),
                TextField(
                  controller: _ownerNameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del Dueño',
                  ),
                ),
                TextField(
                  controller: _ownerPhoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Teléfono del Dueño',
                  ),
                ),
                TextField(
                  controller: _medicalConditionsController,
                  decoration: const InputDecoration(
                    labelText: 'Condiciones Médicas',
                  ),
                ),
                TextField(
                  controller: _allergiesController,
                  decoration: const InputDecoration(
                    labelText: 'Alergias',
                  ),
                ),
                TextField(
                  controller: _currentMedicationsController,
                  decoration: const InputDecoration(
                    labelText: 'Medicamentos Actuales',
                  ),
                ),
                TextField(
                  controller: _vaccinationsController,
                  decoration: const InputDecoration(
                    labelText: 'Vacunas',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                _addPet(context);
                Navigator.pop(context);
              },
              child: const Text('Agregar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showEditPetDialog(BuildContext context, Pet pet) async {
    _clearControllers(); // Clear the controllers before filling them with existing data

    // Fill the controllers with the existing data
    _nameController.text = pet.name;
    _typeController.text = pet.type;
    _ageController.text = pet.age.toString();
    _ownerNameController.text = pet.ownerName;
    _ownerPhoneController.text = pet.ownerPhone;
    _medicalConditionsController.text = pet.medicalConditions;
    _allergiesController.text = pet.allergies;
    _currentMedicationsController.text = pet.currentMedications;
    _vaccinationsController.text = pet.vaccinations;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Editar Mascota'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                GestureDetector(
                  onTap: () async {
                    final pickedImage = await _imagePicker.pickImage(
                        source: ImageSource.gallery);
                    if (pickedImage != null) {
                      setState(() {
                        _selectedImage = File(pickedImage.path);
                      });
                    }
                  },
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.grey[300],
                    ),
                    child: _selectedImage != null
                        ? Image.file(
                            _selectedImage!,
                            fit: BoxFit.cover,
                          )
                        : pet.photoUrl.isNotEmpty
                            ? Image.network(
                                pet.photoUrl,
                                fit: BoxFit.cover,
                              )
                            : const Icon(Icons.camera_alt),
                  ),
                ),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre',
                  ),
                ),
                TextField(
                  controller: _typeController,
                  decoration: const InputDecoration(
                    labelText: 'Raza',
                  ),
                ),
                TextField(
                  controller: _ageController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Edad',
                  ),
                ),
                TextField(
                  controller: _ownerNameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del Dueño',
                  ),
                ),
                TextField(
                  controller: _ownerPhoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Teléfono del Dueño',
                  ),
                ),
                TextField(
                  controller: _medicalConditionsController,
                  decoration: const InputDecoration(
                    labelText: 'Condiciones Médicas',
                  ),
                ),
                TextField(
                  controller: _allergiesController,
                  decoration: const InputDecoration(
                    labelText: 'Alergias',
                  ),
                ),
                TextField(
                  controller: _currentMedicationsController,
                  decoration: const InputDecoration(
                    labelText: 'Medicamentos Actuales',
                  ),
                ),
                TextField(
                  controller: _vaccinationsController,
                  decoration: const InputDecoration(
                    labelText: 'Vacunas',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                _updatePet(context, pet.id);
                Navigator.pop(context);
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addPet(BuildContext context) async {
    String? photoUrl;
    if (_selectedImage != null) {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('pet_photos')
          .child('${DateTime.now().millisecondsSinceEpoch}.jpg');
      final uploadTask = storageRef.putFile(_selectedImage!);
      await uploadTask.whenComplete(() => null);
      photoUrl = await storageRef.getDownloadURL();
    }

    final pet = Pet(
      name: _nameController.text,
      type: _typeController.text,
      age: int.parse(_ageController.text),
      ownerName: _ownerNameController.text,
      ownerPhone: _ownerPhoneController.text,
      photoUrl: photoUrl ?? '',
      medicalConditions: _medicalConditionsController.text,
      allergies: _allergiesController.text,
      currentMedications: _currentMedicationsController.text,
      vaccinations: _vaccinationsController.text,
      id: '', // Empty ID for new pets
    );

    try {
      await FirebaseFirestore.instance.collection('pets').add(pet.toJson());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mascota agregada con éxito'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al agregar la mascota: $e'),
        ),
      );
    }

    _clearControllers();
  }

  Future<void> _updatePet(BuildContext context, String id) async {
    String? photoUrl;
    if (_selectedImage != null) {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('pet_photos')
          .child('${DateTime.now().millisecondsSinceEpoch}.jpg');
      final uploadTask = storageRef.putFile(_selectedImage!);
      await uploadTask.whenComplete(() => null);
      photoUrl = await storageRef.getDownloadURL();
    } else {
      photoUrl =
          (await FirebaseFirestore.instance.collection('pets').doc(id).get())
              .data()?['photoUrl'];
    }

    final pet = Pet(
      name: _nameController.text,
      type: _typeController.text,
      age: int.parse(_ageController.text),
      ownerName: _ownerNameController.text,
      ownerPhone: _ownerPhoneController.text,
      photoUrl: photoUrl ?? '',
      medicalConditions: _medicalConditionsController.text,
      allergies: _allergiesController.text,
      currentMedications: _currentMedicationsController.text,
      vaccinations: _vaccinationsController.text,
      id: id,
    );

    try {
      await FirebaseFirestore.instance
          .collection('pets')
          .doc(id)
          .update(pet.toJson());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mascota actualizada con éxito'),
        ),
      );
      setState(() {}); // Update the UI to reflect changes
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al actualizar la mascota: $e'),
        ),
      );
    }

    _clearControllers();
  }

  Future<void> _deletePet(String id) async {
    try {
      await FirebaseFirestore.instance.collection('pets').doc(id).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mascota eliminada con éxito'),
        ),
      );
      setState(() {}); // Update the UI to reflect changes
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al eliminar la mascota: $e'),
        ),
      );
    }
  }

  void _clearControllers() {
    _nameController.clear();
    _typeController.clear();
    _ageController.clear();
    _ownerNameController.clear();
    _ownerPhoneController.clear();
    _medicalConditionsController.clear();
    _allergiesController.clear();
    _currentMedicationsController.clear();
    _vaccinationsController.clear();
    setState(() {
      _selectedImage = null;
    });
  }
}
