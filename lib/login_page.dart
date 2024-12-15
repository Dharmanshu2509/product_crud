import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:product_crud/home_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:fluttertoast/fluttertoast.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  Future<void> _login() async {
    final email = _emailController.text;
    final password = _passwordController.text;

    print('Email: $email');
    print('Password: $password');

    if (email.isEmpty || password.isEmpty) {
      Fluttertoast.showToast(
        msg: "Email and Password cannot be empty!",
        backgroundColor: Colors.red,
        textColor: Colors.white,
        gravity: ToastGravity.BOTTOM,
      );
      return;
    }

    if (!_isEmailValid(email)) {
      Fluttertoast.showToast(
        msg: "Please enter a valid email!",
        backgroundColor: Colors.red,
        textColor: Colors.white,
        gravity: ToastGravity.BOTTOM,
      );
      return;
    }

    if (!_isPasswordValid(password)) {
      Fluttertoast.showToast(
        msg: "Password should be at least 6 characters!",
        backgroundColor: Colors.red,
        textColor: Colors.white,
        gravity: ToastGravity.BOTTOM,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('https://reqres.in/api/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      print('Response Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['token'];

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);
        await prefs.setBool('isLoggedIn', true);  // Save the login state

        // Show success toast with blue color
        Fluttertoast.showToast(
          msg: "Login Successful",
          backgroundColor: Colors.blue.shade600,
          textColor: Colors.white,
          gravity: ToastGravity.BOTTOM,
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      } else {
        // Show failure toast with blue color
        Fluttertoast.showToast(
          msg: "Login Failed",
          backgroundColor: Colors.red,
          textColor: Colors.white,
          gravity: ToastGravity.BOTTOM,
        );
      }
    } catch (e) {
      print('Error: $e');
      // Show failure toast with blue color
      Fluttertoast.showToast(
        msg: "An error occurred",
        backgroundColor: Colors.blue.shade600,
        textColor: Colors.white,
        gravity: ToastGravity.BOTTOM,
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  void _unfocusFields() {
    FocusScope.of(context).unfocus();
  }

  // Function to validate email format
  bool _isEmailValid(String email) {
    final emailRegExp =
        RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$");
    return emailRegExp.hasMatch(email);
  }

  // Function to validate password length
  bool _isPasswordValid(String password) {
    return password.length >=
        6; // Ensure password is at least 6 characters long
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _unfocusFields, // Unfocus when tapping outside
      child: Scaffold(
        backgroundColor: Colors.white,
        body: _isLoading
            ? Center(child: CircularProgressIndicator(color: Colors.blue.shade600,))
            : SingleChildScrollView(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 30, vertical: 30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 50),
                      Center(
                        child: Image.asset(
                          'assets/login_img.png', // Add your image asset path
                          fit: BoxFit.cover,
                          height: 225,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        "Login",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                            fontSize: 30),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.alternate_email,
                            color: Colors.grey, // Icon color
                            size: 24.0,
                          ),
                          const SizedBox(
                              width: 8.0), // Spacing between icon and TextField
                          Expanded(
                              child: TextField(
                            controller: _emailController,
                            focusNode: _emailFocusNode, // Attach the focus node
                            decoration: InputDecoration(
                              labelText: 'Email ID',
                              labelStyle: const TextStyle(
                                color:
                                    Colors.grey, // Label color when not focused
                                fontWeight:
                                    FontWeight.bold, // Bold font for label
                              ),
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.blue
                                      .shade600, // Border color when focused
                                  width: 1.0, // Border thickness when focused
                                ),
                              ),
                              enabledBorder: const UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors
                                      .grey, // Border color when not focused
                                  width:
                                      0.5, // Border thickness when not focused
                                ),
                              ),
                            ),
                            cursorColor: Colors
                                .blue.shade600, // Cursor color while typing
                          )),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.lock_outline,
                            color: Colors.grey, // Icon color
                            size: 24.0,
                          ),
                          const SizedBox(
                              width: 8.0), // Spacing between icon and TextField
                          Expanded(
                            child: TextField(
                              controller: _passwordController,
                              obscureText:
                                  !_isPasswordVisible, // For hiding/showing the password
                              focusNode:
                                  _passwordFocusNode, // Attach the focus node
                              decoration: InputDecoration(
                                labelText: 'Password',
                                labelStyle: const TextStyle(
                                  color: Colors
                                      .grey, // Label color when not focused
                                  fontWeight:
                                      FontWeight.bold, // Bold font for label
                                ),
                                focusedBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Colors.blue
                                        .shade600, // Border color when focused
                                    width: 1.0, // Border thickness when focused
                                  ),
                                ),
                                enabledBorder: const UnderlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Colors
                                        .grey, // Border color when not focused
                                    width:
                                        0.5, // Border thickness when not focused
                                  ),
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _isPasswordVisible
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                    color: Colors.blue.shade600, // Icon color
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _isPasswordVisible = !_isPasswordVisible;
                                    });
                                  },
                                ),
                              ),
                              cursorColor: Colors
                                  .blue.shade600, // Cursor color while typing
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {}, // Add forgot password logic
                          child: Text(
                            'Forgot Password?',
                            style: TextStyle(
                                color: Colors.blue.shade600,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade600,
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                                15), // Set border radius to 5
                          ),
                        ),
                        child: const Text(
                          'Login',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      const SizedBox(height: 25),
                      const Row(
                        children: [
                          Expanded(
                            child: Divider(
                              thickness: 0.5,
                              color: Colors.black26,
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8.0),
                            child: Text(
                              'OR',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                                //fontSize: 18,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              thickness: 0.5,
                              color: Colors.black26,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                      Container(
                        padding: const EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Expanded(
                              flex: 1,
                              child: Image.asset(
                                'assets/search.png', // Add your Google logo asset path
                                height: 24,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Expanded(
                                flex: 2,
                                child: Text(
                                  'Login with Google',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey,
                                    fontSize: 18,
                                  ),
                                )),
                          ],
                        ),
                      ),
                      const SizedBox(height: 25),
                      Center(
                        child: RichText(
                          text: TextSpan(
                            text: 'New to Logistic? ',
                            style: const TextStyle(
                                color: Colors.grey,
                                fontWeight: FontWeight.bold),
                            children: [
                              TextSpan(
                                text: 'Register',
                                style: TextStyle(
                                  color: Colors.blue.shade600,
                                  fontWeight: FontWeight.bold,
                                ),
                                // Add registration logic
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
