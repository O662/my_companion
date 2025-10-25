import 'package:flutter/material.dart';
import 'login_page.dart';
import 'signup_page.dart';

class WelcomePage extends StatelessWidget {
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
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Expanded(
                flex: 2,
                child: Align(
                  alignment: Alignment(0, -0.5), // Move up to about 2/3 height
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // White stroke
                      Text(
                        'Welcome!',
                        style: TextStyle(
                          fontSize: 60,
                          fontWeight: FontWeight.bold,
                          foreground: Paint()
                            ..style = PaintingStyle.stroke
                            ..strokeWidth = .5
                            ..color = Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      // Black fill
                      const Text(
                        'Welcome!',
                        style: TextStyle(
                          fontSize: 60,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black,
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => LoginPage()),
                    );
                  },
                  child: const Text('Login', style: TextStyle(color: Colors.black)),
                ),
              ),
              SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black,
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SignupPage()),
                    );
                  },
                  child: const Text('Signup', style: TextStyle(color: Colors.black)),
                ),
              ),
              SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}