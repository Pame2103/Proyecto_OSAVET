import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pdfLib;
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart'; // Agregar esta importación
import 'dart:io';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "your_api_key",
      authDomain: "your_auth_domain",
      projectId: "your_project_id",
      storageBucket: "your_storage_bucket",
      messagingSenderId: "your_messaging_sender_id",
      appId: "your_app_id",
      measurementId: "your_measurement_id",
    ),
  );

  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? user = _auth.currentUser;

  if (user == null) {
    try {
      final UserCredential userCredential =
          await _auth.signInWithEmailAndPassword(
        email: 'usuario@example.com',
        password: 'contraseña',
      );
      print('Usuario autenticado: ${userCredential.user!.uid}');
    } catch (e) {
      print('Error al autenticar al usuario: $e');
    }
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'OSAVET',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const BillingScreen(),
    );
  }
}

class InvoiceItem {
  final String name;
  final double price;
  int quantity;

  InvoiceItem({required this.name, required this.price, required this.quantity});

  factory InvoiceItem.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return InvoiceItem(
      name: data['name'] ?? '',
      price: data['price']?.toDouble() ?? 0.0,
      quantity: data['quantity'] ?? 1,
    );
  }
}

class BillingScreen extends StatefulWidget {
  const BillingScreen({Key? key});

  @override
  _BillingScreenState createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  List<InvoiceItem> invoiceItems = [];
  List<InvoiceItem> availableProducts = [];

  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _detailsController = TextEditingController();
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _issuerNameController = TextEditingController();
  final TextEditingController _customerPhoneController = TextEditingController();

  InvoiceItem? _selectedProduct;
  double total = 0.0;

  double get totalWithIva => total * 1.13;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  void _fetchProducts() async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance.collection('servicios-productos').get();
      setState(() {
        availableProducts = querySnapshot.docs.map((doc) => InvoiceItem.fromFirestore(doc)).toList();
      });
    } catch (e) {
      print('Error fetching products: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Facturación'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.picture_as_pdf),
            onPressed: () {
              _createPDF();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Fecha: ${DateTime.now().toLocal().toString().split(' ')[0]}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    Text(
                      'Hora: ${TimeOfDay.now().format(context)}',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _customerNameController,
              decoration: const InputDecoration(labelText: 'Nombre del Cliente'),
            ),
            TextField(
              controller: _customerPhoneController,
              decoration: const InputDecoration(labelText: 'Teléfono del Cliente'),
            ),
            TextField(
              controller: _issuerNameController,
              decoration: const InputDecoration(labelText: 'Nombre del Emisor'),
            ),
                      const SizedBox(height: 10),
            DropdownButton<InvoiceItem>(
              hint: const Text('Seleccionar Producto'),
              value: _selectedProduct,
              onChanged: (InvoiceItem? newValue) {
                setState(() {
                  _selectedProduct = newValue;
                  _quantityController.text = '1';
                });
              },
              items: availableProducts.map((InvoiceItem product) {
                return DropdownMenuItem<InvoiceItem>(
                  value: product,
                  child: Text('${product.name} - \$${product.price}'),
                );
              }).toList(),
            ),
            TextField(
              controller: _quantityController,
              decoration: const InputDecoration(labelText: 'Cantidad'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _addItemToInvoice,
              child: const Text('Agregar a Factura'),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: invoiceItems.length,
                itemBuilder: (BuildContext context, int index) {
                  return ListTile(
                    title: Text(invoiceItems[index].name),
                    subtitle: Text('Cantidad: ${invoiceItems[index].quantity}, Precio Unitario: \$${invoiceItems[index].price}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        IconButton(
                          icon: const Icon(Icons.remove),
                          onPressed: () => _decreaseQuantity(index),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () => _increaseQuantity(index),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _removeItemFromInvoice(index),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const Divider(),
            TextField(
              controller: _detailsController,
              decoration: const InputDecoration(labelText: 'Detalle'),
            ),
            const SizedBox(height: 10),
            Text(
              'Total: \$${total.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Total con IVA (13%): \$${totalWithIva.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addItemToInvoice() {
    if (_selectedProduct != null) {
      int quantity = int.tryParse(_quantityController.text) ?? 0;
      if (quantity > 0) {
        setState(() {
          int index = invoiceItems.indexWhere((item) => item.name == _selectedProduct!.name);
          if (index != -1) {
            invoiceItems[index].quantity += quantity;
          } else {
            invoiceItems.add(InvoiceItem(
              name: _selectedProduct!.name,
              price: _selectedProduct!.price,
              quantity: quantity,
            ));
          }
          total += quantity * _selectedProduct!.price;
        });
        _quantityController.clear();
      }
    }
  }

  void _decreaseQuantity(int index) {
    setState(() {
      if (invoiceItems[index].quantity > 1) {
        invoiceItems[index].quantity--;
        total -= invoiceItems[index].price;
      }
    });
  }

  void _increaseQuantity(int index) {
    setState(() {
      invoiceItems[index].quantity++;
      total += invoiceItems[index].price;
    });
  }

  void _removeItemFromInvoice(int index) {
    setState(() {
      total -= invoiceItems[index].quantity * invoiceItems[index].price;
      invoiceItems.removeAt(index);
    });
  }

  void _createPDF() async {
    final pdfLib.Document pdf = pdfLib.Document();

    pdf.addPage(
      pdfLib.Page(
        build: (context) => pdfLib.Column(
          crossAxisAlignment: pdfLib.CrossAxisAlignment.start,
          children: [
            pdfLib.Text('Factura', style: pdfLib.TextStyle(fontSize: 30)),
            pdfLib.SizedBox(height: 20),
            pdfLib.Text('Nombre del Cliente: ${_customerNameController.text}'),
            pdfLib.Text('Teléfono del Cliente: ${_customerPhoneController.text}'),
            pdfLib.Text('Nombre del Emisor: ${_issuerNameController.text}'),
            pdfLib.SizedBox(height: 20),
            pdfLib.Text('Detalles: ${_detailsController.text}'),
            pdfLib.SizedBox(height: 20),
            pdfLib.Text('Productos:'),
            pdfLib.ListView(
              children: [
                for (var item in invoiceItems)
                  pdfLib.Text('${item.name} - Cantidad: ${item.quantity}, Precio Unitario: \$${item.price}'),
              ],
            ),
            pdfLib.SizedBox(height: 20),
            pdfLib.Text('Total: \$${total.toStringAsFixed(2)}'),
            pdfLib.Text('Total con IVA (13%): \$${totalWithIva.toStringAsFixed(2)}'),
          ],
        ),
      ),
    );

    final String dir = (await getApplicationDocumentsDirectory()).path;
    final String path = '$dir/factura.pdf';
    final File file = File(path);
    await file.writeAsBytes(await pdf.save());
    OpenFile.open(path);
  }
}

