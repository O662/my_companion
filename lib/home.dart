import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'profile.dart';
import 'tools.dart';
import 'health.dart';
import 'finances.dart';
import 'focus.dart';
import 'bottom_nav_bar.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
// ...existing code...

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _locationString = '';
  String _currentTemp = '';
  String _firstName = '';
  String _greeting = '';
  File? _profileImage;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
  _fetchUserInfo();
  _getLocationAndWeather();
  }

  Future<void> _fetchUserInfo() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      setState(() {
        _firstName = userDoc['first_name'];
        _setGreeting();
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

  Future<void> _getLocationAndWeather() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _currentTemp = 'Location services are disabled.';
      });
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _currentTemp = 'Location permissions are denied.';
        });
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _currentTemp = 'Location permissions are permanently denied.';
      });
      return;
    }

    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.low);
    double lat = position.latitude;
    double lon = position.longitude;

  // ...existing code...

    // Get placemark (city/state) from coordinates
    List<Placemark> placemarks = await placemarkFromCoordinates(lat, lon);
    if (placemarks.isNotEmpty) {
      final place = placemarks.first;
      setState(() {
        _locationString = '${place.locality}, ${place.administrativeArea}';
      });
    }

    // Get NWS gridpoint for location
    final pointsUrl = Uri.parse('https://api.weather.gov/points/$lat,$lon');
    final pointsResp = await http.get(pointsUrl, headers: {
      'User-Agent': 'MyCompanionApp (your@email.com)'
    });
  // ...existing code...
    if (pointsResp.statusCode == 200) {
      final pointsData = json.decode(pointsResp.body);
      final gridId = pointsData['properties']['gridId'];
      final gridX = pointsData['properties']['gridX'];
      final gridY = pointsData['properties']['gridY'];
      // Get forecast for gridpoint
      final forecastUrl = Uri.parse('https://api.weather.gov/gridpoints/$gridId/$gridX,$gridY/forecast');
      final forecastResp = await http.get(forecastUrl, headers: {
        'User-Agent': 'MyCompanionApp (your@email.com)'
      });
      if (forecastResp.statusCode == 200) {
        final forecastData = json.decode(forecastResp.body);
        final periods = forecastData['properties']['periods'];

        if (periods != null && periods.isNotEmpty) {
          final temp = periods[0]['temperature'];
          final unit = periods[0]['temperatureUnit'];
          setState(() {
            _currentTemp = '$temp°$unit';
          });
        } else {
          setState(() {
            _currentTemp = 'No temperature data.';
          });
        }
      } else {
        setState(() {
          _currentTemp = 'Failed to fetch weather.';
        });
      }
    } else {
      setState(() {
        _currentTemp = 'Failed to get location grid.';
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context,
    MaterialPageRoute(builder: (context) => ToolsPage()),
        );
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HealthPage()),
        );
        break;
      case 3:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => FinancesPage()),
        );
        break;
      case 4:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => FocusPage()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_greeting.isEmpty ? 'Home' : _greeting),
        actions: [
          IconButton(
            icon: CircleAvatar(
              radius: 20,
              backgroundImage: _profileImage != null
                  ? FileImage(_profileImage!)
                  : AssetImage('lib/assets/profile/profilepicture.png'),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfilePage()),
              );
            },
          ),
        ],
      ),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 32),
            Text('Hi $_firstName! Welcome to the Home Page!'),
            const SizedBox(height: 16),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue, width: 2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.thermostat, color: Colors.blue),
                      const SizedBox(width: 8),
                      Text(
                        _currentTemp.isEmpty ? 'Loading temperature...' : 'Current Temp: $_currentTemp',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  if (_locationString.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Location: $_locationString',
                      style: const TextStyle(fontSize: 16, color: Colors.black87),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}