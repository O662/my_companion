import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../home.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      try {
        UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text,
          password: _passwordController.text,
        );
        // Navigate to the home page and remove all previous routes
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
          (Route<dynamic> route) => false,
        );
      } on FirebaseAuthException catch (e) {
        // Handle login errors here
        print('Error: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFF3E5F5), // Very light purple at top
            Color(0xFF8E24AA), // Deep purple at bottom
          ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Login'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(flex: 1),
                Align(
                  alignment: Alignment(0, 0.66), // 2/3 from the bottom
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: 400),
                    child: SingleChildScrollView(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Welcome Back!',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 32),
                            TextFormField(
                              controller: _emailController,
                              decoration: InputDecoration(
                                labelText: 'Email',
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                prefixIcon: Icon(Icons.email),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your email';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _passwordController,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                prefixIcon: Icon(Icons.lock),
                              ),
                              obscureText: true,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your password';
                                }
                                return null;
                              },
                              onFieldSubmitted: (_) => _login(),
                              textInputAction: TextInputAction.done,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const Spacer(flex: 1),
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                      backgroundColor: Colors.white,
                      foregroundColor: Color(0xFF8E24AA),
                    ),
                    onPressed: _login,
                    child: const Text(
                      'Login',
                      style: TextStyle(
                        color: Color(0xFF8E24AA),
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
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