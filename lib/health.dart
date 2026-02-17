import 'package:flutter/material.dart';
import 'home.dart';
import 'tools.dart';
import 'personal.dart';

import 'bottom_nav_bar.dart';

class HealthPage extends StatefulWidget {
  @override
  _HealthPageState createState() => _HealthPageState();
}

class _HealthPageState extends State<HealthPage> {
  int _selectedIndex = 2;

  // Sample health data - you can later connect to health APIs or Firebase
  final int _currentSteps = 8247;
  final int _goalSteps = 10000;
  final List<int> _weeklySteps = [7500, 9200, 6800, 8500, 7900, 9600, 8247];

  double get _progressPercentage => (_currentSteps / _goalSteps).clamp(0.0, 1.0);

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
        title: Text('Health'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Steps Card with Chart
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.directions_walk, color: Colors.green, size: 24),
                      const SizedBox(width: 8),
                      const Text(
                        'Daily Steps',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Main display with number and chart
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Large number on the left
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _currentSteps.toString(),
                              style: TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'of $_goalSteps goal',
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(context).textTheme.bodySmall?.color,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: _progressPercentage,
                                backgroundColor: Colors.grey[300],
                                color: Colors.green,
                                minHeight: 8,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${(_progressPercentage * 100).toStringAsFixed(0)}% complete',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).textTheme.bodySmall?.color,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Chart on the right
                      Expanded(
                        flex: 3,
                        child: SizedBox(
                          height: 120,
                          child: CustomPaint(
                            painter: BarChartPainter(
                              data: _weeklySteps,
                              maxValue: _goalSteps,
                              barColor: Colors.green,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Week labels
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Expanded(
                        flex: 2,
                        child: Container(),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 3,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: ['M', 'T', 'W', 'T', 'F', 'S', 'S']
                              .map((day) => Text(
                                    day,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Theme.of(context).textTheme.bodySmall?.color,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ))
                              .toList(),
                        ),
                      ),
                    ],
                  ),
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

// Custom painter for bar chart
class BarChartPainter extends CustomPainter {
  final List<int> data;
  final int maxValue;
  final Color barColor;

  BarChartPainter({
    required this.data,
    required this.maxValue,
    required this.barColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final barWidth = size.width / (data.length * 2 - 1);
    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < data.length; i++) {
      final barHeight = (data[i] / maxValue) * size.height;
      final left = i * barWidth * 2;
      final top = size.height - barHeight;

      paint.color = (i == data.length - 1) ? barColor : barColor.withOpacity(0.5);

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(left, top, barWidth, barHeight),
        const Radius.circular(4),
      );
      canvas.drawRRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}