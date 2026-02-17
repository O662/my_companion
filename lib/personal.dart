import 'package:flutter/material.dart';
import 'home.dart';
import 'tools.dart';
import 'health.dart';

import 'bottom_nav_bar.dart';

class PersonalPage extends StatefulWidget {
  @override
  _PersonalPageState createState() => _PersonalPageState();
}

class _PersonalPageState extends State<PersonalPage> {
  int _selectedIndex = 3;

  // Vehicle information - you can later connect this to Firebase
  final Map<String, String> _vehicleInfo = {
    'make': 'Toyota',
    'model': 'Camry',
    'year': '2022',
    'vin': '1HGBH41JXMN109186',
    'mileage': '28,450',
  };

  // Vehicle maintenance reminders
  final List<Map<String, dynamic>> _maintenanceReminders = [
    {
      'title': 'Oil Change',
      'date': DateTime(2026, 3, 1),
      'mileage': '30,000',
      'icon': Icons.oil_barrel,
    },
    {
      'title': 'Tire Rotation',
      'date': DateTime(2026, 4, 15),
      'mileage': '32,000',
      'icon': Icons.tire_repair,
    },
    {
      'title': 'Annual Inspection',
      'date': DateTime(2026, 6, 20),
      'mileage': 'Required',
      'icon': Icons.verified,
    },
  ];

  // Sample agenda items - you can later connect this to Firebase
  final List<Map<String, dynamic>> _agendaItems = [
    {
      'title': 'Mom\'s Birthday',
      'date': DateTime(2026, 3, 15),
      'type': 'birthday',
      'icon': Icons.cake,
    },
    {
      'title': 'Dentist Appointment',
      'date': DateTime(2026, 2, 20),
      'type': 'dentist',
      'icon': Icons.medical_services,
    },
    {
      'title': 'Annual Checkup',
      'date': DateTime(2026, 3, 5),
      'type': 'doctor',
      'icon': Icons.local_hospital,
    },
    {
      'title': 'Dad\'s Birthday',
      'date': DateTime(2026, 4, 22),
      'type': 'birthday',
      'icon': Icons.cake,
    },
    {
      'title': 'Dental Cleaning',
      'date': DateTime(2026, 5, 10),
      'type': 'dentist',
      'icon': Icons.medical_services,
    },
  ];

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now).inDays;
    
    final monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final formattedDate = '${monthNames[date.month - 1]} ${date.day}, ${date.year}';
    
    if (difference < 0) {
      return '$formattedDate (Past)';
    } else if (difference == 0) {
      return '$formattedDate (Today)';
    } else if (difference == 1) {
      return '$formattedDate (Tomorrow)';
    } else if (difference < 7) {
      return '$formattedDate (in $difference days)';
    } else {
      return formattedDate;
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'birthday':
        return Colors.pink;
      case 'dentist':
        return Colors.teal;
      case 'doctor':
        return Colors.blue;
      case 'vehicle':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  void _onItemTapped(int index) {
    // Don't navigate if we're already on this page
    if (index == 3) {
      return; // Already on personal page
    }
    
    // Navigate to other pages
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
    }
  }

  @override
  Widget build(BuildContext context) {
    // Sort agenda items by date
    final sortedAgenda = List<Map<String, dynamic>>.from(_agendaItems)
      ..sort((a, b) => a['date'].compareTo(b['date']));
    
    // Sort maintenance reminders by date
    final sortedMaintenance = List<Map<String, dynamic>>.from(_maintenanceReminders)
      ..sort((a, b) => a['date'].compareTo(b['date']));
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Personal'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Vehicle Information Card
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.directions_car, color: Colors.orange, size: 24),
                      const SizedBox(width: 8),
                      const Text(
                        'My Vehicle',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_vehicleInfo['year']} ${_vehicleInfo['make']} ${_vehicleInfo['model']}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'VIN: ${_vehicleInfo['vin']}',
                              style: TextStyle(
                                fontSize: 13,
                                color: Theme.of(context).textTheme.bodySmall?.color,
                                fontFamily: 'monospace',
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Mileage: ${_vehicleInfo['mileage']} miles',
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(context).textTheme.bodyMedium?.color,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 12),
                  const Text(
                    'Maintenance Reminders',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (sortedMaintenance.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('No maintenance scheduled'),
                      ),
                    ),
                  if (sortedMaintenance.isNotEmpty)
                    ...List<Widget>.generate(sortedMaintenance.length, (index) {
                      final item = sortedMaintenance[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.orange.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: ListTile(
                          leading: Icon(
                            item['icon'],
                            color: Colors.orange,
                            size: 20,
                          ),
                          title: Text(
                            item['title'],
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          subtitle: Text(
                            '${_formatDate(item['date'])} • ${item['mileage']} mi',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).textTheme.bodySmall?.color,
                            ),
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.calendar_today, color: Colors.blue, size: 24),
                      const SizedBox(width: 8),
                      const Text(
                        'Upcoming Events',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (sortedAgenda.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('No upcoming events'),
                      ),
                    ),
                  if (sortedAgenda.isNotEmpty)
                    ...List<Widget>.generate(sortedAgenda.length, (index) {
                      final item = sortedAgenda[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: _getTypeColor(item['type']).withOpacity(0.3),
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _getTypeColor(item['type']).withOpacity(0.2),
                            child: Icon(
                              item['icon'],
                              color: _getTypeColor(item['type']),
                              size: 20,
                            ),
                          ),
                          title: Text(
                            item['title'],
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Text(
                            _formatDate(item['date']),
                            style: TextStyle(
                              fontSize: 13,
                              color: Theme.of(context).textTheme.bodySmall?.color,
                            ),
                          ),
                          trailing: Icon(
                            Icons.chevron_right,
                            color: _getTypeColor(item['type']),
                          ),
                        ),
                      );
                    }),
                ],
              ),
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
