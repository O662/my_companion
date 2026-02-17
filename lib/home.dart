import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';
import 'profile.dart';
import 'tools.dart';
import 'health.dart';
import 'personal.dart';

import 'bottom_nav_bar.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _locationString = '';
  String _currentTemp = '';
  String _feelsLikeTemp = '';
  String _highTemp = '';
  String _lowTemp = '';
  String _dayOfWeek = '';
  String _dateString = '';
  String _firstName = '';
  String _greeting = '';
  File? _profileImage;
  int _selectedIndex = 0;
  List<Map<String, String>> _fiveDayForecast = [];
  bool _isUsingFallbackTemp = false;

  @override
  void initState() {
    super.initState();
    _setDateInfo();
  _fetchUserInfo();
  _getLocationAndWeather();
  }
  
  void _setDateInfo() {
    final now = DateTime.now();
    final dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final monthNames = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    
    setState(() {
      _dayOfWeek = dayNames[now.weekday - 1];
      _dateString = '${monthNames[now.month - 1]} ${now.day}, ${now.year}';
    });
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
    try {
      bool serviceEnabled;
      LocationPermission permission;

      // On web, location services check works differently
      if (kIsWeb) {
        print('Running on web, checking permissions...');
        // For web, we'll just try to get permission directly
        permission = await Geolocator.checkPermission();
        print('Permission status: $permission');
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
          if (permission == LocationPermission.denied) {
            setState(() {
              _currentTemp = 'Please allow location access in your browser.';
            });
            return;
          }
        }
        if (permission == LocationPermission.deniedForever) {
          setState(() {
            _currentTemp = 'Location access blocked. Check browser settings.';
          });
          return;
        }
      } else {
        // For mobile platforms
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
      }

    print('Getting current position...');
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.low,
      timeLimit: Duration(seconds: 10),
    ).timeout(
      Duration(seconds: 15),
      onTimeout: () {
        throw Exception('Location request timed out');
      },
    );
    
    print('Got position: ${position.latitude}, ${position.longitude}');
    double lat = position.latitude;
    double lon = position.longitude;

    // Get placemark (city/state) from coordinates
    print('Getting placemark...');
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lon);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        print('Location: ${place.locality}, ${place.administrativeArea}');
        setState(() {
          _locationString = '${place.locality ?? 'Unknown'}, ${place.administrativeArea ?? ''}';
        });
      }
    } catch (e) {
      print('Geocoding error: $e');
      setState(() {
        _locationString = 'Location: $lat, $lon';
      });
    }

    // Get NWS gridpoint for location
    print('Fetching weather data...');
    final pointsUrl = Uri.parse('https://api.weather.gov/points/$lat,$lon');
    final pointsResp = await http.get(pointsUrl, headers: {
      'User-Agent': 'MyCompanionApp (your@email.com)'
    });
    
    print('Points API response: ${pointsResp.statusCode}');
    if (pointsResp.statusCode == 200) {
      final pointsData = json.decode(pointsResp.body);
      final properties = pointsData['properties'];
      
      if (properties == null) {
        print('Properties is null');
        setState(() {
          _currentTemp = 'Weather data unavailable.';
        });
        return;
      }
      
      final gridId = properties['gridId'];
      final gridX = properties['gridX'];
      final gridY = properties['gridY'];
      
      if (gridId == null || gridX == null || gridY == null) {
        print('Grid data is null: gridId=$gridId, gridX=$gridX, gridY=$gridY');
        setState(() {
          _currentTemp = 'Weather unavailable for this location.';
        });
        return;
      }
      
      print('Grid: $gridId $gridX,$gridY');
      
      // Get observation stations for this gridpoint
      final stationsUrl = Uri.parse('https://api.weather.gov/gridpoints/$gridId/$gridX,$gridY/stations');
      final stationsResp = await http.get(stationsUrl, headers: {
        'User-Agent': 'MyCompanionApp (your@email.com)'
      });
      
      print('Stations API response: ${stationsResp.statusCode}');
      if (stationsResp.statusCode == 200) {
        final stationsData = json.decode(stationsResp.body);
        final features = stationsData['features'];
        
        if (features != null && features.isNotEmpty) {
          // Get the nearest station ID
          final nearestStation = features[0]['properties']['stationIdentifier'];
          print('Nearest station: $nearestStation');
          
          // Get latest observation from the nearest station
          final observationUrl = Uri.parse('https://api.weather.gov/stations/$nearestStation/observations/latest');
          final observationResp = await http.get(observationUrl, headers: {
            'User-Agent': 'MyCompanionApp (your@email.com)'
          });
          
          print('Observation API response: ${observationResp.statusCode}');
          if (observationResp.statusCode == 200) {
            final observationData = json.decode(observationResp.body);
            final obsProperties = observationData['properties'];
            
            if (obsProperties != null) {
              final tempCelsius = obsProperties['temperature']['value'];
              
              if (tempCelsius != null) {
                // Convert Celsius to Fahrenheit
                final tempF = (tempCelsius * 9 / 5 + 32).round();
                print('Current Temperature: $tempF°F');
                
                // Get feels like temperature (heat index or wind chill)
                String feelsLike = '';
                final heatIndexC = obsProperties['heatIndex']?['value'];
                final windChillC = obsProperties['windChill']?['value'];
                
                if (heatIndexC != null) {
                  final heatIndexF = (heatIndexC * 9 / 5 + 32).round();
                  feelsLike = '$heatIndexF°F';
                  print('Heat Index: $heatIndexF°F');
                } else if (windChillC != null) {
                  final windChillF = (windChillC * 9 / 5 + 32).round();
                  feelsLike = '$windChillF°F';
                  print('Wind Chill: $windChillF°F');
                }
                
                setState(() {
                  _currentTemp = '$tempF°F';
                  _feelsLikeTemp = feelsLike;
                  _isUsingFallbackTemp = false;
                });
                
                // Now get today's high and low from forecast
                _getTodayHighLow(gridId, gridX, gridY);
              } else {
                print('Temperature value is null, trying hourly forecast instead');
                // Fallback to hourly forecast if observation is null
                _getHourlyForecastAsFallback(gridId, gridX, gridY);
              }
            } else {
              print('Observation properties is null');
              _getHourlyForecastAsFallback(gridId, gridX, gridY);
            }
          } else {
            print('Observation API error: ${observationResp.body}');
            _getHourlyForecastAsFallback(gridId, gridX, gridY);
          }
        } else {
          print('No stations found');
          setState(() {
            _currentTemp = 'No weather stations nearby.';
          });
        }
      } else {
        print('Stations API error: ${stationsResp.body}');
        setState(() {
          _currentTemp = 'Failed to find weather stations.';
        });
      }
    } else {
      print('Points API error: ${pointsResp.body}');
      setState(() {
        _currentTemp = 'Weather unavailable for this location.';
      });
    }
    } catch (e, stackTrace) {
      print('Error getting location/weather: $e');
      print('Stack trace: $stackTrace');
      setState(() {
        if (e.toString().contains('timed out') || e.toString().contains('TimeoutException')) {
          _currentTemp = 'Location request timed out.';
        } else if (e.toString().contains('No host specified')) {
          _currentTemp = 'Network error. Check connection.';
        } else {
          _currentTemp = 'Unable to get weather: ${e.toString().split('\n').first}';
        }
      });
    }
  }
  
  Future<void> _getHourlyForecastAsFallback(String gridId, int gridX, int gridY) async {
    try {
      print('Using hourly forecast temperature as fallback...');
      final hourlyUrl = Uri.parse('https://api.weather.gov/gridpoints/$gridId/$gridX,$gridY/forecast/hourly');
      final hourlyResp = await http.get(hourlyUrl, headers: {
        'User-Agent': 'MyCompanionApp (your@email.com)'
      });
      
      if (hourlyResp.statusCode == 200) {
        final hourlyData = json.decode(hourlyResp.body);
        final properties = hourlyData['properties'];
        
        if (properties != null) {
          final periods = properties['periods'];
          
          if (periods != null && periods.isNotEmpty) {
            final temp = periods[0]['temperature'];
            final unit = periods[0]['temperatureUnit'];
            
            if (temp != null && unit != null) {
              print('Hourly Forecast Temperature: $temp°$unit');
              setState(() {
                _currentTemp = '$temp°$unit';
                _feelsLikeTemp = '';
                _isUsingFallbackTemp = true;
              });
            } else {
              setState(() {
                _currentTemp = 'Temperature unavailable.';
              });
            }
          }
        }
      }
      
      // Get today's high and low regardless
      _getTodayHighLow(gridId, gridX, gridY);
    } catch (e) {
      print('Error getting hourly forecast temperature: $e');
      setState(() {
        _currentTemp = 'Temperature unavailable.';
      });
    }
  }
  
  Future<void> _getTodayHighLow(String gridId, int gridX, int gridY) async {
    try {
      print('Fetching today\'s high/low...');
      final forecastUrl = Uri.parse('https://api.weather.gov/gridpoints/$gridId/$gridX,$gridY/forecast');
      final forecastResp = await http.get(forecastUrl, headers: {
        'User-Agent': 'MyCompanionApp (your@email.com)'
      });
      
      if (forecastResp.statusCode == 200) {
        final forecastData = json.decode(forecastResp.body);
        final properties = forecastData['properties'];
        
        if (properties != null) {
          final periods = properties['periods'];
          
          if (periods != null && periods.isNotEmpty) {
            // Find today's high and low
            String? high;
            String? low;
            
            for (var period in periods) {
              final isDaytime = period['isDaytime'];
              final temp = period['temperature'];
              final unit = period['temperatureUnit'];
              
              if (temp != null && unit != null) {
                if (isDaytime == true && high == null) {
                  high = '$temp°$unit';
                } else if (isDaytime == false && low == null) {
                  low = '$temp°$unit';
                }
              }
              
              // Break once we have both
              if (high != null && low != null) break;
            }
            
            setState(() {
              _highTemp = high ?? '--';
              _lowTemp = low ?? '--';
            });
            print('High: $high, Low: $low');
            
            // Get next 5 days forecast
            _getMultiDayForecast(periods);
          }
        }
      }
    } catch (e) {
      print('Error getting high/low: $e');
    }
  }

  void _getMultiDayForecast(List<dynamic> periods) {
    try {
      print('Processing 5-day forecast...');
      List<Map<String, String>> forecast = [];
      Map<String, Map<String, String>> dayMap = {};
      
      // Get today's day name
      final dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      final today = dayNames[DateTime.now().weekday - 1];
      
      for (int i = 0; i < periods.length && forecast.length < 5; i++) {
        final period = periods[i];
        final name = period['name'] as String?;
        final isDaytime = period['isDaytime'] as bool?;
        final temp = period['temperature'];
        final unit = period['temperatureUnit'];
        final icon = period['icon'] as String?;
        
        if (name != null && temp != null && unit != null) {
          // Skip today's entries completely
          if (name == 'Tonight' || name == 'Today' || name == 'This Afternoon') {
            continue;
          }
          
          // Extract day name (e.g., "Monday" from "Monday Night")
          String dayName = name.replaceAll(' Night', '');
          
          // Skip if this is today's day
          if (dayName == today) {
            continue;
          }
          
          if (!dayMap.containsKey(dayName)) {
            dayMap[dayName] = {};
          }
          
          if (isDaytime == true) {
            dayMap[dayName]!['high'] = '$temp°';
            // Store icon for daytime (primary icon)
            if (icon != null) {
              dayMap[dayName]!['icon'] = icon;
            }
          } else {
            dayMap[dayName]!['low'] = '$temp°';
          }
        }
      }
      
      // Convert to list
      int count = 0;
      for (var entry in dayMap.entries) {
        if (count >= 5) break;
        
        forecast.add({
          'day': entry.key,
          'high': entry.value['high'] ?? '--',
          'low': entry.value['low'] ?? '--',
          'icon': entry.value['icon'] ?? '',
        });
        count++;
      }
      
      setState(() {
        _fiveDayForecast = forecast;
      });
      print('5-day forecast: $_fiveDayForecast');
    } catch (e) {
      print('Error processing 5-day forecast: $e');
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
          MaterialPageRoute(builder: (context) => PersonalPage()),
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
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Weather Card
            Card(
              margin: const EdgeInsets.all(16),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                  if (_dayOfWeek.isNotEmpty) ...[
                    Text(
                      _dayOfWeek,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blue),
                    ),
                    Text(
                      _dateString,
                      style: TextStyle(fontSize: 16, color: Theme.of(context).textTheme.bodyMedium?.color),
                    ),
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 8),
                  ],
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.thermostat, color: Colors.blue),
                      const SizedBox(width: 8),
                      Text(
                        _currentTemp.isEmpty ? 'Loading...' : _isUsingFallbackTemp ? '$_currentTemp *' : _currentTemp,
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  if (_feelsLikeTemp.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Feels Like: $_feelsLikeTemp',
                      style: TextStyle(fontSize: 16, color: Theme.of(context).textTheme.bodySmall?.color),
                    ),
                  ],
                  if (_highTemp.isNotEmpty && _lowTemp.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.arrow_upward, color: Colors.red[700], size: 20),
                        const SizedBox(width: 4),
                        Text(
                          _highTemp,
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.red[700]),
                        ),
                        const SizedBox(width: 24),
                        Icon(Icons.arrow_downward, color: Colors.blue[700], size: 20),
                        const SizedBox(width: 4),
                        Text(
                          _lowTemp,
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.blue[700]),
                        ),
                      ],
                    ),
                  ],
                  if (_locationString.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    const Divider(),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.location_on, color: Colors.blue, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          _locationString,
                          style: TextStyle(fontSize: 14, color: Theme.of(context).textTheme.bodyMedium?.color),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
            if (_fiveDayForecast.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    '5-Day Forecast',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: SizedBox(
                  height: 160,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    shrinkWrap: true,
                    itemCount: _fiveDayForecast.length,
                    itemBuilder: (context, index) {
                      final day = _fiveDayForecast[index];
                      return Container(
                        width: 100,
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark 
                            ? Colors.blue.withOpacity(0.15) 
                            : Colors.blue[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade300, width: 1.5),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            day['day']!,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          if (day['icon'] != null && day['icon']!.isNotEmpty)
                            Image.network(
                              day['icon']!,
                              width: 40,
                              height: 40,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(Icons.wb_sunny, size: 30, color: Colors.orange);
                              },
                            ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.arrow_upward, color: Colors.red[700], size: 14),
                              const SizedBox(width: 2),
                              Text(
                                day['high']!,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.red[700],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.arrow_downward, color: Colors.blue[700], size: 14),
                              const SizedBox(width: 2),
                              Text(
                                day['low']!,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue[700],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
                ),
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}