import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../home.dart';
import '../tools.dart';
import '../health.dart';
import '../personal.dart';
import '../bottom_nav_bar.dart';

class RadarPage extends StatefulWidget {
  @override
  _RadarPageState createState() => _RadarPageState();
}

class _RadarPageState extends State<RadarPage> {
  int _selectedIndex = 1;
  LatLng _currentLocation = LatLng(37.7749, -122.4194); // Default to San Francisco
  bool _isLoadingLocation = true;
  MapController _mapController = MapController();
  int _radarOpacity = 70;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          setState(() => _isLoadingLocation = false);
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            setState(() => _isLoadingLocation = false);
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() => _isLoadingLocation = false);
        }
        return;
      }

      Position position = await Geolocator.getCurrentPosition();
      if (!mounted) return;
      
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
        _isLoadingLocation = false;
      });
      
      // Move map to current location after a short delay to ensure map is rendered
      Future.delayed(Duration(milliseconds: 100), () {
        if (mounted && _mapController != null) {
          _mapController.move(_currentLocation, 8.0);
        }
      });
    } catch (e) {
      print('Error getting location: $e');
      if (mounted) {
        setState(() => _isLoadingLocation = false);
      }
    }
  }

  void _onItemTapped(int index) {
    if (index == 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => ToolsPage()),
      );
      return;
    }
    
    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
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
          MaterialPageRoute(builder: (context) => PersonalPage()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Radar'),
        actions: [
          IconButton(
            icon: Icon(Icons.my_location),
            onPressed: () {
              _getCurrentLocation();
            },
            tooltip: 'Center on my location',
          ),
        ],
      ),
      body: Column(
        children: [
          // Radar info banner
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            child: Row(
              children: [
                Icon(Icons.radar, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '🌧️ Live NOAA Weather Radar - US/North America',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          // Opacity slider
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Text('Opacity: '),
                Expanded(
                  child: Slider(
                    value: _radarOpacity.toDouble(),
                    min: 0,
                    max: 100,
                    divisions: 10,
                    label: '$_radarOpacity%',
                    onChanged: (value) {
                      setState(() => _radarOpacity = value.toInt());
                    },
                  ),
                ),
                Text('$_radarOpacity%'),
              ],
            ),
          ),
          // Map
          Expanded(
            child: _isLoadingLocation
                ? Center(child: CircularProgressIndicator())
                : FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _currentLocation,
                      initialZoom: 8.0,
                      minZoom: 3.0,
                      maxZoom: 18.0,
                    ),
                    children: [
                      // Base map tile layer
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.my_companion',
                        tileProvider: NetworkTileProvider(),
                        tileBuilder: (context, widget, tile) {
                          return ColorFiltered(
                            colorFilter: ColorFilter.mode(
                              Theme.of(context).brightness == Brightness.dark
                                  ? Colors.grey.shade900
                                  : Colors.white,
                              BlendMode.modulate,
                            ),
                            child: widget,
                          );
                        },
                      ),
                      // Weather radar overlay (US NOAA Radar via Iowa State - 100% Free!)
                      TileLayer(
                        urlTemplate: 'https://mesonet.agron.iastate.edu/cache/tile.py/1.0.0/nexrad-n0q-900913/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.my_companion',
                        tileProvider: NetworkTileProvider(),
                        tileBuilder: (context, widget, tile) {
                          return Opacity(
                            opacity: _radarOpacity / 100,
                            child: widget,
                          );
                        },
                      ),
                      // Current location marker
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _currentLocation,
                            width: 80,
                            height: 80,
                            child: Icon(
                              Icons.my_location,
                              color: Colors.blue,
                              size: 40,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
          ),
          // Legend
          Container(
            padding: EdgeInsets.all(8),
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.info_outline, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Pinch to zoom • Drag to move • Data: NOAA/Iowa State & OpenWeatherMap',
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                ),
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
