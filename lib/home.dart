import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _firstName = '';
  String _greeting = '';

  @override
  void initState() {
    super.initState();
    _fetchUserInfo();
    _setGreeting();
  }

  Future<void> _fetchUserInfo() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      setState(() {
        _firstName = userDoc['first_name'];
        _setGreeting(); // Update greeting after fetching user info
      });
    }
  }

  void _setGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      _greeting = 'Good Morning';
    } else if (hour < 17) {
      _greeting = 'Good Afternoon';
    } else {
      _greeting = 'Good Evening';
    }
    if (_firstName.isNotEmpty) {
      _greeting += ', $_firstName';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_greeting.isEmpty ? 'Home' : _greeting)),
      body: Center(
        child: Text('Hi $_firstName! Welcome to the Home Page!'),
      ),
    );
  }
}