import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class AddProductPage extends StatefulWidget {
  const AddProductPage({super.key});

  @override
  _AddProductPageState createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();

  String? _selectedCategory; // Default category
  final List<String> _categories = ['Product', 'Accessories'];

  File? _image;

  // List to store products (for demo purposes; ideally this should come from a database)
  final List<Map<String, dynamic>> _products = [];

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  // Function to check for product duplicacy
  bool _isProductDuplicate(String productName) {
    return _products.any((product) => product['name'] == productName);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Product')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Product Name'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a product name';
                    }
                    if (_isProductDuplicate(value)) {
                      return 'Product with this name already exists';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _priceController,
                  decoration: const InputDecoration(labelText: 'Price'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a price';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: _categories.map((String category) {
                    return DropdownMenuItem<String>(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value;
                    });
                    print("Dropdown changed: $_selectedCategory"); // Debug
                  },
                ),
                const SizedBox(height: 50),
                Container(
                  height: 200,
                  width: 200,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.all(Radius.circular(10)),
                    border: Border.all(width: 1, color: Colors.black26),
                  ),
                  child: _image != null
                      ? Image.file(
                          _image!,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        )
                      : const Text('No image selected'),
                ),
                const SizedBox(height: 50),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    ElevatedButton(
                      onPressed: _pickImage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade600, // Button color
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(15), // Border radius
                        ),
                      ),
                      child: const Text(
                        'Pick Image',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 20),
                    ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          if (_selectedCategory != null) {
                            // Debug print to verify data
                            print(
                                "Form Data: ${_nameController.text}, ${_priceController.text}, $_selectedCategory");
                            print("Selected Category: $_selectedCategory");

                            Navigator.pop(context, {
                              'name': _nameController.text,
                              'price': double.parse(_priceController.text),
                              'category':
                                  _selectedCategory, // Pass the correct category
                              'image': _image?.path,
                            });
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Please select a category')),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade600, // Button color
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(15), // Border radius
                        ),
                      ),
                      child: const Text(
                        'Add Product',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
