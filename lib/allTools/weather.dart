import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import '../home.dart';
import '../tools.dart';
import '../health.dart';
import '../personal.dart';
import '../bottom_nav_bar.dart';
import 'radar.dart';

class WeatherPage extends StatefulWidget {
  @override
  _WeatherPageState createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> {
  int _selectedIndex = 1;
  bool _isLoading = true;
  String _location = 'Loading...';
  Map<String, dynamic>? _weatherData;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _getWeather();
  }

  Future<void> _getWeather() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Get current location
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _errorMessage = 'Location services are disabled.';
          _isLoading = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _errorMessage = 'Location permissions are denied.';
            _isLoading = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _errorMessage = 'Location permissions are permanently denied.';
          _isLoading = false;
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition();
      
      // Fetch weather data from Open-Meteo API (Free, no API key needed!)
      final weatherUrl = Uri.parse(
        'https://api.open-meteo.com/v1/forecast?latitude=${position.latitude}&longitude=${position.longitude}&current=temperature_2m,relative_humidity_2m,apparent_temperature,precipitation,weather_code,cloud_cover,pressure_msl,wind_speed_10m,wind_direction_10m&temperature_unit=fahrenheit&wind_speed_unit=mph&precipitation_unit=inch&timezone=auto',
      );
      
      final response = await http.get(weatherUrl);
      
      print('Weather API Response Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Get location name using Nominatim reverse geocoding (same as home page)
        String locationName = 'Current Location';
        try {
          final geoUrl = Uri.parse(
            'https://nominatim.openstreetmap.org/reverse?format=json&lat=${position.latitude}&lon=${position.longitude}',
          );
          final geoResponse = await http.get(geoUrl);
          if (geoResponse.statusCode == 200) {
            final geocodeData = json.decode(geoResponse.body);
            final address = geocodeData['address'];
            
            if (address != null) {
              String prefix = '';
              
              // Try to get city/town (same logic as home page)
              if (address['city'] != null && address['city'].toString().isNotEmpty) {
                locationName = address['city'];
              } else if (address['town'] != null && address['town'].toString().isNotEmpty) {
                locationName = address['town'];
              } else if (address['village'] != null && address['village'].toString().isNotEmpty) {
                locationName = address['village'];
              } else if (address['suburb'] != null && address['suburb'].toString().isNotEmpty) {
                locationName = address['suburb'];
                prefix = 'Near ';
              } else if (address['county'] != null && address['county'].toString().isNotEmpty) {
                locationName = address['county'];
                prefix = 'Near ';
              } else if (address['state'] != null && address['state'].toString().isNotEmpty) {
                locationName = address['state'];
                prefix = 'Near ';
              }
              
              locationName = prefix + locationName;
            }
          }
        } catch (e) {
          print('Geocoding error: $e');
        }
        
        setState(() {
          _weatherData = data;
          _location = locationName;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load weather data (Status: ${response.statusCode})';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Weather Error: $e');
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  String _getWeatherIcon(int? weatherCode) {
    if (weatherCode == null) return '🌡️';
    // WMO Weather interpretation codes
    if (weatherCode == 0) return '☀️'; // Clear sky
    if (weatherCode <= 3) return '⛅'; // Partly cloudy
    if (weatherCode <= 48) return '🌫️'; // Fog
    if (weatherCode <= 67) return '🌧️'; // Rain
    if (weatherCode <= 77) return '❄️'; // Snow
    if (weatherCode <= 82) return '🌦️'; // Rain showers
    if (weatherCode <= 86) return '🌨️'; // Snow showers
    if (weatherCode >= 95) return '⛈️'; // Thunderstorm
    return '🌡️';
  }

  String _getWeatherDescription(int? weatherCode) {
    if (weatherCode == null) return 'Unknown';
    if (weatherCode == 0) return 'Clear Sky';
    if (weatherCode == 1) return 'Mainly Clear';
    if (weatherCode == 2) return 'Partly Cloudy';
    if (weatherCode == 3) return 'Overcast';
    if (weatherCode <= 48) return 'Foggy';
    if (weatherCode <= 67) return 'Rainy';
    if (weatherCode <= 77) return 'Snowy';
    if (weatherCode <= 82) return 'Rain Showers';
    if (weatherCode <= 86) return 'Snow Showers';
    if (weatherCode >= 95) return 'Thunderstorm';
    return 'Unknown';
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
        title: Text('Weather'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _getWeather,
            tooltip: 'Refresh weather',
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: Colors.red),
                        SizedBox(height: 16),
                        Text(
                          _errorMessage,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _getWeather,
                          child: Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _getWeather,
                  child: SingleChildScrollView(
                    physics: AlwaysScrollableScrollPhysics(),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Location
                          Text(
                            _location,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 32),
                          
                          // Main weather info
                          Card(
                            elevation: 4,
                            child: Padding(
                              padding: EdgeInsets.all(24),
                              child: Column(
                                children: [
                                  Text(
                                    _getWeatherIcon(_weatherData?['current']?['weather_code']),
                                    style: TextStyle(fontSize: 80),
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    '${_weatherData?['current']?['temperature_2m']?.round() ?? '--'}°F',
                                    style: TextStyle(
                                      fontSize: 48,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    _getWeatherDescription(_weatherData?['current']?['weather_code']),
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'Feels like ${_weatherData?['current']?['apparent_temperature']?.round() ?? '--'}°F',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: 24),
                          
                          // Weather details grid
                          GridView.count(
                            crossAxisCount: 2,
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                            childAspectRatio: 1.5,
                            children: [
                              _buildWeatherDetail(
                                '💨 Wind',
                                '${_weatherData?['current']?['wind_speed_10m']?.round() ?? '--'} mph',
                              ),
                              _buildWeatherDetail(
                                '💧 Humidity',
                                '${_weatherData?['current']?['relative_humidity_2m'] ?? '--'}%',
                              ),
                              _buildWeatherDetail(
                                '🌧️ Precipitation',
                                '${_weatherData?['current']?['precipitation'] ?? '0'} in',
                              ),
                              _buildWeatherDetail(
                                '🔽 Pressure',
                                '${_weatherData?['current']?['pressure_msl']?.round() ?? '--'} hPa',
                              ),
                              _buildWeatherDetail(
                                '🧭 Wind Dir',
                                '${_weatherData?['current']?['wind_direction_10m']?.round() ?? '--'}°',
                              ),
                              _buildWeatherDetail(
                                '☁️ Clouds',
                                '${_weatherData?['current']?['cloud_cover'] ?? '--'}%',
                              ),
                            ],
                          ),
                          SizedBox(height: 24),
                          
                          // Radar button
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => RadarPage()),
                              );
                            },
                            icon: Icon(Icons.radar),
                            label: Text('View Weather Radar'),
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                              textStyle: TextStyle(fontSize: 16),
                            ),
                          ),
                          SizedBox(height: 24),
                          
                          // Attribution
                          Text(
                            'Data provided by Open-Meteo.com',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }

  Widget _buildWeatherDetail(String label, String value) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
