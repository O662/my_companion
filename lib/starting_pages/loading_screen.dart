import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'dart:async';

class LoadingScreen extends StatefulWidget {
  final Widget nextScreen;

  const LoadingScreen({Key? key, required this.nextScreen}) : super(key: key);

  @override
  _LoadingScreenState createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  @override
  void initState() {
    super.initState();
    // Navigate to next screen after 1 second
    Timer(Duration(seconds: 1), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => widget.nextScreen),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
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
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // You can replace this with a Lottie animation once you add a JSON file
              // Lottie.asset(
              //   'lib/assets/animations/loading.json',
              //   width: 200,
              //   height: 200,
              // ),
              
              // For now, using a circular progress indicator
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
              const SizedBox(height: 24),
              const Text(
                'My Companion',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
