import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:product_crud/login_page.dart';
import 'package:product_crud/add_product.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> _filteredProducts = [];
  final _searchController = TextEditingController();
  bool _isSearching = false; // Flag to indicate search mode
  //String _selectedCategory = 'Product'; // Default category
  final List<String> _categories = ['Product', 'Accessories'];

  List<Map<String, dynamic>> _products = [];
  final Map<String, List<Map<String, dynamic>>> _categorizedProducts = {
    'Product': [],
    'Accessories': []
  };
  final Map<String, bool> _showAllFlags = {
    'Product': false,
    'Accessories': false
  };

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    if (isLoggedIn) {
      _loadProducts(); // Load products if logged in
    } else {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const LoginPage()));
    }
  }

  Future<void> _loadProducts() async {
    final prefs = await SharedPreferences.getInstance();
    final productsString = prefs.getString('products');
    if (productsString != null) {
      setState(() {
        _products = List<Map<String, dynamic>>.from(jsonDecode(productsString))
            .map((product) {
          product['timestamp'] ??= 0;
          return product;
        }).toList();
        print('Loaded products 2: $_products');
        _sortProductsByNewest(); // Sort after loading
        _categorizeProducts();
        _filteredProducts = List.from(_products); // Initialize filtered list
      });
    }
  }

  void _categorizeProducts() {
    _categorizedProducts['Product'] =
        _products.where((p) => p['category'] == 'Product').toList();
    _categorizedProducts['Accessories'] =
        _products.where((p) => p['category'] == 'Accessories').toList();
  }

  Future<void> _addProduct(
      String name, double price, String? imagePath, String category) async {
    final prefs = await SharedPreferences.getInstance();
    print("Saving Product Data: $name, $price, $category, $imagePath");
    _products.add({
      'name': name, 'price': price, 'image': imagePath, 'category': category,
      'timestamp': DateTime.now().millisecondsSinceEpoch, // Add timestamp
    });
    print("added product 90: $_products");
    await prefs.setString('products', jsonEncode(_products));
    setState(() {
      _categorizeProducts(); // Re-categorize after adding a product
      _sortProductsByNewest(); // Sort products
      _filteredProducts = List.from(_products); // Reset filtered list
    });
  }

  void _sortProductsByNewest() {
    _products.sort((a, b) {
      final timestampA = a['timestamp'] ?? 0; // Use 0 if timestamp is null
      final timestampB = b['timestamp'] ?? 0; // Use 0 if timestamp is null
      return timestampB.compareTo(timestampA);
    });
  }

  Future<void> _deleteProduct(int index) async {
    final prefs = await SharedPreferences.getInstance();
    final productToDelete =
        _filteredProducts[index]; // Get the product from the filtered list

    // Remove the product from the original _products list
    _products.removeWhere(
        (product) => product['timestamp'] == productToDelete['timestamp']);

    // Save the updated _products list back to SharedPreferences
    await prefs.setString('products', jsonEncode(_products));

    setState(() {
      // Rebuild the filtered list after deletion
      _filteredProducts = List.from(_products);
      _categorizeProducts(); // Re-categorize after deletion
    });
  }

  void _filterProducts(String query) {
    setState(() {
      print('Search query: $query');
      _filteredProducts = _products.where((product) {
        bool matches = product['name'] != null &&
            product['name'].toLowerCase().contains(query.toLowerCase());
        print('Checking: ${product['name']} => $matches');
        return matches;
      }).toList();
    });
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Logout'),
          content: const Text('Are you sure you want to log out?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context)
                    .pop(); // Close the dialog without logging out
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('token');
                await prefs.remove('isLoggedIn'); // Remove login status
                Fluttertoast.showToast(
                  msg: "Logged Out",
                  backgroundColor: Colors.blue.shade600,
                  textColor: Colors.white,
                  gravity: ToastGravity.BOTTOM,
                );
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (_) => const LoginPage()));
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCategoryRow(String category) {
    final count = _categorizedProducts[category]?.length ?? 0;
    final showAll = _showAllFlags[category]!;
    final items = _isSearching
        ? _filteredProducts.where((p) => p['category'] == category).toList()
        : showAll
            ? _categorizedProducts[category]!
            : _categorizedProducts[category]!.take(2).toList();

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$category $count',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            GestureDetector(
              onTap: () {
                setState(() {
                  _showAllFlags[category] = !_showAllFlags[category]!;
                });
              },
              child: Text(
                showAll ? 'Show Less' : 'Show All',
                style: const TextStyle(
                    color: Colors.blue, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.9,
            crossAxisSpacing: 8.0,
            mainAxisSpacing: 8.0,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final product = items[index];
            return Card(
              elevation: 0,
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      Container(
                        height: 120,
                        width: double.infinity,
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius:
                              const BorderRadius.all(Radius.circular(12)),
                        ),
                        child: product['image'] != null
                            ? Image.file(
                                File(product['image']),
                                fit: BoxFit.contain,
                              )
                            : const Icon(Icons.image, size: 100),
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            size: 35,
                            color: Colors.black,
                          ),
                          onPressed: () => _deleteProduct(index),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      product['name'],
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text('Price: \$${product['price']}'),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCategoryRowWithProducts(
      String category, List<Map<String, dynamic>> categoryProducts) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$category ${categoryProducts.length}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.9,
            crossAxisSpacing: 8.0,
            mainAxisSpacing: 8.0,
          ),
          itemCount: categoryProducts.length,
          itemBuilder: (context, index) {
            final product = categoryProducts[index];
            return Card(
              elevation: 0,
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      Container(
                        height: 120,
                        width: double.infinity,
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius:
                              const BorderRadius.all(Radius.circular(12)),
                        ),
                        child: product['image'] != null
                            ? Image.file(
                                File(product['image']),
                                fit: BoxFit.contain,
                              )
                            : const Icon(Icons.image, size: 100),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      product['name'],
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text('Price: \$${product['price']}'),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (_isSearching) {
          setState(() {
            _isSearching = false; // Close the search TextField
          });
          FocusScope.of(context)
              .unfocus(); // Hide keyboard when tapping outside
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 30),
            child: Column(
              children: [
                // Custom AppBar
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Row(
                    children: [
                      // Back button in grey box
                      Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Icon(
                          Icons.arrow_back_ios_new,
                          color: Colors.grey.shade600,
                          size: 18,
                        ),
                      ),
                      const Spacer(),
                      // Search icon or TextField
                      _isSearching
                          ? Expanded(
                              child: TextField(
                                controller: _searchController,
                                autofocus: true,
                                decoration: InputDecoration(
                                  hintText: 'Search...',
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                        color: Colors.grey.shade200,
                                        width:
                                            2.0), // Border color when focused
                                    borderRadius: const BorderRadius.all(
                                        Radius.circular(8.0)),
                                  ),
                                  enabledBorder: const OutlineInputBorder(
                                    borderSide: BorderSide(
                                        color: Colors.grey,
                                        width:
                                            1.0), // Border color when not focused
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(8.0)),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                      vertical: 0, horizontal: 10),
                                ),
                                onChanged: _filterProducts,
                              ),
                            )
                          : GestureDetector(
                              onTap: () {
                                setState(() {
                                  _isSearching = true;
                                });
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                      width: 2, color: Colors.grey.shade200),
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                padding: const EdgeInsets.all(12),
                                child: Icon(
                                  Icons.search,
                                  color: Colors.grey.shade600,
                                  size: 20,
                                ),
                              ),
                            ),
                      const SizedBox(width: 10),
                      // Logout icon box
                      GestureDetector(
                        onTap: () => _showLogoutDialog(),
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                                width: 2, color: Colors.grey.shade200),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          padding: const EdgeInsets.all(13),
                          child: Icon(
                            Icons.logout,
                            size: 18,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  alignment: Alignment.centerLeft,
                  margin: const EdgeInsets.symmetric(horizontal: 15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Hi-Fi Shop & Service",
                        style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 30),
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      Text(
                        "Audio shop on Rustaveli Ave 57.",
                        style: TextStyle(
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.bold,
                            fontSize: 16),
                      ),
                      const SizedBox(
                        height: 5,
                      ),
                      Text(
                        "This shop offers both product and services",
                        style: TextStyle(
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.bold,
                            fontSize: 16),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                Container(
                  height: 600,
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Flexible(
                        child: ListView(
                          children: [
                            // If search query is not empty, display the filtered products
                            if (_searchController.text.isNotEmpty)
                              ..._categories.map((category) {
                                final filteredCategoryProducts =
                                    _filteredProducts
                                        .where((p) => p['category'] == category)
                                        .toList();
                                return _buildCategoryRowWithProducts(
                                    category, filteredCategoryProducts);
                              }),

                            // If search query is empty, show the full categories
                            if (_searchController.text.isEmpty)
                              _buildCategoryRow('Product'),
                            const SizedBox(height: 20),
                            if (_searchController.text.isEmpty)
                              _buildCategoryRow('Accessories'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(
                  height: 30,
                ),
              ],
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: Colors.blue, // Set background color to blue
          shape: const CircleBorder(),
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddProductPage()),
            );
            if (result != null) {
              _addProduct(
                result['name'],
                result['price'],
                result['image'],
                result['category'],
              );
              print('Add products 1: $_addProduct');
            }
          },
          child: const Icon(Icons.add, color: Colors.white), // White plus icon
        ),
      ),
    );
  }
}
